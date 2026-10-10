//
//  StrongBot.swift
//  BigTwoKit — fair opponent. Own hand, public `left: N`, and cards already
//  played. Never another seat's hole cards (those are on `BotContext` for Classic).
//
//  Plans the fewest plays that empty the hand, then picks a gear:
//
//    attack  — control covers the plan: take the lead and run it out.
//    contest — one play short: fight for the lead whenever the hand can still
//              afford the stopper it spends (`Choice.affordsSpending`).
//    defend  — far short: keep the stoppers, answer only with spare cards.
//
//  ⚠️ `contest` is the gear the bot that shipped did not have. It was weak /
//  not-weak, and nearly every hand is weak at thirteen cards, so a human could win
//  every trick with a king while the bot sat on an ace it was "saving". Spending a
//  stopper is now an affordability question, not a mood.
//
//  On top of that: when the deal is going away (`losingRace`) the objective changes
//  from fewest plays to fewest *points*. A card left in hand costs its rank and ten
//  cards double it, so a lost deal is about unloading twos and aces, not about
//  tidy play. Nothing in the old bot knew that.
//

import Foundation

/// How hard the hand can push. Replaces the old weak / not-weak pair.
enum Stance {
  case attack, contest, defend
}

public enum StrongBot {

  public static func choose(_ c: BotContext) -> Play? { choose(c, reading: nil) }

  /// `reading` is what makes a seat Expert rather than Strong: the same policy, run
  /// against what the table says the other three are holding instead of against the
  /// worst case. Everything downstream — the plan, the gear, whether a stopper is
  /// spare — reads it through `Choice`.
  static func choose(_ c: BotContext, reading belief: Belief?) -> Play? {
    let hand = c.hand
    guard !hand.isEmpty else { return nil }
    let counts = opponentCounts(c)
    let planner = Planner(hand: hand, rules: c.rules, unseen: unseenCards(c),
                          maxHold: counts.max() ?? 0, reading: belief)
    let options = planner.choices(beating: c.table, mustInclude: c.mustInclude)
    guard !options.isEmpty else { return nil }
    if let out = options.first(where: { $0.play.count == hand.count }) { return out.play }
    let stance = planner.stance(leading: c.leading)
    let dumping = losingRace(handPlays: planner.plays, counts: counts, handCount: hand.count)
    guard let table = c.table else {
      return lead(options, counts, stance: stance, dumping: dumping)
    }
    return follow(options, counts, table, handCount: hand.count,
                  stance: stance, dumping: dumping, reading: belief != nil)
  }

  // MARK: - Points

  /// What this play would have cost if it had stayed in the hand at the end.
  static func penalty(_ play: Play) -> Int {
    play.cards.reduce(0) { $0 + $1.rank.penalty }
  }

  /// All `left: N` says about a seat, in plays. Three cards is about one play.
  static func estimatedPlays(_ count: Int) -> Int { (count + 2) / 3 }

  /// Somebody is close to out and the bot is further behind than it can catch up.
  /// Nobody being short yet is not a lost deal, whatever the plan lengths say —
  /// a thirteen-card hand of singles would otherwise start the deal in dumping mode.
  /// ⚠️ Both numbers are tight on purpose. Giving up early is expensive against a
  /// weak opponent, who hands the lead back and lets a bot that kept playing win the
  /// deal after all: over 16 seeded games, four cards and three plays scores 2693
  /// against greedy seats, six and two scores 2018, and never dumping scores 2798 —
  /// but never dumping drops from 1622 to 1280 against a real opponent, which is the
  /// one that matters. These two values beat the shipped policy on both.
  static func losingRace(handPlays: Int, counts: [Int], handCount: Int) -> Bool {
    guard let best = counts.min(), best <= 4 else { return false }
    if best <= 2 && handCount >= 5 { return true }
    return estimatedPlays(best) + 3 <= handPlays
  }

  /// Cheapest play — or, when the deal is going away, the one that unloads the most
  /// points. Same candidates either way; only the objective changes.
  static func pick(_ options: [Choice], dumping: Bool) -> Play? {
    guard dumping else { return shed(options) }
    return options.min { dumpsBetter($0, $1) }?.play
  }

  static func dumpsBetter(_ a: Choice, _ b: Choice) -> Bool {
    let pa = penalty(a.play), pb = penalty(b.play)
    if pa != pb { return pa > pb }
    return weaker(a.play, b.play)
  }

  // MARK: - Lead

  /// A two is control even when nothing beats it — leading it first is how a
  /// "strong" bot got weaker than greedy.
  static func lead(_ options: [Choice], _ counts: [Int], stance: Stance, dumping: Bool) -> Play? {
    let short = counts.contains { $0 <= 2 }
    return options.min {
      betterLead($0, $1, counts: counts, short: short, stance: stance, dumping: dumping)
    }?.play
  }

  static func betterLead(_ a: Choice, _ b: Choice, counts: [Int], short: Bool,
                         stance: Stance, dumping: Bool) -> Bool {
    if a.opensSweep != b.opensSweep { return a.opensSweep }
    if a.opensSweep && b.opensSweep {
      if a.play.count != b.play.count { return a.play.count > b.play.count }
      return weaker(a.play, b.play)
    }
    let aCover = covers(a, counts), bCover = covers(b, counts)
    if aCover != bCover { return aCover }
    if aCover && bCover {
      if a.control != b.control { return !a.control }
      if a.play.count != b.play.count { return a.play.count > b.play.count }
    }
    // A seat on one card goes out the moment it gets a turn, and nothing they cannot
    // answer costs anything to lead. `covers` only sees plays longer than their hand.
    if counts.contains(1), a.unbeatable != b.unbeatable { return a.unbeatable }
    if a.damage != b.damage { return a.damage < b.damage }
    // Someone on one card wins the moment they play it. A low single hands them the deal.
    if counts.contains(1), a.play.count == 1, b.play.count == 1 {
      return stronger(a.play, b.play)
    }
    // Holding control back is only worth it while the lead is still worth winning.
    if !dumping, a.control != b.control { return !a.control }
    // A hand short of control keeps a king pair as a stopper and leads a dead single.
    if stance != .attack, highGroup(a.play) != highGroup(b.play) { return !highGroup(a.play) }
    if a.play.count != b.play.count { return a.play.count > b.play.count }
    if dumping, penalty(a.play) != penalty(b.play) { return penalty(a.play) > penalty(b.play) }
    if short { return stronger(a.play, b.play) }
    return weaker(a.play, b.play)
  }

  // MARK: - Follow

  static func follow(_ options: [Choice], _ counts: [Int], _ table: Play,
                     handCount: Int, stance: Stance, dumping: Bool,
                     reading: Bool = false) -> Play? {
    if let sweep = shed(options.filter(\.restSweeps)) { return sweep }
    let oneLeft = counts.contains(1)
    if counts.contains(table.count) || oneLeft {
      if let lock = shed(options.filter(\.unbeatable)) { return lock }
      if counts.contains(table.count) {
        return options.min { stronger($0.play, $1.play) }?.play
      }
    }
    // A five that is already one play of the plan dumps five cards and takes the
    // lead. Passing on it, bomb included, is how a straight runs out.
    if table.count == 5,
       let five = pick(options.filter { $0.play.count == 5 && $0.damage <= 0 }, dumping: dumping) {
      return five
    }
    let spare = options.filter {
      spareCard($0, table, stance: stance, dumping: dumping, reading: reading)
    }
    if let free = pick(spare.filter { $0.damage == 0 }, dumping: dumping) { return free }
    // Breaking one pair still sheds a card. Passing here is how a lead runs away.
    if let cracked = pick(spare.filter { $0.damage <= 1 }, dumping: dumping) { return cracked }

    // ⚠️ The gear the shipped bot did not have. A stopper is worth spending when what
    // is left still covers what is left to play — otherwise every trick goes to whoever
    // holds a king, and the bot finishes with the expensive cards in its hand.
    if (stance != .defend || dumping) && worthAStopper(table) {
      let affordable = options.filter { ($0.control || $0.unbeatable) && $0.affordsSpending }
      if let clean = pick(affordable.filter { $0.damage == 0 }, dumping: dumping) { return clean }
      if let split = pick(affordable.filter { $0.damage <= 1 }, dumping: dumping) { return split }
    }

    guard worthControl(table, counts, handCount: handCount,
                       stance: stance, dumping: dumping) else { return nil }
    if let clean = pick(options.filter { $0.damage == 0 }, dumping: dumping) { return clean }
    // A strong hand will split one pair of twos to take a king back. The other two stays.
    if stance == .attack || dumping,
       let split = pick(options.filter { $0.damage <= 1 }, dumping: dumping) { return split }
    if counts.contains(where: { $0 <= 2 }) || oneLeft || handCount <= 2 {
      return pick(options, dumping: dumping)
    }
    return nil
  }

  /// A card the hand can throw at this trick without giving anything up: not control,
  /// and — unless the hand is attacking or already unloading points — not a big jump.
  /// A king over a four is a stopper spent on a cheap trick.
  static func spareCard(_ choice: Choice, _ table: Play, stance: Stance, dumping: Bool,
                        reading: Bool = false) -> Bool {
    if choice.control { return false }
    if stance == .attack || dumping { return true }
    guard choice.play.count == 1,
          let card = choice.play.cards.first, let shown = table.cards.first else { return true }
    // ⚠️ This is the one place the Expert reading pays, and it is worth knowing why.
    // Strong has to guess with the distance between the two cards: five ranks or less
    // and the card is spare, otherwise it would rather pass than spend it. That throws
    // away tricks — a nine over a three is not a stopper, it is just a nine — and it
    // keeps cards that stopped being stoppers four tricks ago. Expert asks whether the
    // card would actually hold the lead and spends everything that would not.
    // ⚠️ Measured: this is the whole of Expert. Feeding the belief to `unbeatable`,
    // to `power` or to the lead ordering changed 1 decision in 3552 or made it worse —
    // see CLAUDE.md § Expert.
    if reading { return choice.survival < Belief.worthKeeping }
    return card.rank.rawValue - shown.rank.rawValue <= 5
  }

  /// A low single is somebody else's problem — spending a stopper on it buys a trick
  /// the next seat would have taken anyway, and the lead comes back either way.
  static func worthAStopper(_ table: Play) -> Bool {
    guard table.count == 1, let card = table.cards.first else { return true }
    return card.rank >= .ten
  }

  /// Endgame, a short opponent, a lost deal, or a hand with the control to spare.
  /// A hand that is far short of control does not spend its two on a high card.
  static func worthControl(_ table: Play, _ counts: [Int], handCount: Int,
                           stance: Stance, dumping: Bool) -> Bool {
    if handCount <= 3 || counts.contains(where: { $0 <= 2 }) { return true }
    if dumping { return true }
    if stance == .defend { return false }
    return tableIsHigh(table)
  }

  /// King or ace pair / triple — a stopper, not a lead, when the hand is short of control.
  static func highGroup(_ play: Play) -> Bool {
    guard play.count == 2 || play.count == 3 else { return false }
    return (play.cards.first?.rank ?? .three) >= .king
  }

  static func shed(_ options: [Choice]) -> Play? {
    options.min { weaker($0.play, $1.play) }?.play
  }

  // MARK: - What the table shows

  /// `left: N` only. Hole cards stay on the context for Classic.
  static func opponentCounts(_ c: BotContext) -> [Int] {
    c.hands.indices.filter { $0 != c.seat }.map { c.hands[$0].count }
  }

  static func unseenCards(_ c: BotContext) -> [Card] {
    var gone = Set(c.hand)
    gone.formUnion(c.discarded)
    if let table = c.table { gone.formUnion(table.cards) }
    return Card.deck.filter { !gone.contains($0) }
  }

  /// A short seat cannot answer this. A lone two does not qualify — leading it
  /// first throws away the card that takes the lead back.
  static func covers(_ c: Choice, _ counts: [Int]) -> Bool {
    if c.control && c.play.count < 5 { return false }
    let danger = counts.filter { $0 <= 3 }
    guard !danger.isEmpty else { return false }
    return danger.allSatisfy { $0 < c.play.count }
  }

  static func tableIsHigh(_ play: Play) -> Bool {
    if play.count <= 3 {
      return (play.cards.map(\.rank).max() ?? .three) >= .king
    }
    return play.kind >= .fullHouse
  }

  static func weaker(_ a: Play, _ b: Play) -> Bool {
    if a.beats(b) { return false }
    if b.beats(a) { return true }
    return weight(a) < weight(b)
  }

  static func stronger(_ a: Play, _ b: Play) -> Bool {
    if a.beats(b) { return true }
    if b.beats(a) { return false }
    return weight(a) < weight(b)
  }

  static func weight(_ play: Play) -> Int {
    play.cards.reduce(0) { $0 + $1.id }
  }

  static func isControl(_ play: Play) -> Bool {
    if play.kind.isBomb { return true }
    if play.cards.contains(where: { $0.rank == .two }) { return true }
    if play.count == 1, play.cards.first?.rank ?? .three >= .ace { return true }
    // A pair or triple of aces takes the lead as reliably as a single ace.
    if (play.count == 2 || play.count == 3),
       (play.cards.first?.rank ?? .three) >= .ace { return true }
    return false
  }

  /// Points of control in one play of the plan. Two is a hard stopper, a king
  /// pair is only probable — the hand is strong when the total covers its plays.
  static func power(of play: Play, unbeatable: Bool) -> Int {
    if unbeatable || isControl(play) { return 2 }
    if (play.count == 2 || play.count == 3),
       (play.cards.first?.rank ?? .three) >= .king { return 1 }
    if play.kind >= .fullHouse { return 1 }
    return 0
  }
}

// MARK: - Plan

// `Choice`, `Planner` and `Reader` are internal, not private: `LegacyStrongBot` in the
// test target is the old *policy* measured against the new one, and it shares this
// infrastructure. Keep what they already return stable — add fields, don't redefine —
// or the yardstick stops being the bot that shipped.

/// Fewest legal plays that partition the hand. 13 cards → 8192 subsets.
struct Choice {
  let play: Play
  let damage: Int
  let unbeatable: Bool
  /// The chance this play is still on the table when the turn comes back. Strong only
  /// ever knows 0 or 1 (`Reader` answers the worst case); Expert reads it off `Belief`.
  let survival: Double
  let control: Bool
  let restSweeps: Bool
  /// Control points left, and plays still needed, once this one is gone.
  let restPower: Int
  let restPlays: Int
  /// Unbeatable, and every play after it is too, so the lead empties the hand.
  var opensSweep: Bool { unbeatable && restSweeps }
  /// Spending this stopper still leaves the rest of the hand covered. Winning the
  /// trick hands the lead back, which is worth one play — that is the `+ 1`.
  var affordsSpending: Bool { restPower + 1 >= restPlays }
}

struct Planner {
  let full: Int
  let dp: [Int]
  let sweep: [Bool]
  /// Control points in a shortest partition of each subset.
  let power: [Int]
  private let tagged: [Tagged]

  struct Tagged {
    let mask: Int
    let play: Play
    let unbeatable: Bool
    let survival: Double
    let control: Bool
    let power: Int
  }

  /// Plays in the shortest partition of the whole hand.
  var plays: Int { dp[full] }

  /// Leading spends one play for free, so the same cards are less weak with the lead.
  /// Kept for `LegacyStrongBot`, the yardstick in the test target.
  func weak(leading: Bool) -> Bool {
    let budget = power[full] + (leading ? 1 : 0)
    return budget < dp[full]
  }

  /// `attack` is the old `!weak`. `contest` is within two plays of covering the plan —
  /// close enough to fight for the lead when the hand can afford the stopper it spends.
  /// ⚠️ The two is measured, not chosen. Seat 0 over 16 seeded games, against three
  /// of the shipped policy (which scores -512 there) and against three greedy seats
  /// (2532): one short 1222 / 2954, two short 1622 / 2693, three short 1702 / 2416.
  /// Two is the only one that beats the shipped policy on both — a wider gear keeps
  /// buying tricks from an opponent who was going to give them away anyway.
  func stance(leading: Bool) -> Stance {
    let budget = power[full] + (leading ? 1 : 0)
    let need = dp[full]
    if budget >= need { return .attack }
    if budget + 2 >= need { return .contest }
    return .defend
  }

  /// `reading` is Expert: the same plan, scored against what the table says the other
  /// three can be holding instead of against every card nobody has seen.
  init(hand: [Card], rules: RuleSet, unseen: [Card], maxHold: Int, reading: Belief? = nil) {
    let cards = hand.sorted()
    let n = cards.count
    let full = n == 0 ? 0 : (1 << n) - 1
    self.full = full
    let reader = Reader(cards: unseen, maxHold: maxHold, rules: rules)
    // The DP below indexes the *hand*, so each move's 52-bit card mask is folded down
    // to a mask over the sorted hand. `lexBefore` puts the moves back in the order the
    // old combination walk produced them — see its comment for why that matters.
    var index = Array(repeating: 0, count: 52)
    for (i, card) in cards.enumerated() { index[card.id] = i }
    var found: [Tagged] = []
    for move in MoveGen.moves(in: CardSet(cards), rules: rules).sorted(by: MoveGen.lexBefore) {
      var mask = 0
      var rest = move.mask
      while rest != 0 {
        mask |= 1 << index[rest.trailingZeroBitCount]
        rest &= rest - 1
      }
      let play = move.play
      let unbeatable = !reader.canBeat(play)
      let survival = reading.map { $0.survival(of: play) } ?? (unbeatable ? 1 : 0)
      found.append(Tagged(mask: mask, play: play,
                          unbeatable: unbeatable,
                          survival: survival,
                          control: StrongBot.isControl(play),
                          power: StrongBot.power(of: play, unbeatable: unbeatable)))
    }
    tagged = found

    var dp = Array(repeating: n + 1, count: full + 1)
    var sweep = Array(repeating: false, count: full + 1)
    var power = Array(repeating: 0, count: full + 1)
    dp[0] = 0
    sweep[0] = true
    if full > 0 {
      for mask in 1...full {
        for play in found where mask & play.mask == play.mask {
          let rest = mask ^ play.mask
          let tricks = dp[rest] + 1
          let gained = power[rest] + play.power
          if tricks < dp[mask] || (tricks == dp[mask] && gained > power[mask]) {
            dp[mask] = tricks
            power[mask] = gained
          }
          if play.unbeatable && sweep[rest] { sweep[mask] = true }
        }
      }
    }
    self.dp = dp
    self.sweep = sweep
    self.power = power
  }

  func choices(beating table: Play?, mustInclude: Card?) -> [Choice] {
    let base = dp[full]
    return tagged.compactMap { tag in
      if let must = mustInclude, !tag.play.cards.contains(must) { return nil }
      if let table, !tag.play.beats(table) { return nil }
      let rest = full ^ tag.mask
      return Choice(play: tag.play,
                    damage: dp[rest] - (base - 1),
                    unbeatable: tag.unbeatable,
                    survival: tag.survival,
                    control: tag.control,
                    restSweeps: sweep[rest],
                    restPower: power[rest],
                    restPlays: dp[rest])
    }
  }
}

// MARK: - Cards still out

/// Worst case: one opponent holds any subset of the unseen cards up to `maxHold`.
struct Reader {
  let cards: Set<Card>
  let rankCount: [Int]
  let maxHold: Int
  let rules: RuleSet

  init(cards: [Card], maxHold: Int, rules: RuleSet) {
    self.cards = Set(cards)
    var counts = Array(repeating: 0, count: Rank.allCases.count)
    for card in cards { counts[card.rank.rawValue] += 1 }
    rankCount = counts
    self.maxHold = maxHold
    self.rules = rules
  }

  func canBeat(_ play: Play) -> Bool {
    switch play.count {
    case 1: return canBeatSingle(play)
    case 2: return canBeatPair(play)
    case 3: return canBeatTriple(play)
    case 5: return canBeatFive(play)
    default: return false
    }
  }

  func canBeatSingle(_ play: Play) -> Bool {
    guard maxHold >= 1, let card = play.cards.first else { return false }
    return cards.contains { $0 > card }
  }

  func canBeatPair(_ play: Play) -> Bool {
    guard maxHold >= 2, let rank = play.cards.first?.rank else { return false }
    if Rank.allCases.contains(where: { $0 > rank && rankCount[$0.rawValue] >= 2 }) {
      return true
    }
    let same = cards.filter { $0.rank == rank }.sorted()
    guard same.count >= 2, let top = same.last, let second = same.dropLast().last else {
      return false
    }
    return Play([second, top], rules: rules)?.beats(play) ?? false
  }

  func canBeatTriple(_ play: Play) -> Bool {
    guard maxHold >= 3, let rank = play.cards.first?.rank else { return false }
    return Rank.allCases.contains { $0 > rank && rankCount[$0.rawValue] >= 3 }
  }

  func canBeatFive(_ play: Play) -> Bool {
    guard maxHold >= 5 else { return false }
    if straightFlushBeats(play) || quadsBeat(play) || fullHouseBeats(play) { return true }
    if play.kind <= .flush && flushBeats(play) { return true }
    if play.kind == .straight && straightBeats(play) { return true }
    return false
  }

  func straightFlushBeats(_ target: Play) -> Bool {
    for suit in Suit.allCases {
      for window in Self.windows {
        let suited = window.map { Card(rank: $0, suit: suit) }
        guard suited.allSatisfy({ cards.contains($0) }) else { continue }
        if Play(suited, rules: rules)?.beats(target) == true { return true }
      }
    }
    return false
  }

  func quadsBeat(_ target: Play) -> Bool {
    for rank in Rank.allCases where rankCount[rank.rawValue] == 4 {
      let quad = Suit.allCases.map { Card(rank: rank, suit: $0) }
      guard let kicker = cards.first(where: { $0.rank != rank }) else { continue }
      if Play(quad + [kicker], rules: rules)?.beats(target) == true { return true }
    }
    return false
  }

  func fullHouseBeats(_ target: Play) -> Bool {
    for triple in Rank.allCases where rankCount[triple.rawValue] >= 3 {
      guard Rank.allCases.contains(where: { $0 != triple && rankCount[$0.rawValue] >= 2 }) else {
        continue
      }
      let trips = Suit.allCases.map { Card(rank: triple, suit: $0) }.filter { cards.contains($0) }
      let pairRank = Rank.allCases.first { $0 != triple && rankCount[$0.rawValue] >= 2 }
      guard let pairRank else { continue }
      let pair = Suit.allCases.map { Card(rank: pairRank, suit: $0) }.filter { cards.contains($0) }
      guard trips.count >= 3, pair.count >= 2 else { continue }
      let hand = Array(trips.prefix(3)) + Array(pair.prefix(2))
      if Play(hand, rules: rules)?.beats(target) == true { return true }
    }
    return false
  }

  func flushBeats(_ target: Play) -> Bool {
    for suit in Suit.allCases {
      let suited = cards.filter { $0.suit == suit }.sorted()
      guard suited.count >= 5 else { continue }
      if Play(Array(suited.suffix(5)), rules: rules)?.beats(target) == true { return true }
    }
    return false
  }

  func straightBeats(_ target: Play) -> Bool {
    for window in Self.windows {
      guard window.allSatisfy({ rankCount[$0.rawValue] >= 1 }) else { continue }
      let topRank = Self.top(of: window)
      let top = Suit.allCases.reversed().map { Card(rank: topRank, suit: $0) }.first { cards.contains($0) }
      guard let top else { continue }
      var chosen = [top]
      var intact = true
      for rank in window where rank != topRank {
        guard let card = Suit.allCases.map({ Card(rank: rank, suit: $0) }).first(where: { cards.contains($0) }) else {
          intact = false
          break
        }
        chosen.append(card)
      }
      if intact, Play(chosen, rules: rules)?.beats(target) == true { return true }
    }
    return false
  }

  /// The same ten straights the generator walks — one table, not two.
  static let windows: [[Rank]] = MoveGen.straightRanks

  /// A2345 is topped by the five. Every other window is topped by its last rank.
  static func top(of window: [Rank]) -> Rank { MoveGen.topRank(of: window) }
}

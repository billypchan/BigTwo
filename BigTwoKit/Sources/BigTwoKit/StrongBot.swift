//
//  StrongBot.swift
//  BigTwoKit — fair opponent. Own hand, public `left: N`, and cards already
//  played. Never another seat's hole cards (those are on `BotContext` for Classic).
//
//  Plans the fewest plays that empty the hand, dumps a low combo while it has the
//  lead, and holds twos / aces / bombs to take the lead back.
//

import Foundation

public enum StrongBot {

  public static func choose(_ c: BotContext) -> Play? {
    let hand = c.hand
    guard !hand.isEmpty else { return nil }
    let counts = opponentCounts(c)
    let planner = Planner(hand: hand, rules: c.rules,
                          unseen: unseenCards(c), maxHold: counts.max() ?? 0)
    let options = planner.choices(beating: c.table, mustInclude: c.mustInclude)
    guard !options.isEmpty else { return nil }
    if let out = options.first(where: { $0.play.count == hand.count }) { return out.play }
    if c.leading { return lead(options, counts) }
    guard let table = c.table else { return lead(options, counts) }
    return follow(options, counts, table, handCount: hand.count)
  }

  // MARK: - Lead

  /// A two is control even when nothing beats it — leading it first is how a
  /// "strong" bot got weaker than greedy.
  static func lead(_ options: [Choice], _ counts: [Int]) -> Play? {
    let short = counts.contains { $0 <= 2 }
    return options.min { betterLead($0, $1, counts: counts, short: short) }?.play
  }

  static func betterLead(_ a: Choice, _ b: Choice, counts: [Int], short: Bool) -> Bool {
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
    if a.damage != b.damage { return a.damage < b.damage }
    // Someone on one card wins the moment they play it. A low single hands them the deal.
    if counts.contains(1), a.play.count == 1, b.play.count == 1 {
      return stronger(a.play, b.play)
    }
    if a.control != b.control { return !a.control }
    if a.play.count != b.play.count { return a.play.count > b.play.count }
    if short { return stronger(a.play, b.play) }
    return weaker(a.play, b.play)
  }

  // MARK: - Follow

  static func follow(_ options: [Choice], _ counts: [Int], _ table: Play, handCount: Int) -> Play? {
    if let sweep = shed(options.filter(\.restSweeps)) { return sweep }
    let oneLeft = counts.contains(1)
    if counts.contains(table.count) || oneLeft {
      if let lock = shed(options.filter(\.unbeatable)) { return lock }
      if counts.contains(table.count) {
        return options.min { stronger($0.play, $1.play) }?.play
      }
    }
    if let free = shed(options.filter { $0.damage == 0 && !$0.control }) { return free }
    // Breaking one pair still sheds a card. Passing here is how a lead runs away.
    if let cracked = shed(options.filter { $0.damage <= 1 && !$0.control }) { return cracked }
    let short = counts.contains { $0 <= 2 }
    let high = tableIsHigh(table)
    if short || high || oneLeft || handCount <= 2 {
      if let clean = shed(options.filter { $0.damage == 0 }) { return clean }
      if short || oneLeft || handCount <= 2 { return shed(options) }
    }
    // A spare two can buy the lead; the last two cannot, unless a rule above said so.
    let spare = options.filter { $0.spareTwo }
    return shed(spare)
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
    return false
  }
}

// MARK: - Plan

/// Fewest legal plays that partition the hand. 13 cards → 8192 subsets.
struct Choice {
  let play: Play
  let damage: Int
  let unbeatable: Bool
  let control: Bool
  let restSweeps: Bool
  /// Unbeatable, and every play after it is too, so the lead empties the hand.
  var opensSweep: Bool { unbeatable && restSweeps }
  /// Spending this two still leaves a two or a bomb.
  let spareTwo: Bool
}

private struct Planner {
  let full: Int
  let dp: [Int]
  let sweep: [Bool]
  private let tagged: [Tagged]

  struct Tagged {
    let mask: Int
    let play: Play
    let unbeatable: Bool
    let control: Bool
  }

  init(hand: [Card], rules: RuleSet, unseen: [Card], maxHold: Int) {
    let cards = hand.sorted()
    let n = cards.count
    let full = n == 0 ? 0 : (1 << n) - 1
    self.full = full
    let reader = Reader(cards: unseen, maxHold: maxHold, rules: rules)
    var found: [Tagged] = []
    for size in [1, 2, 3, 5] where size <= n {
      for combo in PlayFinder.combinations(Array(0..<n), size) {
        let taken = combo.map { cards[$0] }
        guard let play = Play(taken, rules: rules) else { continue }
        let mask = combo.reduce(0) { $0 | (1 << $1) }
        found.append(Tagged(mask: mask, play: play,
                            unbeatable: !reader.canBeat(play),
                            control: StrongBot.isControl(play)))
      }
    }
    tagged = found

    var dp = Array(repeating: n + 1, count: full + 1)
    var sweep = Array(repeating: false, count: full + 1)
    dp[0] = 0
    sweep[0] = true
    if full > 0 {
      for mask in 1...full {
        for play in found where mask & play.mask == play.mask {
          let rest = mask ^ play.mask
          if dp[rest] + 1 < dp[mask] { dp[mask] = dp[rest] + 1 }
          if play.unbeatable && sweep[rest] { sweep[mask] = true }
        }
      }
    }
    self.dp = dp
    self.sweep = sweep
  }

  func choices(beating table: Play?, mustInclude: Card?) -> [Choice] {
    let base = dp[full]
    return tagged.compactMap { tag in
      if let must = mustInclude, !tag.play.cards.contains(must) { return nil }
      if let table, !tag.play.beats(table) { return nil }
      let rest = full ^ tag.mask
      let spareTwo = tag.control && !tag.play.kind.isBomb && tagged.contains {
        $0.control && rest & $0.mask == $0.mask
      }
      return Choice(play: tag.play,
                    damage: dp[rest] - (base - 1),
                    unbeatable: tag.unbeatable,
                    control: tag.control,
                    restSweeps: sweep[rest],
                    spareTwo: spareTwo)
    }
  }
}

// MARK: - Cards still out

/// Worst case: one opponent holds any subset of the unseen cards up to `maxHold`.
private struct Reader {
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

  static let windows: [[Rank]] = [
    [.ace, .two, .three, .four, .five],
    [.two, .three, .four, .five, .six],
    [.three, .four, .five, .six, .seven],
    [.four, .five, .six, .seven, .eight],
    [.five, .six, .seven, .eight, .nine],
    [.six, .seven, .eight, .nine, .ten],
    [.seven, .eight, .nine, .ten, .jack],
    [.eight, .nine, .ten, .jack, .queen],
    [.nine, .ten, .jack, .queen, .king],
    [.ten, .jack, .queen, .king, .ace],
  ]

  /// A2345 is topped by the five. Every other window is topped by its last rank.
  static func top(of window: [Rank]) -> Rank {
    if window.first == .ace, window.dropFirst().first == .two { return .five }
    return window.last ?? .ace
  }
}

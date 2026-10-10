//
//  Belief.swift
//  BigTwoKit — what Expert thinks the other three are holding.
//
//  Strong asks `Reader` one question: could *any* unseen card beat this? That is the
//  worst case, and it is most of why a human wins trick after trick with a king — the
//  bot never works out that the kings are already gone, or that the seat who passed on
//  a jack cannot have anything above one.
//
//  Same public information as Strong, read properly: cards left (`left: N`), cards
//  already played, and every pass this deal (`BotContext.history`). No hole cards —
//  `ignoresOtherPlayersHoleCards` covers Expert too.
//
//  ⚠️ Closed form, no sampling. A seeded sample would still be reproducible, but this
//  runs on every turn on a watch, and marginals are what the policy actually reads.
//

import Foundation

struct Belief {

  /// How much a pass counts against holding a card that would have beaten it.
  /// ⚠️ A pass is not proof. This bot's own `defend` gear passes on a five while
  /// holding a king (`weakHandDoesNotJumpALowCardWithItsKing`), and an autopass looks
  /// exactly the same from the outside — so the evidence is weighted, never applied
  /// as a rule.
  static let passedOnSingle = 0.30
  static let passedOnGroup = 0.60
  /// Below this a seat is treated as not holding the card at all, for the five-card
  /// `Reader`s. Three opponents put an unremarkable card at about a third.
  static let plausible = 0.10
  /// A single this likely to hold the lead is a stopper worth keeping; anything below
  /// is spare. ⚠️ A single's survival is close to 0 or close to 1 — every unseen card
  /// is in *somebody's* hand, so "can anyone beat it" barely has a middle — and the
  /// duels came out the same anywhere from 0.25 to 0.80. Nothing here is fitted.
  static let worthKeeping = 0.5

  let seat: Int
  let rules: RuleSet
  /// Cards left, by seat — `left: N`, which the table shows.
  let counts: [Int]
  /// Ascending by `Card.id`.
  let unseen: [Card]
  let others: [Int]

  /// `holds[seat][card.id]`. Our own row is zero.
  private let holds: [[Double]]
  /// `safeAbove[seat][k]` — the chance `seat` holds none of `unseen[k...]`.
  private let safeAbove: [[Double]]
  /// First index into `unseen` holding a card above this `id`.
  private let aboveIndex: [Int]
  private let byRank: [[Card]]
  /// One per seat, over the cards that seat can plausibly hold — five-card plays are
  /// answered the way Strong answers them, but against three narrower hands.
  private let readers: [Reader?]

  init(_ c: BotContext) {
    seat = c.seat
    rules = c.rules
    let counts = c.hands.map(\.count)
    self.counts = counts
    let unseen = StrongBot.unseenCards(c)
    self.unseen = unseen
    let others = c.hands.indices.filter { $0 != c.seat && c.hands[$0].count > 0 }
    self.others = others

    var holds = Array(repeating: Array(repeating: 0.0, count: 52), count: c.hands.count)
    for o in others {
      for card in unseen { holds[o][card.id] = 1 }
    }
    Belief.applyPasses(c.history, seat: c.seat, unseen: unseen, to: &holds)
    Belief.balance(&holds, counts: counts, others: others, unseen: unseen)
    self.holds = holds

    var safe = Array(repeating: [Double](), count: c.hands.count)
    for o in others {
      var suffix = Array(repeating: 1.0, count: unseen.count + 1)
      for k in stride(from: unseen.count - 1, through: 0, by: -1) {
        suffix[k] = suffix[k + 1] * (1 - holds[o][unseen[k].id])
      }
      safe[o] = suffix
    }
    safeAbove = safe

    // `unseen` is ascending, so walking it backwards leaves each id pointing at the
    // first unseen card above it.
    var above = Array(repeating: unseen.count, count: 52)
    for (k, card) in unseen.enumerated().reversed() {
      for id in 0..<card.id { above[id] = k }
    }
    aboveIndex = above

    var ranks = Array(repeating: [Card](), count: Rank.allCases.count)
    for card in unseen { ranks[card.rank.rawValue].append(card) }
    byRank = ranks

    var built = Array(repeating: Reader?.none, count: c.hands.count)
    for o in others {
      let likely = unseen.filter { holds[o][$0.id] >= Belief.plausible }
      built[o] = Reader(cards: likely, maxHold: counts[o], rules: c.rules)
    }
    readers = built
  }

  // MARK: - Reading the deal

  /// The chance seat `o` can beat this play.
  ///
  /// ⚠️ This, not `survival`, is what the reading is *for*. `Reader` asks whether any
  /// unseen card beats a play, which quietly lets one seat hold all thirty-nine of
  /// them — and the answer is almost always yes, so Strong learns nothing from it
  /// until the very end of a deal. Asked of **one** seat, with the number of cards
  /// that seat actually holds, it is a real number: a seat down to its last card can
  /// beat a jack about a quarter of the time, and that is a lead worth making.
  func answerChance(_ play: Play, from o: Int) -> Double {
    guard counts[o] > 0 else { return 0 }
    switch play.count {
    case 1:
      guard let card = play.cards.first else { return 0 }
      return 1 - safeAbove[o][aboveIndex[card.id]]
    case 2, 3:
      return 1 - groupSurvival(play, o)
    default:
      // Five-card hands stay a yes/no question, as they are for Strong — but asked of
      // each seat's plausible holding instead of every card nobody has seen.
      return readers[o]?.canBeat(play) == true ? 1 : 0
    }
  }

  /// The chance this play is still on the table when the turn comes back.
  func survival(of play: Play) -> Double {
    others.reduce(1.0) { $0 * (1 - answerChance(play, from: $1)) }
  }

  /// The chance seat `o` cannot answer this pair or triple.
  private func groupSurvival(_ play: Play, _ o: Int) -> Double {
    guard let rank = play.cards.first?.rank else { return 1 }
    var safe = 1.0
    for higher in Rank.allCases where higher > rank {
      let group = byRank[higher.rawValue]
      guard group.count >= play.count else { continue }
      safe *= 1 - atLeast(play.count, of: group, o)
    }
    // The very rank on the table, beaten on suit — rare, and `Reader` counts it too.
    let same = byRank[rank.rawValue]
    if same.count >= play.count,
       Play(Array(same.suffix(play.count)), rules: rules)?.beats(play) == true {
      safe *= 1 - atLeast(play.count, of: same, o)
    }
    return safe
  }

  /// Poisson binomial over at most four cards — the chance seat `o` holds `n` of them.
  private func atLeast(_ n: Int, of group: [Card], _ o: Int) -> Double {
    var distribution = [1.0]
    for card in group {
      let p = holds[o][card.id]
      var next = Array(repeating: 0.0, count: distribution.count + 1)
      for (held, chance) in distribution.enumerated() {
        next[held] += chance * (1 - p)
        next[held + 1] += chance * p
      }
      distribution = next
    }
    return distribution.enumerated().reduce(0.0) { $1.offset >= n ? $0 + $1.element : $0 }
  }

  // MARK: - Building it

  /// A seat that passed probably could not answer — unless it later showed a card that
  /// says otherwise, in which case the pass was a choice and tells us nothing.
  private static func applyPasses(_ history: [PublicAction], seat: Int, unseen: [Card],
                                  to holds: inout [[Double]]) {
    var table: Play?
    var passes = 0
    var events: [(seat: Int, target: Play, at: Int)] = []
    for (index, action) in history.enumerated() {
      switch action {
      case .played(_, let play):
        table = play
        passes = 0
      case .passed(let who):
        if let table, who != seat { events.append((who, table, index)) }
        passes += 1
        if passes >= 3 { table = nil; passes = 0 }  // the trick ended, as in `BigTwoGame`
      }
    }

    for event in events {
      guard !shown(history, after: event.at, by: event.seat, beating: event.target) else {
        continue
      }
      switch event.target.count {
      case 1:
        guard let card = event.target.cards.first else { break }
        for other in unseen where other.id > card.id {
          holds[event.seat][other.id] *= passedOnSingle
        }
      case 2, 3:
        guard let rank = event.target.cards.first?.rank else { break }
        for other in unseen where other.rank > rank {
          holds[event.seat][other.id] *= passedOnGroup
        }
      default:
        break  // five cards say too little about any one card to be worth weighting
      }
    }
  }

  private static func shown(_ history: [PublicAction], after index: Int, by seat: Int,
                            beating target: Play) -> Bool {
    for action in history.dropFirst(index + 1) {
      guard case .played(let who, let play) = action, who == seat else { continue }
      if target.count == 1, let card = target.cards.first,
         play.cards.contains(where: { $0.id > card.id }) { return true }
      if play.count == target.count, play.beats(target) { return true }
    }
    return false
  }

  /// Sinkhorn: every unseen card is in exactly one hand, and every hand holds exactly
  /// `left: N` of them. Alternating the two scalings turns the weights into something
  /// that satisfies both. Ends on a card pass so no card adds up to more than one.
  private static func balance(_ holds: inout [[Double]], counts: [Int],
                              others: [Int], unseen: [Card]) {
    guard !others.isEmpty else { return }
    for round in 0...16 {
      for card in unseen {
        let total = others.reduce(0.0) { $0 + holds[$1][card.id] }
        if total <= 0 {
          for o in others { holds[o][card.id] = 1 / Double(others.count) }
        } else {
          for o in others { holds[o][card.id] /= total }
        }
      }
      guard round < 16 else { break }
      for o in others {
        let total = unseen.reduce(0.0) { $0 + holds[o][$1.id] }
        guard total > 0 else { continue }
        let scale = Double(counts[o]) / total
        for card in unseen { holds[o][card.id] = min(1, holds[o][card.id] * scale) }
      }
    }
  }

  /// For the tests: how likely `seat` is to be holding this card.
  func chance(_ card: Card, at seat: Int) -> Double { holds[seat][card.id] }
}

//
//  BotPlayer.swift
//  BigTwoKit — Adam, Carl and Dean, playing the way the Palm bots did.
//
//  Reimplemented from a description of the Palm v2.2.9 bots' behaviour — not from their
//  code, which is GPL (see CLAUDE.md § Original source). No search: a fixed order of
//  "cheapest play of this kind", after setting aside the cards the bot wants to keep.
//

import Foundation

/// Everything a bot looks at. Like the Palm bots it sees every hand — they peeked.
public struct BotContext: Sendable {
  public let seat: Int
  public let hands: [[Card]]
  public let isHuman: [Bool]
  public let table: Play?
  public let tableOwner: Int?
  public let mustInclude: Card?
  public let rules: RuleSet
  /// Re-rolled every deal: guard every five-card hand (true) or only straights and pairs.
  public let prefersFiveCards: Bool
  /// Cards already played this deal. Public — the tracker shows them. Not hole cards.
  public let discarded: [Card]

  public init(seat: Int, hands: [[Card]], isHuman: [Bool], table: Play?, tableOwner: Int?,
              mustInclude: Card?, rules: RuleSet, prefersFiveCards: Bool,
              discarded: [Card] = []) {
    self.seat = seat
    self.hands = hands
    self.isHuman = isHuman
    self.table = table
    self.tableOwner = tableOwner
    self.mustInclude = mustInclude
    self.rules = rules
    self.prefersFiveCards = prefersFiveCards
    self.discarded = discarded
  }

  var hand: [Card] { hands[seat] }
  var leading: Bool { table == nil }
  var next: Int { (seat + 1) % hands.count }
  /// Somebody — the bot included — is down to two cards: stop saving anything.
  var nearWin: Bool { hands.contains { $0.count < 3 } }
  var lastCard: Bool { hands.contains { $0.count == 1 } }
  var humanCounts: [Int] { hands.indices.filter { isHuman[$0] }.map { hands[$0].count } }
}

public enum BotPlayer {

  public static func choose(_ c: BotContext) -> Play? {
    guard let table = c.table else { return lead(c) }
    switch table.count {
    case 5: return five(c)
    case 3: return triple(c)
    case 2: return pair(c)
    default: return single(c)
    }
  }

  /// Five, three, two, one — but a human on two cards gets a single before a pair.
  static func lead(_ c: BotContext) -> Play? {
    let order: [(BotContext) -> Play?] = c.humanCounts.contains(2)
      ? [five, triple, single, pair]
      : [five, triple, pair, single]
    for pick in order {
      if let play = pick(c) { return play }
    }
    return nil
  }

  // MARK: - Five cards

  static func five(_ c: BotContext) -> Play? {
    let hand = c.hand
    guard hand.count >= 5 else { return nil }
    let all = Fives(hand, c)
    var keepStraights: Fives {
      Fives(removing(protectedFives(in: hand, c, straightsOnly: true), from: hand), c)
    }
    let flushes = c.prefersFiveCards ? all : Fives(removingLowGroups(hand), c)

    let steps: [(PlayKind, Fives)]
    switch c.table?.kind {
    case nil:
      steps = [(.straightFlush, all), (.straight, all), (.fourOfAKind, all),
               (.fullHouse, all), (.flush, flushes)]
    case .straight?:
      steps = [(.straight, all), (.straightFlush, all), (.fourOfAKind, all),
               (.fullHouse, all), (.flush, flushes)]
    case .flush?:
      let kept = keepStraights
      steps = [(.straightFlush, all), (.fourOfAKind, kept), (.fullHouse, kept),
               (.flush, kept), (.fourOfAKind, all), (.fullHouse, all), (.flush, flushes)]
    case .fullHouse?:
      let kept = keepStraights
      steps = [(.straightFlush, all), (.fourOfAKind, kept), (.fullHouse, kept),
               (.fourOfAKind, all), (.fullHouse, all)]
    case .fourOfAKind?:
      steps = [(.straightFlush, all), (.fourOfAKind, keepStraights), (.fourOfAKind, all)]
    default:
      steps = [(.straightFlush, all)]
    }
    for (kind, pool) in steps {
      if let play = pool.cheapest(kind) { return play }
    }
    return nil
  }

  /// The five-card plays in one pool of cards, enumerated once and asked by kind.
  struct Fives {
    let pool: [Card]
    let plays: [Play]
    let context: BotContext

    init(_ pool: [Card], _ c: BotContext, answering: Bool = true) {
      self.pool = pool
      context = c
      plays = PlayFinder.plays(in: pool, beating: answering ? c.table : nil, rules: c.rules,
                               mustInclude: answering ? c.mustInclude : nil, size: 5)
    }

    func cheapest(_ kind: PlayKind) -> Play? {
      // Never spend aces or 2s on a full house or four of a kind — until the end is near.
      let sparesTop = (kind == .fourOfAKind || kind == .fullHouse) && !context.nearWin
      return plays.filter {
        $0.kind == kind
          && !(sparesTop && $0.cards.contains { $0.rank >= .ace })
          && (kind != .straight || keepsPairs($0, within: pool, context))
      }
      .min(by: cheaper)
    }
  }

  /// A straight may not break up two or more pairs (or any four) among its ranks; a
  /// pair-minded bot won't break any pair for a straight from 9 up. A2345/23456 only
  /// count the 3-6 part, and tolerate one pair.
  static func keepsPairs(_ straight: Play, within pool: [Card], _ c: BotContext) -> Bool {
    let low = straight.cards.contains { $0.rank == .two }
    let span = Set(straight.cards.map(\.rank)).subtracting(low ? [.ace, .two] : [])
    let groups = Dictionary(grouping: pool.filter { span.contains($0.rank) }, by: \.rank)
      .values.map(\.count).filter { $0 >= 2 }
    if low { return groups.allSatisfy { $0 == 2 } && groups.count < 2 }
    if groups.contains(4) || groups.count >= 2 { return false }
    if !c.prefersFiveCards, let bottom = straight.cards.first, bottom.rank >= .nine {
      return groups.isEmpty
    }
    return true
  }

  /// Cheapest first; among straights, those without a 2 (so 34567 goes before A2345).
  static func cheaper(_ a: Play, _ b: Play) -> Bool {
    let a2 = a.cards.contains { $0.rank == .two }, b2 = b.cards.contains { $0.rank == .two }
    if a.kind == .straight && b.kind == .straight && a2 != b2 { return !a2 }
    if a.strength != b.strength { return a.strength < b.strength }
    return a.cards.map(\.id).reduce(0, +) < b.cards.map(\.id).reduce(0, +)
  }

  /// The five-card hands a bot sets aside before looking for pairs or singles, found
  /// cheapest-first and removed one at a time.
  static func protectedFives(in pool: [Card], _ c: BotContext, straightsOnly: Bool) -> [Card] {
    let kinds: [PlayKind] = straightsOnly
      ? [.straightFlush, .straight]
      : [.straightFlush, .straight, .fourOfAKind, .fullHouse, .flush]
    var rest = pool
    var kept: [Card] = []
    while rest.count >= 5 {
      let fives = Fives(rest, c, answering: false)
      guard let hand = kinds.lazy.compactMap({ fives.cheapest($0) }).first else { break }
      kept += hand.cards
      rest = removing(hand.cards, from: rest)
    }
    return kept
  }

  // MARK: - Three, two, one

  static func triple(_ c: BotContext) -> Play? {
    var pool = c.hand
    if pool.count > 4 { pool.removeAll { $0.rank == .two } }
    return answers(from: pool, size: 3, c).min(by: cheaper)
  }

  static func pair(_ c: BotContext) -> Play? {
    if c.nearWin {
      // Biggest pair or nothing: if it can't win the trick, a smaller one can't either.
      let pairs = PlayFinder.plays(in: c.hand, rules: c.rules, mustInclude: c.mustInclude, size: 2)
      guard let biggest = pairs.max(by: cheaper) else { return nil }
      if let table = c.table, !biggest.beats(table) { return nil }
      return biggest
    }
    var pool = c.hand
    if pool.count > 2 { pool.removeAll { $0.rank == .two } }
    if !c.leading {
      pool = removing(protectedFives(in: pool, c, straightsOnly: !c.prefersFiveCards), from: pool)
    }
    return answers(from: pool, size: 2, c).min(by: cheaper)
  }

  static func single(_ c: BotContext) -> Play? {
    guard let top = c.hand.max() else { return nil }
    let others = c.hands.indices.filter { $0 != c.seat }

    // Two cards or fewer and the top one can't be beaten by anyone: take the trick.
    if c.hand.count <= 2,
       others.allSatisfy({ c.hands[$0].max().map { top > $0 } ?? true }),
       let play = playable(top, c) {
      return play
    }

    if c.lastCard {
      // Block with the top card when the next player — or a human the next player can't
      // stop — is on one card. Otherwise shed the smallest card that works.
      let nextTop = c.hands[c.next].max()
      let humanGetsThrough = c.hands.indices.contains { seat in
        guard c.isHuman[seat], c.hands[seat].count == 1, let last = c.hands[seat].first else {
          return false
        }
        return nextTop.map { last > $0 } ?? true
      }
      if c.hands[c.next].count == 1 || humanGetsThrough { return playable(top, c) }
      return answers(from: c.hand, size: 1, c).first
    }

    if let table = c.table, let owner = c.tableOwner, !c.isHuman[owner],
       let card = table.cards.first, card.rank > .queen {
      return nil  // a fellow bot's K, A or 2 stands
    }

    var pool = c.hand
    if !c.leading && c.humanCounts.allSatisfy({ $0 > 3 }) {
      pool = removing(protectedFives(in: pool, c, straightsOnly: !c.prefersFiveCards), from: pool)
      pool = removingLowGroups(pool)
    }
    return answers(from: pool, size: 1, c).first
  }

  // MARK: - Helpers

  static func answers(from pool: [Card], size: Int, _ c: BotContext) -> [Play] {
    PlayFinder.plays(in: pool, beating: c.table, rules: c.rules, mustInclude: c.mustInclude,
                     size: size)
  }

  static func playable(_ card: Card, _ c: BotContext) -> Play? {
    if let must = c.mustInclude, card != must { return nil }
    guard let play = Play([card], rules: c.rules) else { return nil }
    if let table = c.table, !play.beats(table) { return nil }
    return play
  }

  /// Drops every pair, triple and four below the king.
  static func removingLowGroups(_ cards: [Card]) -> [Card] {
    let counts = Dictionary(grouping: cards, by: \.rank).mapValues(\.count)
    return cards.filter { $0.rank > .queen || counts[$0.rank, default: 0] < 2 }
  }

  static func removing(_ taken: [Card], from cards: [Card]) -> [Card] {
    let set = Set(taken)
    return cards.filter { !set.contains($0) }
  }
}

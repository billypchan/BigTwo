//
//  CardSet.swift
//  BigTwoKit — a hand as 52 bits, and a move generator over it.
//
//  `Card.id` is rank * 4 + suit, so it is both 0…51 and the one Big Two ordering:
//  a hand is a `UInt64`, and the highest card is the highest set bit. Nothing is
//  sorted and no `[Card]` is built until a move is handed back.
//
//  ⚠️ The rules live in `Play.swift` and only there. This file is a faster way to
//  ask the same question — "what can this hand play?" — and `MoveGenTests` checks
//  every move it makes, on random hands, against `PlayFinder`. If the two ever
//  disagree, `PlayFinder` is right.
//

import Foundation

/// A set of cards as one machine word.
struct CardSet: Equatable, Hashable, Sendable {
  private(set) var bits: UInt64

  init(bits: UInt64 = 0) { self.bits = bits }

  init<S: Sequence>(_ cards: S) where S.Element == Card {
    bits = cards.reduce(0) { $0 | CardSet.bit($1.id) }
  }

  var count: Int { bits.nonzeroBitCount }
  var isEmpty: Bool { bits == 0 }

  func contains(_ card: Card) -> Bool { bits & Self.bit(card.id) != 0 }
  func subtracting(_ other: CardSet) -> CardSet { CardSet(bits: bits & ~other.bits) }

  mutating func insert(_ card: Card) { bits |= Self.bit(card.id) }
  mutating func remove(_ card: Card) { bits &= ~Self.bit(card.id) }
  mutating func subtract(_ mask: UInt64) { bits &= ~mask }

  /// Ascending — deck order, which is also ranking order.
  var cards: [Card] { Self.cards(of: bits) }

  static func bit(_ id: Int) -> UInt64 { 1 << UInt64(id) }

  static func cards(of bits: UInt64) -> [Card] {
    var out: [Card] = []
    out.reserveCapacity(bits.nonzeroBitCount)
    var rest = bits
    while rest != 0 {
      out.append(Card.deck[rest.trailingZeroBitCount])  // deck is indexed by `id`
      rest &= rest - 1
    }
    return out
  }

  /// The four cards of each rank, and the thirteen of each suit.
  static let rankMasks: [UInt64] = (0..<Rank.allCases.count).map { 0xF << UInt64($0 * 4) }
  static let suitMasks: [UInt64] = (0..<Suit.allCases.count).map { suit in
    (0..<Rank.allCases.count).reduce(UInt64(0)) { $0 | bit($1 * 4 + suit) }
  }
}

// MARK: - A play, without the `Play`

/// What `MoveGen` hands back: the cards as a mask, plus the kind and strength
/// `Play` would have worked out for them.
struct Move: Equatable, Sendable {
  let mask: UInt64
  let kind: PlayKind
  let strength: Int

  var count: Int { kind.cardCount }
  var cards: [Card] { CardSet.cards(of: mask) }
  var play: Play { Play(trusted: cards, kind: kind, strength: strength) }
}

/// The play on the table, reduced to what deciding "does this beat it?" needs.
struct MoveTarget: Equatable, Sendable {
  let count: Int
  let kind: PlayKind
  let strength: Int

  init(count: Int, kind: PlayKind, strength: Int) {
    self.count = count
    self.kind = kind
    self.strength = strength
  }

  init(_ play: Play) {
    self.init(count: play.count, kind: play.kind, strength: play.strength)
  }

  init(_ move: Move) {
    self.init(count: move.count, kind: move.kind, strength: move.strength)
  }

  /// The same test as `Play.beats`, without building either `Play`.
  func beaten(by kind: PlayKind, _ strength: Int) -> Bool {
    if count == 5 && kind != self.kind { return kind > self.kind }
    return strength > self.strength
  }
}

// MARK: - Generating moves

enum MoveGen {

  /// Every legal play in `hand`, in generation order (by size, then by kind).
  /// `beating` restricts it to answers for the turn, `mustInclude` to the opening 3♦.
  static func moves(in hand: CardSet, beating target: MoveTarget? = nil,
                    rules: RuleSet = .standard, mustInclude: Card? = nil) -> [Move] {
    var out: [Move] = []
    out.reserveCapacity(64)
    let must: UInt64 = mustInclude.map { CardSet.bit($0.id) } ?? 0

    func emit(_ mask: UInt64, _ kind: PlayKind, _ strength: Int) {
      if must != 0, mask & must == 0 { return }
      if let target, !target.beaten(by: kind, strength) { return }
      out.append(Move(mask: mask, kind: kind, strength: strength))
    }

    let sizes = target.map { [$0.count] } ?? [1, 2, 3, 5]
    for size in sizes where size <= hand.count {
      switch size {
      case 1: singles(hand, emit)
      case 2: sameRank(hand, 2, .pair, emit)
      case 3: sameRank(hand, 3, .triple, emit)
      case 5: fives(hand, rules, emit)
      default: break
      }
    }
    return out
  }

  /// True if `hand` holds anything that beats `target`. Stops at the first answer —
  /// autopass asks this for every seat on every turn.
  static func canBeat(_ target: MoveTarget, in hand: CardSet, rules: RuleSet) -> Bool {
    !moves(in: hand, beating: target, rules: rules).isEmpty
  }

  /// `PlayFinder.combinations` walks index tuples lexicographically, and `min(by:)`
  /// keeps the first of several equal candidates — so the order plays arrive in can
  /// decide which of two equally good ones a bot picks. Sorting generated moves back
  /// into that order is what makes swapping the generator in invisible.
  static func lexBefore(_ a: Move, _ b: Move) -> Bool {
    if a.count != b.count { return a.count < b.count }
    let diff = a.mask ^ b.mask
    guard diff != 0 else { return false }
    return a.mask & (diff & (0 &- diff)) != 0  // whoever owns the lowest differing card
  }

  // MARK: Sizes 1, 2 and 3

  private static func singles(_ hand: CardSet, _ emit: (UInt64, PlayKind, Int) -> Void) {
    var rest = hand.bits
    while rest != 0 {
      let id = rest.trailingZeroBitCount
      emit(CardSet.bit(id), .single, id)  // a single is ranked by the card itself
      rest &= rest - 1
    }
  }

  /// Pairs and triples: rank first, then the highest suit present — which is just
  /// the highest `id` in the mask.
  private static func sameRank(_ hand: CardSet, _ size: Int, _ kind: PlayKind,
                               _ emit: (UInt64, PlayKind, Int) -> Void) {
    for rank in 0..<Rank.allCases.count {
      let group = hand.bits & CardSet.rankMasks[rank]
      guard group.nonzeroBitCount >= size else { continue }
      subsets(group, size) { emit($0, kind, top(of: $0)) }
    }
  }

  // MARK: Size 5

  private static func fives(_ hand: CardSet, _ rules: RuleSet,
                            _ emit: (UInt64, PlayKind, Int) -> Void) {
    quads(hand, emit)
    fullHouses(hand, emit)
    straights(hand, rules, emit)  // also every straight flush
    flushes(hand, emit)
  }

  private static func quads(_ hand: CardSet, _ emit: (UInt64, PlayKind, Int) -> Void) {
    for rank in 0..<Rank.allCases.count {
      let group = hand.bits & CardSet.rankMasks[rank]
      guard group.nonzeroBitCount == 4 else { continue }
      subsets(hand.bits & ~group, 1) { emit(group | $0, .fourOfAKind, rank) }
    }
  }

  private static func fullHouses(_ hand: CardSet, _ emit: (UInt64, PlayKind, Int) -> Void) {
    for triple in 0..<Rank.allCases.count {
      let three = hand.bits & CardSet.rankMasks[triple]
      guard three.nonzeroBitCount >= 3 else { continue }
      for pair in 0..<Rank.allCases.count where pair != triple {
        let two = hand.bits & CardSet.rankMasks[pair]
        guard two.nonzeroBitCount >= 2 else { continue }
        subsets(three, 3) { trips in
          subsets(two, 2) { emit(trips | $0, .fullHouse, triple) }  // ranked by the triple
        }
      }
    }
  }

  /// One pass for both: five suited cards in sequence are a straight flush, and
  /// `Play.evaluateFive` reads a straight before it reads a flush.
  private static func straights(_ hand: CardSet, _ rules: RuleSet,
                                _ emit: (UInt64, PlayKind, Int) -> Void) {
    for window in windows {
      var groups: [UInt64] = []
      groups.reserveCapacity(5)
      for rank in window.ranks {
        let group = hand.bits & CardSet.rankMasks[rank]
        if group == 0 { break }
        groups.append(group)
      }
      guard groups.count == 5 else { continue }
      let sequence = rules.hongKong && window.sequence == 1 ? 10 : window.sequence
      combine(groups, 0, 0) { mask in
        let topSuit = top(of: mask & CardSet.rankMasks[window.top]) % 4
        let suited = Suit.allCases.contains { mask & CardSet.suitMasks[$0.rawValue] == mask }
        emit(mask, suited ? .straightFlush : .straight, sequence * 4 + topSuit)
      }
    }
  }

  private static func flushes(_ hand: CardSet, _ emit: (UInt64, PlayKind, Int) -> Void) {
    for suit in 0..<Suit.allCases.count {
      let suited = hand.bits & CardSet.suitMasks[suit]
      guard suited.nonzeroBitCount >= 5 else { continue }
      subsets(suited, 5) { mask in
        guard !isSequence(mask) else { return }  // already emitted as a straight flush
        emit(mask, .flush, top(of: mask))  // ranked by the highest card: rank, then suit
      }
    }
  }

  // MARK: Bit walking

  /// Every `size`-card subset of `bits`, lowest card first — the order
  /// `PlayFinder.combinations` would have produced.
  private static func subsets(_ bits: UInt64, _ size: Int, _ body: (UInt64) -> Void) {
    if size == 0 { body(0); return }
    var rest = bits
    while rest.nonzeroBitCount >= size {
      let low = CardSet.bit(rest.trailingZeroBitCount)
      rest &= rest - 1
      subsets(rest, size - 1) { body(low | $0) }
    }
  }

  /// One card from each group — the suit choices for a straight.
  private static func combine(_ groups: [UInt64], _ level: Int, _ mask: UInt64,
                              _ body: (UInt64) -> Void) {
    guard level < groups.count else { return body(mask) }
    var rest = groups[level]
    while rest != 0 {
      combine(groups, level + 1, mask | CardSet.bit(rest.trailingZeroBitCount), body)
      rest &= rest - 1
    }
  }

  private static func top(of mask: UInt64) -> Int { 63 - mask.leadingZeroBitCount }

  private static func isSequence(_ mask: UInt64) -> Bool {
    var ranks: UInt16 = 0
    var rest = mask
    while rest != 0 {
      ranks |= 1 << UInt16(rest.trailingZeroBitCount / 4)
      rest &= rest - 1
    }
    return windowRanks.contains(ranks)
  }

  // MARK: The ten straights

  struct Window {
    let ranks: [Int]
    /// The rank that ranks the straight — the five in A2345, the last rank otherwise.
    let top: Int
    /// 0 = A2345 … 9 = TJQKA. Hong Kong lifts 23456 to 10.
    let sequence: Int
  }

  /// Lowest first: A2345 < 23456 < … < TJQKA. `Reader` reads the same table.
  static let straightRanks: [[Rank]] = [
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

  /// A2345 is topped by its five, every other window by its last rank.
  static func topRank(of window: [Rank]) -> Rank {
    if window.first == .ace, window.dropFirst().first == .two { return .five }
    return window.last ?? .ace
  }

  static let windows: [Window] = straightRanks.enumerated().map { sequence, ranks in
    Window(ranks: ranks.map(\.rawValue), top: topRank(of: ranks).rawValue, sequence: sequence)
  }

  private static let windowRanks: [UInt16] = straightRanks.map { ranks in
    ranks.reduce(UInt16(0)) { $0 | (1 << UInt16($1.rawValue)) }
  }
}

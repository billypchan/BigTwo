//
//  Play.swift
//  BigTwoKit — legal plays and their ranking.
//
//  A turn is 1, 2, 3 or 5 cards. Five-card hands rank:
//  straight < flush < full house < four of a kind < straight flush.
//

import Foundation

public struct RuleSet: Equatable, Codable, Sendable {
  /// Preferences → "Hong Kong Rule Set":
  ///   1. other than the first deal, the winner of the last deal leads
  ///   2. 23456 is the largest straight
  public var hongKong: Bool
  public var dealsPerGame: Int

  public init(hongKong: Bool = false, dealsPerGame: Int = 10) {
    self.hongKong = hongKong
    self.dealsPerGame = dealsPerGame
  }

  public static let standard = RuleSet()
  public static let hongKong = RuleSet(hongKong: true)
}

public enum PlayKind: Int, Comparable, CaseIterable, Sendable {
  case single, pair, triple, straight, flush, fullHouse, fourOfAKind, straightFlush

  public var cardCount: Int {
    switch self {
    case .single: return 1
    case .pair: return 2
    case .triple: return 3
    default: return 5
    }
  }

  public var name: String {
    switch self {
    case .single: return "single"
    case .pair: return "pair"
    case .triple: return "three of a kind"
    case .straight: return "straight"
    case .flush: return "flush"
    case .fullHouse: return "full house"
    case .fourOfAKind: return "four of a kind"
    case .straightFlush: return "straight flush"
    }
  }

  /// A bomb is worth hanging on to.
  public var isBomb: Bool { self == .fourOfAKind || self == .straightFlush }

  public static func < (l: PlayKind, r: PlayKind) -> Bool { l.rawValue < r.rawValue }
}

public struct Play: Equatable, Sendable {
  public let cards: [Card]  // ascending
  public let kind: PlayKind
  public let strength: Int  // only meaningful against the same kind

  public init?(_ raw: [Card], rules: RuleSet = .standard) {
    let sorted = raw.sorted()
    guard let first = sorted.first, let last = sorted.last,
          Set(sorted).count == sorted.count else { return nil }

    switch sorted.count {
    case 1:
      kind = .single
      strength = first.id
    case 2:
      guard first.rank == last.rank else { return nil }
      kind = .pair
      strength = last.id  // rank ties broken by the higher suit
    case 3:
      guard sorted.allSatisfy({ $0.rank == first.rank }) else { return nil }
      kind = .triple
      strength = last.id
    case 5:
      guard let five = Play.evaluateFive(sorted, rules: rules) else { return nil }
      kind = five.kind
      strength = five.strength
    default:
      return nil
    }
    cards = sorted
  }

  public var count: Int { cards.count }
  public var label: String { cards.map(\.label).joined(separator: " ") }

  /// Two plays only meet if they use the same number of cards.
  public func beats(_ other: Play) -> Bool {
    guard count == other.count else { return false }
    if count == 5 && kind != other.kind { return kind > other.kind }
    return strength > other.strength
  }

  // MARK: - Five-card hands

  /// `c` must be sorted ascending.
  private static func evaluateFive(_ c: [Card], rules: RuleSet) -> (kind: PlayKind, strength: Int)? {
    let counts = Dictionary(grouping: c, by: \.rank).mapValues(\.count)
    let isFlush = Set(c.map(\.suit)).count == 1

    if let quad = counts.first(where: { $0.value == 4 })?.key {
      return (.fourOfAKind, quad.rawValue)
    }
    if let triple = counts.first(where: { $0.value == 3 })?.key,
       counts.contains(where: { $0.value == 2 }) {
      return (.fullHouse, triple.rawValue)  // ranked by the triple
    }
    if let seq = straightStrength(c, rules: rules) {
      return (isFlush ? .straightFlush : .straight, seq)
    }
    if isFlush, let top = c.last {
      return (.flush, top.id)  // highest card: rank, then suit
    }
    return nil
  }

  /// Straights, ascending: A2345 < 23456 < 34567 < ... < 9TJQK < TJQKA.
  /// JQKA2 is not a straight (disallowed since v1.0).
  /// Equal sequences are separated by the suit of the highest *sequence* card,
  /// e.g. 3456(7♠) beats 3456(7♥), and A234(5♠) beats A234(5♥).
  private static func straightStrength(_ c: [Card], rules: RuleSet) -> Int? {
    var idx = c.map(\.rank.sequenceIndex).sorted()
    guard Set(idx).count == 5 else { return nil }
    let aceHigh = idx == [1, 10, 11, 12, 13]
    if aceHigh { idx = [10, 11, 12, 13, 14] }
    guard zip(idx, idx.dropFirst()).allSatisfy({ $1 == $0 + 1 }) else { return nil }

    let low = idx[0]  // 1 = A2345 ... 10 = TJQKA
    var sequence = low - 1  // 0 ... 9
    if rules.hongKong && low == 2 { sequence = 10 }  // 23456 becomes the biggest

    let top = aceHigh
      ? c.first { $0.rank == .ace }
      : c.max { $0.rank.sequenceIndex < $1.rank.sequenceIndex }
    guard let top else { return nil }
    return sequence * 4 + top.suit.rawValue
  }
}

// MARK: - Finding plays

public enum PlayFinder {

  /// Every legal play in `hand`, cheapest first (fewest cards, then weakest). Pass
  /// `beating` to restrict to answers for the current turn, `mustInclude` for the
  /// opening play of a deal (3♦), and `size` to look at one play size only.
  public static func plays(in hand: [Card],
                           beating target: Play? = nil,
                           rules: RuleSet = .standard,
                           mustInclude: Card? = nil,
                           size: Int? = nil) -> [Play] {
    var sizes = target.map { [$0.count] } ?? [1, 2, 3, 5]
    if let size { sizes = sizes.filter { $0 == size } }
    var found: [Play] = []

    for size in sizes where size <= hand.count {
      for combo in combinations(hand, size) {
        if let must = mustInclude, !combo.contains(must) { continue }
        guard let play = Play(combo, rules: rules) else { continue }
        if let target, !play.beats(target) { continue }
        found.append(play)
      }
    }
    return found.sorted {
      $0.count != $1.count ? $0.count < $1.count
        : ($0.kind != $1.kind ? $0.kind < $1.kind : $0.strength < $1.strength)
    }
  }

  /// Stops at the first answer — autopass asks this for every seat on every turn.
  public static func canBeat(_ target: Play?, with hand: [Card], rules: RuleSet) -> Bool {
    guard let target else { return !hand.isEmpty }
    return combinations(hand, target.count).contains {
      Play($0, rules: rules).map { $0.beats(target) } ?? false
    }
  }

  /// All `k`-element combinations, in index order.
  static func combinations<T>(_ items: [T], _ k: Int) -> [[T]] {
    guard k > 0 else { return [[]] }
    guard items.count >= k else { return [] }
    var result: [[T]] = []
    var index = Array(0..<k)
    while true {
      result.append(index.map { items[$0] })
      var i = k - 1
      while i >= 0 && index[i] == items.count - k + i { i -= 1 }
      if i < 0 { return result }
      index[i] += 1
      for j in (i + 1)..<k { index[j] = index[j - 1] + 1 }
    }
  }
}

//
//  Card.swift
//  BigTwoKit
//
//  Rank ordering, ascending:  3 < 4 < ... < K < A < 2
//  Suit ordering, ascending:  ♦ < ♣ < ♥ < ♠
//  So 2♠ is the highest card and 3♦ the lowest.
//

import Foundation

public enum Suit: Int, CaseIterable, Comparable, Codable, Sendable {
  case diamond = 0, club, heart, spade

  public var symbol: String { ["♦", "♣", "♥", "♠"][rawValue] }
  public var name: String { ["diamonds", "clubs", "hearts", "spades"][rawValue] }
  public var isRed: Bool { self == .diamond || self == .heart }

  public static func < (l: Suit, r: Suit) -> Bool { l.rawValue < r.rawValue }
}

public enum Rank: Int, CaseIterable, Comparable, Codable, Sendable {
  case three = 0, four, five, six, seven, eight, nine, ten, jack, queen, king, ace, two

  public var label: String {
    ["3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A", "2"][rawValue]
  }

  public var name: String {
    ["3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace", "2"][rawValue]
  }

  /// Points charged for a card left in hand at the end of a deal: 3 costs 1 … 2 costs 13.
  public var penalty: Int { rawValue + 1 }

  /// Position in a *straight*: A = 1, 2 = 2, 3 = 3 … K = 13 (the ace can also sit on the king).
  public var sequenceIndex: Int {
    switch self {
    case .ace: return 1
    case .two: return 2
    default: return rawValue + 3
    }
  }

  public static func < (l: Rank, r: Rank) -> Bool { l.rawValue < r.rawValue }
}

public struct Card: Hashable, Comparable, Codable, Identifiable, Sendable {
  public let rank: Rank
  public let suit: Suit

  public init(rank: Rank, suit: Suit) {
    self.rank = rank
    self.suit = suit
  }

  /// Rank first, then suit — the single Big Two ordering for everything.
  public var id: Int { rank.rawValue * 4 + suit.rawValue }

  public var label: String { rank.label + suit.symbol }
  public var spokenName: String { "\(rank.name) of \(suit.name)" }
  /// ASCII shorthand, e.g. "Td" for 10♦ — accessibility identifiers and test fixtures.
  public var code: String {
    ["3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A", "2"][rank.rawValue]
      + ["d", "c", "h", "s"][suit.rawValue]
  }

  public static func < (l: Card, r: Card) -> Bool { l.id < r.id }

  public static let threeOfDiamonds = Card(rank: .three, suit: .diamond)

  public static let deck: [Card] =
    Rank.allCases.flatMap { rank in Suit.allCases.map { Card(rank: rank, suit: $0) } }
}

public enum HandSort: String, CaseIterable, Sendable {
  case byRank, bySuit

  public func sorted(_ cards: [Card]) -> [Card] {
    switch self {
    case .byRank:
      return cards.sorted()
    case .bySuit:
      return cards.sorted { $0.suit == $1.suit ? $0.rank < $1.rank : $0.suit < $1.suit }
    }
  }
}

/// SplitMix64 — a fixed seed gives the same deals, for tests and screenshots.
/// ⚠️ `shuffled(using:)` is only stable within one toolchain; never persist a seed as game data.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
  private var state: UInt64

  public init(seed: UInt64) { state = seed }

  public mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}

//
//  Card.swift
//  Big Two — iOS remake of the Palm OS game (v2.2.8)
//
//  Rank ordering, ascending:  3 < 4 < ... < K < A < 2
//  Suit ordering, ascending:  ♦ < ♣ < ♥ < ♠
//  So 2♠ is the highest card and 3♦ the lowest.
//

import Foundation

enum Suit: Int, CaseIterable, Comparable, Codable {
    case diamond = 0, club, heart, spade

    var symbol: String { ["♦", "♣", "♥", "♠"][rawValue] }
    var isRed: Bool { self == .diamond || self == .heart }

    static func < (l: Suit, r: Suit) -> Bool { l.rawValue < r.rawValue }
}

enum Rank: Int, CaseIterable, Comparable, Codable {
    case three = 0, four, five, six, seven, eight, nine, ten, jack, queen, king, ace, two

    var label: String {
        ["3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A", "2"][rawValue]
    }

    /// Points charged for a card left in hand at the end of a deal:
    /// 3 costs 1, 4 costs 2, ... 2 costs 13.
    var penalty: Int { rawValue + 1 }

    /// Position in a *straight* sequence — A = 1, 2 = 2, 3 = 3, ... K = 13.
    /// (Straights run A2345 up to TJQKA; the ace can also ride on top of the king.)
    var sequenceIndex: Int {
        switch self {
        case .ace: return 1
        case .two: return 2
        default:  return rawValue + 3
        }
    }

    static func < (l: Rank, r: Rank) -> Bool { l.rawValue < r.rawValue }
}

struct Card: Hashable, Comparable, Codable, Identifiable {
    let rank: Rank
    let suit: Suit

    /// Rank first, then suit — the single Big Two ordering for everything.
    var id: Int { rank.rawValue * 4 + suit.rawValue }

    var label: String { rank.label + suit.symbol }

    static func < (l: Card, r: Card) -> Bool { l.id < r.id }

    static let threeOfDiamonds = Card(rank: .three, suit: .diamond)

    static var deck: [Card] {
        Rank.allCases.flatMap { rank in Suit.allCases.map { Card(rank: rank, suit: $0) } }
    }
}

enum HandSort: String, CaseIterable {
    case byRank, bySuit

    func sorted(_ cards: [Card]) -> [Card] {
        switch self {
        case .byRank:
            return cards.sorted()
        case .bySuit:
            return cards.sorted {
                $0.suit == $1.suit ? $0.rank < $1.rank : $0.suit < $1.suit
            }
        }
    }
}

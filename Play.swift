//
//  Play.swift
//  Big Two — legal plays and their ranking.
//
//  A turn is 1, 2, 3 or 5 cards. Five-card hands rank:
//  straight < flush < full house < four of a kind < straight flush.
//

import Foundation

struct RuleSet: Equatable, Codable {
    /// Preferences → "Hong Kong Rule Set":
    ///   1. other than the first deal, the winner of the last deal leads
    ///   2. 23456 is the largest straight
    var hongKong = false
    var dealsPerGame = 10

    static let standard = RuleSet()
    static let hongKong = RuleSet(hongKong: true)
}

enum PlayKind: Int, Comparable, CaseIterable {
    case single, pair, triple, straight, flush, fullHouse, fourOfAKind, straightFlush

    var cardCount: Int {
        switch self {
        case .single: return 1
        case .pair:   return 2
        case .triple: return 3
        default:      return 5
        }
    }

    var name: String {
        switch self {
        case .single:        return "single"
        case .pair:          return "pair"
        case .triple:        return "three of a kind"
        case .straight:      return "straight"
        case .flush:         return "flush"
        case .fullHouse:     return "full house"
        case .fourOfAKind:   return "four of a kind"
        case .straightFlush: return "straight flush"
        }
    }

    /// A bomb is worth hanging on to.
    var isBomb: Bool { self == .fourOfAKind || self == .straightFlush }

    static func < (l: PlayKind, r: PlayKind) -> Bool { l.rawValue < r.rawValue }
}

struct Play: Equatable {
    let cards: [Card]      // ascending
    let kind: PlayKind
    let strength: Int      // only meaningful against the same kind

    init?(_ raw: [Card], rules: RuleSet = .standard) {
        let sorted = raw.sorted()
        guard Set(sorted).count == sorted.count else { return nil }

        switch sorted.count {
        case 1:
            kind = .single
            strength = sorted[0].id
        case 2:
            guard sorted[0].rank == sorted[1].rank else { return nil }
            kind = .pair
            strength = sorted[1].id          // rank ties broken by the higher suit
        case 3:
            guard sorted.allSatisfy({ $0.rank == sorted[0].rank }) else { return nil }
            kind = .triple
            strength = sorted[2].id
        case 5:
            guard let five = Play.evaluateFive(sorted, rules: rules) else { return nil }
            kind = five.kind
            strength = five.strength
        default:
            return nil
        }
        self.cards = sorted
    }

    var count: Int { cards.count }
    var label: String { cards.map(\.label).joined(separator: " ") }

    /// Two plays only meet if they use the same number of cards.
    func beats(_ other: Play) -> Bool {
        guard count == other.count else { return false }
        if count == 5 && kind != other.kind { return kind > other.kind }
        return strength > other.strength
    }

    // MARK: - Five-card hands

    private static func evaluateFive(_ c: [Card], rules: RuleSet) -> (kind: PlayKind, strength: Int)? {
        let counts = Dictionary(grouping: c, by: \.rank).mapValues(\.count)
        let isFlush = Set(c.map(\.suit)).count == 1

        if let quad = counts.first(where: { $0.value == 4 })?.key {
            return (.fourOfAKind, quad.rawValue)
        }
        if let triple = counts.first(where: { $0.value == 3 })?.key,
           counts.contains(where: { $0.value == 2 }) {
            return (.fullHouse, triple.rawValue)     // ranked by the triple
        }
        if let seq = straightStrength(c, rules: rules) {
            return (isFlush ? .straightFlush : .straight, seq)
        }
        if isFlush {
            return (.flush, c.last!.id)              // highest card: rank, then suit
        }
        return nil
    }

    /// Straights, ascending: A2345 < 23456 < 34567 < ... < 9TJQK < TJQKA.
    /// JQKA2 is not a straight (disallowed since v1.0).
    /// Equal sequences are separated by the suit of the highest sequence card,
    /// e.g. 3456(7♠) beats 3456(7♥).
    private static func straightStrength(_ c: [Card], rules: RuleSet) -> Int? {
        var idx = c.map(\.rank.sequenceIndex).sorted()
        guard Set(idx).count == 5 else { return nil }
        if idx == [1, 10, 11, 12, 13] { idx = [10, 11, 12, 13, 14] }   // ace on top of the king
        guard zip(idx, idx.dropFirst()).allSatisfy({ $1 == $0 + 1 }) else { return nil }

        let low = idx[0]                    // 1 = A2345 ... 10 = TJQKA
        var sequence = low - 1              // 0 ... 9
        if rules.hongKong && low == 2 { sequence = 10 }   // 23456 becomes the biggest

        let top: Card = low == 10
            ? c.first { $0.rank == .ace }!
            : c.max { $0.rank.sequenceIndex < $1.rank.sequenceIndex }!

        return sequence * 4 + top.suit.rawValue
    }
}

// MARK: - Finding plays

enum PlayFinder {

    /// Every legal play in `hand`. Pass `beating` to restrict to answers for the
    /// current turn, and `mustInclude` for the opening play of a deal (3♦).
    static func plays(in hand: [Card],
                      beating target: Play? = nil,
                      rules: RuleSet = .standard,
                      mustInclude: Card? = nil) -> [Play] {
        let sizes = target.map { [$0.count] } ?? [1, 2, 3, 5]
        var found: [Play] = []

        for size in sizes where size <= hand.count {
            for combo in combinations(hand, size) {
                if let must = mustInclude, !combo.contains(must) { continue }
                guard let play = Play(combo, rules: rules) else { continue }
                if let target, !play.beats(target) { continue }
                found.append(play)
            }
        }
        // Cheapest first: fewest cards, weakest hand.
        return found.sorted {
            $0.count != $1.count ? $0.count < $1.count
                : ($0.kind != $1.kind ? $0.kind < $1.kind : $0.strength < $1.strength)
        }
    }

    static func canBeat(_ target: Play?, with hand: [Card], rules: RuleSet) -> Bool {
        !plays(in: hand, beating: target, rules: rules).isEmpty
    }

    static func combinations<T>(_ items: [T], _ k: Int) -> [[T]] {
        guard k > 0 else { return [[]] }
        guard items.count >= k else { return [] }
        if k == items.count { return [items] }
        var result: [[T]] = []
        for (i, item) in items.enumerated() where items.count - i >= k {
            for rest in combinations(Array(items[(i + 1)...]), k - 1) {
                result.append([item] + rest)
            }
        }
        return result
    }
}

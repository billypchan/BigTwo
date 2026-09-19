//
//  StrongBot.swift
//  BigTwoKit — a harder, fair opponent. Sees only its own hand and the public
//  counts (`left: N`). Fights every seat, including fellow bots.
//

import Foundation

public enum StrongBot {

  public static func choose(_ c: BotContext) -> Play? {
    let options = PlayFinder.plays(in: c.hand, beating: c.table, rules: c.rules,
                                   mustInclude: c.mustInclude)
    guard !options.isEmpty else { return nil }
    if let out = options.first(where: { $0.count == c.hand.count }) { return out }
    return c.leading ? lead(options, c) : follow(options, c)
  }

  // MARK: - Lead

  static func lead(_ options: [Play], _ c: BotContext) -> Play? {
    let counts = opponentCounts(c)
    let hot = counts.contains { $0 <= 2 }
    // Someone on one card can only answer a single — dump a combo first.
    if counts.contains(1) {
      for size in [5, 3, 2] {
        if let play = cheap(options, size: size, allowTwos: hot) { return play }
      }
      return options.last(where: { $0.count == 1 }) ?? options.first
    }
    // Someone on two could finish a pair — lead anything but a pair.
    let sizes = counts.contains(2) ? [5, 3, 1, 2] : [5, 3, 2, 1]
    for size in sizes {
      if let play = cheap(options, size: size, allowTwos: hot || size == 1) { return play }
    }
    return options.first
  }

  // MARK: - Follow

  static func follow(_ options: [Play], _ c: BotContext) -> Play? {
    let counts = opponentCounts(c)
    let hot = counts.contains { $0 <= 2 }
    // An opponent who has exactly this many cards might go out — contest it.
    if let table = c.table, counts.contains(table.count) {
      if table.count == 1 {
        return options.last(where: { $0.count == 1 }) ?? options.first
      }
      return cheap(options, size: table.count, allowTwos: true) ?? options.first
    }
    let shaped = shapedAnswers(options, c, allowBreak: hot)
    let spendTwos = hot || (c.table?.cards.last?.rank ?? .three) > .queen
    if let play = cheap(shaped, size: options.first?.count ?? 1, allowTwos: spendTwos) {
      return play
    }
    return hot ? options.first : nil
  }

  // MARK: - Public info only

  /// `left: N` on the table — never the cards themselves.
  static func opponentCounts(_ c: BotContext) -> [Int] {
    c.hands.indices.filter { $0 != c.seat }.map { c.hands[$0].count }
  }

  static func cheap(_ options: [Play], size: Int, allowTwos: Bool) -> Play? {
    options.first {
      $0.count == size && (allowTwos || !$0.cards.contains { $0.rank == .two })
    }
  }

  /// Drop singles that would break a pair/triple, and bombs, until someone is short.
  static func shapedAnswers(_ options: [Play], _ c: BotContext, allowBreak: Bool) -> [Play] {
    let ranks = Dictionary(grouping: c.hand, by: \.rank).mapValues(\.count)
    return options.filter { play in
      if play.kind.isBomb { return allowBreak }
      guard play.count == 1, let card = play.cards.first else { return true }
      return allowBreak || ranks[card.rank, default: 0] == 1
    }
  }
}

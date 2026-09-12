//
//  BotPlayer.swift
//  BigTwoKit — Adam, Carl and Dean.
//
//  Deliberately simple and all in one place, so it is easy to tune:
//  play the cheapest thing that works, keep bombs back, and push hard
//  once somebody is about to go out.
//

import Foundation

public enum BotPlayer {

  /// `options` must be cheapest-first, as `PlayFinder.plays` returns them.
  public static func choose(from options: [Play],
                            table: Play?,
                            hand: [Card],
                            opponentCounts: [Int]) -> Play? {
    guard !options.isEmpty else { return nil }

    let danger = opponentCounts.contains { $0 <= 2 }
    let endgame = hand.count <= 5
    let safe = options.filter { !$0.kind.isBomb }

    if table == nil {
      // Leading: shed cards. Prefer a five-card hand, then the lowest single.
      let pool = safe.isEmpty ? options : safe
      if danger, let strongest = pool.last { return strongest }
      if let five = pool.last(where: { $0.count == 5 && !$0.kind.isBomb }),
         hand.count > 5 { return five }
      return pool.first
    }

    // Answering: cheapest play that beats the table.
    if let cheap = safe.first { return cheap }

    // Only bombs left: spend one if the deal is slipping away, otherwise fold.
    return (danger || endgame) ? options.first : nil
  }
}

//
//  GreedyBot.swift
//  The app's first bot, kept as a yardstick: play the cheapest thing that works, keep
//  bombs back, push hard once somebody is about to go out. No peeking, no teamwork.
//

import BigTwoKit

enum GreedyBot {

  @MainActor
  static func choose(in game: BigTwoGame, seat: Int) -> Play? {
    let options = game.legalPlays(for: seat)  // cheapest first
    guard !options.isEmpty else { return nil }
    let hand = game.seats[seat].hand
    let danger = game.seats.filter { $0.id != seat }.contains { $0.hand.count <= 2 }
    let endgame = hand.count <= 5
    let safe = options.filter { !$0.kind.isBomb }

    if game.table == nil {
      let pool = safe.isEmpty ? options : safe
      if danger, let strongest = pool.last { return strongest }
      if let five = pool.last(where: { $0.count == 5 && !$0.kind.isBomb }),
         hand.count > 5 { return five }
      return pool.first
    }
    if let cheap = safe.first { return cheap }
    return (danger || endgame) ? options.first : nil
  }
}

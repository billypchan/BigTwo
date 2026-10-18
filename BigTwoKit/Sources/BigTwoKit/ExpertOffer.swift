//
//  ExpertOffer.swift
//  BigTwoKit — whether Final Score should ask the player to move up from Strong.
//

import Foundation

public enum ExpertOffer {
  /// The human beat a Strong table: the game is over, the bots are Strong, and that
  /// seat's score is strictly the highest. A tie is not a win, and neither is 0–0.
  public static func shouldAsk(botLevel: BotLevel, gameOver: Bool,
                                scores: [Int], humanSeat: Int?) -> Bool {
    guard gameOver, botLevel == .strong,
          let humanSeat, scores.indices.contains(humanSeat) else { return false }
    let mine = scores[humanSeat]
    return scores.enumerated().allSatisfy { index, score in
      index == humanSeat || mine > score
    }
  }
}

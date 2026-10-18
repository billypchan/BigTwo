//
//  WatchScoreSheetView.swift
//  Big Two — the score sheet, and the Expert question that can replace it.
//
//  ⚠️ The swap has to live in this view. Flipping a flag on `WatchGameView` and
//  branching inside the `.sheet` closure left the score on screen: the sheet does
//  not rebuild its content for that.
//

import BigTwoKit
import SwiftUI

struct WatchScoreSheetView: View {
  @ObservedObject var game: BigTwoGame
  let result: DealResult
  @State private var asking = false

  /// `-offerExpert YES` — autoplay has no human seat, so a test cannot win for real.
  private var forceOffer: Bool { UserDefaults.standard.bool(forKey: "offerExpert") }

  var body: some View {
    if asking {
      WatchExpertOfferView(onExpert: accept, onDecline: decline)
    } else {
      WatchScoreView(result: result, seats: game.seats, gameOver: game.gameOver) {
        if game.gameOver && (game.offerExpert || forceOffer) {
          asking = true
        } else {
          game.continueAfterScore()
        }
      }
    }
  }

  /// Set the level before the next game is dealt.
  private func accept() {
    game.preferences.botLevel = .expert
    asking = false
    game.continueAfterScore()
  }

  private func decline() {
    asking = false
    game.continueAfterScore()
  }
}

#Preview {
  WatchScoreSheetView(game: BigTwoGame(seed: 2),
                      result: DealResult(deal: 10, winner: 1, cardsLeft: [3, 0, 5, 8],
                                         points: [-3, 16, -5, -8]))
}

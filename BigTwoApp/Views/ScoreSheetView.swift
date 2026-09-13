//
//  ScoreSheetView.swift
//  Big Two — the end-of-deal score dialog.
//

import BigTwoKit
import SwiftUI

struct ScoreSheetView: View {
  @ObservedObject var game: BigTwoGame
  let result: DealResult

  var body: some View {
    VStack(spacing: 14) {
      Text(game.gameOver ? "Final Score" : "Score").font(.palm(20, .heavy))
      ForEach(game.seats) { player in
        row(player)
      }
      if game.seats.allSatisfy({ $0.score == 0 }) {
        Text("I will not play with real money")
          .font(.palm(11, .regular))
          .foregroundColor(.inkDim)
      }
      PalmButtonView(title: game.gameOver ? "New Game" : "OK", wide: true) {
        game.continueAfterScore()
      }
      .accessibilityIdentifier("score_ok")
    }
    .foregroundColor(.ink)
    .padding(24)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("score_sheet")
  }

  private func row(_ player: Seat) -> some View {
    HStack {
      Text(player.name).font(.palm(15))
      if player.id == result.winner {
        // verbatim: a literal would read the asterisks as Markdown italics (v2.2 added them).
        Text(verbatim: "*WIN!*").font(.palm(15, .heavy)).foregroundColor(.suitRed)
      }
      if game.preferences.showCardsLeft && player.id != result.winner {
        Text("\(result.cardsLeft[player.id]) left").font(.palm(12, .regular))
        if result.cardsLeft[player.id] >= 10 {
          Text("DOUBLE!").font(.palm(11, .heavy)).foregroundColor(.suitRed)
        }
      }
      Spacer()
      Text(BigTwoGame.signed(result.points[player.id])).font(.palm(13, .regular))
      Text("\(player.score)").font(.palm(16, .heavy)).frame(width: 52, alignment: .trailing)
    }
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("score_row_\(player.id)")
  }
}

#Preview {
  ScoreSheetView(game: BigTwoGame(seed: 2),
                 result: DealResult(deal: 1, winner: 1, cardsLeft: [4, 0, 11, 7],
                                    points: [-20, 128, -90, -18]))
}

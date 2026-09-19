//
//  ScoreDialogView.swift
//  Big Two — the end-of-deal score dialog. Modal: only OK moves on.
//

import BigTwoKit
import SwiftUI

struct ScoreDialogView: View {
  @ObservedObject var game: BigTwoGame
  let result: DealResult

  @Environment(\.palmUnit) private var u

  var body: some View {
    PalmDialogView(title: game.gameOver
                    ? L10n.string("Final Score")
                    : L10n.string("Score — Deal %d", result.deal)) {
      VStack(spacing: 4 * u) {
        ForEach(game.seats) { player in
          row(player)
        }
        if game.seats.allSatisfy({ $0.score == 0 }) {
          Text(L10n.string("I will not play with real money"))
            .font(.palm(11 * u, .regular))
            .foregroundColor(.inkDim)
        }
      }
    } buttons: {
      PalmButtonView(title: L10n.string(game.gameOver ? "New Game" : "OK"),
                     width: game.gameOver ? 80 : 40) {
        game.continueAfterScore()
      }
      .accessibilityIdentifier("score_ok")
    }
    .accessibilityIdentifier("score_sheet")
  }

  private func row(_ player: Seat) -> some View {
    HStack(spacing: 4 * u) {
      Text(player.name).font(.palm(14 * u))
      if player.id == result.winner {
        // verbatim: a literal would read the asterisks as Markdown italics (v2.2 added them).
        Text(verbatim: L10n.string("*WIN!*")).font(.palm(14 * u, .heavy)).foregroundColor(.suitRed)
      }
      if game.preferences.showCardsLeft && player.id != result.winner {
        Text(L10n.string("%d left", result.cardsLeft[player.id])).font(.palm(12 * u, .regular))
        if result.cardsLeft[player.id] >= 10 {
          Text(L10n.string("DOUBLE!")).font(.palm(11 * u, .heavy)).foregroundColor(.suitRed)
        }
      }
      Spacer(minLength: 0)
      Text(BigTwoGame.signed(result.points[player.id])).font(.palm(12 * u, .regular))
      Text("\(player.score)")
        .font(.palm(15 * u, .heavy))
        .frame(width: 44 * u, alignment: .trailing)
    }
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("score_row_\(player.id)")
  }
}

#Preview {
  ScoreDialogView(game: BigTwoGame(seed: 2),
                  result: DealResult(deal: 1, winner: 1, cardsLeft: [4, 0, 11, 7],
                                     points: [-20, 128, -90, -18]))
    .padding()
    .background(Color.felt)
}

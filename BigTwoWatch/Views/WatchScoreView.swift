//
//  WatchScoreView.swift
//  Big Two — the deal's score on the watch, and the button that deals the next one.
//

import BigTwoKit
import SwiftUI

struct WatchScoreView: View {
  let result: DealResult
  let seats: [Seat]
  let gameOver: Bool
  let onContinue: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 6) {
        Text(verbatim: gameOver ? L10n.string("Final Score")
                                : L10n.string("Score — Deal %d", result.deal))
          .font(.system(size: 15, weight: .heavy))
        ForEach(seats) { seat in
          HStack {
            Text(verbatim: seat.name)
              .fontWeight(seat.id == result.winner ? .heavy : .regular)
            Spacer()
            Text(verbatim: BigTwoGame.signed(result.points[seat.id]))
            Text(verbatim: "(\(seat.score))")
              .foregroundColor(.inkDim)
          }
          .font(.system(size: 13))
        }
        Button(L10n.string(gameOver ? "New Game" : "OK"), action: onContinue)
          .accessibilityIdentifier("score_ok")
      }
      .padding(.horizontal, 4)
    }
  }
}

#Preview {
  WatchScoreView(result: DealResult(deal: 1, winner: 1, cardsLeft: [3, 0, 5, 8],
                                    points: [-3, 16, -5, -8]),
                 seats: (0..<4).map { Seat(id: $0, name: BigTwoGame.defaultNames[$0],
                                           isHuman: $0 == 1) },
                 gameOver: false) {}
}

//
//  WatchScoreView.swift
//  Big Two — the deal's score on the watch, and the button that deals the next one.
//  Same row as the phone: who won, how many cards are left, and DOUBLE! at ten or more.
//

import BigTwoKit
import SwiftUI

struct WatchScoreView: View {
  let result: DealResult
  let seats: [Seat]
  let gameOver: Bool
  var showCardsLeft = true
  let onContinue: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 6) {
        Text(verbatim: gameOver ? L10n.string("Final Score")
                                : L10n.string("Score — Deal %d", result.deal))
          .font(.system(size: 15, weight: .heavy))
        ForEach(seats) { seat in
          row(seat)
        }
        WatchPalmButtonView(title: L10n.string(gameOver ? "New Game" : "OK"), action: onContinue)
          .accessibilityIdentifier("score_ok")
      }
      .padding(.horizontal, 4)
    }
  }

  private func row(_ seat: Seat) -> some View {
    HStack(spacing: 3) {
      Text(verbatim: seat.name)
        .fontWeight(seat.id == result.winner ? .heavy : .regular)
        .lineLimit(1)
      if seat.id == result.winner {
        Text(verbatim: L10n.string("*WIN!*"))
          .fontWeight(.heavy)
          .foregroundColor(.suitRed)
      }
      if showCardsLeft && seat.id != result.winner {
        Text(verbatim: L10n.string("%d left", result.cardsLeft[seat.id]))
          .foregroundColor(.inkDim)
        if result.cardsLeft[seat.id] >= 10 {
          Text(verbatim: L10n.string("DOUBLE!"))
            .fontWeight(.heavy)
            .foregroundColor(.suitRed)
        }
      }
      Spacer(minLength: 2)
      Text(verbatim: BigTwoGame.signed(result.points[seat.id]))
      Text(verbatim: "(\(seat.score))")
        .foregroundColor(.inkDim)
    }
    .font(.system(size: 13))
    .lineLimit(1)
    .minimumScaleFactor(0.6)
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("score_row_\(seat.id)")
  }
}

#Preview {
  WatchScoreView(result: DealResult(deal: 1, winner: 1, cardsLeft: [3, 0, 12, 8],
                                    points: [-3, 46, -30, -13]),
                 seats: (0..<4).map { Seat(id: $0, name: BigTwoGame.defaultNames[$0],
                                           isHuman: $0 == 1) },
                 gameOver: false) {}
}

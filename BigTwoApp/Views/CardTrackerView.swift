//
//  CardTrackerView.swift
//  Big Two — the Palm's card tracker, in the space its portrait screen gave the input
//  area: every card by suit and rank, played ones turned white.
//

import BigTwoKit
import SwiftUI

struct CardTrackerView: View {
  let played: Set<Card>

  @Environment(\.palmUnit) private var u

  private static let rankCodes = ["3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A", "2"]

  var body: some View {
    VStack(spacing: 2 * u) {
      ForEach(Suit.allCases, id: \.self) { suit in
        HStack(spacing: 0) {
          Text(suit.symbol)
            .foregroundColor(suit.isRed ? .suitRed : .ink)
            .frame(width: 24 * u)
          ForEach(Rank.allCases, id: \.self) { rank in
            Text(Self.rankCodes[rank.rawValue])
              .foregroundColor(color(Card(rank: rank, suit: suit)))
              .frame(maxWidth: .infinity)
          }
        }
        .font(.palm(15 * u))
      }
    }
    .padding(.horizontal, 4 * u)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.felt)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Cards played")
    .accessibilityValue(Card.deck.filter(played.contains).map(\.code).joined(separator: " "))
    .accessibilityIdentifier("card_tracker")
  }

  private func color(_ card: Card) -> Color {
    if played.contains(card) { return .playedCard }
    return card.suit.isRed ? .suitRed : .ink
  }
}

#Preview {
  CardTrackerView(played: Set(Card.deck.prefix(9)))
    .frame(width: 400, height: 125)
    .environment(\.palmUnit, 1.25)
}

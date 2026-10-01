//
//  WatchPlayedCardView.swift
//  Big Two — a card in someone else's row. Unlike a card in your hand it is only ever
//  read, never picked, so it does not need the phone's rank-over-suit strip: rank and
//  suit sit side by side, which fits a five-card play across a watch row at a size that
//  can actually be read.
//

import BigTwoKit
import SwiftUI

struct WatchPlayedCardView: View {
  let card: Card
  var height: CGFloat = 21

  var body: some View {
    HStack(spacing: 0) {
      Text(card.rank.label)
      Text(card.suit.symbol)
    }
    .font(.palm(height * 0.62, .heavy))
    .foregroundColor(card.suit.isRed ? .suitRed : .ink)
    .lineLimit(1)
    .minimumScaleFactor(0.6)
    .padding(.horizontal, height * 0.1)
    .frame(height: height)
    .background(RoundedRectangle(cornerRadius: 3).fill(Color.cardFace))
    .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color.ink, lineWidth: 1))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(L10n.spokenCard(rankName: card.rank.name, suitName: card.suit.name))
  }
}

#Preview {
  VStack(alignment: .leading, spacing: 4) {
    HStack(spacing: 1) {
      ForEach([Card(rank: .three, suit: .diamond), Card(rank: .three, suit: .club),
               Card(rank: .seven, suit: .club), Card(rank: .seven, suit: .heart),
               Card(rank: .seven, suit: .spade)]) { WatchPlayedCardView(card: $0) }
    }
    HStack(spacing: 1) {
      ForEach([Card(rank: .ten, suit: .diamond), Card(rank: .two, suit: .spade)]) {
        WatchPlayedCardView(card: $0)
      }
    }
  }
  .padding()
  .background(Color.felt)
}

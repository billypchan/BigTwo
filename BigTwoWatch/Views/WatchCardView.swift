//
//  WatchCardView.swift
//  Big Two — a card in your hand, laid out like a played one: rank and suit side by side
//  on a white face with a 1px black border. The phone's rank-over-suit strip exists so an
//  overlapped card still reads from its left edge; nothing overlaps on a watch, and side
//  by side a card is legible at half the height. Selected cards invert.
//
//  ⚠️ No height is passed in. A card is as wide as the grid column it lands in and as tall
//  as its own text asks for, so the hand needs nothing measured to lay itself out — which
//  is what lets the table drop its `GeometryReader`.
//

import BigTwoKit
import SwiftUI

struct WatchCardView: View {
  let card: Card
  var selected = false

  private static let font: CGFloat = 13

  var body: some View {
    HStack(spacing: 0) {
      Text(card.rank.label)
      Text(card.suit.symbol)
    }
    .font(.palm(Self.font, .heavy))
    .foregroundColor(glyphColor)
    .lineLimit(1)
    .minimumScaleFactor(0.4)
    .padding(.horizontal, 1)
    .padding(.vertical, 1)
    .frame(maxWidth: .infinity)
    .background(RoundedRectangle(cornerRadius: 3).fill(selected ? Color.ink : Color.cardFace))
    .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color.ink, lineWidth: 1))
    // One element, not a rank and a suit: without this the identifier on the card matches
    // three times over and a UI test cannot tap it at all.
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(L10n.spokenCard(rankName: card.rank.name, suitName: card.suit.name))
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private var glyphColor: Color {
    switch (card.suit.isRed, selected) {
    case (true, false): return .suitRed
    case (true, true): return .suitRedOnInk
    case (false, false): return .ink
    case (false, true): return .cardFace
    }
  }
}

#Preview {
  HStack(spacing: 2) {
    WatchCardView(card: .threeOfDiamonds)
    WatchCardView(card: Card(rank: .ten, suit: .heart), selected: true)
    WatchCardView(card: Card(rank: .two, suit: .spade))
  }
  .padding()
  .background(Color.felt)
}

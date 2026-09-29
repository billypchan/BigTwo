//
//  WatchCardView.swift
//  Big Two — the phone's card, shrunk: white face, 1px black border, rank with the suit
//  under it so a card still reads when only its left strip shows. Selected cards invert.
//

import BigTwoKit
import SwiftUI

struct WatchCardView: View {
  let card: Card
  var selected = false
  var height: CGFloat = 40

  var body: some View {
    ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: height * 0.08).fill(selected ? Color.ink : Color.cardFace)
      RoundedRectangle(cornerRadius: height * 0.08).strokeBorder(Color.ink, lineWidth: 1)
      VStack(alignment: .leading, spacing: -height * 0.06) {
        Text(card.rank.label)
          .font(.palm(height * 0.36, .heavy))
          .minimumScaleFactor(0.5)
          .lineLimit(1)
        Text(card.suit.symbol)
          .font(.palm(height * 0.36, .regular))
      }
      .foregroundColor(glyphColor)
      .padding(.leading, height * 0.07)
      .padding(.top, height * 0.04)
    }
    .frame(width: height * Self.aspect, height: height)
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

  static let aspect: CGFloat = 0.64
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

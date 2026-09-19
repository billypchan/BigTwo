//
//  CardView.swift
//  Big Two — a Palm card: white face, 1px black border, rank top-left with the suit under
//  it, so a card still reads when only its left strip shows. Selected cards are inverted.
//

import BigTwoKit
import SwiftUI

struct CardView: View {
  let card: Card
  var selected = false
  var height: CGFloat = 60

  var body: some View {
    ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: height * 0.05).fill(selected ? Color.ink : Color.cardFace)
      RoundedRectangle(cornerRadius: height * 0.05).strokeBorder(Color.ink, lineWidth: 1)
      VStack(alignment: .leading, spacing: 0) {
        Text(card.rank.label)
          .font(.palm(height * 0.3, .heavy))
          .minimumScaleFactor(0.6)
          .lineLimit(1)
        Text(card.suit.symbol)
          .font(.palm(height * 0.36, .regular))
      }
      .foregroundColor(glyphColor)
      .padding(.leading, height * 0.05)
      .padding(.top, height * 0.02)
    }
    .frame(width: height * CardView.aspect, height: height)
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
  HStack {
    CardView(card: .threeOfDiamonds)
    CardView(card: Card(rank: .ten, suit: .heart), selected: true)
    CardView(card: Card(rank: .two, suit: .spade))
  }
  .padding()
  .background(Color.felt)
}

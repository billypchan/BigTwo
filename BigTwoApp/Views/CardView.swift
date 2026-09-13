//
//  CardView.swift
//  Big Two — white face, 1px black border, 3pt corners, rank top-left, suit centre and
//  bottom-right. Red suits colour the rank too.
//

import BigTwoKit
import SwiftUI

struct CardView: View {
  let card: Card
  var selected = false
  var height: CGFloat = 76

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 3).fill(Color.cardFace)
      RoundedRectangle(cornerRadius: 3).strokeBorder(Color.ink, lineWidth: selected ? 2 : 1)
      VStack(spacing: 0) {
        HStack(spacing: 1) {
          Text(card.rank.label).font(.palm(height * 0.24, .heavy))
          Spacer(minLength: 0)
        }
        Text(card.suit.symbol).font(.palm(height * 0.34, .regular))
        Spacer(minLength: 0)
        HStack {
          Spacer(minLength: 0)
          Text(card.suit.symbol).font(.palm(height * 0.18, .regular))
        }
      }
      .foregroundColor(card.suit.isRed ? .suitRed : .ink)
      .padding(.horizontal, 3)
      .padding(.vertical, 2)
    }
    .frame(width: height * CardView.aspect, height: height)
    .offset(y: selected ? -14 : 0)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(card.spokenName)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  static let aspect: CGFloat = 0.66
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

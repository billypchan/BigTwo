//
//  WatchCardView.swift
//  Big Two — one card on the watch. The phone draws rank over suit in a tall strip;
//  a watch has no room for that, so both sit on one line and the whole chip inverts
//  when it is selected, which is the Palm's own way of showing a picked card.
//

import BigTwoKit
import SwiftUI

struct WatchCardView: View {
  let card: Card
  var isSelected = false
  /// Table cards are shown, never picked, so they don't take a tap target.
  var isCompact = false

  var body: some View {
    HStack(spacing: 1) {
      Text(card.rank.label)
      Text(card.suit.symbol)
    }
    .font(.system(size: isCompact ? 13 : 15, weight: .bold))
    .foregroundColor(faceColor)
    .lineLimit(1)
    .minimumScaleFactor(0.6)
    .frame(maxWidth: .infinity, minHeight: isCompact ? 20 : 30)
    .background(isSelected ? Color.ink : Color.cardFace)
    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.ink, lineWidth: 1))
    .clipShape(RoundedRectangle(cornerRadius: 3))
    // One element, not a rank and a suit: without this the rows the identifier is put on
    // match three times over and a UI test cannot tap a card at all.
    .accessibilityElement(children: .combine)
    .accessibilityLabel(L10n.spokenCard(rankName: card.rank.name, suitName: card.suit.name))
    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
  }

  private var faceColor: Color {
    guard card.suit.isRed else { return isSelected ? .cardFace : .ink }
    return isSelected ? .suitRedOnInk : .suitRed
  }
}

#Preview {
  HStack {
    WatchCardView(card: .threeOfDiamonds)
    WatchCardView(card: Card(rank: .ace, suit: .spade), isSelected: true)
  }
  .padding()
  .background(Color.felt)
}

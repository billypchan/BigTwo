//
//  WatchCardView.swift
//  Big Two — a card in your hand, laid out like a played one: rank and suit side by side
//  on a white face with a 1px black border. The phone's rank-over-suit strip exists so an
//  overlapped card still reads from its left edge; nothing overlaps on a watch, and side
//  by side a card is legible at half the height. Selected cards invert.
//

import BigTwoKit
import SwiftUI

struct WatchCardView: View {
  let card: Card
  var selected = false
  var height: CGFloat = 21

  var body: some View {
    HStack(spacing: 0) {
      Text(card.rank.label)
      Text(card.suit.symbol)
    }
    .font(.palm(height * 0.62, .heavy))
    .foregroundColor(glyphColor)
    .lineLimit(1)
    .minimumScaleFactor(0.6)
    .padding(.horizontal, height * 0.1)
    // The card fills its grid column; the column is sized from `aspect`, so the two agree.
    .frame(maxWidth: .infinity)
    .frame(height: height)
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

  /// Width per point of height. Rank and suit side by side need a card wider than it is
  /// tall; the hand's grid sizes a column from this so the card fills it exactly.
  static let aspect: CGFloat = 1.3
}

#Preview {
  HStack(spacing: 2) {
    WatchCardView(card: .threeOfDiamonds)
    WatchCardView(card: Card(rank: .ten, suit: .heart), selected: true)
    WatchCardView(card: Card(rank: .two, suit: .spade))
  }
  .frame(height: 21)
  .padding()
  .background(Color.felt)
}

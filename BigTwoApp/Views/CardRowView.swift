//
//  CardRowView.swift
//  Big Two — an overlapping row of cards that always fits the width it is given.
//

import BigTwoKit
import SwiftUI

struct CardRowView: View {
  let cards: [Card]
  var height: CGFloat = 76
  var selection: Set<Card> = []
  /// Prefix for each card's accessibility identifier, e.g. "hand" → "hand_3d".
  var idPrefix = "card"
  var onTap: ((Card) -> Void)?
  var onLongPress: ((Card) -> Void)?

  @State private var pressBegan = false
  @State private var pressMoved = false
  @State private var longPressFired = false
  @State private var longPressTask: Task<Void, Never>?

  private var interactive: Bool { onTap != nil || onLongPress != nil }

  var body: some View {
    GeometryReader { geo in
      let w = height * CardView.aspect
      let step = cards.count > 1
        ? min(w + 4, max(14, (geo.size.width - w) / CGFloat(cards.count - 1)))
        : 0
      ZStack(alignment: .leading) {
        ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
          CardView(card: card, selected: selection.contains(card), height: height)
            .offset(x: CGFloat(index) * step)
            .zIndex(Double(index))
            .accessibilityIdentifier("\(idPrefix)_\(card.code)")
            .accessibilityAddTraits(interactive ? .isButton : [])
            .accessibilityAction { onTap?(card) }
        }
      }
      .frame(width: step * CGFloat(max(cards.count - 1, 0)) + w, height: height + 16,
             alignment: .leading)
      .contentShape(Rectangle())
      .gesture(interactive ? press(step: step, width: w) : nil)
      .frame(maxWidth: .infinity)
    }
    .frame(height: height + 16)
  }

  /// ⚠️ One gesture for the whole row, not one per card: overlapping cards with their own
  /// tap gestures lose a touch near a strip's edge to the neighbour on top (touch slop),
  /// so a tap on 3♦'s visible strip selected 4♣. Here the x position picks the strip.
  private func press(step: CGFloat, width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        if !pressBegan {
          pressBegan = true
          guard let card = card(at: value.startLocation.x, step: step, width: width) else { return }
          longPressTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            longPressFired = true
            onLongPress?(card)
          }
        } else if hypot(value.translation.width, value.translation.height) > 10 {
          pressMoved = true
          longPressTask?.cancel()
        }
      }
      .onEnded { value in
        longPressTask?.cancel()
        if !longPressFired, !pressMoved,
           let card = card(at: value.startLocation.x, step: step, width: width) {
          onTap?(card)
        }
        pressBegan = false
        pressMoved = false
        longPressFired = false
      }
  }

  private func card(at x: CGFloat, step: CGFloat, width: CGFloat) -> Card? {
    guard !cards.isEmpty, x >= 0, x <= step * CGFloat(cards.count - 1) + width else { return nil }
    let index = step > 0 ? Int(x / step) : 0
    return cards[min(index, cards.count - 1)]
  }
}

#Preview {
  CardRowView(cards: Array(Card.deck.prefix(13)), height: 82,
              selection: [Card.deck[4]], onTap: { _ in })
    .padding()
    .background(Color.felt)
}

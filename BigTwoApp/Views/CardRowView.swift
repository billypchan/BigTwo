//
//  CardRowView.swift
//  Big Two — a row of cards that always fits the width it is given, overlapping when it
//  must.
//

import BigTwoKit
import SwiftUI

struct CardRowView: View {
  let cards: [Card]
  var height: CGFloat = 60
  var selection: Set<Card> = []
  /// Prefix for each card's accessibility identifier, e.g. "hand" → "hand_3d".
  var idPrefix = "card"
  var alignment: Alignment = .leading
  var onTap: ((Card) -> Void)?
  /// A second tap on the same card within 0.4s; the first tap has already gone to `onTap`.
  var onDoubleTap: ((Card) -> Void)?
  var onLongPress: ((Card) -> Void)?

  @State private var pressBegan = false
  @State private var pressStart = Date.distantPast
  @State private var pressMoved = false
  @State private var longPressFired = false
  @State private var longPressTask: Task<Void, Never>?
  @State private var lastTap: (card: Card, time: Date)?

  private var interactive: Bool { onTap != nil || onDoubleTap != nil || onLongPress != nil }

  var body: some View {
    GeometryReader { geo in
      let w = height * CardView.aspect
      let step = cards.count > 1
        ? min(w + 1, max(12, (geo.size.width - w) / CGFloat(cards.count - 1)))
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
      .frame(width: step * CGFloat(max(cards.count - 1, 0)) + w, height: height,
             alignment: .leading)
      .contentShape(Rectangle())
      .gesture(interactive ? press(step: step, width: w) : nil)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
    .frame(height: height)
  }

  /// ⚠️ One gesture for the whole row, not one per card: overlapping cards with their own
  /// tap gestures lose a touch near a strip's edge to the neighbour on top (touch slop),
  /// so a tap on 3♦'s visible strip selected 4♣. Here the x position picks the strip.
  private func press(step: CGFloat, width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        if !pressBegan {
          pressBegan = true
          pressStart = value.time
          guard let card = card(at: value.startLocation.x, step: step, width: width) else { return }
          longPressTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
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
        // Judge by the events' own timestamps: when the main thread stalls, touch-down and
        // touch-up arrive together and the timer never gets its chance.
        if !longPressFired, !pressMoved,
           let card = card(at: value.startLocation.x, step: step, width: width) {
          if value.time.timeIntervalSince(pressStart) >= 0.35 {
            onLongPress?(card)
          } else if let last = lastTap, last.card == card, let onDoubleTap,
                    pressStart.timeIntervalSince(last.time) < 0.4 {
            lastTap = nil
            onDoubleTap(card)
          } else {
            lastTap = (card, pressStart)  // touch-down to touch-down, as UIKit measures it
            onTap?(card)
          }
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
  CardRowView(cards: Array(Card.deck.prefix(13)), height: 70,
              selection: [Card.deck[4]], onTap: { _ in })
    .padding()
    .background(Color.felt)
}

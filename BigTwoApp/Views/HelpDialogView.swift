//
//  HelpDialogView.swift
//  Big Two — how the buttons work, and the rules. A Palm form. The text is longer
//  than the square, so it scrolls; the form itself does not.
//

import SwiftUI

struct HelpDialogView: View {
  let onOK: () -> Void

  @Environment(\.palmUnit) private var u

  /// English keys. One element so a test can read the rules without scrolling.
  private static let lines = [
    "Tap a card to pick it. Tap it again to put it back.",
    "Double-tap takes the pair or three of that rank, or the whole suit when you hold five or more of it.",
    "Hold a card to take every card of that rank.",
    "Lead and Play send the cards you picked. Pass stays out. You cannot pass a lead. The empty box clears the pick.",
    "The sort button shows ♠ or 2: that is the order a tap switches to.",
    "The player with the 3♦ leads the first deal. Match the play on the table with a higher one, or pass.",
    "Two or three of a kind: higher rank wins, then the highest suit among them.",
    "Five cards, from low to high: straight, flush, full house, four of a kind, straight flush.",
    "A straight runs A2345, then 23456, up to TJQKA. JQKA2 is not a straight.",
    "A straight is ranked by its highest card, then that card's suit. In A2345 the high card is the 5.",
    "A flush is ranked by its highest card, then that card's suit. A full house by the three of a kind. Four of a kind by the four.",
    "Each card left costs its rank: 3 is 1, up to 2 which is 13. Ten or more cards left doubles the cost. The winner takes all three totals.",
    "A game is ten deals.",
    "With Hong Kong rules, from the next deal: the last winner leads, and 23456 is the highest straight.",
  ]

  var body: some View {
    PalmDialogView(title: L10n.string("Help")) {
      ScrollView {
        Text(Self.lines.map { L10n.string($0) }.joined(separator: "\n\n"))
          .font(.palm(12 * u))
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityIdentifier("help_text")
      }
      .frame(height: 210 * u)
    } buttons: {
      PalmButtonView(title: L10n.string("OK"), width: 40, action: onOK)
        .accessibilityIdentifier("help_ok")
    }
  }
}

#Preview {
  HelpDialogView(onOK: {})
    .padding()
    .background(Color.felt)
}

//
//  WatchPlayerRowView.swift
//  Big Two — one player's row, as on the phone: name chip (inverted on that player's
//  turn), their last move this deal, and how many cards they hold. The played cards get
//  most of the row: a five-card play is the whole point of the row, and shrinking it to
//  fit a wide name chip made it unreadable.
//

import BigTwoKit
import SwiftUI

struct WatchPlayerRowView: View {
  let player: Seat
  let action: SeatAction?
  let isTurn: Bool

  private static let cardHeight: CGFloat = 21

  var body: some View {
    HStack(spacing: 2) {
      Text(player.name)
        .font(.palm(11))
        .foregroundColor(isTurn ? .cardFace : .ink)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(width: 34, height: 17)
        .background(RoundedRectangle(cornerRadius: 3).fill(isTurn ? Color.ink : Color.chrome))
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color.inkDim, lineWidth: 1))
        .accessibilityLabel(isTurn ? L10n.string("%@, to play", player.name) : player.name)
        .accessibilityIdentifier("name_\(player.id)")

      Group {
        switch action {
        case .played(let play)?:
          // Side by side and readable, not overlapped: a watch row has the width for
          // five of these once the name chip stops taking a fifth of it.
          HStack(spacing: 1) {
            ForEach(play.cards) { WatchPlayedCardView(card: $0, height: Self.cardHeight) }
          }
        case .passed?:
          Text(L10n.string("PASS"))
            .font(.palm(12, .regular))
            .foregroundColor(.ink)
            .accessibilityIdentifier("pass_\(player.id)")
        case nil:
          Color.clear
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Text(verbatim: "\(player.hand.count)")
        .font(.palm(11, .semibold))
        .foregroundColor(.ink)
        .fixedSize()
        .frame(minWidth: 16, alignment: .trailing)
        .accessibilityLabel(L10n.string("left: %d", player.hand.count))
        .accessibilityIdentifier("left_\(player.id)")
    }
    .frame(height: 23)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("seat_\(player.id)")
  }
}

#Preview {
  VStack(spacing: 2) {
    WatchPlayerRowView(player: Seat(id: 2, name: "Carl", isHuman: false),
                       action: Play(Array(Card.deck.prefix(3))).map(SeatAction.played),
                       isTurn: true)
    WatchPlayerRowView(player: Seat(id: 3, name: "Dean", isHuman: false), action: .passed,
                       isTurn: false)
  }
  .padding(2)
  .background(Color.felt)
}

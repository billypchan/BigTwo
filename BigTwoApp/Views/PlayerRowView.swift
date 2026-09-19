//
//  PlayerRowView.swift
//  Big Two — one player's row on the Palm table: name button, that player's last move
//  this deal (the cards, or "PASS"), and how many cards they hold.
//

import BigTwoKit
import SwiftUI

struct PlayerRowView: View {
  let player: Seat
  let action: SeatAction?
  let isTurn: Bool
  /// Points kept clear on the right for Play/Pass (44pt hit boxes don't scale).
  var trailingReserve: CGFloat = 0

  @Environment(\.palmUnit) private var u

  var body: some View {
    HStack(alignment: .top, spacing: 4 * u) {
      Text(player.name)
        .font(.palm(12 * u))
        .foregroundColor(isTurn ? .cardFace : .ink)
        .frame(width: 46 * u, height: 20 * u)
        .background(RoundedRectangle(cornerRadius: 3 * u).fill(isTurn ? Color.ink : Color.chrome))
        .overlay(RoundedRectangle(cornerRadius: 3 * u).strokeBorder(Color.inkDim, lineWidth: 1))
        .padding(.top, 3 * u)
        .accessibilityLabel(isTurn ? L10n.string("%@, to play", player.name) : player.name)

      Group {
        switch action {
        case .played(let play)?:
          CardRowView(cards: play.cards, height: 44 * u, idPrefix: "row\(player.id)")
        case .passed?:
          Text(L10n.string("PASS"))
            .font(.palm(19 * u, .regular))
            .foregroundColor(.ink)
            .padding(.leading, 12 * u)
            .accessibilityIdentifier("pass_\(player.id)")
        case nil:
          Color.clear
        }
      }
      .frame(minWidth: 0, maxWidth: 134 * u)
      .frame(height: 46 * u, alignment: .leading)
      .layoutPriority(-1)

      Text(L10n.string("left: %d", player.hand.count))
        .font(.palm(12 * u, .semibold))
        .foregroundColor(.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .fixedSize(horizontal: true, vertical: false)
        .frame(height: 46 * u)
        .accessibilityIdentifier("left_\(player.id)")
      Spacer(minLength: 0)
    }
    .padding(.leading, 2 * u)
    .padding(.trailing, trailingReserve)
    .frame(height: 50 * u, alignment: .top)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("seat_\(player.id)")
  }
}

#Preview {
  VStack(spacing: 0) {
    PlayerRowView(player: Seat(id: 2, name: "Carl", isHuman: false),
                  action: Play(Array(Card.deck.prefix(5))).map(SeatAction.played), isTurn: true,
                  trailingReserve: 80)
    PlayerRowView(player: Seat(id: 3, name: "Dean", isHuman: false), action: .passed,
                  isTurn: false)
  }
  .background(Color.felt)
}

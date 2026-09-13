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
        .accessibilityLabel(isTurn ? "\(player.name), to play" : player.name)

      Group {
        switch action {
        case .played(let play)?:
          CardRowView(cards: play.cards, height: 44 * u, idPrefix: "row\(player.id)")
        case .passed?:
          Text("PASS")
            .font(.palm(19 * u, .regular))
            .foregroundColor(.ink)
            .padding(.leading, 12 * u)
            .accessibilityIdentifier("pass_\(player.id)")
        case nil:
          Color.clear
        }
      }
      .frame(width: 134 * u, height: 46 * u, alignment: .leading)

      Text("left: \(player.hand.count)")
        .font(.palm(12 * u, .semibold))
        .foregroundColor(.ink)
        .frame(height: 46 * u)
        .accessibilityIdentifier("left_\(player.id)")
      Spacer(minLength: 0)
    }
    .padding(.leading, 2 * u)
    .frame(height: 50 * u, alignment: .top)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("seat_\(player.id)")
  }
}

#Preview {
  VStack(spacing: 0) {
    PlayerRowView(player: Seat(id: 2, name: "Carl", isHuman: false),
                  action: Play(Array(Card.deck.prefix(5))).map(SeatAction.played), isTurn: true)
    PlayerRowView(player: Seat(id: 3, name: "Dean", isHuman: false), action: .passed,
                  isTurn: false)
  }
  .background(Color.felt)
}

//
//  ExpertOfferDialogView.swift
//  Big Two — after a Strong game the player won, ask once whether to move up.
//

import SwiftUI

struct ExpertOfferDialogView: View {
  let onExpert: () -> Void
  let onDecline: () -> Void

  @Environment(\.palmUnit) private var u

  var body: some View {
    PalmDialogView(title: L10n.string("Set bots to Expert?")) {
      Text(verbatim: L10n.string("You beat Strong."))
        .font(.palm(13 * u, .regular))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8 * u)
    } buttons: {
      PalmButtonView(title: L10n.string("Expert"), width: 70, action: onExpert)
        .accessibilityIdentifier("expert_yes")
      PalmButtonView(title: L10n.string("Not now"), width: 78, action: onDecline)
        .accessibilityIdentifier("expert_no")
    }
    .accessibilityIdentifier("expert_offer")
  }
}

#Preview {
  ExpertOfferDialogView(onExpert: {}, onDecline: {})
    .padding()
    .background(Color.felt)
}

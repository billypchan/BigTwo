//
//  WatchExpertOfferView.swift
//  Big Two — the phone's "set the bots to Expert?" question, inside the score sheet.
//

import SwiftUI

struct WatchExpertOfferView: View {
  let onExpert: () -> Void
  let onDecline: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      Text(verbatim: L10n.string("Set bots to Expert?"))
        .font(.system(size: 15, weight: .heavy))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
      Text(verbatim: L10n.string("You beat Strong."))
        .font(.system(size: 13))
        .multilineTextAlignment(.center)
      WatchPalmButtonView(title: L10n.string("Expert"), action: onExpert)
        .accessibilityIdentifier("expert_yes")
      WatchPalmButtonView(title: L10n.string("Not now"), action: onDecline)
        .accessibilityIdentifier("expert_no")
    }
    // ⚠️ No identifier on this stack. One on the container replaced `expert_yes`
    // on both buttons, and the test could not find them.
    .padding(.horizontal, 4)
    .accessibilityElement(children: .contain)
  }
}

#Preview {
  WatchExpertOfferView(onExpert: {}, onDecline: {})
    .padding()
    .background(Color.felt)
}

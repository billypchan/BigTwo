//
//  RedealDialogView.swift
//  Big Two — Hong Kong bad hand. A Palm form inside the square: deal again, or play it.
//

import SwiftUI

struct RedealDialogView: View {
  let onDealAgain: () -> Void
  let onPlay: () -> Void

  @Environment(\.palmUnit) private var u

  var body: some View {
    PalmDialogView(title: L10n.string("Bad hand")) {
      Text(L10n.string("Two or fewer face cards, and no ace or two."))
        .font(.palm(13 * u))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 6 * u)
    } buttons: {
      PalmButtonView(title: L10n.string("Deal again"), width: 92, action: onDealAgain)
        .accessibilityIdentifier("redeal_again")
      PalmButtonView(title: L10n.string("Play"), width: 50, action: onPlay)
        .accessibilityIdentifier("redeal_play")
    }
    .accessibilityIdentifier("redeal_dialog")
  }
}

#Preview {
  RedealDialogView(onDealAgain: {}, onPlay: {})
    .padding()
    .background(Color.felt)
}

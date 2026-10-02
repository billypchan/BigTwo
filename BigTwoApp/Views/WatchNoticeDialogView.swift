//
//  WatchNoticeDialogView.swift
//  Big Two — the one-time note that the game is on Apple Watch too. A Palm form like the
//  others, shown once and never again.
//

import SwiftUI

struct WatchNoticeDialogView: View {
  let onOK: () -> Void

  @Environment(\.palmUnit) private var u

  var body: some View {
    PalmDialogView(title: L10n.string("Now on Apple Watch")) {
      VStack(spacing: 6 * u) {
        Text(L10n.string("The same game is on your watch"))
          .font(.palm(13 * u, .regular))
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(.vertical, 4 * u)
    } buttons: {
      PalmButtonView(title: L10n.string("OK"), width: 40, action: onOK)
        .accessibilityIdentifier("watch_notice_ok")
    }
  }
}

#Preview {
  WatchNoticeDialogView(onOK: {})
    .padding()
    .background(Color.felt)
}

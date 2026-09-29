//
//  WatchStoreView.swift
//  Big Two — the paywall. The watch app installs with the phone app, so this is what
//  a player who has not bought it sees.
//

import SwiftUI

struct WatchStoreView: View {
  @ObservedObject var unlock: WatchUnlock

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        Text(verbatim: L10n.string("Big Two on Apple Watch"))
          .font(.system(size: 15, weight: .heavy))
          .multilineTextAlignment(.center)
        Text(verbatim: L10n.string("Play the full game on your wrist. One purchase, no subscription."))
          .font(.system(size: 12))
          .multilineTextAlignment(.center)

        switch unlock.state {
        case .locked(let price):
          Button(price.map { L10n.string("Buy %@", $0) } ?? L10n.string("Buy")) {
            Task { await unlock.buy() }
          }
          .disabled(unlock.isWorking)
          .accessibilityIdentifier("store_buy")
        case .unavailable:
          // Not the same as "not bought" — say so, or a flat network looks like a refusal.
          Text(verbatim: L10n.string("The App Store could not be reached."))
            .font(.system(size: 12))
            .foregroundColor(.inkDim)
            .multilineTextAlignment(.center)
        case .loading, .unlocked:
          ProgressView()
        }

        Button(L10n.string("Restore Purchase")) {
          Task { await unlock.restore() }
        }
        .disabled(unlock.isWorking)
        .accessibilityIdentifier("store_restore")
      }
      .padding(.horizontal, 4)
    }
    .task { await unlock.refresh() }
  }
}

#Preview {
  WatchStoreView(unlock: WatchUnlock())
}

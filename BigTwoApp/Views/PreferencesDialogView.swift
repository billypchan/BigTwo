//
//  PreferencesDialogView.swift
//  Big Two — the Palm "Preferences" form, wording and all.
//

import BigTwoKit
import SwiftUI

struct PreferencesDialogView: View {
  @Binding var preferences: Preferences
  let onOK: () -> Void

  @Environment(\.palmUnit) private var u
  @Environment(\.openURL) private var openURL

  var body: some View {
    PalmDialogView(title: L10n.string("Preferences")) {
      VStack(alignment: .leading, spacing: 0) {
        PalmCheckboxView(title: L10n.string("Auto pass"), isOn: $preferences.autopass)
          .accessibilityIdentifier("pref_autopass")
        PalmCheckboxView(title: L10n.string("Enable autopass for 5-card turn"),
                         isOn: $preferences.autopassFiveCard)
          .accessibilityIdentifier("pref_autopassFiveCard")
        PalmCheckboxView(title: L10n.string("Show card left in score dialog"),
                         isOn: $preferences.showCardsLeft)
          .accessibilityIdentifier("pref_showCardsLeft")
        PalmCheckboxView(title: L10n.string("Use Hong Kong Rule Set"), isOn: $preferences.hongKong)
          .accessibilityIdentifier("pref_hongKong")
        HStack(spacing: 6 * u) {
          Text(L10n.string("Bots:")).font(.palm(13 * u))
          PalmPushButtonsView(options: [(false, "Classic"), (true, "Strong")],
                              selection: $preferences.strongBots, idPrefix: "pref_bots")
        }
        HStack(spacing: 6 * u) {
          Text(L10n.string("Game speed:")).font(.palm(13 * u))
          PalmPushButtonsView(options: [(.slow, "Slow"), (.medium, "Medium"), (.fast, "Fast")],
                              selection: $preferences.gameSpeed, idPrefix: "pref_speed")
        }
        HStack(spacing: 6 * u) {
          Text(L10n.string("Sort cards by:")).font(.palm(13 * u))
          PalmPushButtonsView(options: [(false, "Rank"), (true, "Suit")],
                              selection: $preferences.sortBySuit, idPrefix: "pref_sort")
        }
      }
    } buttons: {
      PalmButtonView(title: L10n.string("OK"), width: 40, action: onOK)
        .accessibilityIdentifier("pref_ok")
      PalmButtonView(title: L10n.string("Source"), width: 56, action: openSource)
        .accessibilityIdentifier("pref_source")
    }
  }

  private func openSource() {
    guard let url = URL(string: "https://github.com/billypchan/BigTwo") else { return }
    openURL(url)
  }
}

#Preview {
  PreferencesDialogView(preferences: .constant(Preferences()), onOK: {})
    .padding()
    .background(Color.felt)
}

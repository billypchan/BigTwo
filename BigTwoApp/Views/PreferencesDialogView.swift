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

  var body: some View {
    PalmDialogView(title: "Preferences") {
      VStack(alignment: .leading, spacing: 0) {
        PalmCheckboxView(title: "Auto pass", isOn: $preferences.autopass)
          .accessibilityIdentifier("pref_autopass")
        PalmCheckboxView(title: "Enable autopass for 5-card turn", isOn: $preferences.autopassFiveCard)
          .accessibilityIdentifier("pref_autopassFiveCard")
        PalmCheckboxView(title: "Show card left in score dialog", isOn: $preferences.showCardsLeft)
          .accessibilityIdentifier("pref_showCardsLeft")
        PalmCheckboxView(title: "Use Hong Kong Rule Set", isOn: $preferences.hongKong)
          .accessibilityIdentifier("pref_hongKong")
        HStack(spacing: 6 * u) {
          Text("Game speed:").font(.palm(13 * u))
          PalmPushButtonsView(options: [(.slow, "Slow"), (.medium, "Medium"), (.fast, "Fast")],
                              selection: $preferences.gameSpeed, idPrefix: "pref_speed")
        }
        HStack(spacing: 6 * u) {
          Text("Sort cards by:").font(.palm(13 * u))
          PalmPushButtonsView(options: [(false, "Rank"), (true, "Suit")],
                              selection: $preferences.sortBySuit, idPrefix: "pref_sort")
        }
      }
    } buttons: {
      PalmButtonView(title: "OK", width: 40, action: onOK)
        .accessibilityIdentifier("pref_ok")
    }
  }
}

#Preview {
  PreferencesDialogView(preferences: .constant(Preferences()), onOK: {})
    .padding()
    .background(Color.felt)
}

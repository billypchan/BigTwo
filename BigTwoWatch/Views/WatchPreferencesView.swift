//
//  WatchPreferencesView.swift
//  Big Two — the Palm Preferences form as a watch page. Same settings, same wording and
//  the same identifiers as the phone; a change here is saved and pushed to the phone by
//  the app, because they are one set of preferences on two devices.
//

import BigTwoKit
import SwiftUI

struct WatchPreferencesView: View {
  @ObservedObject var game: BigTwoGame

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.string("Preferences"))
          .font(.palm(14, .heavy))
          .foregroundColor(.ink)
          .frame(maxWidth: .infinity, alignment: .leading)

        check("Auto pass", isOn: $game.preferences.autopass, id: "pref_autopass")
        check("Enable autopass for 5-card turn", isOn: $game.preferences.autopassFiveCard,
              id: "pref_autopass5")
        check("Show card left in score dialog", isOn: $game.preferences.showCardsLeft,
              id: "pref_showCardsLeft")
        check("Use Hong Kong Rule Set", isOn: $game.preferences.hongKong, id: "pref_hongKong")

        group("Bots:") {
          WatchPushButtonsView(options: [(false, "Classic"), (true, "Strong")],
                               selection: $game.preferences.strongBots, idPrefix: "pref_bots")
        }
        group("Game speed:") {
          WatchPushButtonsView(
            options: [(GameSpeed.slow, "Slow"), (.medium, "Medium"), (.fast, "Fast")],
            selection: $game.preferences.gameSpeed, idPrefix: "pref_speed")
        }
        group("Sort cards by:") {
          WatchPushButtonsView(options: [(false, "Rank"), (true, "Suit")],
                               selection: $game.preferences.sortBySuit, idPrefix: "pref_sort")
        }
      }
      .padding(.horizontal, 4)
    }
    .background(Color.felt.ignoresSafeArea())
  }

  /// A Palm checkbox: a square box with a tick, and the label beside it.
  private func check(_ key: String, isOn: Binding<Bool>, id: String) -> some View {
    Button { isOn.wrappedValue.toggle() } label: {
      HStack(alignment: .top, spacing: 5) {
        ZStack {
          RoundedRectangle(cornerRadius: 2).fill(Color.cardFace)
          RoundedRectangle(cornerRadius: 2).strokeBorder(Color.ink, lineWidth: 1)
          if isOn.wrappedValue {
            Text(verbatim: "✓").font(.palm(12, .heavy)).foregroundColor(.ink)
          }
        }
        .frame(width: 16, height: 16)
        Text(L10n.string(key))
          .font(.palm(12))
          .foregroundColor(.ink)
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: 0)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(WatchPalmPressStyle())
    .accessibilityIdentifier(id)
    .accessibilityAddTraits(isOn.wrappedValue ? [.isSelected] : [])
  }

  private func group<Content: View>(_ key: String,
                                    @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(L10n.string(key))
        .font(.palm(12))
        .foregroundColor(.ink)
      content()
    }
  }
}

#Preview {
  WatchPreferencesView(game: BigTwoGame(seed: 2))
}

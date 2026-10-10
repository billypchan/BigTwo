//
//  WatchPreferencesView.swift
//  Big Two — the Palm Preferences form as a watch page. Same settings, same wording and
//  the same identifiers as the phone; a change here is saved and pushed to the phone,
//  because they are one set of preferences on two devices.
//
//  The Palm form had an OK button and so does this one: a change applies as you make it,
//  and OK writes it and takes you back to the table. Without it there was no way to leave
//  the page except a swipe, and nothing told you the setting had been kept.
//
//  ⚠️ OK is **pinned**, not the last thing in the scroll. The settings are longer than any
//  watch screen, so at the bottom of the list it was below the fold — a confirm button
//  nobody can see is the thing this was added to fix.
//

import BigTwoKit
import SwiftUI

struct WatchPreferencesView: View {
  @ObservedObject var game: BigTwoGame
  /// Writes the preferences and returns to the table.
  let onDone: () -> Void

  var body: some View {
    // The same bottom band the table page sinks into — see `WatchGameView.controls`.
    GeometryReader { geo in
      VStack(spacing: 0) {
        settings
        WatchPalmButtonView(title: L10n.string("OK"), action: onDone)
          .accessibilityIdentifier("pref_ok")
          .padding(.horizontal, 10)
          .frame(height: 32)
          .background(Color.felt)
      }
      .padding(.bottom, -max(geo.safeAreaInsets.bottom - 2, 0))
    }
    .background(Color.felt.ignoresSafeArea())
  }

  private var settings: some View {
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
          WatchPushButtonsView(
            options: [(BotLevel.classic, "Classic"), (.strong, "Strong"), (.expert, "Expert")],
            selection: $game.preferences.botLevel, idPrefix: "pref_bots")
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
  WatchPreferencesView(game: BigTwoGame(seed: 2)) {}
}

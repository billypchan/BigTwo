//
//  MenuSheetView.swift
//  Big Two — Preferences, the game history ("export to Memo Pad") and About.
//

import BigTwoKit
import SwiftUI
import UIKit

struct MenuSheetView: View {
  @ObservedObject var game: BigTwoGame
  @Environment(\.dismiss) private var dismiss

  private static let site = URL(string: "https://bigtwo-palmos.sourceforge.net")

  private var version: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? "?"
    let build = info?["CFBundleVersion"] as? String ?? "?"
    return "\(short) (\(build))"
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Toggle("Hong Kong rule set", isOn: $game.preferences.hongKong)
            .accessibilityIdentifier("pref_hongKong")
          Toggle("Autopass", isOn: $game.preferences.autopass)
            .accessibilityIdentifier("pref_autopass")
          Toggle("Autopass on 5-card turns", isOn: $game.preferences.autopassFiveCard)
            .accessibilityIdentifier("pref_autopassFiveCard")
          Toggle("Show cards left in score", isOn: $game.preferences.showCardsLeft)
            .accessibilityIdentifier("pref_showCardsLeft")
        } header: {
          Text("Preferences")
        } footer: {
          Text("Hong Kong rules: the last deal's winner leads, and 23456 is the largest straight. Takes effect from the next deal.")
        }
        Section("Game history") {
          Text(game.historyText)
            .font(.system(size: 12, design: .monospaced))
            .accessibilityIdentifier("history_text")
          Button("Copy history") {
            UIPasteboard.general.string = game.historyText
          }
        }
        Section {
          Button("New game", role: .destructive) {
            game.startGame()
            dismiss()
          }
          .accessibilityIdentifier("menu_new_game")
        }
        Section("About") {
          LabeledContent("Version", value: version)
          Text("Big Two for Palm OS © Woo Kok Tong 1999, Chan Yiu Por Bill 2006.")
            .font(.footnote)
          if let site = Self.site {
            Link("bigtwo-palmos.sourceforge.net", destination: site)
          }
        }
      }
      .navigationTitle("Big Two")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        Button("Done") { dismiss() }
          .accessibilityIdentifier("menu_done")
      }
    }
  }
}

#Preview {
  MenuSheetView(game: BigTwoGame(seed: 2))
}

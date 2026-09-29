//
//  BigTwoWatchApp.swift
//  Big Two on Apple Watch. The rules, the bots and the scoring are BigTwoKit — the
//  same code the phone runs. Only the screen is different: a watch cannot hold the
//  320×320 square, so the hand is a grid and the table is one line.
//

import BigTwoKit
import SwiftUI

@main
struct BigTwoWatchApp: App {
  @StateObject private var unlock = WatchUnlock()
  @StateObject private var game = BigTwoGame(preferences: Preferences(), humanSeats: [1])

  var body: some Scene {
    WindowGroup {
      Group {
        switch unlock.state {
        case .unlocked:
          WatchGameView(game: game)
        case .loading:
          ProgressView()
        case .locked, .unavailable:
          WatchStoreView(unlock: unlock)
        }
      }
      .task { await unlock.refresh() }
    }
  }
}

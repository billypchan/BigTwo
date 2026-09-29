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
  /// ⚠️ Off until `com.billchan.BigTwo.watch` exists in App Store Connect. Until it does
  /// there is nothing to buy, so a paywall would lock the game with no way past it.
  /// `WatchUnlock` and `WatchStoreView` are complete and unused — flip this to gate again.
  private static let paywallEnabled = false

  /// `-seed 2` deals the same hands every launch, so a UI test can assert on cards.
  private static var seed: UInt64? {
    UserDefaults.standard.string(forKey: "seed").flatMap(UInt64.init)
  }

  @StateObject private var unlock = WatchUnlock()
  @StateObject private var game = BigTwoGame(preferences: Preferences(), seed: seed,
                                             humanSeats: [1])

  var body: some Scene {
    WindowGroup {
      Group {
        if !Self.paywallEnabled {
          WatchGameView(game: game)
        } else {
          switch unlock.state {
          case .unlocked:
            WatchGameView(game: game)
          case .loading:
            ProgressView()
          case .locked, .unavailable:
            WatchStoreView(unlock: unlock)
          }
        }
      }
      .task {
        guard Self.paywallEnabled else { return }
        await unlock.refresh()
      }
    }
  }
}

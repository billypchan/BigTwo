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

  private static let uiTestSuite = "WatchUITestPreferences"

  /// `-seed 2` deals the same hands every launch, so a UI test can assert on cards.
  private static var seed: UInt64? {
    UserDefaults.standard.string(forKey: "seed").flatMap(UInt64.init)
  }

  /// The watch keeps its own preferences, so the sort order survives a relaunch the way
  /// it does on the phone. Nothing is shared with the phone's copy — they are separate
  /// devices running separate games.
  ///
  /// ⚠️ Under `UITestMode` this is a throwaway suite, wiped each launch. Without that a
  /// test that toggles the sort order saves it, and the *next* run starts in the other
  /// order and fails on its first assertion — which is exactly what happened once.
  private static func makeStore() -> PreferencesStore {
    guard ProcessInfo.processInfo.arguments.contains("UITestMode"),
          let defaults = UserDefaults(suiteName: uiTestSuite)
    else { return PreferencesStore() }
    defaults.removePersistentDomain(forName: uiTestSuite)
    return PreferencesStore(defaults: defaults)
  }

  private let store: PreferencesStore
  @StateObject private var unlock = WatchUnlock()
  @StateObject private var sync = PreferenceSync()
  @StateObject private var game: BigTwoGame

  init() {
    let store = Self.makeStore()
    self.store = store
    _game = StateObject(wrappedValue: BigTwoGame(preferences: store.load(), seed: Self.seed,
                                                 humanSeats: [1]))
  }

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
      .onChange(of: game.preferences) {
        store.save($0)
        sync.send($0)
      }
      // Settings and player names follow whichever device was edited last.
      .onChange(of: sync.incoming) { incoming in
        guard let incoming, incoming != game.preferences else { return }
        game.preferences = incoming
        game.applyNames(incoming.playerNames)
        store.save(incoming)
        sync.clearIncoming()
      }
      .task {
        guard Self.paywallEnabled else { return }
        await unlock.refresh()
      }
    }
  }
}

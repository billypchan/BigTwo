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
  /// On for the build that goes to review with `com.billchan.BigTwo.watch`. A binary
  /// that plays for free gives the reviewer nothing to buy. The paywall is the first
  /// screen, with Buy and Try one game. UI tests pass `-unlocked YES` (debug only) so
  /// they open on the game.
  private static let paywallEnabled = true

  private static let uiTestSuite = "WatchUITestPreferences"

  /// `-seed 2` deals the same hands every launch, so a UI test can assert on cards.
  private static var seed: UInt64? {
    UserDefaults.standard.string(forKey: "seed").flatMap(UInt64.init)
  }

  /// `-dealsPerGame 1` is the phone's flag. The argument domain may hand back a string.
  private static var dealsPerGame: Int? {
    let defaults = UserDefaults.standard
    if let n = defaults.object(forKey: "dealsPerGame") as? Int { return n }
    return defaults.string(forKey: "dealsPerGame").flatMap(Int.init)
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
  @StateObject private var trial: WatchTrial
  @StateObject private var game: BigTwoGame

  init() {
    let store = Self.makeStore()
    self.store = store
    var preferences = store.load()
    // `-hongKong YES`, same as the phone. The checkbox does not redeal.
    if UserDefaults.standard.bool(forKey: "hongKong") { preferences.hongKong = true }
    let deals = Self.dealsPerGame
    // Paused until the table is on screen. The object exists behind the paywall, and
    // the bots would otherwise play the free game before Try.
    let autoplay = UserDefaults.standard.bool(forKey: "autoplay")
    let game = BigTwoGame(preferences: preferences, seed: Self.seed,
                          humanSeats: autoplay ? [] : [1], startPaused: true)
    if ProcessInfo.processInfo.arguments.contains("UITestMode") {
      game.botDelayOverride = 0.15
    }
    if let deals { game.dealsPerGameOverride = deals }
    _game = StateObject(wrappedValue: game)
    _trial = StateObject(wrappedValue: WatchTrial(allowance: deals ?? 10))
  }

  var body: some Scene {
    WindowGroup {
      Group {
        if showsGame {
          tabs
        } else if Self.paywallEnabled, case .loading = unlock.state {
          ProgressView()
        } else {
          WatchStoreView(unlock: unlock, trial: trial)
        }
      }
      .onChange(of: unlock.state) { previous, new in
        // Bought from the spent paywall. The free game is still the one on the table;
        // start the one they just paid for. Loading → unlocked is a launch, and that
        // game was already dealt.
        guard case .unlocked = new, trial.isSpent, previous != .loading else { return }
        game.startGame()
      }
      .task {
        guard Self.paywallEnabled else { return }
        await unlock.refresh()
      }
    }
  }

  /// Purchased, or still inside the one free game (the finishing score sheet included).
  private var showsGame: Bool {
    if !Self.paywallEnabled { return true }
    if case .unlocked = unlock.state { return true }
    return trial.canPlay
  }

  private var trialActive: Bool {
    Self.paywallEnabled && unlock.state != .unlocked
  }

  // ⚠️ Saving and syncing the preferences are `WatchTabsView`'s, not this scene's: an
  // `App` body is not a reliable place to watch a `@StateObject` it owns, and a setting
  // changed on the watch was applied to the game and never written to the store.
  private var tabs: some View {
    WatchTabsView(game: game, sync: sync, trial: trial, store: store, trialActive: trialActive)
  }
}

//
//  BigTwoApp.swift
//  Big Two — iOS remake of the Palm OS game.
//  Original © Woo Kok Tong, 1999 · © Bill Chan, 2006 · GPL
//

import BigTwoKit
import SwiftUI

@main
struct BigTwoApp: App {
  private let store: PreferencesStore
  @StateObject private var game: BigTwoGame

  init() {
    let store = LaunchOptions.preferencesStore()
    let game = BigTwoGame(preferences: store.load(),
                          seed: LaunchOptions.seed,
                          humanSeats: LaunchOptions.autoplay ? [] : [1])
    if LaunchOptions.uiTestMode { game.botDelayOverride = 0.15 }
    if let n = LaunchOptions.dealsPerGame { game.dealsPerGameOverride = n }
    self.store = store
    _game = StateObject(wrappedValue: game)
  }

  var body: some Scene {
    WindowGroup {
      GameView(game: game)
        .preferredColorScheme(.light)
        .onChange(of: game.preferences) { store.save($0) }
    }
  }
}

//
//  WatchTabsView.swift
//  Big Two — the watch's three pages: the table, Preferences and About. The phone reaches
//  those two by tapping its title; a watch has no menu bar, and paging is what it does.
//
//  ⚠️ Saving the preferences lives here, not in the `App`. An `App`'s body is not a
//  reliable place to watch a `@StateObject` it owns — a change made on the Preferences
//  page applied to the game and was never written, so it was gone on the next launch.
//  This view observes the game directly, so its `onChange` always runs.
//

import BigTwoKit
import SwiftUI

struct WatchTabsView: View {
  @ObservedObject var game: BigTwoGame
  @ObservedObject var sync: PreferenceSync
  let store: PreferencesStore

  @State private var page = Page.table

  private enum Page: Hashable { case table, preferences, about }

  var body: some View {
    // Horizontal paging, not vertical: the table scrolls under the Digital Crown, and a
    // vertically paged TabView would take the Crown away from it.
    TabView(selection: $page) {
      WatchGameView(game: game).tag(Page.table)
      WatchPreferencesView(game: game) { page = .table }.tag(Page.preferences)
      WatchAboutView().tag(Page.about)
    }
    .tabViewStyle(.page)
    .onChange(of: game.preferences) { _, preferences in
      store.save(preferences)
      sync.send(preferences)
    }
    // Settings and player names follow whichever device was edited last.
    .onChange(of: sync.incoming) { _, incoming in
      guard let incoming, incoming != game.preferences else { return }
      game.preferences = incoming
      game.applyNames(incoming.playerNames)
      store.save(incoming)
      sync.clearIncoming()
    }
  }
}

#Preview {
  WatchTabsView(game: BigTwoGame(seed: 2), sync: PreferenceSync(), store: PreferencesStore())
}

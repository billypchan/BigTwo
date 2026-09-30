//
//  WatchTabsView.swift
//  Big Two — the watch's three pages: the table, Preferences and About. The phone reaches
//  those two by tapping its title; a watch has no menu, and paging is what it does.
//

import BigTwoKit
import SwiftUI

struct WatchTabsView: View {
  @ObservedObject var game: BigTwoGame

  var body: some View {
    // Horizontal paging, not vertical: the table scrolls under the Digital Crown, and a
    // vertically paged TabView would take the Crown away from it.
    TabView {
      WatchGameView(game: game)
      WatchPreferencesView(game: game)
      WatchAboutView()
    }
    .tabViewStyle(.page)
  }
}

#Preview {
  WatchTabsView(game: BigTwoGame(seed: 2))
}

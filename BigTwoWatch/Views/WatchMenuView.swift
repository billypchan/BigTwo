//
//  WatchMenuView.swift
//  Big Two — the menu that drops from the title tab, as it did on the Palm and as it does
//  on the phone. A watch reaches Preferences and About by paging, so only the items that
//  have nowhere else to live are here.
//

import SwiftUI

struct WatchMenuView: View {
  struct Item: Identifiable {
    let id: String
    let title: String
    let action: () -> Void
  }

  let items: [Item]

  var body: some View {
    // ⚠️ The white face is a layer of this stack, not a `.background`. A bare `Color`
    // handed to `.background` spreads into the safe area — the face ran from under the
    // title bar to the top of the screen — and a `Rectangle().fill(…)` background did not
    // draw at all behind the shadow. Inside the stack it is sized by the items and there
    // is nothing to go wrong.
    ZStack {
      Rectangle().fill(Color.cardFace)
      VStack(alignment: .leading, spacing: 0) {
        ForEach(items) { item in
          Button(action: item.action) {
            Text(item.title)
              .font(.palm(13, .heavy))
              .foregroundColor(.ink)
              .lineLimit(1)
              .minimumScaleFactor(0.7)
              .padding(.horizontal, 8)
              // ⚠️ `height`, not `minHeight`. A minimum takes the height it is *proposed*
              // when that is larger, and in a stack filling the screen that is the whole
              // screen: the menu's white face ran from under the title to the top edge,
              // with the one item floating in the middle of it.
              .frame(maxWidth: .infinity, alignment: .leading)
              .frame(height: 30)
              .contentShape(Rectangle())
          }
          .buttonStyle(WatchPalmPressStyle())
          .accessibilityIdentifier("menu_\(item.id)")
        }
      }
    }
    .frame(width: 112)
    .fixedSize(horizontal: false, vertical: true)
    .overlay(Rectangle().strokeBorder(Color.ink, lineWidth: 1))
    // The Palm's menu shadow: a hard 2px offset, not a blur.
    .background(Rectangle().fill(Color.ink).offset(x: 2, y: 2))
  }
}

#Preview {
  WatchMenuView(items: [.init(id: "new_game", title: "New Game") {}])
    .padding()
    .background(Color.felt)
}

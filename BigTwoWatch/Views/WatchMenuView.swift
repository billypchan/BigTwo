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
    VStack(alignment: .leading, spacing: 0) {
      ForEach(items) { item in
        Button(action: item.action) {
          Text(item.title)
            .font(.palm(13, .heavy))
            .foregroundColor(.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(WatchPalmPressStyle())
        .accessibilityIdentifier("menu_\(item.id)")
      }
    }
    .frame(width: 112)
    .background(Color.cardFace)
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

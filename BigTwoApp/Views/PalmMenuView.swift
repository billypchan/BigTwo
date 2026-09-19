//
//  PalmMenuView.swift
//  Big Two — the Palm OS menu that drops from the title tab.
//

import SwiftUI

struct PalmMenuView: View {
  struct Item: Identifiable {
    let id: String
    let title: String
    let action: () -> Void
  }

  let items: [Item]

  @Environment(\.palmUnit) private var u

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(items) { item in
        Button(action: item.action) {
          Text(item.title)
            .font(.palm(14 * u, .heavy))
            .foregroundColor(.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 6 * u)
            .frame(maxWidth: .infinity, minHeight: PalmMetrics.minTouch, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PalmPressStyle())
        .accessibilityIdentifier("menu_\(item.id)")
      }
    }
    .frame(width: 190 * u)
    .background(Color.cardFace)
    .overlay(Rectangle().strokeBorder(Color.ink, lineWidth: max(1, u)))
    // The Palm's menu shadow: a hard 2px offset, not a blur.
    .background(Rectangle().fill(Color.ink).offset(x: 2 * u, y: 2 * u))
  }
}

#Preview {
  PalmMenuView(items: [
    .init(id: "new_game", title: "New Game") {},
    .init(id: "preferences", title: "Preferences") {},
  ])
  .padding()
  .background(Color.felt)
}

//
//  TitleBarView.swift
//  Big Two — the Palm form title: a navy "Big Two" tab over a navy rule. Tapping the
//  title opens the menu, as it did on the Palm.
//

import SwiftUI

struct TitleBarView: View {
  let deal: Int
  let dealsPerGame: Int
  let onMenu: () -> Void

  @Environment(\.palmUnit) private var u

  var body: some View {
    ZStack(alignment: .bottom) {
      Rectangle().fill(Color.titleNavy).frame(height: 2 * u)
      HStack(alignment: .bottom, spacing: 0) {
        Button(action: onMenu) {
          Text("Big Two")
            .font(.palm(15 * u, .heavy))
            .foregroundColor(.felt)
            .padding(.leading, 5 * u)
            .padding(.trailing, 9 * u)
            .frame(height: 22 * u)
            .background(TitleTabShape(radius: 7 * u).fill(Color.titleNavy))
            .contentShape(Rectangle())
        }
        .buttonStyle(PalmPressStyle())
        .accessibilityLabel("Menu")
        .accessibilityIdentifier("menu_button")
        Spacer()
        Text("Deal \(deal)/\(dealsPerGame)")
          .font(.palm(12 * u))
          .foregroundColor(.ink)
          .padding(.trailing, 4 * u)
          .padding(.bottom, 5 * u)
          .accessibilityIdentifier("deal_label")
      }
    }
  }
}

#Preview {
  TitleBarView(deal: 1, dealsPerGame: 10) {}
    .frame(height: 30)
    .background(Color.felt)
}

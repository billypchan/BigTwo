//
//  TitleBarView.swift
//  Big Two — the Palm form title: a navy "Big Two" tab sitting *on* a navy rule. Tapping
//  the title opens the menu, as it did on the Palm.
//
//  ⚠️ The tab is 22 units and the bar 24, so the tab's bottom edge runs into the rule and
//  its corners never show. It used to carry `minHeight: PalmMetrics.minTouch`, which made
//  the bar 44pt and left the tab floating 16pt above the rule — and the extra hit area
//  reached down into the first player's row. The title tab is the documented exception to
//  the 44pt rule for exactly this reason: the bar has nowhere to grow into.
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
          Text(L10n.string("Big Two"))
            .font(.palm(15 * u, .heavy))
            .foregroundColor(.felt)
            .padding(.leading, 5 * u)
            .padding(.trailing, 9 * u)
            .frame(height: 22 * u)
            .background(TitleTabShape(radius: 7 * u).fill(Color.titleNavy))
            .contentShape(Rectangle())
        }
        .buttonStyle(PalmPressStyle())
        .accessibilityLabel(L10n.string("Menu"))
        .accessibilityIdentifier("menu_button")
        Spacer()
        Text(L10n.string("Deal %d/%d", deal, dealsPerGame))
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

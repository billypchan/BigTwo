//
//  WatchTitleBarView.swift
//  Big Two — the phone's form title, shrunk into the watch's top bar so it shares the
//  row with the system clock: the navy "Big Two" tab and the deal counter. The clock
//  owns the right of that row, so both sit leading.
//

import SwiftUI

struct WatchTitleBarView: View {
  let deal: Int
  let dealsPerGame: Int

  var body: some View {
    HStack(spacing: 4) {
      Text(L10n.string("Big Two"))
        .font(.palm(12, .heavy))
        .foregroundColor(.felt)
        .lineLimit(1)
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.titleNavy))
      Text(L10n.string("Deal %d/%d", deal, dealsPerGame))
        .font(.palm(11))
        .foregroundColor(.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityIdentifier("deal_label")
    }
    .fixedSize()
  }
}

#Preview {
  WatchTitleBarView(deal: 1, dealsPerGame: 10)
    .padding()
    .background(Color.felt)
}

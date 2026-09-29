//
//  WatchTitleBarView.swift
//  Big Two — the phone's form title on a watch: a navy "Big Two" tab over a navy rule,
//  with the deal counter where the phone puts it. It lives in the top safe-area inset,
//  under the system clock, so it stays put while the table scrolls.
//

import SwiftUI

struct WatchTitleBarView: View {
  let deal: Int
  let dealsPerGame: Int

  var body: some View {
    ZStack(alignment: .bottom) {
      Rectangle().fill(Color.titleNavy).frame(height: 2)
      HStack(alignment: .bottom, spacing: 0) {
        Text(L10n.string("Big Two"))
          .font(.palm(13, .heavy))
          .foregroundColor(.felt)
          .padding(.leading, 5)
          .padding(.trailing, 8)
          .frame(height: 20)
          .background(
            UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6)
              .fill(Color.titleNavy)
          )
        Spacer(minLength: 2)
        Text(L10n.string("Deal %d/%d", deal, dealsPerGame))
          .font(.palm(11))
          .foregroundColor(.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .padding(.trailing, 3)
          .padding(.bottom, 3)
          .accessibilityIdentifier("deal_label")
      }
    }
    .frame(height: 22)
    .background(Color.felt)
  }
}

#Preview {
  WatchTitleBarView(deal: 1, dealsPerGame: 10)
    .background(Color.felt)
}

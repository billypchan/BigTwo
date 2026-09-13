//
//  HistoryDialogView.swift
//  Big Two — "Game History": every move of the deal, and Copy (the Palm exported it to
//  the Memo Pad).
//

import SwiftUI
import UIKit

struct HistoryDialogView: View {
  let deal: Int
  let text: String
  let onOK: () -> Void

  @Environment(\.palmUnit) private var u

  var body: some View {
    PalmDialogView(title: "Game History of deal \(deal)") {
      ScrollView {
        Text(text)
          .font(.system(size: 11 * u, weight: .semibold, design: .monospaced))
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityIdentifier("history_text")
      }
      .frame(height: 200 * u)
    } buttons: {
      PalmButtonView(title: "OK", width: 40, action: onOK)
        .accessibilityIdentifier("history_ok")
      PalmButtonView(title: "Copy", width: 50) {
        UIPasteboard.general.string = text
      }
      .accessibilityIdentifier("history_copy")
    }
  }
}

#Preview {
  HistoryDialogView(deal: 1, text: "— Deal 1 —\nBill: 3♦\nCarl: 5♣\nDean: pass", onOK: {})
    .padding()
    .background(Color.felt)
}

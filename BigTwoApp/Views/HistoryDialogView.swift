//
//  HistoryDialogView.swift
//  Big Two — "Game History": open hands and every step. Copy, or Export a text file.
//

import SwiftUI
import UIKit

struct HistoryDialogView: View {
  let deal: Int
  let text: String
  let onOK: () -> Void

  @Environment(\.palmUnit) private var u
  @State private var exportFile: ExportFile?

  var body: some View {
    PalmDialogView(title: L10n.string("Game History of deal %d", deal)) {
      ScrollView {
        Text(text)
          .font(.system(size: 11 * u, weight: .semibold, design: .monospaced))
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityIdentifier("history_text")
      }
      .frame(height: 200 * u)
    } buttons: {
      PalmButtonView(title: L10n.string("OK"), width: 36, action: onOK)
        .accessibilityIdentifier("history_ok")
      PalmButtonView(title: L10n.string("Copy"), width: 50) {
        UIPasteboard.general.string = text
      }
      .accessibilityIdentifier("history_copy")
      PalmButtonView(title: L10n.string("Export"), width: 58, action: export)
        .accessibilityIdentifier("history_export")
    }
    .sheet(item: $exportFile) { file in
      ActivityView(items: [file.url])
    }
  }

  /// Same text as the screen, so a deal still in play is not written out in the clear.
  private func export() {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("BigTwo.txt")
    guard (try? text.write(to: url, atomically: true, encoding: .utf8)) != nil else { return }
    exportFile = ExportFile(url: url)
  }
}

private struct ExportFile: Identifiable {
  let url: URL
  var id: String { url.path }
}

private struct ActivityView: UIViewControllerRepresentable {
  let items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#Preview {
  HistoryDialogView(deal: 1, text: "— Deal 1 —\nBill: 3♦\nCarl: 5♣\nDean: pass", onOK: {})
    .padding()
    .background(Color.felt)
}

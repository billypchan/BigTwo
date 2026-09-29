//
//  HistoryDialogView.swift
//  Big Two — "Game History": open hands and every step, one game at a time.
//  ◄ ► page back through earlier games; Copy or Export write the game on screen.
//

import BigTwoKit
import SwiftUI
import UIKit

struct HistoryDialogView: View {
  let rounds: [HistoryRound]
  let onOK: () -> Void

  @Environment(\.palmUnit) private var u
  @State private var index = 0
  @State private var exportFile: ExportFile?

  var body: some View {
    PalmDialogView(title: L10n.string("Game History")) {
      VStack(spacing: 4 * u) {
        HStack(spacing: 4 * u) {
          // ◄ goes back in time: the rounds are newest first.
          PalmButtonView(title: "◄", enabled: index + 1 < rounds.count, width: 18) {
            index += 1
          }
          .accessibilityIdentifier("history_prev")
          Text(label)
            .font(.palm(12 * u))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("history_round")
          PalmButtonView(title: "►", enabled: index > 0, width: 18) {
            index -= 1
          }
          .accessibilityIdentifier("history_next")
        }
        ScrollView {
          Text(text)
            .font(.system(size: 11 * u, weight: .semibold, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("history_text")
        }
        .frame(height: 180 * u)
      }
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

  private var round: HistoryRound? {
    rounds.indices.contains(index) ? rounds[index] : rounds.first
  }

  private var text: String { round?.text ?? "" }

  /// The game on the table has no date worth showing — it is "This game" until it ends.
  private var label: String {
    guard let round else { return "" }
    if round.isCurrent { return L10n.string("This game") }
    guard let started = round.startedAt else { return "#\(round.id)" }
    return Self.dateLabel.string(from: started)
  }

  /// Same text as the screen, so a deal still in play is not written out in the clear.
  private func export() {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    guard (try? text.write(to: url, atomically: true, encoding: .utf8)) != nil else { return }
    exportFile = ExportFile(url: url)
  }

  /// Not the shown label: that one is localized and can hold a slash.
  private var fileName: String {
    guard let started = round?.startedAt else { return "BigTwo.txt" }
    return "BigTwo-\(Self.fileDate.string(from: started)).txt"
  }

  private static let dateLabel: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .short
    f.timeStyle = .short
    return f
  }()

  private static let fileDate: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd-HHmm"
    return f
  }()
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
  HistoryDialogView(rounds: [
    HistoryRound(id: 0, startedAt: Date(), deals: 1,
                 text: "— Deal 1 —\nBill: 3♦\nCarl: 5♣\nDean: pass"),
    HistoryRound(id: 1, startedAt: Date(timeIntervalSinceNow: -3600), deals: 10,
                 text: "— Deal 1 —\nBill: 3♦"),
  ], onOK: {})
  .padding()
  .background(Color.felt)
}

//
//  AboutDialogView.swift
//  Big Two — version and credits.
//

import SwiftUI

struct AboutDialogView: View {
  let onOK: () -> Void

  @Environment(\.palmUnit) private var u
  @Environment(\.openURL) private var openURL

  private var version: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? "?"
    let build = info?["CFBundleVersion"] as? String ?? "?"
    return "\(short) (\(build))"
  }

  var body: some View {
    PalmDialogView(title: "About Big Two") {
      VStack(spacing: 6 * u) {
        Text("Big Two \(version)").font(.palm(15 * u, .heavy))
        Text("Remade for iPhone by Chan Yiu Por Bill, 2026.")
        // ⚠️ No other platform's name here or in the store copy (guideline 2.3.10).
        Text("After the 1999 handheld game by Woo Kok Tong and Chan Yiu Por Bill.")
        Text("I will not play with real money.").foregroundColor(.inkDim)
      }
      .font(.palm(12 * u, .regular))
      .multilineTextAlignment(.center)
    } buttons: {
      PalmButtonView(title: "OK", width: 40, action: onOK)
        .accessibilityIdentifier("about_ok")
      PalmButtonView(title: "SharedKit", width: 72, action: openSharedKit)
        .accessibilityIdentifier("about_sharedkit")
    }
  }

  private func openSharedKit() {
    guard let url = URL(string: "https://github.com/billypchan/SharedKit") else { return }
    openURL(url)
  }
}

#Preview {
  AboutDialogView(onOK: {})
    .padding()
    .background(Color.felt)
}

//
//  WatchAboutView.swift
//  Big Two — the About page on the watch. Same wording as the phone, minus the rows that
//  open a browser: a watch has none, so Share, Rate, Report and Source stay on the phone.
//

import SwiftUI

struct WatchAboutView: View {
  private var version: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? "?"
    let build = info?["CFBundleVersion"] as? String ?? "?"
    return "\(short) (\(build))"
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 6) {
        Text(L10n.string("About Big Two"))
          .font(.palm(14, .heavy))
        Text(L10n.string("Big Two %@", version))
          .font(.palm(13, .heavy))
          .accessibilityIdentifier("about_version")
        Text(L10n.string("Remade for iPhone by Bill Chan, 2026."))
        // ⚠️ No other platform's name here or in the store copy (guideline 2.3.10).
        Text(L10n.string("After the 1999 handheld game by Woo Kok Tong and Bill Chan."))
        // ⚠️ Not `.inkDim`: the phone dims this against a white dialog body, and the same
        // grey on the green felt is barely legible.
        Text(L10n.string("I will not play with real money"))
          .font(.palm(10, .regular))
      }
      .font(.palm(11, .regular))
      .foregroundColor(.ink)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 4)
    }
    .background(Color.felt.ignoresSafeArea())
  }
}

#Preview {
  WatchAboutView()
}

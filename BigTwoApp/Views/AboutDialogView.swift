//
//  AboutDialogView.swift
//  Big Two — version, credits, and support rows (share / rate / report / X).
//  No SharedKit button. Do not import billypchan/SharedKit (iOS 17).
//

import StoreKit
import SwiftUI
import UIKit

struct AboutDialogView: View {
  let onOK: () -> Void

  @Environment(\.palmUnit) private var u
  @Environment(\.openURL) private var openURL
  @State private var shareItem: ShareItem?

  private var version: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? "?"
    let build = info?["CFBundleVersion"] as? String ?? "?"
    return "\(short) (\(build))"
  }

  var body: some View {
    PalmDialogView(title: L10n.string("About Big Two")) {
      VStack(spacing: 6 * u) {
        VStack(spacing: 6 * u) {
          Text(L10n.string("Big Two %@", version)).font(.palm(15 * u, .heavy))
          Text(L10n.string("Remade for iPhone by Bill Chan, 2026."))
          // ⚠️ No other platform's name here or in the store copy (guideline 2.3.10).
          Text(L10n.string("After the 1999 handheld game by Woo Kok Tong and Bill Chan."))
          Text(L10n.string("I will not play with real money.")).foregroundColor(.inkDim)
        }
        .font(.palm(12 * u, .regular))
        .multilineTextAlignment(.center)
        VStack(alignment: .leading, spacing: 0) {
          row("Share this App", id: "about_share", action: shareApp)
          row("Rate this App", id: "about_rate", action: rateApp)
          row("Report an Issue", id: "about_report") { open(Self.github) }
          row("Follow on X", id: "about_x") { open(Self.twitter) }
        }
      }
    } buttons: {
      PalmButtonView(title: L10n.string("OK"), width: 40, action: onOK)
        .accessibilityIdentifier("about_ok")
    }
    .sheet(item: $shareItem) { item in
      ActivityView(items: [item.url])
    }
  }

  private func row(_ key: String, id: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(L10n.string(key))
        .font(.palm(13 * u))
        .foregroundColor(.ink)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 20u, not 44pt: four rows plus credits have to fit the 320 square.
        .frame(minHeight: 20 * u, alignment: .leading)
        .contentShape(Rectangle())
    }
    .buttonStyle(PalmPressStyle())
    .accessibilityIdentifier(id)
  }

  private func shareApp() {
    if let url = Self.appStore { shareItem = ShareItem(url: url) }
  }

  private func rateApp() {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    guard let scene else { return }
    SKStoreReviewController.requestReview(in: scene)
  }

  private func open(_ url: URL?) {
    guard let url else { return }
    openURL(url)
  }

  private static let appStore = URL(string: "https://apps.apple.com/app/id6811548119")
  private static let github = URL(string: "https://github.com/billypchan/BigTwo")
  private static let twitter = URL(string: "https://x.com/billchanios")
}

private struct ShareItem: Identifiable {
  let url: URL
  var id: String { url.absoluteString }
}

private struct ActivityView: UIViewControllerRepresentable {
  let items: [Any]
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#Preview {
  AboutDialogView(onOK: {})
    .padding()
    .background(Color.felt)
}

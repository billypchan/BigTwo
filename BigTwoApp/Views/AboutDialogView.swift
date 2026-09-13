//
//  AboutDialogView.swift
//  Big Two — version and credits.
//

import SwiftUI

struct AboutDialogView: View {
  let onOK: () -> Void

  @Environment(\.palmUnit) private var u

  private static let site = URL(string: "https://bigtwo-palmos.sourceforge.net")

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
        Text("Big Two for Palm OS © Woo Kok Tong 1999, Chan Yiu Por Bill 2006.")
        if let site = Self.site {
          Link("bigtwo-palmos.sourceforge.net", destination: site)
            .foregroundColor(.titleNavy)
        }
        Text("I will not play with real money.").foregroundColor(.inkDim)
      }
      .font(.palm(12 * u, .regular))
      .multilineTextAlignment(.center)
    } buttons: {
      PalmButtonView(title: "OK", width: 40, action: onOK)
        .accessibilityIdentifier("about_ok")
    }
  }
}

#Preview {
  AboutDialogView(onOK: {})
    .padding()
    .background(Color.felt)
}

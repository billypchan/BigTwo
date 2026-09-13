//
//  PalmDialogView.swift
//  Big Two — a Palm OS modal form: navy title bar, white body, buttons along the bottom.
//

import SwiftUI

struct PalmDialogView<Content: View, Buttons: View>: View {
  let title: String
  let content: Content
  let buttons: Buttons

  @Environment(\.palmUnit) private var u

  init(title: String, @ViewBuilder content: () -> Content, @ViewBuilder buttons: () -> Buttons) {
    self.title = title
    self.content = content()
    self.buttons = buttons()
  }

  var body: some View {
    VStack(spacing: 0) {
      Text(title)
        .font(.palm(14 * u, .heavy))
        .foregroundColor(.cardFace)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
        .frame(height: 22 * u)
        .background(Color.titleNavy)
      content
        .padding(.horizontal, 8 * u)
        .padding(.top, 4 * u)
      HStack(spacing: 8 * u) { buttons }
    }
    .foregroundColor(.ink)
    .background(Color.cardFace)
    .clipShape(RoundedRectangle(cornerRadius: 6 * u))
    .overlay(RoundedRectangle(cornerRadius: 6 * u).strokeBorder(Color.titleNavy, lineWidth: 2 * u))
    .accessibilityElement(children: .contain)
  }
}

#Preview {
  PalmDialogView(title: "Preferences") {
    Text("Game speed")
  } buttons: {
    PalmButtonView(title: "OK", width: 40) {}
  }
  .padding()
  .background(Color.felt)
}

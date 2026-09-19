//
//  NamesDialogView.swift
//  Big Two — Palm v2.0.11 editable player names.
//

import SwiftUI

struct NamesDialogView: View {
  @Binding var names: [String]
  let placeholders: [String]
  let onOK: () -> Void

  @Environment(\.palmUnit) private var u

  var body: some View {
    PalmDialogView(title: NSLocalizedString("Player names", comment: "")) {
      VStack(alignment: .leading, spacing: 4 * u) {
        ForEach(0..<4, id: \.self) { i in
          HStack(spacing: 6 * u) {
            Text("\(i + 1).")
              .font(.palm(13 * u))
              .frame(width: 16 * u, alignment: .trailing)
            TextField(placeholder(i), text: binding(i))
              .font(.palm(13 * u))
              .disableAutocorrection(true)
              .textFieldStyle(PlainTextFieldStyle())
              .padding(.horizontal, 4 * u)
              .frame(height: 22 * u)
              .background(Color.cardFace)
              .overlay(Rectangle().strokeBorder(Color.ink, lineWidth: max(1, u)))
              .accessibilityIdentifier("pref_name_\(i)")
          }
        }
      }
      .padding(.bottom, 6 * u)
    } buttons: {
      PalmButtonView(title: NSLocalizedString("OK", comment: ""), width: 40, action: onOK)
        .accessibilityIdentifier("names_ok")
    }
  }

  private func placeholder(_ i: Int) -> String {
    i < placeholders.count ? placeholders[i] : PlayerNames.keys[i]
  }

  private func binding(_ i: Int) -> Binding<String> {
    Binding(
      get: { i < names.count ? names[i] : "" },
      set: { newValue in
        if names.count < 4 { names = (names + ["", "", "", ""]).prefix(4).map { $0 } }
        names[i] = newValue
      }
    )
  }
}

#Preview {
  NamesDialogView(names: .constant(["", "", "", ""]), placeholders: PlayerNames.keys, onOK: {})
    .padding()
    .background(Color.felt)
}

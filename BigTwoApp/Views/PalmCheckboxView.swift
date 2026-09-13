//
//  PalmCheckboxView.swift
//  Big Two — a Palm OS checkbox row.
//

import SwiftUI

struct PalmCheckboxView: View {
  let title: String
  @Binding var isOn: Bool

  @Environment(\.palmUnit) private var u

  var body: some View {
    Button { isOn.toggle() } label: {
      HStack(spacing: 6 * u) {
        ZStack {
          RoundedRectangle(cornerRadius: u).strokeBorder(Color.ink, lineWidth: max(1, u))
          if isOn { Text(verbatim: "✓").font(.palm(12 * u, .heavy)) }
        }
        .frame(width: 13 * u, height: 13 * u)
        Text(title)
          .font(.palm(13 * u))
          .multilineTextAlignment(.leading)
        Spacer(minLength: 0)
      }
      .foregroundColor(.ink)
      .frame(minHeight: PalmMetrics.minTouch)
      .contentShape(Rectangle())
    }
    .buttonStyle(PalmPressStyle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue(isOn ? "1" : "0")
    .accessibilityAddTraits(.isButton)
  }
}

#Preview {
  VStack(alignment: .leading) {
    PalmCheckboxView(title: "Auto pass", isOn: .constant(true))
    PalmCheckboxView(title: "Use Hong Kong Rule Set", isOn: .constant(false))
  }
  .padding()
  .background(Color.cardFace)
}

//
//  PalmButtonView.swift
//  Big Two — the Palm OS push button: a white pill with a black border.
//

import SwiftUI

struct PalmButtonView: View {
  let title: String
  var enabled = true
  /// In Palm units.
  var width: CGFloat = 50
  let action: () -> Void

  @Environment(\.palmUnit) private var u

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.palm(13 * u))
        .foregroundColor(enabled ? .ink : .inkDim)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(width: width * u, height: 20 * u)
        .background(Capsule().fill(Color.cardFace))
        .overlay(Capsule().strokeBorder(enabled ? Color.ink : Color.inkDim, lineWidth: max(1, u)))
        .frame(minWidth: PalmMetrics.minTouch, minHeight: PalmMetrics.minTouch)
        .contentShape(Rectangle())
    }
    .buttonStyle(PalmPressStyle())
    .disabled(!enabled)
  }
}

#Preview {
  HStack {
    PalmButtonView(title: "Play") {}
    PalmButtonView(title: "Pass", enabled: false) {}
    PalmButtonView(title: "OK", width: 40) {}
  }
  .padding()
  .background(Color.felt)
}

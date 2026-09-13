//
//  PalmPushButtonsView.swift
//  Big Two — a Palm OS push-button group ("Slow | Medium | Fast"): the chosen one is navy.
//

import SwiftUI

struct PalmPushButtonsView<Value: Hashable>: View {
  let options: [(value: Value, label: String)]
  @Binding var selection: Value
  /// Each segment's accessibility identifier is `<idPrefix>_<label>`.
  let idPrefix: String

  @Environment(\.palmUnit) private var u

  var body: some View {
    HStack(spacing: 0) {
      ForEach(Array(options.enumerated()), id: \.offset) { _, option in
        let chosen = option.value == selection
        Button { selection = option.value } label: {
          Text(option.label)
            .font(.palm(12 * u))
            .foregroundColor(chosen ? .cardFace : .ink)
            .padding(.horizontal, 5 * u)
            .frame(height: 18 * u)
            .background(chosen ? Color.titleNavy : Color.cardFace)
            .overlay(Rectangle().strokeBorder(Color.ink, lineWidth: max(1, u * 0.8)))
            .frame(minHeight: PalmMetrics.minTouch)
            .contentShape(Rectangle())
        }
        .buttonStyle(PalmPressStyle())
        .accessibilityIdentifier("\(idPrefix)_\(option.label)")
        .accessibilityAddTraits(chosen ? .isSelected : [])
      }
    }
  }
}

#Preview {
  PalmPushButtonsView(options: [(1, "Slow"), (2, "Medium"), (3, "Fast")],
                      selection: .constant(3), idPrefix: "speed")
    .padding()
    .background(Color.cardFace)
}

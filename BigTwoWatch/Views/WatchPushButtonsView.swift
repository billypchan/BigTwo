//
//  WatchPushButtonsView.swift
//  Big Two — the Palm push-button group ("Slow | Medium | Fast"), sized for a watch.
//  The chosen segment is navy, as on the phone.
//

import SwiftUI

struct WatchPushButtonsView<Value: Hashable>: View {
  let options: [(value: Value, label: String)]
  @Binding var selection: Value
  /// Each segment's identifier is `<idPrefix>_<English label>`, so a UI test stays
  /// locale-stable while the visible text is translated.
  let idPrefix: String

  var body: some View {
    HStack(spacing: 0) {
      ForEach(Array(options.enumerated()), id: \.offset) { _, option in
        let chosen = option.value == selection
        Button { selection = option.value } label: {
          Text(L10n.string(option.label))
            .font(.palm(11))
            .foregroundColor(chosen ? .cardFace : .ink)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
            .frame(height: 22)
            .background(chosen ? Color.titleNavy : Color.cardFace)
            .overlay(Rectangle().strokeBorder(Color.ink, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(WatchPalmPressStyle())
        .accessibilityIdentifier("\(idPrefix)_\(option.label)")
      }
    }
  }
}

#Preview {
  WatchPushButtonsView(options: [(0, "Slow"), (1, "Medium"), (2, "Fast")],
                       selection: .constant(1), idPrefix: "pref_speed")
    .padding()
    .background(Color.felt)
}

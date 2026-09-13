//
//  PalmButtonView.swift
//  Big Two — the flat, bordered Palm button.
//

import SwiftUI

struct PalmButtonView: View {
  let title: String
  var wide = false
  var enabled = true
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.palm(14))
        .foregroundColor(.ink)
        .padding(.horizontal, wide ? 18 : 10)
        .frame(height: 30)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.chrome))
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.ink, lineWidth: 1))
        // The Palm look is 30pt; the finger still gets 44.
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .opacity(enabled ? 1 : 0.4)
    .disabled(!enabled)
  }
}

#Preview {
  HStack {
    PalmButtonView(title: "2") {}
    PalmButtonView(title: "Clear", enabled: false) {}
    PalmButtonView(title: "Play", wide: true) {}
  }
  .padding()
  .background(Color.felt)
}

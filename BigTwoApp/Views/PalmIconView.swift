//
//  PalmIconView.swift
//  Big Two — the small boxed icons beside Play and Pass: an empty box (clear the
//  selection) and a card showing the sort you would switch to.
//

import SwiftUI

struct PalmIconView: View {
  /// Empty draws the bare box.
  let glyph: String
  var enabled = true
  let action: () -> Void

  @Environment(\.palmUnit) private var u

  var body: some View {
    Button(action: action) {
      ZStack {
        if !glyph.isEmpty {
          RoundedRectangle(cornerRadius: 2 * u).fill(Color.cardFace)
          Text(glyph).font(.palm(13 * u)).foregroundColor(.ink)
        }
        RoundedRectangle(cornerRadius: 2 * u)
          .strokeBorder(enabled ? Color.ink : Color.inkDim, lineWidth: max(1, u))
      }
      .frame(width: 20 * u, height: 20 * u)
      .frame(minWidth: PalmMetrics.minTouch, minHeight: PalmMetrics.minTouch)
      .contentShape(Rectangle())
    }
    .buttonStyle(PalmPressStyle())
    .disabled(!enabled)
  }
}

#Preview {
  HStack {
    PalmIconView(glyph: "") {}
    PalmIconView(glyph: "♠") {}
    PalmIconView(glyph: "2") {}
  }
  .padding()
  .background(Color.felt)
}

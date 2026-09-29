//
//  WatchPalmIconView.swift
//  Big Two — the phone's small square icon button: white face, black border, one glyph.
//  Used for the sort toggle, which shows the order a tap switches *to*, as on the phone.
//

import SwiftUI

struct WatchPalmIconView: View {
  let glyph: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(verbatim: glyph)
        .font(.palm(13))
        .foregroundColor(.ink)
        .frame(width: 26, height: 26)
        .background(RoundedRectangle(cornerRadius: 3).fill(Color.cardFace))
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color.ink, lineWidth: 1))
        .contentShape(Rectangle())
    }
    .buttonStyle(WatchPalmPressStyle())
  }
}

#Preview {
  HStack(spacing: 4) {
    WatchPalmIconView(glyph: "♠") {}
    WatchPalmIconView(glyph: "2") {}
  }
  .padding()
  .background(Color.felt)
}

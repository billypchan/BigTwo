//
//  WatchPalmIconView.swift
//  Big Two — the watch's round action button: a white disc with a black border and one
//  mark on it. All three of the bottom bar's actions are these, because a watch bar has
//  room for three discs and not for three worded pills.
//
//  The sort toggle draws a literal glyph rather than a symbol: ♠ / 2 says *which order a
//  tap switches to*, which no SF Symbol says.
//

import SwiftUI

struct WatchPalmIconView: View {
  var systemImage: String?
  var glyph: String?
  var enabled = true
  var diameter: CGFloat = 40
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Group {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.system(size: diameter * 0.38, weight: .heavy))
        } else if let glyph {
          Text(verbatim: glyph).font(.palm(diameter * 0.42, .heavy))
        }
      }
      // Palm greys the mark and keeps the white disc; a faded-out button is not this app.
      .foregroundColor(enabled ? .ink : .inkDim)
      .frame(width: diameter, height: diameter)
      .background(Circle().fill(Color.cardFace))
      .overlay(Circle().strokeBorder(enabled ? Color.ink : Color.inkDim, lineWidth: 1))
      .contentShape(Circle())
    }
    .buttonStyle(WatchPalmPressStyle())
    .disabled(!enabled)
  }
}

#Preview {
  HStack(spacing: 6) {
    WatchPalmIconView(systemImage: "checkmark") {}
    WatchPalmIconView(glyph: "♠") {}
    WatchPalmIconView(systemImage: "forward.fill", enabled: false) {}
  }
  .padding()
  .background(Color.felt)
}

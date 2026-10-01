//
//  WatchPalmButtonView.swift
//  Big Two — the phone's push button on a watch: a white pill with a black border.
//  watchOS's own button style is a tall tinted capsule and would not read as this app.
//

import SwiftUI

struct WatchPalmButtonView: View {
  let title: String
  var enabled = true
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.palm(13))
        // Palm greys the text and keeps the white pill; a faded-out button is not this app.
        .foregroundColor(enabled ? .ink : .inkDim)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        // ⚠️ The toolbar proposes no width, so the pill has to carry its own: without the
        // padding `maxWidth: .infinity` falls back to the width of the word and "Lead"
        // comes out as a circle.
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 26)
        .background(Capsule().fill(Color.cardFace))
        .overlay(Capsule().strokeBorder(enabled ? Color.ink : Color.inkDim, lineWidth: 1))
        .contentShape(Capsule())
    }
    .buttonStyle(WatchPalmPressStyle())
    .disabled(!enabled)
  }
}

extension View {
  /// Apple's Double Tap (pinch twice) on the watches that have it. The app ships to
  /// watchOS 10, where the modifier does not exist, so it is applied behind a check
  /// rather than by raising the deployment target for one shortcut.
  @ViewBuilder func primaryActionHandGesture(_ enabled: Bool) -> some View {
    if #available(watchOS 11.0, *) {
      handGestureShortcut(.primaryAction, isEnabled: enabled)
    } else {
      self
    }
  }
}

/// SwiftUI's own styles fade a disabled button — a white pill over the felt comes back
/// as translucent green. Palm greys the text and keeps the pill, so the style must not
/// read `isEnabled` at all; `enabled` above colours the text instead.
struct WatchPalmPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.opacity(configuration.isPressed ? 0.6 : 1)
  }
}

#Preview {
  HStack(spacing: 4) {
    WatchPalmButtonView(title: "Play") {}
    WatchPalmButtonView(title: "Pass", enabled: false) {}
  }
  .padding()
  .background(Color.felt)
}

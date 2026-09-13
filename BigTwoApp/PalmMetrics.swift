//
//  PalmMetrics.swift
//  Big Two — the game is laid out on the Palm's 320×320 grid; one Palm unit is
//  `side / 320` points, so the whole screen scales as a square.
//

import SwiftUI

private struct PalmUnitKey: EnvironmentKey {
  static let defaultValue: CGFloat = 1.25
}

extension EnvironmentValues {
  /// Points per Palm pixel (320 across the square).
  var palmUnit: CGFloat {
    get { self[PalmUnitKey.self] }
    set { self[PalmUnitKey.self] = newValue }
  }
}

enum PalmMetrics {
  /// The Palm look is small; the finger still gets this much.
  static let minTouch: CGFloat = 44
}

/// The Palm OS form title: a tab with only its top-right corner rounded.
struct TitleTabShape: Shape {
  var radius: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
    path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                      control: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

/// Palm buttons never fade when disabled (they grey their text), and darken while held.
/// SwiftUI's plain style would wash the whole pill out.
struct PalmPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.opacity(configuration.isPressed ? 0.55 : 1)
  }
}

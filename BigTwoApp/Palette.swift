//
//  Palette.swift
//  Big Two — every color and the one font. Views never write a color literal.
//

import SwiftUI

extension Color {
  /// `#00cc00`, the lighter table green of Palm v2.0.a.
  static let felt = Color(red: 0.00, green: 0.80, blue: 0.00)
  /// ⚠️ `Resources/Assets.xcassets/AccentColor` holds the same components — keep them in sync.
  static let feltDeep = Color(red: 0.00, green: 0.55, blue: 0.00)
  static let feltText = Color.white
  static let feltTextDim = Color.white.opacity(0.8)
  static let chrome = Color(red: 0.80, green: 0.85, blue: 0.80)
  static let ink = Color.black
  static let inkDim = Color(white: 0.4)
  static let cardFace = Color(white: 0.99)
  /// `#cc0000` — red suits colour the rank digit too, as on the Palm.
  static let suitRed = Color(red: 0.80, green: 0.00, blue: 0.00)
}

extension Font {
  static func palm(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
    .system(size: size, weight: weight, design: .default)
  }
}

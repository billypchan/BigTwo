//
//  Palette.swift
//  Big Two — every color and the one font. Views never write a color literal.
//

import SwiftUI

extension Color {
  /// `#00cc00`, the table green of Palm v2.0.a — flat, as on the Palm screen.
  static let felt = Color(red: 0.00, green: 0.80, blue: 0.00)
  /// ⚠️ `Resources/Assets.xcassets/AccentColor` holds the same components — keep them in sync.
  static let feltDeep = Color(red: 0.00, green: 0.55, blue: 0.00)
  /// Palm OS 5 form chrome: the title tab, the rule under it, dialog frames and selections.
  static let titleNavy = Color(red: 0.00, green: 0.20, blue: 0.60)
  /// The case around the square screen.
  static let bezel = Color(white: 0.13)
  static let chrome = Color(red: 0.80, green: 0.85, blue: 0.80)
  static let ink = Color.black
  static let inkDim = Color(white: 0.45)
  static let cardFace = Color(white: 0.99)
  /// `#cc0000` — red suits colour the rank digit too, as on the Palm.
  static let suitRed = Color(red: 0.80, green: 0.00, blue: 0.00)
  /// Red on a selected (inverted) card.
  static let suitRedOnInk = Color(red: 1.00, green: 0.45, blue: 0.45)
  /// A card the tracker has seen played.
  static let playedCard = Color.white
}

extension Font {
  static func palm(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
    .system(size: size, weight: weight, design: .default)
  }
}

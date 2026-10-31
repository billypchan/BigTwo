//
//  AdUnits.swift
//  Big Two — the AdMob identifiers.
//
//  Debug keeps Google's public test unit, so a developer tap never hits the real
//  banner. The app id lives in `project.yml` — the Info.plist is generated from it.
//

import Foundation

enum AdUnits {
  /// Google's test banner unit. Always used in a Debug build, so development traffic
  /// never reaches the real unit.
  static let testBanner = "ca-app-pub-3940256099942544/2934735716"

  /// The banner a Release build requests. Big Two 鋤大弟, created 2026-10-18.
  static let releaseBanner = "ca-app-pub-4810336293797836/6353715341"

  static var banner: String {
    #if DEBUG
      testBanner
    #else
      releaseBanner
    #endif
  }
}

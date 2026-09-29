//
//  AdUnits.swift
//  Big Two — the AdMob identifiers.
//
//  ⚠️ These are Google's public test ids. They serve a fixed "Test Ad" banner and are
//  safe to run on a device; real ids must never be tapped by a developer or the account
//  is suspended. Swapping them is two edits: `banner` here and `GADApplicationIdentifier`
//  in `project.yml` (the Info.plist is generated from it — editing the plist is lost).
//

import Foundation

enum AdUnits {
  /// Google's test banner unit. Always used in a Debug build, so development traffic
  /// never reaches the real unit.
  static let testBanner = "ca-app-pub-3940256099942544/2934735716"

  /// The unit a Release build asks for. Still the test id until the real one exists.
  static let releaseBanner = "ca-app-pub-3940256099942544/2934735716"

  static var banner: String {
    #if DEBUG
      testBanner
    #else
      releaseBanner
    #endif
  }
}

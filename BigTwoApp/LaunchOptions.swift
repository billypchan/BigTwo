//
//  LaunchOptions.swift
//  Big Two — launch arguments the UI tests steer the app with.
//

import BigTwoKit
import Foundation

enum LaunchOptions {
  /// Fast bots and throwaway preferences, so one test can't leak into the next.
  static let uiTestMode = ProcessInfo.processInfo.arguments.contains("UITestMode")

  /// `-seed 2` deals the same hands every launch.
  static var seed: UInt64? {
    UserDefaults.standard.string(forKey: "seed").flatMap(UInt64.init)
  }

  /// `-autoplay YES` gives your seat to the bot too, so a deal plays itself out.
  static var autoplay: Bool { UserDefaults.standard.bool(forKey: "autoplay") }

  /// `-keepPreferences YES` keeps the UI-test preference suite across a relaunch.
  static var keepPreferences: Bool { UserDefaults.standard.bool(forKey: "keepPreferences") }

  private static let uiTestSuite = "UITestPreferences"

  static func preferencesStore() -> PreferencesStore {
    guard uiTestMode, let defaults = UserDefaults(suiteName: uiTestSuite) else {
      return PreferencesStore()
    }
    if !keepPreferences { defaults.removePersistentDomain(forName: uiTestSuite) }
    return PreferencesStore(defaults: defaults)
  }
}

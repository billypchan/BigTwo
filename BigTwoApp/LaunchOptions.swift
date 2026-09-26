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

  /// `-dealsPerGame 1` ends the game after one deal (Final Score screenshot).
  static var dealsPerGame: Int? {
    UserDefaults.standard.object(forKey: "dealsPerGame") as? Int
      ?? UserDefaults.standard.string(forKey: "dealsPerGame").flatMap(Int.init)
  }

  /// `-keepPreferences YES` keeps the UI-test preference suite across a relaunch.
  static var keepPreferences: Bool { UserDefaults.standard.bool(forKey: "keepPreferences") }

  private static let uiTestSuite = "UITestPreferences"

  /// UI tests wipe this unless `-keepPreferences YES`, so one run can't fill Game History.
  static func recordStore() -> GameRecordStore {
    let url: URL
    if uiTestMode {
      url = FileManager.default.temporaryDirectory.appendingPathComponent("BigTwoUITestRecord.json")
      if !keepPreferences { try? FileManager.default.removeItem(at: url) }
    } else {
      url = GameRecordStore.defaultURL
    }
    return GameRecordStore(url: url)
  }

  static func preferencesStore() -> PreferencesStore {
    guard uiTestMode, let defaults = UserDefaults(suiteName: uiTestSuite) else {
      return PreferencesStore()
    }
    if !keepPreferences { defaults.removePersistentDomain(forName: uiTestSuite) }
    return PreferencesStore(defaults: defaults)
  }
}

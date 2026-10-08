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

  /// Ads are off in every UI test: a banner moves the square, and a tap near the
  /// bottom edge would land on someone else's ad. `-showAds YES` puts it back.
  static var showAds: Bool {
    uiTestMode ? UserDefaults.standard.bool(forKey: "showAds") : true
  }

  /// `-keepPreferences YES` keeps the UI-test preference suite across a relaunch.
  static var keepPreferences: Bool { UserDefaults.standard.bool(forKey: "keepPreferences") }

  /// `-watchNotice YES` shows the one-time Apple Watch note even under `UITestMode`,
  /// which otherwise suppresses it. ⚠️ Without that suppression the note would cover the
  /// table on the first launch of *every* test — the preference suite is wiped each time,
  /// so "once" would mean "every run".
  static var forceWatchNotice: Bool { UserDefaults.standard.bool(forKey: "watchNotice") }

  /// `-askName YES` opens the first-launch name dialog even under `UITestMode`.
  static var forceNamePrompt: Bool { UserDefaults.standard.bool(forKey: "askName") }

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


/// Whether the one-time Apple Watch note has been shown. ⚠️ Deliberately *not* part of
/// `Preferences`: that is synced to the watch, and whether the phone has shown a note is
/// the phone's business. Shipped user data — renaming the key shows the note again.
enum WatchNotice {
  private static let key = "watchNoticeShown.v1"

  static var shouldShow: Bool {
    if LaunchOptions.forceWatchNotice { return true }
    if LaunchOptions.uiTestMode { return false }
    return !UserDefaults.standard.bool(forKey: key)
  }

  static func markShown() { UserDefaults.standard.set(true, forKey: key) }
}

/// Whether the first launch has asked for a name. ⚠️ Not part of `Preferences`: that is
/// synced to the watch, and whether the phone has asked is the phone's business.
/// Renaming the key asks again. `UITestMode` suppresses it for the same reason as
/// `WatchNotice` — a wiped suite would put the dialog over every test.
enum NamePrompt {
  private static let key = "namePromptShown.v1"

  static var shouldShow: Bool {
    if LaunchOptions.forceNamePrompt { return true }
    if LaunchOptions.uiTestMode { return false }
    return !UserDefaults.standard.bool(forKey: key)
  }

  static func markShown() { UserDefaults.standard.set(true, forKey: key) }
}

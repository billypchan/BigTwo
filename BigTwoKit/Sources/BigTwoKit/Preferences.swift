//
//  Preferences.swift
//  BigTwoKit — the Palm "Preferences" form, persisted.
//

import Foundation

public struct Preferences: Codable, Equatable, Sendable {
  /// Takes effect from the next deal — a rule change mid-deal would re-rank the table.
  public var hongKong = false
  /// 1, 2 and 3-card turns.
  public var autopass = true
  /// "Enable autopass for 5-card turn for a faster pace".
  public var autopassFiveCard = false
  public var showCardsLeft = true

  public init(hongKong: Bool = false, autopass: Bool = true,
              autopassFiveCard: Bool = false, showCardsLeft: Bool = true) {
    self.hongKong = hongKong
    self.autopass = autopass
    self.autopassFiveCard = autopassFiveCard
    self.showCardsLeft = showCardsLeft
  }

  // ⚠️ Shipped user data: every key is optional so adding a preference never resets the rest.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let d = Preferences()
    hongKong = try c.decodeIfPresent(Bool.self, forKey: .hongKong) ?? d.hongKong
    autopass = try c.decodeIfPresent(Bool.self, forKey: .autopass) ?? d.autopass
    autopassFiveCard = try c.decodeIfPresent(Bool.self, forKey: .autopassFiveCard) ?? d.autopassFiveCard
    showCardsLeft = try c.decodeIfPresent(Bool.self, forKey: .showCardsLeft) ?? d.showCardsLeft
  }
}

public struct PreferencesStore {
  /// ⚠️ Shipped user data — renaming this key resets everyone's preferences.
  public static let key = "preferences.v1"

  private let defaults: UserDefaults

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  public func load() -> Preferences {
    guard let data = defaults.data(forKey: Self.key),
          let prefs = try? JSONDecoder().decode(Preferences.self, from: data) else {
      return Preferences()
    }
    return prefs
  }

  public func save(_ prefs: Preferences) {
    guard let data = try? JSONEncoder().encode(prefs) else { return }
    defaults.set(data, forKey: Self.key)
  }
}

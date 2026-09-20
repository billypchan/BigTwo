//
//  Preferences.swift
//  BigTwoKit — the Palm "Preferences" form, persisted.
//

import Foundation

/// "Game speed: Slow | Medium | Fast" — the pause before each bot move.
public enum GameSpeed: String, Codable, CaseIterable, Sendable {
  case slow, medium, fast

  public var botDelay: TimeInterval {
    switch self {
    case .slow: return 1.2
    case .medium: return 0.7
    case .fast: return 0.35
    }
  }
}

public struct Preferences: Codable, Equatable, Sendable {
  /// Takes effect from the next deal — a rule change mid-deal would re-rank the table.
  public var hongKong = false
  /// 1, 2 and 3-card turns.
  public var autopass = true
  /// "Enable autopass for 5-card turn for a faster pace".
  public var autopassFiveCard = false
  public var showCardsLeft = true
  public var gameSpeed = GameSpeed.medium
  /// "Sort cards by: Rank | Suit" — also flipped by the sort icon on the table.
  public var sortBySuit = false
  /// Strong bots use every hand they can see to stop you and to go out.
  public var strongBots = true
  /// Custom names for seats 0…3. Empty string / missing slot = use the localized default.
  /// Not written until the player edits a name, so a language change still updates defaults.
  public var playerNames: [String] = []

  public init(hongKong: Bool = false, autopass: Bool = true,
              autopassFiveCard: Bool = false, showCardsLeft: Bool = true,
              gameSpeed: GameSpeed = .medium, sortBySuit: Bool = false,
              strongBots: Bool = true, playerNames: [String] = []) {
    self.hongKong = hongKong
    self.autopass = autopass
    self.autopassFiveCard = autopassFiveCard
    self.showCardsLeft = showCardsLeft
    self.gameSpeed = gameSpeed
    self.sortBySuit = sortBySuit
    self.strongBots = strongBots
    self.playerNames = playerNames
  }

  // ⚠️ Shipped user data: every key is optional, and a value this build can't read falls
  // back to its default, so adding or extending a preference never resets the rest.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let d = Preferences()
    hongKong = (try? c.decodeIfPresent(Bool.self, forKey: .hongKong)) ?? d.hongKong
    autopass = (try? c.decodeIfPresent(Bool.self, forKey: .autopass)) ?? d.autopass
    autopassFiveCard = (try? c.decodeIfPresent(Bool.self, forKey: .autopassFiveCard)) ?? d.autopassFiveCard
    showCardsLeft = (try? c.decodeIfPresent(Bool.self, forKey: .showCardsLeft)) ?? d.showCardsLeft
    gameSpeed = (try? c.decodeIfPresent(GameSpeed.self, forKey: .gameSpeed)) ?? d.gameSpeed
    sortBySuit = (try? c.decodeIfPresent(Bool.self, forKey: .sortBySuit)) ?? d.sortBySuit
    strongBots = (try? c.decodeIfPresent(Bool.self, forKey: .strongBots)) ?? d.strongBots
    playerNames = (try? c.decodeIfPresent([String].self, forKey: .playerNames)) ?? d.playerNames
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

//
//  PlayerNames.swift
//  Big Two — default seat names are local given names for that language,
//  not translations of Adam / Bill / Carl / Dean.
//  zh-Hant uses the latest published HK Chinese newborn ranking (NameChef):
//  boys 梓軒 / 宇軒, girls 凱晴 / 芷晴. Hong Kong does not publish an
//  official 2026 birth-name table.
//

import Foundation

enum PlayerNames {
  static let keys = ["Adam", "Bill", "Carl", "Dean"]

  /// Localized defaults. Falls back to the English key.
  static var defaults: [String] {
    keys.map { NSLocalizedString($0, tableName: nil, bundle: .main, value: $0, comment: "default player name") }
  }
}

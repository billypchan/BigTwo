//
//  PlayerNames.swift
//  Big Two — default seat names follow the phone language until the player edits one.
//

import Foundation

enum PlayerNames {
  static let keys = ["Adam", "Bill", "Carl", "Dean"]

  /// Localized Adam / Bill / Carl / Dean. Falls back to the English key.
  static var defaults: [String] {
    keys.map { NSLocalizedString($0, tableName: nil, bundle: .main, value: $0, comment: "default player name") }
  }
}

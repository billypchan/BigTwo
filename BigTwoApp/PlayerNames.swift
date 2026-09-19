//
//  PlayerNames.swift
//  Big Two — default seat names are local given names for that language,
//  not translations of Adam / Bill / Carl / Dean.
//  zh-Hant: HK Chinese ranking boys 梓軒 / 子謙 (skip 宇軒 so two seats
//  don't share 軒), girls 凱晴 / 芷晴.
//

import Foundation

enum PlayerNames {
  static let keys = ["Adam", "Bill", "Carl", "Dean"]

  /// Localized defaults. Falls back to the English key.
  static var defaults: [String] {
    keys.map { NSLocalizedString($0, tableName: nil, bundle: .main, value: $0, comment: "default player name") }
  }
}

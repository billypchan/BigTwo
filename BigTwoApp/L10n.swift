//
//  L10n.swift
//  Big Two — string lookup. Keys are the English UI copy.
//  NSLocalizedString + String(format:locale:) so format args follow the phone language.
//

import Foundation

enum L10n {
  static func string(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    guard !args.isEmpty else { return format }
    return String(format: format, locale: .current, arguments: args)
  }

  /// Kit submit() still returns English; map the one interpolated case.
  static func playError(_ raw: String) -> String {
    let prefix = "That does not beat "
    if raw.hasPrefix(prefix) {
      return string("That does not beat %@", String(raw.dropFirst(prefix.count)))
    }
    return string(raw)
  }

  static func spokenCard(rankName: String, suitName: String) -> String {
    string("%@ of %@", string(rankName), string(suitName))
  }
}

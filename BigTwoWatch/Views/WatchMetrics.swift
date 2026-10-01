//
//  WatchMetrics.swift
//  Big Two — one step of the watch table's size.
//
//  ⚠️ Nothing on the watch is measured: no `GeometryReader`, no `NavigationStack`, no
//  inset arithmetic. `ViewThatFits` is what replaces all of it — the table is built once
//  per step, largest first, and SwiftUI lays out the first one whose ideal height fits the
//  screen it is on. A 46mm gets the big cards; a 40mm (162×197pt, the smallest watch this
//  ships to) falls through to the last step and still shows all thirteen.
//
//  Add a step rather than stretch one: the steps are cheap, and a single set of numbers
//  that has to suit both sizes suits neither.
//

import SwiftUI

struct WatchMetrics {
  /// One player's row, and the cards drawn inside it.
  let row: CGFloat
  let playedCard: CGFloat
  let nameFont: CGFloat
  /// The prompt line and a card in your hand.
  let promptFont: CGFloat
  let handFont: CGFloat

  var namePlate: CGSize { CGSize(width: row * 1.7, height: row - 4) }

  static let huge = WatchMetrics(row: 31, playedCard: 27, nameFont: 15,
                                 promptFont: 15, handFont: 20)
  static let large = WatchMetrics(row: 27, playedCard: 23, nameFont: 13,
                                  promptFont: 13, handFont: 17)
  static let medium = WatchMetrics(row: 23, playedCard: 19, nameFont: 12,
                                   promptFont: 12, handFont: 15)
  static let small = WatchMetrics(row: 20, playedCard: 17, nameFont: 11,
                                  promptFont: 11, handFont: 13)
}

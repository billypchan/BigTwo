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

  /// ⚠️ `playedCard` is `row - 2`, not `row - 4`: the gap above a player's row is the
  /// navigation bar's own band and cannot be taken back, so the only way to grow a played
  /// card is to let it fill the row it is already in.
  static let giant = WatchMetrics(row: 35, playedCard: 33, nameFont: 16,
                                  promptFont: 16, handFont: 22)
  static let huge = WatchMetrics(row: 31, playedCard: 29, nameFont: 15,
                                 promptFont: 15, handFont: 20)
  static let large = WatchMetrics(row: 27, playedCard: 25, nameFont: 13,
                                  promptFont: 13, handFont: 17)
  static let medium = WatchMetrics(row: 23, playedCard: 21, nameFont: 12,
                                   promptFont: 12, handFont: 15)
  static let small = WatchMetrics(row: 20, playedCard: 18, nameFont: 11,
                                  promptFont: 11, handFont: 13)
  /// ⚠️ The floor, and a 40mm needs it: the round buttons are 40pt and the bottom bar
  /// takes its own band on top of that, which leaves a 162×197pt screen very little. With
  /// nowhere smaller to fall, `ViewThatFits` keeps the step that does not fit and the
  /// first player's row is pushed up behind the title.
  static let tiny = WatchMetrics(row: 17, playedCard: 15, nameFont: 10,
                                 promptFont: 10, handFont: 11)
}

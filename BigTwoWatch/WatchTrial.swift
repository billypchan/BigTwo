//
//  WatchTrial.swift
//  Big Two — one free game on the watch, then the purchase.
//
//  A game is `dealsPerGame` finished deals (10, unless a test overrides it). The count
//  lives in the watch's own UserDefaults, not in `Preferences`: that struct is synced
//  to the phone, and the phone has no trial. Renaming either key grants the free game
//  again.
//

import Foundation

@MainActor
final class WatchTrial: ObservableObject {
  /// Finished deals in the free game. The watch passes the same number the table plays.
  let allowance: Int

  @Published private(set) var entered: Bool
  @Published private(set) var dealsFinished: Int
  /// The last deal's score sheet has been dismissed. Until then the sheet stays up,
  /// so Final Score is still on screen when the free game ends.
  @Published private(set) var blocked: Bool

  private let defaults: UserDefaults

  // Shipped data. A new key is a new free game.
  private static let enteredKey = "watchTrial.entered"
  private static let dealsKey = "watchTrial.dealsFinished"

  /// The paywall offers the button. Hidden once they have started, and once it is spent.
  var offerTry: Bool { !entered && dealsFinished < allowance }

  /// The table, including the score sheet of the deal that spends the allowance.
  /// `blocked` is what sends them back to the paywall; flipping this on the deal
  /// itself would pull the sheet down before they can read it.
  var canPlay: Bool { entered && !blocked }

  var isSpent: Bool { dealsFinished >= allowance }

  init(allowance: Int = 10, defaults: UserDefaults = .standard, resetsForUITest: Bool = true) {
    self.allowance = max(1, allowance)
    self.defaults = defaults
    if resetsForUITest,
       ProcessInfo.processInfo.arguments.contains("UITestMode"),
       !defaults.bool(forKey: "keepPreferences") {
      // Same trap as the sort order: a test that spends the trial would otherwise
      // leave the next launch on the paywall with no Try.
      defaults.removeObject(forKey: Self.enteredKey)
      defaults.removeObject(forKey: Self.dealsKey)
    }
    var entered = defaults.bool(forKey: Self.enteredKey)
    var deals = defaults.integer(forKey: Self.dealsKey)
    var blocked = false
    #if DEBUG
      // `-trialUsed YES` opens the paywall the way it looks after the free game.
      if defaults.bool(forKey: "trialUsed") {
        entered = true
        deals = self.allowance
        blocked = true
      }
    #endif
    if deals >= self.allowance {
      entered = true
      blocked = true
    }
    self.entered = entered
    self.dealsFinished = deals
    self.blocked = blocked
  }

  func begin() {
    guard !entered else { return }
    entered = true
    save()
  }

  /// One finished deal. The deal that reaches the allowance does not block yet.
  func noteDealFinished() {
    guard entered, dealsFinished < allowance else { return }
    dealsFinished += 1
    save()
  }

  func requirePurchase() {
    guard isSpent else { return }
    blocked = true
  }

  private func save() {
    defaults.set(entered, forKey: Self.enteredKey)
    defaults.set(dealsFinished, forKey: Self.dealsKey)
  }
}

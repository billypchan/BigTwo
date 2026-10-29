//
//  ReviewPrompt.swift
//  Big Two — ask for an App Store rating after a deal is finished.
//

import StoreKit
import UIKit

/// Asked when the score sheet is dismissed, then not again for four months.
/// Launch does not ask. `UITestMode` does not ask: the score sheet is what the
/// tests and the store screenshots are looking at.
enum ReviewPrompt {
  private static let askedKey = "reviewPromptAfterDeal.v1"

  static func shouldAsk(lastAsked: Date?, now: Date = .now) -> Bool {
    guard let lastAsked else { return true }
    let cutoff = Calendar.current.date(byAdding: .month, value: -4, to: now)!
    return lastAsked < cutoff
  }

  @MainActor
  static func askAfterDealIfNeeded() {
    if LaunchOptions.uiTestMode { return }
    let defaults = UserDefaults.standard
    let last = defaults.object(forKey: askedKey) as? Date
    guard shouldAsk(lastAsked: last) else { return }
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    guard let scene else { return }
    defaults.set(Date.now, forKey: askedKey)
    SKStoreReviewController.requestReview(in: scene)
  }
}

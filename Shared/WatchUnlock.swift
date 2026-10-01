//
//  WatchUnlock.swift
//  Big Two — the one in-app purchase: the Apple Watch game.
//
//  The watch app ships inside the phone app, so the purchase cannot gate the install —
//  it gates play. StoreKit 2 entitlements follow the Apple ID, so the watch asks the
//  App Store itself rather than syncing a flag over from the phone.
//

import Foundation
import StoreKit

@MainActor
final class WatchUnlock: ObservableObject {
  /// Must match the product id in App Store Connect and in `Configurations/BigTwo.storekit`.
  static let productID = "com.billchan.BigTwo.watch"

  enum State: Equatable {
    case loading
    case locked(price: String?)
    case unlocked
    /// The store could not be reached. The watch game stays locked, but the message
    /// has to say why — a network blip must not read as "you did not buy this".
    case unavailable
  }

  @Published private(set) var state: State = .loading
  @Published private(set) var isWorking = false

  private var product: Product?
  private var updates: Task<Void, Never>?

  init() {
    // A purchase made on another device, or a refund, arrives here rather than at launch.
    updates = Task { [weak self] in
      for await update in Transaction.updates {
        guard case .verified(let transaction) = update else { continue }
        await transaction.finish()
        await self?.refresh()
      }
    }
  }

  deinit { updates?.cancel() }

  func refresh() async {
    #if DEBUG
      // `-unlocked YES` skips the paywall so the game can be worked on and photographed:
      // watchOS has no XCUITest, so there is no other way to drive past it. A Release
      // build does not compile this.
      if UserDefaults.standard.bool(forKey: "unlocked") {
        state = .unlocked
        return
      }
    #endif
    if await isEntitled() {
      state = .unlocked
      return
    }
    do {
      product = try await Product.products(for: [Self.productID]).first
      state = .locked(price: product?.displayPrice)
    } catch {
      state = .unavailable
    }
  }

  /// `.unlocked` on success; a cancelled sheet leaves the state alone.
  func buy() async {
    guard let product else { return }
    isWorking = true
    defer { isWorking = false }
    do {
      switch try await product.purchase() {
      case .success(let verification):
        if case .verified(let transaction) = verification {
          await transaction.finish()
          state = .unlocked
        }
      case .userCancelled, .pending:
        break
      @unknown default:
        break
      }
    } catch {
      // Nothing was bought; the paywall stays up and says so through `state`.
    }
  }

  func restore() async {
    isWorking = true
    defer { isWorking = false }
    try? await AppStore.sync()
    await refresh()
  }

  private func isEntitled() async -> Bool {
    for await entitlement in Transaction.currentEntitlements {
      if case .verified(let transaction) = entitlement,
         transaction.productID == Self.productID,
         transaction.revocationDate == nil {
        return true
      }
    }
    return false
  }
}

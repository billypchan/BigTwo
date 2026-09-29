//
//  AdConsent.swift
//  Big Two — the UMP consent gate in front of the banner.
//
//  Google requires a consent form for EEA/UK traffic before a personalised ad is
//  requested. Outside those regions UMP reports "not required" and this costs one
//  network round trip at launch. The banner is only built once `isReady` is true,
//  so an ad is never requested ahead of consent.
//

import GoogleMobileAds
import SwiftUI
import UserMessagingPlatform

@MainActor
final class AdConsent: ObservableObject {
  /// True once the SDK has started and consent has been obtained or found unnecessary.
  @Published private(set) var isReady = false

  private var didStart = false

  func start() {
    // A SwiftUI view can appear more than once; the SDK must be started once.
    guard !didStart else { return }
    didStart = true

    let parameters = RequestParameters()
    #if DEBUG
      // Without this a debug build in the EEA would show the real form; the test
      // geography makes it appear everywhere so the flow can actually be seen.
      let debugSettings = DebugSettings()
      debugSettings.geography = .EEA
      parameters.debugSettings = debugSettings
    #endif

    // UMP calls back off the main actor; every hop below is what keeps that legal.
    ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
      if let error {
        // A consent failure must not take the game with it — serve nothing and play on.
        print("[BigTwo] consent update failed: \(error.localizedDescription)")
        Task { @MainActor in self?.startAds() }
        return
      }
      Task { @MainActor in
        ConsentForm.loadAndPresentIfRequired(from: nil) { formError in
          if let formError {
            print("[BigTwo] consent form failed: \(formError.localizedDescription)")
          }
          Task { @MainActor in self?.startAds() }
        }
      }
    }
  }

  private func startAds() {
    MobileAds.shared.start { _ in
      Task { @MainActor in self.isReady = true }
    }
  }
}

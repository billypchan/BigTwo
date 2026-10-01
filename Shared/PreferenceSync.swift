//
//  PreferenceSync.swift
//  Big Two — keeps Preferences (rule set, speed, sort order, bots and the player names)
//  the same on the phone and the watch.
//
//  WatchConnectivity's *application context* is the right channel: it is a single
//  latest-value slot, delivered in the background, replaced rather than queued. A
//  message queue would replay every intermediate toggle; a file transfer would arrive
//  late. Nothing here is a game in progress — the two devices deal their own cards.
//

import BigTwoKit
import Foundation
import WatchConnectivity

@MainActor
public final class PreferenceSync: NSObject, ObservableObject {
  /// What arrived from the other device, for the app to apply.
  @Published public private(set) var incoming: Preferences?

  // nonisolated: the delegate reads these off the main actor, on WatchConnectivity's
  // own queue, to pull the Sendable values out of the context dictionary.
  nonisolated private static let payloadKey = "preferences"
  nonisolated private static let stampKey = "changedAt"

  /// When the local copy last changed. An edit made while the other device was away
  /// arrives later than it was made, so the newer *edit* wins, not the later delivery.
  ///
  /// ⚠️ **Persisted.** This used to live only in memory, and that is what "the setting is
  /// not saved" was: change something on the watch, quit, come back, and it had reverted.
  /// On activation WatchConnectivity hands over whatever the other device last pushed —
  /// an *older* copy — and against a `lastLocalChange` that had just been reset to
  /// `.distantPast` it won, and was then written to the store over the change.
  /// `double(forKey:)` is 0 when the key is absent, which is 1970 and loses to anything,
  /// so the first launch after an update can still be overwritten once.
  private static let stampKeyDefaults = "preferenceSync.lastLocalChange"
  private let defaults: UserDefaults
  private var lastLocalChange: Date {
    get { Date(timeIntervalSince1970: defaults.double(forKey: Self.stampKeyDefaults)) }
    set { defaults.set(newValue.timeIntervalSince1970, forKey: Self.stampKeyDefaults) }
  }
  private var session: WCSession?

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    super.init()
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    self.session = session
    session.delegate = self
    session.activate()
  }

  /// Push the local preferences to the other device. Cheap to call on every change:
  /// the context is a slot, so repeated writes collapse into the latest one.
  public func send(_ preferences: Preferences) {
    let now = Date()
    lastLocalChange = now
    guard let session, session.activationState == .activated,
          let data = try? JSONEncoder().encode(preferences)
    else { return }
    // ⚠️ `updateApplicationContext` throws when called with an unchanged dictionary, and
    // that is not worth surfacing — the other side already has this value.
    try? session.updateApplicationContext([
      Self.payloadKey: data,
      Self.stampKey: now.timeIntervalSince1970,
    ])
  }

  private func receive(_ data: Data, stamp: TimeInterval) {
    guard let preferences = try? JSONDecoder().decode(Preferences.self, from: data) else { return }
    // Last edit wins. Without this, opening the watch after changing a name on the phone
    // could push the watch's older copy straight back over it.
    guard Date(timeIntervalSince1970: stamp) >= lastLocalChange else { return }
    lastLocalChange = Date(timeIntervalSince1970: stamp)
    incoming = preferences
  }

  /// ⚠️ `[String: Any]` is not `Sendable`, so the payload is pulled apart here, on the
  /// delegate's own thread, and only `Data` and a `TimeInterval` cross to the main actor.
  nonisolated private func handOver(_ context: [String: Any]) {
    guard let data = context[Self.payloadKey] as? Data else { return }
    let stamp = context[Self.stampKey] as? TimeInterval ?? 0
    Task { @MainActor in self.receive(data, stamp: stamp) }
  }

  /// The app calls this once it has applied `incoming`, so the same value is not re-applied.
  public func clearIncoming() { incoming = nil }
}

extension PreferenceSync: WCSessionDelegate {
  nonisolated public func session(_ session: WCSession,
                                  activationDidCompleteWith state: WCSessionActivationState,
                                  error: Error?) {
    // Whatever the other device last pushed is already waiting in the context.
    handOver(session.receivedApplicationContext)
  }

  nonisolated public func session(_ session: WCSession,
                                  didReceiveApplicationContext context: [String: Any]) {
    handOver(context)
  }

  #if os(iOS)
    // Required on iOS so the session can be handed to a second paired watch.
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
      WCSession.default.activate()
    }
  #endif
}

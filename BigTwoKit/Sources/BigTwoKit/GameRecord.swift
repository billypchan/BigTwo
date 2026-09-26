//
//  GameRecord.swift
//  BigTwoKit — the game's transcript: open hands, then every step.
//  Kept on device. A game nobody has played is not stored.
//

import Foundation

public struct GameRecord: Codable, Equatable, Sendable {
  public struct Deal: Codable, Equatable, Sendable {
    public var number: Int
    public var names: [String]
    public var hands: [[Card]]
    public var steps: [String]
    public var cardsLeft: [Int]?
    public var points: [Int]?

    public init(number: Int, names: [String], hands: [[Card]], steps: [String] = [],
                cardsLeft: [Int]? = nil, points: [Int]? = nil) {
      self.number = number
      self.names = names
      self.hands = hands
      self.steps = steps
      self.cardsLeft = cardsLeft
      self.points = points
    }
  }

  public var deals: [Deal]

  public init(deals: [Deal] = []) {
    self.deals = deals
  }

  public var hasSteps: Bool { deals.contains { !$0.steps.isEmpty } }
}

public struct GameRecordLibrary: Codable, Equatable, Sendable {
  public static let maxSaved = 20

  public var current: GameRecord
  public var saved: [GameRecord]

  public init(current: GameRecord = GameRecord(), saved: [GameRecord] = []) {
    self.current = current
    self.saved = saved
  }
}

public struct GameRecordStore: Sendable {
  public let url: URL

  public init(url: URL) {
    self.url = url
  }

  public static var defaultURL: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    return base.appendingPathComponent("BigTwo/game-record.json")
  }

  public func load() -> GameRecordLibrary {
    guard let data = try? Data(contentsOf: url),
          let library = try? JSONDecoder().decode(GameRecordLibrary.self, from: data) else {
      return GameRecordLibrary()
    }
    return library
  }

  public func save(_ library: GameRecordLibrary) {
    guard let data = try? JSONEncoder().encode(library) else { return }
    let directory = url.deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try? data.write(to: url, options: .atomic)
  }
}

//
//  Game.swift
//  BigTwoKit — table state, turn order and scoring.
//
//  Scoring, as on the Palm: a card left in hand costs its rank (3 = 1 ... 2 = 13),
//  doubled if you are holding 10 cards or more. The winner collects the lot.
//  After `dealsPerGame` deals the game is over and the score goes to the high scores.
//

import Foundation

public struct Seat: Identifiable, Sendable {
  public let id: Int
  public var name: String
  public var isHuman: Bool
  public var hand: [Card] = []
  public var score: Int = 0

  public init(id: Int, name: String, isHuman: Bool) {
    self.id = id
    self.name = name
    self.isHuman = isHuman
  }
}

/// What a seat did last in the current trick — the Palm's row shows the cards or "PASS".
public enum SeatAction: Equatable, Sendable {
  case played(Play)
  case passed
}

public struct DealResult: Identifiable, Sendable {
  public let deal: Int
  public let winner: Int
  public let cardsLeft: [Int]
  public let points: [Int]  // what each seat gained (+) or paid (-) this deal

  public init(deal: Int, winner: Int, cardsLeft: [Int], points: [Int]) {
    self.deal = deal
    self.winner = winner
    self.cardsLeft = cardsLeft
    self.points = points
  }

  public var id: Int { deal }
}

@MainActor
public final class BigTwoGame: ObservableObject {

  @Published public private(set) var seats: [Seat]
  @Published public var preferences: Preferences
  /// The rules the deal in progress is played under; picked up from `preferences` at each deal.
  @Published public private(set) var rules: RuleSet
  @Published public private(set) var turn = 0
  @Published public private(set) var table: Play?  // the play to beat; nil means a lead
  @Published public private(set) var tableOwner: Int?
  /// Each seat's last move this deal; nil until it has moved.
  @Published public private(set) var lastActions: [SeatAction?] = [nil, nil, nil, nil]
  @Published public private(set) var deal = 1
  @Published public private(set) var history: [String] = []
  @Published public private(set) var result: DealResult?  // non-nil while the score sheet is up
  @Published public private(set) var gameOver = false

  /// Replaces `preferences.gameSpeed` — UI tests run the bots fast.
  public var botDelayOverride: TimeInterval?

  private var passes = 0
  private var lastWinner: Int?
  private var openingPlay = false  // the 3♦ must be in the first play of a deal
  private var botTask: Task<Void, Never>?
  private var rng: SeededGenerator?
  private var prefersFiveCards = [true, false, true, false]
  private let botsMoveThemselves: Bool

  /// `humanSeats` empty lets the bots play every seat (UI-test autoplay).
  /// `botsMoveThemselves: false` leaves every move to the caller — tests step the bots
  /// with `botChoice(for:)` instead of waiting on timers.
  public init(preferences: Preferences = Preferences(), seed: UInt64? = nil,
              humanSeats: Set<Int> = [1], botsMoveThemselves: Bool = true) {
    self.preferences = preferences
    self.rules = RuleSet(hongKong: preferences.hongKong)
    self.rng = seed.map(SeededGenerator.init(seed:))
    self.botsMoveThemselves = botsMoveThemselves
    self.seats = ["Adam", "Bill", "Carl", "Dean"].enumerated().map {
      Seat(id: $0.offset, name: $0.element, isHuman: humanSeats.contains($0.offset))
    }
    startGame()
  }

  public var humanSeat: Int? { seats.firstIndex { $0.isHuman } }
  public var isHumanTurn: Bool { seats[turn].isHuman }
  public var mustPlayThreeOfDiamonds: Bool { openingPlay }

  // MARK: - Setup

  public func startGame() {
    deal = 1
    lastWinner = nil
    gameOver = false
    for i in seats.indices { seats[i].score = 0 }
    newDeal()
  }

  private func newDeal() {
    rules = RuleSet(hongKong: preferences.hongKong)
    var deck = shuffledDeck()
    for i in seats.indices {
      seats[i].hand = HandSort.byRank.sorted(Array(deck.prefix(13)))
      deck.removeFirst(13)
    }
    prefersFiveCards = seats.map { _ in coinFlip() }  // after the deal, so seeds keep their hands
    table = nil
    tableOwner = nil
    lastActions = [nil, nil, nil, nil]
    passes = 0
    result = nil
    history = ["— Deal \(deal) —"]

    // HK rules: the winner of the last deal leads. Otherwise 3♦ leads and must be played.
    if rules.hongKong, let winner = lastWinner {
      turn = winner
      openingPlay = false
    } else {
      turn = seats.firstIndex { $0.hand.contains(.threeOfDiamonds) } ?? 0
      openingPlay = true
    }
    scheduleBot()
  }

  private func shuffledDeck() -> [Card] {
    guard var generator = rng else { return Card.deck.shuffled() }
    defer { rng = generator }
    return Card.deck.shuffled(using: &generator)
  }

  private func coinFlip() -> Bool {
    guard var generator = rng else { return Bool.random() }
    defer { rng = generator }
    return Bool.random(using: &generator)
  }

  // MARK: - Turns

  public func legalPlays(for seat: Int) -> [Play] {
    PlayFinder.plays(in: seats[seat].hand,
                     beating: table,
                     rules: rules,
                     mustInclude: openingPlay ? .threeOfDiamonds : nil)
  }

  /// Returns nil on success, or why the play was rejected.
  @discardableResult
  public func submit(_ cards: [Card], from seat: Int) -> String? {
    guard result == nil, seat == turn else { return "Not your turn" }
    guard cards.allSatisfy({ seats[seat].hand.contains($0) }) else { return "Not your cards" }
    guard let play = Play(cards, rules: rules) else { return "Not a legal combination" }
    if openingPlay && !cards.contains(.threeOfDiamonds) { return "First play must include 3♦" }
    if let table, !play.beats(table) { return "That does not beat \(table.label)" }

    seats[seat].hand.removeAll { cards.contains($0) }
    table = play
    tableOwner = seat
    lastActions[seat] = .played(play)
    passes = 0
    openingPlay = false
    log("\(seats[seat].name): \(play.label)")

    if seats[seat].hand.isEmpty {
      endDeal(winner: seat)
    } else {
      advance()
    }
    return nil
  }

  public func pass(from seat: Int) {
    guard result == nil, seat == turn, table != nil else { return }
    log("\(seats[seat].name): pass")
    lastActions[seat] = .passed
    passes += 1
    if passes >= 3 {  // everyone else folded — new trick
      turn = tableOwner ?? turn
      table = nil
      tableOwner = nil
      passes = 0
      log("— \(seats[turn].name) leads —")
      scheduleBot()
    } else {
      advance()
    }
  }

  private func advance() {
    turn = (turn + 1) % 4
    if tryAutopass() { return }
    scheduleBot()
  }

  /// Skip a seat that has no legal reply. Size no longer matters: a 5-card on the
  /// table with no answer used to wait for a second preference that shipped off.
  @discardableResult
  func tryAutopass() -> Bool {
    guard let table, preferences.autopass else { return false }
    // The 5-card checkbox is an off-switch only. Leaving it off used to skip
    // this path entirely — the screenshot case (7d 8c 9d Ts Jd vs Bill's 13).
    if table.count >= 5 && !preferences.autopassFiveCard { return false }
    guard !PlayFinder.canBeat(table, with: seats[turn].hand, rules: rules) else { return false }
    pass(from: turn)
    return true
  }

  /// Test hook: drop a mid-trick without dealing.
  func plantTrick(hands: [[Card]], turn: Int, table: Play, tableOwner: Int) {
    for i in seats.indices { seats[i].hand = i < hands.count ? hands[i] : [] }
    self.turn = turn
    self.table = table
    self.tableOwner = tableOwner
    openingPlay = false
    passes = 0
    result = nil
    lastActions = [nil, nil, nil, nil]
  }

  private func scheduleBot() {
    botTask?.cancel()
    guard botsMoveThemselves, !seats[turn].isHuman, result == nil, !gameOver else { return }
    let seat = turn
    let delay = UInt64((botDelayOverride ?? preferences.gameSpeed.botDelay) * 1_000_000_000)
    botTask = Task { [weak self] in
      try? await Task.sleep(nanoseconds: delay)
      guard !Task.isCancelled, let self, self.turn == seat else { return }
      self.playBotTurn(seat)
    }
  }

  private func playBotTurn(_ seat: Int) {
    if let choice = botChoice(for: seat) {
      submit(choice.cards, from: seat)
    } else {
      pass(from: seat)
    }
  }

  public func botContext(for seat: Int) -> BotContext {
    BotContext(seat: seat,
               hands: seats.map(\.hand),
               isHuman: seats.map(\.isHuman),
               table: table,
               tableOwner: tableOwner,
               mustInclude: openingPlay ? .threeOfDiamonds : nil,
               rules: rules,
               prefersFiveCards: prefersFiveCards[seat])
  }

  /// What the bot would play from `seat` right now; nil is a pass.
  public func botChoice(for seat: Int) -> Play? {
    BotPlayer.choose(botContext(for: seat))
  }

  // MARK: - Scoring

  private func endDeal(winner: Int) {
    var points = [0, 0, 0, 0]
    var left = [0, 0, 0, 0]

    for i in seats.indices where i != winner {
      left[i] = seats[i].hand.count
      var cost = seats[i].hand.reduce(0) { $0 + $1.rank.penalty }
      if seats[i].hand.count >= 10 { cost *= 2 }  // DOUBLE!
      points[i] = -cost
      points[winner] += cost
    }
    for i in seats.indices { seats[i].score += points[i] }

    lastWinner = winner
    result = DealResult(deal: deal, winner: winner, cardsLeft: left, points: points)
    log("*** \(seats[winner].name) WINS! ***")
    gameOver = deal >= rules.dealsPerGame
  }

  /// Called when the score sheet is dismissed.
  public func continueAfterScore() {
    guard result != nil else { return }
    result = nil
    if gameOver {
      startGame()
    } else {
      deal += 1
      newDeal()
    }
  }

  // MARK: - History ("export the history to Memo pad")

  private func log(_ line: String) { history.append(line) }

  public var historyText: String {
    var text = history.joined(separator: "\n")
    if preferences.showCardsLeft, let result {
      text += "\n" + seats.indices.map {
        "\(seats[$0].name): \(result.cardsLeft[$0]) left, \(Self.signed(result.points[$0]))"
      }.joined(separator: "\n")
    }
    return text
  }

  public static func signed(_ n: Int) -> String { n > 0 ? "+\(n)" : "\(n)" }
}

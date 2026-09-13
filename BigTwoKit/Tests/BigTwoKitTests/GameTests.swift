import BigTwoKit
import Foundation
import Testing

@MainActor
struct GameTests {

  /// Seat 1 is the human, as in the app, but nothing runs on a timer — the test moves
  /// every seat itself, the human's with the same bot.
  func driven(_ prefs: Preferences = Preferences(), seed: UInt64 = 1) -> BigTwoGame {
    BigTwoGame(preferences: prefs, seed: seed, humanSeats: [1], botsMoveThemselves: false)
  }

  /// One bot move for whoever's turn it is. Returns false if the bot tried to pass a lead.
  @discardableResult
  func step(_ game: BigTwoGame) -> Bool {
    let seat = game.turn
    if let choice = game.botChoice(for: seat) {
      #expect(game.legalPlays(for: seat).contains(choice))
      #expect(game.submit(choice.cards, from: seat) == nil, "legal \(choice.label) rejected")
      return true
    }
    guard game.table != nil else { return false }
    game.pass(from: seat)
    return true
  }

  // MARK: - Opening

  @Test func holderOfThreeOfDiamondsLeadsAndMustPlayIt() throws {
    let game = driven()
    let seat = game.turn
    #expect(game.seats[seat].hand.contains(.threeOfDiamonds))
    #expect(game.mustPlayThreeOfDiamonds)
    let other = try #require(game.seats[seat].hand.first { $0 != .threeOfDiamonds })
    #expect(game.submit([other], from: seat) == "First play must include 3♦")
    #expect(game.submit([.threeOfDiamonds], from: seat) == nil)
    #expect(!game.mustPlayThreeOfDiamonds)
  }

  @Test func rejectsCardsFromAnotherHand() throws {
    let game = driven()
    let other = (game.turn + 1) % 4
    let stolen = try #require(game.seats[other].hand.last)
    #expect(game.submit([stolen], from: game.turn) == "Not your cards")
    #expect(game.seats[other].hand.contains(stolen))
  }

  @Test func rejectsOutOfTurnAndPassingALead() {
    let game = driven()
    let lead = game.turn
    let hand = game.seats[(lead + 1) % 4].hand
    #expect(game.submit([hand[0]], from: (lead + 1) % 4) == "Not your turn")
    game.pass(from: lead)  // cannot pass a lead
    #expect(game.turn == lead)
    #expect(game.history.count == 1)
  }

  @Test func sameSeedDealsTheSameHands() {
    #expect(driven(seed: 42).seats.map(\.hand) == driven(seed: 42).seats.map(\.hand))
    #expect(driven(seed: 42).seats.map(\.hand) != driven(seed: 43).seats.map(\.hand))
  }

  // MARK: - Rules change between deals

  @Test func hongKongPreferenceWaitsForTheNextDeal() {
    let game = driven()
    game.preferences.hongKong = true
    #expect(!game.rules.hongKong, "a mid-deal change would re-rank the table")
    while game.result == nil { step(game) }
    game.continueAfterScore()
    #expect(game.rules.hongKong)
  }

  @Test func hongKongWinnerLeadsNextDealWithoutThreeOfDiamonds() throws {
    let game = driven(Preferences(hongKong: true))
    while game.result == nil { step(game) }
    let winner = try #require(game.result?.winner)
    game.continueAfterScore()
    #expect(game.turn == winner)
    #expect(!game.mustPlayThreeOfDiamonds)
  }

  // MARK: - Whole games

  @Test(arguments: [false, true])
  func botsFinishWholeGamesWithConsistentScores(hongKong: Bool) {
    for seed in UInt64(1)...3 {
      let game = driven(Preferences(hongKong: hongKong), seed: seed)
      var played = 0
      var steps = 0
      var before = game.seats.map(\.score)

      while steps < 20_000 {
        steps += 1
        if let r = game.result {
          #expect(r.points.reduce(0, +) == 0, "deal \(r.deal) not zero-sum")
          #expect(game.seats[r.winner].hand.isEmpty)
          for i in 0..<4 where i != r.winner {
            let hand = game.seats[i].hand
            let cost = hand.reduce(0) { $0 + $1.rank.penalty } * (hand.count >= 10 ? 2 : 1)
            #expect(r.points[i] == -cost)
            #expect(r.cardsLeft[i] == hand.count)
            #expect(game.seats[i].score == before[i] + r.points[i])
          }
          if game.gameOver { break }
          game.continueAfterScore()
          before = game.seats.map(\.score)
          played = 0
          continue
        }
        let inHands = game.seats.reduce(0) { $0 + $1.hand.count }
        #expect(inHands + played == 52, "cards not conserved")
        let handBefore = game.seats[game.turn].hand.count
        let seat = game.turn
        guard step(game) else {
          Issue.record("bot passed on a lead")
          return
        }
        played += handBefore - game.seats[seat].hand.count
      }
      #expect(game.gameOver, "seed \(seed) did not finish")
      #expect(game.deal == 10)
      game.continueAfterScore()
      #expect(game.deal == 1 && game.seats.allSatisfy { $0.score == 0 }, "a new game starts after 10 deals")
    }
  }

  @Test func autopassSkipsASeatThatCannotAnswer() {
    // Nobody can beat 2♠, so autopass hands a 2♠ lead straight back.
    let twoOfSpades = Card(rank: .two, suit: .spade)
    let game = driven()
    for _ in 0..<5_000 {
      if game.result != nil { game.continueAfterScore() }
      let seat = game.turn
      if game.table == nil, !game.mustPlayThreeOfDiamonds, game.seats[seat].hand.contains(twoOfSpades) {
        #expect(game.submit([twoOfSpades], from: seat) == nil)
        if game.result != nil { continue }  // that was the last card
        #expect(game.turn == seat && game.table == nil, "three autopasses hand the lead back")
        return
      }
      step(game)
    }
    Issue.record("the 2♠ holder never got a lead")
  }
}

struct PreferencesStoreTests {
  func freshDefaults() throws -> UserDefaults {
    let name = "BigTwoKitTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: name))
    defaults.removePersistentDomain(forName: name)
    return defaults
  }

  @Test func roundTrips() throws {
    let store = PreferencesStore(defaults: try freshDefaults())
    #expect(store.load() == Preferences())
    let changed = Preferences(hongKong: true, autopass: false, autopassFiveCard: true, showCardsLeft: false)
    store.save(changed)
    #expect(store.load() == changed)
  }

  @Test func missingKeysKeepTheirDefaults() throws {
    let defaults = try freshDefaults()
    defaults.set(Data(#"{"hongKong":true}"#.utf8), forKey: PreferencesStore.key)
    let prefs = PreferencesStore(defaults: defaults).load()
    #expect(prefs.hongKong)
    #expect(prefs.autopass == Preferences().autopass)
  }

  @Test func corruptDataFallsBackToDefaults() throws {
    let defaults = try freshDefaults()
    defaults.set(Data("nope".utf8), forKey: PreferencesStore.key)
    #expect(PreferencesStore(defaults: defaults).load() == Preferences())
  }
}

import BigTwoKit
import Testing

/// The Palm bots' habits, one per test. The bot sits in seat 0; seat 1 is the human.
struct BotPlayerTests {

  /// `others` are the sizes of seats 1 (the human), 2 and 3, filled with low cards the bot
  /// doesn't hold (their top cards stay below a 2). Codes come back in Big Two order —
  /// ♦ before ♣, so a pair of fives is "5d 5c".
  func context(_ hand: String, table: String? = nil, owner: Int? = nil,
               others: [Int] = [13, 13, 13], prefersFiveCards: Bool = false,
               mustInclude: Card? = nil) throws -> BotContext {
    let mine = try cards(hand)
    var spare = Card.deck.filter { !mine.contains($0) && $0.rank < .two }
    var hands = [mine]
    for count in others {
      hands.append(Array(spare.prefix(count)))
      spare.removeFirst(count)
    }
    return BotContext(seat: 0, hands: hands, isHuman: [false, true, false, false],
                      table: try table.map { try play($0) }, tableOwner: owner,
                      mustInclude: mustInclude, rules: .standard,
                      prefersFiveCards: prefersFiveCards)
  }

  func choice(_ c: BotContext) -> String? {
    BotPlayer.choose(c).map { $0.cards.map(\.code).joined(separator: " ") }
  }

  // MARK: - Leading

  @Test func leadsAFiveCardHandFirst() throws {
    #expect(choice(try context("3c 4d 5h 6s 7d 9c 9h Kd")) == "3c 4d 5h 6s 7d")
  }

  @Test func prefersAPlainStraightToA2345() throws {
    #expect(choice(try context("Ac 2d 3h 4s 5c 6d 7h 8s")) == "3h 4s 5c 6d 7h")
  }

  @Test func wontBreakTwoPairsForAStraight() throws {
    #expect(choice(try context("4c 4d 5h 5s 6c 7d 8h Kd")) == "4d 4c")
    #expect(try BotPlayer.choose(context("4c 4d 5h 6c 7d 8h Kd"))?.kind == .straight)
  }

  @Test func pairMindedBotKeepsPairsOutOfHighStraights() throws {
    let hand = "9c Th Td Js Qd Kh 3c"
    #expect(try BotPlayer.choose(context(hand, prefersFiveCards: false))?.kind != .straight)
    #expect(try BotPlayer.choose(context(hand, prefersFiveCards: true))?.kind == .straight)
  }

  @Test func humanOnTwoCardsGetsASingleBeforeAPair() throws {
    #expect(choice(try context("5c 5d 9h Kd")) == "5d 5c")
    #expect(choice(try context("5c 5d 9h Kd", others: [2, 13, 13])) == "5d")
  }

  @Test func keepsTwosOutOfPairsUntilSomeoneIsNearlyOut() throws {
    #expect(choice(try context("2c 2d 5h 9s Kd")) == "5h")
    #expect(choice(try context("2c 2d 5h 9s Kd", others: [13, 2, 13])) == "2d 2c")
  }

  @Test func openingPlayContainsThreeOfDiamonds() throws {
    let lead = try #require(BotPlayer.choose(
      context("3d 3c 5h 8s 9d Jc Qs Ah", mustInclude: .threeOfDiamonds)))
    #expect(lead.cards.contains(.threeOfDiamonds))
  }

  // MARK: - Following

  @Test func followsASingleWithoutBreakingAPair() throws {
    #expect(choice(try context("5c 5d 9h Kd 2s", table: "4s", owner: 1)) == "9h")
  }

  @Test func breaksPairsOnceAHumanIsDownToThree() throws {
    #expect(choice(try context("5c 5d 9h Kd 2s", table: "4s", owner: 1, others: [3, 13, 13])) == "5d")
  }

  @Test func letsAFellowBotsHighSingleStand() throws {
    #expect(choice(try context("4c 9h As 2d", table: "Ks", owner: 2)) == nil)
    #expect(choice(try context("4c 9h As 2d", table: "Ks", owner: 1)) == "As")
  }

  @Test func sparesAcesAndTwosInAFullHouseUntilSomeoneIsNearlyOut() throws {
    let hand = "Ac Ad Ah 3c 3d 9s Tc"
    #expect(choice(try context(hand, table: "4c 4d 5c 5d 5h", owner: 1)) == nil)
    #expect(choice(try context(hand, table: "4c 4d 5c 5d 5h", owner: 1, others: [13, 2, 13]))
      == "3d 3c Ad Ac Ah")
  }

  @Test func escalatesFromAStraightToAStraightFlush() throws {
    #expect(try BotPlayer.choose(context("4c 5c 6c 7c 8c Kd", table: "9d Tc Jh Qs Ks", owner: 1))?
      .kind == .straightFlush)
  }

  // MARK: - End of the deal

  @Test func leadsTheUnbeatableCardWhenDownToTwo() throws {
    #expect(choice(try context("3d 2s", others: [13, 13, 13])) == "2s")
  }

  @Test func blocksTheNextPlayerOnOneCard() throws {
    #expect(choice(try context("4c 9h Ad", table: "3s", owner: 3, others: [1, 5, 5])) == "Ad")
    #expect(choice(try context("4c 9h Ad", table: "3s", owner: 3, others: [5, 5, 1])) == "4c")
  }

  // MARK: - Strength

  /// Seat 1 plays the old greedy bot, as a stand-in human; the other three play Palm-style.
  /// Seeded, so the numbers are fixed for a given toolchain.
  @MainActor @Test func palmBotsOutscoreTheGreedyBot() {
    var greedyTotal = 0
    for seed in UInt64(1)...8 {
      let game = BigTwoGame(seed: seed, humanSeats: [1], botsMoveThemselves: false)
      while !(game.result != nil && game.gameOver) {
        if game.result != nil { game.continueAfterScore(); continue }
        let seat = game.turn
        let choice = seat == 1
          ? GreedyBot.choose(in: game, seat: seat)
          : BotPlayer.choose(game.botContext(for: seat))
        if let choice { game.submit(choice.cards, from: seat) } else { game.pass(from: seat) }
      }
      greedyTotal += game.seats[1].score
    }
    print("greedy seat over 8 games: \(greedyTotal)")
    #expect(greedyTotal < 0, "the Palm-style bots should beat the greedy one")
  }
}

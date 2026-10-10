import BigTwoKit
import Testing

/// StrongBot sees only its own cards and public counts, and fights every seat.
struct StrongBotTests {

  func context(_ hand: String, table: String? = nil, owner: Int? = nil,
               others: [Int] = [13, 13, 13],
               humanCards: String? = nil,
               discarded: [Card] = []) throws -> BotContext {
    let mine = try cards(hand)
    var spare = Card.deck.filter { !mine.contains($0) }
    var hands = [mine]
    if let humanCards {
      let human = try cards(humanCards)
      spare.removeAll { human.contains($0) }
      hands.append(human)
      for count in others.dropFirst() {
        hands.append(Array(spare.prefix(count)))
        spare.removeFirst(min(count, spare.count))
      }
    } else {
      for count in others {
        hands.append(Array(spare.prefix(count)))
        spare.removeFirst(min(count, spare.count))
      }
    }
    return BotContext(seat: 0, hands: hands, isHuman: [false, true, false, false],
                      table: try table.map { try play($0) }, tableOwner: owner,
                      mustInclude: nil, rules: .standard, prefersFiveCards: false,
                      discarded: discarded)
  }

  func choice(_ c: BotContext) -> String? {
    StrongBot.choose(c).map { $0.cards.map(\.code).joined(separator: " ") }
  }

  @Test func goesOutWhenTheWholeHandIsAPlay() throws {
    #expect(choice(try context("3c 4d 5h 6s 7d")) == "3c 4d 5h 6s 7d")
  }

  @Test func beatsAFellowBotsHighSingle() throws {
    // Classic lets a fellow bot's K stand; Strong fights whoever played it.
    let c = try context("4c 9h 2d", table: "Ks", owner: 2, humanCards: "3d 5c 8h")
    #expect(BotPlayer.choose(c) == nil)
    #expect(choice(c) == "2d")
  }

  @Test func ignoresOtherPlayersHoleCards() throws {
    let a = try context("4c 9h Ad", table: "4s", owner: 3,
                        others: [1, 5, 5], humanCards: "5s")
    let b = try context("4c 9h Ad", table: "4s", owner: 3,
                        others: [1, 5, 5], humanCards: "2s")
    #expect(choice(a) == choice(b))
    #expect(choice(a) == "Ad")  // someone is on one card: highest single, no peek
  }

  @Test func leadsHighWhenAnOpponentHasOneCard() throws {
    #expect(choice(try context("4c 9h 2s", others: [1, 8, 8])) == "2s")
  }

  @Test func leadsThePairWhenAnOpponentHasTwoSingletons() throws {
    // Two cards are rarely a pair. A single is easy for them to top, and then they lead the last one.
    #expect(choice(try context("5c 5d 9h Kd", others: [2, 13, 13])) == "5d 5c")
  }

  @Test func leadsTheStraightAndKeepsTheTwo() throws {
    #expect(choice(try context("3c 4d 5h 6s 7d 9c 2s")) == "3c 4d 5h 6s 7d")
  }

  @Test func leadsAComboWhenSomeoneHasOneCard() throws {
    #expect(choice(try context("3c 4d 5h 6s 7d 2s", others: [1, 8, 8])) == "3c 4d 5h 6s 7d")
  }

  @Test func breaksTheLowPairRatherThanSpendTheTwo() throws {
    #expect(choice(try context("4c 4d 2s", table: "3h")) == "4d")
  }

  @Test func cardCountingLetsALowSingleStand() throws {
    let scared = try context("3c 9h", others: [1, 8, 8])
    #expect(choice(scared) == "9h")
    let mine = try cards("3c 9h")
    let gone = Card.deck.filter { !mine.contains($0) }
    let calm = try context("3c 9h", others: [1, 8, 8], discarded: gone)
    #expect(choice(calm) == "3c")
  }

  @Test func doesNotBreakAPairToFollowWhileTheTableIsSafe() throws {
    #expect(choice(try context("5c 5d 9h Kd 2s", table: "4s", owner: 1)) == "9h")
  }

  // A long hand with one two cannot buy the lead often enough to empty. The
  // recorded games were lost by spending that two on an ace, or on another two.
  @Test func weakHandKeepsItsTwoWhenAnAceIsLed() throws {
    #expect(choice(try context("3c 5d 7h 8s Tc Qd Kh 2c", table: "As")) == nil)
  }

  @Test func weakHandKeepsItsTwoWhenATwoIsLed() throws {
    #expect(choice(try context("3c 5d 7h 8s Tc Qd Kh 2c", table: "2d")) == nil)
  }

  @Test func weakHandStillAnswersANearbyCard() throws {
    #expect(choice(try context("3c 5d 7h 8s Tc Qd Kh 2c", table: "4d")) == "5d")
  }

  @Test func weakHandDoesNotJumpALowCardWithItsKing() throws {
    #expect(choice(try context("3c 3d 4h Kh 2c", table: "5d")) == nil)
  }

  @Test func strongHandTakesAKingBackWithATwo() throws {
    // Straight plus two twos covers the hand, so the king is worth answering.
    #expect(choice(try context("3c 4d 5h 6s 7d 2c 2s", table: "Ks")) == "2c")
  }

  @Test func playsThePlannedBombOverAStraight() throws {
    let hand = "4h 5d 5c 5h 5s 9d 9c Td Qc Qh Kc Kh 2s"
    #expect(choice(try context(hand, table: "6s 7d 8c 9h Ts")) == "4h 5d 5c 5h 5s")
  }

  @Test func weakHandLeadsADeadSingleInsteadOfItsKingPair() throws {
    #expect(choice(try context("3c 5d 7h 9s Kc Kd 2c")) == "3c")
  }

  // MARK: - The contest gear

  // ⚠️ These four are the whole point of the 1.4 bot. The policy that shipped was
  // weak / not-weak, and nearly every hand is weak at six cards, so it passed here
  // and a human won every trick with a king. Spending a stopper is an affordability
  // question now: what is left has to cover what is left to play.

  @Test func spendsAnAceOnAKingWhenTheRestOfTheHandIsStillCovered() throws {
    let c = try context("3c 3d 4h 4s Ac Ad", table: "Ks")
    #expect(LegacyStrongBot.choose(c) == nil)  // the shipped bot folded
    #expect(choice(c) == "Ad")  // the cheaper of the two aces
  }

  @Test func leavesALowSingleAloneRatherThanSpendAnAceOnIt() throws {
    #expect(choice(try context("3c 3d 4h 4s Ac Ad", table: "5d")) == nil)
  }

  // MARK: - Points

  @Test func unloadsItsBiggestCardWhenTheDealIsGoingAway() throws {
    let c = try context("3d 5c 7h 9s Qd 2c", others: [2, 13, 13])
    #expect(choice(c) == "2c")
  }

  @Test func doesNotUnloadWhileEverybodyStillHoldsThirteen() throws {
    #expect(choice(try context("3d 5c 7h 9s Qd 2c")) == "3d")
  }

  /// One Strong seat against three greedy seats — they fight each other, so 3v1
  /// would let greedy win. Strong should still come out ahead on its own score.
  @MainActor @Test func oneStrongBotOutscoresThreeGreedyBots() {
    var strongTotal = 0
    for seed in UInt64(1)...8 {
      let game = BigTwoGame(seed: seed, humanSeats: [0, 1, 2, 3], botsMoveThemselves: false)
      while !(game.result != nil && game.gameOver) {
        if game.result != nil { game.continueAfterScore(); continue }
        let seat = game.turn
        let choice = seat == 0
          ? StrongBot.choose(game.botContext(for: seat))
          : GreedyBot.choose(in: game, seat: seat)
        if let choice { game.submit(choice.cards, from: seat) } else { game.pass(from: seat) }
      }
      strongTotal += game.seats[0].score
    }
    print("one Strong vs three greedy over 8 games: \(strongTotal)")
    // 2026-10-03: +867 (was +344 on 2026-09-26). Floor stays under that so a reshuffle can move.
    #expect(strongTotal > 200, "a single StrongBot should beat greedy seats")
  }
}

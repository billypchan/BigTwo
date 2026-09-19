import BigTwoKit
import Testing

/// StrongBot sees only its own cards and public counts, and fights every seat.
struct StrongBotTests {

  func context(_ hand: String, table: String? = nil, owner: Int? = nil,
               others: [Int] = [13, 13, 13],
               humanCards: String? = nil) throws -> BotContext {
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
                      mustInclude: nil, rules: .standard, prefersFiveCards: false)
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

  @Test func doesNotLeadAPairWhenAnOpponentHasTwo() throws {
    #expect(choice(try context("5c 5d 9h Kd", others: [2, 13, 13])) == "5d")
  }

  @Test func doesNotBreakAPairToFollowWhileTheTableIsSafe() throws {
    #expect(choice(try context("5c 5d 9h Kd 2s", table: "4s", owner: 1)) == "9h")
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
    #expect(strongTotal > 0, "a single StrongBot should beat greedy seats")
  }
}

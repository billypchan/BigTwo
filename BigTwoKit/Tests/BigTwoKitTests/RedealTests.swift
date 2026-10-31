import BigTwoKit
import Foundation
import Testing

@MainActor
struct RedealTests {

  /// Seat 1 (the human) holds `4d 5d 5s 7d 7c 7s 8d 8s 9c 9h Ts Jh Qc`:
  /// two face cards, no ace, no two. Seat 3 leads. The next shuffle is not a bad hand.
  private let rottenSeed: UInt64 = 100

  private func dealt(_ prefs: Preferences = Preferences(hongKong: true),
                     seed: UInt64 = 100,
                     humanSeats: Set<Int> = [1]) -> BigTwoGame {
    BigTwoGame(preferences: prefs, seed: seed, humanSeats: humanSeats, botsMoveThemselves: false)
  }

  @Test func twoOrFewerFaceCardsAndNeitherAceNorTwo() throws {
    #expect(Redeal.isBadHand(try cards("Jh Qc 3d 4d 5d 6d 7d 8d 9d Td 4c 5c 6c")))
    #expect(Redeal.isBadHand(try cards("3d 4d 5d 6d 7d 8d 9d Td 4c 5c 6c 7c 8c")))
    #expect(Redeal.isBadHand(try cards("Jh 3d 4d")))
    #expect(!Redeal.isBadHand(try cards("Jh Qc Kd 3d 4d")))
    #expect(!Redeal.isBadHand(try cards("Jh Qc Ad 3d")))
    #expect(!Redeal.isBadHand(try cards("Jh Qc 2d 3d")))
    #expect(!Redeal.isBadHand(try cards("Ad 3d 4d")))
    #expect(!Redeal.isBadHand(try cards("2s 3d 4d")))
  }

  /// Deal 2 on 2026-10-31. One jack, and neither an ace nor a two.
  @Test func reportedOneJackHandMayBeDealtAgain() throws {
    let hand = try cards("3d 4d 4c 4h 5d 5s 6h 6s 7c 7h 9s Ts Jd")
    #expect(hand.count == 13)
    #expect(Redeal.isBadHand(hand))
  }

  @Test func hongKongAsksOnlyTheHuman() throws {
    let game = dealt()
    #expect(game.offersRedeal)
    #expect(game.rules.hongKong)
    #expect(Redeal.isBadHand(game.seats[1].hand))
    #expect(game.turn == 3)

    let standard = dealt(Preferences())
    #expect(!standard.offersRedeal)
    #expect(Redeal.isBadHand(standard.seats[1].hand))

    let autoplay = dealt(humanSeats: [])
    #expect(!autoplay.offersRedeal)
    #expect(Redeal.isBadHand(autoplay.seats[1].hand))
  }

  @Test func playingOrPassingWaitsForTheAnswer() throws {
    let game = dealt()
    let seat = game.turn
    let card = try #require(game.seats[seat].hand.first)
    #expect(game.submit([card], from: seat) == "Deal again or play")
    #expect(game.seats[seat].hand.contains(card))
    game.pass(from: seat)
    #expect(game.turn == seat)
    #expect(game.offersRedeal)

    game.declineRedeal()
    #expect(!game.offersRedeal)
    #expect(game.submit([card], from: seat) != "Deal again or play")
  }

  @Test func redealShufflesTheSameDealAndDropsTheUnplayedHand() {
    let game = dealt()
    let dealtHands = game.seats.map(\.hand)
    #expect(game.history.filter { $0.hasPrefix("— Deal") }.count == 1)

    game.redeal()
    #expect(!game.offersRedeal)
    #expect(game.deal == 1)
    #expect(game.seats.map(\.hand) != dealtHands)
    #expect(!Redeal.isBadHand(game.seats[1].hand))
    #expect(game.history.filter { $0.hasPrefix("— Deal") }.count == 1)
    #expect(game.historyRounds.first?.deals == 1)

    let kept = game.seats.map(\.hand)
    game.redeal()
    game.declineRedeal()
    #expect(game.seats.map(\.hand) == kept)
  }

  @Test func botsDoNotMoveWhileTheQuestionIsUp() {
    let game = BigTwoGame(preferences: Preferences(hongKong: true), seed: rottenSeed,
                          humanSeats: [1], botsMoveThemselves: true, botDelayOverride: 0)
    #expect(game.offersRedeal)
    #expect(game.turn == 3)
    #expect(game.seats[3].hand.count == 13)

    game.declineRedeal()
    #expect(game.seats[3].hand.count < 13)
  }
}

@testable import BigTwoKit
import Testing

/// Deal 4 screenshot: Adam's 7♦ 8♣ 9♦ 10♠ J♦ on the table, Bill to play
/// 3♣ 4♦ 5♦ 5♥ 6♥ 7♣ 7♥ 10♦ 10♣ J♣ K♠ 2♥ 2♠.
@MainActor
struct AutopassTests {

  private func billHand() throws -> [Card] {
    try cards("3c 4d 5d 5h 6h 7c 7h Td Tc Jc Ks 2h 2s")
  }

  private func tableStraight() throws -> Play {
    try play("7d 8c 9d Ts Jd")
  }

  @Test func screenshotHandCannotBeatStandardStraight() throws {
    #expect(!PlayFinder.canBeat(try tableStraight(), with: try billHand(), rules: .standard))
    #expect(PlayFinder.canBeat(try tableStraight(), with: try billHand(), rules: .hongKong),
            "HK 23456 is the largest straight and Bill holds 2-3-4-5-6")
  }

  @Test func autopassFiresOnFiveCardEvenWhenFiveCardFlagIsOff() throws {
    var prefs = Preferences()
    prefs.autopass = true
    prefs.autopassFiveCard = false
    let game = BigTwoGame(preferences: prefs, seed: 1, humanSeats: [1], botsMoveThemselves: false)
    game.plantTrick(hands: [[], try billHand(), [], []],
                    turn: 1, table: try tableStraight(), tableOwner: 0)
    #expect(game.tryAutopass())
    #expect(game.lastActions[1] == .passed)
  }

  @Test func autopassDoesNotFireWhenHongKongMakes23456AReply() throws {
    let game = BigTwoGame(preferences: Preferences(hongKong: true), seed: 1,
                          humanSeats: [1], botsMoveThemselves: false)
    game.plantTrick(hands: [[], try billHand(), [], []],
                    turn: 1, table: try tableStraight(), tableOwner: 0)
    #expect(game.rules.hongKong)
    #expect(!game.tryAutopass(), "Bill can play 23456 under HK")
    #expect(game.lastActions[1] == nil)
  }

  @Test func autopassOffLeavesTheHumanToPass() throws {
    var prefs = Preferences()
    prefs.autopass = false
    let game = BigTwoGame(preferences: prefs, seed: 1, humanSeats: [1], botsMoveThemselves: false)
    game.plantTrick(hands: [[], try billHand(), [], []],
                    turn: 1, table: try tableStraight(), tableOwner: 0)
    #expect(!game.tryAutopass())
    #expect(game.lastActions[1] == nil)
    #expect(game.turn == 1)
  }
}

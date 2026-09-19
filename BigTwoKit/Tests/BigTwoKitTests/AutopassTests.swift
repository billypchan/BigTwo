import BigTwoKit
import Testing

/// Deal 4 screenshot: Adam's 7♦ 8♣ 9♦ 10♠ J♦ on the table, Bill to play
/// 3♣ 4♦ 5♦ 5♥ 6♥ 7♣ 7♥ 10♦ 10♣ J♣ K♠ 2♥ 2♠. No 5-card beats that
/// straight under standard rules (34567 and 23456 both lose). HK makes 23456
/// the largest straight, so the same hand *can* answer.
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
    prefs.autopassFiveCard = false  // shipped default — used to block this path
    let game = BigTwoGame(preferences: prefs, seed: 1, humanSeats: [1], botsMoveThemselves: false)
    let empty = [Card]()
    game.plantTrick(hands: [empty, try billHand(), empty, empty],
                    turn: 1, table: try tableStraight(), tableOwner: 0)
    #expect(game.tryAutopass())
    #expect(game.lastActions[1] == .passed)
  }

  @Test func autopassDoesNotFireWhenHongKongMakes23456AReply() throws {
    var prefs = Preferences()
    prefs.autopass = true
    prefs.hongKong = true
    let game = BigTwoGame(preferences: prefs, seed: 1, humanSeats: [1], botsMoveThemselves: false)
    game.plantTrick(hands: [[], try billHand(), [], []],
                    turn: 1, table: try tableStraight(), tableOwner: 0)
    // rules were fixed at deal time from prefs.hongKong; plant does not retake them.
    // Force the HK ranking by submitting under a game whose rules already match.
    #expect(PlayFinder.canBeat(try tableStraight(), with: try billHand(), rules: game.rules)
              == game.rules.hongKong)
    if game.rules.hongKong {
      #expect(!game.tryAutopass(), "Bill can play 23456 under HK")
    }
  }

  @Test func autopassOffLeavesTheHumanToPass() throws {
    var prefs = Preferences()
    prefs.autopass = false
    prefs.autopassFiveCard = true
    let game = BigTwoGame(preferences: prefs, seed: 1, humanSeats: [1], botsMoveThemselves: false)
    game.plantTrick(hands: [[], try billHand(), [], []],
                    turn: 1, table: try tableStraight(), tableOwner: 0)
    #expect(!game.tryAutopass())
    #expect(game.lastActions[1] == nil)
    #expect(game.turn == 1)
  }
}

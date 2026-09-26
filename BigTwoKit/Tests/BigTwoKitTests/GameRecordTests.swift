import BigTwoKit
import Foundation
import Testing

@MainActor
struct GameRecordTests {

  @Test func openHandsAndTheStepAreBothRecorded() throws {
    let game = BigTwoGame(seed: 2, humanSeats: [0, 1, 2, 3], botsMoveThemselves: false)
    #expect(game.history.first == "— Deal 1 —")
    for seat in game.seats {
      let line = "\(seat.name): \(seat.hand.map(\.label).joined(separator: " "))"
      #expect(game.history.contains(line))
      #expect(seat.hand.count == 13)
    }
    let seat = game.turn
    let play = try #require(game.legalPlays(for: seat).first)
    #expect(game.submit(play.cards, from: seat) == nil)
    #expect(game.history.last == "\(game.seats[seat].name): \(play.label)")
  }

  @Test func theNextDealKeepsTheFirst() throws {
    let game = BigTwoGame(seed: 1, humanSeats: [0, 1, 2, 3], botsMoveThemselves: false)
    let opener = game.history[1]
    let seat = game.turn
    let play = try #require(game.legalPlays(for: seat).first)
    game.submit(play.cards, from: seat)
    while game.result == nil {
      let turn = game.turn
      if let choice = game.botChoice(for: turn) {
        game.submit(choice.cards, from: turn)
      } else {
        game.pass(from: turn)
      }
    }
    #expect(game.historyText.contains("left,"))
    game.continueAfterScore()
    #expect(game.history.contains("— Deal 1 —"))
    #expect(game.history.contains("— Deal 2 —"))
    #expect(game.history.contains(opener))
  }

  @Test func namesFollowTheTableUntilTheFirstStep() throws {
    let game = BigTwoGame(seed: 2, botsMoveThemselves: false)
    game.applyDisplayNames(["亞當", "比爾", "卡爾", "迪安"])
    #expect(game.history.contains { $0.hasPrefix("比爾:") })
    let seat = game.turn
    let play = try #require(game.legalPlays(for: seat).first)
    game.submit(play.cards, from: seat)
    game.applyDisplayNames(["A", "B", "C", "D"])
    #expect(game.history.contains { $0.hasPrefix("比爾:") })
  }

  @Test func aPlayedGameIsKeptAndAnUnplayedDealIsNot() throws {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("bigtwo-record-\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: url) }
    let store = GameRecordStore(url: url)

    let game = BigTwoGame(seed: 2, humanSeats: [0, 1, 2, 3], botsMoveThemselves: false,
                          recordStore: store)
    let seat = game.turn
    let play = try #require(game.legalPlays(for: seat).first)
    game.submit(play.cards, from: seat)
    let step = "\(game.seats[seat].name): \(play.label)"

    let again = BigTwoGame(seed: 3, botsMoveThemselves: false, recordStore: store)
    #expect(again.historyText.contains(step))
    #expect(!again.history.contains(step))

    let freshURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("bigtwo-record-\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: freshURL) }
    let fresh = GameRecordStore(url: freshURL)
    _ = BigTwoGame(seed: 1, botsMoveThemselves: false, recordStore: fresh)
    let relaunch = BigTwoGame(seed: 1, botsMoveThemselves: false, recordStore: fresh)
    let deals = relaunch.historyText.components(separatedBy: "— Deal ").count - 1
    #expect(deals == 1)
  }
}

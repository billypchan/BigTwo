import BigTwoKit
import Testing

struct PlayerNameTests {

  @Test func emptyStoredNamesUseEnglishDefaults() {
    #expect(BigTwoGame.resolvedNames([]) == ["Adam", "Bill", "Carl", "Dean"])
    #expect(BigTwoGame.resolvedNames(["", "  ", "", ""]) == ["Adam", "Bill", "Carl", "Dean"])
  }

  @Test func customNameWinsPerSeat() {
    #expect(BigTwoGame.resolvedNames(["", "Mei", "", ""]) == ["Adam", "Mei", "Carl", "Dean"])
  }

  @Test func localizedDefaultsFillEmptySlots() {
    let zh = ["亞當", "比爾", "卡爾", "迪安"]
    #expect(BigTwoGame.resolvedNames([], defaults: zh) == zh)
    #expect(BigTwoGame.resolvedNames(["", "Bill", "", ""], defaults: zh)
              == ["亞當", "Bill", "卡爾", "迪安"])
  }

  @Test func namesAreTrimmedAndCapped() {
    #expect(BigTwoGame.resolvedNames(["  Ann  ", "VeryLongNameHere"])[0] == "Ann")
    #expect(BigTwoGame.resolvedNames(["", "VeryLongNameHere"])[1] == "VeryLongNa")
  }
}

@MainActor
struct PlayerNameGameTests {

  @Test func applyNamesPersistsAndShowsOnSeats() {
    let game = BigTwoGame(seed: 1, botsMoveThemselves: false)
    game.applyNames(["", "Mei", "", "Zed"], defaults: ["亞當", "比爾", "卡爾", "迪安"])
    #expect(game.seats.map(\.name) == ["亞當", "Mei", "卡爾", "Zed"])
    #expect(game.preferences.playerNames == ["", "Mei", "", "Zed"])
    #expect(game.hasCustomNames)
  }

  @Test func displayNamesFollowLocaleUntilEdited() {
    let game = BigTwoGame(seed: 1, botsMoveThemselves: false)
    game.applyDisplayNames(["亞當", "比爾", "卡爾", "迪安"])
    #expect(game.seats.map(\.name) == ["亞當", "比爾", "卡爾", "迪安"])
    #expect(!game.hasCustomNames)
    #expect(game.preferences.playerNames.isEmpty)
  }
}

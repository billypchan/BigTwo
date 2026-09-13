import XCTest

final class GameUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    continueAfterFailure = false
    app = .bigTwo()
  }

  func testLaunch_youHoldThreeOfDiamondsAndLead() {
    app.launch()
    XCTAssertTrue(app.prompt.waitForExistence(timeout: 10))
    XCTAssertEqual(app.prompt.label, "Lead with the 3♦")
    XCTAssertEqual(app.handCards.count, 13)
    XCTAssertEqual(app.element("deal_label").label, "Deal 1/10")
    XCTAssertFalse(app.buttons["button_pass"].isEnabled, "a lead cannot be passed")
    XCTAssertFalse(app.buttons["button_play"].isEnabled, "nothing selected yet")
  }

  func testLead_threeOfDiamondsLeavesTwelveCards() {
    app.launch()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10))
    app.element("hand_3d").tap()
    waitForCount(app.selectedHandCards, 1)
    XCTAssertTrue(app.element("hand_3d").isSelected)
    XCTAssertEqual(app.buttons["button_play"].label, "Lead")
    app.buttons["button_play"].tap()

    waitForCount(app.handCards, 12)
    XCTAssertFalse(app.element("hand_3d").exists)
    // The strip shows only the last two moves — the bots may already have played past it.
    app.buttons["menu_button"].tap()
    XCTAssertTrue(app.element("history_text").waitForExistence(timeout: 5))
    XCTAssertTrue(app.element("history_text").label.contains("Bill: 3♦"))
  }

  func testIllegalPlay_showsReasonAndKeepsHand() {
    app.launch()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10))
    app.element("hand_3d").tap()
    app.element("hand_4c").tap()
    waitForCount(app.selectedHandCards, 2)  // a loaded simulator lags behind the taps
    app.buttons["button_play"].tap()

    waitFor(app.prompt, label: "Not a legal combination")
    XCTAssertEqual(app.handCards.count, 13)
    XCTAssertEqual(app.selectedHandCards.count, 2, "a rejected play keeps the selection")
  }

  func testLongPress_selectsTheWholeRank() {
    app.launch()
    XCTAssertTrue(app.element("hand_8h").waitForExistence(timeout: 10))
    app.element("hand_8h").press(forDuration: 0.6)
    waitForCount(app.selectedHandCards, 2)
    XCTAssertTrue(app.element("hand_8s").isSelected)
  }

  func testDoubleTap_selectsTheWholeSuit() {
    app.launch()
    XCTAssertTrue(app.element("hand_Qc").waitForExistence(timeout: 10))
    app.element("hand_Qc").doubleTap()
    waitForCount(app.selectedHandCards, 6)  // 4c 9c Tc Jc Qc 2c
    XCTAssertFalse(app.element("hand_3d").isSelected)

    app.buttons["button_clear"].tap()
    waitForCount(app.selectedHandCards, 0)
  }

  func testScoreSheet_swipeDownDoesNotDismissIt() {
    app = .bigTwo(["-autoplay", "YES"])
    app.launch()
    let sheet = app.element("score_sheet")
    XCTAssertTrue(sheet.waitForExistence(timeout: 120), "the bots never finished the deal")
    waitUntilSettled(sheet)
    let winnerRows = app.descendants(matching: .any).matching(
      NSPredicate(format: "identifier BEGINSWITH 'score_row_' AND label CONTAINS '*WIN!*'"))
    XCTAssertEqual(winnerRows.count, 1, "one winner, asterisks shown literally")

    // ⚠️ `sheet.swipeDown()` never moves a sheet — it passed with the guard removed.
    // A press-and-drag from just inside the sheet's top edge is what a finger does.
    let top = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
      .withOffset(CGVector(dx: 0, dy: 12))
    top.press(forDuration: 0.2,
              thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
    sleep(1)
    XCTAssertTrue(sheet.exists, "only OK may leave the score sheet")

    app.buttons["score_ok"].tap()
    waitFor(app.element("deal_label"), label: "Deal 2/10")
  }

  func testPreferences_surviveARelaunch() {
    app.launch()
    app.buttons["menu_button"].tap()
    let hk = app.switches["pref_hongKong"]
    XCTAssertTrue(hk.waitForExistence(timeout: 5))
    XCTAssertEqual(hk.value as? String, "0")
    hk.switches.firstMatch.tap()
    XCTAssertEqual(hk.value as? String, "1")

    app.terminate()
    app = .bigTwo(["-keepPreferences", "YES"])
    app.launch()
    app.buttons["menu_button"].tap()
    XCTAssertTrue(app.switches["pref_hongKong"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.switches["pref_hongKong"].value as? String, "1")
  }
}

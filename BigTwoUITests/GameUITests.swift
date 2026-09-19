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
    XCTAssertEqual(app.element("left_1").label, "left: 13")
    XCTAssertFalse(app.buttons["button_pass"].isEnabled, "a lead cannot be passed")
    XCTAssertFalse(app.buttons["button_play"].isEnabled, "nothing selected yet")
  }

  func testLead_showsInYourRowAndTheTracker() {
    app.launch()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10))
    app.element("hand_3d").tap()
    waitForCount(app.selectedHandCards, 1)
    XCTAssertTrue(app.element("hand_3d").isSelected)
    XCTAssertEqual(app.buttons["button_play"].label, "Lead")
    app.buttons["button_play"].tap()

    waitForCount(app.handCards, 12)
    XCTAssertFalse(app.element("hand_3d").exists)
    XCTAssertTrue(app.element("row1_3d").waitForExistence(timeout: 5), "your row shows your lead")
    XCTAssertTrue((app.element("card_tracker").value as? String ?? "").contains("3d"))

    app.buttons["menu_button"].tap()
    app.buttons["menu_history"].tap()
    XCTAssertTrue(app.element("history_text").waitForExistence(timeout: 5))
    XCTAssertTrue(app.element("history_text").label.contains("Bill: 3♦"))
  }

  func testPass_showsPassInYourRow() {
    app.launch()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10))
    app.element("hand_3d").tap()
    waitForCount(app.selectedHandCards, 1)
    app.buttons["button_play"].tap()

    // Either you get to answer and pass by hand, or autopass passes for you.
    let yourPlay = NSPredicate(format: "label == 'Your Play'")
    let deadline = Date().addingTimeInterval(20)
    while Date() < deadline && !app.element("pass_1").exists {
      if yourPlay.evaluate(with: app.prompt), app.buttons["button_pass"].isEnabled {
        app.buttons["button_pass"].tap()
      }
      usleep(200_000)
    }
    XCTAssertTrue(app.element("pass_1").exists, "PASS should replace your row's cards")
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
    waitForCount(app.selectedHandCards, 6)  // 4c 9c Tc Jc Qc 2c — 5+ of a suit
    XCTAssertFalse(app.element("hand_3d").isSelected)

    app.buttons["button_clear"].tap()
    waitForCount(app.selectedHandCards, 0)
  }

  func testDoubleTap_selectsPairWhenSuitIsShort() {
    app.launch()
    XCTAssertTrue(app.element("hand_8h").waitForExistence(timeout: 10))
    app.element("hand_8h").doubleTap()
    waitForCount(app.selectedHandCards, 2)  // two hearts; pair of eights
    XCTAssertTrue(app.element("hand_8s").isSelected)
    XCTAssertFalse(app.element("hand_6h").isSelected)
  }

  func testDoubleTap_doesNothingWithoutAPair() {
    app.launch()
    XCTAssertTrue(app.element("hand_6h").waitForExistence(timeout: 10))
    app.element("hand_6h").doubleTap()
    waitForCount(app.selectedHandCards, 1)  // two hearts, only one 6
    XCTAssertTrue(app.element("hand_6h").isSelected)
    XCTAssertFalse(app.element("hand_8h").isSelected)
  }

  func testAbout_showsSharedKit() {
    app.launch()
    app.buttons["menu_button"].tap()
    XCTAssertTrue(app.buttons["menu_about"].waitForExistence(timeout: 5))
    app.buttons["menu_about"].tap()
    XCTAssertTrue(app.buttons["about_ok"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["about_share"].exists)
    XCTAssertTrue(app.buttons["about_rate"].exists)
    XCTAssertTrue(app.buttons["about_report"].exists)
    XCTAssertTrue(app.buttons["about_x"].exists)
    XCTAssertFalse(app.buttons["about_sharedkit"].exists)
    XCTAssertEqual(app.state, .runningForeground)
    app.buttons["about_ok"].tap()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 5))
  }

  func testSortIcon_togglesBetweenRankAndSuit() {
    app.launch()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10))
    XCTAssertEqual(app.handCards.element(boundBy: 1).identifier, "hand_4c", "by rank: 3d 4c …")
    app.buttons["button_sort"].tap()
    let bySuit = NSPredicate(format: "identifier == 'hand_Jd'")
    let expectation = XCTNSPredicateExpectation(predicate: bySuit, object: app.handCards.element(boundBy: 1))
    XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed, "by suit: 3d Jd …")
  }

  func testScoreDialog_isModal() {
    app = .bigTwo(["-autoplay", "YES"])
    app.launch()
    let dialog = app.element("score_sheet")
    XCTAssertTrue(dialog.waitForExistence(timeout: 120), "the bots never finished the deal")
    let winnerRows = app.descendants(matching: .any).matching(
      NSPredicate(format: "identifier BEGINSWITH 'score_row_' AND label CONTAINS '*WIN!*'"))
    XCTAssertEqual(winnerRows.count, 1, "one winner, asterisks shown literally")

    // A tap on the hand below the dialog must not reach it.
    let card = app.handCards.firstMatch
    if card.exists {
      card.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5)).tap()
      sleep(1)
      XCTAssertEqual(app.selectedHandCards.count, 0, "the score dialog is modal")
    }
    XCTAssertTrue(dialog.exists, "only OK leaves the score dialog")

    app.buttons["score_ok"].tap()
    waitFor(app.element("deal_label"), label: "Deal 2/10")
  }

  func testPreferences_surviveARelaunch() {
    app.launch()
    openPreferences()
    let hk = app.buttons["pref_hongKong"]
    XCTAssertTrue(hk.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["pref_source"].exists)
    XCTAssertTrue(app.buttons["pref_bots_Strong"].isSelected)
    XCTAssertEqual(hk.value as? String, "0")
    hk.tap()
    waitFor(hk, value: "1")
    app.buttons["pref_bots_Classic"].tap()
    app.buttons["pref_speed_Fast"].tap()
    app.buttons["pref_ok"].tap()

    app.terminate()
    app = .bigTwo(["-keepPreferences", "YES"])
    app.launch()
    openPreferences()
    XCTAssertTrue(app.buttons["pref_hongKong"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.buttons["pref_hongKong"].value as? String, "1")
    XCTAssertTrue(app.buttons["pref_speed_Fast"].isSelected)
    XCTAssertTrue(app.buttons["pref_bots_Classic"].isSelected)
    XCTAssertTrue(app.buttons["pref_source"].exists)
  }

  func testNames_customNameShowsOnTheTableAndSurvivesARelaunch() {
    app.launch()
    XCTAssertTrue(app.element("name_1").waitForExistence(timeout: 10))
    XCTAssertEqual(app.element("name_1").label, "Bill, to play")

    openNames()
    let field = app.element("pref_name_1")
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["names_ok"].exists)
    field.tap()
    field.typeText("Mei")
    // Keyboard covers the square's OK; tap the form title to dismiss it.
    app.staticTexts["Player names"].tap()
    app.buttons["names_ok"].tap()
    waitFor(app.element("name_1"), label: "Mei, to play")

    app.terminate()
    app = .bigTwo(["-keepPreferences", "YES"])
    app.launch()
    XCTAssertTrue(app.element("name_1").waitForExistence(timeout: 10))
    waitFor(app.element("name_1"), label: "Mei, to play")
  }

  /// Menu tap can lag the synthesized hit; wait for the item before tapping it.
  private func openPreferences() {
    app.buttons["menu_button"].tap()
    XCTAssertTrue(app.buttons["menu_preferences"].waitForExistence(timeout: 5))
    app.buttons["menu_preferences"].tap()
  }

  private func openNames() {
    app.buttons["menu_button"].tap()
    XCTAssertTrue(app.buttons["menu_names"].waitForExistence(timeout: 5))
    app.buttons["menu_names"].tap()
  }
}

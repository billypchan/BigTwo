import XCTest

final class GameUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    continueAfterFailure = false
    app = .bigTwo()
  }

  /// Opening the menu used to grow the square (the dismiss layer is flexible) and
  /// leave a strip of felt between the title rule and the menu.
  func testMenu_staysFlushWithTheTitleAndDoesNotMoveTheTable() {
    app.launch()
    let title = app.buttons["menu_button"]
    let deal = app.element("deal_label")
    XCTAssertTrue(title.waitForExistence(timeout: 10))
    XCTAssertTrue(app.prompt.waitForExistence(timeout: 10))
    let dealY = deal.frame.origin.y
    let promptY = app.prompt.frame.origin.y
    let titleMaxY = title.frame.maxY
    title.tap()
    let item = app.buttons["menu_new_game"]
    XCTAssertTrue(item.waitForExistence(timeout: 5))
    waitUntilSettled(item)
    XCTAssertEqual(deal.frame.origin.y, dealY, accuracy: 0.5, "the table moved when the menu opened")
    XCTAssertEqual(app.prompt.frame.origin.y, promptY, accuracy: 0.5, "the table moved when the menu opened")
    XCTAssertEqual(title.frame.maxY, titleMaxY, accuracy: 0.5, "the title moved when the menu opened")
    XCTAssertEqual(item.frame.minY, title.frame.maxY, accuracy: 1,
                   "felt is showing between the title and the menu")
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
    XCTAssertTrue(app.element("history_text").label.contains("***"), "hands stay hidden during the deal")
    XCTAssertTrue(app.buttons["history_export"].exists)
    XCTAssertEqual(app.element("history_round").label, "This game")
    XCTAssertFalse(app.buttons["history_prev"].isEnabled, "a first run has nothing earlier")
    XCTAssertFalse(app.buttons["history_next"].isEnabled)
  }

  func testHistory_pagesBackToTheGameBeforeTheRelaunch() {
    app.launch()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10))
    app.element("hand_3d").tap()
    waitForCount(app.selectedHandCards, 1)
    app.buttons["button_play"].tap()
    waitForCount(app.handCards, 12)

    // The record survives the relaunch; starting a game files the played one away.
    app.terminate()
    app = .bigTwo(["-keepPreferences", "YES"])
    app.launch()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10))
    app.buttons["menu_button"].tap()
    app.buttons["menu_history"].tap()
    XCTAssertTrue(app.element("history_text").waitForExistence(timeout: 5))
    XCTAssertEqual(app.element("history_round").label, "This game")
    XCTAssertFalse(app.element("history_text").label.contains("Bill: 3♦"),
                   "the new game has no steps yet")

    let older = app.buttons["history_prev"]
    XCTAssertTrue(older.isEnabled, "the game before the relaunch is a round of its own")
    older.tap()
    let round = app.element("history_round")
    let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != 'This game'"),
                                            object: round)
    XCTAssertEqual(XCTWaiter().wait(for: [changed], timeout: 5), .completed,
                   "the earlier round is labelled with its date")
    XCTAssertTrue(app.element("history_text").label.contains("Bill: 3♦"))
    XCTAssertFalse(app.buttons["history_prev"].isEnabled, "only two rounds")
    XCTAssertTrue(app.buttons["history_next"].isEnabled)
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

  /// The Apple Watch note is shown once. ⚠️ `UITestMode` suppresses it — the preference
  /// suite is wiped every launch, so without that it would cover the table in every test —
  /// and `-watchNotice YES` is what asks for it back.
  func testWatchNotice_showsOnceAndDismisses() {
    app.launchArguments += ["-watchNotice", "YES"]
    app.launch()
    XCTAssertTrue(app.buttons["watch_notice_ok"].waitForExistence(timeout: 10),
                  "the Apple Watch note never came up")
    app.buttons["watch_notice_ok"].tap()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10),
                  "the table was not there after dismissing the note")
    XCTAssertFalse(app.buttons["watch_notice_ok"].exists)
  }

  /// Every other test launches without that argument, so the note must stay away.
  func testWatchNotice_staysAwayInTests() {
    app.launch()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10))
    XCTAssertFalse(app.buttons["watch_notice_ok"].exists)
  }

  func testAbout_showsSharedKit() {
    app.launch()
    // The title tab is 22 units. The first tap often misses it; the tour retries too.
    app.buttons["menu_button"].tap()
    if !app.buttons["menu_about"].waitForExistence(timeout: 3) {
      app.buttons["menu_button"].tap()
    }
    XCTAssertTrue(app.buttons["menu_about"].waitForExistence(timeout: 5))
    app.buttons["menu_about"].tap()
    XCTAssertTrue(app.buttons["about_ok"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.element("about_share").waitForExistence(timeout: 5))
    XCTAssertTrue(app.element("about_rate").exists)
    XCTAssertTrue(app.element("about_report").exists)
    // Moved here from Preferences: the repo link belongs with the other credits rows.
    XCTAssertTrue(app.element("about_source").exists)
    // ⚠️ Not tapped, like about_source and about_report: it opens a browser and the test
    // cannot come back.
    XCTAssertTrue(app.element("about_coffee").exists)
    XCTAssertTrue(app.element("about_x").exists)
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
    XCTAssertFalse(app.buttons["pref_source"].exists, "Source lives in About now")
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
  }

  /// ⚠️ Expert is a third pill, not a replacement, and the setting it saves is a new
  /// key — an old build only wrote Classic/Strong. If this ever fails after a relaunch,
  /// check `Preferences.botLevel`'s migration before touching the view.
  func testPreferences_expertIsAThirdBotLevelAndSticks() {
    app.launch()
    openPreferences()
    let expert = app.buttons["pref_bots_Expert"]
    XCTAssertTrue(expert.waitForExistence(timeout: 5))
    XCTAssertFalse(expert.isSelected, "Strong stays the default")
    expert.tap()
    waitFor(expert, selected: true)
    app.buttons["pref_ok"].tap()

    app.terminate()
    app = .bigTwo(["-keepPreferences", "YES"])
    app.launch()
    openPreferences()
    XCTAssertTrue(app.buttons["pref_bots_Expert"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["pref_bots_Expert"].isSelected)
    XCTAssertFalse(app.buttons["pref_bots_Strong"].isSelected)
  }

  func testNames_customNameShowsOnTheTableAndSurvivesARelaunch() {
    app.launch()
    XCTAssertTrue(app.element("name_1").waitForExistence(timeout: 10))
    XCTAssertEqual(app.element("name_1").label, "Bill, to play")

    openNames()
    let field = app.element("pref_name_1")
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["names_ok"].exists)
    // Row 2 is the human seat: its number is inverted and says so to VoiceOver.
    XCTAssertTrue(app.element("names_you").exists)
    XCTAssertEqual(app.element("names_you").label, "Player 2, you")
    XCTAssertTrue(app.element("names_seat_0").exists)
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

  /// Help is the second menu row. The text is one element, so the rules can be
  /// read without scrolling. New Game stays first: the flush test measures that row.
  func testHelp_explainsTheButtonsAndTheRules() {
    app.launch()
    openMenu()
    let about = app.buttons["menu_about"]
    XCTAssertTrue(about.waitForExistence(timeout: 5))
    waitUntilSettled(about)
    XCTAssertTrue(about.isHittable, "six menu rows do not fit in the square")
    app.buttons["menu_help"].tap()
    let text = app.element("help_text")
    XCTAssertTrue(text.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["help_ok"].isHittable, "Help's OK is outside the square")
    if XCUIApplication.uiTestLanguage == "en" {
      XCTAssertTrue(text.label.contains("Double-tap"))
      XCTAssertTrue(text.label.contains("empty box"))
      XCTAssertTrue(text.label.contains("JQKA2"))
      XCTAssertTrue(text.label.contains("23456"))
      XCTAssertTrue(text.label.contains("straight flush"))
    }
    attachScreen("help")
    app.buttons["help_ok"].tap()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["help_ok"].exists)
  }

  /// First launch asks for a name, then the watch note. ⚠️ `UITestMode` suppresses
  /// the name dialog — the same reason as the watch note — so `-askName YES` asks
  /// for it back. The two never show at once.
  func testNamePrompt_asksThenTheWatchNote() {
    app.launchArguments += ["-askName", "YES", "-watchNotice", "YES"]
    app.launch()
    let intro = app.element("name_intro")
    XCTAssertTrue(intro.waitForExistence(timeout: 10), "the name dialog never came up")
    XCTAssertTrue(app.element("names_you").exists, "the dark row is the player")
    XCTAssertFalse(app.buttons["watch_notice_ok"].exists, "the watch note stacked on the names")
    XCTAssertTrue(app.buttons["names_ok"].isHittable, "Names' OK is outside the square")
    if XCUIApplication.uiTestLanguage == "en" {
      XCTAssertTrue(intro.label.contains("dark row"))
    }
    attachScreen("name_intro")
    app.buttons["names_ok"].tap()
    XCTAssertTrue(app.buttons["watch_notice_ok"].waitForExistence(timeout: 5),
                  "the watch note did not follow the name dialog")
    XCTAssertFalse(intro.exists)
    app.buttons["watch_notice_ok"].tap()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10))
  }

  /// A normal UI-test launch must not cover the table. Opening Names from the menu
  /// does not repeat the first-launch line.
  func testNamePrompt_staysAwayInTests() {
    app.launch()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10))
    XCTAssertFalse(app.element("name_intro").exists)
    XCTAssertFalse(app.buttons["names_ok"].exists)
    XCTAssertFalse(app.buttons["watch_notice_ok"].exists)
    openMenu()
    app.buttons["menu_names"].tap()
    XCTAssertTrue(app.buttons["names_ok"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.element("name_intro").exists)
  }

  /// The title tab is 22 units. The first tap often misses it.
  private func openMenu() {
    app.buttons["menu_button"].tap()
    if !app.buttons["menu_new_game"].waitForExistence(timeout: 3) {
      app.buttons["menu_button"].tap()
    }
    XCTAssertTrue(app.buttons["menu_new_game"].waitForExistence(timeout: 5))
  }

  private func attachScreen(_ name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
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

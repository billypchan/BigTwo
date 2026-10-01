import XCTest

/// Seed 2 deals the human seat `3d 4c 6h 8h 8s 9c 9s Tc Jd Jc Qc Ad 2c`, so you lead
/// with the 3 of diamonds — the same fixed deal the phone suite uses.
final class WatchGameUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["UITestMode", "-AppleLanguages", "(en)", "-seed", "2"]
    app.launch()
  }

  /// ⚠️ There is deliberately no "scroll until hittable" dance here. `isHittable` is
  /// true for every card in the hand, including the ones below the fold, so such a loop
  /// never runs — it looks like a safeguard and is not one. What makes a tap land is the
  /// layout: the first row of the hand has to be on screen. If that stops being true,
  /// this test fails with "never became selected" and the layout is the thing to look at.
  private func card(_ id: String) -> XCUIElement {
    let element = app.descendants(matching: .any)[id]
    XCTAssertTrue(element.waitForExistence(timeout: 20))
    return element
  }

  /// The paywall is off, so the game is what opens.
  func testOpensOnTheGame() {
    let prompt = app.staticTexts["prompt"]
    XCTAssertTrue(prompt.waitForExistence(timeout: 20))
    XCTAssertEqual(prompt.label, "Your Lead")
  }

  func testTappingACardSelectsIt() {
    let three = card("hand_3d")
    XCTAssertFalse(three.isSelected)

    three.tap()
    // ⚠️ Never read the trait on the next line — the tap lands after this returns.
    let selected = NSPredicate(format: "selected == true")
    let outcome = XCTWaiter().wait(
      for: [XCTNSPredicateExpectation(predicate: selected, object: three)], timeout: 10)
    XCTAssertEqual(outcome, .completed, "the 3 of diamonds never became selected")
  }

  private var selectedCards: XCUIElementQuery {
    app.descendants(matching: .any)
      .matching(NSPredicate(format: "identifier BEGINSWITH 'hand_' AND selected == true"))
  }

  private func waitForSelected(_ count: Int, _ what: String,
                               file: StaticString = #filePath, line: UInt = #line) {
    let outcome = XCTWaiter().wait(
      for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == %d", count),
                                      object: selectedCards)], timeout: 10)
    XCTAssertEqual(outcome, .completed,
                   "\(what): expected \(count) selected, got \(selectedCards.count)",
                   file: file, line: line)
  }

  /// Double tap takes the whole suit when you hold five or more of it. Seed 2 leaves the
  /// human six clubs — 4c 9c Tc Jc Qc 2c — so a double tap on one takes all six.
  func testDoubleTapTakesTheSuitWhenItIsLong() {
    card("hand_9c").doubleTap()
    waitForSelected(6, "double tap on a long suit")
  }

  /// With fewer than five of the suit it takes the pair instead: two eights here.
  func testDoubleTapTakesThePairWhenTheSuitIsShort() {
    card("hand_8h").doubleTap()
    waitForSelected(2, "double tap on a short suit")
  }

  /// Long press takes every card of that rank.
  func testLongPressTakesTheRank() {
    card("hand_9c").press(forDuration: 1.0)
    waitForSelected(2, "long press")
  }

  /// The sort icon shows the order a tap switches *to*, so tapping it flips the label.
  func testSortButtonFlipsTheOrder() {
    let sort = app.buttons["button_sort"]
    XCTAssertTrue(sort.waitForExistence(timeout: 20))
    XCTAssertEqual(sort.label, "Sort by suit")

    sort.tap()
    let flipped = XCTWaiter().wait(
      for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Sort by rank"),
                                      object: sort)], timeout: 10)
    XCTAssertEqual(flipped, .completed, "the sort icon never offered the other order")
    // The hand is re-ordered, not re-dealt.
    XCTAssertTrue(card("hand_3d").exists)
  }

  /// Leading the 3 of diamonds must empty the selection and shorten the hand.
  func testLeadingThreeOfDiamondsPlaysIt() {
    let three = card("hand_3d")
    three.tap()

    let lead = app.buttons["button_play"]
    XCTAssertTrue(lead.waitForExistence(timeout: 10))
    let enabled = XCTWaiter().wait(
      for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"),
                                      object: lead)], timeout: 10)
    XCTAssertEqual(enabled, .completed, "Lead never became enabled")
    lead.tap()

    let gone = XCTWaiter().wait(
      for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                      object: three)], timeout: 15)
    XCTAssertEqual(gone, .completed, "the 3 of diamonds was still in the hand after leading")
  }

  /// Tapping the title opens the menu, as it does on the phone, and New Game re-deals.
  func testTitleOpensTheMenuAndNewGameDeals() {
    let three = card("hand_3d")
    three.tap()
    waitForSelected(1, "tap before opening the menu")

    // ⚠️ `.firstMatch`: a watchOS toolbar item is published more than once, so the plain
    // query fails with "Multiple matching elements found" before it ever taps.
    let title = app.buttons["menu_button"].firstMatch
    XCTAssertTrue(title.waitForExistence(timeout: 20))
    title.tap()

    let newGame = app.descendants(matching: .any)["menu_new_game"]
    XCTAssertTrue(newGame.waitForExistence(timeout: 10), "the menu never came up")
    newGame.tap()

    // A new game closes the menu, clears the selection and deals again.
    let closed = XCTWaiter().wait(
      for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                      object: newGame)], timeout: 10)
    XCTAssertEqual(closed, .completed, "the menu stayed up after New Game")
    // ⚠️ `deal_label` is not asserted here: the watch publishes nothing for it, the text
    // lives in a toolbar item and no query of any element type finds it. The selection
    // clearing is what a new deal looks like from the outside.
    waitForSelected(0, "after New Game")
    // ⚠️ Not `hand_3d`: New Game deals again from the same seeded generator, so the next
    // hand is a different one. Thirteen cards is what a fresh deal looks like.
    let hand = app.descendants(matching: .any)
      .matching(NSPredicate(format: "identifier BEGINSWITH 'hand_'"))
    let dealt = XCTWaiter().wait(
      for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 13"),
                                      object: hand)], timeout: 10)
    XCTAssertEqual(dealt, .completed, "New Game did not deal a full hand")
  }

  /// The Preferences page has the Palm form's OK button, and it comes back to the table.
  func testPreferencesOKReturnsToTheTable() {
    // ⚠️ `swipeLeft()` does page a TabView even though it cannot scroll a ScrollView.
    app.swipeLeft()

    let autopass = app.descendants(matching: .any)["pref_autopass"]
    XCTAssertTrue(autopass.waitForExistence(timeout: 20), "the Preferences page never came up")

    let ok = app.buttons["pref_ok"]
    XCTAssertTrue(ok.waitForExistence(timeout: 10), "Preferences has no OK button")
    ok.tap()

    let prompt = app.staticTexts["prompt"]
    XCTAssertTrue(prompt.waitForExistence(timeout: 10), "OK did not come back to the table")
  }
}

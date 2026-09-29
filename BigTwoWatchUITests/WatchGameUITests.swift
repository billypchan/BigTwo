import XCTest

/// Seed 2 deals the human seat `3d 4c 6h 8h 8s 9c 9s Tc Jd Jc Qc Ad 2c`, so you lead
/// with the 3 of diamonds — the same fixed deal the phone suite uses.
final class WatchGameUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-AppleLanguages", "(en)", "-seed", "2"]
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
}

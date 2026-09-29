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

  /// A hand of 13 sits below the fold on a watch; a tap on an element that is not
  /// hittable silently lands somewhere else, so scroll to it first.
  private func scrolledTo(_ element: XCUIElement) -> XCUIElement {
    XCTAssertTrue(element.waitForExistence(timeout: 20))
    var swipes = 0
    while !element.isHittable && swipes < 8 {
      app.swipeUp()
      swipes += 1
    }
    XCTAssertTrue(element.isHittable, "\(element) never scrolled into reach")
    return element
  }

  /// The paywall is off, so the game is what opens.
  func testOpensOnTheGame() {
    let prompt = app.staticTexts["prompt"]
    XCTAssertTrue(prompt.waitForExistence(timeout: 20))
    XCTAssertEqual(prompt.label, "Your Lead")
  }

  func testTappingACardSelectsIt() {
    let three = scrolledTo(app.descendants(matching: .any)["hand_3d"])
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
    let three = scrolledTo(app.descendants(matching: .any)["hand_3d"])
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

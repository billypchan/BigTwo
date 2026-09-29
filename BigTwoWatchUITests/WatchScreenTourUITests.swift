import XCTest

/// Photographs the watch screens so a layout bug is seen rather than inferred — the
/// watch has no committed screenshot set, because `simctl status_bar override` answers
/// *Operation not supported* on watchOS and the clock would churn every capture.
final class WatchScreenTourUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-AppleLanguages", "(en)", "-seed", "2"]
    app.launch()
  }

  func testScreenTour() {
    let prompt = app.staticTexts["prompt"]
    XCTAssertTrue(prompt.waitForExistence(timeout: 20))
    capture("watch_screen_01_lead")

    // ⚠️ There is no shot of the whole hand, and there cannot be one: a watchOS UI test
    // cannot scroll. `swipeUp()` on the app *and* on the scroll view both leave the
    // screen byte-identical (checked by hashing the PNGs), and the Digital Crown has no
    // XCUITest API. `isHittable` is no help either — it is true for cards below the fold.
    // So whatever the player must see has to be on screen without scrolling.
    let three = app.descendants(matching: .any)["hand_3d"]
    XCTAssertTrue(three.waitForExistence(timeout: 20))

    three.tap()
    let selected = XCTWaiter().wait(
      for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "selected == true"),
                                      object: three)], timeout: 10)
    XCTAssertEqual(selected, .completed, "the 3 of diamonds never became selected")
    capture("watch_screen_02_selected")

    let lead = app.buttons["button_play"]
    XCTAssertTrue(lead.waitForExistence(timeout: 10))
    lead.tap()
    let gone = XCTWaiter().wait(
      for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                      object: three)], timeout: 15)
    XCTAssertEqual(gone, .completed, "the 3 of diamonds was still in the hand after leading")
    capture("watch_screen_03_trick")
  }

  private func capture(_ name: String) {
    let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    shot.name = name
    shot.lifetime = .keepAlways
    add(shot)
  }
}

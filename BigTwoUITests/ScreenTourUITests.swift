import XCTest

/// App Store / review screenshots: `ios_screen_NN_<name>`.
final class ScreenTourUITests: XCTestCase {

  override func setUp() {
    continueAfterFailure = false
  }

  func testScreenTour() {
    let app = XCUIApplication.bigTwo()
    app.launch()
    XCTAssertTrue(app.element("hand_3d").waitForExistence(timeout: 10))
    capture(app, "ios_screen_01_lead")

    // A tap goes to whatever is really on top — if a system alert covered us, this fails.
    app.element("hand_3d").tap()
    waitForCount(app.selectedHandCards, 1)
    XCTAssertTrue(app.element("hand_3d").isSelected)
    capture(app, "ios_screen_02_selected")

    app.buttons["button_play"].tap()
    waitForCount(app.handCards, 12)
    let yourTurn = NSPredicate(format: "label IN %@", ["Your Play", "Your Lead"])
    XCTAssertTrue(app.prompt.wait(for: yourTurn, timeout: 20))
    capture(app, "ios_screen_03_trick")

    app.buttons["menu_button"].tap()
    XCTAssertTrue(app.switches["pref_hongKong"].waitForExistence(timeout: 5))
    capture(app, "ios_screen_04_menu")
    app.buttons["menu_done"].tap()

    app.terminate()
    let auto = XCUIApplication.bigTwo(["-autoplay", "YES"])
    auto.launch()
    XCTAssertTrue(auto.element("score_sheet").waitForExistence(timeout: 120))
    waitUntilSettled(auto.element("score_sheet"))
    capture(auto, "ios_screen_05_score")
  }
}

private extension XCUIElement {
  func wait(for predicate: NSPredicate, timeout: TimeInterval) -> Bool {
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
    return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
  }
}

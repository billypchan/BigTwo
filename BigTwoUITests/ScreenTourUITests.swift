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
    if !app.buttons["menu_preferences"].waitForExistence(timeout: 3) {
      app.buttons["menu_button"].tap()
    }
    XCTAssertTrue(app.buttons["menu_preferences"].waitForExistence(timeout: 5))
    capture(app, "ios_screen_04_menu")
    app.buttons["menu_preferences"].tap()
    XCTAssertTrue(app.buttons["pref_ok"].waitForExistence(timeout: 5))
    capture(app, "ios_screen_05_preferences")
    app.buttons["pref_ok"].tap()

    app.buttons["menu_button"].tap()
    if !app.buttons["menu_names"].waitForExistence(timeout: 3) {
      app.buttons["menu_button"].tap()
    }
    XCTAssertTrue(app.buttons["menu_names"].waitForExistence(timeout: 5))
    app.buttons["menu_names"].tap()
    XCTAssertTrue(app.buttons["names_ok"].waitForExistence(timeout: 5))
    waitUntilSettled(app.buttons["names_ok"])
    capture(app, "ios_screen_06_names")
    app.buttons["names_ok"].tap()
    XCTAssertTrue(app.buttons["names_ok"].waitForNonExistence(timeout: 5))

    app.buttons["menu_button"].tap()
    if !app.buttons["menu_about"].waitForExistence(timeout: 3) {
      app.buttons["menu_button"].tap()
    }
    XCTAssertTrue(app.buttons["menu_about"].waitForExistence(timeout: 5))
    app.buttons["menu_about"].tap()
    XCTAssertTrue(app.buttons["about_ok"].waitForExistence(timeout: 5))
    waitUntilSettled(app.buttons["about_ok"])
    capture(app, "ios_screen_07_about")

    app.terminate()
    let auto = XCUIApplication.bigTwo(["-autoplay", "YES"])
    auto.launch()
    XCTAssertTrue(auto.element("score_sheet").waitForExistence(timeout: 120))
    waitUntilSettled(auto.element("score_sheet"))
    capture(auto, "ios_screen_08_score")

    auto.terminate()
    let final = XCUIApplication.bigTwo(["-autoplay", "YES", "-dealsPerGame", "1"])
    final.launch()
    XCTAssertTrue(final.element("score_sheet").waitForExistence(timeout: 120))
    waitUntilSettled(final.element("score_sheet"))
    XCTAssertEqual(final.buttons["score_ok"].label, "New Game")
    capture(final, "ios_screen_09_final_score")
  }
}

private extension XCUIElement {
  func wait(for predicate: NSPredicate, timeout: TimeInterval) -> Bool {
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
    return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
  }
}

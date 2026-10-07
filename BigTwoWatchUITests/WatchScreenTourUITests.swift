import XCTest

/// Photographs the watch screens so a layout bug is seen rather than inferred — the
/// watch has no committed screenshot set, because `simctl status_bar override` answers
/// *Operation not supported* on watchOS and the clock would churn every capture.
final class WatchScreenTourUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["UITestMode", "-AppleLanguages", "(en)", "-seed", "2", "-unlocked", "YES"]
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

    // ⚠️ `descendants` + `.firstMatch`: what element type the title is published as has
    // changed under us once already — see `WatchGameUITests`.
    let title = app.descendants(matching: .any)["menu_button"].firstMatch
    XCTAssertTrue(title.waitForExistence(timeout: 10))
    title.tap()
    // ⚠️ `.firstMatch`: the menu hangs off a toolbar item, and a watchOS
    // toolbar publishes its content more than once.
    let newGame = app.descendants(matching: .any)["menu_new_game"].firstMatch
    XCTAssertTrue(newGame.waitForExistence(timeout: 10), "the menu never came up")
    capture("watch_screen_04_menu")
    // Tapping outside closes it, which is also the only way back to the table.
    app.descendants(matching: .any)["prompt"].firstMatch.tap()
    let closed = XCTWaiter().wait(
      for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                      object: newGame)], timeout: 10)
    XCTAssertEqual(closed, .completed, "the menu would not close")

    // Paging is a different mechanism from scrolling a ScrollView, which a watchOS UI
    // test cannot drive — a swipe between tabs does work.
    app.swipeLeft()
    let preferences = app.descendants(matching: .any)["pref_hongKong"]
    XCTAssertTrue(preferences.waitForExistence(timeout: 10), "the Preferences page never came up")
    capture("watch_screen_05_preferences")

    app.swipeLeft()
    let about = app.descendants(matching: .any)["about_version"]
    XCTAssertTrue(about.waitForExistence(timeout: 10), "the About page never came up")
    capture("watch_screen_06_about")
  }

  private func capture(_ name: String) {
    let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    shot.name = name
    shot.lifetime = .keepAlways
    add(shot)
  }
}

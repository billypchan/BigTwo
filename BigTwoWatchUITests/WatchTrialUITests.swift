import XCTest

/// The paywall is the first screen. One finished game (here, one deal) spends the
/// trial; `-trialUsed YES` is that same screen without waiting for the bots.
final class WatchTrialUITests: XCTestCase {
  private func launch(_ extra: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["UITestMode", "-AppleLanguages", "(en)"] + extra
    app.launch()
    return app
  }

  private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
    app.descendants(matching: .any)[id].firstMatch
  }

  /// `-unlocked` is absent on purpose. Try is on the paywall, next to Buy.
  func testPaywallOffersOneGame() {
    let app = launch()
    let tryOne = element(app, "store_try")
    XCTAssertTrue(tryOne.waitForExistence(timeout: 20), "the paywall never offered the free game")
    XCTAssertTrue(element(app, "store_buy").exists)
    XCTAssertTrue(element(app, "store_restore").exists)
  }

  /// One deal is the whole game (`-dealsPerGame 1`), and the bots play it. Dismissing
  /// Final Score is what brings the paywall back, with no second Try.
  func testOneGameThenThePurchase() {
    let app = launch(["-seed", "2", "-autoplay", "YES", "-dealsPerGame", "1"])
    let tryOne = element(app, "store_try")
    XCTAssertTrue(tryOne.waitForExistence(timeout: 20))
    tryOne.tap()

    let score = element(app, "score_ok")
    XCTAssertTrue(score.waitForExistence(timeout: 90), "the free game never finished")
    score.tap()

    let buy = element(app, "store_buy")
    XCTAssertTrue(buy.waitForExistence(timeout: 15), "the paywall did not come back")
    XCTAssertFalse(element(app, "store_try").waitForExistence(timeout: 2),
                   "a second free game was offered")
  }

  func testSpentTrialHasNoTry() {
    let app = launch(["-trialUsed", "YES"])
    XCTAssertTrue(element(app, "store_buy").waitForExistence(timeout: 20))
    XCTAssertFalse(element(app, "store_try").waitForExistence(timeout: 2))
  }
}

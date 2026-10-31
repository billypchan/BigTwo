import XCTest

/// A one-deal autoplay lands on Final Score. `-offerExpert YES` asks even though
/// autoplay has no human seat to win.
final class WatchExpertOfferUITests: XCTestCase {
  func testExpertOfferSetsTheBots() {
    let app = XCUIApplication()
    app.launchArguments = ["UITestMode", "-AppleLanguages", "(en)", "-seed", "2",
                           "-unlocked", "YES", "-autoplay", "YES", "-dealsPerGame", "1",
                           "-offerExpert", "YES"]
    app.launch()

    let score = app.descendants(matching: .any)["score_ok"].firstMatch
    XCTAssertTrue(score.waitForExistence(timeout: 120), "the bots never finished the game")
    XCTAssertEqual(score.label, "New Game", "this was not Final Score")
    score.tap()

    let yes = app.descendants(matching: .any)["expert_yes"].firstMatch
    XCTAssertTrue(yes.waitForExistence(timeout: 10), "Final Score did not ask about Expert")
    yes.tap()
    XCTAssertTrue(yes.waitForNonExistence(timeout: 15))

    // Preferences is the next page. The Bots row is below the fold; `isSelected`
    // is still readable, and a watchOS test cannot scroll to tap it.
    app.swipeLeft()
    let expert = app.descendants(matching: .any)["pref_bots_Expert"].firstMatch
    XCTAssertTrue(expert.waitForExistence(timeout: 20), "the Preferences page never came up")
    let selected = NSPredicate(format: "selected == true")
    let outcome = XCTWaiter().wait(
      for: [XCTNSPredicateExpectation(predicate: selected, object: expert)], timeout: 10)
    XCTAssertEqual(outcome, .completed, "Expert was not the bot level after the offer")
  }
}

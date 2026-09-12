import XCTest

/// Seed 2 deals your seat `3d 4c 6h 8h 8s 9c 9s Tc Jd Jc Qc Ad 2c`, so you lead.
let humanLeadsSeed = "2"

extension XCUIApplication {
  static func bigTwo(seed: String = humanLeadsSeed, _ extra: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["UITestMode", "-seed", seed] + extra
    return app
  }

  func element(_ id: String) -> XCUIElement {
    descendants(matching: .any)[id]
  }

  var handCards: XCUIElementQuery {
    descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'hand_'"))
  }

  var selectedHandCards: XCUIElementQuery {
    handCards.matching(NSPredicate(format: "selected == true"))
  }

  var prompt: XCUIElement { staticTexts["prompt"] }
}

extension XCTestCase {
  func waitFor(_ element: XCUIElement, label: String, timeout: TimeInterval = 10,
               file: StaticString = #filePath, line: UInt = #line) {
    let predicate = NSPredicate(format: "label == %@", label)
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let outcome = XCTWaiter().wait(for: [expectation], timeout: timeout)
    XCTAssertEqual(outcome, .completed, "'\(element.label)' never became '\(label)'",
                   file: file, line: line)
  }

  func waitForCount(_ query: XCUIElementQuery, _ count: Int, timeout: TimeInterval = 10,
                    file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(timeout)
    while query.count != count && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(query.count, count, file: file, line: line)
  }

  /// ⚠️ `exists` is true the moment a sheet starts sliding in. A screenshot taken then
  /// showed the score sheet's OK half below the screen — a layout bug that wasn't there.
  func waitUntilSettled(_ element: XCUIElement, timeout: TimeInterval = 5) {
    let deadline = Date().addingTimeInterval(timeout)
    var last = element.frame
    while Date() < deadline {
      usleep(250_000)
      let now = element.frame
      if now == last { return }
      last = now
    }
  }

  func capture(_ app: XCUIApplication, _ name: String) {
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = name
    shot.lifetime = .keepAlways
    add(shot)
  }
}

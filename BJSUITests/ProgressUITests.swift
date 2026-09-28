import XCTest

@MainActor
final class ProgressUITests: XCTestCase {

    private func waitForValue(_ element: XCUIElement, _ value: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "value == %@", value)
        return XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)],
                              timeout: timeout) == .completed
    }

    private func scrollToHittable(_ element: XCUIElement, in app: XCUIApplication) {
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
    }

    func testFixtureHeadlinesHistoryAndWhy() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-progressFixture", "-startTab", "progress"]
        app.launch()

        // 7 days: 22 of 33 strategy decisions.
        let strategy = app.descendants(matching: .any)["progress.chip.strategy"]
        XCTAssertTrue(strategy.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForValue(strategy, "67%"))
        XCTAssertTrue(app.descendants(matching: .any)["progress.chart"].exists)

        // All time adds the day-9 session: 24 of 35.
        app.buttons["All time"].tap()
        XCTAssertTrue(waitForValue(strategy, "69%"))

        // The newest session is a Strategy Test with mistakes.
        let row = app.buttons.matching(identifier: "progress.history.row").firstMatch
        scrollToHittable(row, in: app)
        row.tap()
        let mistake = app.buttons.matching(identifier: "progress.mistake").firstMatch
        XCTAssertTrue(mistake.waitForExistence(timeout: 5))
        mistake.tap()

        let close = app.buttons["strategy.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(mistake.waitForExistence(timeout: 5))
    }

    func testEmptyStateLinksToTrain() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-startTab", "progress"]
        app.launch()

        let start = app.buttons["Start training"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        XCTAssertTrue(app.buttons["hub.tile.strategy"].waitForExistence(timeout: 5))
    }
}

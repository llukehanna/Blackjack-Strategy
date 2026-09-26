import XCTest

@MainActor
final class StrategyUITests: XCTestCase {

    func testFiveHandSessionReachesSummary() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-strategyLength", "5", "-seed", "1"]
        app.launch()

        let tile = app.buttons["hub.tile.strategy"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.tap()

        let start = app.buttons["strategy.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        for hand in 1...5 {
            let stand = app.buttons["STAND"]
            XCTAssertTrue(stand.waitForExistence(timeout: 5), "hand \(hand): dock")
            stand.tap()
            let next = app.buttons["NEXT"]
            XCTAssertTrue(next.waitForExistence(timeout: 5), "hand \(hand): feedback before the next deal")
            next.tap()
            let deal = app.buttons["strategy.deal"]
            XCTAssertTrue(deal.waitForExistence(timeout: 5), "hand \(hand): outcome")
            deal.tap()
        }

        XCTAssertTrue(app.staticTexts["strategy.summary"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["hub.continue"].waitForExistence(timeout: 5))
    }
}

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

        let hubContinue = app.buttons["hub.continue"]
        XCTAssertTrue(hubContinue.waitForExistence(timeout: 5))
        hubContinue.tap()

        // Continue should skip setup and go straight to the trainer, awaiting the first decision.
        XCTAssertTrue(app.buttons["STAND"].waitForExistence(timeout: 5), "Continue should reopen the trainer directly")

        app.buttons["strategy.close"].tap()
        // No decision has been made in this fresh session yet, so the leave dialog shouldn't
        // appear; but handle it either way to keep the test deterministic if that changes.
        let keepPlaying = app.buttons["Keep playing"]
        if keepPlaying.waitForExistence(timeout: 2) {
            app.buttons["Discard"].tap()
        }
        XCTAssertTrue(app.buttons["hub.continue"].waitForExistence(timeout: 5))
    }
}

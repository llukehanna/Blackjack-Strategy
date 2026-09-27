import XCTest

@MainActor
final class CountingUITests: XCTestCase {

    func testTenCardRunningCountDrillReachesSummary() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-seed", "1", "-countPace", "0.3"]
        app.launch()

        let tile = app.buttons["hub.tile.counting"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.tap()

        let running = app.buttons["counting.menu.running"]
        XCTAssertTrue(running.waitForExistence(timeout: 5))
        running.tap()

        let ten = app.buttons["10"]
        XCTAssertTrue(ten.waitForExistence(timeout: 5))
        ten.tap()
        app.buttons["counting.start"].tap()

        // 10 cards at 0.3 s each, then the end-of-drill checkpoint.
        let enter = app.buttons["Enter"]
        XCTAssertTrue(enter.waitForExistence(timeout: 15), "keypad at the checkpoint")
        app.buttons["0"].tap()
        enter.tap()

        let next = app.buttons["NEXT"]
        XCTAssertTrue(next.waitForExistence(timeout: 5), "feedback after the answer")
        next.tap()

        XCTAssertTrue(app.staticTexts["counting.summary"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        let hubContinue = app.buttons["hub.continue"]
        XCTAssertTrue(hubContinue.waitForExistence(timeout: 5))
        hubContinue.tap()

        // Continue reopens the drill directly: no menu, no setup.
        XCTAssertTrue(app.staticTexts["counting.progress"].waitForExistence(timeout: 5),
                      "Continue should reopen the running count drill")
        XCTAssertFalse(app.buttons["counting.start"].exists)

        app.buttons["counting.close"].tap()
        // No check has been answered yet in this drill, so it closes without the leave dialog; handle
        // the dialog anyway so the test stays deterministic.
        let discard = app.buttons["Discard"]
        if discard.waitForExistence(timeout: 2) { discard.tap() }
        XCTAssertTrue(app.buttons["hub.continue"].waitForExistence(timeout: 5))
    }
}

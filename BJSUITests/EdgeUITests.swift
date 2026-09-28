import XCTest

@MainActor
final class EdgeUITests: XCTestCase {

    func testPresetChangeAndApplyUpdatesHub() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let header = app.buttons["hub.rulesSummary"]
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        XCTAssertEqual(header.value as? String, "6D · S17 · DAS · 3:2")

        app.buttons["hub.tile.edge"].tap()

        // Opens on the active rules (6D S17 DAS 3:2 = WoO 0.42622%), with nothing to apply.
        let number = app.staticTexts["edge.number"]
        XCTAssertTrue(number.waitForExistence(timeout: 5))
        XCTAssertEqual(number.label, "0.43%")
        XCTAssertEqual(app.staticTexts["edge.rating"].label, "Good")
        XCTAssertTrue(app.staticTexts["edge.applied"].exists)
        XCTAssertFalse(app.staticTexts["edge.comparison"].exists)

        // Single Deck 6:5 = 1D H17 NDAS 6:5 = WoO 1.69824%.
        let preset = app.buttons["settings.preset"]
        XCTAssertTrue(preset.waitForExistence(timeout: 5))
        preset.tap()
        let singleDeck = app.buttons["Single Deck 6:5"]
        XCTAssertTrue(singleDeck.waitForExistence(timeout: 5))
        singleDeck.tap()

        XCTAssertEqual(number.label, "1.70%")
        XCTAssertEqual(app.staticTexts["edge.rating"].label, "Poor")
        XCTAssertTrue(app.staticTexts["edge.comparison"].exists)

        let apply = app.buttons["edge.apply"]
        XCTAssertTrue(apply.waitForExistence(timeout: 5))
        apply.tap()
        let confirm = app.buttons["Use these rules"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        XCTAssertTrue(app.staticTexts["edge.applied"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["edge.comparison"].exists)

        app.buttons["edge.close"].tap()
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertEqual(header.value as? String, "1D · H17 · 6:5")
    }
}

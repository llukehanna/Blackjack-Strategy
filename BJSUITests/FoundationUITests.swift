import XCTest

@MainActor
final class FoundationUITests: XCTestCase {

    func testPresetChangeUpdatesHubHeader() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let header = app.buttons["hub.rulesSummary"]
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        XCTAssertEqual(header.value as? String, "6D · S17 · DAS · 3:2")

        header.tap()
        let preset = app.buttons["settings.preset"]
        XCTAssertTrue(preset.waitForExistence(timeout: 5))
        preset.tap()
        let downtown = app.buttons["Downtown Vegas"]
        XCTAssertTrue(downtown.waitForExistence(timeout: 5))
        downtown.tap()

        app.tabBars.buttons["Train"].tap()
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertEqual(header.value as? String, "2D · H17 · DAS · LS · 3:2")
    }
}

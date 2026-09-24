import XCTest

/// Spec §7 design check: walks the hub, a placeholder route, Settings (incl. the reset
/// confirmation) and every component-gallery page, attaching a screenshot of each.
/// CI runs this on iPhone 16 and iPhone SE (3rd generation) and uploads the PNGs.
final class DesignScreenshotTests: XCTestCase {

    /// Must match `GalleryPage` raw values in `BJS/Design/Gallery/ComponentGallery.swift`.
    private static let galleryPages = [
        "colors", "type", "cards", "dock", "feedback",
        "buttons", "tiles", "settingsRows", "keypad", "keypadDecimal", "countdown",
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchApp(galleryPage: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["BJS_UI_TESTING"] = "1"
        if let galleryPage {
            app.launchEnvironment["BJS_GALLERY_PAGE"] = galleryPage
        }
        app.launch()
        return app
    }

    @MainActor
    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testHubPlaceholderAndSettings() throws {
        let app = launchApp()

        let rulesSummary = app.buttons["hub.rulesSummary"]
        XCTAssertTrue(rulesSummary.waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["hub.tile.strategy"].exists)
        XCTAssertTrue(app.buttons["hub.tile.edge"].exists)
        snapshot("01-hub")

        app.buttons["hub.tile.strategy"].tap()
        XCTAssertTrue(app.staticTexts["placeholder.title"].waitForExistence(timeout: 5))
        snapshot("02-placeholder-strategy")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(rulesSummary.waitForExistence(timeout: 5))

        // The rules summary switches to the Settings tab.
        rulesSummary.tap()
        XCTAssertTrue(app.staticTexts["settings.title"].waitForExistence(timeout: 5))
        snapshot("03-settings-top")

        app.swipeUp()
        snapshot("04-settings-middle")
        app.swipeUp()
        snapshot("05-settings-bottom")

        let reset = app.buttons["settings.resetProgress"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5))
        reset.tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        snapshot("06-reset-confirmation")
        alert.buttons["Cancel"].tap()
    }

    @MainActor
    func testComponentGalleryPages() throws {
        for (index, page) in Self.galleryPages.enumerated() {
            let app = launchApp(galleryPage: page)
            XCTAssertTrue(app.staticTexts["gallery.title"].waitForExistence(timeout: 15), "gallery page \(page)")
            snapshot(String(format: "%02d-gallery-%@", 10 + index, page))
            app.terminate()
        }
    }
}

import XCTest
import UIKit

/// Spec §7 UI test: launch → hub → 5-hand Strategy session → summary visible. The walk also
/// attaches the Strategy design-check screenshots (setup, trainer with hint, FeedbackCard,
/// WHY sheet, outcome, summary, Continue, Speed countdown and timeout, leave prompt, mistake WHY).
///
/// Hands come from a fixed seed (`BJS_STRATEGY_SEED`), but the test never assumes which
/// hands: it plays by reading the dock — the brass-ringed ("Suggested") button in Learn
/// mode, otherwise the first enabled one.
final class StrategySessionUITests: XCTestCase {

    private static let seed = "20260924"
    private static let dockActions = ["stand", "hit", "double", "split", "surrender"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["BJS_UI_TESTING"] = "1"
        app.launchEnvironment["BJS_STRATEGY_SEED"] = Self.seed
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

    /// The first of `elements` that exists within `timeout` (polling every 0.1 s).
    @MainActor
    private func firstExisting(_ elements: [XCUIElement], timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if let found = elements.first(where: { $0.exists }) { return found }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return nil
    }

    @MainActor
    private func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element)
        wait(for: [gone], timeout: timeout)
    }

    /// Learn mode's ringed button if there is one, else the first enabled dock button.
    @MainActor
    private func dockChoice(in app: XCUIApplication) -> XCUIElement? {
        let enabled = Self.dockActions
            .map { app.buttons["action.\($0)"] }
            .filter { $0.exists && $0.isEnabled }
        return enabled.first { ($0.value as? String) == "Suggested" } ?? enabled.first
    }

    @MainActor
    private func openStrategySetup(_ app: XCUIApplication) {
        let tile = app.buttons["hub.tile.strategy"]
        XCTAssertTrue(tile.waitForExistence(timeout: 15))
        tile.tap()
        XCTAssertTrue(app.staticTexts["strategy.setup.title"].waitForExistence(timeout: 5))
    }

    /// Plays until `hands` hands have reached their outcome; returns with that outcome showing.
    /// With `snapshots`, attaches the decision, feedback, WHY and outcome screenshots once each.
    @MainActor
    private func play(hands: Int, in app: XCUIApplication, snapshots: Bool) {
        let next = app.buttons["feedback.next"]
        let nextHand = app.buttons["trainer.nextHand"]
        let stand = app.buttons["action.stand"]
        var completed = 0
        var tookDecision = !snapshots
        var tookFeedback = !snapshots
        var printedDiagnostic = false

        for _ in 0..<150 {
            guard let element = firstExisting([next, nextHand, stand], timeout: 10) else {
                XCTFail("Neither feedback, an outcome nor the dock appeared")
                return
            }
            switch element.identifier {
            case "feedback.next":
                // The top bar stays on screen, and usable, while feedback shows.
                if !printedDiagnostic {
                    printedDiagnostic = true
                    logScreen("test-feedback")
                }
                XCTAssertTrue(app.buttons["trainer.close"].isHittable, "✕ is hittable during feedback")
                if !tookFeedback {
                    tookFeedback = true
                    snapshot("32-strategy-feedback")
                    app.buttons["feedback.why"].tap()
                    XCTAssertTrue(app.staticTexts["why.title"].waitForExistence(timeout: 5))
                    snapshot("33-strategy-why")
                    app.buttons["why.done"].tap()
                    waitUntilGone(app.staticTexts["why.title"])
                }
                next.tap()
                waitUntilGone(next)
            case "trainer.nextHand":
                completed += 1
                if completed == 1 && snapshots { snapshot("34-strategy-outcome") }
                if completed == hands { return }
                nextHand.tap()
                waitUntilGone(nextHand)
            default:
                // The dock: while feedback is still animating in, every button is disabled.
                guard let choice = dockChoice(in: app) else {
                    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
                    continue
                }
                if !tookDecision {
                    tookDecision = true
                    snapshot("31-strategy-decision")
                }
                choice.tap()
                XCTAssertTrue(next.waitForExistence(timeout: 5), "every decision shows feedback")
            }
        }
        XCTFail("Did not finish \(hands) hands in 150 steps")
    }

    // MARK: - Tests

    /// Spec §7: launch → hub → 5-hand Strategy session → summary visible; then Continue.
    @MainActor
    func testFiveHandStrategySession() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["hub.tile.strategy"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["hub.continue"].exists, "Continue is hidden on first launch")

        openStrategySetup(app)
        app.buttons["Endless"].tap()
        snapshot("30-strategy-setup")
        app.buttons["strategy.start"].tap()
        XCTAssertTrue(app.staticTexts["trainer.progress"].waitForExistence(timeout: 10))

        play(hands: 5, in: app, snapshots: true)

        app.buttons["trainer.end"].tap()
        XCTAssertTrue(app.staticTexts["summary.title"].waitForExistence(timeout: 5))
        let hands = app.descendants(matching: .any)["summary.hands"]
        XCTAssertTrue(hands.exists)
        XCTAssertTrue(hands.label.contains("5"), "summary shows 5 hands: \(hands.label)")
        snapshot("35-strategy-summary")

        // Done returns to setup; the hub now offers Continue with the same setup.
        app.buttons["summary.done"].tap()
        XCTAssertTrue(app.staticTexts["strategy.setup.title"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let continueButton = app.buttons["hub.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertTrue(continueButton.label.contains("Strategy"))
        snapshot("36-hub-continue")

        // Continue starts the trainer straight away; closing before any decision just closes.
        continueButton.tap()
        XCTAssertTrue(app.staticTexts["trainer.progress"].waitForExistence(timeout: 10))
        app.buttons["trainer.close"].tap()
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
    }

    /// Speed timeout, the leave prompt with Save partial, and a mistake's WHY from the summary.
    @MainActor
    func testSpeedTimeoutSavePartialAndMistakeWhy() throws {
        let app = launchApp()
        openStrategySetup(app)
        app.buttons["Speed"].tap()
        app.buttons["strategy.start"].tap()
        XCTAssertTrue(app.staticTexts["trainer.progress"].waitForExistence(timeout: 10))
        snapshot("37-strategy-speed")

        // Do nothing: the default 3 s countdown runs out and records a timeout.
        let next = app.buttons["feedback.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        let timeUp = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Time's up")).firstMatch
        XCTAssertTrue(timeUp.exists)
        snapshot("38-strategy-timeout")

        // Leaving with a graded decision asks first. The ✕ must be on screen with the card up.
        let close = app.buttons["trainer.close"]
        // Diagnostic (temporary): dump the element tree with frames so CI logs show the layout.
        logScreen("speed-feedback")
        XCTAssertTrue(close.isHittable, "✕ is hittable while the timeout FeedbackCard shows")
        close.tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        snapshot("39-strategy-leave")
        alert.buttons["Save partial"].tap()

        XCTAssertTrue(app.staticTexts["summary.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["summary.meanTime"].exists)
        snapshot("40-strategy-summary-speed")

        let mistake = app.buttons["summary.mistake.1"]
        XCTAssertTrue(mistake.waitForExistence(timeout: 5))
        mistake.tap()
        XCTAssertTrue(app.staticTexts["why.title"].waitForExistence(timeout: 5))
        snapshot("41-strategy-why-mistake")
        app.buttons["why.done"].tap()
        waitUntilGone(app.staticTexts["why.title"])
        app.buttons["summary.done"].tap()
        XCTAssertTrue(app.staticTexts["strategy.setup.title"].waitForExistence(timeout: 5))
    }

    /// Diagnostic (temporary): prints a small JPEG of the screen as base64 so CI logs carry it.
    @MainActor
    private func logScreen(_ tag: String) {
        let image = XCUIScreen.main.screenshot().image
        let width: CGFloat = 240
        let size = CGSize(width: width, height: image.size.height * width / image.size.width)
        let renderer = UIGraphicsImageRenderer(size: size)
        let small = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        if let data = small.jpegData(compressionQuality: 0.6) {
            print("BJS-SHOT \(tag) \(data.base64EncodedString())")
        }
    }
}

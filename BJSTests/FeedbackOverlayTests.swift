import Testing
@testable import BJS

struct FeedbackOverlayTests {
    @Test func headingStringsExact() {
        #expect(FeedbackOverlayView.headingCorrect == "Well played!")
        #expect(FeedbackOverlayView.headingIncorrect == "Incorrect!")
    }

    @Test func buttonLabelsExact() {
        #expect(FeedbackOverlayView.dealLabel == "DEAL")
        #expect(FeedbackOverlayView.whyLabel == "WHY")
    }

    @Test func tappingWhyInvokesClosure() {
        final class Probe: @unchecked Sendable {
            var fired = false
        }
        let probe = Probe()
        let view = FeedbackOverlayView(
            isCorrect: false,
            userActionLabel: "HIT",
            correctActionLabel: "STAND",
            onDeal: {},
            onWhy: { probe.fired = true }
        )
        // Invoke the closure directly — exercises the same path the
        // SwiftUI button calls when tapped.
        view.onWhy()
        #expect(probe.fired == true)
    }

    @Test func incorrectBodyTemplateMatchesSpec() {
        let body = FeedbackOverlayView.incorrectBody(userAction: "HIT", correctAction: "DOUBLE")
        #expect(body == "In this situation HIT isn't the right move. You should have DOUBLE.")
    }

    @Test func correctBodyTemplateMatchesSpec() {
        let body = FeedbackOverlayView.correctBody(action: "STAND")
        #expect(body == "STAND was the right move.")
    }
}

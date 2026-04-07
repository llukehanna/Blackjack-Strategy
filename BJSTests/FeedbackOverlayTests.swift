import Testing
@testable import BJS

struct FeedbackOverlayTests {
    @Test func headingStringsExact() {
        #expect(FeedbackOverlayView.headingCorrect == "Well played!")
        #expect(FeedbackOverlayView.headingIncorrect == "Incorrect!")
    }

    @Test func buttonLabelsExact() {
        #expect(FeedbackOverlayView.dealLabel == "DEAL")
        #expect(FeedbackOverlayView.understandWhyLabel == "UNDERSTAND WHY")
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

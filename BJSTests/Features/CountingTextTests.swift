import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct CountingTextTests {

    @Test("Signed integers use a true minus sign")
    func signedInt() {
        #expect(TrainingText.signed(3) == "+3")
        #expect(TrainingText.signed(-2) == "\u{2212}2")
        #expect(TrainingText.signed(0) == "0")
    }

    @Test("Signed doubles round to one decimal and drop .0")
    func signedDouble() {
        #expect(TrainingText.signed(7.0 / 3) == "+2.3")
        #expect(TrainingText.signed(-3.0) == "\u{2212}3")
        #expect(TrainingText.signed(0.5) == "+0.5")
        #expect(TrainingText.signed(0.04) == "0")
        #expect(TrainingText.signed(-2.5) == "\u{2212}2.5")
    }

    @Test("Decks keep quarters")
    func decks() {
        #expect(CountingText.decks(0.25) == "0.25")
        #expect(CountingText.decks(2.5) == "2.5")
        #expect(CountingText.decks(3) == "3")
        #expect(CountingText.decks(1.75) == "1.75")
        #expect(CountingText.decksLeft(1) == "1 deck left")
        #expect(CountingText.decksLeft(0.75) == "0.75 decks left")
    }

    @Test("Durations and error")
    func numbers() {
        #expect(CountingText.pace(0.3) == "0.3 s")
        #expect(CountingText.seconds(1.0 / 3) == "0.33 s")
        #expect(TrainingText.meanError(nil) == "—")
        #expect(TrainingText.meanError(0.72) == "0.7")
    }

    @Test("RC feedback: correct, and wrong with the user's answer")
    func runningFeedback() {
        #expect(CountingText.runningFeedback(expected: 3, answered: 3)
                == .init(headline: "Correct", reason: "The running count is +3."))
        #expect(CountingText.runningFeedback(expected: 3, answered: 2)
                == .init(headline: "Running count is +3", reason: "You said +2."))
    }

    @Test("TC feedback shows the keypad answer and the working")
    func trueFeedback() {
        let q = TrueCountQuestion(runningCount: 7, decksRemaining: 3)
        #expect(CountingText.trueFeedback(question: q, convention: .exact, answered: 3, isCorrect: false)
                == .init(headline: "True count is +2.5", reason: "RC +7 ÷ 3 decks left = +2.3. You said +3."))
        #expect(CountingText.trueFeedback(question: q, convention: .exact, answered: 2.5, isCorrect: true)
                == .init(headline: "Correct", reason: "RC +7 ÷ 3 decks left = +2.3."))
        let n = TrueCountQuestion(runningCount: -7, decksRemaining: 3)
        #expect(CountingText.trueFeedback(question: n, convention: .floor, answered: -2, isCorrect: false).headline
                == "True count is \u{2212}3")
    }

    @Test("Card value feedback names the rank and its value")
    func cardValue() {
        #expect(CountingText.cardValueFeedback(rank: .five).headline == "Five is +1")
        #expect(CountingText.cardValueFeedback(rank: .seven).headline == "Seven is 0")
        #expect(CountingText.cardValueFeedback(rank: .king).headline == "King is \u{2212}1")
        #expect(CountingText.cardValueFeedback(rank: .king).reason
                == "2 to 6 are +1, 7 to 9 are 0, and 10 to Ace are \u{2212}1.")
    }

    @Test("Convention rules name each convention")
    func rules() {
        #expect(TrainingText.conventionRule(.exact).hasPrefix("Exact:"))
        #expect(TrainingText.conventionRule(.floor).hasPrefix("Floor:"))
        #expect(TrainingText.conventionRule(.truncate).hasPrefix("Truncate:"))
    }

    @Test("Summary rows")
    func rows() {
        let t = Date(timeIntervalSince1970: 0)
        let right = GradedCount(id: 0, kind: .runningCount, expected: 3, answered: 3, isCorrect: true,
                                responseMs: 900, cardsSeen: 12, checkedAt: t)
        let wrong = GradedCount(id: 1, kind: .runningCount, expected: -1, answered: 2, isCorrect: false,
                                responseMs: 900, cardsSeen: 26, checkedAt: t)
        #expect(CountingText.runningRow(right) == CountSummaryRow(id: 0, label: "After card 12", value: "+3"))
        #expect(CountingText.runningRow(wrong)
                == CountSummaryRow(id: 1, label: "After card 26", value: "\u{2212}1 · you said +2"))

        let q = TrueCountQuestion(runningCount: 7, decksRemaining: 2.5)
        let tc = GradedCount(id: 0, kind: .trueCount, expected: 2.8, answered: 2, isCorrect: false,
                             responseMs: 900, cardsSeen: 182, checkedAt: t)
        #expect(CountingText.trueRow(tc, question: q, convention: .exact)
                == CountSummaryRow(id: 0, label: "+7 · 2.5 decks left", value: "+3 · you said +2"))
    }

    @Test("A graded count maps to its draft; response time never goes negative")
    func gradedCount() {
        let t = Date(timeIntervalSince1970: 100)
        let g = GradedCount(id: 0, kind: .trueCount, expected: 2, answered: 2, isCorrect: true,
                            responseMs: 1500, cardsSeen: 104, checkedAt: t)
        #expect(g.draft == CountCheckDraft(kind: .trueCount, expected: 2, answered: 2, isCorrect: true,
                                           responseMs: 1500, cardsSeen: 104, checkedAt: t))
        #expect(GradedCount.milliseconds(from: t, to: t.addingTimeInterval(1.2345)) == 1235)
        #expect(GradedCount.milliseconds(from: t, to: t.addingTimeInterval(-1)) == 0)
    }
}

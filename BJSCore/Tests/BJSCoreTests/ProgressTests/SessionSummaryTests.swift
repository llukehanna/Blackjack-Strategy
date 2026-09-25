import Testing
@testable import BJSCore

@Suite("SessionSummary")
struct SessionSummaryTests {

    @Test("Empty session")
    func empty() {
        let s = SessionSummary(decisions: [], countChecks: [])
        #expect(s.decisionCount == 0)
        #expect(s.correctDecisions == 0)
        #expect(s.countCheckCount == 0)
        #expect(s.correctCountChecks == 0)
        #expect(s.bestStreak == 0)
        #expect(s.meanResponseMs == nil)
    }

    @Test("Counts and best streak are taken in order")
    func countsAndStreak() {
        let d: [(isCorrect: Bool, responseMs: Int?)] = [
            (true, nil), (true, nil), (false, nil), (true, nil), (true, nil), (true, nil), (false, nil),
        ]
        let s = SessionSummary(decisions: d, countChecks: [true, false, true])
        #expect(s.decisionCount == 7)
        #expect(s.correctDecisions == 5)
        #expect(s.bestStreak == 3)
        #expect(s.countCheckCount == 3)
        #expect(s.correctCountChecks == 2)
    }

    @Test("Mean response ignores decisions without a time")
    func meanResponse() {
        let s = SessionSummary(decisions: [(true, 1000 as Int?), (false, nil as Int?), (true, 2000 as Int?)], countChecks: [])
        #expect(s.meanResponseMs == 1500)
    }
}

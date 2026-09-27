import Testing
@testable import BJSCore

@Suite("Count drill score")
struct CountDrillScoreTests {

    @Test("No checks: no accuracy and no error")
    func empty() {
        let s = CountDrillScore([])
        #expect(s.checks == 0)
        #expect(s.correct == 0)
        #expect(s.accuracy == nil)
        #expect(s.meanAbsoluteError == nil)
    }

    @Test("All correct and exact")
    func allCorrect() {
        let s = CountDrillScore([(expected: 3, answered: 3, isCorrect: true),
                                 (expected: -1, answered: -1, isCorrect: true)])
        #expect(s.accuracy == 1)
        #expect(s.meanAbsoluteError == 0)
    }

    @Test("Mixed: accuracy counts isCorrect; the error is the mean of |answered − expected|")
    func mixed() {
        // A TC answer can be correct (within 0.25) with a non-zero error.
        let s = CountDrillScore([(expected: 3, answered: 3, isCorrect: true),
                                 (expected: -2, answered: 1, isCorrect: false),
                                 (expected: 0.5, answered: 0.25, isCorrect: true),
                                 (expected: 4, answered: 2, isCorrect: false)])
        #expect(s.checks == 4)
        #expect(s.correct == 2)
        #expect(s.accuracy == 0.5)
        #expect(s.meanAbsoluteError == (0 + 3 + 0.25 + 2) / 4)
    }

    @Test("Seconds per card is the pace divided by the group size")
    func secondsPerCard() {
        #expect(abs(CountDrillScore.secondsPerCard(pace: 0.9, groupSize: 3) - 0.3) < 1e-12)
        #expect(CountDrillScore.secondsPerCard(pace: 1.0, groupSize: 1) == 1.0)
    }
}

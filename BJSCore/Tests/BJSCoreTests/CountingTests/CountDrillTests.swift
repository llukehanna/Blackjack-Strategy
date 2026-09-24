import Testing
@testable import BJSCore

@Suite("Count drills")
struct CountDrillTests {

    @Test("Card lengths and group sizes", arguments: [(10, 1), (26, 2), (52, 3), (10, 3)])
    func lengthsAndGroups(length: Int, groupSize: Int) {
        var rng = SeededRandomNumberGenerator(seed: 1)
        let drill = CountDrillGenerator.runningCountDrill(
            length: .cards(length), groupSize: groupSize, deckCount: 6,
            randomCheckpoints: false, using: &rng)
        #expect(drill.cardCount == length)
        #expect(drill.groups.dropLast().allSatisfy { $0.count == groupSize })
        #expect(drill.groups.last!.count <= groupSize)
        #expect(drill.checkpoints == [drill.groups.count - 1])
    }

    @Test("Full shoe uses every card of the rules' deck count and ends at count zero")
    func fullShoe() {
        var rng = SeededRandomNumberGenerator(seed: 2)
        let drill = CountDrillGenerator.runningCountDrill(
            length: .fullShoe, groupSize: 2, deckCount: 2, randomCheckpoints: false, using: &rng)
        #expect(drill.cardCount == 104)
        #expect(drill.expectedCount(afterGroup: drill.groups.count - 1) == 0)
    }

    @Test("Expected count matches a HiLoCounter at every group")
    func expectedCountMatchesCounter() {
        var rng = SeededRandomNumberGenerator(seed: 3)
        let drill = CountDrillGenerator.runningCountDrill(
            length: .cards(52), groupSize: 3, deckCount: 1, randomCheckpoints: false, using: &rng)
        var counter = HiLoCounter()
        for (index, group) in drill.groups.enumerated() {
            counter.process(group)
            #expect(drill.expectedCount(afterGroup: index) == counter.runningCount)
        }
    }

    @Test("Random checkpoints are sorted, unique, include the last group, and occur sometimes")
    func randomCheckpoints() {
        var rng = SeededRandomNumberGenerator(seed: 4)
        let drill = CountDrillGenerator.runningCountDrill(
            length: .fullShoe, groupSize: 1, deckCount: 6, randomCheckpoints: true, using: &rng)
        #expect(drill.checkpoints == Array(Set(drill.checkpoints)).sorted())
        #expect(drill.checkpoints.last == drill.groups.count - 1)
        // 311 eligible groups at p = 1/8, so expect roughly 39; allow a wide band.
        #expect((15...70).contains(drill.checkpoints.count - 1))
    }

    @Test("True count questions have half-deck steps within the shoe")
    func trueCountQuestionShape() {
        var rng = SeededRandomNumberGenerator(seed: 5)
        for _ in 0..<500 {
            let q = CountDrillGenerator.trueCountQuestion(deckCount: 6, using: &rng)
            #expect(q.decksRemaining >= 0.5 && q.decksRemaining <= 5.5)
            #expect((q.decksRemaining * 2).rounded() == q.decksRemaining * 2)
            #expect((-12...12).contains(q.runningCount))
        }
        var single = SeededRandomNumberGenerator(seed: 6)
        let q = CountDrillGenerator.trueCountQuestion(deckCount: 1, using: &single)
        #expect(q.decksRemaining == 0.5)
    }

    @Test("Grading conventions")
    func grading() {
        let q = TrueCountQuestion(runningCount: 7, decksRemaining: 2.0)   // exact 3.5
        #expect(q.isCorrect(3.5, convention: .exact))
        #expect(q.isCorrect(3.25, convention: .exact))
        #expect(!q.isCorrect(3.0, convention: .exact))
        #expect(q.isCorrect(3, convention: .floor))
        #expect(!q.isCorrect(4, convention: .floor))
        #expect(q.isCorrect(3, convention: .truncate))

        let negative = TrueCountQuestion(runningCount: -7, decksRemaining: 2.0) // exact -3.5
        #expect(negative.isCorrect(-4, convention: .floor))
        #expect(negative.isCorrect(-3, convention: .truncate))
        #expect(!negative.isCorrect(-3, convention: .floor))
    }
}

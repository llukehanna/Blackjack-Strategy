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

    @Test("Full shoe holds back a random 5–15 card tail, so the last count isn't forced to zero")
    func fullShoe() {
        var sawNonZero = false
        var tails = Set<Int>()
        for seed in UInt64(1)...40 {
            var rng = SeededRandomNumberGenerator(seed: seed)
            let drill = CountDrillGenerator.runningCountDrill(
                length: .fullShoe, groupSize: 2, deckCount: 2, randomCheckpoints: false, using: &rng)
            let tail = 104 - drill.cardCount
            #expect(CountDrillGenerator.fullShoeHoldBack.contains(tail))
            tails.insert(tail)
            if drill.expectedCount(afterGroup: drill.groups.count - 1) != 0 { sawNonZero = true }
        }
        #expect(sawNonZero)
        #expect(tails.count > 1)
    }

    @Test("A card length equal to the whole shoe draws from a larger pool, so it isn't a full count-down")
    func wholePoolLength() {
        var sawNonZero = false
        for seed in UInt64(1)...20 {
            var rng = SeededRandomNumberGenerator(seed: seed)
            let drill = CountDrillGenerator.runningCountDrill(
                length: .cards(52), groupSize: 1, deckCount: 1, randomCheckpoints: false, using: &rng)
            #expect(drill.cardCount == 52)
            if drill.expectedCount(afterGroup: drill.groups.count - 1) != 0 { sawNonZero = true }
        }
        #expect(sawNonZero)
    }

    @Test("Partial-length drills draw from the configured deck count, not a minimal pool")
    func partialLengthUsesConfiguredDeckCount() {
        var sawNonZero = false
        for seed in UInt64(1)...20 {
            var rng = SeededRandomNumberGenerator(seed: seed)
            let drill = CountDrillGenerator.runningCountDrill(
                length: .cards(52), groupSize: 52, deckCount: 6,
                randomCheckpoints: false, using: &rng)
            if drill.expectedCount(afterGroup: drill.groups.count - 1) != 0 {
                sawNonZero = true
            }
        }
        #expect(sawNonZero)
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

    @Test("True count questions step in quarter decks for 1–2 decks and half decks otherwise",
          arguments: [(1, 0.25), (2, 0.25), (6, 0.5), (8, 0.5)])
    func trueCountSteps(deckCount: Int, step: Double) {
        #expect(CountDrillGenerator.trueCountStep(deckCount: deckCount) == step)
        var rng = SeededRandomNumberGenerator(seed: UInt64(deckCount))
        var seen = Set<Double>()
        for _ in 0..<2000 {
            let q = CountDrillGenerator.trueCountQuestion(deckCount: deckCount, using: &rng)
            #expect(q.decksRemaining >= step && q.decksRemaining <= Double(deckCount) - step)
            #expect((q.decksRemaining / step).rounded() == q.decksRemaining / step)
            #expect((-12...12).contains(q.runningCount))
            #expect(abs(q.exactTrueCount) <= CountDrillGenerator.maxTrueCountMagnitude + 1e-9)
            seen.insert(q.decksRemaining)
        }
        // Every step from one step to one step short of the full shoe appears.
        #expect(seen.count == Int((Double(deckCount) / step).rounded()) - 1)
    }

    @Test("The TC cap keeps small-deck questions sane but still allows big counts in a shoe")
    func trueCountCap() {
        var single = SeededRandomNumberGenerator(seed: 11)
        for _ in 0..<500 {
            let q = CountDrillGenerator.trueCountQuestion(deckCount: 1, using: &single)
            if q.decksRemaining == 0.25 { #expect(abs(q.runningCount) <= 2) }
        }
        var shoe = SeededRandomNumberGenerator(seed: 12)
        var sawBig = false
        for _ in 0..<500 where abs(CountDrillGenerator.trueCountQuestion(deckCount: 6, using: &shoe).runningCount) >= 10 {
            sawBig = true
        }
        #expect(sawBig)
    }

    @Test("Target per convention, including negatives")
    func targets() {
        let q = TrueCountQuestion(runningCount: 7, decksRemaining: 3)      // +2.333…
        #expect(abs(q.target(for: .exact) - 7.0 / 3) < 1e-12)
        #expect(q.target(for: .floor) == 2)
        #expect(q.target(for: .truncate) == 2)
        let n = TrueCountQuestion(runningCount: -7, decksRemaining: 3)     // −2.333…
        #expect(n.target(for: .floor) == -3)
        #expect(n.target(for: .truncate) == -2)
    }

    @Test("Keypad answer: nearest half under Exact, the target otherwise")
    func keypadAnswers() {
        #expect(TrueCountQuestion(runningCount: 7, decksRemaining: 3).keypadAnswer(for: .exact) == 2.5)
        #expect(TrueCountQuestion(runningCount: -7, decksRemaining: 3).keypadAnswer(for: .exact) == -2.5)
        #expect(TrueCountQuestion(runningCount: 7, decksRemaining: 3).keypadAnswer(for: .floor) == 2)
        #expect(TrueCountQuestion(runningCount: -7, decksRemaining: 3).keypadAnswer(for: .truncate) == -2)
    }

    @Test("The keypad answer is always graded correct", arguments: TrueCountConvention.allCases)
    func keypadAnswerIsCorrect(convention: TrueCountConvention) {
        var rng = SeededRandomNumberGenerator(seed: 13)
        for deckCount in [1, 2, 6, 8] {
            for _ in 0..<500 {
                let q = CountDrillGenerator.trueCountQuestion(deckCount: deckCount, using: &rng)
                #expect(q.isCorrect(q.keypadAnswer(for: convention), convention: convention))
            }
        }
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

    @Test("Trace covers the cards since the previous checkpoint, with running totals")
    func trace() {
        let c = { (r: Rank) in Card(rank: r, suit: .spades) }
        let drill = RunningCountDrill(
            groups: [[c(.two), c(.king)], [c(.five), c(.five)], [c(.ace), c(.seven)], [c(.three)]],
            checkpoints: [1, 3])
        let first = drill.trace(throughGroup: 1)
        #expect(first.map(\.card.rank) == [.two, .king, .five, .five])
        #expect(first.map(\.value) == [1, -1, 1, 1])
        #expect(first.map(\.runningCount) == [1, 0, 1, 2])
        // The next trace starts after group 1 and continues from its count (+2).
        let later = drill.trace(throughGroup: 3)
        #expect(later.map(\.card.rank) == [.ace, .seven, .three])
        #expect(later.map(\.runningCount) == [1, 1, 2])
    }

    @Test("Traces over every checkpoint cover the drill exactly once", arguments: [1, 2, 3])
    func tracesPartitionDrill(groupSize: Int) {
        var rng = SeededRandomNumberGenerator(seed: 7)
        let drill = CountDrillGenerator.runningCountDrill(
            length: .cards(52), groupSize: groupSize, deckCount: 6, randomCheckpoints: true, using: &rng)
        var all: [CountTraceEntry] = []
        for checkpoint in drill.checkpoints {
            let entries = drill.trace(throughGroup: checkpoint)
            #expect(entries.last?.runningCount == drill.expectedCount(afterGroup: checkpoint))
            all += entries
        }
        #expect(all.map(\.card) == drill.groups.flatMap { $0 })
    }

    @Test("Random cards cover every rank and suit, and a seed reproduces the same sequence")
    func randomCardCoversRanksAndSuits() {
        var rng = SeededRandomNumberGenerator(seed: 8)
        var ranks = Set<Rank>()
        var suits = Set<Suit>()
        var drawn: [Card] = []
        for _ in 0..<500 {
            let card = CountDrillGenerator.randomCard(using: &rng)
            ranks.insert(card.rank)
            suits.insert(card.suit)
            drawn.append(card)
        }
        #expect(ranks == Set(Rank.allCases))
        #expect(suits == Set(Suit.allCases))

        var replay = SeededRandomNumberGenerator(seed: 8)
        let replayed = (0..<500).map { _ in CountDrillGenerator.randomCard(using: &replay) }
        #expect(replayed == drawn)
    }
}

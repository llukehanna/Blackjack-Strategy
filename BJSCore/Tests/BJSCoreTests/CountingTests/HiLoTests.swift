import Testing
@testable import BJSCore

@Suite("Hi-Lo Counter")
struct HiLoTests {

    // MARK: - Running Count

    @Test("Fresh counter has running count of 0")
    func freshCounterIsZero() {
        let counter = HiLoCounter()
        #expect(counter.runningCount == 0)
    }

    @Test("Low card (2) increments running count by 1")
    func lowCardIncrementsCount() {
        var counter = HiLoCounter()
        counter.process(Card(rank: .two, suit: .hearts))
        #expect(counter.runningCount == 1)
    }

    @Test("Neutral card (7) does not change running count")
    func neutralCardNoChange() {
        var counter = HiLoCounter()
        counter.process(Card(rank: .seven, suit: .hearts))
        #expect(counter.runningCount == 0)
    }

    @Test("High card (ace) decrements running count by 1")
    func highCardDecrementsCount() {
        var counter = HiLoCounter()
        counter.process(Card(rank: .ace, suit: .hearts))
        #expect(counter.runningCount == -1)
    }

    @Test("Sequence of low cards [2,3,4,5,6] gives RC +5")
    func sequenceOfLowCards() {
        var counter = HiLoCounter()
        let lowRanks: [Rank] = [.two, .three, .four, .five, .six]
        for rank in lowRanks {
            counter.process(Card(rank: rank, suit: .spades))
        }
        #expect(counter.runningCount == 5)
    }

    @Test("Sequence of high cards [10,J,Q,K,A] gives RC -5")
    func sequenceOfHighCards() {
        var counter = HiLoCounter()
        let highRanks: [Rank] = [.ten, .jack, .queen, .king, .ace]
        for rank in highRanks {
            counter.process(Card(rank: rank, suit: .clubs))
        }
        #expect(counter.runningCount == -5)
    }

    @Test("Mixed cards [2, 10] cancel out to RC 0")
    func mixedCardsCancelOut() {
        var counter = HiLoCounter()
        counter.process(Card(rank: .two, suit: .hearts))
        counter.process(Card(rank: .ten, suit: .hearts))
        #expect(counter.runningCount == 0)
    }

    @Test("Batch process multiple cards at once")
    func batchProcess() {
        var counter = HiLoCounter()
        let cards = [
            Card(rank: .two, suit: .hearts),
            Card(rank: .three, suit: .hearts),
            Card(rank: .ten, suit: .hearts),
        ]
        counter.process(cards)
        #expect(counter.runningCount == 1)
    }

    // MARK: - True Count

    @Test("True count: RC 4 with 2.0 decks remaining = 2.0")
    func trueCountBasic() {
        var counter = HiLoCounter()
        for _ in 0..<4 {
            counter.process(Card(rank: .two, suit: .hearts))
        }
        let tc = counter.trueCount(decksRemaining: 2.0)
        #expect(abs(tc - 2.0) < 0.001)
    }

    @Test("True count: RC -6 with 3.0 decks remaining = -2.0")
    func trueCountNegative() {
        var counter = HiLoCounter()
        for _ in 0..<6 {
            counter.process(Card(rank: .ace, suit: .hearts))
        }
        let tc = counter.trueCount(decksRemaining: 3.0)
        #expect(abs(tc - (-2.0)) < 0.001)
    }

    @Test("True count: RC 5 with 2.5 decks remaining = 2.0")
    func trueCountFractionalDecks() {
        var counter = HiLoCounter()
        for _ in 0..<5 {
            counter.process(Card(rank: .three, suit: .hearts))
        }
        let tc = counter.trueCount(decksRemaining: 2.5)
        #expect(abs(tc - 2.0) < 0.001)
    }

    @Test("True count: RC 0 with any decks remaining = 0.0")
    func trueCountZeroRC() {
        let counter = HiLoCounter()
        let tc = counter.trueCount(decksRemaining: 4.0)
        #expect(tc == 0.0)
    }

    @Test("True count: 0 decks remaining returns 0 (guard)")
    func trueCountZeroDecks() {
        var counter = HiLoCounter()
        counter.process(Card(rank: .two, suit: .hearts))
        let tc = counter.trueCount(decksRemaining: 0.0)
        #expect(tc == 0.0)
    }

    // MARK: - End-of-Shoe Invariant

    @Test("End-of-shoe invariant: RC == 0 after full single deck")
    func endOfShoeInvariantSingleDeck() {
        var shoe = Shoe(deckCount: 1)
        shoe.shuffle()
        var counter = HiLoCounter()
        while let card = shoe.deal() {
            counter.process(card)
        }
        #expect(counter.runningCount == 0,
                "Running count should be 0 after dealing entire deck, got \(counter.runningCount)")
    }

    @Test("End-of-shoe invariant: RC == 0 after full 6-deck shoe")
    func endOfShoeInvariantSixDeck() {
        var shoe = Shoe(deckCount: 6)
        shoe.shuffle()
        var counter = HiLoCounter()
        while let card = shoe.deal() {
            counter.process(card)
        }
        #expect(counter.runningCount == 0)
    }

    // MARK: - Reset

    @Test("After reset, running count returns to 0")
    func resetClearsCount() {
        var counter = HiLoCounter()
        counter.process(Card(rank: .two, suit: .hearts))
        counter.process(Card(rank: .three, suit: .hearts))
        #expect(counter.runningCount == 2)
        counter.reset()
        #expect(counter.runningCount == 0)
    }
}

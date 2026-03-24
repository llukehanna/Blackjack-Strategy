import Testing
@testable import BJSCore

@Suite("Shoe")
struct ShoeTests {

    @Test("1-deck shoe has 52 cards")
    func oneDeckCount() {
        let shoe = Shoe(deckCount: 1)
        #expect(shoe.totalCards == 52)
        #expect(shoe.cardsRemaining == 52)
    }

    @Test("6-deck shoe has 312 cards")
    func sixDeckCount() {
        let shoe = Shoe(deckCount: 6)
        #expect(shoe.totalCards == 312)
        #expect(shoe.cardsRemaining == 312)
    }

    @Test("Dealing one card reduces cardsRemaining by 1")
    func dealReducesRemaining() {
        var shoe = Shoe(deckCount: 1)
        shoe.shuffle()
        let _ = shoe.deal()
        #expect(shoe.cardsRemaining == 51)
    }

    @Test("Dealing all 52 cards from 1-deck returns 52 non-nil cards, then nil")
    func dealExhaustsShoe() {
        var shoe = Shoe(deckCount: 1)
        shoe.shuffle()
        var dealtCards: [Card] = []
        for _ in 0..<52 {
            if let card = shoe.deal() {
                dealtCards.append(card)
            }
        }
        #expect(dealtCards.count == 52)
        #expect(shoe.deal() == nil)
    }

    @Test("After shuffle, cardsRemaining resets to totalCards")
    func shuffleResets() {
        var shoe = Shoe(deckCount: 1)
        shoe.shuffle()
        // Deal some cards
        for _ in 0..<10 {
            let _ = shoe.deal()
        }
        #expect(shoe.cardsRemaining == 42)
        // Reshuffle
        shoe.shuffle()
        #expect(shoe.cardsRemaining == 52)
    }

    @Test("decksRemaining for fresh 6-deck shoe is 6.0")
    func decksRemainingFresh() {
        let shoe = Shoe(deckCount: 6)
        #expect(shoe.decksRemaining == 6.0)
    }

    @Test("needsReshuffle is false until penetration threshold reached")
    func needsReshuffleFalseBeforeThreshold() {
        var shoe = Shoe(deckCount: 1, penetration: 0.75)
        shoe.shuffle()
        // Deal 38 of 52 cards (73% penetration) - still below 75%
        for _ in 0..<38 {
            let _ = shoe.deal()
        }
        #expect(shoe.needsReshuffle == false)
    }

    @Test("needsReshuffle is true when dealt cards / totalCards >= penetration")
    func needsReshuffleTrueAtThreshold() {
        var shoe = Shoe(deckCount: 1, penetration: 0.75)
        shoe.shuffle()
        // Deal 39 of 52 cards (75% penetration) - at threshold
        for _ in 0..<39 {
            let _ = shoe.deal()
        }
        #expect(shoe.needsReshuffle == true)
    }

    @Test("Dealt cards contain correct distribution from a 1-deck shoe")
    func cardDistribution() {
        var shoe = Shoe(deckCount: 1)
        shoe.shuffle()
        var cards: [Card] = []
        while let c = shoe.deal() {
            cards.append(c)
        }
        // Should have exactly 4 of each rank
        for rank in Rank.allCases {
            let count = cards.filter { $0.rank == rank }.count
            #expect(count == 4, "Expected 4 of \(rank), got \(count)")
        }
        // Should have exactly 13 of each suit
        for suit in Suit.allCases {
            let count = cards.filter { $0.suit == suit }.count
            #expect(count == 13, "Expected 13 of \(suit), got \(count)")
        }
    }
}

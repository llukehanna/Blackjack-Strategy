import Testing
@testable import BJSCore

@Suite("Shoe seeding and stacking")
struct ShoeSeedingTests {

    @Test("Same seed produces the same shuffle")
    func sameSeedSameOrder() {
        var a = Shoe(deckCount: 2)
        var b = Shoe(deckCount: 2)
        var rngA = SeededRandomNumberGenerator(seed: 42)
        var rngB = SeededRandomNumberGenerator(seed: 42)
        a.shuffle(using: &rngA)
        b.shuffle(using: &rngB)
        let first = (0..<104).compactMap { _ in a.deal() }
        let second = (0..<104).compactMap { _ in b.deal() }
        #expect(first == second)
    }

    @Test("Different seeds produce different shuffles")
    func differentSeeds() {
        var a = Shoe(deckCount: 1)
        var b = Shoe(deckCount: 1)
        var rngA = SeededRandomNumberGenerator(seed: 1)
        var rngB = SeededRandomNumberGenerator(seed: 2)
        a.shuffle(using: &rngA)
        b.shuffle(using: &rngB)
        let first = (0..<52).compactMap { _ in a.deal() }
        let second = (0..<52).compactMap { _ in b.deal() }
        #expect(first != second)
    }

    @Test("Ordered shoe deals exactly the given cards then nil")
    func orderedShoe() {
        let cards = [Card(rank: .ace, suit: .spades), Card(rank: .two, suit: .hearts)]
        var shoe = Shoe(orderedCards: cards)
        #expect(shoe.totalCards == 2)
        #expect(shoe.deal() == cards[0])
        #expect(shoe.dealtCount == 1)
        #expect(shoe.deal() == cards[1])
        #expect(shoe.deal() == nil)
    }

    @Test("standardCards has 52 unique cards per deck")
    func standardCards() {
        #expect(Shoe.standardCards(deckCount: 1).count == 52)
        #expect(Set(Shoe.standardCards(deckCount: 1)).count == 52)
        #expect(Shoe.standardCards(deckCount: 6).count == 312)
    }

    @Test("BlackjackHand is Equatable by cards")
    func handEquatable() {
        let a = BlackjackHand(cards: [Card(rank: .ten, suit: .clubs)])
        let b = BlackjackHand(cards: [Card(rank: .ten, suit: .clubs)])
        #expect(a == b)
    }
}

import Testing
@testable import BJSCore

@Suite("Card, Rank, and Suit Types")
struct CardTests {

    // MARK: - Rank blackjackValue

    @Test("All rank blackjack values are correct")
    func rankBlackjackValues() {
        #expect(Rank.two.blackjackValue == 2)
        #expect(Rank.three.blackjackValue == 3)
        #expect(Rank.four.blackjackValue == 4)
        #expect(Rank.five.blackjackValue == 5)
        #expect(Rank.six.blackjackValue == 6)
        #expect(Rank.seven.blackjackValue == 7)
        #expect(Rank.eight.blackjackValue == 8)
        #expect(Rank.nine.blackjackValue == 9)
        #expect(Rank.ten.blackjackValue == 10)
        #expect(Rank.jack.blackjackValue == 10)
        #expect(Rank.queen.blackjackValue == 10)
        #expect(Rank.king.blackjackValue == 10)
        #expect(Rank.ace.blackjackValue == 1)
    }

    // MARK: - Rank hiLoValue

    @Test("Hi-Lo values: 2-6 are +1")
    func hiLoLowCards() {
        #expect(Rank.two.hiLoValue == 1)
        #expect(Rank.three.hiLoValue == 1)
        #expect(Rank.four.hiLoValue == 1)
        #expect(Rank.five.hiLoValue == 1)
        #expect(Rank.six.hiLoValue == 1)
    }

    @Test("Hi-Lo values: 7-9 are 0")
    func hiLoNeutralCards() {
        #expect(Rank.seven.hiLoValue == 0)
        #expect(Rank.eight.hiLoValue == 0)
        #expect(Rank.nine.hiLoValue == 0)
    }

    @Test("Hi-Lo values: 10-A are -1")
    func hiLoHighCards() {
        #expect(Rank.ten.hiLoValue == -1)
        #expect(Rank.jack.hiLoValue == -1)
        #expect(Rank.queen.hiLoValue == -1)
        #expect(Rank.king.hiLoValue == -1)
        #expect(Rank.ace.hiLoValue == -1)
    }

    // MARK: - Rank columnIndex

    @Test("Column index for strategy table lookup")
    func rankColumnIndex() {
        #expect(Rank.two.columnIndex == 0)
        #expect(Rank.three.columnIndex == 1)
        #expect(Rank.ten.columnIndex == 8)
        #expect(Rank.jack.columnIndex == 8)
        #expect(Rank.queen.columnIndex == 8)
        #expect(Rank.king.columnIndex == 8)
        #expect(Rank.ace.columnIndex == 9)
    }

    // MARK: - Card Sendable and Codable

    @Test("Card conforms to Sendable")
    func cardIsSendable() {
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        let card = requireSendable(Card(rank: .ace, suit: .spades))
        #expect(card.rank == .ace)
    }

    @Test("Card round-trips through JSON encoding/decoding")
    func cardCodableRoundTrip() throws {
        let original = Card(rank: .queen, suit: .diamonds)
        let decoded = try CodableTestHelper.jsonRoundTrip(original)
        #expect(decoded == original)
    }

    @Test("All 52 unique cards can be created from Rank and Suit allCases")
    func fullDeck() {
        var cards: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(Card(rank: rank, suit: suit))
            }
        }
        #expect(cards.count == 52)
    }

    // MARK: - Action enum

    @Test("All Action cases exist and are Codable")
    func actionCases() throws {
        let allActions = Action.allCases
        #expect(allActions.count == 5)
        #expect(allActions.contains(.hit))
        #expect(allActions.contains(.stand))
        #expect(allActions.contains(.double))
        #expect(allActions.contains(.split))
        #expect(allActions.contains(.surrender))

        // Codable round-trip
        for action in allActions {
            let decoded = try CodableTestHelper.jsonRoundTrip(action)
            #expect(decoded == action)
        }
    }
}

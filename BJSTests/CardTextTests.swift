import BJSCore
import Testing
@testable import BJS

@Suite("CardText")
struct CardTextTests {

    @Test("VoiceOver label reads rank and suit", arguments: [
        (Card(rank: .eight, suit: .clubs), "Eight of clubs"),
        (Card(rank: .ace, suit: .spades), "Ace of spades"),
        (Card(rank: .ten, suit: .hearts), "Ten of hearts"),
        (Card(rank: .queen, suit: .diamonds), "Queen of diamonds"),
    ])
    func label(_ card: Card, _ expected: String) {
        #expect(CardText.accessibilityLabel(card) == expected)
    }

    @Test("Corner index for every rank")
    func index() {
        #expect(Rank.allCases.map(CardText.rankIndex) ==
                ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"])
    }

    @Test("Hearts and diamonds are red; clubs and spades are not")
    func colours() {
        #expect(CardText.isRed(.hearts))
        #expect(CardText.isRed(.diamonds))
        #expect(!CardText.isRed(.clubs))
        #expect(!CardText.isRed(.spades))
    }

    @Test("Every suit has an SF Symbol")
    func symbols() {
        #expect(Suit.allCases.map(CardText.suitSymbolName) ==
                ["suit.heart.fill", "suit.diamond.fill", "suit.club.fill", "suit.spade.fill"])
    }
}

import Testing
import BJSCore
@testable import BJS

@MainActor
struct PlayingCardTests {

    @Test("VoiceOver names read like 'Eight of clubs'")
    func spokenNames() {
        #expect(Card(rank: .eight, suit: .clubs).spokenName == "Eight of clubs")
        #expect(Card(rank: .ace, suit: .spades).spokenName == "Ace of spades")
        #expect(Card(rank: .ten, suit: .hearts).spokenName == "Ten of hearts")
        #expect(Card(rank: .jack, suit: .diamonds).spokenName == "Jack of diamonds")
    }

    @Test("All 52 cards have distinct names")
    func allNamesDistinct() {
        let names = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(rank: $0, suit: suit).spokenName } }
        #expect(Set(names).count == 52)
    }

    @Test("Index labels: A K Q J 10 … 2")
    func indexLabels() {
        #expect(Rank.allCases.map { $0.indexLabel }
                == ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"])
    }

    @Test("Hearts and diamonds are red; suits use SF Symbols")
    func suits() {
        #expect(Suit.hearts.isRed && Suit.diamonds.isRed)
        #expect(!Suit.clubs.isRed && !Suit.spades.isRed)
        #expect(Suit.hearts.symbolName == "suit.heart.fill")
        #expect(Suit.diamonds.symbolName == "suit.diamond.fill")
        #expect(Suit.clubs.symbolName == "suit.club.fill")
        #expect(Suit.spades.symbolName == "suit.spade.fill")
    }

    @Test("A face-down card is announced without revealing it")
    func faceDownLabel() {
        let card = Card(rank: .king, suit: .hearts)
        #expect(PlayingCard.accessibilityText(card: card, isFaceUp: true) == "King of hearts")
        #expect(PlayingCard.accessibilityText(card: card, isFaceUp: false) == "Face-down card")
    }

    @Test("Card height is width × 1.4")
    func aspect() {
        #expect(PlayingCardMetrics.aspectRatio == 1.4)
        #expect(PlayingCardMetrics.height(forWidth: 70) == 98)
    }

    @Test("Hand layout offsets each card by the visible fraction of its width")
    func handLayout() {
        #expect(HandLayout.offsets(count: 3, cardWidth: 100, overlap: 0.5) == [0, 50, 100])
        #expect(HandLayout.totalWidth(count: 3, cardWidth: 100, overlap: 0.5) == 200)
        #expect(HandLayout.totalWidth(count: 1, cardWidth: 100, overlap: 0.5) == 100)
        #expect(HandLayout.totalWidth(count: 0, cardWidth: 100, overlap: 0.5) == 0)
        #expect(HandLayout.offsets(count: 0, cardWidth: 100, overlap: 0.5).isEmpty)
    }
}

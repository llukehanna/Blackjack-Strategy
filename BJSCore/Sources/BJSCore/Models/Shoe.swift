/// A multi-deck card source (shoe) with shuffle, deal, and penetration tracking.
///
/// The shoe contains one or more standard 52-card decks. Cards are dealt in order
/// from the shuffled shoe. The `needsReshuffle` flag indicates when the dealt
/// percentage has reached or exceeded the configured penetration threshold.
public struct Shoe: Sendable {

    private var cards: [Card]
    private var dealIndex: Int = 0

    /// The total number of cards in the shoe (before any deals).
    public let totalCards: Int

    /// The fraction of the shoe that should be dealt before reshuffling (0.0-1.0).
    public let penetration: Double

    /// Creates a shoe with the specified number of decks.
    /// - Parameters:
    ///   - deckCount: Number of standard 52-card decks (1-8).
    ///   - penetration: Fraction of shoe to deal before reshuffle (default 0.75 = 75%).
    public init(deckCount: Int, penetration: Double = 0.75) {
        self.penetration = penetration
        var allCards: [Card] = []
        for _ in 0..<deckCount {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    allCards.append(Card(rank: rank, suit: suit))
                }
            }
        }
        self.totalCards = allCards.count
        self.cards = allCards
    }

    /// Shuffles all cards in the shoe and resets the deal position to the beginning.
    public mutating func shuffle() {
        cards.shuffle()
        dealIndex = 0
    }

    /// Deals the next card from the shoe, or nil if the shoe is exhausted.
    public mutating func deal() -> Card? {
        guard dealIndex < cards.count else { return nil }
        let card = cards[dealIndex]
        dealIndex += 1
        return card
    }

    /// The number of cards remaining to be dealt.
    public var cardsRemaining: Int { cards.count - dealIndex }

    /// The approximate number of decks remaining (cardsRemaining / 52).
    public var decksRemaining: Double { Double(cardsRemaining) / 52.0 }

    /// Whether the shoe has reached its penetration threshold and should be reshuffled.
    public var needsReshuffle: Bool {
        Double(dealIndex) / Double(totalCards) >= penetration
    }
}

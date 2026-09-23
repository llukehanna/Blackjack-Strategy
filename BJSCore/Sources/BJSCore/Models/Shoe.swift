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

    /// Creates an unshuffled shoe with the specified number of decks.
    /// - Parameters:
    ///   - deckCount: Number of standard 52-card decks (1-8).
    ///   - penetration: Fraction of shoe to deal before reshuffle (default 0.75 = 75%).
    public init(deckCount: Int, penetration: Double = 0.75) {
        self.init(orderedCards: Self.standardCards(deckCount: deckCount), penetration: penetration)
    }

    /// Creates a shoe that deals exactly `orderedCards`, first element first.
    /// Used for stacked training hands and deterministic tests.
    public init(orderedCards: [Card], penetration: Double = 1.0) {
        self.cards = orderedCards
        self.totalCards = orderedCards.count
        self.penetration = penetration
    }

    /// All cards of `deckCount` standard decks in a fixed, unshuffled order.
    public static func standardCards(deckCount: Int) -> [Card] {
        var all: [Card] = []
        all.reserveCapacity(deckCount * 52)
        for _ in 0..<deckCount {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    all.append(Card(rank: rank, suit: suit))
                }
            }
        }
        return all
    }

    /// Shuffles all cards using the system RNG and resets the deal position.
    public mutating func shuffle() {
        var rng = SystemRandomNumberGenerator()
        shuffle(using: &rng)
    }

    /// Shuffles all cards using `rng` and resets the deal position.
    public mutating func shuffle<G: RandomNumberGenerator>(using rng: inout G) {
        cards.shuffle(using: &rng)
        dealIndex = 0
    }

    /// Deals the next card from the shoe, or nil if the shoe is exhausted.
    public mutating func deal() -> Card? {
        guard dealIndex < cards.count else { return nil }
        let card = cards[dealIndex]
        dealIndex += 1
        return card
    }

    /// The number of cards dealt since the last shuffle.
    public var dealtCount: Int { dealIndex }

    /// The number of cards remaining to be dealt.
    public var cardsRemaining: Int { cards.count - dealIndex }

    /// The approximate number of decks remaining (cardsRemaining / 52).
    public var decksRemaining: Double { Double(cardsRemaining) / 52.0 }

    /// Whether the shoe has reached its penetration threshold and should be reshuffled.
    public var needsReshuffle: Bool {
        Double(dealIndex) / Double(totalCards) >= penetration
    }
}

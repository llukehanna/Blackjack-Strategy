/// Builds training hands: picks a cell (uniformly or by weight) and stacks a shoe
/// so `RoundEngine` deals exactly that starting hand.
public enum HandGenerator {

    /// Floor applied to every cell weight so no cell is ever unreachable.
    public static let minimumWeight: Double = 0.05

    private static let tenRanks: [Rank] = [.ten, .jack, .queen, .king]

    /// Picks a cell matching `filter`. With `weights == nil` the pick is uniform;
    /// otherwise proportional to `max(weights[cell] ?? minimumWeight, minimumWeight)`.
    public static func sampleCell<G: RandomNumberGenerator>(
        filter: HandFilter, weights: [TrainingCell: Double]?, using rng: inout G
    ) -> TrainingCell {
        let candidates = TrainingCell.cells(matching: filter)
        guard let weights else { return candidates.randomElement(using: &rng)! }
        let values = candidates.map { max(weights[$0] ?? minimumWeight, minimumWeight) }
        let total = values.reduce(0, +)
        var target = Double.random(in: 0..<total, using: &rng)
        for (cell, weight) in zip(candidates, values) {
            if target < weight { return cell }
            target -= weight
        }
        return candidates[candidates.count - 1]
    }

    /// Concrete cards for a cell. The three cards always have distinct suits,
    /// so they are distinct cards even in a single deck.
    public static func cards<G: RandomNumberGenerator>(
        for cell: TrainingCell, using rng: inout G
    ) -> (player: [Card], upcard: Card) {
        let suits = Suit.allCases.shuffled(using: &rng)
        let upRank = rank(forValue: cell.dealerUpcard, using: &rng)
        let ranks: (Rank, Rank)
        switch cell.handType {
        case .pair:
            let r = rank(forValue: cell.playerValue, using: &rng)
            ranks = (r, r)
        case .soft:
            ranks = (.ace, rank(forValue: cell.playerValue - 11, using: &rng))
        case .hard:
            ranks = hardRanks(total: cell.playerValue, using: &rng)
        }
        return ([Card(rank: ranks.0, suit: suits[0]), Card(rank: ranks.1, suit: suits[1])],
                Card(rank: upRank, suit: suits[2]))
    }

    /// A shoe that deals the cell's hand in `RoundEngine` order (P1, upcard, P2, hole),
    /// followed by the rest of `deckCount` shuffled decks.
    ///
    /// Under American peek the hole card never gives the dealer a natural, so every
    /// training hand starts with a decision — the round would otherwise end before
    /// the player acts. Under European no-hole-card the player always decides first
    /// regardless of the hole card, so the exclusion is skipped and dealer naturals
    /// occur at their natural frequency, which is the lesson ENHC teaches.
    public static func stackedShoe<G: RandomNumberGenerator>(
        for cell: TrainingCell, deckCount: Int, peekRule: BlackjackRules.PeekRule = .americanPeek,
        using rng: inout G
    ) -> Shoe {
        let (player, up) = cards(for: cell, using: &rng)
        var rest = Shoe.standardCards(deckCount: deckCount)
        for card in player + [up] {
            if let index = rest.firstIndex(of: card) { rest.remove(at: index) }
        }
        rest.shuffle(using: &rng)
        let holeIndex: Int
        if peekRule == .europeanNoPeek {
            holeIndex = 0
        } else {
            holeIndex = rest.firstIndex { !completesBlackjack(upcard: up.rank, hole: $0.rank) } ?? 0
        }
        let hole = rest.remove(at: holeIndex)
        return Shoe(orderedCards: [player[0], up, player[1], hole] + rest)
    }

    // MARK: - Helpers

    static func rank<G: RandomNumberGenerator>(forValue value: Int, using rng: inout G) -> Rank {
        switch value {
        case 11: return .ace
        case 10: return tenRanks.randomElement(using: &rng)!
        default: return Rank(rawValue: value)!
        }
    }

    /// Two non-ace ranks summing to `total` that are not a pair (by rank).
    /// Hard 20 uses two different ten-value ranks (e.g. K + Q).
    static func hardRanks<G: RandomNumberGenerator>(total: Int, using rng: inout G) -> (Rank, Rank) {
        var options: [(Int, Int)] = []
        for a in 2...10 {
            let b = total - a
            if b >= a && b <= 10 && (a != b || a == 10) { options.append((a, b)) }
        }
        let (a, b) = options.randomElement(using: &rng)!
        if a == 10 && b == 10 {
            let tens = tenRanks.shuffled(using: &rng)
            return (tens[0], tens[1])
        }
        return (rank(forValue: a, using: &rng), rank(forValue: b, using: &rng))
    }

    static func completesBlackjack(upcard: Rank, hole: Rank) -> Bool {
        (upcard == .ace && hole.blackjackValue == 10) || (upcard.blackjackValue == 10 && hole == .ace)
    }
}

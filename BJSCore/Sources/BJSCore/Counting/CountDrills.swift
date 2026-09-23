/// How the user is expected to round a true count.
public enum TrueCountConvention: String, CaseIterable, Sendable, Codable {
    /// Within ±0.25 of RC / decks.
    case exact
    /// ⌊RC / decks⌋.
    case floor
    /// RC / decks rounded toward zero.
    case truncate
}

public enum DrillLength: Sendable, Equatable, Hashable {
    case cards(Int)
    case fullShoe
}

/// A running-count drill: cards shown in groups; the user reports the count at checkpoints.
public struct RunningCountDrill: Sendable, Equatable {
    public let groups: [[Card]]
    /// Ascending group indices after which the user is asked for the running count.
    /// Always includes the last group.
    public let checkpoints: [Int]
    private let countsAfterGroup: [Int]

    init(groups: [[Card]], checkpoints: [Int]) {
        self.groups = groups
        self.checkpoints = checkpoints
        var running = 0
        self.countsAfterGroup = groups.map { group in
            running += group.reduce(0) { $0 + $1.rank.hiLoValue }
            return running
        }
    }

    public var cardCount: Int { groups.reduce(0) { $0 + $1.count } }

    /// The correct running count after the group at `index` has been shown.
    public func expectedCount(afterGroup index: Int) -> Int {
        countsAfterGroup[index]
    }
}

/// A true-count conversion question.
public struct TrueCountQuestion: Sendable, Equatable {
    public let runningCount: Int
    public let decksRemaining: Double

    public init(runningCount: Int, decksRemaining: Double) {
        self.runningCount = runningCount
        self.decksRemaining = decksRemaining
    }

    public var exactTrueCount: Double { Double(runningCount) / decksRemaining }

    public func isCorrect(_ answer: Double, convention: TrueCountConvention) -> Bool {
        switch convention {
        case .exact:
            return abs(answer - exactTrueCount) <= 0.25 + 1e-9
        case .floor:
            return abs(answer - exactTrueCount.rounded(.down)) < 1e-9
        case .truncate:
            return abs(answer - exactTrueCount.rounded(.towardZero)) < 1e-9
        }
    }
}

public enum CountDrillGenerator {

    /// Chance that any non-final group is a surprise checkpoint (about 1 in 8).
    public static let randomCheckpointProbability = 0.125

    public static func runningCountDrill<G: RandomNumberGenerator>(
        length: DrillLength, groupSize: Int, deckCount: Int,
        randomCheckpoints: Bool, using rng: inout G
    ) -> RunningCountDrill {
        let cards: [Card]
        switch length {
        case .cards(let n):
            let decks = max(1, Int((Double(n) / 52).rounded(.up)))
            cards = Array(Shoe.standardCards(deckCount: decks).shuffled(using: &rng).prefix(n))
        case .fullShoe:
            cards = Shoe.standardCards(deckCount: deckCount).shuffled(using: &rng)
        }
        let size = max(1, groupSize)
        let groups = stride(from: 0, to: cards.count, by: size).map {
            Array(cards[$0..<min($0 + size, cards.count)])
        }
        var checkpoints: [Int] = []
        if randomCheckpoints {
            for index in 0..<(groups.count - 1)
            where Double.random(in: 0..<1, using: &rng) < randomCheckpointProbability {
                checkpoints.append(index)
            }
        }
        checkpoints.append(groups.count - 1)
        return RunningCountDrill(groups: groups, checkpoints: checkpoints)
    }

    /// Running count in -12...12; decks remaining in half-deck steps from 0.5
    /// to `deckCount - 0.5` (0.5 for a single deck).
    public static func trueCountQuestion<G: RandomNumberGenerator>(
        deckCount: Int, using rng: inout G
    ) -> TrueCountQuestion {
        let maxHalfDecks = max(1, deckCount * 2 - 1)
        let halfDecks = Int.random(in: 1...maxHalfDecks, using: &rng)
        let rc = Int.random(in: -12...12, using: &rng)
        return TrueCountQuestion(runningCount: rc, decksRemaining: Double(halfDecks) / 2)
    }
}

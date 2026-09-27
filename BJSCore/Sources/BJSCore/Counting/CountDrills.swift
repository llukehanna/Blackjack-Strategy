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

/// One card in a running-count trace: its Hi-Lo value and the running count after it.
public struct CountTraceEntry: Sendable, Equatable {
    public let card: Card
    public let value: Int
    public let runningCount: Int

    public init(card: Card, value: Int, runningCount: Int) {
        self.card = card
        self.value = value
        self.runningCount = runningCount
    }
}

/// A running-count drill: cards shown in groups; the user reports the count at checkpoints.
public struct RunningCountDrill: Sendable, Equatable {
    public let groups: [[Card]]
    /// Ascending group indices after which the user is asked for the running count.
    /// Always includes the last group.
    public let checkpoints: [Int]
    private let countsAfterGroup: [Int]

    /// `checkpoints` must be ascending group indices ending with the last group.
    public init(groups: [[Card]], checkpoints: [Int]) {
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

    /// Every card from the group after the previous checkpoint through `groupIndex`, with its
    /// Hi-Lo value and the running count after it. The first checkpoint's trace starts at card 1.
    public func trace(throughGroup groupIndex: Int) -> [CountTraceEntry] {
        let first = checkpoints.last(where: { $0 < groupIndex }).map { $0 + 1 } ?? 0
        var running = first == 0 ? 0 : countsAfterGroup[first - 1]
        var entries: [CountTraceEntry] = []
        for group in groups[first...groupIndex] {
            for card in group {
                running += card.rank.hiLoValue
                entries.append(CountTraceEntry(card: card, value: card.rank.hiLoValue, runningCount: running))
            }
        }
        return entries
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

    /// The value a convention grades against: exact RC ÷ decks, rounded down, or rounded toward zero.
    public func target(for convention: TrueCountConvention) -> Double {
        switch convention {
        case .exact: return exactTrueCount
        case .floor: return exactTrueCount.rounded(.down)
        case .truncate: return exactTrueCount.rounded(.towardZero)
        }
    }

    /// What to enter on the half-step keypad: the nearest half for Exact (always within 0.25),
    /// otherwise the target.
    public func keypadAnswer(for convention: TrueCountConvention) -> Double {
        convention == .exact ? (exactTrueCount * 2).rounded() / 2 : target(for: convention)
    }

    public func isCorrect(_ answer: Double, convention: TrueCountConvention) -> Bool {
        switch convention {
        case .exact:
            return abs(answer - exactTrueCount) <= 0.25 + 1e-9
        case .floor, .truncate:
            return abs(answer - target(for: convention)) < 1e-9
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
            let neededDecks = max(1, Int((Double(n) / 52).rounded(.up)))
            let decks = max(deckCount, neededDecks)
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

    /// No TC question asks for more than ±10 (Step 4 spec §1).
    public static let maxTrueCountMagnitude = 10.0

    /// Decks-remaining step: quarter decks for 1–2 decks, half decks otherwise (Step 4 spec §1).
    public static func trueCountStep(deckCount: Int) -> Double {
        deckCount <= 2 ? 0.25 : 0.5
    }

    /// Decks remaining in `trueCountStep` steps from one step to `deckCount` minus one step.
    /// Running count in -12...12, redrawn until |RC ÷ decks remaining| ≤ `maxTrueCountMagnitude`
    /// (RC 0 always qualifies, so this terminates).
    public static func trueCountQuestion<G: RandomNumberGenerator>(
        deckCount: Int, using rng: inout G
    ) -> TrueCountQuestion {
        let step = trueCountStep(deckCount: deckCount)
        let stepsPerDeck = Int((1 / step).rounded())
        let maxSteps = max(1, max(1, deckCount) * stepsPerDeck - 1)
        let decksRemaining = Double(Int.random(in: 1...maxSteps, using: &rng)) * step
        var rc: Int
        repeat {
            rc = Int.random(in: -12...12, using: &rng)
        } while abs(Double(rc) / decksRemaining) > maxTrueCountMagnitude + 1e-9
        return TrueCountQuestion(runningCount: rc, decksRemaining: decksRemaining)
    }
}

import Testing
@testable import BJSCore

// A,A (soft 12) and 2,2 (hard 4) have no row of their own in the soft/hard tables.
// When splitting is not legal (max split hands reached, no resplit aces) the lookup
// used to clamp them into soft 13 / hard 5, so unsplittable A,A doubled vs 5 and 6
// (the soft 13 row) and unsplittable 2,2 took hard 5's early-surrender play.
//
// Asserted plays are hit wherever it is robust. Soft 12 vs 6 is left out: an exact
// composition-dependent calculation puts double ahead of hit there in every game
// (by 0.001-0.05 units), and the engine doubles it under H17 and at one deck. Soft 12
// vs 5 at one and two decks is also a double on that calculation and is left out.

private func hand(_ a: Rank, _ b: Rank) -> BlackjackHand {
    BlackjackHand(cards: [Card(rank: a, suit: .clubs), Card(rank: b, suit: .hearts)])
}

private let allUpcards: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .ace]
private let noSplit: Set<Action> = [.hit, .stand, .double, .surrender]

struct NoSurrenderConfig: Sendable, CustomTestStringConvertible {
    let decks: BlackjackRules.DeckCount
    let soft17: BlackjackRules.DealerSoft17
    let peek: BlackjackRules.PeekRule
    var rules: BlackjackRules {
        var r = BlackjackRules()
        r.deckCount = decks
        r.dealerSoft17 = soft17
        r.peekRule = peek
        r.surrenderRule = .none
        return r
    }
    var testDescription: String { "\(decks.rawValue)D \(soft17) \(peek)" }
}

private let configs: [NoSurrenderConfig] = BlackjackRules.DeckCount.allCases.flatMap { d in
    BlackjackRules.DealerSoft17.allCases.flatMap { s in
        BlackjackRules.PeekRule.allCases.map { NoSurrenderConfig(decks: d, soft17: s, peek: $0) }
    }
}

@Suite("Unsplittable A,A and 2,2 lookup")
struct UnsplittablePairTests {

    @Test("Unsplittable A,A (soft 12) hits against 2-4 and 7-A", arguments: configs)
    func acesHit(config: NoSurrenderConfig) {
        let t = StrategyEngine().strategy(for: config.rules)
        for up in allUpcards where up != .five && up != .six {
            #expect(t.action(for: hand(.ace, .ace), dealerUpcard: up, legal: noSplit) == .hit, "A,A vs \(up)")
        }
    }

    @Test("Unsplittable A,A vs 5 hits at 4+ decks", arguments: configs.filter { $0.decks.rawValue >= 4 })
    func acesVsFiveHit(config: NoSurrenderConfig) {
        let t = StrategyEngine().strategy(for: config.rules)
        #expect(t.action(for: hand(.ace, .ace), dealerUpcard: .five, legal: noSplit) == .hit)
    }

    @Test("Unsplittable A,A vs 5/6 only ever hits or doubles", arguments: configs)
    func acesVsFiveSixHitOrDouble(config: NoSurrenderConfig) {
        let t = StrategyEngine().strategy(for: config.rules)
        for up in [Rank.five, .six] {
            let a = t.action(for: hand(.ace, .ace), dealerUpcard: up, legal: noSplit)
            #expect(a == .hit || a == .double, "A,A vs \(up): \(a)")
            // Without double (e.g. no double on soft hands) it hits.
            #expect(t.action(for: hand(.ace, .ace), dealerUpcard: up, legal: [.hit, .stand]) == .hit)
        }
    }

    @Test("Unsplittable 2,2 (hard 4) hits against every upcard", arguments: configs)
    func twosHit(config: NoSurrenderConfig) {
        let t = StrategyEngine().strategy(for: config.rules)
        for up in allUpcards {
            #expect(t.action(for: hand(.two, .two), dealerUpcard: up, legal: noSplit) == .hit, "2,2 vs \(up)")
        }
    }

    @Test("A,A vs 5 does not take the soft 13 double when split is illegal (6D S17 regression)")
    func acesVsFiveRegression() {
        let t = StrategyEngine().strategy(for: BlackjackRules())
        #expect(t.action(for: hand(.ace, .ace), dealerUpcard: .five, legal: [.hit, .stand, .double]) == .hit)
    }

    @Test("Split still wins when legal")
    func splitWhenLegal() {
        let t = StrategyEngine().strategy(for: BlackjackRules())
        #expect(t.action(for: hand(.ace, .ace), dealerUpcard: .six, legal: noSplit.union([.split])) == .split)
        #expect(t.action(for: hand(.two, .two), dealerUpcard: .six, legal: noSplit.union([.split])) == .split)
    }

    @Test("6D S17 early surrender: unsplittable 2,2 vs A hits (WoO ES surrenders 3,3 but not 2,2)")
    func twosVsAceEarlySurrenderS17() {
        var r = BlackjackRules()
        r.surrenderRule = .early
        let t = StrategyEngine().strategy(for: r)
        #expect(t.action(for: hand(.two, .two), dealerUpcard: .ace, legal: noSplit) == .hit)
        #expect(t.action(for: hand(.ace, .ace), dealerUpcard: .ace, legal: noSplit) == .hit)
    }
}

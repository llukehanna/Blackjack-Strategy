import Testing
@testable import BJSCore

struct WhyContextSpotTests {

    func card(_ r: Rank, _ s: Suit = .spades) -> Card { Card(rank: r, suit: s) }
    func spot(_ ranks: [Rank], up: Rank, legal: Set<Action>) -> DecisionSpot {
        DecisionSpot(hand: BlackjackHand(cards: ranks.enumerated().map { card($1, Suit.allCases[$0 % 4]) }),
                     dealerUpcard: up, legalActions: legal)
    }
    func context(_ s: DecisionSpot, rules: BlackjackRules = BlackjackRules(), user: Action? = .stand) -> WhyContext {
        WhyContext(spot: s, userAction: user, table: StrategyEngine().strategy(for: rules), rules: rules)
    }

    @Test("A pair is a pair only while split is legal")
    func pairRow() {
        let splittable = context(spot([.eight, .eight], up: .six, legal: [.hit, .stand, .double, .split]))
        #expect(splittable.handType == .pair)
        #expect(splittable.pairRank == .eight)
        #expect(splittable.correctAction == .split)
        let unsplittable = context(spot([.eight, .eight], up: .six, legal: [.hit, .stand, .double]))
        #expect(unsplittable.handType == .hard)
        #expect(unsplittable.handTotal == 16)
        #expect(unsplittable.pairRank == nil)
    }

    @Test("A three-card soft 18 vs 6 records double as the preferred-but-illegal play")
    func preferredIllegalDouble() {
        let c = context(spot([.ace, .four, .three], up: .six, legal: [.hit, .stand]))
        #expect(c.handType == .soft)
        #expect(c.correctAction == .stand)
        #expect(c.preferredIllegal == .double)
        #expect(WhyExplanation.explain(c).hasPrefix("Doubling would be best"))
    }

    @Test("No preferredIllegal when the first preference is legal")
    func noPreferredIllegal() {
        #expect(context(spot([.ten, .six], up: .ten, legal: [.hit, .stand, .double])).preferredIllegal == nil)
    }

    @Test("SurrenderContext follows surrender and peek rules")
    func surrenderContext() {
        var r = BlackjackRules()
        #expect(SurrenderContext(rules: r) == nil)
        r.surrenderRule = .late
        #expect(SurrenderContext(rules: r) == .late)
        r.surrenderRule = .early
        #expect(SurrenderContext(rules: r) == .early)
        r.peekRule = .europeanNoPeek
        #expect(SurrenderContext(rules: r) == .noHoleCard)
        r.surrenderRule = .late
        #expect(SurrenderContext(rules: r) == .noHoleCard)
    }

    @Test("Early surrender of hard 5 vs A explains surrendering before the peek")
    func earlySurrenderReason() {
        var r = BlackjackRules()
        r.surrenderRule = .early
        let c = context(spot([.two, .three], up: .ace, legal: [.hit, .stand, .double, .surrender]), rules: r)
        #expect(c.correctAction == .surrender)
        #expect(WhyExplanation.explain(c).contains("before the dealer checks for blackjack"))
    }

    @Test("No-hole-card surrender explains the later dealer blackjack")
    func noHoleCardReason() {
        var r = BlackjackRules()
        r.surrenderRule = .late
        r.peekRule = .europeanNoPeek
        let c = context(spot([.ten, .six], up: .ten, legal: [.hit, .stand, .double, .surrender]), rules: r)
        #expect(c.correctAction == .surrender)
        #expect(WhyExplanation.explain(c).contains("no hole card"))
    }

    @Test("The hard 14 vs 10 composition note names the deck-specific cards")
    func compositionNote() {
        var r = BlackjackRules()
        r.deckCount = .one
        r.surrenderRule = .early
        let c = context(spot([.ten, .four], up: .ten, legal: [.hit, .stand, .double, .surrender]), rules: r)
        #expect(c.compositionNote)
        #expect(c.correctAction == .hit)
        #expect(WhyExplanation.explain(c).contains("surrender 8+6"))
    }

    @Test("A timeout context has no user action")
    func timeout() {
        #expect(context(spot([.ten, .six], up: .ten, legal: [.hit, .stand]), user: nil).userAction == nil)
    }

    @Test("Every two-card spot under several rule sets explains within 30..<400 characters, ending in a full stop")
    func bounds() {
        var ruleSets: [BlackjackRules] = [BlackjackRules()]
        for (decks, surrender, peek) in [(BlackjackRules.DeckCount.one, BlackjackRules.SurrenderRule.early, BlackjackRules.PeekRule.americanPeek),
                                         (.two, .early, .americanPeek), (.six, .late, .europeanNoPeek),
                                         (.eight, .late, .americanPeek)] {
            var r = BlackjackRules()
            r.deckCount = decks
            r.surrenderRule = surrender
            r.peekRule = peek
            r.doubleRestriction = .tenToEleven
            ruleSets.append(r)
        }
        for rules in ruleSets {
            let table = StrategyEngine().strategy(for: rules)
            for first in Rank.allCases { for second in Rank.allCases { for up in Rank.allCases {
                let hand = BlackjackHand(cards: [card(first, .spades), card(second, .hearts)])
                guard !hand.isBlackjack else { continue }
                var legal: Set<Action> = [.hit, .stand]
                if hand.canDouble(rules: rules) { legal.insert(.double) }
                if hand.isPair { legal.insert(.split) }
                if rules.surrenderRule != .none { legal.insert(.surrender) }
                let c = WhyContext(spot: DecisionSpot(hand: hand, dealerUpcard: up, legalActions: legal),
                                   userAction: .hit, table: table, rules: rules)
                let text = WhyExplanation.explain(c)
                #expect((30..<400).contains(text.count), "\(text.count): \(text)")
                #expect(text.hasSuffix(".") || text.hasSuffix("!"), "\(text)")
            } } }
        }
    }
}

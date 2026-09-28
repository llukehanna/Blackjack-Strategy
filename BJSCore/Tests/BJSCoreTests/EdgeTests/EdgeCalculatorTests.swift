import Testing
@testable import BJSCore

/// A rule set and WoO's "basic strategy with cut card" house edge for it (Step 5 spec §2).
struct EdgeReference: Sendable, CustomTestStringConvertible {
    let label: String
    let expected: Double
    let rules: BlackjackRules

    var testDescription: String { label }

    init(_ label: String, _ expected: Double, _ configure: (inout BlackjackRules) -> Void = { _ in }) {
        var rules = BlackjackRules()
        configure(&rules)
        self.label = label
        self.expected = expected
        self.rules = rules
    }
}

let wooEdgeReferences: [EdgeReference] = [
    EdgeReference("6D", 0.42622),
    EdgeReference("6D H17", 0.63873) { $0.dealerSoft17 = .hits },
    EdgeReference("6D LS", 0.35361) { $0.surrenderRule = .late },
    EdgeReference("8D", 0.44686) { $0.deckCount = .eight },
    EdgeReference("1D H17", 0.15945) { $0.deckCount = .one; $0.dealerSoft17 = .hits },
    EdgeReference("1D H17 NDAS D9-11 2 hands", 0.46612) {
        $0.deckCount = .one; $0.dealerSoft17 = .hits; $0.doubleAfterSplit = false
        $0.doubleRestriction = .nineToEleven; $0.maxSplitHands = 2
    },
    EdgeReference("1D H17 6:5", 1.55422) { $0.deckCount = .one; $0.dealerSoft17 = .hits; $0.blackjackPayout = .sixToFive },
    EdgeReference("2D H17", 0.45688) { $0.deckCount = .two; $0.dealerSoft17 = .hits },
    EdgeReference("6D LS RSA", 0.28507) { $0.surrenderRule = .late; $0.resplitAces = true },
    EdgeReference("8D H17 LS", 0.56926) { $0.deckCount = .eight; $0.dealerSoft17 = .hits; $0.surrenderRule = .late },
    EdgeReference("4D NDAS D9-11 3 hands", 0.62718) {
        $0.deckCount = .four; $0.doubleAfterSplit = false; $0.doubleRestriction = .nineToEleven; $0.maxSplitHands = 3
    },
    EdgeReference("6D 6:5", 1.78591) { $0.blackjackPayout = .sixToFive },
    EdgeReference("1D", -0.03119) { $0.deckCount = .one },
    EdgeReference("2D", 0.25532) { $0.deckCount = .two },
    EdgeReference("4D", 0.38699) { $0.deckCount = .four },
    EdgeReference("6D NDAS", 0.56799) { $0.doubleAfterSplit = false },
    EdgeReference("6D hit split aces", 0.23881) { $0.hitSplitAces = true },
    EdgeReference("6D D10-11", 0.61830) { $0.doubleRestriction = .tenToEleven },
    EdgeReference("6D D9-11", 0.52232) { $0.doubleRestriction = .nineToEleven },
    EdgeReference("6D 2 hands", 0.47999) { $0.maxSplitHands = 2 },
    EdgeReference("6D 3 hands", 0.43486) { $0.maxSplitHands = 3 },
    EdgeReference("6D no hole card", 0.53727) { $0.peekRule = .europeanNoPeek },
    EdgeReference("6D RSA", 0.35767) { $0.resplitAces = true },
    EdgeReference("2D H17 LS", 0.39072) { $0.deckCount = .two; $0.dealerSoft17 = .hits; $0.surrenderRule = .late },
    EdgeReference("8D LS", 0.37104) { $0.deckCount = .eight; $0.surrenderRule = .late },
    EdgeReference("1D H17 NDAS 6:5", 1.69824) {
        $0.deckCount = .one; $0.dealerSoft17 = .hits; $0.doubleAfterSplit = false; $0.blackjackPayout = .sixToFive
    },
    EdgeReference("1D NDAS", 0.11008) { $0.deckCount = .one; $0.doubleAfterSplit = false },
    EdgeReference("2D NDAS D10-11", 0.60446) {
        $0.deckCount = .two; $0.doubleAfterSplit = false; $0.doubleRestriction = .tenToEleven
    },
    EdgeReference("8D 6:5", 1.80485) { $0.deckCount = .eight; $0.blackjackPayout = .sixToFive },
    EdgeReference("1D 6:5", 1.36358) { $0.deckCount = .one; $0.blackjackPayout = .sixToFive },
    EdgeReference("8D no hole card", 0.55853) { $0.deckCount = .eight; $0.peekRule = .europeanNoPeek },
    EdgeReference("6D H17 no hole card", 0.75015) { $0.dealerSoft17 = .hits; $0.peekRule = .europeanNoPeek },
    EdgeReference("1D RSA hit split aces", -0.19917) { $0.deckCount = .one; $0.resplitAces = true; $0.hitSplitAces = true },
    EdgeReference("2D NDAS D10-11 2 hands", 0.63191) {
        $0.deckCount = .two; $0.doubleAfterSplit = false; $0.doubleRestriction = .tenToEleven; $0.maxSplitHands = 2
    },
    EdgeReference("4D H17 LS RSA", 0.45042) {
        $0.deckCount = .four; $0.dealerSoft17 = .hits; $0.surrenderRule = .late; $0.resplitAces = true
    },
    EdgeReference("8D H17 NDAS D10-11 2 hands 6:5", 2.37443) {
        $0.deckCount = .eight; $0.dealerSoft17 = .hits; $0.doubleAfterSplit = false
        $0.doubleRestriction = .tenToEleven; $0.maxSplitHands = 2; $0.blackjackPayout = .sixToFive
    },
    EdgeReference("6D H17 LS", 0.55051) { $0.dealerSoft17 = .hits; $0.surrenderRule = .late },
    EdgeReference("1D H17 LS", 0.12144) { $0.deckCount = .one; $0.dealerSoft17 = .hits; $0.surrenderRule = .late },
]

@Suite("EdgeCalculator")
struct EdgeCalculatorTests {
    let calculator = EdgeCalculator()

    @Test("Matches WoO's calculator (basic strategy, cut card)", arguments: wooEdgeReferences)
    func matchesWizardOfOdds(_ reference: EdgeReference) {
        // WoO rounds to 5 decimals; the table stores those same rounded values.
        #expect(abs(calculator.houseEdge(for: reference.rules) - reference.expected) <= 0.00001)
    }

    @Test("There are at least 20 reference combinations")
    func referenceCount() {
        #expect(wooEdgeReferences.count >= 20)
    }

    @Test("Table index is a bijection onto the WoO data")
    func tableIndexBijection() {
        var seen = Set<Int>()
        for deckCount in BlackjackRules.DeckCount.allCases {
            for soft17 in BlackjackRules.DealerSoft17.allCases {
                for das in [false, true] {
                    for restriction in BlackjackRules.DoubleRestriction.allCases {
                        for hands in 2...4 {
                            for rsa in [false, true] {
                                for hsa in [false, true] {
                                    for peek in BlackjackRules.PeekRule.allCases {
                                        var rules = BlackjackRules()
                                        rules.deckCount = deckCount
                                        rules.dealerSoft17 = soft17
                                        rules.doubleAfterSplit = das
                                        rules.doubleRestriction = restriction
                                        rules.maxSplitHands = hands
                                        rules.resplitAces = rsa
                                        rules.hitSplitAces = hsa
                                        rules.peekRule = peek
                                        for late in [false, true] {
                                            for sixToFive in [false, true] {
                                                seen.insert(EdgeCalculator.tableIndex(
                                                    rules, lateSurrender: late, sixToFive: sixToFive))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        #expect(seen.count == WoOEdgeData.cutCard.count)
        #expect(seen.min() == 0)
        #expect(seen.max() == WoOEdgeData.cutCard.count - 1)
    }

    @Test("2:1 sits 5/3 of the 6:5 gap on the other side of 3:2")
    func twoToOne() {
        var eight = BlackjackRules()
        eight.deckCount = .eight
        let threeToTwo = calculator.houseEdge(for: eight)
        eight.blackjackPayout = .twoToOne
        // WoO rule variations (8 decks): blackjack pays 2 to 1, +2.27% for the player.
        #expect(abs((calculator.houseEdge(for: eight) - threeToTwo) - (-2.27)) < 0.01)

        var one = BlackjackRules()
        one.deckCount = .one
        one.blackjackPayout = .twoToOne
        let expected = -0.03119 - 5.0 / 3.0 * (1.36358 - (-0.03119))
        #expect(abs(calculator.houseEdge(for: one) - expected) < 1e-9)
    }

    @Test("Early surrender is the no-surrender edge less 0.63", arguments: BlackjackRules.DeckCount.allCases)
    func earlySurrender(_ deckCount: BlackjackRules.DeckCount) {
        var rules = BlackjackRules()
        rules.deckCount = deckCount
        let none = calculator.houseEdge(for: rules)
        rules.surrenderRule = .early
        #expect(abs(calculator.houseEdge(for: rules) - (none - 0.63)) < 1e-9)
    }

    @Test("Under no hole card, late surrender is priced as early")
    func noHoleCardLateSurrender() {
        var rules = BlackjackRules()
        rules.peekRule = .europeanNoPeek
        rules.surrenderRule = .late
        let late = calculator.analyze(rules: rules)
        #expect(abs(late.houseEdge - (0.53727 - 0.63)) < 1e-9)
        #expect(late.contributions.last?.factor == .surrender(.late, pricedAsEarly: true))

        rules.surrenderRule = .early
        #expect(abs(calculator.houseEdge(for: rules) - late.houseEdge) < 1e-9)
        #expect(calculator.analyze(rules: rules).contributions.last?.factor == .surrender(.early, pricedAsEarly: false))

        var peek = BlackjackRules()
        peek.surrenderRule = .late
        #expect(calculator.analyze(rules: peek).contributions.last?.factor == .surrender(.late, pricedAsEarly: false))
    }

    @Test("Baseline is WoO's 8-deck game with no contributions")
    func baseline() {
        #expect(EdgeCalculator.baselineRules.deckCount == .eight)
        var expected = BlackjackRules()
        expected.deckCount = .eight
        #expect(EdgeCalculator.baselineRules == expected)
        #expect(abs(EdgeCalculator.baselineHouseEdge - 0.44686) < 1e-9)
        #expect(calculator.analyze(rules: EdgeCalculator.baselineRules).contributions.isEmpty)
    }

    @Test("Downtown Vegas: each step is the table difference, in order")
    func attributionDowntown() {
        let result = calculator.analyze(rules: RulePreset.downtownVegas.rules)  // 2D H17 DAS LS 3:2
        #expect(result.contributions.map(\.factor) == [.decks(.two), .dealerHitsSoft17,
                                                       .surrender(.late, pricedAsEarly: false)])
        let changes = result.contributions.map(\.edgeChange)
        #expect(abs(changes[0] - (0.25532 - 0.44686)) < 1e-9)
        #expect(abs(changes[1] - (0.45688 - 0.25532)) < 1e-9)
        #expect(abs(changes[2] - (0.39072 - 0.45688)) < 1e-9)
    }

    @Test("Single Deck 6:5: payout comes before DAS")
    func attributionSingleDeck() {
        let result = calculator.analyze(rules: RulePreset.singleDeckSixFive.rules)  // 1D H17 NDAS 6:5
        #expect(result.contributions.map(\.factor) == [.decks(.one), .dealerHitsSoft17,
                                                       .payout(.sixToFive), .noDoubleAfterSplit])
        let changes = result.contributions.map(\.edgeChange)
        #expect(abs(changes[0] - (-0.03119 - 0.44686)) < 1e-9)
        #expect(abs(changes[1] - (0.15945 - -0.03119)) < 1e-9)
        #expect(abs(changes[2] - (1.55422 - 0.15945)) < 1e-9)
        #expect(abs(changes[3] - (1.69824 - 1.55422)) < 1e-9)
    }

    @Test("Every factor appears in attribution order")
    func attributionOrder() {
        var rules = BlackjackRules()
        rules.deckCount = .two
        rules.dealerSoft17 = .hits
        rules.blackjackPayout = .twoToOne
        rules.doubleAfterSplit = false
        rules.doubleRestriction = .tenToEleven
        rules.maxSplitHands = 3
        rules.resplitAces = true
        rules.hitSplitAces = true
        rules.peekRule = .europeanNoPeek
        rules.surrenderRule = .late
        let result = calculator.analyze(rules: rules)
        #expect(result.contributions.map(\.factor) == [
            .decks(.two), .dealerHitsSoft17, .payout(.twoToOne), .noDoubleAfterSplit,
            .doubleRestriction(.tenToEleven), .maxSplitHands(3), .resplitAces, .hitSplitAces,
            .noHoleCard, .surrender(.late, pricedAsEarly: true),
        ])
        let sum = result.contributions.reduce(0) { $0 + $1.edgeChange }
        #expect(abs(EdgeCalculator.baselineHouseEdge + sum - result.houseEdge) < 1e-9)
    }

    @Test("Contributions sum to the headline for every preset", arguments: RulePreset.allCases)
    func contributionsSum(_ preset: RulePreset) {
        let result = calculator.analyze(rules: preset.rules)
        let sum = result.contributions.reduce(0) { $0 + $1.edgeChange }
        #expect(abs(EdgeCalculator.baselineHouseEdge + sum - result.houseEdge) < 1e-9)
        #expect(result.houseEdge == calculator.houseEdge(for: preset.rules))
    }
}

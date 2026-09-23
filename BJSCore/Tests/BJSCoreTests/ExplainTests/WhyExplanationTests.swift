import Testing
import Foundation
@testable import BJSCore

struct WhyExplanationTests {

    // MARK: - Helpers

    private static let rules = BlackjackRules()

    private func ctx(
        total: Int,
        type: HandType,
        pair: Rank? = nil,
        up: Rank,
        user: Action,
        correct: Action
    ) -> WhyContext {
        WhyContext(
            handTotal: total,
            handType: type,
            pairRank: pair,
            dealerUpCard: up,
            userAction: user,
            correctAction: correct,
            rules: Self.rules
        )
    }

    // MARK: - Targeted scenario coverage (the four pinned in the plan + extras)

    struct Scenario: Sendable {
        let name: String
        let context: WhyContext
        let mustContain: [String]
    }

    static let scenarios: [Scenario] = {
        let r = BlackjackRules()
        return [
            Scenario(
                name: "hard 16 vs 10 STAND",
                context: WhyContext(handTotal: 16, handType: .hard, dealerUpCard: .ten,
                                    userAction: .hit, correctAction: .stand, rules: r),
                mustContain: ["16", "10"]
            ),
            Scenario(
                name: "soft 18 vs 9 HIT",
                context: WhyContext(handTotal: 18, handType: .soft, dealerUpCard: .nine,
                                    userAction: .stand, correctAction: .hit, rules: r),
                mustContain: ["Soft 18", "9"]
            ),
            Scenario(
                name: "pair of 8s vs 7 SPLIT",
                context: WhyContext(handTotal: 16, handType: .pair, pairRank: .eight, dealerUpCard: .seven,
                                    userAction: .stand, correctAction: .split, rules: r),
                mustContain: ["8s", "16"]
            ),
            Scenario(
                name: "hard 11 vs 6 DOUBLE",
                context: WhyContext(handTotal: 11, handType: .hard, dealerUpCard: .six,
                                    userAction: .hit, correctAction: .double, rules: r),
                mustContain: ["doubling", "6"]
            ),
            Scenario(
                name: "pair of 10s vs 6 STAND",
                context: WhyContext(handTotal: 20, handType: .pair, pairRank: .ten, dealerUpCard: .six,
                                    userAction: .split, correctAction: .stand, rules: r),
                mustContain: ["20"]
            ),
            Scenario(
                name: "pair of Aces vs 5 SPLIT",
                context: WhyContext(handTotal: 12, handType: .pair, pairRank: .ace, dealerUpCard: .five,
                                    userAction: .stand, correctAction: .split, rules: r),
                mustContain: ["Aces"]
            ),
            Scenario(
                name: "hard 9 vs 3 DOUBLE",
                context: WhyContext(handTotal: 9, handType: .hard, dealerUpCard: .three,
                                    userAction: .hit, correctAction: .double, rules: r),
                mustContain: ["9", "3"]
            ),
            Scenario(
                name: "soft 20 vs 5 STAND",
                context: WhyContext(handTotal: 20, handType: .soft, dealerUpCard: .five,
                                    userAction: .hit, correctAction: .stand, rules: r),
                mustContain: ["Soft 20"]
            ),
        ]
    }()

    @Test(arguments: scenarios)
    func explainHitsExpectedSubstrings(_ scenario: Scenario) {
        let result = WhyExplanation.explain(scenario.context)
        for fragment in scenario.mustContain {
            #expect(
                result.contains(fragment),
                "Scenario \(scenario.name): expected '\(fragment)' in: \(result)"
            )
        }
        #expect(result.count >= 30, "Scenario \(scenario.name): too short (\(result.count)): \(result)")
        #expect(result.count < 400, "Scenario \(scenario.name): too long (\(result.count))")
    }

    // MARK: - Smoke test: every (handType, action) combo returns a bounded non-empty string

    @Test
    func explainCoversAllHandTypeActionCombinations() {
        let rules = BlackjackRules()
        let totalsByType: [HandType: [Int]] = [
            .hard: [5, 9, 11, 12, 14, 16, 17, 19],
            .soft: [13, 15, 17, 18, 19, 20],
            .pair: [4, 12, 16, 20]
        ]
        let dealerUpcards: [Rank] = [.two, .four, .six, .seven, .nine, .ten, .ace]
        let pairRanks: [Rank] = [.two, .seven, .eight, .nine, .ten, .ace]

        for handType in [HandType.hard, .soft, .pair] {
            for total in totalsByType[handType] ?? [] {
                for up in dealerUpcards {
                    for action in Action.allCases {
                        let pair: Rank? = (handType == .pair) ? pairRanks.randomElement() : nil
                        let context = WhyContext(
                            handTotal: total,
                            handType: handType,
                            pairRank: pair,
                            dealerUpCard: up,
                            userAction: .hit,
                            correctAction: action,
                            rules: rules
                        )
                        let result = WhyExplanation.explain(context)
                        #expect(!result.isEmpty, "empty for \(handType) total=\(total) up=\(up) action=\(action)")
                        #expect(result.count >= 30, "too short for \(handType)/\(action): \(result)")
                        #expect(result.count < 400, "too long for \(handType)/\(action)")
                    }
                }
            }
        }
    }
}

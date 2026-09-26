import Testing
import BJSCore
@testable import BJS

@MainActor
struct StrategyTextTests {

    func context(total: Int, type: HandType, pair: Rank? = nil, up: Rank) -> WhyContext {
        WhyContext(handTotal: total, handType: type, pairRank: pair, dealerUpCard: up,
                   userAction: .hit, correctAction: .stand, rules: BlackjackRules())
    }

    @Test("Hand labels")
    func labels() {
        #expect(StrategyText.handLabel(context(total: 16, type: .hard, up: .king)) == "Hard 16 vs 10")
        #expect(StrategyText.handLabel(context(total: 18, type: .soft, up: .ace)) == "Soft 18 vs A")
        #expect(StrategyText.handLabel(context(total: 16, type: .pair, pair: .eight, up: .six)) == "Pair of 8s vs 6")
        #expect(StrategyText.handLabel(context(total: 12, type: .pair, pair: .ace, up: .two)) == "Pair of Aces vs 2")
        #expect(StrategyText.handLabel(context(total: 20, type: .pair, pair: .king, up: .two)) == "Pair of 10s vs 2")
    }

    @Test("Action names")
    func actionNames() {
        #expect(Action.allCases.map(StrategyText.actionName) == ["Hit", "Stand", "Double", "Split", "Surrender"])
    }

    @Test("Feedback text for correct, wrong and timeout")
    func feedback() {
        let right = StrategyText.feedback(isCorrect: true, chosen: .action(.stand), correct: .stand, label: "Hard 17 vs 10")
        #expect(right.headline == "Correct: Stand")
        #expect(right.reason == "Hard 17 vs 10")
        let wrong = StrategyText.feedback(isCorrect: false, chosen: .action(.stand), correct: .hit, label: "Hard 16 vs 10")
        #expect(wrong.headline == "The play is Hit")
        #expect(wrong.reason == "You chose Stand on hard 16 vs 10.")
        let late = StrategyText.feedback(isCorrect: false, chosen: .timeout, correct: .hit, label: "Hard 16 vs 10")
        #expect(late.headline == "Time's up")
        #expect(late.reason == "The play was Hit on hard 16 vs 10.")
    }

    @Test("Signed units use a true minus sign and trim zeros")
    func units() {
        #expect(StrategyText.signedUnits(1) == "+1")
        #expect(StrategyText.signedUnits(1.5) == "+1.5")
        #expect(StrategyText.signedUnits(-2) == "−2")
        #expect(StrategyText.signedUnits(-0.5) == "−0.5")
        #expect(StrategyText.signedUnits(0) == "±0")
    }

    @Test("Percent text")
    func percent() {
        #expect(PercentText.text(nil) == "—")
        #expect(PercentText.text(2.0 / 3.0) == "67%")
    }
}

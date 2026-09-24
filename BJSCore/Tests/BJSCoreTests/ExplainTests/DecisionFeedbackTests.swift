import Foundation
import Testing
@testable import BJSCore

@Suite("DecisionFeedback")
struct DecisionFeedbackTests {

    private func decision(_ ranks: [Rank], up: Rank, choice: DecisionChoice, correct: Action,
                          legal: Set<Action> = [.hit, .stand, .double, .split]) -> GradedDecision {
        GradedDecision(sequence: 1, handNumber: 1, spot: makeSpot(ranks, up: up, legal: legal), choice: choice,
                       correctAction: correct, responseMs: nil, decidedAt: Date(timeIntervalSinceReferenceDate: 0))
    }

    @Test("Hand, upcard and spot names")
    func names() {
        #expect(DecisionFeedback.handName(TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 7)) == "Hard 16")
        #expect(DecisionFeedback.handName(TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 7)) == "Soft 18")
        #expect(DecisionFeedback.handName(TrainingCell(handType: .pair, playerValue: 8, dealerUpcard: 7)) == "Pair of 8s")
        #expect(DecisionFeedback.handName(TrainingCell(handType: .pair, playerValue: 11, dealerUpcard: 7)) == "Pair of Aces")
        #expect(DecisionFeedback.spotTitle(TrainingCell(handType: .pair, playerValue: 10, dealerUpcard: 11)) == "Pair of 10s vs Ace")
        #expect(DecisionFeedback.actionName(.surrender) == "Surrender")
        #expect(DecisionFeedback.choiceName(.timeout) == "Timeout")
        #expect(DecisionFeedback.choiceName(.action(.double)) == "Double")
    }

    @Test("Correct decision")
    func correct() {
        let d = decision([.ten, .six], up: .seven, choice: .action(.hit), correct: .hit)
        #expect(DecisionFeedback.headline(for: d) == "Correct: Hit")
        #expect(DecisionFeedback.reason(for: d) == "Basic strategy hits hard 16 against a 7.")
    }

    @Test("Incorrect decision names the choice and the play")
    func incorrect() {
        let d = decision([.eight, .eight], up: .ace, choice: .action(.hit), correct: .split)
        #expect(DecisionFeedback.headline(for: d) == "The play is Split")
        #expect(DecisionFeedback.reason(for: d) == "You chose Hit. Basic strategy splits a pair of 8s against an Ace.")
    }

    @Test("Timeout")
    func timeout() {
        let d = decision([.ace, .seven], up: .eight, choice: .timeout, correct: .stand)
        #expect(DecisionFeedback.headline(for: d) == "Time's up: Stand")
        #expect(DecisionFeedback.reason(for: d) == "No action in time. Basic strategy stands on soft 18 against an 8.")
    }

    @Test("WHY title matches the decision's spot title")
    func whyTitle() {
        let cases: [([Rank], Rank, Set<Action>, String)] = [
            ([.king, .king], .ace, [.hit, .stand, .split], "Pair of 10s vs Ace"),
            ([.ace, .ace], .six, [.hit, .stand], "Soft 12 vs 6"),
            ([.ten, .two, .four], .ten, [.hit, .stand], "Hard 16 vs 10"),
        ]
        for (ranks, up, legal, expected) in cases {
            let d = decision(ranks, up: up, choice: .action(.stand), correct: .stand, legal: legal)
            #expect(DecisionFeedback.spotTitle(d.whyContext(rules: BlackjackRules())) == expected)
            #expect(DecisionFeedback.spotTitle(d.cell) == expected)
        }
    }
}

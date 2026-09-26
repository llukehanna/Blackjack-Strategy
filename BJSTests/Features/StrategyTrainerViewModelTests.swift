import Foundation
import Testing
import BJSCore
@testable import BJS

/// Hands out pre-built shoes in order; records the cells the trainer asked for.
@MainActor
final class ScriptedShoes {
    var shoes: [[Card]]
    var requestedCells: [TrainingCell] = []
    init(_ shoes: [[Card]]) { self.shoes = shoes }

    var maker: StrategyTrainerViewModel.ShoeMaker {
        { [self] cell, _, _ in
            requestedCells.append(cell)
            // After the script runs out, repeat the last shoe.
            let cards = shoes.count > 1 ? shoes.removeFirst() : shoes[0]
            return Shoe(orderedCards: cards)
        }
    }
}

func trainerCard(_ rank: Rank, _ suit: Suit = .spades) -> Card { Card(rank: rank, suit: suit) }

/// RoundEngine deal order: P1, upcard, P2, hole, then draws.
func shoe(player: (Rank, Rank), up: Rank, hole: Rank, draws: [Rank] = []) -> [Card] {
    [trainerCard(player.0, .spades), trainerCard(up, .hearts), trainerCard(player.1, .clubs), trainerCard(hole, .diamonds)]
        + draws.map { trainerCard($0, .spades) } + Array(repeating: trainerCard(.ten, .clubs), count: 20)
}

@MainActor
struct StrategyTrainerViewModelTests {

    func trainer(_ shoes: ScriptedShoes, mode: StrategyMode = .test, length: StrategyLength = .hands(25),
                 rules: BlackjackRules = BlackjackRules(), limit: Int? = nil,
                 weights: [TrainingCell: Double]? = nil, filter: HandFilter = .all,
                 now: @escaping () -> Date = { Date(timeIntervalSince1970: 1000) }) -> StrategyTrainerViewModel {
        StrategyTrainerViewModel(setup: StrategySetup(mode: mode, length: length, filter: filter), rules: rules,
                                 weights: weights, speedTimerSeconds: 3, handLimitOverride: limit, seed: 1,
                                 now: now, makeShoe: shoes.maker, persist: { _ in })
    }

    @Test("The first hand is dealt on init and awaits a decision")
    func dealsOnInit() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven)]))
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.handNumber == 1)
        #expect(vm.playerHands.count == 1)
        #expect(vm.dealerCards.count == 2)
        #expect(!vm.isDealerRevealed)
        #expect(vm.legalActions.contains(.stand))
    }

    @Test("A wrong STAND shows feedback, and NEXT reveals the dealer")
    func wrongStand() throws {
        // Hard 16 vs 10, 6D S17 no surrender: correct play is hit. Dealer 10+7 = 17, no draw.
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven)]))
        vm.choose(.stand)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(!graded.isCorrect)
        #expect(graded.correctAction == .hit)
        #expect(graded.chosen == .action(.stand))
        #expect(vm.dealerCards.count == 2)
        vm.next()
        #expect(vm.phase == .outcome)
        #expect(vm.isDealerRevealed)
        #expect(vm.outcomeLines == ["Dealer 17", "Lose −1"])
    }

    @Test("A correct STAND still shows feedback before the outcome")
    func correctStand() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight)]))
        vm.choose(.stand)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect)
        #expect(vm.toastCount == 0)
    }

    @Test("A correct hit that keeps the hand going shows a toast, not feedback")
    func correctHitToast() {
        // Hard 9 vs 7 → hit; draws a 2 → hard 11, still deciding.
        let vm = trainer(ScriptedShoes([shoe(player: (.five, .four), up: .seven, hole: .ten, draws: [.two])]))
        let token = vm.decisionToken
        vm.choose(.hit)
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.toastCount == 1)
        #expect(vm.decisions.count == 1)
        #expect(vm.decisionToken != token)
        #expect(vm.playerHands[0].hand.total == 11)
    }

    @Test("A wrong hit that keeps the hand going shows feedback, and NEXT returns to deciding")
    func wrongHitContinues() {
        // Hard 17 vs 10 → stand; the user hits and draws an ace → 18, still deciding.
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight, draws: [.ace])]))
        vm.choose(.hit)
        guard case .feedback = vm.phase else { Issue.record("expected feedback"); return }
        vm.next()
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.playerHands[0].hand.total == 18)
    }

    @Test("A hit that busts ends the turn: feedback, then outcome")
    func hitBust() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .two), up: .two, hole: .ten, draws: [.king])]))
        vm.choose(.hit)   // hard 12 vs 2 → hit is correct, busts on K
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect)
        vm.next()
        #expect(vm.phase == .outcome)
        #expect(vm.outcomeLines.last == "Bust −1")
    }

    @Test("Learn mode hints the correct play; Test mode doesn't")
    func hints() {
        let cards = shoe(player: (.ten, .six), up: .ten, hole: .seven)
        #expect(trainer(ScriptedShoes([cards]), mode: .learn).hint == .hit)
        #expect(trainer(ScriptedShoes([cards]), mode: .test).hint == nil)
    }

    @Test("DEAL after the outcome deals the next hand")
    func dealNext() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight),
                                        shoe(player: (.nine, .seven), up: .six, hole: .ten)]))
        vm.choose(.stand)
        vm.next()
        vm.deal()
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.handNumber == 2)
        #expect(vm.handsCompleted == 1)
        #expect(vm.playerHands[0].hand.total == 16)
    }

    @Test("Reaching the hand limit goes to the summary")
    func handLimit() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight)]), limit: 2)
        for _ in 0..<2 { vm.choose(.stand); vm.next(); vm.deal() }
        #expect(vm.phase == .summary)
        #expect(vm.handsCompleted == 2)
        #expect(vm.handLimit == 2)
    }

    @Test("Split: a correct split toasts, each split hand is played, then the dealer is revealed")
    func splitFlow() {
        // 8,8 vs 6 → split. Split cards: 10 onto the first 8, 9 onto the second.
        let vm = trainer(ScriptedShoes([shoe(player: (.eight, .eight), up: .six, hole: .ten,
                                             draws: [.ten, .nine])]))
        vm.choose(.split)
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.toastCount == 1)
        #expect(vm.playerHands.count == 2)
        #expect(vm.activeHandIndex == 0)
        vm.choose(.stand)            // 18 vs 6: correct stand, second hand still to play → toast
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.activeHandIndex == 1)
        vm.choose(.stand)            // 17 vs 6: correct, turn ends → feedback
        guard case .feedback = vm.phase else { Issue.record("expected feedback"); return }
        // Dealer 6+10=16 must draw to resolve the round, but the draw stays hidden until outcome.
        #expect(!vm.isDealerRevealed)
        #expect(vm.dealerCards.count == 2)
        vm.next()
        #expect(vm.phase == .outcome)
        #expect(vm.dealerCards.count == 3)
        #expect(vm.outcomeLines.count == 3)
    }

    @Test("Grading uses the snapshot rules' composition note")
    func compositionGrading() {
        var rules = BlackjackRules()
        rules.deckCount = .one
        rules.surrenderRule = .early
        let vm = trainer(ScriptedShoes([shoe(player: (.eight, .six), up: .ten, hole: .seven)]), rules: rules)
        #expect(vm.legalActions.contains(.surrender))
        vm.choose(.surrender)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect)
    }

    @Test("Decisions record cell, response time and WHY context")
    func decisionRecord() {
        var clock = Date(timeIntervalSince1970: 1000)
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven)]), now: { clock })
        clock = clock.addingTimeInterval(1.25)
        vm.choose(.stand)
        let d = vm.decisions[0]
        #expect(d.cell == TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10))
        #expect(d.responseMs == 1250)
        #expect(d.why.userAction == .stand)
        #expect(d.why.correctAction == .hit)
        #expect(d.draft.chosen == .action(.stand))
        #expect(d.draft.handNumber == 1)
    }

    @Test("Actions outside awaitingDecision, or illegal ones, are ignored")
    func ignoredActions() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven)]))
        vm.choose(.split)              // not legal on 10,6
        #expect(vm.decisions.isEmpty)
        vm.choose(.stand)
        vm.choose(.hit)                // in feedback
        #expect(vm.decisions.count == 1)
        vm.deal()                      // not in outcome
        guard case .feedback = vm.phase else { Issue.record("expected feedback"); return }
    }

    @Test("Filter and weights reach the cell sampler")
    func sampling() {
        let pairsOnly = ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight)])
        let vm = trainer(pairsOnly, limit: 10, filter: .pairs)
        for _ in 0..<9 { vm.choose(.stand); vm.next(); vm.deal() }
        #expect(pairsOnly.requestedCells.count == 10)
        #expect(pairsOnly.requestedCells.allSatisfy { $0.handType == .pair })

        let target = TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 9)
        let heavy = [target: 1000.0]
        let weighted = ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight)])
        let wvm = trainer(weighted, mode: .weakSpots, limit: 20, weights: heavy)
        for _ in 0..<19 { wvm.choose(.stand); wvm.next(); wvm.deal() }
        #expect(weighted.requestedCells.filter { $0 == target }.count >= 15)

        let unweighted = ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight)])
        let tvm = trainer(unweighted, mode: .test, limit: 20, weights: heavy)
        for _ in 0..<19 { tvm.choose(.stand); tvm.next(); tvm.deal() }
        #expect(unweighted.requestedCells.filter { $0 == target }.count < 5)
    }

    /// Parent spec §7 required regression (the Phase 7 bug): STAND always produces
    /// feedback before the next hand, in every mode, with real generated hands.
    @Test("STAND regression: every turn-ending decision shows feedback before the next deal",
          arguments: StrategyMode.allCases)
    func standAlwaysFeedsBack(mode: StrategyMode) {
        for seed in UInt64(1)...UInt64(5) {
            let vm = StrategyTrainerViewModel(setup: StrategySetup(mode: mode, length: .hands(15)),
                                              rules: BlackjackRules(), weights: nil, speedTimerSeconds: 3,
                                              seed: seed, persist: { _ in })
            var hands = 0
            while vm.phase != .summary {
                let dealt = vm.handNumber
                #expect(vm.phase == .awaitingDecision)
                vm.choose(.stand)
                // Stand ends the turn unless an earlier split hand is waiting; this path never splits.
                guard case .feedback = vm.phase else {
                    Issue.record("seed \(seed) hand \(dealt): no feedback after STAND"); return
                }
                #expect(!vm.isDealerRevealed)
                #expect(vm.dealerCards.count == 2)
                #expect(vm.handNumber == dealt, "no new hand before feedback")
                vm.next()
                #expect(vm.phase == .outcome)
                vm.deal()
                hands += 1
            }
            #expect(hands == 15)
        }
    }
}

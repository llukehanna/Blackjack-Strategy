import Testing
@testable import BJS
import BJSCore

// MARK: - TrainerViewModel Tests

struct TrainerViewModelTests {

    // Helper: create a TrainerViewModel with default Vegas Strip rules
    private func makeVM(mode: TrainingMode = .test) -> TrainerViewModel {
        let vm = TrainerViewModel()
        vm.mode = mode
        return vm
    }

    // STRAT-01: Deal hands under active rules
    @Test func testDealNewHand() {
        let vm = makeVM()
        vm.startSession()
        vm.dealNewHand()

        #expect(vm.playerHand != nil, "Player hand should be dealt")
        #expect(vm.playerHand!.cards.count == 2, "Player should have 2 cards")
        #expect(vm.dealerHand != nil, "Dealer hand should be dealt")
        #expect(vm.dealerHand!.cards.count == 2, "Dealer should have 2 cards")
        #expect(vm.dealerUpcard != nil, "Dealer upcard should be set")
        // Phase should be awaitingDecision (unless player BJ)
        if !vm.playerHand!.isBlackjack {
            #expect(vm.phase == .awaitingDecision, "Phase should be awaitingDecision after deal")
        }
        #expect(vm.sessionStats.handCount == 1, "Hand count should be 1 after first deal")
    }

    // Test shoe reshuffle when needed
    @Test func testDealNewHandReshuffles() {
        let vm = makeVM()
        vm.startSession()
        // Deal many hands to trigger reshuffle
        for _ in 0..<100 {
            vm.dealNewHand()
            // Advance through phases to allow next deal
            if vm.phase == .awaitingDecision {
                vm.playerAction(.stand)
                vm.advanceFromFeedback()
                vm.playOutDealer()
            }
        }
        // If we got through 100 hands without crash, reshuffle works
        #expect(vm.sessionStats.handCount == 100, "Should have dealt 100 hands")
    }

    // STRAT-02: Evaluate decision against correct strategy
    @Test func testDecisionEvaluationCorrectHit() {
        let vm = makeVM()
        vm.startSession()

        // Deal until we get a hand where hit is correct
        // Use a known scenario: create a hand and test evaluation
        // We'll deal and check for correctness of evaluation logic
        vm.dealNewHand()

        guard vm.phase == .awaitingDecision,
              let playerHand = vm.playerHand,
              let upcard = vm.dealerUpcard else {
            // Player blackjack - skip this test iteration
            return
        }

        let engine = StrategyEngine()
        let table = engine.strategy(for: vm.rules)
        let tableAction = table.action(for: playerHand, dealerUpcard: upcard.rank, rules: vm.rules)
        let mappedAction = vm.correctActionMapped

        // Whatever the correct action is, submitting it should be correct
        vm.playerAction(mappedAction)
        #expect(vm.feedbackState?.isCorrect == true, "Submitting the correct action should give correct feedback")
        #expect(vm.phase == .showingFeedback, "Phase should be showingFeedback after decision")
    }

    // Test incorrect decision
    @Test func testDecisionEvaluationIncorrect() {
        let vm = makeVM()
        vm.startSession()
        vm.dealNewHand()

        guard vm.phase == .awaitingDecision else { return }

        let correctAction = vm.correctActionMapped
        // Pick a wrong action (anything but the correct one that's available)
        let wrongAction = vm.availableActions.first(where: { $0 != correctAction }) ?? .stand
        if wrongAction != correctAction {
            vm.playerAction(wrongAction)
            #expect(vm.feedbackState?.isCorrect == false, "Submitting wrong action should give incorrect feedback")
        }
    }

    // STRAT-03: Feedback before hand outcome
    @Test func testFeedbackPhase() {
        let vm = makeVM()
        vm.startSession()
        vm.dealNewHand()

        guard vm.phase == .awaitingDecision else { return }

        let action = vm.availableActions.first!
        vm.playerAction(action)
        // Phase must be showingFeedback BEFORE play-out
        #expect(vm.phase == .showingFeedback, "Phase should be showingFeedback, not playingOut")
        #expect(vm.feedbackState != nil, "Feedback state should be set")
    }

    // Mid-hand action mapping: double -> hit for 3+ cards
    @Test func testMidHandActionMappingDoubleToHit() {
        // Create a hand with 3 cards where table might say double
        let cards = [
            Card(rank: .three, suit: .hearts),
            Card(rank: .two, suit: .spades),
            Card(rank: .four, suit: .clubs)
        ]
        let hand = BlackjackHand(cards: cards) // total = 9, 3 cards
        let rules = BlackjackRules()

        // canDouble should be false for 3+ cards
        #expect(!hand.canDouble(rules: rules), "3-card hand cannot double")

        // The mapToAvailableAction should convert .double to .hit
        let mapped = TrainerViewModel.mapAction(.double, for: hand, rules: rules, currentSplitCount: 0)
        #expect(mapped == .hit, "double should map to hit for 3+ card hand")
    }

    // Mid-hand action mapping: surrender -> hit for 3+ cards
    @Test func testMidHandActionMappingSurrenderToHit() {
        let cards = [
            Card(rank: .ten, suit: .hearts),
            Card(rank: .two, suit: .spades),
            Card(rank: .four, suit: .clubs)
        ]
        let hand = BlackjackHand(cards: cards) // total = 16, 3 cards
        let rules = BlackjackRules()

        #expect(!hand.canSurrender(rules: rules), "3-card hand cannot surrender")

        let mapped = TrainerViewModel.mapAction(.surrender, for: hand, rules: rules, currentSplitCount: 0)
        #expect(mapped == .hit, "surrender should map to hit for 3+ card hand")
    }

    // Available actions for 2-card hand vs 3+ card hand
    @Test func testAvailableActions() {
        let vm = makeVM()
        vm.startSession()
        vm.dealNewHand()

        guard vm.phase == .awaitingDecision,
              let hand = vm.playerHand else { return }

        let actions = vm.availableActions
        // 2-card hand always has hit and stand
        #expect(actions.contains(.hit), "Hit should always be available")
        #expect(actions.contains(.stand), "Stand should always be available")

        // If it's a pair, split should be available
        if hand.isPair {
            #expect(actions.contains(.split), "Split should be available for pairs")
        }

        // After a hit (3+ cards), double/split/surrender should not be available
        if actions.contains(.hit) && vm.correctActionMapped == .hit {
            vm.playerAction(.hit)
            vm.advanceFromFeedback()
            if vm.phase == .awaitingDecision {
                let actionsAfterHit = vm.availableActions
                #expect(!actionsAfterHit.contains(.double), "Double should not be available after hit")
                #expect(!actionsAfterHit.contains(.split), "Split should not be available after hit")
                #expect(!actionsAfterHit.contains(.surrender), "Surrender should not be available after hit")
            }
        }
    }

    // STRAT-04: Session stats tracking
    @Test func testSessionStatsAccuracy() {
        var stats = SessionStats()
        stats.recordDecision(isCorrect: true)
        stats.recordDecision(isCorrect: true)
        stats.recordDecision(isCorrect: false)

        #expect(stats.totalDecisions == 3)
        #expect(stats.correctDecisions == 2)
        #expect(stats.errorCount == 1)
        // accuracy = 2/3 * 100 = 66.666...
        #expect(abs(stats.accuracy - 66.666) < 0.1, "Accuracy should be ~66.7%")
    }

    @Test func testSessionStatsErrorCount() {
        var stats = SessionStats()
        stats.recordDecision(isCorrect: true)
        stats.recordDecision(isCorrect: false)
        stats.recordDecision(isCorrect: false)

        #expect(stats.errorCount == 2, "Error count should be 2")
        #expect(stats.correctDecisions == 1)
    }

    @Test func testSessionStatsBestStreak() {
        var stats = SessionStats()
        stats.recordDecision(isCorrect: true)
        stats.recordDecision(isCorrect: true)
        stats.recordDecision(isCorrect: true)
        stats.recordDecision(isCorrect: false)
        stats.recordDecision(isCorrect: true)
        stats.recordDecision(isCorrect: true)

        #expect(stats.bestStreak == 3, "Best streak should be 3")
        #expect(stats.currentStreak == 2, "Current streak should be 2")
    }

    // STRAT-05: Learn mode shows correct action
    @Test func testLearnMode() {
        let vm = makeVM(mode: .learn)
        vm.startSession()
        vm.dealNewHand()

        guard vm.phase == .awaitingDecision else { return }

        let displayAction = vm.correctActionForDisplay
        #expect(displayAction != nil, "Learn mode should expose correct action")
    }

    // STRAT-06: Test mode hides correct action
    @Test func testTestMode() {
        let vm = makeVM(mode: .test)
        vm.startSession()
        vm.dealNewHand()

        guard vm.phase == .awaitingDecision else { return }

        let displayAction = vm.correctActionForDisplay
        #expect(displayAction == nil, "Test mode should NOT expose correct action")
    }

    // PROG-02: Session summary
    @Test func testSessionSummary() {
        let vm = makeVM()
        vm.startSession()

        // Play a few hands
        for _ in 0..<3 {
            vm.dealNewHand()
            if vm.phase == .awaitingDecision {
                let action = vm.availableActions.first!
                vm.playerAction(action)
                vm.advanceFromFeedback()
                if vm.phase == .playingOut {
                    vm.playOutDealer()
                }
            }
        }

        let stats = vm.sessionStats
        #expect(stats.handCount >= 1, "Should have played at least 1 hand")
        #expect(stats.totalDecisions >= 1, "Should have at least 1 decision")

        let mistakes = vm.mistakes
        // Mistakes should only contain incorrect decisions
        for mistake in mistakes {
            #expect(!mistake.isCorrect, "Mistakes array should only contain incorrect decisions")
        }
    }

    // Player blackjack skips awaitingDecision
    @Test func testPlayerBlackjackSkipsDecision() {
        // We can test the logic: if playerHand.isBlackjack, phase should be showingResult
        let vm = makeVM()
        vm.startSession()

        // Deal many hands until we get a blackjack (or just verify the logic path)
        // Since we can't control the shoe, we test the state machine rule:
        // After dealNewHand, if playerHand.isBlackjack, phase != .awaitingDecision
        for _ in 0..<200 {
            vm.dealNewHand()
            if let hand = vm.playerHand, hand.isBlackjack {
                #expect(vm.phase == .showingResult, "Blackjack should skip to showingResult")
                #expect(vm.handResult == .blackjack, "Result should be blackjack")
                return
            }
            // Reset for next attempt
            if vm.phase == .awaitingDecision {
                vm.playerAction(.stand)
                vm.advanceFromFeedback()
                if vm.phase == .playingOut {
                    vm.playOutDealer()
                }
            }
        }
        // It's statistically very unlikely we don't see a BJ in 200 hands,
        // but if so, the test just passes without asserting
    }

    // Player bust skips dealer play-out
    @Test func testPlayerBustSkipsDealerPlayOut() {
        let vm = makeVM()
        vm.startSession()

        // Play hands, hitting repeatedly until bust
        for _ in 0..<200 {
            vm.dealNewHand()
            guard vm.phase == .awaitingDecision else { continue }

            // Keep hitting until bust or stand is forced
            while vm.phase == .awaitingDecision {
                vm.playerAction(.hit)
                vm.advanceFromFeedback()
            }

            if vm.handResult == .bust {
                // After bust, phase should be showingResult (not playingOut)
                #expect(vm.phase == .showingResult, "Bust should skip dealer play-out")
                return
            }
        }
    }

    // Decisions array tracks all decisions
    @Test func testDecisionsArray() {
        let vm = makeVM()
        vm.startSession()
        vm.dealNewHand()

        guard vm.phase == .awaitingDecision else { return }

        let action = vm.availableActions.first!
        vm.playerAction(action)

        #expect(vm.decisions.count == 1, "Should have 1 decision recorded")
        #expect(vm.decisions[0].playerAction == action, "Decision should record player's action")
        #expect(vm.decisions[0].handNumber == 1, "First decision should be hand 1")
    }
}

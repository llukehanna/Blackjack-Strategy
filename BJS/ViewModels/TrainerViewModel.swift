import Foundation
import SwiftUI
import SwiftData
import BJSCore

// MARK: - Supporting Types

enum TrainingMode: String, CaseIterable {
    case learn = "Learn"
    case test = "Test"
}

enum TrainerPhase: Equatable {
    case preSession
    case dealing
    case awaitingDecision
    case showingFeedback
    case playingOut
    case showingResult
    case sessionSummary
}

enum FeedbackResult: Equatable {
    case correct
    case incorrect(correctAction: Action)

    var message: String {
        switch self {
        case .correct:
            return "Correct"
        case .incorrect(let action):
            return "Incorrect \u{2014} Should: \(action.rawValue.capitalized)"
        }
    }

    var isCorrect: Bool {
        if case .correct = self { return true }
        return false
    }
}

enum HandResult: String {
    case win = "Win"
    case loss = "Loss"
    case push = "Push"
    case blackjack = "Blackjack!"
    case bust = "Bust"
    case surrender = "Surrender (-0.5)"
}

struct DecisionRecord: Equatable {
    let handDescription: String
    let playerAction: Action
    let correctAction: Action
    let isCorrect: Bool
    let handNumber: Int
}

struct SessionStats {
    var totalDecisions: Int = 0
    var correctDecisions: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var handCount: Int = 0

    var accuracy: Double {
        guard totalDecisions > 0 else { return 0 }
        return Double(correctDecisions) / Double(totalDecisions) * 100
    }

    var errorCount: Int { totalDecisions - correctDecisions }

    mutating func recordDecision(isCorrect: Bool) {
        totalDecisions += 1
        if isCorrect {
            correctDecisions += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
        } else {
            currentStreak = 0
        }
    }
}

// MARK: - TrainerViewModel

@Observable
class TrainerViewModel {
    var phase: TrainerPhase = .preSession
    var mode: TrainingMode = .test
    var playerHand: BlackjackHand?
    var dealerHand: BlackjackHand?
    var dealerUpcard: Card?
    var shoe: Shoe
    var rules: BlackjackRules
    var feedbackState: FeedbackResult?
    var handResult: HandResult?
    var sessionStats = SessionStats()
    var decisions: [DecisionRecord] = []
    var currentSplitCount: Int = 0

    private let engine = StrategyEngine()
    private var strategyTable: StrategyTable

    // The last evaluated correct action (after mapping) for the current hand state
    private var lastCorrectAction: Action?

    init(rules: BlackjackRules = BlackjackRules()) {
        self.rules = rules
        self.shoe = Shoe(deckCount: rules.deckCount.rawValue)
        self.strategyTable = StrategyEngine().strategy(for: rules)
        self.shoe.shuffle()
        self.strategyTable = engine.strategy(for: rules)
    }

    // MARK: - Public API

    func updateRules(_ newRules: BlackjackRules) {
        rules = newRules
        shoe = Shoe(deckCount: newRules.deckCount.rawValue)
        shoe.shuffle()
        strategyTable = engine.strategy(for: newRules)
    }

    func startSession() {
        sessionStats = SessionStats()
        decisions = []
        phase = .preSession
    }

    func startNewSession() {
        sessionStats = SessionStats()
        decisions = []
        phase = .preSession
    }

    // MARK: - Available Actions

    var availableActions: [Action] {
        guard let hand = playerHand, phase == .awaitingDecision else { return [] }
        var actions: [Action] = [.hit, .stand]
        if hand.canDouble(rules: rules) {
            actions.append(.double)
        }
        if hand.canSplit(rules: rules, currentSplitCount: currentSplitCount) {
            actions.append(.split)
        }
        if hand.canSurrender(rules: rules) {
            actions.append(.surrender)
        }
        return actions
    }

    // MARK: - Correct Action Display (Learn vs Test)

    var correctActionForDisplay: Action? {
        guard mode == .learn, phase == .awaitingDecision else { return nil }
        return correctActionMapped
    }

    /// The correct action after mapping unavailable actions to alternatives.
    /// Exposed for testing and learn mode display.
    var correctActionMapped: Action {
        guard let hand = playerHand, let upcard = dealerUpcard else { return .stand }
        let tableAction = strategyTable.action(for: hand, dealerUpcard: upcard.rank, rules: rules)
        return Self.mapAction(tableAction, for: hand, rules: rules, currentSplitCount: currentSplitCount)
    }

    // MARK: - Static Action Mapping (exposed for tests)

    /// Maps a strategy table action to an available action given the current hand state.
    /// Per RESEARCH.md Critical Integration Detail:
    /// - .double when !canDouble -> .hit
    /// - .surrender when !canSurrender -> .hit
    /// - .split when !canSplit -> uses the hard/soft table fallback (simplified to .stand)
    static func mapAction(_ tableAction: Action, for hand: BlackjackHand, rules: BlackjackRules, currentSplitCount: Int) -> Action {
        switch tableAction {
        case .double:
            if !hand.canDouble(rules: rules) { return .hit }
            return .double
        case .surrender:
            if !hand.canSurrender(rules: rules) { return .hit }
            return .surrender
        case .split:
            if !hand.canSplit(rules: rules, currentSplitCount: currentSplitCount) { return .stand }
            return .split
        case .hit, .stand:
            return tableAction
        }
    }

    // MARK: - Dealing

    func dealNewHand() {
        // Check if shoe needs reshuffle
        if shoe.needsReshuffle || shoe.cardsRemaining < 20 {
            shoe.shuffle()
        }

        // Deal 2 cards each
        guard let p1 = shoe.deal(),
              let d1 = shoe.deal(),
              let p2 = shoe.deal(),
              let d2 = shoe.deal() else {
            // Shoe exhausted -- reshuffle and try again
            shoe.shuffle()
            guard let p1 = shoe.deal(),
                  let d1 = shoe.deal(),
                  let p2 = shoe.deal(),
                  let d2 = shoe.deal() else { return }
            playerHand = BlackjackHand(cards: [p1, p2])
            dealerHand = BlackjackHand(cards: [d1, d2])
            dealerUpcard = d1
            sessionStats.handCount += 1
            checkForNaturals()
            return
        }

        playerHand = BlackjackHand(cards: [p1, p2])
        dealerHand = BlackjackHand(cards: [d1, d2])
        dealerUpcard = d1
        currentSplitCount = 0
        feedbackState = nil
        handResult = nil
        lastCorrectAction = nil
        sessionStats.handCount += 1

        HapticManager.dealCards()
        checkForNaturals()
    }

    private func checkForNaturals() {
        guard let playerHand = playerHand, let dealerHand = dealerHand else { return }

        // Player blackjack
        if playerHand.isBlackjack {
            if dealerHand.isBlackjack {
                handResult = .push
            } else {
                handResult = .blackjack
            }
            phase = .showingResult
            return
        }

        // Dealer blackjack with American peek
        if rules.peekRule == .americanPeek && dealerHand.isBlackjack {
            handResult = .loss
            phase = .showingResult
            return
        }

        phase = .awaitingDecision
    }

    // MARK: - Player Decision

    func playerAction(_ action: Action) {
        guard let hand = playerHand, let upcard = dealerUpcard else { return }
        guard phase == .awaitingDecision else { return }

        // Get correct action
        let tableAction = strategyTable.action(for: hand, dealerUpcard: upcard.rank, rules: rules)
        let correctAction = Self.mapAction(tableAction, for: hand, rules: rules, currentSplitCount: currentSplitCount)
        lastCorrectAction = correctAction

        let isCorrect = action == correctAction

        // Record decision
        let record = DecisionRecord(
            handDescription: describeHand(hand, vs: upcard),
            playerAction: action,
            correctAction: correctAction,
            isCorrect: isCorrect,
            handNumber: sessionStats.handCount
        )
        decisions.append(record)
        sessionStats.recordDecision(isCorrect: isCorrect)

        // Set feedback
        if isCorrect {
            feedbackState = .correct
            HapticManager.correctDecision()
        } else {
            feedbackState = .incorrect(correctAction: correctAction)
            HapticManager.incorrectDecision()
        }

        // Store the action the player chose so advanceFromFeedback can execute it
        pendingPlayerAction = action
        phase = .showingFeedback
    }

    // MARK: - Feedback Advance

    private var pendingPlayerAction: Action?

    /// Called after the feedback overlay display (~1 second). Executes the player's action.
    func advanceFromFeedback() {
        guard let action = pendingPlayerAction else {
            phase = .playingOut
            return
        }
        pendingPlayerAction = nil
        feedbackState = nil

        switch action {
        case .hit:
            executeHit()
        case .stand:
            phase = .playingOut
        case .double:
            executeDouble()
        case .surrender:
            handResult = .surrender
            phase = .showingResult
        case .split:
            // Simplified split: for now, just continue with the hand
            // Full split implementation can be enhanced later
            phase = .playingOut
        }
    }

    private func executeHit() {
        guard var hand = playerHand, let card = shoe.deal() else {
            phase = .playingOut
            return
        }
        hand.addCard(card)
        playerHand = hand

        if hand.isBust {
            handResult = .bust
            phase = .showingResult
        } else {
            // Player still has decisions to make
            phase = .awaitingDecision
        }
    }

    private func executeDouble() {
        guard var hand = playerHand, let card = shoe.deal() else {
            phase = .playingOut
            return
        }
        hand.addCard(card)
        playerHand = hand

        if hand.isBust {
            handResult = .bust
            phase = .showingResult
        } else {
            phase = .playingOut
        }
    }

    // MARK: - Dealer Play-Out

    func playOutDealer() {
        guard var dealer = dealerHand else {
            phase = .showingResult
            return
        }

        // Dealer draws per rules
        while shouldDealerHit(dealer) {
            guard let card = shoe.deal() else { break }
            dealer.addCard(card)
        }
        dealerHand = dealer

        // Determine result
        guard let playerTotal = playerHand?.total else {
            phase = .showingResult
            return
        }

        let dealerTotal = dealer.total

        if dealer.isBust {
            handResult = .win
        } else if playerTotal > dealerTotal {
            handResult = .win
        } else if playerTotal < dealerTotal {
            handResult = .loss
        } else {
            handResult = .push
        }

        phase = .showingResult
    }

    private func shouldDealerHit(_ hand: BlackjackHand) -> Bool {
        let total = hand.total
        if total < 17 { return true }
        if total == 17 && hand.isSoft && rules.dealerSoft17 == .hits { return true }
        return false
    }

    // MARK: - Navigation

    func advanceToNextHand() {
        dealNewHand()
    }

    // MARK: - Session End

    func endSession(modelContext: ModelContext) {
        // Encode rules to JSON
        guard let rulesData = try? JSONEncoder().encode(rules) else { return }

        let session = TrainingSession(mode: mode.rawValue, rulesJSON: rulesData)
        session.endDate = Date()
        modelContext.insert(session)

        // Create SessionDecision records
        for record in decisions {
            let decision = SessionDecision(
                handDescription: record.handDescription,
                playerAction: record.playerAction.rawValue,
                correctAction: record.correctAction.rawValue,
                isCorrect: record.isCorrect,
                handNumber: record.handNumber
            )
            decision.session = session
            modelContext.insert(decision)
        }

        try? modelContext.save()

        HapticManager.sessionComplete()
        phase = .sessionSummary
    }

    // MARK: - Why Context

    /// Builds a `WhyContext` from the most recent decision so the WHY sheet
    /// can render an explanation. Returns `nil` if no decision is currently
    /// being shown in the feedback overlay.
    func makeWhyContext() -> WhyContext? {
        guard feedbackState != nil,
              let hand = playerHand,
              let upcard = dealerUpcard,
              let lastDecision = decisions.last else {
            return nil
        }

        let handType: HandType
        let pairRank: Rank?
        if hand.isPair {
            handType = .pair
            pairRank = hand.cards.first?.rank
        } else if hand.isSoft {
            handType = .soft
            pairRank = nil
        } else {
            handType = .hard
            pairRank = nil
        }

        return WhyContext(
            handTotal: hand.total,
            handType: handType,
            pairRank: pairRank,
            dealerUpCard: upcard.rank,
            userAction: lastDecision.playerAction,
            correctAction: lastDecision.correctAction,
            rules: rules
        )
    }

    // MARK: - Mistakes

    var mistakes: [DecisionRecord] {
        decisions.filter { !$0.isCorrect }
    }

    // MARK: - Hand Description

    private func describeHand(_ hand: BlackjackHand, vs upcard: Card) -> String {
        let upcardName = rankName(upcard.rank)

        if hand.isPair {
            let pairName = rankName(hand.cards[0].rank)
            return "Pair \(pairName)s vs \(upcardName)"
        }

        if hand.isSoft {
            return "Soft \(hand.total) vs \(upcardName)"
        }

        return "Hard \(hand.total) vs \(upcardName)"
    }

    private func rankName(_ rank: Rank) -> String {
        switch rank {
        case .ace: return "A"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        }
    }
}

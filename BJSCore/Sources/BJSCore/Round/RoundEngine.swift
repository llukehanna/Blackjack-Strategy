/// A single blackjack round as a pure value-type state machine.
///
/// Create it with a shoe (deals P1, dealer upcard, P2, dealer hole), then call
/// `apply(_:shoe:)` with player actions until `phase == .settled`. The dealer
/// plays automatically once every player hand is finished.
public struct RoundEngine: Sendable {

    public enum Phase: Sendable, Equatable {
        case playerTurn
        case settled
    }

    public let rules: BlackjackRules
    public private(set) var dealer: BlackjackHand
    public private(set) var hands: [PlayerHandState]
    public private(set) var activeHandIndex: Int = 0
    public private(set) var phase: Phase = .playerTurn
    /// Every card taken from the shoe during this round, in draw order.
    public private(set) var drawnCards: [Card]

    /// True when the dealer holds a natural that is only revealed after the
    /// player's early-surrender decision (American peek + early surrender).
    private var peekPending = false

    public init(rules: BlackjackRules, shoe: inout Shoe) throws {
        guard let p1 = shoe.deal(), let up = shoe.deal(),
              let p2 = shoe.deal(), let hole = shoe.deal() else {
            throw RoundError.shoeExhausted
        }
        self.rules = rules
        self.dealer = BlackjackHand(cards: [up, hole])
        self.hands = [PlayerHandState(hand: BlackjackHand(cards: [p1, p2]))]
        self.drawnCards = [p1, up, p2, hole]
        resolveNaturals()
    }

    // MARK: - Queries

    public var dealerUpcard: Card { dealer.cards[0] }

    public var totalNet: Double { hands.reduce(0) { $0 + $1.net } }

    public var legalActions: Set<Action> {
        guard phase == .playerTurn else { return [] }
        let state = hands[activeHandIndex]
        let hand = state.hand
        var actions: Set<Action> = [.stand]
        if hand.canSplit(rules: rules, currentSplitCount: hands.count - 1) {
            actions.insert(.split)
        }
        if state.isSplitAces && !rules.hitSplitAces { return actions }
        actions.insert(.hit)
        if hand.canDouble(rules: rules) && (!state.isFromSplit || rules.doubleAfterSplit) {
            actions.insert(.double)
        }
        if hands.count == 1 && hand.canSurrender(rules: rules) {
            actions.insert(.surrender)
        }
        return actions
    }

    public var currentSpot: DecisionSpot? {
        guard phase == .playerTurn else { return nil }
        return DecisionSpot(hand: hands[activeHandIndex].hand,
                            dealerUpcard: dealerUpcard.rank,
                            legalActions: legalActions)
    }

    // MARK: - Actions

    public mutating func apply(_ action: Action, shoe: inout Shoe) throws {
        guard phase == .playerTurn else { throw RoundError.notPlayerTurn }
        guard legalActions.contains(action) else { throw RoundError.illegalAction(action) }

        if peekPending {
            peekPending = false
            if action != .surrender {
                // Dealer peeks after the early-surrender window: original bet lost.
                hands[0].isFinished = true
                hands[0].outcome = .loss
                hands[0].net = -1
                phase = .settled
                return
            }
        }

        let i = activeHandIndex
        switch action {
        case .hit:
            try draw(into: i, shoe: &shoe)
            if hands[i].hand.total >= 21 { hands[i].isFinished = true }
        case .stand:
            hands[i].isFinished = true
        case .double:
            hands[i].isDoubled = true
            try draw(into: i, shoe: &shoe)
            hands[i].isFinished = true
        case .surrender:
            hands[i].isSurrendered = true
            hands[i].isFinished = true
        case .split:
            try split(i, shoe: &shoe)
        }
        try advance(shoe: &shoe)
    }

    // MARK: - Internals

    private mutating func resolveNaturals() {
        let player = hands[0].hand
        if player.isBlackjack {
            hands[0].isFinished = true
            if dealer.isBlackjack {
                hands[0].outcome = .push
                hands[0].net = 0
            } else {
                hands[0].outcome = .blackjack
                hands[0].net = rules.blackjackPayout.multiplier
            }
            phase = .settled
            return
        }
        guard dealer.isBlackjack, rules.peekRule == .americanPeek else { return }
        if rules.surrenderRule == .early {
            peekPending = true
        } else {
            hands[0].isFinished = true
            hands[0].outcome = .loss
            hands[0].net = -1
            phase = .settled
        }
    }

    private mutating func draw(into i: Int, shoe: inout Shoe) throws {
        guard let card = shoe.deal() else { throw RoundError.shoeExhausted }
        drawnCards.append(card)
        var hand = hands[i].hand
        hand.addCard(card)
        hands[i].hand = hand
    }

    private mutating func split(_ i: Int, shoe: inout Shoe) throws {
        let original = hands[i].hand.cards
        guard let first = shoe.deal(), let second = shoe.deal() else {
            throw RoundError.shoeExhausted
        }
        drawnCards.append(first)
        drawnCards.append(second)
        let aces = original[0].rank == .ace

        var left = PlayerHandState(hand: BlackjackHand(cards: [original[0], first]))
        left.isFromSplit = true
        left.isSplitAces = aces
        var right = PlayerHandState(hand: BlackjackHand(cards: [original[1], second]))
        right.isFromSplit = true
        right.isSplitAces = aces

        hands[i] = left
        hands.insert(right, at: i + 1)
        // A split can raise the total split count enough that an already-waiting
        // split-ace hand (kept alive earlier because it could still resplit) no
        // longer can, so every hand is rechecked, not just the two just created.
        for idx in hands.indices {
            autoFinishIfNeeded(idx)
        }
    }

    /// Finishes a hand that has no meaningful decision left:
    /// 21 or more, or a split-ace hand that may neither hit nor resplit.
    private mutating func autoFinishIfNeeded(_ i: Int) {
        let state = hands[i]
        if state.hand.total >= 21 {
            hands[i].isFinished = true
            return
        }
        if state.isSplitAces && !rules.hitSplitAces
            && !state.hand.canSplit(rules: rules, currentSplitCount: hands.count - 1) {
            hands[i].isFinished = true
        }
    }

    private mutating func advance(shoe: inout Shoe) throws {
        if let next = hands.indices.first(where: { !hands[$0].isFinished }) {
            activeHandIndex = next
            return
        }
        try finishRound(shoe: &shoe)
    }

    private mutating func finishRound(shoe: inout Shoe) throws {
        if dealer.isBlackjack {
            // Reachable only under European no-peek or after an early surrender.
            for i in hands.indices { settleAgainstDealerBlackjack(i) }
            phase = .settled
            return
        }
        let hasLiveHand = hands.contains { !$0.isSurrendered && !$0.hand.isBust }
        if hasLiveHand {
            while shouldDealerHit {
                guard let card = shoe.deal() else { throw RoundError.shoeExhausted }
                drawnCards.append(card)
                dealer.addCard(card)
            }
        }
        for i in hands.indices { settle(i) }
        phase = .settled
    }

    private var shouldDealerHit: Bool {
        let total = dealer.total
        if total < 17 { return true }
        return total == 17 && dealer.isSoft && rules.dealerSoft17 == .hits
    }

    private mutating func settleAgainstDealerBlackjack(_ i: Int) {
        let state = hands[i]
        if state.isSurrendered {
            // Reachable only under no hole card or after an early surrender. Either way the
            // hand was surrendered before the dealer's blackjack existed, so it keeps half.
            hands[i].outcome = .surrendered
            hands[i].net = -0.5
        } else {
            hands[i].outcome = state.hand.isBust ? .bust : .loss
            hands[i].net = -state.betUnits
        }
    }

    private mutating func settle(_ i: Int) {
        let state = hands[i]
        let bet = state.betUnits
        if state.isSurrendered {
            hands[i].outcome = .surrendered
            hands[i].net = -0.5
        } else if state.hand.isBust {
            hands[i].outcome = .bust
            hands[i].net = -bet
        } else if dealer.isBust || state.hand.total > dealer.total {
            hands[i].outcome = .win
            hands[i].net = bet
        } else if state.hand.total < dealer.total {
            hands[i].outcome = .loss
            hands[i].net = -bet
        } else {
            hands[i].outcome = .push
            hands[i].net = 0
        }
    }
}

import Testing
@testable import BJSCore

func card(_ rank: Rank, _ suit: Suit = .hearts) -> Card {
    Card(rank: rank, suit: suit)
}

@Suite("BlackjackHand")
struct HandTests {

    // MARK: - Total computation

    @Test("Hard hand: [10, 5] -> total 15, not soft, not bust")
    func hardHandTotal() {
        let hand = BlackjackHand(cards: [card(.ten), card(.five)])
        #expect(hand.total == 15)
        #expect(hand.isSoft == false)
        #expect(hand.isBust == false)
    }

    @Test("Soft hand: [Ace, 6] -> total 17, soft")
    func softSeventeen() {
        let hand = BlackjackHand(cards: [card(.ace), card(.six)])
        #expect(hand.total == 17)
        #expect(hand.isSoft == true)
    }

    @Test("Two aces: [Ace, Ace] -> total 12, soft")
    func twoAces() {
        let hand = BlackjackHand(cards: [card(.ace), card(.ace)])
        #expect(hand.total == 12)
        #expect(hand.isSoft == true)
    }

    @Test("Soft becomes hard: [Ace, 6, 8] -> total 15, not soft")
    func softBecomesHard() {
        let hand = BlackjackHand(cards: [card(.ace), card(.six), card(.eight)])
        #expect(hand.total == 15)
        #expect(hand.isSoft == false)
    }

    @Test("Multiple aces: [Ace, 6, Ace] -> total 18, soft")
    func aceWithSixAndAce() {
        let hand = BlackjackHand(cards: [card(.ace), card(.six), card(.ace)])
        #expect(hand.total == 18)
        #expect(hand.isSoft == true)
    }

    @Test("Three aces: [Ace, Ace, Ace] -> total 13, soft")
    func threeAces() {
        let hand = BlackjackHand(cards: [card(.ace), card(.ace), card(.ace)])
        #expect(hand.total == 13)
        #expect(hand.isSoft == true)
    }

    @Test("Bust hand: [10, 5, 9] -> total 24, bust")
    func bustHand() {
        let hand = BlackjackHand(cards: [card(.ten), card(.five), card(.nine)])
        #expect(hand.total == 24)
        #expect(hand.isBust == true)
    }

    @Test("Natural blackjack: [Ace, 10] -> total 21, soft, isBlackjack")
    func naturalBlackjack() {
        let hand = BlackjackHand(cards: [card(.ace), card(.ten)])
        #expect(hand.total == 21)
        #expect(hand.isSoft == true)
        #expect(hand.isBlackjack == true)
    }

    @Test("Non-natural 21: [7, 7, 7] -> total 21, not blackjack")
    func nonNatural21() {
        let hand = BlackjackHand(cards: [card(.seven), card(.seven), card(.seven)])
        #expect(hand.total == 21)
        #expect(hand.isBlackjack == false)
    }

    // MARK: - Pair detection

    @Test("Same rank pair: [5, 5] -> isPair true")
    func pairDetection() {
        let hand = BlackjackHand(cards: [card(.five), card(.five)])
        #expect(hand.isPair == true)
    }

    @Test("Same-value different-rank is NOT a pair: [10, King] -> isPair false")
    func sameValueNotPair() {
        let hand = BlackjackHand(cards: [card(.ten), card(.king)])
        #expect(hand.isPair == false)
    }

    @Test("Three cards is not a pair even if first two match")
    func threeCardsNotPair() {
        let hand = BlackjackHand(cards: [card(.five), card(.five), card(.three)])
        #expect(hand.isPair == false)
    }

    // MARK: - canDouble

    @Test("2-card hand with anyTwo restriction -> canDouble true")
    func canDoubleAnyTwo() {
        let hand = BlackjackHand(cards: [card(.seven), card(.four)])
        var rules = BlackjackRules()
        rules.doubleRestriction = .anyTwo
        #expect(hand.canDouble(rules: rules) == true)
    }

    @Test("3-card hand -> canDouble false regardless of restriction")
    func cannotDoubleThreeCards() {
        let hand = BlackjackHand(cards: [card(.three), card(.four), card(.five)])
        let rules = BlackjackRules()
        #expect(hand.canDouble(rules: rules) == false)
    }

    @Test("[8, 3] total 11 with nineToEleven restriction -> canDouble true")
    func canDoubleNineToEleven() {
        let hand = BlackjackHand(cards: [card(.eight), card(.three)])
        var rules = BlackjackRules()
        rules.doubleRestriction = .nineToEleven
        #expect(hand.canDouble(rules: rules) == true)
    }

    @Test("[8, 6] total 14 with nineToEleven restriction -> canDouble false")
    func cannotDoubleOutOfRange() {
        let hand = BlackjackHand(cards: [card(.eight), card(.six)])
        var rules = BlackjackRules()
        rules.doubleRestriction = .nineToEleven
        #expect(hand.canDouble(rules: rules) == false)
    }

    @Test("[5, 5] total 10 with tenToEleven restriction -> canDouble true")
    func canDoubleTenToEleven() {
        let hand = BlackjackHand(cards: [card(.five), card(.five)])
        var rules = BlackjackRules()
        rules.doubleRestriction = .tenToEleven
        #expect(hand.canDouble(rules: rules) == true)
    }

    @Test("[4, 5] total 9 with tenToEleven restriction -> canDouble false")
    func cannotDoubleBelowTen() {
        let hand = BlackjackHand(cards: [card(.four), card(.five)])
        var rules = BlackjackRules()
        rules.doubleRestriction = .tenToEleven
        #expect(hand.canDouble(rules: rules) == false)
    }

    // MARK: - canSplit

    @Test("Pair with splitCount < maxSplitHands -> canSplit true")
    func canSplitBasic() {
        let hand = BlackjackHand(cards: [card(.five), card(.five)])
        let rules = BlackjackRules() // maxSplitHands = 4
        #expect(hand.canSplit(rules: rules, currentSplitCount: 0) == true)
    }

    @Test("Pair with splitCount >= maxSplitHands-1 -> canSplit false")
    func cannotSplitAtMax() {
        let hand = BlackjackHand(cards: [card(.five), card(.five)])
        let rules = BlackjackRules() // maxSplitHands = 4
        #expect(hand.canSplit(rules: rules, currentSplitCount: 3) == false)
    }

    @Test("Aces pair with resplitAces false and splitCount > 0 -> canSplit false")
    func cannotResplitAces() {
        let hand = BlackjackHand(cards: [card(.ace), card(.ace)])
        var rules = BlackjackRules()
        rules.resplitAces = false
        #expect(hand.canSplit(rules: rules, currentSplitCount: 1) == false)
    }

    @Test("Aces pair with resplitAces true and splitCount > 0 -> canSplit true")
    func canResplitAcesWhenAllowed() {
        let hand = BlackjackHand(cards: [card(.ace), card(.ace)])
        var rules = BlackjackRules()
        rules.resplitAces = true
        #expect(hand.canSplit(rules: rules, currentSplitCount: 1) == true)
    }

    @Test("Non-pair hand -> canSplit false")
    func cannotSplitNonPair() {
        let hand = BlackjackHand(cards: [card(.five), card(.six)])
        let rules = BlackjackRules()
        #expect(hand.canSplit(rules: rules, currentSplitCount: 0) == false)
    }

    // MARK: - canSurrender

    @Test("Late surrender with 2-card hand -> canSurrender true")
    func canSurrenderLate() {
        let hand = BlackjackHand(cards: [card(.ten), card(.six)])
        var rules = BlackjackRules()
        rules.surrenderRule = .late
        #expect(hand.canSurrender(rules: rules) == true)
    }

    @Test("No surrender rule -> canSurrender false")
    func cannotSurrenderNone() {
        let hand = BlackjackHand(cards: [card(.ten), card(.six)])
        var rules = BlackjackRules()
        rules.surrenderRule = .none
        #expect(hand.canSurrender(rules: rules) == false)
    }

    @Test("3-card hand -> canSurrender false even with late surrender")
    func cannotSurrenderThreeCards() {
        let hand = BlackjackHand(cards: [card(.ten), card(.three), card(.three)])
        var rules = BlackjackRules()
        rules.surrenderRule = .late
        #expect(hand.canSurrender(rules: rules) == false)
    }

    // MARK: - addCard

    @Test("addCard appends to the hand")
    func addCard() {
        var hand = BlackjackHand(cards: [card(.ten), card(.five)])
        hand.addCard(card(.three))
        #expect(hand.cards.count == 3)
        #expect(hand.total == 18)
    }

    // MARK: - Index helpers

    @Test("hardIndex: total 5 -> 0, total 21 -> 16")
    func hardIndex() {
        let hand5 = BlackjackHand(cards: [card(.two), card(.three)])
        #expect(hand5.hardIndex == 0)

        let hand21 = BlackjackHand(cards: [card(.ten), card(.ace, .spades), card(.ten, .diamonds)])
        #expect(hand21.hardIndex == 16)
    }

    @Test("softIndex: soft 13 -> 0, soft 21 -> 8")
    func softIndex() {
        let soft13 = BlackjackHand(cards: [card(.ace), card(.two)])
        #expect(soft13.softIndex == 0)

        let soft21 = BlackjackHand(cards: [card(.ace), card(.ten)])
        #expect(soft21.softIndex == 8)
    }

    @Test("pairIndex: pair of 2s -> 0, pair of aces -> 9")
    func pairIndex() {
        let twos = BlackjackHand(cards: [card(.two), card(.two)])
        #expect(twos.pairIndex == 0)

        let aces = BlackjackHand(cards: [card(.ace), card(.ace)])
        #expect(aces.pairIndex == 9)

        let tens = BlackjackHand(cards: [card(.ten), card(.ten)])
        #expect(tens.pairIndex == 8)
    }
}

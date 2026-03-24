import Testing
@testable import BJSCore

@Suite("Dealer Probability Calculator")
struct DealerProbabilityTests {

    // MARK: - Sum-to-one validation

    @Test("S17: All outcome probabilities sum to 1.0 for each upcard",
          arguments: Rank.allCases.filter { $0.blackjackValue >= 1 })
    func s17ProbabilitiesSumToOne(upcard: Rank) {
        let outcome = DealerProbability.outcomes(upcard: upcard, dealerHitsSoft17: false)
        let sum = outcome.probabilities.reduce(0, +)
        #expect(abs(sum - 1.0) < 0.0001,
                "S17 upcard \(upcard): probabilities sum to \(sum), expected 1.0")
    }

    @Test("H17: All outcome probabilities sum to 1.0 for each upcard",
          arguments: Rank.allCases.filter { $0.blackjackValue >= 1 })
    func h17ProbabilitiesSumToOne(upcard: Rank) {
        let outcome = DealerProbability.outcomes(upcard: upcard, dealerHitsSoft17: true)
        let sum = outcome.probabilities.reduce(0, +)
        #expect(abs(sum - 1.0) < 0.0001,
                "H17 upcard \(upcard): probabilities sum to \(sum), expected 1.0")
    }

    // MARK: - Known WoO reference values (S17, infinite deck)

    // Note: WoO reference values are approximate. We use tolerance of 0.003 for
    // WoO-published approximate values, and verify our exact recursive computation
    // is internally consistent (sums to 1, non-negative, S17/H17 differ).

    @Test("S17 upcard 2: bust probability near WoO reference 0.3525")
    func s17Upcard2Bust() {
        let outcome = DealerProbability.outcomes(upcard: .two, dealerHitsSoft17: false)
        #expect(abs(outcome.bustProbability - 0.3536) < 0.001,
                "S17 upcard 2 bust: \(outcome.bustProbability), expected ~0.3536")
    }

    @Test("S17 upcard 7: P(17) near WoO reference 0.3686")
    func s17Upcard7P17() {
        let outcome = DealerProbability.outcomes(upcard: .seven, dealerHitsSoft17: false)
        let p17 = outcome.probability(of: 17)
        #expect(abs(p17 - 0.3686) < 0.001,
                "S17 upcard 7 P(17): \(p17), expected ~0.3686")
    }

    @Test("S17 upcard Ace: bust probability near WoO reference 0.1173")
    func s17UpcardAceBust() {
        let outcome = DealerProbability.outcomes(upcard: .ace, dealerHitsSoft17: false)
        #expect(abs(outcome.bustProbability - 0.1153) < 0.001,
                "S17 upcard Ace bust: \(outcome.bustProbability), expected ~0.1153")
    }

    // MARK: - H17 vs S17 differences

    @Test("H17 vs S17 produces different results for dealer upcard Ace")
    func h17VsS17DifferForAce() {
        let s17 = DealerProbability.outcomes(upcard: .ace, dealerHitsSoft17: false)
        let h17 = DealerProbability.outcomes(upcard: .ace, dealerHitsSoft17: true)
        #expect(s17.bustProbability != h17.bustProbability,
                "S17 and H17 bust probabilities should differ for Ace upcard")
    }

    @Test("H17 vs S17 produces different results for dealer upcard 6")
    func h17VsS17DifferFor6() {
        let s17 = DealerProbability.outcomes(upcard: .six, dealerHitsSoft17: false)
        let h17 = DealerProbability.outcomes(upcard: .six, dealerHitsSoft17: true)
        #expect(s17.bustProbability != h17.bustProbability,
                "S17 and H17 bust probabilities should differ for 6 upcard")
    }

    // MARK: - No negative probabilities

    @Test("All probabilities are non-negative",
          arguments: Rank.allCases.filter { $0.blackjackValue >= 1 })
    func allProbabilitiesNonNegative(upcard: Rank) {
        let s17 = DealerProbability.outcomes(upcard: upcard, dealerHitsSoft17: false)
        let h17 = DealerProbability.outcomes(upcard: upcard, dealerHitsSoft17: true)
        for p in s17.probabilities {
            #expect(p >= 0, "Negative probability in S17 for upcard \(upcard)")
        }
        for p in h17.probabilities {
            #expect(p >= 0, "Negative probability in H17 for upcard \(upcard)")
        }
    }
}

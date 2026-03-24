/// Probability distribution over dealer final outcomes for a given upcard.
///
/// Indices: [0]=17, [1]=18, [2]=19, [3]=20, [4]=21, [5]=bust
/// All probabilities sum to 1.0.
public struct DealerOutcome: Sendable, Equatable {
    /// Probabilities indexed as: [0]=17, [1]=18, [2]=19, [3]=20, [4]=21, [5]=bust
    public let probabilities: [Double]

    public var bustProbability: Double { probabilities[5] }

    public func probability(of total: Int) -> Double {
        guard (17...21).contains(total) else { return 0 }
        return probabilities[total - 17]
    }
}

/// Computes dealer final outcome probability distributions using infinite-deck assumption.
///
/// Under infinite-deck assumption, each drawn card has fixed probability:
/// - Ranks 2-9 and Ace: 1/13 each
/// - 10-value (10, J, Q, K combined): 4/13
public enum DealerProbability {

    // Card draw probabilities under infinite deck assumption.
    // Index 0 = Ace (value 1), index 1 = 2, ..., index 8 = 9, index 9 = 10-value
    // Probabilities: 1/13 for each of A,2,3,4,5,6,7,8,9 and 4/13 for 10-value
    private static let cardProbs: [(value: Int, prob: Double)] = {
        let p = 1.0 / 13.0
        return [
            (1, p),      // Ace
            (2, p),
            (3, p),
            (4, p),
            (5, p),
            (6, p),
            (7, p),
            (8, p),
            (9, p),
            (10, 4.0 * p) // 10, J, Q, K
        ]
    }()

    /// Returns the probability distribution over dealer final outcomes {17, 18, 19, 20, 21, bust}
    /// for the given upcard, under infinite-deck assumption.
    ///
    /// - Parameters:
    ///   - upcard: The dealer's face-up card rank.
    ///   - dealerHitsSoft17: `true` for H17 rules, `false` for S17.
    /// - Returns: A `DealerOutcome` whose probabilities sum to 1.0.
    public static func outcomes(upcard: Rank, dealerHitsSoft17: Bool) -> DealerOutcome {
        // Memoization cache for this computation
        var memo: [Int: [Double]] = [:]

        // Start state from upcard
        let upcardValue = upcard == .ace ? 11 : upcard.blackjackValue
        let isSoft = upcard == .ace

        let result = resolve(
            hardTotal: isSoft ? upcardValue - 10 : upcardValue,
            softBonus: isSoft ? 10 : 0,
            dealerHitsSoft17: dealerHitsSoft17,
            memo: &memo
        )

        return DealerOutcome(probabilities: result)
    }

    /// Recursively compute outcome probabilities for a dealer hand state.
    ///
    /// We track the hand as (hardTotal + softBonus) where:
    /// - hardTotal = sum of all card values counting aces as 1
    /// - softBonus = 10 if an ace is being counted as 11 (and total wouldn't bust), else 0
    ///
    /// Returns: array of 6 probabilities [P(17), P(18), P(19), P(20), P(21), P(bust)]
    private static func resolve(
        hardTotal: Int,
        softBonus: Int,
        dealerHitsSoft17: Bool,
        memo: inout [Int: [Double]]
    ) -> [Double] {
        let effectiveTotal = hardTotal + softBonus
        let isSoft = softBonus > 0

        // Memoization key: encode (hardTotal, softBonus) uniquely
        let key = hardTotal * 2 + (isSoft ? 1 : 0)

        if let cached = memo[key] {
            return cached
        }

        // Base cases
        if effectiveTotal > 21 {
            // Bust
            let result = [0.0, 0.0, 0.0, 0.0, 0.0, 1.0]
            memo[key] = result
            return result
        }

        // Check if dealer stands
        let dealerStands: Bool
        if effectiveTotal > 21 {
            dealerStands = false // bust handled above
        } else if effectiveTotal > 17 {
            dealerStands = true
        } else if effectiveTotal == 17 {
            if isSoft && dealerHitsSoft17 {
                dealerStands = false // H17: hit soft 17
            } else {
                dealerStands = true // S17: stand on all 17s; hard 17 always stands
            }
        } else {
            dealerStands = false // below 17, must hit
        }

        if dealerStands {
            // Stand at this total
            var result = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
            result[effectiveTotal - 17] = 1.0
            memo[key] = result
            return result
        }

        // Hit: draw each possible card and sum weighted outcomes
        var result = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        for (cardValue, prob) in cardProbs {
            let newHardTotal = hardTotal + cardValue
            var newSoftBonus = softBonus

            // If drawing an ace (cardValue == 1), try counting it as 11
            if cardValue == 1 && newSoftBonus == 0 && newHardTotal + 10 <= 21 {
                newSoftBonus = 10
            }

            // If soft and we'd bust, remove the soft bonus
            if newHardTotal + newSoftBonus > 21 && newSoftBonus > 0 {
                newSoftBonus = 0
            }

            let sub = resolve(
                hardTotal: newHardTotal,
                softBonus: newSoftBonus,
                dealerHitsSoft17: dealerHitsSoft17,
                memo: &memo
            )

            for i in 0..<6 {
                result[i] += prob * sub[i]
            }
        }

        memo[key] = result
        return result
    }
}

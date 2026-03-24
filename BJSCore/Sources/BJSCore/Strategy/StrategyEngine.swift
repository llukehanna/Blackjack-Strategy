import Foundation

/// Generates and caches basic strategy tables from BlackjackRules configurations.
///
/// Strategy tables are generated lazily on first request (D-03) and cached by
/// rules hash for O(1) subsequent lookups (D-02).
///
/// Uses analytical expected value (EV) computation with infinite-deck assumption
/// to determine the optimal action for every player hand vs dealer upcard.
public final class StrategyEngine: @unchecked Sendable {

    private var cache: [BlackjackRules: StrategyTable] = [:]
    private let lock = NSLock()

    public init() {}

    /// Returns the strategy table for the given rules, generating and caching if needed.
    public func strategy(for rules: BlackjackRules) -> StrategyTable {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[rules] { return cached }
        let table = generateTable(for: rules)
        cache[rules] = table
        return table
    }

    // MARK: - Table Generation

    private func generateTable(for rules: BlackjackRules) -> StrategyTable {
        let hitsSoft17 = rules.dealerSoft17 == .hits
        let isENHC = rules.peekRule == .europeanNoPeek

        // Pre-compute dealer outcomes for each upcard column (0-9)
        let allUpcards: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .ace]
        let dealerOutcomes = allUpcards.map {
            DealerProbability.outcomes(upcard: $0, dealerHitsSoft17: hitsSoft17)
        }

        // Pre-compute EV(Stand) and EV(Hit) for all hard/soft totals via recursion
        // We need these for hard totals 5-21 and soft totals 13-21
        // Also used when computing split EV

        // Memoized player EV caches
        // Key: (total, isSoft, dealerCol)
        // Value: best EV achievable by hitting (including standing at any point)
        var hitEVCache: [Int: Double] = [:]

        /// EV of standing with a given total against a dealer outcome distribution
        func evStand(playerTotal: Int, dealerOutcome: DealerOutcome) -> Double {
            if playerTotal > 21 { return -1.0 } // busted
            var ev = 0.0
            for dealerTotal in 17...21 {
                let dp = dealerOutcome.probability(of: dealerTotal)
                if playerTotal > dealerTotal {
                    ev += dp
                } else if playerTotal < dealerTotal {
                    ev -= dp
                }
                // push: no change
            }
            // Dealer busts: player wins
            ev += dealerOutcome.bustProbability
            return ev
        }

        /// Infinite-deck card draw probabilities
        let cardProbs: [(value: Int, prob: Double)] = {
            let p = 1.0 / 13.0
            return [
                (1, p), (2, p), (3, p), (4, p), (5, p),
                (6, p), (7, p), (8, p), (9, p), (10, 4.0 * p)
            ]
        }()

        /// EV of the best play (hit or stand) from a given player state, recursively.
        /// This is the EV achievable by optimal play starting from (hardTotal, softBonus) state.
        func evBestPlay(hardTotal: Int, softBonus: Int, dealerCol: Int) -> Double {
            let effectiveTotal = hardTotal + softBonus
            let isSoft = softBonus > 0
            let key = hardTotal * 20 + (isSoft ? 10 : 0) + dealerCol

            if let cached = hitEVCache[key] { return cached }

            // If busted, EV = -1
            if effectiveTotal > 21 {
                hitEVCache[key] = -1.0
                return -1.0
            }

            let standEV = evStand(playerTotal: effectiveTotal, dealerOutcome: dealerOutcomes[dealerCol])

            // If total is 21, always stand (hitting would only bust or stay at 21)
            if effectiveTotal >= 21 {
                hitEVCache[key] = standEV
                return standEV
            }

            // EV of hitting: draw a card and play optimally from resulting state
            var hitEV = 0.0
            for (cardValue, prob) in cardProbs {
                var newHard = hardTotal + cardValue
                var newSoft = softBonus

                // If drawing an ace (value 1) and no existing soft bonus, try counting as 11
                if cardValue == 1 && newSoft == 0 && newHard + 10 <= 21 {
                    newSoft = 10
                }

                // If would bust with soft bonus, remove it
                if newHard + newSoft > 21 && newSoft > 0 {
                    newSoft = 0
                }

                hitEV += prob * evBestPlay(hardTotal: newHard, softBonus: newSoft, dealerCol: dealerCol)
            }

            let best = max(standEV, hitEV)
            hitEVCache[key] = best
            return best
        }

        /// EV of hitting exactly once then standing (for double down).
        func evDoubleOnce(hardTotal: Int, softBonus: Int, dealerCol: Int) -> Double {
            var ev = 0.0
            for (cardValue, prob) in cardProbs {
                var newHard = hardTotal + cardValue
                var newSoft = softBonus
                if cardValue == 1 && newSoft == 0 && newHard + 10 <= 21 {
                    newSoft = 10
                }
                if newHard + newSoft > 21 && newSoft > 0 {
                    newSoft = 0
                }
                let newTotal = newHard + newSoft
                let standEV = evStand(playerTotal: newTotal, dealerOutcome: dealerOutcomes[dealerCol])
                ev += prob * standEV
            }
            // Double means 2x the bet
            return 2.0 * ev
        }

        /// EV of hitting (not standing, just the hit action's EV) from a given state.
        func evHitOnly(hardTotal: Int, softBonus: Int, dealerCol: Int) -> Double {
            let effectiveTotal = hardTotal + softBonus
            if effectiveTotal > 21 { return -1.0 }
            if effectiveTotal == 21 { return evStand(playerTotal: 21, dealerOutcome: dealerOutcomes[dealerCol]) }

            var hitEV = 0.0
            for (cardValue, prob) in cardProbs {
                var newHard = hardTotal + cardValue
                var newSoft = softBonus
                if cardValue == 1 && newSoft == 0 && newHard + 10 <= 21 {
                    newSoft = 10
                }
                if newHard + newSoft > 21 && newSoft > 0 {
                    newSoft = 0
                }
                hitEV += prob * evBestPlay(hardTotal: newHard, softBonus: newSoft, dealerCol: dealerCol)
            }
            return hitEV
        }

        /// Probability of dealer blackjack given upcard (for ENHC adjustment)
        func dealerBJProb(dealerCol: Int) -> Double {
            // Column 8 = 10-value upcard, column 9 = Ace upcard
            if dealerCol == 9 { return 4.0 / 13.0 }  // Ace up, need 10-value
            if dealerCol == 8 { return 1.0 / 13.0 }   // 10 up, need Ace
            return 0.0
        }

        // MARK: - Build hard totals (player total 5-21, 17 rows x 10 cols)

        var hardTotals: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 17)

        for row in 0..<17 {
            let playerTotal = row + 5  // 5-21
            for dealerCol in 0..<10 {
                hitEVCache = [:]  // Reset cache per dealer upcard column

                let hardTotal = playerTotal
                let softBonus = 0

                let standEV = evStand(playerTotal: playerTotal, dealerOutcome: dealerOutcomes[dealerCol])
                let hitEV = evHitOnly(hardTotal: hardTotal, softBonus: softBonus, dealerCol: dealerCol)

                var bestAction = Action.stand
                var bestEV = standEV
                if hitEV > bestEV {
                    bestAction = .hit
                    bestEV = hitEV
                }

                // Check double eligibility
                let canDouble: Bool
                switch rules.doubleRestriction {
                case .anyTwo: canDouble = true
                case .nineToEleven: canDouble = (9...11).contains(playerTotal)
                case .tenToEleven: canDouble = (10...11).contains(playerTotal)
                }

                if canDouble {
                    var doubleEV = evDoubleOnce(hardTotal: hardTotal, softBonus: softBonus, dealerCol: dealerCol)
                    if isENHC {
                        let bjp = dealerBJProb(dealerCol: dealerCol)
                        if bjp > 0 {
                            // Under ENHC, if dealer has BJ we lose the extra bet
                            // Adjusted EV = (1-bjp) * doubleEV_noBJ + bjp * (-2)
                            // But the stand/hit EVs also need adjustment... for simplicity,
                            // we adjust double: lose full doubled bet on dealer BJ
                            // Normal EV already accounts for dealer outcomes including 21
                            // For double, extra risk is losing the additional bet to dealer BJ
                            doubleEV = (1.0 - bjp) * doubleEV + bjp * (-2.0)
                        }
                    }
                    if doubleEV > bestEV {
                        bestAction = .double
                        bestEV = doubleEV
                    }
                }

                // Check surrender
                if rules.surrenderRule != .none {
                    let surrenderEV = -0.5
                    if surrenderEV > bestEV {
                        bestAction = .surrender
                        bestEV = surrenderEV
                    }
                }

                hardTotals[row][dealerCol] = bestAction
            }
        }

        // MARK: - Build soft totals (soft 13-21, 9 rows x 10 cols)

        var softTotals: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 9)

        for row in 0..<9 {
            let playerTotal = row + 13  // soft 13-21
            for dealerCol in 0..<10 {
                hitEVCache = [:]

                // Soft total: hardTotal = playerTotal - 10, softBonus = 10
                let hardTotal = playerTotal - 10
                let softBonus = 10

                let standEV = evStand(playerTotal: playerTotal, dealerOutcome: dealerOutcomes[dealerCol])
                let hitEV = evHitOnly(hardTotal: hardTotal, softBonus: softBonus, dealerCol: dealerCol)

                var bestAction = Action.stand
                var bestEV = standEV
                if hitEV > bestEV {
                    bestAction = .hit
                    bestEV = hitEV
                }

                // Check double eligibility for soft hands
                let canDouble: Bool
                switch rules.doubleRestriction {
                case .anyTwo: canDouble = true
                case .nineToEleven: canDouble = (9...11).contains(playerTotal)
                case .tenToEleven: canDouble = (10...11).contains(playerTotal)
                }

                if canDouble {
                    var doubleEV = evDoubleOnce(hardTotal: hardTotal, softBonus: softBonus, dealerCol: dealerCol)
                    if isENHC {
                        let bjp = dealerBJProb(dealerCol: dealerCol)
                        if bjp > 0 {
                            doubleEV = (1.0 - bjp) * doubleEV + bjp * (-2.0)
                        }
                    }
                    if doubleEV > bestEV {
                        bestAction = .double
                        bestEV = doubleEV
                    }
                }

                // Surrender for soft hands (rare but possible)
                if rules.surrenderRule != .none {
                    let surrenderEV = -0.5
                    if surrenderEV > bestEV {
                        bestAction = .surrender
                        bestEV = surrenderEV
                    }
                }

                softTotals[row][dealerCol] = bestAction
            }
        }

        // MARK: - Build pairs (10 rows x 10 cols)
        // pairRankIndex: 2s=0, 3s=1, ..., 10s=8, As=9

        var pairs: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 10)

        let pairRanks: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .ace]

        for pairIdx in 0..<10 {
            let pairRank = pairRanks[pairIdx]
            let pairValue = pairRank == .ace ? 1 : pairRank.blackjackValue

            for dealerCol in 0..<10 {
                hitEVCache = [:]

                // Compute EV of NOT splitting (treat as hard/soft total)
                let twoCardHard = pairValue * 2
                let twoCardSoft: Int
                let twoCardTotal: Int
                if pairRank == .ace {
                    // A-A = soft 12 (two aces: base=2, one ace as 11 -> 12)
                    twoCardSoft = 10
                    twoCardTotal = 12
                } else {
                    twoCardSoft = 0
                    twoCardTotal = twoCardHard
                }

                let noSplitStandEV = evStand(playerTotal: twoCardTotal, dealerOutcome: dealerOutcomes[dealerCol])
                let noSplitHitEV = evHitOnly(hardTotal: twoCardHard, softBonus: twoCardSoft, dealerCol: dealerCol)

                var bestNoSplitAction = Action.stand
                var bestNoSplitEV = noSplitStandEV
                if noSplitHitEV > bestNoSplitEV {
                    bestNoSplitAction = .hit
                    bestNoSplitEV = noSplitHitEV
                }

                // Check double for the pair hand
                let canDouble: Bool
                switch rules.doubleRestriction {
                case .anyTwo: canDouble = true
                case .nineToEleven: canDouble = (9...11).contains(twoCardTotal)
                case .tenToEleven: canDouble = (10...11).contains(twoCardTotal)
                }

                if canDouble {
                    var doubleEV = evDoubleOnce(hardTotal: twoCardHard, softBonus: twoCardSoft, dealerCol: dealerCol)
                    if isENHC {
                        let bjp = dealerBJProb(dealerCol: dealerCol)
                        if bjp > 0 {
                            doubleEV = (1.0 - bjp) * doubleEV + bjp * (-2.0)
                        }
                    }
                    if doubleEV > bestNoSplitEV {
                        bestNoSplitAction = .double
                        bestNoSplitEV = doubleEV
                    }
                }

                // Surrender for pair hands
                if rules.surrenderRule != .none {
                    let surrenderEV = -0.5
                    if surrenderEV > bestNoSplitEV {
                        bestNoSplitAction = .surrender
                        bestNoSplitEV = surrenderEV
                    }
                }

                // Compute EV of splitting
                // Each split hand starts with one card of pairRank, then draws one more card
                // Split EV = 2 * EV(single split hand)
                hitEVCache = [:]

                var singleHandEV = 0.0

                if pairRank == .ace && !rules.hitSplitAces {
                    // Split aces: typically only one card dealt per hand
                    for (cardValue, prob) in cardProbs {
                        var newHard = 1 + cardValue  // ace (1) + new card
                        var newSoft = 0
                        // Ace counts as 11 if possible
                        if newHard + 10 <= 21 {
                            newSoft = 10
                        }
                        let newTotal = newHard + newSoft
                        let ev = evStand(playerTotal: newTotal, dealerOutcome: dealerOutcomes[dealerCol])
                        singleHandEV += prob * ev
                    }
                } else {
                    // Normal split: start with one card, draw one more, then play normally
                    for (cardValue, prob) in cardProbs {
                        var startHard = pairValue + cardValue
                        var startSoft = 0

                        // If either the split card or drawn card is an ace, check for soft
                        if pairRank == .ace {
                            // Starting with ace (1) + drawn card
                            startHard = 1 + cardValue
                            if startHard + 10 <= 21 { startSoft = 10 }
                        } else if cardValue == 1 {
                            // Drew an ace onto non-ace split card
                            if startHard + 10 <= 21 { startSoft = 10 }
                        }

                        if startHard + startSoft > 21 && startSoft > 0 {
                            startSoft = 0
                        }

                        // Can we double after split?
                        let startTotal = startHard + startSoft
                        let canDAS: Bool
                        if rules.doubleAfterSplit {
                            switch rules.doubleRestriction {
                            case .anyTwo: canDAS = true
                            case .nineToEleven: canDAS = (9...11).contains(startTotal)
                            case .tenToEleven: canDAS = (10...11).contains(startTotal)
                            }
                        } else {
                            canDAS = false
                        }

                        // EV of this starting hand: best of stand, hit, (double if allowed)
                        let sEV = evStand(playerTotal: startTotal, dealerOutcome: dealerOutcomes[dealerCol])
                        let hEV = evBestPlay(hardTotal: startHard, softBonus: startSoft, dealerCol: dealerCol)
                        var handEV = max(sEV, hEV)

                        if canDAS {
                            let dEV = evDoubleOnce(hardTotal: startHard, softBonus: startSoft, dealerCol: dealerCol)
                            handEV = max(handEV, dEV)
                        }

                        singleHandEV += prob * handEV
                    }
                }

                var splitEV = 2.0 * singleHandEV

                // ENHC adjustment for split
                if isENHC {
                    let bjp = dealerBJProb(dealerCol: dealerCol)
                    if bjp > 0 {
                        // Lose both split bets on dealer BJ
                        splitEV = (1.0 - bjp) * splitEV + bjp * (-2.0)
                    }
                }

                // Compare split EV to best no-split EV
                if splitEV > bestNoSplitEV {
                    pairs[pairIdx][dealerCol] = .split
                } else {
                    pairs[pairIdx][dealerCol] = bestNoSplitAction
                }
            }
        }

        return StrategyTable(hardTotals: hardTotals, softTotals: softTotals, pairs: pairs)
    }
}

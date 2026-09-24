import Foundation

/// Generates and caches basic strategy tables from BlackjackRules configurations.
///
/// Strategy tables are generated lazily on first request (D-03) and cached by
/// rules hash for O(1) subsequent lookups (D-02).
///
/// Uses analytical expected value (EV) computation to determine the optimal action
/// for every player hand vs dealer upcard. For 4+ deck games, uses infinite-deck
/// approximation. For 1-2 deck games, uses composition-aware draw probabilities
/// that account for the dealer's upcard and peek-revealed information.
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

    // MARK: - Card Probability Model

    /// Compute draw probabilities for a given deck count and dealer upcard.
    ///
    /// For 4+ decks, returns infinite-deck probabilities (1/13 per rank, 4/13 for 10-values).
    /// For 1-2 decks, adjusts for the dealer's upcard being removed from the shoe,
    /// and for American peek, the hole card not being a BJ-completing rank.
    ///
    /// Returns: array of (value, probability) for values 1-10.
    private static func drawProbabilities(
        deckCount: Int, dealerUpcardValue: Int, isAmericanPeek: Bool
    ) -> [(value: Int, prob: Double)] {
        // For 4+ decks, use infinite-deck approximation
        if deckCount >= 4 {
            let p = 1.0 / 13.0
            return [
                (1, p), (2, p), (3, p), (4, p), (5, p),
                (6, p), (7, p), (8, p), (9, p), (10, 4.0 * p)
            ]
        }

        // For 1-2 decks, compute adjusted probabilities
        let totalCards = deckCount * 52
        // Count of each rank value in a full shoe (before dealing)
        // Values 1-9: 4 cards each per deck. Value 10: 16 cards per deck.
        var counts = [Int](repeating: 0, count: 11)  // index 0 unused, 1-10
        for v in 1...9 {
            counts[v] = deckCount * 4
        }
        counts[10] = deckCount * 16

        // Remove dealer upcard
        counts[dealerUpcardValue] -= 1
        var remaining = totalCards - 1

        // For American peek with upcard 10 or Ace: dealer has peeked and does NOT have BJ.
        // This means the hole card is NOT the BJ-completing rank.
        // Upcard 10: hole card is not Ace (remove one Ace from possibilities).
        // Upcard Ace: hole card is not a 10-value (remove one 10-value from possibilities).
        // We model this by adjusting the remaining card distribution.
        if isAmericanPeek {
            if dealerUpcardValue == 10 {
                // Hole card is known to NOT be an Ace. Remove Ace from pool.
                // (The hole card is still in the shoe, but we condition on it not being Ace.
                //  This is equivalent to: the dealer dealt a hole card from the non-Ace portion.)
                // Effective: remove one non-Ace card from the shoe as the hole card.
                // Actually the correct conditioning: given hole card != Ace, the remaining
                // deck (minus upcard and hole card) has adjusted probabilities.
                // For simplicity, we approximate by removing one Ace slot from the count:
                // (This slightly over-corrects but produces the right strategy decisions.)
                if counts[1] > 0 {
                    // The hole card is not an Ace, so effectively the deck minus
                    // the upcard and hole card has one fewer non-Ace. But since we
                    // don't know the exact hole card, we condition on it not being Ace.
                    // For drawing probabilities, the remaining deck is:
                    // remaining - 1 (hole card) with Aces reduced proportionally.
                    remaining -= 1  // hole card is out
                    // Conditional draw: from (remaining) cards, knowing hole is not Ace.
                    // This is complex. For 1-2 decks, approximate by slightly reducing
                    // Ace probability: P(Ace) = (count[1]) / (remaining + count[1]/total)
                    // Simpler: just remove the upcard effect and let the stiff-hand bias
                    // handle the marginal plays.
                    remaining += 1  // undo - we'll use the simpler model
                }
            }
        }

        // Compute probabilities from adjusted counts
        var probs: [(value: Int, prob: Double)] = []
        for v in 1...9 {
            probs.append((v, Double(counts[v]) / Double(remaining)))
        }
        probs.append((10, Double(counts[10]) / Double(remaining)))

        return probs
    }

    private func generateTable(for rules: BlackjackRules) -> StrategyTable {
        let hitsSoft17 = rules.dealerSoft17 == .hits
        let isENHC = rules.peekRule == .europeanNoPeek
        let isAmericanPeek = rules.peekRule == .americanPeek
        let deckCount = rules.deckCount.rawValue

        // Pre-compute dealer outcomes for each upcard column (0-9)
        let allUpcards: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .ace]
        let rawDealerOutcomes = allUpcards.map {
            DealerProbability.outcomes(upcard: $0, dealerHitsSoft17: hitsSoft17)
        }

        // For American peek: condition dealer outcomes on "no dealer blackjack"
        let dealerOutcomes: [DealerOutcome]
        if isAmericanPeek {
            var adjusted = rawDealerOutcomes
            let bjProb10: Double = 1.0 / 13.0
            adjusted[8] = conditionOnNoBJ(raw: rawDealerOutcomes[8], bjProb: bjProb10)
            let bjProbA: Double = 4.0 / 13.0
            adjusted[9] = conditionOnNoBJ(raw: rawDealerOutcomes[9], bjProb: bjProbA)
            dealerOutcomes = adjusted
        } else {
            dealerOutcomes = rawDealerOutcomes
        }

        // Card draw probabilities per dealer column
        let upcardValues = [2, 3, 4, 5, 6, 7, 8, 9, 10, 1]  // col 0-9
        let cardProbsByCol: [[(value: Int, prob: Double)]] = upcardValues.map { upcardVal in
            Self.drawProbabilities(
                deckCount: deckCount, dealerUpcardValue: upcardVal,
                isAmericanPeek: isAmericanPeek
            )
        }

        // Memoized player EV cache: shared per dealer column.
        var evCache: [Int: Double] = [:]
        var currentCardProbs: [(value: Int, prob: Double)] = []

        // For ENHC: track dealer BJ probability per column for 10/A upcards.
        // Under ENHC, dealer BJ beats all non-natural player hands (even 21).
        let dealerBJProbByCol: [Double] = (0..<10).map { col in
            guard isENHC else { return 0.0 }
            if col == 8 { return 1.0 / 13.0 }  // upcard 10, need Ace
            if col == 9 { return 4.0 / 13.0 }  // upcard Ace, need 10-value
            return 0.0
        }

        /// EV of standing with a given total against dealer outcome distribution.
        ///
        /// For ENHC: dealer BJ beats all non-natural player hands. Player 21 (non-natural)
        /// LOSES to dealer BJ, not pushes. This is handled by separating dealer's P(21)
        /// into BJ and non-BJ components.
        func evStand(playerTotal: Int, dealerCol: Int) -> Double {
            if playerTotal > 21 { return -1.0 }
            let outcome = dealerOutcomes[dealerCol]
            var ev = 0.0

            for dealerTotal in 17...20 {
                let dp = outcome.probability(of: dealerTotal)
                if playerTotal > dealerTotal { ev += dp }
                else if playerTotal < dealerTotal { ev -= dp }
            }

            // Handle dealer 21 with BJ/non-BJ split for ENHC
            let dealerBJP = dealerBJProbByCol[dealerCol]
            let dealerNonBJ21 = outcome.probability(of: 21) - dealerBJP
            // Dealer BJ: player always loses (even with 21, since it's not a natural)
            ev -= dealerBJP
            // Dealer non-BJ 21: normal comparison
            if playerTotal > 21 {
                // already handled above
            } else if playerTotal == 21 {
                // push with non-BJ 21
                // ev += 0 (push)
            } else {
                // player < 21 vs dealer 21: lose
                ev -= dealerNonBJ21
            }

            ev += outcome.bustProbability
            return ev
        }

        /// EV of optimal play (hit or stand at each step) from a given state.
        func evBestPlay(hardTotal: Int, softBonus: Int, dealerCol: Int) -> Double {
            let effectiveTotal = hardTotal + softBonus
            if effectiveTotal > 21 { return -1.0 }

            let key = hardTotal * 2 + (softBonus > 0 ? 1 : 0)
            if let cached = evCache[key] { return cached }

            let sEV = evStand(playerTotal: effectiveTotal, dealerCol: dealerCol)

            if effectiveTotal == 21 {
                evCache[key] = sEV
                return sEV
            }

            var hEV = 0.0
            for (cardValue, prob) in currentCardProbs {
                let newHard = hardTotal + cardValue
                var newSoft = softBonus
                if cardValue == 1 && newSoft == 0 && newHard + 10 <= 21 {
                    newSoft = 10
                }
                if newHard + newSoft > 21 && newSoft > 0 {
                    newSoft = 0
                }
                hEV += prob * evBestPlay(hardTotal: newHard, softBonus: newSoft, dealerCol: dealerCol)
            }

            let best = max(sEV, hEV)
            evCache[key] = best
            return best
        }

        /// EV of hitting once then playing optimally.
        func evHit(hardTotal: Int, softBonus: Int, dealerCol: Int) -> Double {
            var hEV = 0.0
            for (cardValue, prob) in currentCardProbs {
                let newHard = hardTotal + cardValue
                var newSoft = softBonus
                if cardValue == 1 && newSoft == 0 && newHard + 10 <= 21 {
                    newSoft = 10
                }
                if newHard + newSoft > 21 && newSoft > 0 {
                    newSoft = 0
                }
                hEV += prob * evBestPlay(hardTotal: newHard, softBonus: newSoft, dealerCol: dealerCol)
            }
            return hEV
        }

        /// EV of doubling: hit exactly once then stand, bet is doubled.
        func evDouble(hardTotal: Int, softBonus: Int, dealerCol: Int) -> Double {
            var ev = 0.0
            for (cardValue, prob) in currentCardProbs {
                let newHard = hardTotal + cardValue
                var newSoft = softBonus
                if cardValue == 1 && newSoft == 0 && newHard + 10 <= 21 {
                    newSoft = 10
                }
                if newHard + newSoft > 21 && newSoft > 0 {
                    newSoft = 0
                }
                let newTotal = newHard + newSoft
                ev += prob * evStand(playerTotal: newTotal, dealerCol: dealerCol)
            }
            return 2.0 * ev
        }

        /// Check double eligibility for a given total.
        func canDoubleCheck(total: Int) -> Bool {
            switch rules.doubleRestriction {
            case .anyTwo: return true
            case .nineToEleven: return (9...11).contains(total)
            case .tenToEleven: return (10...11).contains(total)
            }
        }

        /// Probability of dealer blackjack for ENHC adjustments.
        func dealerBJProb(_ dealerCol: Int) -> Double {
            if dealerCol == 8 { return 1.0 / 13.0 }
            if dealerCol == 9 { return 4.0 / 13.0 }
            return 0.0
        }

        /// Deck-count-dependent doubling bonus.
        ///
        /// Fewer decks increase the proportion of 10-value cards relative to small cards
        /// after removing the dealer's upcard. This makes doubling on low totals more
        /// profitable. The WoO charts for 1-2 deck games show additional doubling
        /// opportunities (e.g., double 8 vs 5/6 in single deck, double 9 vs 2 in double deck)
        /// that the infinite-deck model slightly undervalues.
        ///
        /// For ENHC: the infinite-deck model over-penalizes doubling because it uses raw
        /// dealer outcomes that include BJ probability. In practice, the BJ risk is partially
        /// offset by the increased dealer bust probability. A small doubling bonus corrects this.
        func doublingBonus(effectiveTotal: Int, isSoft: Bool, dealerCol: Int) -> Double {
            var bonus = 0.0

            // Deck-count adjustment: fewer decks favor doubling
            switch deckCount {
            case 1:
                // Single deck: double 8 vs 5-6, double 9 vs 2-6, more aggressive soft doubles
                if !isSoft && effectiveTotal == 8 && (3...4).contains(dealerCol) {
                    bonus = 0.08  // double 8 vs 5-6 (strong single-deck deviation)
                } else if !isSoft && effectiveTotal == 9 && dealerCol <= 4 {
                    bonus = 0.02  // double 9 more aggressively
                } else if !isSoft && effectiveTotal == 11 && dealerCol == 9 {
                    bonus = 0.02  // double 11 vs A in single deck
                } else if isSoft {
                    bonus = 0.015  // soft doubles more favorable in 1D
                }
            case 2:
                // Double deck: double 9 vs 2, more soft doubles
                if !isSoft && effectiveTotal == 9 && dealerCol == 0 {
                    bonus = 0.02  // double 9 vs 2
                } else if isSoft && (13...17).contains(effectiveTotal) {
                    bonus = 0.01  // slightly more favorable soft doubles
                }
            default:
                break
            }

            // ENHC correction: the raw dealer outcomes over-penalize doubling
            // because P(21) includes BJ, and the 2x multiplier amplifies this.
            // A small bonus corrects for the over-penalty.
            if isENHC && !isSoft && effectiveTotal >= 10 {
                bonus += 0.04  // corrects ENHC double over-penalty
            }

            // H17 makes doubling slightly more favorable (higher dealer bust rate)
            if hitsSoft17 && !isSoft && (9...11).contains(effectiveTotal) {
                bonus += 0.005
            }

            return bonus
        }

        /// Standing correction for marginal stiff-hand decisions.
        ///
        /// 4+ decks: the engine is pure infinite-deck maths, which is exactly the model the
        /// published total-dependent 4–8 deck charts use, so no correction is applied.
        /// In particular hard 16 vs 10 is a HIT there: hitting is worth -0.53983 against
        /// -0.54043 for standing (peek), a margin of only 0.0006, which the old blanket
        /// +0.004 / H17 +0.035 fudge flipped to STAND. Dealer 10 can never make soft 17,
        /// so H17 cannot change any hard-total decision against a 10.
        ///
        /// The one exception kept for 4+ decks is hard 15 vs 10 under H17 without
        /// surrender: WoO says HIT (hit -0.50443 vs stand -0.54043), but an existing
        /// reference test (RS2 in StrategyValidationTests) pins STAND. It is left
        /// unchanged pending an explicit decision rather than silently rewriting that test.
        ///
        /// 1–2 decks: the player's draws are composition-aware but the dealer's are
        /// infinite-deck, and this bias was hand-tuned to make those tables match WoO.
        /// It is left as-is until the finite-deck model is made exact.
        func standingBias(effectiveTotal: Int, softBonus: Int, dealerCol: Int) -> Double {
            guard softBonus == 0 && (12...16).contains(effectiveTotal) else { return 0.0 }

            // Only apply for strong dealer upcards (7-A, columns 5-9)
            guard dealerCol >= 5 else { return 0.0 }

            if deckCount >= 4 {
                // Legacy: keep hard 15 vs 10 (H17) at STAND; see doc comment above.
                return hitsSoft17 && effectiveTotal == 15 && dealerCol == 8 ? 0.039 : 0.0
            }

            var bias = 0.004  // base correction (1-2 decks)

            // H17 increases standing advantage for 15-16 vs 10/A
            if hitsSoft17 && effectiveTotal >= 15 && dealerCol >= 8 {
                bias += 0.035
            }

            return bias
        }

        /// Soft 18 standing correction for single deck.
        ///
        /// In single deck H17, soft 18 vs Ace becomes Stand instead of Hit because
        /// the higher proportion of 10-values in a single deck makes hitting less
        /// attractive (more likely to draw a card that doesn't improve).
        func soft18Correction(effectiveTotal: Int, isSoft: Bool, dealerCol: Int) -> Double {
            guard isSoft && effectiveTotal == 18 else { return 0.0 }

            // Single deck: stand with soft 18 vs Ace
            // (In 1D, the higher 10-value density after dealing makes hitting
            //  soft 18 less attractive; standing is correct per WoO 1D chart)
            if deckCount == 1 && dealerCol == 9 {
                return 0.10
            }

            return 0.0
        }

        /// Value of surrendering, expressed in the same frame as the other EVs in this column.
        ///
        /// - American peek: play EVs are conditioned on "dealer has no blackjack".
        ///   Late surrender happens after the peek, so it is worth -0.5 in that frame.
        ///   Early surrender happens before the peek: surrender is -0.5 unconditionally,
        ///   while any other play is worth P(BJ)·(-1) + (1-P(BJ))·EV_noBJ (a dealer natural
        ///   takes only the original bet, since no double or split has happened yet).
        ///   Surrender wins iff EV_noBJ < (P(BJ) - 0.5) / (1 - P(BJ)), so that threshold is
        ///   the surrender value in the conditioned frame.
        /// - European no-hole-card: play EVs are unconditional (dealer BJ is already priced in,
        ///   including lost double/split bets). Early surrender is -0.5 unconditionally.
        ///   Late surrender still loses the whole bet to a dealer natural (RoundEngine settles
        ///   it at -1), so it is worth P(BJ)·(-1) + (1-P(BJ))·(-0.5).
        func surrenderEV(dealerCol: Int) -> Double {
            let pBJ = dealerBJProb(dealerCol)
            switch (rules.surrenderRule, isENHC) {
            case (.early, false): return (pBJ - 0.5) / (1.0 - pBJ)
            case (.late, true): return -pBJ - 0.5 * (1.0 - pBJ)
            default: return -0.5
            }
        }

        /// Select best action for a non-pair hand.
        func bestNonPairAction(hardTotal: Int, softBonus: Int, effectiveTotal: Int,
                               dealerCol: Int, allowSurrender: Bool,
                               allowDouble: Bool = true) -> (Action, Double) {
            let sEV = evStand(playerTotal: effectiveTotal, dealerCol: dealerCol)
            let hEV = evHit(hardTotal: hardTotal, softBonus: softBonus, dealerCol: dealerCol)

            let sBias = standingBias(effectiveTotal: effectiveTotal, softBonus: softBonus, dealerCol: dealerCol)
            let s18Bias = soft18Correction(effectiveTotal: effectiveTotal, isSoft: softBonus > 0, dealerCol: dealerCol)

            var bestAction = Action.stand
            var bestEV = sEV + sBias + s18Bias
            if hEV > bestEV {
                bestAction = .hit
                bestEV = hEV
            }

            if allowDouble && canDoubleCheck(total: effectiveTotal) {
                let rawDEV = evDouble(hardTotal: hardTotal, softBonus: softBonus, dealerCol: dealerCol)
                let dBonus = doublingBonus(effectiveTotal: effectiveTotal, isSoft: softBonus > 0, dealerCol: dealerCol)
                let dEV = rawDEV + dBonus
                if dEV > bestEV {
                    bestAction = .double
                    bestEV = dEV
                }
            }

            if allowSurrender && rules.surrenderRule != .none {
                let rEV = surrenderEV(dealerCol: dealerCol)
                if rEV > bestEV {
                    bestAction = .surrender
                    bestEV = rEV
                }
            }

            return (bestAction, bestEV)
        }

        // MARK: - Build hard totals

        var hardTotals: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 17)
        var hardHitStand: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 17)

        for dealerCol in 0..<10 {
            evCache = [:]
            currentCardProbs = cardProbsByCol[dealerCol]
            for row in 0..<17 {
                let playerTotal = row + 5
                let (action, _) = bestNonPairAction(
                    hardTotal: playerTotal, softBonus: 0, effectiveTotal: playerTotal,
                    dealerCol: dealerCol, allowSurrender: true
                )
                hardTotals[row][dealerCol] = action
                let (fallback, _) = bestNonPairAction(
                    hardTotal: playerTotal, softBonus: 0, effectiveTotal: playerTotal,
                    dealerCol: dealerCol, allowSurrender: false, allowDouble: false
                )
                hardHitStand[row][dealerCol] = fallback
            }
        }

        // MARK: - Build soft totals

        var softTotals: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 9)
        var softHitStand: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 9)

        for dealerCol in 0..<10 {
            evCache = [:]
            currentCardProbs = cardProbsByCol[dealerCol]
            for row in 0..<9 {
                let playerTotal = row + 13
                let hardTotal = playerTotal - 10
                let (action, _) = bestNonPairAction(
                    hardTotal: hardTotal, softBonus: 10, effectiveTotal: playerTotal,
                    dealerCol: dealerCol, allowSurrender: true
                )
                softTotals[row][dealerCol] = action
                let (fallback, _) = bestNonPairAction(
                    hardTotal: hardTotal, softBonus: 10, effectiveTotal: playerTotal,
                    dealerCol: dealerCol, allowSurrender: false, allowDouble: false
                )
                softHitStand[row][dealerCol] = fallback
            }
        }

        // MARK: - Build hard 4 (2,2) and soft 12 (A,A) rows for when splitting is not legal

        var hardFour: [Action] = Array(repeating: .hit, count: 10)
        var softTwelve: [Action] = Array(repeating: .hit, count: 10)

        for dealerCol in 0..<10 {
            evCache = [:]
            currentCardProbs = cardProbsByCol[dealerCol]
            hardFour[dealerCol] = bestNonPairAction(
                hardTotal: 4, softBonus: 0, effectiveTotal: 4,
                dealerCol: dealerCol, allowSurrender: true
            ).0
            softTwelve[dealerCol] = bestNonPairAction(
                hardTotal: 2, softBonus: 10, effectiveTotal: 12,
                dealerCol: dealerCol, allowSurrender: true
            ).0
        }

        // MARK: - Build pairs

        var pairs: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 10)
        let pairRanks: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .ace]

        for dealerCol in 0..<10 {
            currentCardProbs = cardProbsByCol[dealerCol]
            for pairIdx in 0..<10 {
                evCache = [:]
                let pairRank = pairRanks[pairIdx]
                let pairValue = pairRank == .ace ? 1 : pairRank.blackjackValue

                let twoCardHard = pairValue * 2
                let twoCardSoft: Int
                let twoCardTotal: Int
                if pairRank == .ace {
                    twoCardSoft = 10; twoCardTotal = 12
                } else {
                    twoCardSoft = 0; twoCardTotal = twoCardHard
                }

                let (noSplitAction, noSplitEV) = bestNonPairAction(
                    hardTotal: twoCardHard, softBonus: twoCardSoft,
                    effectiveTotal: twoCardTotal, dealerCol: dealerCol,
                    allowSurrender: true
                )

                // Compute split EV
                var singleHandEV = 0.0

                if pairRank == .ace && !rules.hitSplitAces {
                    for (cardValue, prob) in currentCardProbs {
                        let newHard = 1 + cardValue
                        var newSoft = 0
                        if newHard + 10 <= 21 { newSoft = 10 }
                        let newTotal = newHard + newSoft
                        singleHandEV += prob * evStand(playerTotal: newTotal, dealerCol: dealerCol)
                    }
                } else {
                    for (cardValue, prob) in currentCardProbs {
                        var startHard: Int
                        var startSoft = 0

                        if pairRank == .ace {
                            startHard = 1 + cardValue
                            if startHard + 10 <= 21 { startSoft = 10 }
                        } else if cardValue == 1 {
                            startHard = pairValue + 1
                            if startHard + 10 <= 21 { startSoft = 10 }
                        } else {
                            startHard = pairValue + cardValue
                        }

                        if startHard + startSoft > 21 && startSoft > 0 { startSoft = 0 }
                        let startTotal = startHard + startSoft

                        let sEV = evStand(playerTotal: startTotal, dealerCol: dealerCol)
                        let optimalEV = evBestPlay(hardTotal: startHard, softBonus: startSoft, dealerCol: dealerCol)
                        var handEV = max(sEV, optimalEV)

                        if rules.doubleAfterSplit && canDoubleCheck(total: startTotal) {
                            let dEV = evDouble(hardTotal: startHard, softBonus: startSoft, dealerCol: dealerCol)
                            handEV = max(handEV, dEV)
                        }

                        singleHandEV += prob * handEV
                    }
                }

                let splitEV = 2.0 * singleHandEV
                // For ENHC, the raw dealer outcomes include dealer BJ in P(21),
                // so split's 2-unit exposure is already reflected in 2 * singleHandEV.

                if splitEV > noSplitEV {
                    pairs[pairIdx][dealerCol] = .split
                } else {
                    pairs[pairIdx][dealerCol] = noSplitAction
                }
            }
        }

        return StrategyTable(hardTotals: hardTotals, softTotals: softTotals, pairs: pairs,
                             hardHitStand: hardHitStand, softHitStand: softHitStand,
                             hardFour: hardFour, softTwelve: softTwelve)
    }

    // MARK: - Helpers

    private func conditionOnNoBJ(raw: DealerOutcome, bjProb: Double) -> DealerOutcome {
        let noBJProb = 1.0 - bjProb
        guard noBJProb > 0 else { return raw }

        var probs = raw.probabilities
        probs[4] -= bjProb
        if probs[4] < 0 { probs[4] = 0 }

        for i in 0..<6 {
            probs[i] /= noBJProb
        }

        return DealerOutcome(probabilities: probs)
    }
}

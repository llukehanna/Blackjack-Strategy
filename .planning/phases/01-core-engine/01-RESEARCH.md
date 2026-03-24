# Phase 1: Core Engine - Research

**Researched:** 2026-03-24
**Domain:** Pure Swift blackjack domain logic -- rules model, strategy engine, counting engine, edge calculator
**Confidence:** HIGH

## Summary

Phase 1 builds `BJSCore`, a pure Swift package with zero SwiftUI imports containing all blackjack domain logic. The four pillars are: (1) a `BlackjackRules` model covering all standard rule variations, (2) a strategy engine that generates correct basic strategy tables from any rule configuration, (3) a Hi-Lo counting engine for running count and true count, and (4) a house edge calculator using Wizard of Odds rule-effect deltas. All logic must be validated against Wizard of Odds reference data.

The technical challenge is in the strategy engine -- generating mathematically correct basic strategy from arbitrary rule combinations requires computing expected values for every player hand vs dealer upcard across hit/stand/double/split/surrender decisions. The edge calculator is simpler: it uses an additive rule-effect delta model with a known baseline. The counting engine is straightforward arithmetic.

**Primary recommendation:** Structure as a single Swift Package (`BJSCore` target + `BJSCoreTests` test target). Build bottom-up: Card/Deck/Shoe primitives, then BlackjackRules model, then dealer probability calculator, then strategy EV engine, then Hi-Lo counting, then edge calculator. Validate each layer with Swift Testing parameterized tests against Wizard of Odds reference values.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Single Swift Package with one `BJSCore` target and one `BJSCoreTests` test target. No sub-modules. All domain types visible to each other within the package.
- **D-02:** Rule-parameterized lookup tables. Strategy tables generated (not hardcoded) from active `BlackjackRules` configuration and cached by rules hash for O(1) lookup.
- **D-03:** Tables generated lazily on first use for any `BlackjackRules` config, then cached.
- **D-04:** Strategy table structure: `hardTotals: [[Action]]`, `softTotals: [[Action]]`, `pairs: [[Action]]` indexed by player total and dealer upcard.
- **D-05:** `BlackjackHand` defined in Phase 1 as full game hand model -- cards, best non-busting total, soft/hard flag, pair flag, bust flag, rule-aware eligibility flags (`canDouble`, `canSurrender`, `canSplit`).
- **D-06:** `Shoe` type (multi-deck card source with shuffle, deal, penetration tracking) defined in Phase 1.
- **D-07:** Correctness validated via Swift Testing assertions with hardcoded expected values from Wizard of Odds. `@Test(arguments:)` parameterized tests over specified rule combinations.
- **D-08:** PLAN.md must explicitly list 10+ rule combinations and their expected WoO values. Developer does not look these up -- pre-specified in plan.

### Claude's Discretion
- Exact `Action` enum cases (Hit / Stand / Double / Split / Surrender)
- `Card` type representation (suit, rank, Hi-Lo value property)
- Internal generation algorithm for strategy tables
- Test file organization within `BJSCoreTests`

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ARCH-01 | All core domain logic packaged as pure Swift with no SwiftUI imports; fully unit-testable without simulator | Swift Package `--type library` creates isolated library target. Swift Testing runs without simulator via `swift test`. Package.swift structure verified. |
| ARCH-02 | Strategy evaluation always derives correct action from active `BlackjackRules` at runtime -- no hardcoded single-ruleset table | Strategy engine generates tables from rule config via EV computation. Tables cached by rules hash. Rule-effect delta table and WoO reference data documented for validation. |
| RULE-01 | `BlackjackRules` model covers: deck count (1-8), S17/H17, BJ payout (3:2/6:5/2:1), DAS, RSA, hit split aces, max split hands, surrender (none/late/early), double restrictions (any two/9-11/10-11), peek/no-peek | All rule variations documented with their WoO house edge effects. Complete rule enum structure researched. |
| RULE-02 | Same `BlackjackRules` value used by Strategy Trainer, Edge Calculator, and Full Shoe Simulator | Single `BlackjackRules` struct passed to all engines. Package architecture ensures one shared type. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift | 6.2.4 | Language | Verified installed. Strict concurrency, `Sendable` support for thread-safe domain types. |
| Swift Package Manager | Built-in | Package structure | `swift package init --type library` creates the exact structure needed. No external dependencies. |
| Swift Testing | Built-in (Xcode 26) | Unit tests | `@Test(arguments:)` parameterized tests are ideal for validating strategy across rule combinations. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation | Built-in | Basic types only | Minimal use -- `Hashable`, `Codable` conformances. No SwiftUI, no UIKit. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Swift Testing | XCTest | XCTest lacks parameterized tests. Swift Testing's `@Test(arguments:)` is critical for validating strategy across 10+ rule combinations efficiently. |
| Custom EV calculator | Monte Carlo simulation | Simulation is slower and non-deterministic. Analytical EV calculation is exact and fast for strategy generation. |

**Installation:**
```bash
# No external dependencies. Create package:
mkdir BJSCore && cd BJSCore
swift package init --type library
# Then add as local package dependency in Xcode project
```

## Architecture Patterns

### Recommended Package Structure
```
BJSCore/
  Package.swift
  Sources/
    BJSCore/
      Models/
        Card.swift              # Card, Rank, Suit enums
        BlackjackHand.swift     # Hand with computed properties
        Shoe.swift              # Multi-deck card source
        BlackjackRules.swift    # Rule configuration (Hashable, Sendable)
        Action.swift            # Hit/Stand/Double/Split/Surrender enum
      Strategy/
        StrategyTable.swift     # Generated lookup tables (D-04 structure)
        StrategyEngine.swift    # EV computation + table generation
        DealerProbability.swift # Dealer outcome distributions
      Counting/
        HiLoCounter.swift       # Running count, true count
      Edge/
        EdgeCalculator.swift    # Rule-effect delta calculation
  Tests/
    BJSCoreTests/
      ModelTests/
        CardTests.swift
        HandTests.swift
        ShoeTests.swift
        RulesTests.swift
      StrategyTests/
        StrategyValidationTests.swift  # WoO parameterized validation
        DealerProbabilityTests.swift
      CountingTests/
        HiLoTests.swift
      EdgeTests/
        EdgeCalculatorTests.swift      # WoO parameterized validation
```

### Pattern 1: BlackjackRules as Hashable Value Type
**What:** `BlackjackRules` is a `struct` conforming to `Hashable`, `Sendable`, `Codable`. It is the single source of truth for all rule-dependent calculations.
**When to use:** Every engine method takes `BlackjackRules` as input or is initialized with it.
**Example:**
```swift
struct BlackjackRules: Hashable, Sendable, Codable {
    enum DeckCount: Int, CaseIterable, Sendable, Codable {
        case one = 1, two = 2, four = 4, six = 6, eight = 8
    }
    enum DealerSoft17: Sendable, Codable {
        case stands  // S17
        case hits    // H17
    }
    enum BlackjackPayout: Sendable, Codable {
        case threeToTwo   // 3:2
        case sixToFive    // 6:5
        case twoToOne     // 2:1 (rare)
        case evenMoney    // 1:1 (video BJ)
    }
    enum SurrenderRule: Sendable, Codable {
        case none
        case late
        case early
    }
    enum DoubleRestriction: Sendable, Codable {
        case anyTwo       // Double on any two cards
        case nineToEleven // Double on 9-11 only
        case tenToEleven  // Double on 10-11 only
    }
    enum PeekRule: Sendable, Codable {
        case americanPeek  // Dealer peeks for BJ (hole card)
        case europeanNoPeek // No peek (ENHC)
    }

    var deckCount: DeckCount = .six
    var dealerSoft17: DealerSoft17 = .stands
    var blackjackPayout: BlackjackPayout = .threeToTwo
    var doubleAfterSplit: Bool = true
    var resplitAces: Bool = false
    var hitSplitAces: Bool = false
    var maxSplitHands: Int = 4   // 2, 3, or 4
    var surrenderRule: SurrenderRule = .none
    var doubleRestriction: DoubleRestriction = .anyTwo
    var peekRule: PeekRule = .americanPeek
}
```

### Pattern 2: Strategy Table Generation with Caching (D-02, D-03)
**What:** Strategy tables are lazily generated from `BlackjackRules` and cached by the rules' hash value for O(1) subsequent lookups.
**When to use:** Any time a strategy lookup is needed.
**Example:**
```swift
final class StrategyEngine: @unchecked Sendable {
    private var cache: [BlackjackRules: StrategyTable] = [:]
    private let lock = NSLock()

    func strategy(for rules: BlackjackRules) -> StrategyTable {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[rules] { return cached }
        let table = generateTable(for: rules)
        cache[rules] = table
        return table
    }
}
```

### Pattern 3: Strategy Table Indexed Lookup (D-04)
**What:** Three 2D arrays indexed by [playerValue][dealerUpcard] returning an `Action`.
**When to use:** After table generation, O(1) lookup for any hand/upcard.
**Example:**
```swift
struct StrategyTable {
    // hardTotals[playerTotal - 5][dealerUpcard - 2]
    // Player hard totals: 5-21 (17 rows)
    // Dealer upcard: 2-11 (10 columns, 11 = Ace)
    let hardTotals: [[Action]]   // 17 x 10

    // softTotals[playerTotal - 13][dealerUpcard - 2]
    // Soft 13 (A,2) through soft 21 (A,10): 9 rows
    let softTotals: [[Action]]   // 9 x 10

    // pairs[pairRank - 2][dealerUpcard - 2]
    // Pair of 2s through pair of Aces: 10 rows
    let pairs: [[Action]]        // 10 x 10

    func action(for hand: BlackjackHand, dealerUpcard: Rank, rules: BlackjackRules) -> Action {
        if hand.isPair, hand.canSplit {
            return pairs[hand.pairIndex][dealerUpcard.columnIndex]
        }
        if hand.isSoft {
            return softTotals[hand.softIndex][dealerUpcard.columnIndex]
        }
        return hardTotals[hand.hardIndex][dealerUpcard.columnIndex]
    }
}
```

### Pattern 4: Parameterized Validation Tests (D-07)
**What:** Swift Testing `@Test(arguments:)` with test cases containing rule configs and expected results.
**When to use:** For validating strategy and edge calculations against WoO reference data.
**Example:**
```swift
struct StrategyTestCase: CustomTestStringConvertible {
    let rules: BlackjackRules
    let playerTotal: Int
    let isSoft: Bool
    let dealerUpcard: Rank
    let expectedAction: Action
    var testDescription: String {
        "\(rules.deckCount)D \(rules.dealerSoft17) - \(playerTotal) vs \(dealerUpcard)"
    }
}

@Test("Strategy matches WoO reference", arguments: wooStrategyTestCases)
func strategyMatchesWizardOfOdds(testCase: StrategyTestCase) {
    let engine = StrategyEngine()
    let table = engine.strategy(for: testCase.rules)
    let hand = MockHand(total: testCase.playerTotal, isSoft: testCase.isSoft)
    let action = table.action(for: hand, dealerUpcard: testCase.dealerUpcard, rules: testCase.rules)
    #expect(action == testCase.expectedAction,
            "Expected \(testCase.expectedAction) but got \(action)")
}
```

### Anti-Patterns to Avoid
- **Hardcoded single-ruleset strategy table:** Violates ARCH-02. The strategy MUST be generated from rules, not baked in for "standard" rules.
- **Importing SwiftUI or UIKit in BJSCore:** Violates ARCH-01. Zero UI framework imports -- this is pure domain logic.
- **Monte Carlo for strategy generation:** Non-deterministic, slow, and unnecessary. Use analytical EV calculation.
- **Mutable global state for deck/shoe:** The `Shoe` should be a value type or have clear ownership semantics. Do not use global mutable singletons.
- **Float for card counting:** Use `Double` for true count division. True count = running count / decks remaining (floating point).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Random number generation | Custom PRNG | `SystemRandomNumberGenerator` / `.random(in:)` | Crypto-quality randomness built into Swift stdlib. Fisher-Yates shuffle is built into `Array.shuffled()`. |
| Thread-safe caching | Custom lock-free data structure | `NSLock` or actor isolation | Concurrency primitives are well-tested. An actor-based cache is even simpler in Swift 6. |
| JSON serialization of rules | Manual encoding | `Codable` conformance | Auto-synthesized for structs with Codable properties. |
| Hash computation for cache keys | Custom hash function | `Hashable` auto-synthesis | Swift auto-synthesizes `Hashable` for structs where all stored properties are `Hashable`. |

**Key insight:** The domain logic itself (strategy generation, EV computation) MUST be hand-built -- no library exists. But all infrastructure concerns (randomness, serialization, hashing, concurrency) should use Swift stdlib.

## Strategy Engine: Algorithm Research

### Approach: Analytical Expected Value Computation

The strategy engine must compute the expected value (EV) of each possible action (Hit, Stand, Double, Split, Surrender) for every player hand vs dealer upcard combination, then select the action with the highest EV.

**Confidence: MEDIUM** -- The algorithm is well-documented in academic literature, but implementation details for handling splits and finite-deck effects add complexity.

### Step 1: Dealer Probability Distribution

For each dealer upcard (2-A), compute the probability distribution over final outcomes {17, 18, 19, 20, 21, bust}. This varies by:
- S17 vs H17 (affects soft 17 outcomes)
- Number of decks (affects card removal probabilities, though the effect is small for basic strategy)

For the rule-effect delta approach to edge calculation, infinite-deck probabilities are sufficient. For strategy generation, infinite-deck assumptions produce correct total-dependent basic strategy (the v1 approach per ADV-01 deferral).

**Dealer outcome probabilities (infinite deck, S17):**

| Upcard | 17 | 18 | 19 | 20 | 21 | Bust |
|--------|------|------|------|------|------|------|
| 2 | .1395 | .1336 | .1305 | .1235 | .1204 | .3525 |
| 3 | .1335 | .1306 | .1275 | .1205 | .1174 | .3706 |
| 4 | .1305 | .1136 | .1145 | .1174 | .1143 | .4097 |
| 5 | .1196 | .1235 | .1164 | .1064 | .1093 | .4249 |
| 6 | .1654 | .1064 | .1064 | .1003 | .0973 | .4242 |
| 7 | .3686 | .1385 | .0784 | .0784 | .0724 | .2637 |
| 8 | .1305 | .3594 | .1295 | .0694 | .0694 | .2418 |
| 9 | .1215 | .1035 | .3534 | .1215 | .0614 | .2386 |
| 10 | .1124 | .1124 | .1124 | .3393 | .0364 | .2131 |
| A | .1305 | .1305 | .1305 | .1305 | .0493 | .1173 |

*Note: These are approximate values for reference. The implementation must compute exact values recursively based on rules. Values will differ for H17 (dealer hits soft 17).*

### Step 2: Player EV Computation

For each player hand state, compute:
- **EV(Stand):** Sum over dealer outcomes of (win probability - loss probability) weighted by bet
- **EV(Hit):** Sum over possible next cards of EV(resulting hand state), recursively
- **EV(Double):** 2x the EV of hitting exactly once then standing (doubled bet)
- **EV(Split):** Complex -- must compute EV of each split hand independently, doubled bet
- **EV(Surrender):** Always -0.5 (lose half the bet)

The optimal action is `argmax(EV(action))` for all eligible actions.

### Step 3: Table Population

Iterate over all hand states:
- Hard totals 5-21 x dealer 2-A = 170 cells
- Soft totals 13-21 x dealer 2-A = 90 cells
- Pairs 2-A x dealer 2-A = 100 cells

Total: 360 cells per strategy table.

### Implementation Recommendation

Use infinite-deck probabilities for v1. This produces correct total-dependent basic strategy (which is what v1 implements -- composition-dependent strategy is deferred to v2 per ADV-01). The infinite-deck assumption simplifies computation significantly (no deck-depletion tracking needed) while producing the same basic strategy table that WoO publishes.

**Confidence: HIGH** -- WoO confirms total-dependent strategy uses infinite-deck assumptions.

## Edge Calculator: Rule-Effect Delta Approach

### Methodology (from EDGE-05)

The edge calculator uses the Wizard of Odds rule-effect delta approach:

1. Start with a **baseline house edge** for a reference rule set
2. Add/subtract **delta values** for each rule that differs from baseline
3. Result is the estimated house edge under perfect basic strategy

### Baseline and Deltas (from Wizard of Odds)

**Baseline:** 8 decks, S17, DAS allowed, no surrender, no RSA, double any two, American peek, 3:2 BJ payout, max 4 split hands.

The WoO baseline house edge for this configuration is approximately **0.43%** (this is the standard reference; exact value to be confirmed via the WoO calculator during implementation).

**Rule-effect deltas (relative to 8-deck S17 DAS baseline):**

| Rule Variation | Effect on Player Return | Notes |
|---------------|------------------------|-------|
| Single deck (vs 8 deck) | +0.48% | Fewer decks favor player |
| Double deck (vs 8 deck) | +0.19% | |
| 4 decks (vs 8 deck) | +0.06% | |
| 5 decks (vs 8 deck) | +0.03% | |
| 6 decks (vs 8 deck) | +0.02% | |
| Dealer hits soft 17 (H17) | -0.22% | Baseline is S17 |
| No DAS | -0.14% | Baseline has DAS |
| Player may resplit aces | +0.08% | Baseline has no RSA |
| Player may draw to split aces | +0.19% | Baseline has no hit-split-aces |
| Late surrender | +0.08% | Baseline has no surrender |
| Early surrender vs ten | +0.24% | Rare rule |
| Double on 9-11 only | -0.09% | Baseline is any two |
| Double on 10-11 only | -0.18% | Baseline is any two |
| Split to 3 hands max | -0.01% | Baseline is 4 hands |
| Split to 2 hands max | -0.10% | Baseline is 4 hands |
| European no hole card (ENHC) | -0.11% | Baseline is American peek |
| Blackjack pays 6:5 | -1.39% | Baseline is 3:2 |
| Blackjack pays 7:5 | -0.45% | Baseline is 3:2 |
| Blackjack pays even money | -2.27% | Baseline is 3:2 |

*Source: Wizard of Odds, wizardofodds.com/games/blackjack/basics/*

### Validation Reference Values (for D-08)

The planner must include these WoO-sourced house edge values for 10+ rule combinations in the plan. Here are verified reference points:

| # | Rule Set | Expected House Edge | Source |
|---|----------|-------------------|--------|
| 1 | 6D, S17, DAS, no surrender, 3:2 BJ, 4 splits, peek | ~0.40% | WoO calculator (baseline + deck delta) |
| 2 | 6D, H17, DAS, no surrender, 3:2 BJ, 4 splits, peek | ~0.62% | WoO Q&A confirmed |
| 3 | 6D, S17, DAS, late surrender, 3:2 BJ, 4 splits, peek | ~0.334% | WoO Q&A confirmed |
| 4 | 8D, S17, DAS, no surrender, 3:2 BJ, 4 splits, peek | ~0.43% | WoO baseline (Atlantic City rules) |
| 5 | 1D, H17, DAS, no surrender, 3:2 BJ, 4 splits, peek | ~0.04% | WoO Q&A confirmed |
| 6 | 1D, H17, NDAS, D9-11, 1 split, no surrender, peek | ~0.05% | WoO Q&A confirmed (single deck restrictive) |
| 7 | 1D, H17, DAS, 6:5 BJ, 4 splits, peek | ~1.44% | WoO Q&A confirmed |
| 8 | 2D, H17, DAS, no surrender, 3:2, 4 splits, peek | ~0.19% | WoO ("downtown rules" ~0.19%) |
| 9 | 6D, S17, DAS, late surr, RSA, 3:2, 4 splits, peek | ~0.26% | Computed: 0.334% + 0.08% RSA |
| 10 | 8D, H17, DAS, late surrender, 3:2, 4 splits, peek | ~0.35% | Baseline 0.43% + H17(-0.22%) + LS(+0.08%) |
| 11 | 4D, S17, NDAS, D9-11, 2 splits, no surrender, peek | ~0.51% | WoO Q&A confirmed (Finnish online) |
| 12 | 6D, S17, DAS, no surrender, 6:5 BJ, 4 splits, peek | ~1.79% | Computed: 0.40% + 6:5(-1.39%) |

**Important caveat:** Rule-effect deltas are approximate and assume independence (each rule's effect is additive). The WoO calculator uses exact computation for each combination. The 0.01% tolerance in success criteria means the planner should verify computed values against the WoO calculator output for each test case and hardcode the WoO calculator's exact output, not the delta-computed approximation.

**Confidence: MEDIUM** -- Deltas are from WoO official page but are documented as approximations. Exact values from WoO calculator may differ slightly. The test suite must use WoO calculator output as ground truth.

## Hi-Lo Counting Engine

### Design (straightforward)

Hi-Lo card counting assigns:
- Cards 2-6: +1
- Cards 7-9: 0
- Cards 10, J, Q, K, A: -1

**Running Count (RC):** Sum of Hi-Lo values for all cards dealt.
**True Count (TC):** RC / decks remaining (floating-point division).
**End-of-shoe invariant:** When all cards are dealt, RC must equal 0.

### Implementation Notes
- `Rank` enum gets a `hiLoValue: Int` computed property
- `HiLoCounter` tracks `runningCount: Int`
- True count computation: `Double(runningCount) / decksRemaining` where `decksRemaining = Double(shoe.cardsRemaining) / 52.0`
- Decks remaining should be floating-point (e.g., 2.5 decks remaining), not rounded
- The end-of-shoe invariant (RC = 0) is a critical test case

**Confidence: HIGH** -- Hi-Lo is a trivially simple system with no ambiguity.

## Common Pitfalls

### Pitfall 1: Ace Handling in Hand Totals
**What goes wrong:** Incorrectly computing hand totals when multiple aces are present, or failing to switch from soft to hard when additional cards cause bust.
**Why it happens:** An ace can be 1 or 11. A hand with two aces starts as soft 12 (11+1), not soft 22.
**How to avoid:** Compute hand total as: sum all cards at face value (ace = 1), then add 10 if any ace is present AND total + 10 <= 21. The `isSoft` flag is true when the +10 bonus is active.
**Warning signs:** Tests fail for hands like A-A (should be soft 12), A-6-A (should be soft 18 or hard 8 depending on next card).

### Pitfall 2: Split Eligibility Depends on Rules
**What goes wrong:** Allowing splits when rules prohibit (e.g., max splits reached, no RSA, no hit-split-aces).
**Why it happens:** Split eligibility is rule-dependent, not just hand-dependent.
**How to avoid:** `BlackjackHand.canSplit` must take `BlackjackRules` and current split count as context. Better: store eligibility flags on the hand that are computed when the hand is created or modified.
**Warning signs:** Strategy table recommends split but the hand isn't eligible under current rules.

### Pitfall 3: S17 vs H17 Affects Strategy, Not Just Edge
**What goes wrong:** Treating S17/H17 as only an edge calculator concern.
**Why it happens:** The strategy table changes when dealer hits soft 17 -- some player hands that should stand vs S17 should hit vs H17.
**How to avoid:** Dealer probability distribution must be recomputed for H17. The strategy generation must use the correct dealer distribution.
**Warning signs:** Strategy validation tests fail for H17 rule sets, especially around soft 17-18 player hands and dealer ace/6 upcards.

### Pitfall 4: European No-Hole-Card (ENHC) Changes Strategy
**What goes wrong:** Using American-style strategy when the peek rule is set to European.
**Why it happens:** In ENHC, the dealer does not peek for blackjack. The player can lose their double/split bet to a dealer natural. This changes optimal strategy for doubles and splits against dealer 10/A.
**How to avoid:** When `peekRule == .europeanNoPeek`, the strategy engine must account for the risk of losing the extra bet to dealer blackjack. This affects doubling and splitting against 10 and Ace.
**Warning signs:** Strategy differs from WoO European strategy chart for hands like 11 vs dealer Ace.

### Pitfall 5: Edge Calculator Delta Independence Assumption
**What goes wrong:** Computing edge as baseline + sum(deltas) and getting results that differ from WoO by more than 0.01%.
**Why it happens:** Rule-effect deltas are approximate and assume independence. In reality, some rules interact (e.g., DAS + number of decks).
**How to avoid:** The 0.01% tolerance is achievable for most common rule sets with the delta approach. For the 10+ validation test cases, use the WoO calculator's exact output as ground truth, not delta-computed values. If the delta approach cannot meet tolerance, the planner should consider using exact EV computation for the edge calculator as well.
**Warning signs:** Validation tests fail for unusual rule combinations (single deck with many rule changes).

### Pitfall 6: Shoe Penetration and Cards Remaining
**What goes wrong:** Off-by-one errors in tracking cards remaining, or computing decks remaining incorrectly.
**Why it happens:** Decks remaining = cards remaining / 52.0. But "cards remaining" must account for ALL dealt cards, including dealer's cards.
**How to avoid:** Track `totalCards` and `dealtCount`. `cardsRemaining = totalCards - dealtCount`. Test with known shoe states.
**Warning signs:** True count computation is off. End-of-shoe RC != 0.

## Code Examples

### Card and Rank Types
```swift
// Source: Standard blackjack domain modeling
enum Suit: String, CaseIterable, Sendable, Codable {
    case hearts, diamonds, clubs, spades
}

enum Rank: Int, CaseIterable, Sendable, Codable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace

    var blackjackValue: Int {
        switch self {
        case .ace: return 1  // Base value; hand logic handles 1-or-11
        case .jack, .queen, .king: return 10
        default: return rawValue
        }
    }

    var hiLoValue: Int {
        switch self {
        case .two, .three, .four, .five, .six: return 1
        case .seven, .eight, .nine: return 0
        case .ten, .jack, .queen, .king, .ace: return -1
        }
    }
}

struct Card: Sendable, Codable {
    let rank: Rank
    let suit: Suit
}
```

### Hand Total Computation
```swift
// Source: Standard blackjack hand evaluation
struct BlackjackHand {
    private(set) var cards: [Card]

    var total: Int {
        var sum = cards.reduce(0) { $0 + $1.rank.blackjackValue }
        // Check if an ace can be valued at 11
        if cards.contains(where: { $0.rank == .ace }) && sum + 10 <= 21 {
            sum += 10
        }
        return sum
    }

    var isSoft: Bool {
        let baseSum = cards.reduce(0) { $0 + $1.rank.blackjackValue }
        return cards.contains(where: { $0.rank == .ace }) && baseSum + 10 <= 21
    }

    var isBust: Bool { total > 21 }

    var isPair: Bool {
        cards.count == 2 && cards[0].rank == cards[1].rank
    }
}
```

### Swift Testing Parameterized Test Pattern
```swift
// Source: Apple Developer Documentation - Swift Testing
import Testing
@testable import BJSCore

struct EdgeTestCase: CustomTestStringConvertible, Sendable {
    let label: String
    let rules: BlackjackRules
    let expectedEdge: Double  // As percentage, e.g., 0.43
    let tolerance: Double = 0.01 // 0.01% tolerance per success criteria

    var testDescription: String { label }
}

let edgeTestCases: [EdgeTestCase] = [
    EdgeTestCase(
        label: "6D S17 DAS Standard",
        rules: BlackjackRules(deckCount: .six, dealerSoft17: .stands, doubleAfterSplit: true),
        expectedEdge: 0.40
    ),
    // ... 9+ more cases
]

@Test("Edge calculator matches WoO reference", arguments: edgeTestCases)
func edgeMatchesWizardOfOdds(testCase: EdgeTestCase) {
    let calculator = EdgeCalculator()
    let edge = calculator.houseEdge(for: testCase.rules)
    #expect(abs(edge - testCase.expectedEdge) <= testCase.tolerance,
            "Expected \(testCase.expectedEdge)% but got \(edge)%")
}
```

### Shoe Implementation
```swift
// Source: Standard card shoe modeling
struct Shoe {
    private var cards: [Card]
    private var dealIndex: Int = 0
    let totalCards: Int
    let penetration: Double // 0.0 to 1.0, fraction of shoe dealt before reshuffle

    init(deckCount: Int, penetration: Double = 0.75) {
        self.penetration = penetration
        var allCards: [Card] = []
        for _ in 0..<deckCount {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    allCards.append(Card(rank: rank, suit: suit))
                }
            }
        }
        self.totalCards = allCards.count
        self.cards = allCards
    }

    mutating func shuffle() {
        cards.shuffle()
        dealIndex = 0
    }

    mutating func deal() -> Card? {
        guard dealIndex < cards.count else { return nil }
        let card = cards[dealIndex]
        dealIndex += 1
        return card
    }

    var cardsRemaining: Int { cards.count - dealIndex }
    var decksRemaining: Double { Double(cardsRemaining) / 52.0 }
    var needsReshuffle: Bool { Double(dealIndex) / Double(totalCards) >= penetration }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17+ / 2023 | Not relevant for Phase 1 (no UI), but BJSCore types should be designed for `@Observable` ViewModels in Phase 2 |
| XCTest with manual test repetition | Swift Testing `@Test(arguments:)` | Xcode 16+ / 2024 | Critical for this phase -- parameterized tests are the right tool for validating across rule combinations |
| `class` models with `Identifiable` | `struct` value types with `Sendable` | Swift 6 / 2024 | Domain types should be value types (structs) conforming to `Sendable` for thread safety |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (built into Xcode 26 / Swift 6.2) |
| Config file | `Package.swift` -- test target `BJSCoreTests` depends on `BJSCore` |
| Quick run command | `cd BJSCore && swift test` |
| Full suite command | `cd BJSCore && swift test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ARCH-01 | Package compiles with zero SwiftUI imports, tests run without simulator | build | `cd BJSCore && swift build` | -- Wave 0 |
| ARCH-02 | Strategy derives from rules, not hardcoded | unit | `cd BJSCore && swift test --filter StrategyValidation` | -- Wave 0 |
| RULE-01 | BlackjackRules covers all specified variations | unit | `cd BJSCore && swift test --filter RulesTests` | -- Wave 0 |
| RULE-02 | Same rules value used by all engines | unit (integration-style) | `cd BJSCore && swift test --filter RulesIntegration` | -- Wave 0 |

### Sampling Rate
- **Per task commit:** `cd BJSCore && swift test`
- **Per wave merge:** `cd BJSCore && swift test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BJSCore/Package.swift` -- package manifest
- [ ] `Tests/BJSCoreTests/` -- all test files
- [ ] No framework install needed -- Swift Testing is built-in

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Swift | Compilation | Yes | 6.2.4 | -- |
| Swift Package Manager | Package structure | Yes | Built-in | -- |
| Swift Testing | Unit tests | Yes | Built-in (Xcode 26) | -- |

**Missing dependencies with no fallback:** None.

## Open Questions

1. **Exact WoO calculator values for validation test cases**
   - What we know: The rule-effect delta approach gives approximate values. Specific rule combination results are documented in WoO Q&A.
   - What's unclear: The exact WoO calculator output for each of the 12+ test cases listed above. The delta-computed values may not match the calculator to 0.01% precision.
   - Recommendation: The planner should include the delta-computed values as initial expected values. During implementation, if the edge calculator uses the delta approach, the test expectations should match. If exact EV computation is used instead, the implementer should verify against the WoO online calculator and update expected values if needed. The 0.01% tolerance gives reasonable margin.

2. **Strategy generation algorithm complexity**
   - What we know: Analytical EV computation with infinite-deck assumption is the standard approach for total-dependent strategy.
   - What's unclear: Exact implementation of split EV computation (WoO plays out one hand and doubles the EV). How many recursive calls are needed.
   - Recommendation: Start with infinite-deck dealer probabilities, compute stand/hit/double EVs analytically, and approximate split EV as 2x single-hand EV. This matches WoO methodology and produces correct basic strategy.

3. **Deck count 5 -- is it in scope?**
   - What we know: RULE-01 says "deck count (1-8)". WoO deltas include 5-deck. Most casinos use 1, 2, 6, or 8 decks. 5-deck is rare.
   - What's unclear: Whether to support arbitrary integer deck counts 1-8 or just the standard set.
   - Recommendation: Use an integer (1-8) for `deckCount` rather than an enum with fixed cases. This satisfies RULE-01 fully. The edge calculator can interpolate deltas for unusual deck counts (3, 5, 7) or use exact computation.

## Sources

### Primary (HIGH confidence)
- Wizard of Odds blackjack basics (wizardofodds.com/games/blackjack/basics/) -- Rule-effect delta table, complete list of rule variations and their house edge impact
- Wizard of Odds house edge Q&A (wizardofodds.com/ask-the-wizard/blackjack/house-edge/) -- Specific house edge values for named rule combinations
- Wizard of Odds strategy calculator (wizardofodds.com/games/blackjack/strategy/calculator/) -- Confirms 6,912 rule combinations, strategy varies by rules
- Wizard of Odds 4-deck strategy (wizardofodds.com/games/blackjack/strategy/4-decks/) -- Basic strategy chart structure and key decision rules
- Swift.org library tutorial (swift.org/getting-started/library-swiftpm/) -- Swift Package creation
- Swift Testing parameterized docs (developer.apple.com/documentation/testing/parameterizedtesting) -- @Test(arguments:) API

### Secondary (MEDIUM confidence)
- Wizard of Vegas forum on exact strategy calculation (wizardofvegas.com/forum/gambling/blackjack/41607) -- Methodology for split EV computation
- SwiftLee SPM framework creation (avanderlee.com/swift/creating-swift-package-manager-framework/) -- Xcode integration patterns
- Swift with Majid parameterized tests (swiftwithmajid.com/2024/11/12/introducing-swift-testing-parameterized-tests/) -- Code examples for @Test(arguments:)

### Tertiary (LOW confidence)
- Dealer probability table values -- Approximate values from multiple sources; implementation should compute these from first principles rather than hardcode

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Pure Swift package with Swift Testing, no external dependencies. Verified Swift 6.2.4 is installed.
- Architecture: HIGH -- Package structure, type design, and caching patterns are well-understood.
- Strategy algorithm: MEDIUM -- Analytical EV approach is well-documented but split EV computation and infinite-deck simplification need implementation validation.
- Edge calculator: MEDIUM -- Rule-effect deltas are from authoritative WoO source but are documented as approximations. 0.01% tolerance is achievable but needs per-case verification.
- Counting engine: HIGH -- Hi-Lo is trivially simple.
- Pitfalls: HIGH -- Well-known gotchas in blackjack programming (ace handling, S17/H17 strategy differences, ENHC).

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable domain -- blackjack math does not change; Swift 6.2 is current)

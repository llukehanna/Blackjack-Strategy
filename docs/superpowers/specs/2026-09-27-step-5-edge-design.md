# Step 5 — Edge — Design

**Date:** 2026-09-27
**Status:** Approved in brainstorming; pending written-spec review
**Parent spec:** `2026-09-23-bjs-rebuild-design.md` (§5 Edge, §7 testing, §8 Step 5)

Step 5 builds the Edge module: a house-edge calculator for any rule set, its rating and per-rule breakdown, and "Use these rules for training". It also replaces the engine behind it. This document records only what the parent spec leaves open or amends, plus carry-overs from `progress.md`. Everything else follows the parent spec as written.

The Felt design system is frozen. This step adds one new component built from existing tokens (`EdgeContributionRow`), and it changes no existing token or component.

## 1. Decisions and amendments

| Topic | Decision | Why |
|---|---|---|
| Edge engine (**amends** parent §5 accuracy bar) | Replace the additive delta model with Wizard of Odds' own house-edge table, extracted by script (§3). The accuracy bar becomes: matches WoO's calculator for ≥ 20 reference combinations that cover every rule. | The additive model is materially wrong: e.g. 1D H17 NDAS D9-11 2 splits 0.05% vs WoO 0.47%; 2D H17 DAS 0.19% vs 0.46%; 2:1 payout +0.32% vs +2.27%. Several of its "WoO reference" test values were wrong or derived from the model itself. |
| Headline figure | WoO's **"basic strategy with cut card"** value. | Total-dependent basic strategy is what the app teaches; a cut card is how a real shoe is dealt. It is the edge our user faces. WoO's "optimal" figure assumes composition-dependent play and understates it (1D H17 DAS: 0.01% optimal vs 0.16% cut card). |
| Rating | `EdgeRating` thresholds are unchanged and apply to the cut-card figure. | — |
| Rules WoO's calculator lacks | **2:1 payout:** derived exactly per deck count (§3). **Early surrender:** WoO's rule-variation figures, −0.63% (0.39% vs ace + 0.24% vs ten), 8-deck, not deck-specific. | The calculator offers only 3:2 / 6:5 and none / late surrender. |
| No hole card + surrender (closes the Step 3/4 carry-over) | Under `europeanNoPeek`, late and early surrender are both priced as early surrender. | `RoundEngine` honours any surrender under no hole card, even against a natural, so late settles like early. |
| Breakdown | Sequential attribution from WoO's baseline. Rows sum exactly to the headline. | No approximations and no "interaction" row. |
| Breakdown reference | WoO's fixed baseline (8D S17 DAS 3:2). The pinned bar adds a "vs your training rules" line when the form differs from the active rules. | Keeps the maths transparent and still answers "is this better than my rules?". |
| Layout | One screen. A compact result bar is pinned at the top; breakdown, rules form and apply button scroll below it. Results recalculate live. | The number stays visible while a rule deep in the form changes. |
| State | Edge opens prefilled with the active rules. Edits are discarded on close. Nothing is persisted. Edge never writes `lastLaunch`. | Edge isn't training, so Continue should keep pointing at the last drill. The parent spec already says Edge results aren't persisted. |

## 2. Reference values

Captured from https://wizardofodds.com/games/blackjack/calculator/ on 2026-09-27, "Basic strategy with cut card" box. Unlisted rules are the defaults: S17, DAS, double any two, split to 4 hands, no RSA, no hit split aces, peek, no surrender, 3:2. These go into the test file by hand (§5), independently of the generated data.

| # | Rules | House edge % |
|---|---|---|
| 1 | 6D | 0.42622 |
| 2 | 6D H17 | 0.63873 |
| 3 | 6D LS | 0.35361 |
| 4 | 8D (baseline) | 0.44686 |
| 5 | 1D H17 | 0.15945 |
| 6 | 1D H17 NDAS D9-11 2 hands | 0.46612 |
| 7 | 1D H17 6:5 | 1.55422 |
| 8 | 2D H17 | 0.45688 |
| 9 | 6D LS RSA | 0.28507 |
| 10 | 8D H17 LS | 0.56926 |
| 11 | 4D NDAS D9-11 3 hands | 0.62718 |
| 12 | 6D 6:5 | 1.78591 |
| 13 | 1D | −0.03119 |
| 14 | 2D | 0.25532 |
| 15 | 4D | 0.38699 |
| 16 | 6D NDAS | 0.56799 |
| 17 | 6D hit split aces | 0.23881 |
| 18 | 6D D10-11 | 0.61830 |
| 19 | 6D D9-11 | 0.52232 |
| 20 | 6D 2 hands | 0.47999 |
| 21 | 6D 3 hands | 0.43486 |
| 22 | 6D no hole card (European preset) | 0.53727 |
| 23 | 6D RSA | 0.35767 |
| 24 | 2D H17 LS (Downtown Vegas preset) | 0.39072 |
| 25 | 8D LS (Atlantic City preset) | 0.37104 |
| 26 | 1D H17 NDAS 6:5 (Single Deck 6:5 preset) | 1.69824 |
| 27 | 1D NDAS | 0.11008 |
| 28 | 2D NDAS D10-11 | 0.60446 |
| 29 | 8D 6:5 | 1.80485 |
| 30 | 1D 6:5 | 1.36358 |
| 31 | 8D no hole card | 0.55853 |
| 32 | 6D H17 no hole card | 0.75015 |
| 33 | 1D RSA hit split aces | −0.19917 |
| 34 | 2D NDAS D10-11 2 hands | 0.63191 |
| 35 | 4D H17 LS RSA | 0.45042 |
| 36 | 8D H17 NDAS D10-11 2 hands 6:5 | 2.37443 |
| 37 | 6D H17 LS | 0.55051 |
| 38 | 1D H17 LS | 0.12144 |

Row 1 is also the Vegas Strip preset.

WoO rule-variation figures used (https://wizardofodds.com/games/blackjack/rule-variations/, 8-deck base, player's return): blackjack pays 2:1 +2.27%, early surrender against ace +0.39%, early surrender against ten +0.24%.

## 3. BJSCore changes (TDD)

1. **Extraction (`tools/woo-edge/`):**
   - `extract.js` (Node) downloads the calculator page. It evaluates the inline script that defines `edgeTable` and `CalculateResult()`, against a stub `document.selectForm` whose radio groups `SELECT1`…`SELECT10` it sets.
   - For every combination the app supports it calls WoO's `CalculateResult()` and reads `RESULTS7` (basic strategy with cut card). That covers decks 1/2/4/6/8 (WoO index 0/1/2/4/5; 5 decks is skipped), S17/H17, DAS, double any two / 9-11 / 10-11, 2 / 3 / 4 hands, RSA, hit split aces, peek / no hole card (`SELECT8` "loses only original bet" Yes / No), no / late surrender, and 3:2 / 6:5. That is 5 × 2 × 2 × 3 × 3 × 2 × 2 × 2 × 2 × 2 = 5,760 values.
   - It writes `BJSCore/Sources/BJSCore/Edge/WoOEdgeData.swift`: a flat `[Double]` in a documented index order, plus header comments with the source URL, the retrieval date and "House edge by WizardOfOdds.com". It is generated and never edited by hand.
   - `README.md` explains the source and how to regenerate, following `tools/woo-strategy/README.md`. The script is run by hand only. We take data, not WoO's code.
2. **`EdgeCalculator.analyze(rules:)`**, rewritten:
   - **Table lookup:** `table(rules)` indexes `WoOEdgeData` with the rules, mapping payout to 3:2 or 6:5 and surrender to none or late.
   - **2:1 payout:** `edge(3:2) − (5/3) × (edge(6:5) − edge(3:2))`, with every other rule held equal. The payout is linear in the frequency of an unpushed player blackjack, and strategy doesn't depend on it, so this is exact. At 8 decks it gives −2.263, against WoO's −2.27.
   - **Effective surrender:** `early` if the rule is `.early`, or if the rule is `.late` under `.europeanNoPeek`. Otherwise it's the rule as set.
   - **Early surrender:** the no-surrender table value − 0.63.
   - `restrictiveScale`, `deckCountDelta` and the old baseline constant are deleted.
3. **Attribution.**
   - Start from `EdgeCalculator.baselineRules`: 8D S17 DAS, any two, 4 hands, no RSA, no hit split aces, peek, no surrender, 3:2. `baselineHouseEdge` is its table value, 0.44686.
   - Apply the user's rules one field at a time, in this fixed order: decks → soft 17 → payout → DAS → double on → split hands → RSA → hit split aces → hole card → surrender.
   - Each changed field yields `RuleContribution(factor:edgeChange:)`, where `edgeChange = edge(after) − edge(before)`. Unchanged fields yield no row.
   - `houseEdge == baselineHouseEdge + Σ edgeChange`, exactly up to floating point.
4. **API changes:**
   - `RuleContribution` becomes `factor: EdgeFactor` + `edgeChange: Double`, signed in house-edge terms (positive is worse for the player). The old `rule: String` and `delta` (the opposite sign) are removed.
   - `EdgeFactor` is a `Sendable, Hashable` enum:
     - `decks(DeckCount)` and `dealerHitsSoft17`;
     - `payout(BlackjackPayout)`;
     - `noDoubleAfterSplit` and `doubleRestriction(DoubleRestriction)`;
     - `maxSplitHands(Int)`;
     - `resplitAces` and `hitSplitAces`;
     - `noHoleCard`;
     - `surrender(SurrenderRule, pricedAsEarly: Bool)`. `pricedAsEarly` is true for late surrender under no hole card.
   - `EdgeResult`, `houseEdge(for:)` and `EdgeRating` keep their shapes. The only consumers today are BJSCore's own tests.

## 4. App: `Features/Edge`

- **Entry:** `ModuleHost` maps `.edge` to `EdgeView(onClose:)`. The hub tile already launches `.edge`. `AppModule` is unchanged.
- **`EdgeViewModel`** (`@Observable @MainActor`, thin):
  - `init(activeRules:)` holds `rules`, a copy of the active rules.
  - Derived values:
    - `result` via `EdgeCalculator`, and `rating`;
    - `isPlayerEdge` (houseEdge < 0);
    - `comparison: Double?` = edge(form) − edge(active), nil when the rules are equal;
    - `canApply` = `rules != activeRules`.
  - `apply(to: ActiveRulesStore)` writes the rules and updates the model's copy of the active rules.
- **`EdgeView`:**
  - **Pinned result bar**, a top safe-area inset over `FeltBackground`:
    - Row 1: `CloseButton(identifier: "edge.close")` and the label "HOUSE EDGE", or "PLAYER EDGE" when the edge is negative.
    - Row 2: the number, `FeltType.display` with monospaced digits, in absolute value with two decimals (e.g. `0.64%`). Beside it, a rating badge: **Good** in `correct`, **OK** in `textSecondary`, **Poor** in `incorrect`, as text on `surfaceInset`. Brass isn't used, because the parent spec reserves it for hints and highlights.
    - Row 3, only when `comparison != nil`: e.g. `+0.22% vs your training rules` in `textSecondary`.
  - **Breakdown** (`SettingsSection` "Breakdown"):
    - First row: "Baseline · 8D S17 DAS 3:2" with `0.45%`.
    - Then one `EdgeContributionRow` per contribution, in attribution order.
    - Last row: "House edge" with the total.
    - Rows round independently to two decimals, so they may differ visibly from the total by 0.01.
  - **Rules:** the shared `RulesForm(rules: $model.rules)`, unchanged, including the preset menu.
  - **Apply:**
    - A `PrimaryButton` "Use these rules for training", enabled only when `canApply`. When the rules already match, the caption "These are your training rules." sits in its place.
    - Tapping it opens a system `confirmationDialog`. Title: "Use these rules for training?". Message: "New drills will use <RulesSummary>. Saved sessions keep their own rules." Button: "Use these rules".
    - On confirm: `apply`, then a `FeltToast` "Training rules updated". The screen stays open.
  - **Footnote** (`textTertiary`, at the bottom): "House edge for basic strategy dealt with a cut card, from WizardOfOdds.com. Early surrender uses an 8-deck estimate."
- **`EdgeText`** holds all the copy, including the `EdgeFactor` labels. Examples:
  - "1 deck"; "Dealer hits soft 17"; "Blackjack pays 6:5"; "No double after split"; "Double on 10–11 only"; "Split to 2 hands";
  - "Resplit aces"; "Hit split aces"; "No hole card"; "Late surrender"; "Early surrender";
  - "Late surrender (settles as early)" for `pricedAsEarly`.
- **New component** (`Design/Components/EdgeContributionRow.swift`, existing tokens only, added to `FeltCatalogue`):
  - `EdgeContributionRow(label:change:scale:)`: the label on the left, the signed value (`+0.22%`) on the right, and a diverging bar centred on zero below them.
  - The bar is `incorrect` when the change raises the house edge and `correct` when it lowers it. Its length is `|change| / scale` of the half-width, where the caller passes `scale` = the largest |change| on screen.
  - VoiceOver: "Dealer hits soft 17, raises the house edge by 0.22 percent".
- **Accessibility identifiers:** `edge.number`, `edge.rating`, `edge.apply`, `edge.close`. The form keeps its existing identifiers.

## 5. Testing

- **BJSCore** (Swift Testing, TDD):
  - **WoO reference suite:** all 38 rows of §2, typed by hand into `EdgeCalculatorTests`, with a tolerance of 0.00001 + 1e-9 (WoO rounds to 5 decimals).
  - **2:1:** at 8D the change from 3:2 is within 0.01 of −2.27. At 1D it equals −(5/3) × (row 30 − row 13).
  - **Early surrender:** equals no surrender − 0.63 at every deck count. Under no hole card, late surrender equals early surrender, and its factor has `pricedAsEarly == true`.
  - **Attribution:**
    - contributions sum to `houseEdge − baselineHouseEdge` within 1e-9;
    - the baseline rules give no contributions;
    - the order is fixed;
    - each `edgeChange` equals the table difference at its step (checked on a multi-rule case).
  - **Table integrity:** 5,760 entries, all finite and within −1…+3. Every index field round-trips.
  - **`EdgeRating`:** the existing tests stay. The presets rate Good (Vegas Strip, Downtown, Atlantic City), OK (European) and Poor (Single Deck 6:5).
- **App** (Swift Testing):
  - **`EdgeViewModel`:**
    - it inits from the active rules, and the result follows rule changes;
    - `comparison` is nil when the rules are equal, and correctly signed when they differ;
    - `canApply` toggles, and `apply` writes the store;
    - a negative edge gives `isPlayerEdge`.
  - **`EdgeText`:** every factor has a non-empty label.
- **UI** (XCTest, `EdgeUITests`):
  - Hub → Edge tile.
  - Choose the Single Deck 6:5 preset → `edge.number` changes (0.43% → 1.70%) and the rating reads Poor.
  - `edge.apply` → confirm → `edge.close` → the hub header starts with `1D`.
- **Design check:**
  - iPhone 16 and SE screenshots of the default rules, 6:5 (Poor, long bar) and 1D S17 DAS (player edge).
  - The contrast test stays green.

## 6. Done when

- The new WoO suite and every existing BJSCore and app test are green.
- The Edge UI test is green.
- The design check passes.
- `progress.md` has the Step 5 handoff. It records the parent-spec amendments (§5 accuracy bar, rating on the cut-card figure) and the closed ENHC-surrender carry-over.
- The parent spec's §5 Edge accuracy bar line is updated to point here.

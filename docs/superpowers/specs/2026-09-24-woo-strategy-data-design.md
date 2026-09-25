# Strategy from Wizard of Odds data — design

Date: 2026-09-24. Status: approved by Luke (chat, 2026-09-24).
Amends the rebuild spec (`2026-09-23-bjs-rebuild-design.md`): §7 Testing gains the full-chart strategy bar in §6 below. The Edge module's house-edge bar (§5 Edge) is unchanged.

## 1. Problem

`StrategyEngine` computes charts with an infinite-deck EV model plus hand-tuned corrections (`standingBias`, `doublingBonus`, `soft18Correction`). The corrections make every preset's chart wrong somewhere. Examples: 16 vs 10 is "stand" in 6D S17 (WoO: hit); European no-hole-card doubles 11 vs 10 (WoO: hit); soft 13 vs 5 and soft 15 vs 4 hit in 6D S17 (WoO: double); single-deck no-DAS pairs are off. The 38-case validation suite locks one wrong value in. The trainer grades users against these charts, so they must be right.

Separately, `StrategyTable` ignores a pair row unless it says "split", so a two-card pair whose correct non-split play differs from its total's row (e.g. 7,7 vs 10 in single deck: stand; hard 14 vs 10: hit) is graded by the wrong row.

## 2. Decision

Replace the EV generator with Wizard of Odds' published basic-strategy data, decoded per rule set. WoO's calculator (https://wizardofodds.com/games/blackjack/strategy/calculator/) embeds six tables (decks 1 / 2 / 4+ × S17 / H17). Each has 36 rows (hard 5–21, soft 13–21, pairs 2,2–A,A) and 12 columns (dealer 2–9, 10, A, and European no-hole-card 10 and A). Cell codes: `H`, `S`, `DH`, `DS`, `P`, `QH`/`QD`/`QS` (split if DAS, else hit / double-else-hit / stand), `RH`/`RS`/`RP` (surrender if allowed, else hit / stand / split).

The data is extracted by script from the page, not typed. It is checked in as generated Swift with the source URL, retrieval date and "Strategy by WizardOfOdds.com" attribution. Basic strategy is mathematical fact; we take the data only, not WoO's code.

Rejected: an exact finite-deck EV engine (large; WoO's total-dependent method for 1–2 decks isn't published, so marginal cells may never match); patching the current engine (fragile, custom rules stay unverified).

## 3. Decoding rules → chart

`StrategyEngine().strategy(for: BlackjackRules) -> StrategyTable` keeps its signature and per-rules cache.

- **Table:** `deckCount` 1 → 1-deck, 2 → 2-deck, 4/6/8 → "4 or more"; `dealerSoft17` picks S17/H17.
- **Columns:** American peek uses dealer 2–9, 10, A. European no-peek uses 2–9, E10, EA.
- **Cell → preference list** (ordered; grading picks the first legal action):
  - `H` → [hit]; `S` → [stand]; `DH` → [double, hit]; `DS` → [double, stand]; `P` → [split].
  - `QH`/`QD`/`QS`: with DAS → [split]; without → [hit] / [double, hit] / [stand].
  - `RH`/`RS`/`RP`: when surrender applies → [surrender, hit] / [surrender, stand] / [surrender, split]; otherwise → [hit] / [stand] / [split].
- **Surrender applies:**
  - `none` → never.
  - `late` + peek → every column (WoO "allowed with any dealer upcard").
  - `late` or `early` + European → every column, using the E columns. Under no hole card a surrender happens before the dealer's second card exists, so it is never beaten by a later dealer blackjack (see §5).
  - `early` + peek → the `late` + peek chart for dealer 2–9. For dealer 10 and A, surrender iff the hand is on WoO's early-surrender list; otherwise the late chart's cell with surrender removed. The list, from https://wizardofodds.com/games/blackjack/surrender/:
    - vs A: hard 5–7, hard 12–17, pairs 3,3 / 6,6 / 7,7 / 8,8, plus 2,2 when the dealer hits soft 17;
    - vs 10: hard 14–16, pairs 7,7 / 8,8;
    - total-dependent exceptions (the list's composition notes reduced to totals, since 10+4 is the dominant 14): no surrender of hard 14 vs 10 with 1 or 2 decks; no surrender of 8,8 vs 10 with 1 deck and DAS.
    - The non-surrender alternative is the peek chart's action (e.g. hard 16 vs A → [surrender, hit]; 8,8 vs A → [surrender, split]).
- **Double restriction:** `nineToEleven` / `tenToEleven` remove `double` from any cell whose two-card total can't double (pairs use their total: 4,4 = 8, 5,5 = 10; soft totals never qualify). The list's remaining action is the correct play.
- **Not modelled by WoO, no effect on the chart:** `resplitAces`, `hitSplitAces`, `maxSplitHands`, `blackjackPayout`. 4, 6 and 8 decks share one chart, as in WoO. These are documented in code.

## 4. `StrategyTable`

- Stores a preference list per cell for the hard (17×10), soft (9×10) and pair (10×10) grids.
- `action(for hand:, dealerUpcard:, legal:)`:
  1. If the hand is a two-card pair and split is legal, return the first legal action in its pair list. This matches `TrainingCell(spot:)`, which files a pair as a pair cell only while split is legal, so a decision is graded on the row it is recorded under. (Cost: 1-deck 7,7 vs 10 at max split hands grades as hard 14, i.e. hit.)
  2. Otherwise, or if nothing in the pair list is legal, return the first legal action in the hand's hard/soft list. A two-card soft 12 (A,A that can't be split) is graded [hit]: it has no WoO row, and hit beats double against every upcard.
  3. Then the row's hit/stand fallback, then stand.
  - Row indexing for hard 4 (2,2 that can't be split) keeps today's clamping to the hard 5 row.
- `action(for: DecisionSpot)` is unchanged.
- The existing read-only views stay: `hardTotals`/`softTotals`/`pairs` (first action of each list), `hardHitStand`/`softHitStand` (last hit/stand in each list). Consumers and tests keep compiling.
- `action(for:dealerUpcard:rules:)` (two-card, all-legal view) is kept, defined as the legal-aware lookup with every action legal except those the rules forbid (split only if `canSplit`, surrender only if the rule allows it).

## 5. RoundEngine change

Under `europeanNoPeek`, a surrendered hand settles at −0.5 whether the rule is `late` or `early`. Today `late` + ENHC settles at −1 against a dealer natural; the test `enhcLateSurrenderVsNatural` changes to expect `.surrendered`, −0.5. American-peek settlement is unchanged.

## 6. Accuracy bar and tests

- **Full-chart match (the new bar):** a fixture holds WoO's own rendered charts. It is produced by running WoO's `ComputeStrategy` over its selects: 3 deck groups × S17/H17 × DAS yes/no × surrender none/any × peek/no-peek = 48 charts × 340 cells, as display codes (`H S Dh Ds P Rh Rs Rp`). For each combination, a `BlackjackRules` is built (4+ decks → 6; surrender any → `late`). Every cell of our decoded chart, rendered back to the same display code, must equal the fixture.
- **Early surrender:** tests cover the ES list, its H17 and 1–2 deck exceptions, and that dealer 2–9 match the late chart.
- **Double restriction:** tests cover restricted doubles decoding to their fallback.
- **Named spot checks:** 16 vs 10 hit (6D S17, no surrender); 11 vs 10 hit (European); soft 13 vs 5 and soft 15 vs 4 double (6D S17); 7,7 vs 10 stand (1D S17 DAS).
- **Pair-row grading:** a regression test covers pair rows whose non-split play differs from the total row.
- **Removed:** the EV generator, its corrections and the 38-case `StrategyValidationTests` (one wrong value). `DealerProbability` and its tests stay: the spec lists it, and the WHY sheet may use dealer bust odds.
- `StrategyFallbackTests`, `RoundEnginePropertyTests` and the round tests stay green (expected values updated only where they asserted a wrong chart value, each noted in the commit).

## 7. Provenance tooling

`tools/woo-strategy/extract.js` (node, dev-only) downloads the calculator page, evaluates its data script with a stub DOM, and writes:
- `BJSCore/Sources/BJSCore/Strategy/WoOStrategyData.swift`: the six tables as string codes;
- `BJSCore/Tests/BJSCoreTests/Fixtures/woo-rendered-charts.txt`: the 48 rendered charts.

A README states the source, date and how to regenerate. The script executes WoO's page script and is run by hand only.

## 8. Out of scope

Composition-dependent strategy (still v2), WoO's "surrender on dealer 2–10 only" option (not in our rules model), and any Settings UI (Step 2 must offer surrender none/late/early and may explain that surrender under no-peek always keeps half the bet).

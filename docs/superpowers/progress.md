# BJS Rebuild — Progress Log

Newest entry last. Each entry: step, date, commit range, what shipped, test status, notes for the next step.

## Step 0 — Cleanup (2026-09-23)

- Old app layer, `.planning/` (GSD) and `design-system/` removed; `WhyExplanation` moved into BJSCore; `RulePreset` added.
- App is a placeholder three-tab shell (`RootTabView`, `AppTab`).
- Next: Step 1 (engine completion), same plan file, Tasks 4–14.

## Step 1 — Engine completion (2026-09-24)

- Commits: 78de121..badf7d5
- BJSCore tests: 185 passing (`cd BJSCore && swift test`); app shell tests passing (2).
- Added: SeededRandomNumberGenerator; Shoe(orderedCards:), shuffle(using:), standardCards, dealtCount;
  StrategyTable hit/stand fallback + action(for:dealerUpcard:legal:) / action(for: DecisionSpot);
  RoundEngine (naturals, peek/ENHC, early/late surrender, double, splits incl. aces/RSA/max hands);
  TrainingCell (340 cells), HandFilter, HandGenerator (weighted, stacked shoes);
  DecisionSample + WeakSpotWeights; CountDrillGenerator + TrueCountQuestion/Convention; EdgeRating;
  TrainingModule, CountKind, CountSample, SessionSample, ProgressStats.
- Behaviour notes for Step 2+: RoundEngine auto-finishes hands at 21+; no insurance; 21 after split pays 1:1;
  ENHC loses all bets (incl. splits/doubles) to a dealer natural; both split cards are dealt at once
  (UI should reveal the right hand's card when that hand becomes active); K-Q is not splittable (pairs by rank).
  Training hands never start with a dealer natural under American peek; under ENHC they can
  (pass `peekRule:` to `HandGenerator.stackedShoe`). TrainingCell uses 11 for aces.
  Grade decisions only with `StrategyTable.action(for: DecisionSpot)`, never the rules-based overload.
  Streak and weak-spot window order by (date, input position): pass decisions in chronological order.
- Requirements the Step 2 plan must carry (from the final review):
  - `CountKeypad` needs a ".5" / decimal key: the Exact true-count convention has half-integer answers.
  - The persisted decision record needs a per-decision order (timestamp or sequence), not just the session date.
  - Settings must limit `maxSplitHands` to 2…4 (at 1, pair cells stop round-tripping).
  - Unsplittable 2-2 / A-A map to hard 4 / soft 12, which are outside the 340-cell grid; the Progress grid ignores them.
- Open before Step 3 (needs Luke's decision, own change): `StrategyEngine` deviates from Wizard of Odds on a few
  cells — hard 16 vs 10 is "stand" in 6D S17 without surrender (WoO: hit; `StrategyValidationTests` locks the wrong
  value), soft 13 vs 5 and soft 15 vs 4 are "hit" (WoO: double). The hit/stand fallback tables inherit H16 vs T.
  Fix with full-chart WoO tests per preset before Step 3 grades anyone.
- Next: Step 2 (Foundation) — brainstorm/plan in a fresh session from spec §4 and §8.

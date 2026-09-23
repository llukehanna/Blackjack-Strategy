# BJS Rebuild — Progress Log

Newest entry last. Each entry: step, date, commit range, what shipped, test status, notes for the next step.

## Step 0 — Cleanup (2026-09-23)

- Old app layer, `.planning/` (GSD) and `design-system/` removed; `WhyExplanation` moved into BJSCore; `RulePreset` added.
- App is a placeholder three-tab shell (`RootTabView`, `AppTab`).
- Next: Step 1 (engine completion), same plan file, Tasks 4–14.

## Step 1 — Engine completion (2026-09-23)

- Commits: 78de121..6a484a2 (branch `main-8v0ds1`; run in a cloud session).
- BJSCore tests: 173 passing (`cd BJSCore && swift test`, Swift 6.2.4 on Linux). `BJSCore/Sources` has no SwiftUI/SwiftData/UIKit imports.
- **Not run:** Task 14 Step 3 (`xcodegen generate && xcodebuild test ...`). The cloud container has no Xcode or simulator. Luke: run it locally before starting Step 2.
- Added: SeededRandomNumberGenerator; Shoe(orderedCards:), shuffle(using:), standardCards, dealtCount;
  StrategyTable hit/stand fallback + action(for:dealerUpcard:legal:) / action(for: DecisionSpot);
  RoundEngine (naturals, peek/ENHC, early/late surrender, double, splits incl. aces/RSA/max hands);
  TrainingCell (340 cells), HandFilter, HandGenerator (weighted, stacked shoes, no dealer naturals);
  DecisionSample + WeakSpotWeights; CountDrillGenerator + TrueCountQuestion/Convention; EdgeRating;
  TrainingModule, CountKind, CountSample, SessionSample, ProgressStats.
- The property tests (100k seeded rounds, five rule sets) found no engine bugs. The final branch review found two small ones, fixed in 6a484a2: a `.cards(0)` drill crashed, and `TrendPoint` had no public init.
- Behaviour notes for Step 2+: RoundEngine auto-finishes hands at 21+; no insurance; 21 after split pays 1:1;
  training hands never start with a dealer natural (even under ENHC); TrainingCell uses 11 for aces.
- Open items from the final review (decide before the step named):
  - **Early surrender strategy (before Step 3, Important).** StrategyEngine values surrender at a flat −0.5 against peeked hand values, so under early surrender it answers "hit" where ES basic strategy surrenders (e.g. 14v10, 15vA, 12vA, 7vA). This predates the rebuild, but RoundEngine now makes ES playable. Model ES properly with Wizard of Odds reference tests, or hide early surrender until then.
  - **Decision ordering: DECIDED.** Spec §6 now adds `DecisionRecord.decidedAt` and `CountCheckRecord.answeredAt`. Step 2's SchemaV1 must include them, and the mappers must copy them into `DecisionSample.date` / `CountSample.date`, never the session's `startedAt`.
  - Minor: soft 12 (unsplittable A,A) is looked up in the soft 13 row. Hard 4 and soft 12 spots from real play have no TrainingCell/heat-map square. 3+ card hands share a cell with 2-card hands.
  - Minor: split deals both second cards at once (the right-hand card is visible early; relevant to Shoe Sim animations). A deal that runs out mid-action leaves the round half-changed, so Shoe Sim must ensure enough cards before each round.
  - Step 4: exact true-count grading (±0.25) needs a decimal or half-step keypad.
  - Step 3: no helper yet to build WhyContext from TrainingCell + chosen/correct action.
  - `RulePreset.matching(BlackjackRules())` is `.vegasStrip`. Default rules display as Vegas Strip.
  - `project.yml` `-enable-upcoming-feature DefaultIsolationMainActor` may be a no-op (Swift 6.2 uses `SWIFT_DEFAULT_ACTOR_ISOLATION`). Check on the first Xcode build.
  - README.md is stale (says "Not a casino app", lists deleted folders). Fix in Step 8.
  - The HandGenerator weighted-convergence test takes ~7s in debug. Optional speed-up later.
  - EdgeCalculator gives single-deck 6:5 (H17, no DAS) ≈1.43%. Verify against the WoO calculator in Step 5.
- Next: Step 2 (Foundation). Brainstorm and plan it in a fresh session from spec §4 and §8.

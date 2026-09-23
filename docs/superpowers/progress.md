# BJS Rebuild — Progress Log

Newest entry last. Each entry: step, date, commit range, what shipped, test status, notes for the next step.

## Step 0 — Cleanup (2026-09-23)

- Old app layer, `.planning/` (GSD) and `design-system/` removed; `WhyExplanation` moved into BJSCore; `RulePreset` added.
- App is a placeholder three-tab shell (`RootTabView`, `AppTab`).
- Next: Step 1 (engine completion), same plan file, Tasks 4–14.

## Step 1 — Engine completion (2026-09-23)

- Commits: 78de121..6a484a2 (branch `main-8v0ds1`; run in a cloud session).
- BJSCore tests: 173 passing (`cd BJSCore && swift test`, Swift 6.2.4 on Linux). `BJSCore/Sources` has no SwiftUI/SwiftData/UIKit imports.
- Task 14 Step 3 (app build + tests) runs in GitHub Actions: `.github/workflows/ios.yml` (macos-26, latest Xcode 26, newest available iPhone simulator; BJSCore `swift test`, `xcodegen generate`, `xcodebuild test`). Run 1 on df3d559 passed: `** TEST SUCCEEDED **`, 2 app-shell tests. The cloud dev container is Linux, so check app-level work through this workflow. Locally, CLAUDE.md's `OS=18.4` destination still applies.
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
  - **Early surrender strategy: FIXED (65fb927, reviewed).** In peek games, surrender now wins under early surrender when the no-blackjack EV is below (P(BJ) − 0.5)/(1 − P(BJ)). Under late surrender with no hole card (ENHC), surrender is worth −0.5 − 0.5·P(BJ), matching RoundEngine settlement. The 6-deck S17 and H17 early-surrender tables match Wizard of Odds (vs A: hard 5–7 and 12–17, pairs 3s/6s/7s/8s; vs 10: hard 14–16, pairs 7s/8s; vs 9: hard 16). The WHY text now explains the dealer-blackjack risk. Optional follow-ups: early-surrender tests for ENHC and 1–2 decks; check H17 2,2 vs A (the engine surrenders it) against WoO; P(BJ) uses infinite-deck values (negligible).
  - **Decision ordering: DECIDED.** Spec §6 now adds `DecisionRecord.decidedAt` and `CountCheckRecord.answeredAt`. Step 2's SchemaV1 must include them, and the mappers must copy them into `DecisionSample.date` / `CountSample.date`, never the session's `startedAt`.
  - **Soft 12 / hard 4: FIXED (b36ca9f, reviewed).** The engine now computes its own soft-12 and hard-4 rows for unsplittable A,A and 2,2, and no longer borrows the soft-13 and hard-5 rows. An independent EV check confirmed that soft 12 vs 6 is a double under H17 and at 1 deck; the engine now plays it that way. Still open (minor): hard 4 and soft 12 spots from real play have no TrainingCell or heat-map square, and hands of 3+ cards share a cell with 2-card hands.
  - Early-surrender coverage extended (b501781): ENHC and 1–2 deck tests, and every LS cell is also an ES cell. Not asserted: at 1 deck the engine hits 14 v 10, 7,7 v 10 and 16 v 9 under ES, because it ignores the player's own cards (infinite-deck P(BJ)). 7,7 v 10 looks wrong against published 1-deck charts; fixing it means a composition-dependent model (Step 5 or later). H17 2,2 v A surrenders under ES (−.5100 by hitting, vs −.5 surrender), unasserted.
  - Minor: split deals both second cards at once (the right-hand card is visible early; relevant to Shoe Sim animations). A deal that runs out mid-action leaves the round half-changed, so Shoe Sim must ensure enough cards before each round.
  - Step 4: exact true-count grading (±0.25) needs a decimal or half-step keypad.
  - Step 3: no helper yet to build WhyContext from TrainingCell + chosen/correct action.
  - `RulePreset.matching(BlackjackRules())` is `.vegasStrip`. Default rules display as Vegas Strip.
  - `project.yml` `-enable-upcoming-feature DefaultIsolationMainActor` may be a no-op (Swift 6.2 uses `SWIFT_DEFAULT_ACTOR_ISOLATION`). Check on the first Xcode build.
  - README.md is stale (says "Not a casino app", lists deleted folders). Fix in Step 8.
  - The HandGenerator weighted-convergence test takes ~7s in debug. Optional speed-up later.
  - EdgeCalculator gives single-deck 6:5 (H17, no DAS) ≈1.43%. Verify against the WoO calculator in Step 5.
- Next: Step 2 (Foundation). Brainstorm and plan it in a fresh session from spec §4 and §8.

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

## Step 2 — Foundation (2026-09-24)

- Commits: a5edfac..HEAD on `main-8v0ds1` (plan a5edfac + review fixes fa39b7c; code 452e3c7..f0e6771).
- CI: [run 8](https://github.com/llukehanna/Blackjack-Strategy/actions/runs/35955268409) green on 1a14c8c. It ran BJSCore (195 tests), app unit tests (Swift Testing; the plan expects 60), and UI tests (XCTest; 2) on iPhone 16 and iPhone SE, with the screenshots exported and uploaded. Earlier green runs: 5 (Task 1), 6 (Tasks 2–6), 7 (Tasks 7–9). Test counts are from the plan; I didn't read them from the CI log.
- Design check (spec §7): the screenshots are in run 8's `design-screenshots` artifact (16 per device). **Not yet inspected:** the artifact host (blob.core.windows.net) is blocked from the cloud container. A step that would have pushed the screenshots to a git branch needed CI write permission, and that was denied. Luke: download the artifact from the run's Summary page and go through checklist rows 1–19 in Task 13 of `docs/superpowers/plans/2026-09-24-step-2-foundation.md`. Row 7 is out of date: the Reset label is now `textPrimary` (Decision 16), so `incorrect` appears only on feedback. The contrast test is green in the same run.
- **Design freeze: PENDING Luke's approval.** When Luke approves, change this line to "Design freeze: FROZEN on <date> (approved by Luke)". From then on, §4 tokens and components change only by Luke's explicit decision, in their own commit.
- For Luke to confirm at the freeze: the "Decisions this plan makes" list in the Step 2 plan, especially:
  - #11: visual details the spec left open.
  - #13: contrast at the `feltLight` centre. textSecondary is 4.33:1, textTertiary 3.51:1, brass 4.08:1 and incorrect 2.89:1 there. All pass on `feltBase`, which is what the spec requires.
  - #15: opting out of iOS 26 Liquid Glass via `UIDesignRequiresCompatibility`. This was the controller's call, and it's reversible.
  - #16: Reset label in `textPrimary`.
- Added:
  - Felt tokens (`FeltPalette`, `FeltColor`, `FeltType`, `FeltSpacing`, `FeltRadius`, `FeltMetrics`, `FeltMotion`) and `WCAGContrast`.
  - Components: FeltBackground, PlayingCard, HandView, ActionDock, FeedbackCard, StatChip, ModuleTile, PrimaryButton/SecondaryButton (`FeltButtonStyle`), ModePicker, SettingsRow/SettingsSection, CountKeypad (+ `CountEntry`, optional decimal key).
  - DEBUG ComponentGallery.
  - `ActiveRulesStore` and `Preferences`, which write UserDefaults directly with the spec's keys.
  - SwiftData `SchemaV1` + `BJSMigrationPlan`, `ProgressMapper`, `ProgressReset`.
  - Hub shell and Settings tab (+ `SettingsPresetOptions`).
  - `BJSUITests`.
  - CI screenshot pipeline (`scripts/ci/*`, `.github/workflows/ios.yml`).
- `project.yml`: the no-op `DefaultIsolationMainActor` flag is gone. The app is nonisolated by default, with explicit `@MainActor` stores. `UIDesignRequiresCompatibility: true` is set.
- CI now takes ~20 minutes per push (UI tests on two devices, ~10 min of that on the SE). It's free, because the repo is public.
- Notes for Step 3:
  - Hub tiles route through `RootTabView`'s `destination` closure; replace `PlaceholderScreen` for `.strategy`.
  - Records use the typealiases `Session`, `DecisionRecord` and `CountCheckRecord`, and the Session relationship is `countCheckRecords`.
  - Write `decidedAt` per decision. "timeout" is a plain `chosenAction` string.
  - Continue and `lastLaunch` are still to build.
  - `LaunchConfiguration` gives UI tests a clean store (`BJS_UI_TESTING=1`).
- Next: once Luke approves the freeze, Step 3 (Strategy).

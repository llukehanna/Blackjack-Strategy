# BJS Rebuild — Design Spec

**Date:** 2026-09-23
**Status:** Approved in brainstorming; pending written-spec review
**Supersedes:** `.planning/` (GSD roadmap, phases 1–7), `design-system/bjs/MASTER.md`

## 1. Why a rebuild

The GSD roadmap stalled after Phase 2. Four inserted UI phases (2.1, 2.2, 2.3, 7) restyled the same three screens and were each left partly done, while Hi-Lo, Edge, Analytics and the Shoe Simulator never started. The planning docs also drifted from reality.

This spec resets the project:

- **Keep** `BJSCore` (rules, strategy, Hi-Lo, edge calculator; 95 passing tests).
- **Discard** the SwiftUI app layer, the old design system, and the GSD workflow.
- **Rebuild** the app layer on a new, frozen design system, one feature module at a time.
- **Workflow** from now on: superpowers (brainstorming → writing-plans → subagent-driven development / executing-plans, TDD, verification-before-completion). No GSD.

## 2. Product

**What it is:** a native iPhone blackjack *trainer*. Users get measurably better at basic strategy and Hi-Lo counting through accurate, rule-specific feedback. It is educational: no wagering, no real money, no casino integration.

**Visual positioning (change from prior brief):** the app deliberately *looks* like a casino table (felt green, cream cards), while behaving like a serious training tool. The old "NOT casino-themed" rule in `MASTER.md` is retired.

**v1 ships all five areas:** Strategy, Counting, Shoe Sim, Edge, Progress.

**Constraints (unchanged):** Swift 6.2 + SwiftUI, iOS 18+, iPhone only, fully offline, no backend, App Store compliant, maths must be correct.

**Out of scope for v1:** other counting systems, composition-dependent strategy, deviation indices (I18/Fab 4), bet-spread training, iPad layout, iCloud sync, multiplayer/social/leaderboards, side bets, CSM modelling. (Same v2 list as before.)

## 3. Architecture

```
BJSCore (Swift package, no SwiftUI)          BJS (iOS app)
├─ Models    Card, Rank, Suit, BlackjackHand, ├─ App         BJSApp, RootTabView (Train · Progress · Settings)
│            BlackjackRules, Shoe, Action     ├─ Design      Felt tokens + component kit (FROZEN after Step 2)
├─ Rules     RulePresets (moved from app)     ├─ Features/
├─ Strategy  StrategyEngine, StrategyTable,   │   ├─ Hub
│            DealerProbability                │   ├─ Strategy   setup, trainer, summary
├─ Counting  HiLoCounter, CountDrillGenerator │   ├─ Counting   RC drill, TC drill, values reference
├─ Edge      EdgeCalculator, EdgeRating       │   ├─ Edge       rules form, result, breakdown
├─ Round     RoundEngine (NEW)                │   ├─ Shoe       simulator, report
├─ Explain   WhyExplanation (moved from app)  │   ├─ Progress   trends, heat map, history
├─ Training  HandGenerator, WeakSpotWeights   │   └─ Settings   rules + presets, preferences
│            (NEW)                            ├─ Persistence  SwiftData SchemaV1 + mappers
└─ Progress  ProgressStats (NEW)              └─ Shared       ActiveRulesStore, Preferences
```

### Rules

1. **All game logic lives in `BJSCore`.** That covers dealing, split/double/surrender handling, dealer play, settlement, drill generation, explanations, weighting and statistics. `BJSCore` never imports SwiftUI or SwiftData.
2. **ViewModels are thin.** They are `@Observable` and `@MainActor`, and they only call the engine, map results for display, own timing and animation sequencing, and persist results.
3. **`RoundEngine` is a pure value-type state machine.** Input is shoe + rules + player actions. Output is the round's state and settled outcome. The Strategy trainer runs it on a freshly shuffled shoe for every hand. Shoe Sim runs it on one continuous shoe with `HiLoCounter` alongside.
4. **One active rule set app-wide.** `ActiveRulesStore` is `@Observable` and backed by `@AppStorage` JSON. It is set in Settings and injected through the environment. Each session snapshots the rules it ran under. Edge can evaluate other rules without changing the active set.
5. **Feature folders never import each other.** Anything shared comes from `Design/`, `Shared/`, `Persistence/`, or `BJSCore`.
6. **Randomness is injectable.** Anything that shuffles or samples takes a `RandomNumberGenerator`, so tests are seeded and deterministic.
7. **XcodeGen stays.** `project.yml` is the source of truth; `.xcodeproj` is gitignored.

### Code to delete (Step 0)

- `BJS/Views/**`, `BJS/Design/**`, `BJS/ViewModels/**`, `BJS/Models/**` (the old SwiftData models)
- `BJS/Resources/Cards/**` (SVG deck and `ATTRIBUTION.md`, replaced by drawn cards)
- The old app tests in `BJSTests/**` that cover deleted code
- `BJS/Domain/WhyExplanation.swift` moves to `BJSCore/Explain`; `BJS/Utilities/CasinoPreset.swift` is replaced by `BJSCore/Rules/RulePreset`. Both happen at the start of Step 0, before the app layer is deleted.
- `.planning/` (the GSD artifacts; they stay in git history)
- `design-system/` (untracked; superseded by this spec; the reference screenshots belong to a third-party app and must not be committed)
- The "GSD Workflow Enforcement" and GSD-managed sections of the project `CLAUDE.md`

## 4. Design system: Felt

**This is the only design system. It is frozen at the end of Step 2.** Later steps may add new components built from existing tokens. They may not restyle or re-tune existing tokens or components. Any proposed change to a frozen token needs its own explicit decision from Luke. It never rides along inside a feature step.

The app is dark only (`.preferredColorScheme(.dark)`); the felt is the brand.

### Colour tokens (`FeltColor`)

| Token | Value | Use |
|---|---|---|
| `feltDeep` | `#0C2A1F` | Background edge, tab bar base |
| `feltBase` | `#123A2B` | Primary background |
| `feltLight` | `#1F5A43` | Radial highlight centre |
| `surfaceInset` | black @ 22% | Chips, tiles, rows, secondary buttons |
| `cream` | `#FBFAF6` | Cards, primary buttons, feedback card |
| `onCream` | `#123A2B` | Text on cream |
| `onCreamSecondary` | `#3D6B57` | Secondary text on cream |
| `brass` | `#D9B45A` | Accent: hints, highlights, streaks only, never decoration |
| `correct` | `#6EE7A0` | Correct feedback |
| `incorrect` | `#FF6B5B` | Incorrect feedback |
| `suitRed` | `#D23B3B` | Hearts and diamonds |
| `suitBlack` | `#111111` | Spades and clubs |
| `textPrimary` | `#EEF3EE` | Primary text on felt |
| `textSecondary` | `#A9C4B6` | Secondary text on felt |
| `textTertiary` | `#8FB3A2` | Labels and captions on felt |

Contrast requirement: text tokens used on `feltBase` or `cream` must meet WCAG AA (4.5:1 for body, 3:1 for ≥ 17 pt semibold). This is verified by a unit test that computes contrast ratios from the token values.

### Type roles (`FeltType`)

All roles are built on Dynamic Type text styles so they scale.

| Role | Spec |
|---|---|
| `display` | 28 pt bold (`.title`) |
| `title` | 20 pt semibold (`.title3`) |
| `body` | 15 pt regular (`.subheadline`) |
| `label` | 11 pt semibold, uppercase, +0.14 em tracking (`.caption2`) |
| `stat` | 22 pt semibold, SF Mono, monospaced digits (`.title2`) |

### Spacing, radius, motion

- Spacing scale: 4, 8, 12, 16, 24, 32.
- Corner radii: chip 10, tile/button 14, card 8, sheet 16.
- Motion: 0.2 s ease-out for UI; 0.25 s card deal; 0.35 s card flip. Honour Reduce Motion (cross-fade instead).

### Component kit

| Component | Notes |
|---|---|
| `FeltBackground` | Radial `feltLight` (at 45% over `feltBase`; see Step 2 spec §1) → `feltBase` → `feltDeep` |
| `PlayingCard` | Drawn in SwiftUI. Large rank + suit index top-left, large suit bottom-right, cream face. Back = cream border + diagonal felt stripes. Takes an explicit width; height = width × 1.4. VoiceOver label e.g. "Eight of clubs". |
| `HandView` | Overlapping cards with a caller-provided overlap ratio; optional total label |
| `ActionDock` | Row 1: STAND, HIT (cream). Row 2: SPLIT, DOUBLE, SURRENDER (inset). States: enabled, dimmed (not allowed by rules), `hint` (brass ring, Learn mode). Minimum 44 pt tap targets. |
| `FeedbackCard` | Cream, bottom-anchored over the dock; badge (✓ `correct` / ✕ `incorrect`) straddles the top edge; headline, one-line reason, WHY + NEXT buttons |
| `StatChip` | Label + mono stat value on `surfaceInset` |
| `ModuleTile` | Title + subtitle on `surfaceInset`; tappable |
| `PrimaryButton` / `SecondaryButton` | Cream-filled / outlined |
| `ModePicker` | Segmented control on `surfaceInset`; selected segment is cream |
| `SettingsRow` | Label + value/toggle/picker, hairline separators |
| `CountKeypad` | Numeric keypad with ± for entering running/true counts |

## 5. Modules

### Navigation

`RootTabView` with three tabs: **Train** (hub), **Progress**, **Settings**. Training sessions are presented full-screen over the tabs.

### Hub (Train tab)

- Header: a compact summary of the active rules, e.g. `6D · H17 · DAS · 3:2 ›`. Tapping it switches to the Settings tab.
- Stat chips: overall strategy accuracy (last 30 days), overall count accuracy (last 30 days), current strategy streak (consecutive correct strategy decisions across sessions).
- **Continue** button: relaunches the last-used module and mode with its last setup. It is hidden on first launch.
- Tiles: Strategy, Counting, Shoe Sim, Edge.

### Strategy

**Setup screen**
- Mode: Learn / Test / Speed / Weak spots.
- Length: 25 / 50 / 100 hands, or Endless.
- Hand filter: All / Hard / Soft / Pairs.

**Trainer**
- Each hand is dealt from a fresh shoe using `HandGenerator` (applying the filter and, in Weak-spots mode, the weights) and played through `RoundEngine`, including splits.
- Every decision is graded against `StrategyEngine` for the snapshot rules. The `FeedbackCard` appears **before** the hand's outcome is revealed.
- Mode behaviour:
  - **Learn:** the correct action carries the brass hint ring before the user chooses.
  - **Test:** no hints.
  - **Speed:** a per-decision countdown (default 3.0 s, configurable 1–5 s). A timeout records an incorrect decision with the action `timeout`. Reaction time is recorded for every decision.
  - **Weak spots:** as Test, but hands come from `WeakSpotWeights`.
- WHY opens a sheet produced by `WhyExplanation` for this exact hand, upcard and rules.

**Summary**
- Accuracy, mistakes count, best streak, hands played, and average decision time (Speed mode only).
- Mistakes list: each row opens its WHY sheet.

### Counting (Hi-Lo)

**Running count drill**
- Presentation: 1, 2 or 3 cards at a time. Pace from 2.0 s to 0.3 s per group, adjustable in 0.1 s steps.
- Length: 10, 26 or 52 cards, or Full shoe (all cards for the active rules' deck count).
- Checkpoints: always at the end. Optionally also at random points, averaging one check every 8 groups.
- Answers are entered on `CountKeypad`.
- Scores: exact-correct %, mean absolute error, seconds per card.

**True count drill**
- Shows a running count and a discard tray graphic representing decks remaining (quantised to half-decks). The user enters the TC.
- The accepted answer depends on the convention preference:
  - **Exact:** within ±0.25.
  - **Floor:** ⌊RC/decks⌋.
  - **Truncate:** toward zero.

**Card values reference**
- A static Hi-Lo value table, plus a quick self-test that flashes one card and asks for +1 / 0 / −1.

### Shoe Sim

**Setup**
- Uses the active rules.
- Penetration 60–85% (default 75%).
- Pace: Self-paced or Dealer pace (auto-advances; 1.0 s per card by default).

**Play**
- A continuous shoe, with one player hand per round played through `RoundEngine`. Every strategy decision is graded but not interrupted: feedback is a compact ✓/✕ toast, not the full `FeedbackCard`.
- The count is hidden.
- Between rounds there is a random count check (default about 1 round in 4, configurable). It asks "Running count?" and, on about half of checks, also "True count?".
- The shoe ends when penetration is reached; the user can also end it early.

**Report**
- Count accuracy % (RC and TC reported separately), decision accuracy %, hands played.
- Count-over-shoe chart: actual RC line with the user's answers plotted as points.
- Mistakes list: decisions and count misses.

v1 is basic-strategy-only. Index plays and bet spreads are v2.

### Edge

- The rules form reuses `SettingsRow`s and is prefilled from the active rules or a chosen preset.
- Output:
  - Large house-edge number (e.g. `0.42%`), where a negative number means a player edge.
  - Rating from `EdgeRating`: **Good** < 0.50%, **OK** 0.50–1.00%, **Poor** > 1.00%.
  - Per-rule contribution bars from `EdgeResult.contributions`.
- **Use these rules for training** writes the rules to `ActiveRulesStore` after a confirmation.
- Accuracy bar: the house-edge validation against Wizard of Odds (`EdgeCalculatorTests`, ≥ 10 rule combinations) must keep passing.

### Progress tab

- Per-module headline numbers: strategy accuracy, running-count accuracy, true-count accuracy, and Shoe Sim combined.
- Accuracy trend chart (Swift Charts): daily points, with a 7-day / 30-day / all-time toggle.
- **Strategy heat map:** three grids (hard, soft, pairs) of player hand × dealer upcard, coloured by error rate. Cells with fewer than 3 samples are shown as "not enough data".
- Session history list, newest first. Tapping a session opens its summary or report.

### Settings tab

- **Table rules:** presets at the top (from `RulePresets`), then every `BlackjackRules` field.
- **Preferences:**
  - Speed-mode timer.
  - True-count convention (Exact / Floor / Truncate; default Exact).
  - Shoe Sim check frequency.
  - Haptics on/off.
- **Reset progress:** destructive, with a confirmation dialog. It deletes all `Session` data and keeps rules and preferences.

## 6. Data and progress

### SwiftData `SchemaV1`

This is a fresh `VersionedSchema` with a `SchemaMigrationPlan`, so future changes migrate cleanly. The old models are dropped; nothing has shipped.

- **`Session`**
  - Identity and timing: `id: UUID`, `module: String` (strategy | countingRC | countingTC | shoe), `mode: String?`, `startedAt`, `endedAt`.
  - Rules: `rulesJSON: Data`.
  - Cached summary: `decisionCount`, `correctDecisions`, `countChecks`, `correctCountChecks`, `bestStreak`, `meanResponseMs: Double?`.
  - Relationships (cascade delete): `decisions`, `countChecks`.
- **`DecisionRecord`**
  - The hand: `handNumber`, `handType: String` (hard | soft | pair), `playerValue: Int` (total, or pair rank), `dealerUpcard: Int`.
  - The decision: `chosenAction: String` (including `timeout`), `correctAction: String`, `isCorrect`, `responseMs: Int?`.
- **`CountCheckRecord`**
  - `kind: String` (running | true), `expected: Double`, `answered: Double`, `isCorrect`, `responseMs`, `cardsSeen`.

Edge results are not persisted.

### `@AppStorage`

- `activeRules` (JSON)
- `speedTimerSeconds`
- `trueCountConvention`
- `shoeCheckFrequency`
- `hapticsEnabled`
- `lastLaunch` (JSON: module, mode, setup)

### Flow

SwiftData models → mappers → plain `Sendable` values (`DecisionSample`, `CountSample`, `SessionSample`) → pure functions in `BJSCore`:

- **`ProgressStats`** produces trend series, heat-map cells, and per-module headline numbers.
- **`WeakSpotWeights`** computes a weight for each (handType, playerValue, upcard) cell:
  - Error rate is taken over the most recent 500 strategy decisions, smoothed toward the user's overall error rate p in that window: (errors + 2p) / (attempts + 2). Plain Laplace smoothing ((e+1)/(a+2)) was rejected because it gives every unseen cell 0.5, drowning out real weak spots.
  - The floor weight is 0.05, so every cell remains reachable.
  - With fewer than 50 decisions in history, the weights are uniform.
  - The weights feed `HandGenerator`.

### Error handling

- **Session saving:** a session persists only when it ends (summary reached). Leaving mid-session prompts **Save partial / Discard**. Save partial requires at least 1 graded decision or count check.
- **Rules decoding:** if the `activeRules` JSON fails to decode, fall back to `BlackjackRules()` defaults and log via `os.Logger`.
- **Save failures:** a SwiftData save failure shows a non-blocking alert and never crashes. The session summary is still shown.

## 7. Testing

**`BJSCore`** uses Swift Testing via `swift test`, written TDD. The existing 95 tests must stay green.

- **`RoundEngine`**, parameterised across rule sets (S17/H17, DAS on/off, RSA, hit split aces, max split hands, surrender none/late/early, peek vs ENHC):
  - naturals and peek handling;
  - split limits and split-ace restrictions;
  - double restrictions;
  - dealer play;
  - settlement: payouts 3:2 / 6:5 / 2:1, surrender returning 0.5, pushes.
- **Strategy charts:** every decoded chart matches Wizard of Odds' rendered charts cell for cell (48 rule combinations, `WoOChartTests`; see `2026-09-24-woo-strategy-data-design.md` §6).
- **Property checks** over 100k seeded rounds:
  - the Hi-Lo RC over a fully dealt shoe returns to 0;
  - no round ever leaves an illegal state.
- **`HandGenerator`** (seeded):
  - filters are respected;
  - weighted sampling converges to the target distribution;
  - no cell's probability ever reaches 0.
- **`WeakSpotWeights`** and **`ProgressStats`:** hand-built fixtures with known answers.
- **`CountDrillGenerator`:** group sizes, lengths, and correct expected counts.
- **`EdgeRating`:** thresholds, including boundary values.
- **`WhyExplanation`:** the existing tests move along with the code.

**App target** uses Swift Testing for ViewModels, with an injected seed or fake shoe to step through phase sequences deterministically. Required regression test: STAND always produces feedback before the next hand (the Phase 7 bug).

**UI** uses XCTest UI tests:
- launch → hub → 5-hand Strategy session → summary visible;
- a 10-card RC drill end to end.

**Design check** at the end of each step:
- screenshots on iPhone 16 and iPhone SE (3rd gen) are compared against Section 4;
- the colour-contrast unit test must pass.

This is a conformance check, not a redesign opportunity.

## 8. Build order

Each step gets its own writing-plans implementation plan and must be complete and verified before the next starts. Steps 4 and 5 are independent and can run in parallel.

| Step | Scope | Done when |
|---|---|---|
| **0. Cleanup** | Deletions per §3. Add `.superpowers/` to `.gitignore`. Rewrite the project `CLAUDE.md`: remove GSD, add conventions and the design-freeze rule, point to this spec. Minimal `BJSApp` that compiles with an empty `RootTabView`. | Clean build; `swift test` green; no GSD references remain |
| **1. Engine completion** | Seeded RNG + injectable `Shoe` shuffling; legal-action-aware `StrategyTable` lookup with hit/stand fallback tables (fixes the old app mapping every illegal double to hit, e.g. soft 18 vs 6 on 3 cards must stand); `RoundEngine`, `WhyExplanation` + `RulePresets` moved into `BJSCore`, `HandGenerator`, `CountDrillGenerator`, `EdgeRating`, `ProgressStats`, `WeakSpotWeights`, sample types | All §7 `BJSCore` tests green |
| **2. Foundation** | Felt tokens + full component kit, `RootTabView` + hub shell (tiles route to placeholders), Settings (rules + presets + preferences), `ActiveRulesStore`, SwiftData `SchemaV1` + mappers | Design check passes → **design frozen** |
| **3. Strategy** | Setup, trainer (4 modes), WHY sheet, summary, persistence, Continue wiring | Strategy UI test + STAND regression test green |
| **4. Counting** | RC drill, TC drill, card values reference, persistence | RC UI test green |
| **5. Edge** | Calculator screen, rating, breakdown, "use these rules" | WoO validation still green; design check |
| **6. Progress** | Headline numbers, trend chart, heat map, history | Fixtures render correctly; design check |
| **7. Shoe Sim** | Setup, play loop with count checks, report, persistence | End-to-end manual run plus ViewModel tests |
| **8. Launch prep** | App icon, launch screen, accessibility pass (Dynamic Type to AX3, VoiceOver on cards and dock, Reduce Motion), privacy manifest (no data collected), App Store metadata and screenshots | TestFlight build uploaded |

## 9. Open questions

None. All decisions above were made in the 2026-09-23 brainstorming session.

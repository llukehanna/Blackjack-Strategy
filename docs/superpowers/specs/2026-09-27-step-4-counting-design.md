# Step 4 — Counting — Design

**Date:** 2026-09-27
**Status:** Approved in brainstorming; pending written-spec review
**Parent spec:** `2026-09-23-bjs-rebuild-design.md` (§5 Counting, §6 data, §7 testing, §8 Step 4)

Step 4 builds the Counting module: the running count (RC) drill, the true count (TC) drill, the card values reference with its self-test, and persistence. This document records only what the parent spec leaves open or amends, plus carry-overs from `progress.md`. Everything else follows the parent spec as written.

The Felt design system is frozen. This step adds one new component built from existing tokens (`DiscardTray`), and it changes no existing token or component.

## 1. Decisions and amendments

| Topic | Decision | Why |
|---|---|---|
| RC checkpoint feedback | After each checkpoint answer, the `FeedbackCard` reveals ✓/✕ and the correct RC. The user taps NEXT, and the drill resumes from the **correct** count. | One slip doesn't spoil every later checkpoint, and the correction lands straight away. |
| RC WHY | WHY opens a trace sheet: every card since the previous checkpoint, with its Hi-Lo value and the running total. | This shows where the count went wrong. It also lets the frozen `FeedbackCard`, which always has a WHY button, be reused unchanged. |
| TC decks remaining | Shown only as a `DiscardTray` graphic: decks played against the full shoe, with faint whole-deck ticks and **no number**. Feedback shows the exact decks remaining and the working. | This drills the estimation a counter does at a table, not just the division. |
| TC question steps (**amends** parent §5) | Decks remaining is quantised to **quarter decks for 1–2 decks** and half decks for 4 or more. | With half-deck steps, a 1-deck game only ever has 0.5 decks remaining, which makes the drill trivial. |
| TC question range | The RC is drawn from −12…12 and redrawn until \|exact TC\| ≤ 10. | Quarter decks would otherwise allow absurd questions (for example +12 ÷ 0.25 = +48). |
| TC length | 10 / 20 / Endless. Endless has an END button. | Mirrors Strategy's fixed-or-Endless choice at a scale that suits quick arithmetic. |
| Card values self-test | Not persisted. An endless warm-up with an in-screen score and streak. | It's a learning aid. Persisting it would dilute count accuracy with trivially easy checks. |
| Structure | One `CountingFlowView` with a drill menu. RC and TC are separate phase machines. | Only RC has a timed presentation phase. A shared machine would branch on drill type everywhere. |
| Full-deck RC drills (**amends** parent §5; decided 2026-09-27, after the build) | Full shoe holds back a random 5–15 card tail. A card length equal to the whole shoe (e.g. 52 cards under 1-deck rules) draws from one extra deck. | Hi-Lo is balanced, so dealing a whole shoe always ends at RC 0 and the final check could be answered without counting, inflating count accuracy. |

## 2. Structure and navigation

- **Entry:** `ModuleHost` maps `.counting` to `CountingFlowView`. It shows a menu with three rows: **Running count**, **True count**, **Card values**. Each drill runs setup → drill → summary inside the same full-screen cover. From a setup screen, back returns to the menu. × closes the module.
- **Continue:**
  - Starting an RC or TC drill writes `PreferencesStore.lastLaunch`: module `.countingRC` or `.countingTC`, mode `nil`, and the encoded setup.
  - The hub already maps both modules to `AppModule.counting`.
  - `CountingFlowView(initialLaunch:)` takes the module and setup data. It decodes the setup and goes straight to that drill.
  - If the setup fails to decode, it shows the menu and logs the failure.
  - Card values never writes `lastLaunch`.
- **`Features/Counting/`:**
  - `CountingFlowView` and `CountingMenuView`
  - `RunningCountSetup` and `RunningCountSetupView`
  - `RunningCountDrillViewModel` and `RunningCountDrillView`
  - `TrueCountSetup` and `TrueCountSetupView`
  - `TrueCountDrillViewModel` and `TrueCountDrillView`
  - `CountSummaryView`, shared by RC and TC
  - `CountTraceSheet` (the RC WHY sheet) and `TrueCountWorkingSheet` (the TC WHY sheet)
  - `CardValuesView` and `CardValuesViewModel`
  - `CountingText` (copy)
- **New component** (`Design/Components/`, existing tokens only, added to `FeltCatalogue`):
  - `DiscardTray(decksTotal: Double, decksPlayed: Double)`: a tray outline the height of the full shoe, filled to `decksPlayed` with stacked card edges on `cream`.
  - Faint whole-deck ticks in `textTertiary` run along the tray wall. There is no numeric label.
  - VoiceOver reads "Discard tray, about N decks played", rounded to the nearest half deck, so the drill stays about estimation.

## 3. BJSCore changes (TDD)

1. **`CountDrillGenerator.trueCountQuestion(deckCount:using:)`:**
   - Step: 0.25 decks when `deckCount <= 2`, otherwise 0.5.
   - Decks remaining is drawn uniformly from `step … deckCount − step`, in steps.
   - The RC is drawn uniformly from −12…12 and redrawn while |RC ÷ decks remaining| > 10.
2. **`TrueCountQuestion.target(for: TrueCountConvention) -> Double`:**
   - Exact → `exactTrueCount`; Floor → rounded down; Truncate → rounded toward zero.
   - `isCorrect` is unchanged: Exact stays within ±0.25.
3. **`RunningCountDrill.trace(throughGroup:) -> [CountTraceEntry]`:**
   - Returns every card from the group after the previous checkpoint through the given group.
   - `CountTraceEntry` holds `card`, `value` and `runningCount`.
   - The first checkpoint's trace starts at the first card.
4. **`CountDrillScore`:**
   - Built from `[(expected: Double, answered: Double, isCorrect: Bool)]`.
   - Gives `checks`, `correct`, `accuracy: Double?` (nil when empty) and `meanAbsoluteError: Double?`.
   - `static func secondsPerCard(pace:groupSize:)` gives the RC figure.

## 4. Drill flows

Both ViewModels are `@Observable` phase machines with an injected RNG (`SeededRandomNumberGenerator` in tests) and an injected clock. They take a `persist` closure, as Strategy does.

### Running count

- **Setup** (`RunningCountSetup`, `Codable`):
  - group size 1 / 2 / 3, default 1;
  - pace 0.3–2.0 s per group in 0.1 s steps, default 1.0;
  - length 10 / 26 / 52 cards or Full shoe (the active rules' deck count, less a random 5–15 card tail), default 52;
  - random checkpoints, off by default.
- **Phases:**
  1. `presenting(groupIndex)`:
     - the group's cards are shown face up, side by side, replacing the previous group, with "Card n / N" above them;
     - the view's timer task calls `advance(token:)` after `pace` seconds;
     - a stale token is ignored, as with Strategy's `timeoutElapsed(token:)`.
  2. **At a checkpoint group:** after its interval, the phase moves to `answering(checkpoint)`. `CountKeypad` appears with `allowsHalf: false`, and the answer clock starts.
  3. **Enter** grades the answer: `answered == expectedCount(afterGroup:)`.
     - It records a `CountCheckDraft` (kind `.runningCount`, `cardsSeen` = cards shown so far, response ms).
     - It plays a haptic when enabled, then moves to `feedback`.
     - The `FeedbackCard` reads: headline "Running count is +3"; reason "You said +2" (or "Correct").
  4. **WHY** opens `CountTraceSheet` with `trace(throughGroup:)`.
  5. **NEXT** goes to the next `presenting`, or to `summary` after the last group.
- **Pausing:**
  - The presentation timer stops while the leave dialog is open or the scene isn't active.
  - On return, `restartPresentation()` gives the current group a fresh full interval.
- **Summary:**
  - exact-correct %;
  - mean absolute error;
  - seconds per card;
  - a checkpoint list: "After card n: +3 · you said +2".
  - **Again** runs the same setup with a new shuffle; **Done** closes.

### True count

- **Setup** (`TrueCountSetup`, `Codable`):
  - length 10 / 20 / Endless, default 10;
  - the convention, shown read-only from `PreferencesStore` with the note "Change in Settings". The session snapshots it at start.
- **Phases:**
  1. `question(n)`:
     - the RC is shown large (`FeltType.stat`, signed);
     - `DiscardTray(decksTotal: deckCount, decksPlayed: deckCount − decksRemaining)` is shown next to it;
     - `CountKeypad` shows the .5 key only under Exact;
     - the answer clock starts.
  2. **Enter** grades with `isCorrect(_:convention:)`.
     - It records a `CountCheckDraft`: kind `.trueCount`, `expected = target(for:)`, `cardsSeen = Int(((deckCount − decksRemaining) × 52).rounded())`, response ms.
     - It plays a haptic when enabled, then moves to `feedback`.
     - The `FeedbackCard` reads: headline "True count is +2.5"; reason "RC +7 ÷ 2.5 decks left = +2.8" (the exact value to one decimal).
  3. **WHY** opens `TrueCountWorkingSheet` with the working, the decks remaining, and the convention's rule ("Exact: within 0.25 of RC ÷ decks").
  4. **NEXT** goes to the next question, or to `summary` when the length is reached.
  5. **END** (Endless only) goes to the summary, or closes when nothing has been graded.
- **Summary:** accuracy %, mean absolute error against the target, and a question list ("+7 · 2.5 decks → +2.8 · you said +3"). Again and Done work as in RC.

### Card values

- A static table: 2–6 = +1, 7–9 = 0, 10–A = −1, each row with small `PlayingCard`s.
- Below it, the self-test:
  - one random card (from the injected RNG), with three `SecondaryButton`s: **+1**, **0**, **−1**;
  - a correct answer shows the ✓ `FeltToast` and the next card straight away;
  - a wrong answer shows the `FeedbackCard` ("A 5 is +1"). Its WHY scrolls to that rank's row in the table; NEXT gives the next card.
  - An in-screen score (correct / total) and streak are shown.
- Nothing is persisted.

## 5. Sessions and persistence

- **No schema change.**
- **RC session:** `module = countingRC`, `mode = nil`.
- **TC session:** `module = countingTC`, `mode` = the convention's raw value, so history can say how it was graded. This mode is not in `statsExcludedModes`.
- **Leaving mid-drill (×):**
  - With at least 1 graded check, a confirmation dialog offers **Save partial** (save, then summary) or **Discard** (close).
  - With none, it closes straight away.
  - The dialog keeps system styling (an accepted exception).
- **Save once:** a `hasSaved` guard means each session id reaches `SessionStore.save` at most once.
- **Save failure:** a non-blocking alert ("Couldn't save this session"). The summary is still shown.
- **Hub:** the count-accuracy chip already reads `countingRC`, `countingTC` and `shoe`. No change is needed.
- **Carry-over:** add a direct `SessionStore.countSamples(forStats:)` test.
- **UI-test hooks** (`LaunchConfiguration`, honoured only with `-uiTesting`):
  - `-seed N` also seeds the counting drills;
  - the new `-countPace S` overrides the RC pace.

## 6. Testing

- **BJSCore (Swift Testing, TDD):**
  - TC question steps for 1, 2, 6 and 8 decks, and the |TC| ≤ 10 cap over many seeds;
  - `target(for:)` for each convention, including negative values (floor −2.3 → −3, truncate −2.3 → −2);
  - `trace(throughGroup:)` for the first and later checkpoints and for group sizes 1–3;
  - `CountDrillScore`: empty input, all correct, mixed, and mean absolute error.
  - Existing 229 tests stay green.
- **App (Swift Testing):**
  - the RC phase sequence with a seeded drill: presenting → checkpoint → answering → feedback → presenting → summary;
  - stale `advance` tokens are ignored;
  - random checkpoints;
  - pausing and resuming;
  - the TC .5 key only under Exact;
  - TC grading per convention;
  - Endless END;
  - Save partial / Discard;
  - the save-once guard;
  - save failure still shows the summary;
  - the `lastLaunch` round trip and the Continue fallback;
  - Card values scoring and streak;
  - `countSamples(forStats:)`.
- **UI test (XCTest):** launch (`-uiTesting -seed 1 -countPace 0.3`) → hub → Counting → Running count → 10 cards → Start → the keypad appears → enter an answer → NEXT → the summary is visible.
- **Design check:** iPhone 16 and iPhone SE screenshots of the menu, both setups, RC presenting and feedback, the trace sheet, the TC question with `DiscardTray`, TC feedback, the summary and Card values. They are compared against parent spec §4. The contrast test stays green, and `FeltCatalogue` shows `DiscardTray`.

## 7. Out of scope

- Shoe Sim count checks (Step 7) and Progress charts (Step 6).
- Other counting systems, and deviation indices.
- Changes to any frozen token or component.

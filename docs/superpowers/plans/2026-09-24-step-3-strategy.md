# Step 3: Strategy — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Strategy module end to end: the setup screen (mode Learn / Test / Speed / Weak spots, length 25 / 50 / 100 / Endless, filter All / Hard / Soft / Pairs); the trainer, which deals every hand from a fresh stacked shoe through `RoundEngine` (splits included), grades every decision against the strategy table for the session's rules, and shows the `FeedbackCard` before the hand's outcome; the WHY sheet; the summary; persistence (`Session` + one `DecisionRecord` per decision, each with its own `decidedAt`); the leave prompt (Save partial / Discard); and the hub's Continue button (`lastLaunch`). Done when (spec §8) the Strategy UI test and the STAND regression test are green in CI, and the Strategy screens pass the design check.

**Architecture:** Game logic goes into `BJSCore`, where it runs and is tested on Linux:
- `BJSCore/Training/` gains `StrategySessionConfig` (mode, length, filter), `GradedDecision` + `DecisionChoice` (a timeout is a choice), a `WhyContext(spot:…)` helper, `StrategySessionSummary`, and `StrategySession`, a pure value-type state machine (decision → feedback → next decision or outcome → next hand → finished) that wraps `HandGenerator` + `RoundEngine` + `StrategyTable`.
- `BJSCore/Explain/DecisionFeedback` gives the FeedbackCard headline and reason, plus the spot titles for the WHY sheet and the mistakes list.

The app gains:
- `BJS/Shared/`: `LastLaunch` + `LastLaunchStore` (the `lastLaunch` JSON), and display names for modes, lengths and filters.
- `BJS/Persistence/`: `StrategySessionSnapshot`, the `StrategySessionSaving` protocol, the SwiftData saver, and `DecisionHistory` for Weak spots.
- `BJS/Design/Components/CountdownBar`: a new component built from existing tokens.
- `BJS/Features/Strategy/`: a thin `@MainActor @Observable` `StrategyTrainerViewModel` (it owns the RNG, the clock, the Speed countdown token, the WHY sheet, the leave prompt and saving), `StrategyText`, and the setup, trainer, WHY, summary and session-container views.
- `BJS/App/RootTabView`: routes the Strategy tile to setup, presents sessions full-screen, records `lastLaunch`, and wires Continue.

A new dev script, `scripts/dev/linux_app_check.sh`, runs the app's Foundation-only files and their Swift Testing suites on Linux. That covers the ViewModel, including the required STAND regression test, before CI.

**Tech Stack:** Swift 6.2 (language mode 6, `SWIFT_STRICT_CONCURRENCY: complete`), SwiftUI + Observation + SwiftData (iOS 18+), Swift Testing for unit tests, XCTest for UI tests, XcodeGen, GitHub Actions (`macos-26`, Xcode 26).

**Spec:** `docs/superpowers/specs/2026-09-23-bjs-rebuild-design.md`. Before any task, read §3 (Architecture), §4 (Felt, frozen), §5 (Navigation, Hub, Strategy), §6 (Data, including error handling), §7 (Testing) and the §8 Step 3 row. Read the Step 1 and Step 2 entries in `docs/superpowers/progress.md`.

## Global Constraints

- **The app builds only in CI.** The dev container is Linux. BJSCore builds and tests locally. The app target builds only in `.github/workflows/ios.yml` (macos-26, Xcode 26). The workflow runs on every push to `main-8v0ds1` and takes about 20 minutes: unit tests, then UI tests + screenshots on iPhone 16 and iPhone SE. Every app task therefore ends with:
  1. local pre-checks (below);
  2. **the implementer commits and reports the SHA. It does not push;**
  3. **the controller pushes and checks the CI run** ("CI verification (controller)" below). If CI fails, the controller gives the failing log lines back to the implementer, who fixes forward in a new commit (`fix(<scope>): …`) until the run is green. Do not start the next app task on a red run.

  Tasks 1–4 change only BJSCore or add a dev script. They are verified locally, and one CI run after Task 4 covers all four.
- **Local pre-checks** (from the repo root, after `export PATH=/opt/swiftroot/usr/bin:$PATH`):
  - **Engine:** `(cd BJSCore && swift build 2>&1 | tail -1 && swift test 2>&1 | tail -1)` should print the build line and then `Test run with N tests in M suites passed`. N is the running BJSCore count: 195 now, 208 after Task 1, 223 after Task 2, and 228 from Task 3 on.
  - **App logic on Linux (from Task 4):** `scripts/dev/linux_app_check.sh <files>` builds the listed Foundation/Observation/BJSCore-only app files as a throwaway package named `BJS`, so `@testable import BJS` works unchanged, and runs the listed `BJSTests` files. `AppLog` is replaced by a shim. Each task gives the exact file list and the expected `Test run with …` line. The first run also builds BJSCore (about 30 s).
  - **Syntax of every touched Swift file:** `swiftc -parse <files>` should print nothing. It needs no SDK, so it works on SwiftUI files too.
  - **Type-check** files that import only Foundation/BJSCore: `swiftc -swift-version 6 -typecheck -I BJSCore/.build/debug/Modules <files>` should print nothing. Run `swift build` in BJSCore first.
- **Isolation (unchanged from Step 2):** the app is nonisolated by default.
  - Stores and ViewModels are `@MainActor @Observable final class`.
  - Static constants read from anywhere are `nonisolated static let`.
  - Test suites that touch `@MainActor` types are `@MainActor`.
  - Closures handed from `RootTabView` to feature views are closure literals (`{ config in startStrategy(config) }`), never method references. Method references would be `@MainActor`-isolated function values.
- **SwiftUI initialiser rule:** a view with parameters and a `private` stored property that has a default value (including `@State private var x = …`) declares an explicit `init`. The code below does this.
- **Architecture (spec §3):**
  - `Features/Strategy` never references `Features/Hub` or `Features/Settings` types, and the Hub never references Strategy views.
  - `App/RootTabView` is the only place that maps hub routes to screens and presents sessions.
  - Shared code lives in `Design/`, `Shared/`, `Persistence/` or `BJSCore`.
  - Game logic (dealing, grading, sequencing, summary maths, feedback wording) lives in `BJSCore`. The ViewModel only calls it, maps it for display, owns timing, and saves.
- **Design freeze (spec §4, pending Luke's formal approval).**
  - Use only existing tokens and components, and do not restyle any of them.
  - New pieces are built only from existing tokens: `CountdownBar`, the setup-section captions, the outcome panel, the mistake rows and the WHY sheet layout.
  - `brass` appears only on the Learn hint ring. `correct`/`incorrect` appear only on the FeedbackCard badge.
- **XcodeGen owns the project.** New folders under `BJS/` are picked up by `sources: [BJS]`. This step needs no `project.yml` change.
- **Tests:**
  - Unit tests use Swift Testing (`@Test`, `#expect`, `#require`) in `BJSTests`. XCTest is only for `BJSUITests`.
  - Tests never touch `UserDefaults.standard`; use `TestDefaults.make()`.
  - Tests never touch an on-disk store; use `PersistenceController.makeContainer(inMemory: true)`, and create the container before any `@Model` object.
  - Randomness is seeded: `SeededRandomNumberGenerator`, or a scripted shoe.
- **Maths:** this step changes no strategy or EV maths. The engine's table is the grader. See Decision 1 about hard 16 vs 10.
- **YAGNI:** nothing from Steps 4+. No Counting, Shoe Sim, Edge or Progress screens. Continue handles only `module == .strategy`.
- **Commits:** one per task (plus fix-forward commits), with a conventional prefix and scope. Every message ends with a blank line and then these two lines (use the model actually doing the work in the first line):
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi
  ```
- **Branch:** `main-8v0ds1`. Stay on it.

## Decisions this plan makes (spec gaps or ambiguities)

Luke reviews these at the Step 3 design check (Task 12). None changes a §4 token or an existing component.

1. **For Luke: hard 16 vs 10 is graded STAND** (6 decks, S17, no surrender; also under H17). The trainer grades against `StrategyEngine`, and the engine returns *stand* here.
   - The existing `StrategyValidationTests` assert this as "WoO validated" (RS1 and RS7).
   - The Wizard of Odds 4–8-deck charts show *hit* (or surrender when allowed) for two-card 16 vs 10. The cause looks like `StrategyEngine.standingBias` (+0.004 toward standing for hard 12–16 vs 7–A).
   - This plan does not change the maths (the step is scope-frozen, and CLAUDE.md requires WoO-referenced tests for strategy changes). The tests here avoid that spot and use hard 16 vs **7**.
   - **Luke should decide whether a `fix(core)` with WoO reference values lands before Step 3 ships.** Otherwise Learn mode will teach standing on 16 vs 10.
2. **Grade first, apply on NEXT.** A tapped action is graded at once (session phase `feedback`), but the round does not play it until NEXT. Nothing is drawn and the hole card stays down while the FeedbackCard shows. This guarantees "feedback before the outcome" for every action, including STAND (the Phase 7 bug).
3. **Wrong actions are played as chosen.** The user lives with the choice. **After a timeout, NEXT plays the correct action**, so the hand continues on the right line.
4. **Explicit outcome step.** When a hand settles, the outcome panel shows "Dealer has 19" / "Dealer busts", each hand's result ("Win +1", "Bust −2") and a **Next hand** button. On the last hand of a limited session the button reads **See summary**. There is no auto-advance, which keeps the ViewModel deterministic and testable.
5. **Hands played** counts hands that reached settlement. Endless has an **End** button (any phase) that finishes the session and shows the summary. An unfinished hand does not count, but its graded decisions do.
6. **Leaving mid-session.**
   - The close button (✕) closes at once when nothing has been graded, since there is nothing to save.
   - Otherwise an alert offers **Save partial** (ends here, saves, shows the summary), **Discard** (closes, saves nothing) and **Keep playing**.
   - The Speed countdown pauses while the alert is up and restarts from full on Keep playing.
   - On the summary, ✕ is not shown; **Done** closes.
7. **Reaction time.**
   - Every decision records `responseMs`, measured from when that decision started (the deal, or dismissing the previous feedback), not from session start.
   - A timeout records the full countdown (e.g. 3000 ms).
   - `Session.meanResponseMs` is stored for every mode (it is a cached summary field) but shown only in Speed mode.
   - The mean includes timeouts.
8. **Best streak** is the longest run of correct decisions within the session. The hub's streak is unchanged: consecutive correct decisions across sessions.
9. **Weak spots history** is the newest 500 `DecisionRecord`s from any module (Shoe Sim decisions are strategy decisions too). With fewer than 50, `WeakSpotWeights` returns nil and hands are dealt uniformly. The setup text says so.
10. **`lastLaunch`.**
    - JSON `{"module":"strategy","mode":"speed","strategy":{mode,length,filter}}`, stored as `Data` under the `lastLaunch` key, like `activeRules`.
    - It is recorded when a session **starts** (setup Start or Continue).
    - Continue starts the trainer directly with that setup, skipping the setup screen. The setup screen is prefilled from it.
    - Continue appears between the stat chips and the tiles as a `PrimaryButton` ("Continue: Strategy · Learn") with a `label`-style detail line ("25 hands · All hands").
    - Later modules add their own optional setup field.
11. **Routing.**
    - The Strategy tile pushes the setup screen on the hub's stack.
    - `RootTabView` owns `activeSession` and presents `StrategySessionScreen` with `.fullScreenCover`, over the tabs (spec §5).
    - Closing returns to wherever the session was launched from (setup or hub).
12. **What is persisted.**
    - `Session.mode` stores the mode raw value (`learn`, `test`, `speed`, `weakSpots`). Length and filter are not persisted (SchemaV1 has no field, and nothing reads them).
    - `DecisionRecord` uses `TrainingCell(spot:)`: a pair counts as a pair only while splitting is legal, and ace = 11.
    - The record's `chosenAction` is the action raw value or `"timeout"`.
13. **WHY for a timeout.** `WhyContext.userAction` is an `Action`, so a timeout passes the correct action. The explanation depends only on the correct action. The WHY sheet shows "Basic strategy: X" and never claims what the user did.
14. **Deterministic UI tests.**
    - `BJS_STRATEGY_SEED=<UInt64>` in the launch environment fixes the session seed. It is read in any build; it is only a seed.
    - The UI test still never assumes which hands come. It plays the Learn-mode ringed button (accessibility value "Suggested"), or else the first enabled dock button.
15. **New visual pieces (from existing tokens only):**
    - `CountdownBar`: an 8 pt cream capsule on a `surfaceInset` track. It is hidden (opacity 0, layout kept) when no countdown runs.
    - Setup-section captions: `label` in `textTertiary`, like `SettingsSection` titles.
    - Top bar: ✕, "Hand 3 of 25" over the mode name, and the score "7/9" or **End**.
    - Soft totals as "8/18".
    - Split hands: the hands not being played are at 40% opacity (the existing "dimmed" value).
    - Outcome panel: a `title` line plus a `PrimaryButton`.
    - Mistake rows: inside a `SettingsSection` panel, with the SettingsRow hairline recipe.
    - WHY sheet: `feltBase` background, sheet radius 16, medium/large detents, "Done" at the top right, and a `StatChip` for the play.
    - The FeedbackCard is overlaid on the bottom of the dock (spec: "over the dock"). The dock stays underneath with every button disabled.
16. **Where the logic lives.** Sequencing a session (`StrategySession`) and the feedback wording (`DecisionFeedback`) are in BJSCore (spec §3 rule 1: "drills, explanations"), so they are tested on Linux. `StrategyText` (totals, net results, percentages) is presentation and stays in the app.
17. **One `StrategyEngine` for the app** (`StrategyTrainerViewModel.strategyEngine`), so each rule set's table is generated once (about 11 ms).
18. **Errors.**
    - An engine error mid-session cannot happen with a stacked shoe of at least one deck. If it ever did, the session ends gracefully and the summary shows what was graded.
    - A SwiftData save failure rolls the context back, is logged, and shows the alert "Couldn't save this session". The summary still shows (spec §6), and there is no retry.
19. **Linux harness.** `scripts/dev/linux_app_check.sh` is dev tooling, not part of any target. Steps 4+ can reuse it for their ViewModels.

---

## File map

**Created:**

| File | Responsibility |
|---|---|
| `BJSCore/Sources/BJSCore/Training/StrategySessionConfig.swift` | `StrategyMode`, `StrategySessionLength`, `StrategySessionConfig` |
| `BJSCore/Sources/BJSCore/Training/GradedDecision.swift` | `DecisionChoice`, `GradedDecision`, `WhyContext(spot:userAction:correctAction:rules:)` |
| `BJSCore/Sources/BJSCore/Training/StrategySessionSummary.swift` | Accuracy, mistakes, best streak, hands, mean response |
| `BJSCore/Sources/BJSCore/Training/StrategySession.swift` | Trainer state machine over `HandGenerator` + `RoundEngine` + `StrategyTable` |
| `BJSCore/Sources/BJSCore/Explain/DecisionFeedback.swift` | FeedbackCard headline/reason, hand and spot names |
| `BJSCore/Tests/BJSCoreTests/TrainingTests/GradedDecisionTests.swift` | Config, decision, WhyContext and summary tests (+ `makeSpot`, `makeDecision` helpers) |
| `BJSCore/Tests/BJSCoreTests/TrainingTests/StrategySessionTests.swift` | State-machine tests incl. the core STAND regression |
| `BJSCore/Tests/BJSCoreTests/ExplainTests/DecisionFeedbackTests.swift` | Wording tests |
| `scripts/dev/linux_app_check.sh` | Runs Linux-safe app files + tests as a throwaway package |
| `BJS/Shared/LastLaunch.swift` | `lastLaunch` value + JSON coding |
| `BJS/Shared/LastLaunchStore.swift` | `@Observable` store under the `lastLaunch` key |
| `BJS/Shared/TrainingDisplay.swift` | Display names for modules, modes, lengths, filters; Continue text |
| `BJS/Persistence/StrategySessionSaving.swift` | `StrategySessionSnapshot`, `StrategySessionSaving` |
| `BJS/Persistence/StrategySessionWriter.swift` | `SwiftDataStrategySessionSaver`, `StrategyRecordMapper`, `DecisionHistory` |
| `BJS/Design/Components/CountdownBar.swift` | Speed countdown bar (new component, existing tokens) |
| `BJS/Features/Strategy/StrategyTrainerViewModel.swift` | Thin `@MainActor @Observable` adapter |
| `BJS/Features/Strategy/StrategyText.swift` | Progress, totals, net, outcome, percent, seconds, mistake text |
| `BJS/Features/Strategy/StrategySetupView.swift` | Setup screen |
| `BJS/Features/Strategy/StrategyTrainerView.swift` | Table, dock, feedback, outcome, countdown, alerts, WHY sheet |
| `BJS/Features/Strategy/WhySheet.swift` | WHY sheet |
| `BJS/Features/Strategy/StrategySummaryView.swift` | Summary + mistakes list |
| `BJS/Features/Strategy/StrategySessionScreen.swift` | Full-screen container: snapshots rules/timer, loads history, builds the ViewModel |
| `BJSTests/LastLaunchStoreTests.swift` | Store, display text, launch seed |
| `BJSTests/StrategyFixtures.swift` | Shoes, decisions, snapshots, `FakeClock`, `FakeStrategySaver` |
| `BJSTests/StrategySessionWriterTests.swift` | SwiftData saver + history |
| `BJSTests/StrategyTextTests.swift` | Display text |
| `BJSTests/StrategyTrainerViewModelTests.swift` | ViewModel phases incl. **"STAND always produces feedback before the next hand"** |
| `BJSTests/CountdownBarTests.swift` | Countdown maths |
| `BJSUITests/StrategySessionUITests.swift` | 5-hand session → summary; Speed timeout → Save partial → mistake WHY; screenshots |

**Modified:**
- `BJS/App/LaunchConfiguration.swift` (Task 5: `strategySeed`)
- `BJS/Design/Gallery/ComponentGallery.swift` and `BJSUITests/DesignScreenshotTests.swift` (Task 8: countdown page; Task 10: placeholder screenshot moves to the Counting tile)
- `BJS/Features/Hub/HubView.swift`, `BJS/App/RootTabView.swift` and `BJS/App/BJSApp.swift` (Task 10)
- `docs/superpowers/progress.md` (Task 12)

**Task order and counts:**

| After task | BJSCore tests (local + CI) | App unit tests (CI) | UI tests (CI) | Screenshots per device |
|---|---|---|---|---|
| now | 195 | 60 | 2 | 16 |
| 1 | 208 | 60 | 2 | 16 |
| 2 | 223 | 60 | 2 | 16 |
| 3–4 | 228 | 60 | 2 | 16 |
| 5 | 228 | 67 | 2 | 16 |
| 6 | 228 | 71 | 2 | 16 |
| 7 | 228 | 90 | 2 | 16 |
| 8–10 | 228 | 91 | 2 | 17 |
| 11 | 228 | 91 | 4 | 29 |

Swift Testing counts each `@Test` function once; parameterised tests are one test each.

---

### CI verification (controller): the same procedure closes every app task

Referenced below as **"CI verification"**. The controller (not the implementer) does this:

1. `git push origin main-8v0ds1`
2. Find the run for the pushed SHA: GitHub MCP `actions_list` (workflow `ios.yml`, branch `main-8v0ds1`), or `gh run list --branch main-8v0ds1 --limit 1` where `gh` is installed. Wait for it to finish (about 20 minutes).
3. Expected: the run is green.
   - "Engine tests (BJSCore)" ends with `Test run with <BJSCore count> tests … passed`.
   - "Unit tests" ends with `** TEST EXECUTE SUCCEEDED **`, with the task's app unit-test count from the table above.
   - Both "UI tests + screenshots" steps end with `** TEST EXECUTE SUCCEEDED **`.
   - "Export screenshots" prints `Exported <n> screenshots to build/screenshots/iphone-16`, and the same for `iphone-se`.
4. If red: fetch the failing job log (GitHub MCP `get_job_logs`, or `gh run view --log-failed`), give the error lines to the implementer, and repeat from 1 after their fix commit. For a failing UI test, also download the `xcresults` artifact if the log alone does not show which element was missing.

---

# STEP 3 — STRATEGY

### Task 1: Strategy session config, graded decisions and session summary (BJSCore)

**Files:**
- Create: `BJSCore/Sources/BJSCore/Training/StrategySessionConfig.swift`, `GradedDecision.swift`, `StrategySessionSummary.swift`
- Test: `BJSCore/Tests/BJSCoreTests/TrainingTests/GradedDecisionTests.swift`

**Interfaces:**
- Consumes: `Action`, `DecisionSpot`, `TrainingCell(spot:)`, `HandFilter`, `WhyContext`, `WhyExplanation` (all existing, public)
- Produces:
  - `enum StrategyMode: String, CaseIterable, Sendable, Codable { learn, test, speed, weakSpots }` with `showsHint`, `isTimed`, `usesWeakSpotWeights`
  - `enum StrategySessionLength: String, CaseIterable, Sendable, Codable { hands25, hands50, hands100, endless }` with `handLimit: Int?`
  - `struct StrategySessionConfig: Sendable, Hashable, Codable { var mode, length, filter; init(mode: = .learn, length: = .hands25, filter: = .all) }`
  - `enum DecisionChoice: Sendable, Hashable { case action(Action), timeout; static timeoutStorageValue = "timeout"; storageValue: String; action: Action? }`
  - `struct GradedDecision: Sendable, Equatable, Identifiable { sequence, handNumber, spot, cell, choice, correctAction, responseMs: Int?, decidedAt: Date; id: Int; isCorrect; init(sequence:handNumber:spot:choice:correctAction:responseMs:decidedAt:); whyContext(rules:) -> WhyContext }`
  - `extension WhyContext { init(id: = UUID(), spot:, userAction:, correctAction:, rules:) }`
  - `struct StrategySessionSummary: Sendable, Equatable { decisionCount, correctDecisions, bestStreak, handsPlayed, meanResponseMs: Double?, mistakes: [GradedDecision]; mistakeCount; accuracy: Double?; init(decisions:handsPlayed:); static bestStreak(_:) }`
  - Test helpers (module-internal to `BJSCoreTests`): `makeSpot(_:up:legal:)`, `makeDecision(_:correct:responseMs:choice:)`

- [ ] **Step 1: Write the tests**

Create `BJSCore/Tests/BJSCoreTests/TrainingTests/GradedDecisionTests.swift`:

```swift
import Foundation
import Testing
@testable import BJSCore

/// A decision spot with the given player ranks (all hearts) against `up`.
func makeSpot(_ ranks: [Rank], up: Rank, legal: Set<Action> = [.hit, .stand, .double, .split, .surrender]) -> DecisionSpot {
    DecisionSpot(hand: BlackjackHand(cards: ranks.map { Card(rank: $0, suit: .hearts) }),
                 dealerUpcard: up, legalActions: legal)
}

/// A graded decision at a fixed date offset (seconds) from a reference date.
func makeDecision(_ sequence: Int, correct: Bool, responseMs: Int? = 1_000,
                  choice: DecisionChoice? = nil) -> GradedDecision {
    let spot = makeSpot([.ten, .six], up: .ten)
    let made = choice ?? .action(correct ? .surrender : .stand)
    return GradedDecision(sequence: sequence, handNumber: sequence, spot: spot, choice: made,
                          correctAction: .surrender, responseMs: responseMs,
                          decidedAt: Date(timeIntervalSinceReferenceDate: 800_000_000 + Double(sequence)))
}

@Suite("Strategy session config")
struct StrategySessionConfigTests {

    @Test("Modes: only Learn hints, only Speed is timed, only Weak spots uses weights")
    func modes() {
        #expect(StrategyMode.allCases == [.learn, .test, .speed, .weakSpots])
        #expect(StrategyMode.allCases.filter(\.showsHint) == [.learn])
        #expect(StrategyMode.allCases.filter(\.isTimed) == [.speed])
        #expect(StrategyMode.allCases.filter(\.usesWeakSpotWeights) == [.weakSpots])
    }

    @Test("Lengths are 25, 50, 100 hands or Endless")
    func lengths() {
        #expect(StrategySessionLength.allCases.map(\.handLimit) == [25, 50, 100, nil])
    }

    @Test("Defaults are Learn, 25 hands, all hands; the config round-trips through JSON")
    func configCoding() throws {
        #expect(StrategySessionConfig() == StrategySessionConfig(mode: .learn, length: .hands25, filter: .all))
        let config = StrategySessionConfig(mode: .weakSpots, length: .endless, filter: .pairs)
        let data = try JSONEncoder().encode(config)
        #expect(try JSONDecoder().decode(StrategySessionConfig.self, from: data) == config)
    }
}

@Suite("GradedDecision")
struct GradedDecisionTests {

    @Test("A decision is correct only when the chosen action is the correct one")
    func correctness() {
        #expect(makeDecision(1, correct: true).isCorrect)
        #expect(!makeDecision(1, correct: false).isCorrect)
        #expect(!makeDecision(1, correct: false, choice: .timeout).isCorrect)
    }

    @Test("Timeouts are stored as the string \"timeout\"; actions by raw value")
    func storage() {
        #expect(DecisionChoice.timeout.storageValue == "timeout")
        #expect(DecisionChoice.action(.surrender).storageValue == "surrender")
        #expect(DecisionChoice.timeout.action == nil)
        #expect(DecisionChoice.action(.hit).action == .hit)
    }

    @Test("The cell follows TrainingCell(spot:)")
    func cell() {
        #expect(makeDecision(1, correct: true).cell == TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10))
    }

    @Test("WhyContext for a splittable pair carries the pair rank")
    func whyPair() {
        let context = WhyContext(spot: makeSpot([.eight, .eight], up: .six), userAction: .hit,
                                 correctAction: .split, rules: BlackjackRules())
        #expect(context.handType == .pair)
        #expect(context.pairRank == .eight)
        #expect(context.handTotal == 16)
        #expect(context.dealerUpCard == .six)
        #expect(context.userAction == .hit)
        #expect(context.correctAction == .split)
    }

    @Test("A pair that can no longer split is explained by its total (A,A → soft 12)")
    func whyUnsplittablePair() {
        let context = WhyContext(spot: makeSpot([.ace, .ace], up: .six, legal: [.hit, .stand]),
                                 userAction: .stand, correctAction: .hit, rules: BlackjackRules())
        #expect(context.handType == .soft)
        #expect(context.handTotal == 12)
        #expect(context.pairRank == nil)
    }

    @Test("A timeout's WHY context uses the correct action as the user's action")
    func whyTimeout() {
        let decision = makeDecision(1, correct: false, choice: .timeout)
        let context = decision.whyContext(rules: BlackjackRules())
        #expect(context.userAction == .surrender)
        #expect(context.correctAction == .surrender)
        #expect(!WhyExplanation.explain(context).isEmpty)
    }
}

@Suite("StrategySessionSummary")
struct StrategySessionSummaryTests {

    @Test("No decisions: no accuracy, no mean time, zero streak")
    func empty() {
        let summary = StrategySessionSummary(decisions: [], handsPlayed: 0)
        #expect(summary.accuracy == nil)
        #expect(summary.meanResponseMs == nil)
        #expect(summary.bestStreak == 0)
        #expect(summary.mistakeCount == 0)
    }

    @Test("Accuracy, mistakes and hands played")
    func counts() {
        let decisions = [makeDecision(1, correct: true), makeDecision(2, correct: false),
                         makeDecision(3, correct: true), makeDecision(4, correct: true)]
        let summary = StrategySessionSummary(decisions: decisions, handsPlayed: 3)
        #expect(summary.decisionCount == 4)
        #expect(summary.correctDecisions == 3)
        #expect(summary.accuracy == 0.75)
        #expect(summary.mistakes.map(\.sequence) == [2])
        #expect(summary.handsPlayed == 3)
    }

    @Test("Best streak is the longest correct run in decision order, whatever the input order")
    func bestStreak() {
        let pattern = [true, true, false, true, true, true, false, true]
        let decisions = pattern.enumerated().map { makeDecision($0.offset + 1, correct: $0.element) }
        #expect(StrategySessionSummary(decisions: decisions.reversed(), handsPlayed: 8).bestStreak == 3)
        #expect(StrategySessionSummary.bestStreak(decisions) == 3)
        #expect(StrategySessionSummary.bestStreak([makeDecision(1, correct: false)]) == 0)
    }

    @Test("Mean reaction time skips decisions without one; timeouts count at the full countdown")
    func meanResponse() {
        let decisions = [makeDecision(1, correct: true, responseMs: 1_000),
                         makeDecision(2, correct: true, responseMs: nil),
                         makeDecision(3, correct: false, responseMs: 3_000, choice: .timeout)]
        let summary = StrategySessionSummary(decisions: decisions, handsPlayed: 3)
        #expect(summary.meanResponseMs == 2_000)
        #expect(summary.mistakes.map(\.choice) == [.timeout])
    }
}
```

- [ ] **Step 2: Run the tests to see them fail**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
(cd BJSCore && swift build --build-tests 2>&1 | grep -m3 "error:")
```

Expected: compile errors such as `cannot find 'StrategyMode' in scope` / `cannot find type 'GradedDecision' in scope`.

- [ ] **Step 3: Implement**

Create `BJSCore/Sources/BJSCore/Training/StrategySessionConfig.swift`:

```swift
/// Strategy trainer modes (spec §5 Strategy).
public enum StrategyMode: String, CaseIterable, Sendable, Codable {
    /// The correct action carries the brass hint ring before the user chooses.
    case learn
    /// No hints.
    case test
    /// No hints; a countdown per decision. A timeout is an incorrect decision.
    case speed
    /// As Test, but hands are sampled by `WeakSpotWeights`.
    case weakSpots

    /// Learn mode shows the correct action before the user chooses.
    public var showsHint: Bool { self == .learn }

    /// Speed mode runs a countdown per decision.
    public var isTimed: Bool { self == .speed }

    /// Weak-spots mode samples hands by weight.
    public var usesWeakSpotWeights: Bool { self == .weakSpots }
}

/// How many hands a strategy session deals.
public enum StrategySessionLength: String, CaseIterable, Sendable, Codable {
    case hands25
    case hands50
    case hands100
    case endless

    /// nil for Endless.
    public var handLimit: Int? {
        switch self {
        case .hands25: return 25
        case .hands50: return 50
        case .hands100: return 100
        case .endless: return nil
        }
    }
}

/// Everything the Strategy setup screen chooses. Also stored as the hub's `lastLaunch` setup.
public struct StrategySessionConfig: Sendable, Hashable, Codable {
    public var mode: StrategyMode
    public var length: StrategySessionLength
    public var filter: HandFilter

    public init(mode: StrategyMode = .learn, length: StrategySessionLength = .hands25, filter: HandFilter = .all) {
        self.mode = mode
        self.length = length
        self.filter = filter
    }
}
```

Create `BJSCore/Sources/BJSCore/Training/GradedDecision.swift`:

```swift
import Foundation

/// What the player did at a decision: an action, or nothing before the Speed-mode countdown ran out.
public enum DecisionChoice: Sendable, Hashable {
    case action(Action)
    case timeout

    /// The string stored in `DecisionRecord.chosenAction` for a timeout.
    public static let timeoutStorageValue = "timeout"

    /// `Action` raw value, or "timeout".
    public var storageValue: String {
        switch self {
        case .action(let action): return action.rawValue
        case .timeout: return Self.timeoutStorageValue
        }
    }

    /// The chosen action, or nil for a timeout.
    public var action: Action? {
        switch self {
        case .action(let action): return action
        case .timeout: return nil
        }
    }
}

/// One strategy decision, graded against the basic-strategy table for the session's rules.
public struct GradedDecision: Sendable, Equatable, Identifiable {
    /// 1-based position of this decision in its session. Also the `id`.
    public let sequence: Int
    /// 1-based hand number within the session.
    public let handNumber: Int
    public let spot: DecisionSpot
    /// The heat-map / weak-spot cell (`TrainingCell(spot:)`).
    public let cell: TrainingCell
    public let choice: DecisionChoice
    public let correctAction: Action
    /// Reaction time in milliseconds. For a timeout, the full countdown.
    public let responseMs: Int?
    /// When the decision was made. Persisted as `DecisionRecord.decidedAt`.
    public let decidedAt: Date

    public var id: Int { sequence }

    public var isCorrect: Bool { choice == .action(correctAction) }

    public init(sequence: Int, handNumber: Int, spot: DecisionSpot, choice: DecisionChoice,
                correctAction: Action, responseMs: Int?, decidedAt: Date) {
        self.sequence = sequence
        self.handNumber = handNumber
        self.spot = spot
        self.cell = TrainingCell(spot: spot)
        self.choice = choice
        self.correctAction = correctAction
        self.responseMs = responseMs
        self.decidedAt = decidedAt
    }

    /// The WHY-sheet context for this decision. A timeout is explained as if the
    /// correct action had been chosen (the explanation only depends on the correct action).
    public func whyContext(rules: BlackjackRules) -> WhyContext {
        WhyContext(spot: spot, userAction: choice.action ?? correctAction,
                   correctAction: correctAction, rules: rules)
    }
}

extension WhyContext {
    /// Builds the explanation context for a decision spot. The hand type follows
    /// `TrainingCell(spot:)`: a pair counts as a pair only while splitting is legal;
    /// otherwise it is explained by its hard or soft total (e.g. A,A → soft 12).
    public init(id: UUID = UUID(), spot: DecisionSpot, userAction: Action, correctAction: Action,
                rules: BlackjackRules) {
        let cell = TrainingCell(spot: spot)
        self.init(id: id,
                  handTotal: spot.hand.total,
                  handType: cell.handType,
                  pairRank: cell.handType == .pair ? spot.hand.cards[0].rank : nil,
                  dealerUpCard: spot.dealerUpcard,
                  userAction: userAction,
                  correctAction: correctAction,
                  rules: rules)
    }
}
```

Create `BJSCore/Sources/BJSCore/Training/StrategySessionSummary.swift`:

```swift
/// A strategy session's summary numbers (spec §5 Summary) and the cached values
/// stored on its `Session` (spec §6).
public struct StrategySessionSummary: Sendable, Equatable {
    public let decisionCount: Int
    public let correctDecisions: Int
    /// Longest run of consecutive correct decisions in this session.
    public let bestStreak: Int
    /// Hands that reached settlement.
    public let handsPlayed: Int
    /// Mean reaction time over decisions that recorded one, or nil if none did.
    public let meanResponseMs: Double?
    /// Incorrect decisions (including timeouts), in the order they were made.
    public let mistakes: [GradedDecision]

    public init(decisions: [GradedDecision], handsPlayed: Int) {
        let ordered = decisions.sorted { $0.sequence < $1.sequence }
        decisionCount = ordered.count
        correctDecisions = ordered.filter(\.isCorrect).count
        bestStreak = Self.bestStreak(ordered)
        self.handsPlayed = handsPlayed
        let times = ordered.compactMap(\.responseMs)
        meanResponseMs = times.isEmpty ? nil : Double(times.reduce(0, +)) / Double(times.count)
        mistakes = ordered.filter { !$0.isCorrect }
    }

    public var mistakeCount: Int { mistakes.count }

    /// Fraction correct in 0...1, or nil with no decisions.
    public var accuracy: Double? {
        decisionCount == 0 ? nil : Double(correctDecisions) / Double(decisionCount)
    }

    /// Longest run of consecutive correct decisions, in the given order.
    public static func bestStreak(_ decisions: [GradedDecision]) -> Int {
        var best = 0
        var run = 0
        for decision in decisions {
            run = decision.isCorrect ? run + 1 : 0
            best = max(best, run)
        }
        return best
    }
}
```

- [ ] **Step 4: Run the tests to see them pass**

```bash
(cd BJSCore && swift build 2>&1 | tail -1 && swift test 2>&1 | tail -1)
grep -rE "import (SwiftUI|SwiftData|UIKit)" BJSCore/Sources || echo "no UI imports"
```

Expected: `Build complete!`, then `Test run with 208 tests in 29 suites passed …` (195 + 13), then `no UI imports`.

- [ ] **Step 5: Commit**

```bash
git add BJSCore/Sources/BJSCore/Training/StrategySessionConfig.swift BJSCore/Sources/BJSCore/Training/GradedDecision.swift \
        BJSCore/Sources/BJSCore/Training/StrategySessionSummary.swift BJSCore/Tests/BJSCoreTests/TrainingTests/GradedDecisionTests.swift
git commit -m "feat(core): strategy session config, graded decisions and session summary

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller. (No CI run of its own: covered by the run after Task 4.)

---

### Task 2: `StrategySession` state machine (BJSCore)

**Files:**
- Create: `BJSCore/Sources/BJSCore/Training/StrategySession.swift`
- Test: `BJSCore/Tests/BJSCoreTests/TrainingTests/StrategySessionTests.swift`

**Interfaces:**
- Consumes: Task 1; `HandGenerator.sampleCell(filter:weights:using:)`, `HandGenerator.stackedShoe(for:deckCount:using:)`, `RoundEngine(rules:shoe:)`, `RoundEngine.apply(_:shoe:)`, `.phase`, `.currentSpot`, `StrategyTable.action(for: DecisionSpot)`, `StrategyEngine().strategy(for:)`; the test helper `stackedShoe(_:)` from `RoundEngineTests.swift`
- Produces:
  - `enum StrategySessionError: Error, Equatable, Sendable { wrongPhase, illegalAction(Action) }`
  - `struct StrategySession: Sendable` with
    - `enum Phase { decision, feedback, outcome, finished }`, `enum HandSource { generated, scripted([Shoe]) }`
    - `init<G: RandomNumberGenerator>(rules:config:table:weights: = nil, source: = .generated, using: inout G) throws`
    - read-only: `rules`, `config`, `weights` (non-nil only in Weak spots), `phase`, `round: RoundEngine`, `handNumber`, `handsCompleted`, `decisions`, `currentSpot`, `correctAction`, `hint`, `lastDecision`, `isLastHand`, `summary`
    - `@discardableResult mutating func choose(_ choice: DecisionChoice, responseMs: Int?, at date: Date) throws -> GradedDecision`
    - `mutating func continueAfterFeedback() throws`
    - `mutating func nextHand<G: RandomNumberGenerator>(using: inout G) throws`
    - `mutating func finish()`

The engine hands every decision to the feedback phase before it touches the round. That makes "STAND always produces feedback before the next hand" a property of BJSCore, pinned here and again in the app (Task 7).

- [ ] **Step 1: Write the tests**

Create `BJSCore/Tests/BJSCoreTests/TrainingTests/StrategySessionTests.swift`:

```swift
import Foundation
import Testing
@testable import BJSCore

@Suite("StrategySession")
struct StrategySessionTests {

    private static let rules = BlackjackRules()
    private static let table = StrategyEngine().strategy(for: BlackjackRules())
    private static let date = Date(timeIntervalSinceReferenceDate: 800_000_000)

    /// Deal order: P1, UP, P2, HOLE, then draws.
    private static let hard16vs7 = stackedShoe([.ten, .seven, .six, .ten, .five, .nine, .nine])

    private func session(_ config: StrategySessionConfig = StrategySessionConfig(mode: .test),
                         shoes: [Shoe]? = nil, weights: [TrainingCell: Double]? = nil,
                         seed: UInt64 = 1) throws -> (StrategySession, SeededRandomNumberGenerator) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let source: StrategySession.HandSource = shoes.map { .scripted($0) } ?? .generated
        let session = try StrategySession(rules: Self.rules, config: config, table: Self.table,
                                          weights: weights, source: source, using: &rng)
        return (session, rng)
    }

    @Test("A new session deals hand 1 and waits for a decision")
    func starts() throws {
        let (session, _) = try session(shoes: [Self.hard16vs7])
        #expect(session.phase == .decision)
        #expect(session.handNumber == 1)
        #expect(session.handsCompleted == 0)
        #expect(session.currentSpot?.hand.total == 16)
        #expect(session.currentSpot?.dealerUpcard == .seven)
        #expect(session.correctAction == .hit)
    }

    @Test("STAND shows feedback before the outcome, and the next hand only comes after it")
    func standFeedbackBeforeOutcome() throws {
        var (session, rng) = try session(shoes: [Self.hard16vs7])
        let decision = try session.choose(.action(.stand), responseMs: 900, at: Self.date)
        #expect(session.phase == .feedback)
        #expect(session.lastDecision == decision)
        #expect(!decision.isCorrect)
        #expect(decision.correctAction == .hit)
        #expect(session.round.phase == .playerTurn)       // not applied yet: outcome still hidden
        #expect(session.handsCompleted == 0)
        #expect(session.currentSpot == nil)

        try session.continueAfterFeedback()
        #expect(session.phase == .outcome)
        #expect(session.round.phase == .settled)
        #expect(session.round.hands[0].outcome == .loss)  // 16 vs dealer 17 (7 + 10)
        #expect(session.handsCompleted == 1)
        #expect(session.handNumber == 1)

        try session.nextHand(using: &rng)
        #expect(session.phase == .decision)
        #expect(session.handNumber == 2)
    }

    @Test("Regression: every STAND on generated hands is followed by feedback, then the outcome, then the next hand",
          arguments: [1, 2, 3, 4, 5] as [UInt64])
    func standAlwaysGivesFeedback(seed: UInt64) throws {
        var (session, rng) = try session(StrategySessionConfig(mode: .test, length: .hands50), seed: seed)
        for hand in 1...50 {
            #expect(session.phase == .decision)
            #expect(session.handNumber == hand)
            try session.choose(.action(.stand), responseMs: nil, at: Self.date)
            #expect(session.phase == .feedback)
            #expect(session.lastDecision?.handNumber == hand)
            try session.continueAfterFeedback()
            #expect(session.phase == .outcome)
            try session.nextHand(using: &rng)
        }
        #expect(session.phase == .finished)
        #expect(session.decisions.count == 50)
        #expect(session.handsCompleted == 50)
    }

    @Test("HIT that does not end the hand returns to a decision on the same hand")
    func hitContinues() throws {
        // 5,6 = 11 vs 10; the hit draws a 2 → hard 13.
        var (session, _) = try session(shoes: [stackedShoe([.five, .ten, .six, .seven, .two, .nine])])
        try session.choose(.action(.hit), responseMs: 500, at: Self.date)
        try session.continueAfterFeedback()
        #expect(session.phase == .decision)
        #expect(session.handNumber == 1)
        #expect(session.currentSpot?.hand.total == 13)
        #expect(session.currentSpot?.legalActions == [.hit, .stand])
    }

    @Test("Splits: each split hand's decisions are graded on the same hand number")
    func splitHands() throws {
        // 8,8 vs 6 | split draws 3 then 10 | double on 11 draws 9 | dealer 6+10 draws 10 (bust).
        var (session, _) = try session(shoes: [stackedShoe([.eight, .six, .eight, .ten, .three, .ten, .nine, .ten])])
        #expect(session.correctAction == .split)
        try session.choose(.action(.split), responseMs: 400, at: Self.date)
        try session.continueAfterFeedback()
        #expect(session.phase == .decision)
        #expect(session.round.hands.count == 2)
        #expect(session.currentSpot?.hand.total == 11)
        #expect(session.correctAction == .double)

        try session.choose(.action(.double), responseMs: 400, at: Self.date)
        try session.continueAfterFeedback()
        #expect(session.phase == .decision)
        #expect(session.currentSpot?.hand.total == 18)

        try session.choose(.action(.stand), responseMs: 400, at: Self.date)
        try session.continueAfterFeedback()
        #expect(session.phase == .outcome)
        #expect(session.decisions.map(\.handNumber) == [1, 1, 1])
        #expect(session.decisions.map(\.isCorrect) == [true, true, true])
        #expect(session.decisions.map(\.cell.handType) == [.pair, .hard, .hard])
        #expect(session.round.totalNet == 3)
    }

    @Test("A timeout is graded incorrect, then the correct action is played")
    func timeout() throws {
        var (session, _) = try session(StrategySessionConfig(mode: .speed), shoes: [Self.hard16vs7])
        let decision = try session.choose(.timeout, responseMs: 3_000, at: Self.date)
        #expect(!decision.isCorrect)
        #expect(decision.choice.storageValue == "timeout")
        #expect(decision.responseMs == 3_000)
        try session.continueAfterFeedback()
        // The hit (correct play) draws the 5: 21, which finishes the hand; dealer stands on 17.
        #expect(session.round.hands[0].hand.cards.count == 3)
        #expect(session.round.hands[0].hand.total == 21)
        #expect(session.phase == .outcome)
        #expect(session.round.hands[0].outcome == .win)
    }

    @Test("Illegal actions are rejected and nothing is graded")
    func illegal() throws {
        var (session, _) = try session(shoes: [Self.hard16vs7])     // no surrender in default rules
        #expect(throws: StrategySessionError.illegalAction(.surrender)) {
            try session.choose(.action(.surrender), responseMs: nil, at: Self.date)
        }
        #expect(session.phase == .decision)
        #expect(session.decisions.isEmpty)
    }

    @Test("Calls in the wrong phase throw and change nothing (e.g. a double tap)")
    func wrongPhase() throws {
        var (session, rng) = try session(shoes: [Self.hard16vs7])
        #expect(throws: StrategySessionError.wrongPhase) { try session.continueAfterFeedback() }
        #expect(throws: StrategySessionError.wrongPhase) { try session.nextHand(using: &rng) }
        try session.choose(.action(.stand), responseMs: nil, at: Self.date)
        #expect(throws: StrategySessionError.wrongPhase) {
            try session.choose(.action(.stand), responseMs: nil, at: Self.date)
        }
        #expect(session.decisions.count == 1)
        #expect(session.phase == .feedback)
    }

    @Test("Learn mode hints the correct action; the other modes never hint")
    func hints() throws {
        #expect(try session(StrategySessionConfig(mode: .learn), shoes: [Self.hard16vs7]).0.hint == .hit)
        for mode in [StrategyMode.test, .speed, .weakSpots] {
            #expect(try session(StrategySessionConfig(mode: mode), shoes: [Self.hard16vs7]).0.hint == nil)
        }
    }

    @Test("A 25-hand session finishes after the 25th outcome")
    func handLimit() throws {
        var (session, rng) = try session(StrategySessionConfig(mode: .test, length: .hands25))
        while session.phase != .finished {
            switch session.phase {
            case .decision: try session.choose(.action(.stand), responseMs: nil, at: Self.date)
            case .feedback: try session.continueAfterFeedback()
            case .outcome: try session.nextHand(using: &rng)
            case .finished: break
            }
        }
        #expect(session.handNumber == 25)
        #expect(session.isLastHand)
        #expect(session.summary.handsPlayed == 25)
        #expect(session.summary.decisionCount == 25)
    }

    @Test("Endless never runs out of hands")
    func endless() throws {
        var (session, rng) = try session(StrategySessionConfig(mode: .test, length: .endless))
        for _ in 1...120 {
            try session.choose(.action(.stand), responseMs: nil, at: Self.date)
            try session.continueAfterFeedback()
            try session.nextHand(using: &rng)
        }
        #expect(session.phase == .decision)
        #expect(session.handNumber == 121)
        #expect(!session.isLastHand)
    }

    @Test("finish() keeps graded decisions; the unfinished hand is not counted as played")
    func finishEarly() throws {
        var (session, _) = try session(shoes: [Self.hard16vs7])
        try session.choose(.action(.hit), responseMs: 700, at: Self.date)
        session.finish()
        #expect(session.phase == .finished)
        #expect(session.summary.decisionCount == 1)
        #expect(session.summary.handsPlayed == 0)
        #expect(throws: StrategySessionError.wrongPhase) { try session.continueAfterFeedback() }
    }

    @Test("The filter is respected", arguments: [HandFilter.hard, .soft, .pairs])
    func filter(_ filter: HandFilter) throws {
        var (session, rng) = try session(StrategySessionConfig(mode: .test, length: .endless, filter: filter))
        for _ in 0..<40 {
            let spot = try #require(session.currentSpot)
            #expect(filter.includes(TrainingCell(spot: spot).handType))
            try session.choose(.action(.stand), responseMs: nil, at: Self.date)
            try session.continueAfterFeedback()
            try session.nextHand(using: &rng)
        }
    }

    @Test("Weights are used only in Weak-spots mode")
    func weakSpots() throws {
        let target = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 7)
        var weights: [TrainingCell: Double] = [:]
        for cell in TrainingCell.all { weights[cell] = 0.05 }
        weights[target] = 1_000

        #expect(try session(StrategySessionConfig(mode: .test), weights: weights).0.weights == nil)

        var hits = 0
        for seed in 1...20 as ClosedRange<UInt64> {
            let (session, _) = try session(StrategySessionConfig(mode: .weakSpots), weights: weights, seed: seed)
            #expect(session.weights != nil)
            if session.currentSpot.map(TrainingCell.init(spot:)) == target { hits += 1 }
        }
        #expect(hits >= 15)          // ≈ 98% of the weight sits on the target cell
    }

    @Test("The same seed deals the same hands")
    func deterministic() throws {
        func cells(seed: UInt64) throws -> [TrainingCell] {
            var (session, rng) = try session(StrategySessionConfig(mode: .test, length: .endless), seed: seed)
            var result: [TrainingCell] = []
            for _ in 0..<10 {
                result.append(TrainingCell(spot: try #require(session.currentSpot)))
                try session.choose(.action(.stand), responseMs: nil, at: Self.date)
                try session.continueAfterFeedback()
                try session.nextHand(using: &rng)
            }
            return result
        }
        #expect(try cells(seed: 42) == cells(seed: 42))
        #expect(try cells(seed: 42) != cells(seed: 43))
    }
}
```

Note on the fixtures: the tests use hard 16 vs **7** (basic strategy hits, clear-cut). They avoid 16 vs 10, where the engine currently says stand (Decision 1).

- [ ] **Step 2: Run the tests to see them fail**

```bash
(cd BJSCore && swift build --build-tests 2>&1 | grep -m3 "error:")
```

Expected: `cannot find type 'StrategySession' in scope` (and similar).

- [ ] **Step 3: Implement**

Create `BJSCore/Sources/BJSCore/Training/StrategySession.swift`:

```swift
import Foundation

public enum StrategySessionError: Error, Equatable, Sendable {
    /// The call does not fit the session's current phase (e.g. a second tap on STAND).
    case wrongPhase
    /// The action is not legal at the current decision.
    case illegalAction(Action)
}

/// One Strategy-trainer session as a pure value-type state machine (spec §5 Strategy).
///
/// Every hand is dealt from a fresh stacked shoe (`HandGenerator`, honouring the filter and,
/// in Weak-spots mode, the weights) and played through `RoundEngine`, including splits.
/// Each decision is graded against the `StrategyTable` for the session's rules:
///
///     decision ──choose──▶ feedback ──continueAfterFeedback──▶ decision (same hand)
///                                                          └─▶ outcome ──nextHand──▶ decision (next hand)
///                                                                               └─▶ finished (hand limit)
///     any phase ──finish──▶ finished
///
/// The graded action is applied to the round only when the feedback is dismissed, so the
/// FeedbackCard always appears before the hand's outcome is revealed. After a timeout the
/// correct action is played, so the hand continues along the right line.
public struct StrategySession: Sendable {

    public enum Phase: Sendable, Equatable {
        /// Waiting for the player's action at `currentSpot`.
        case decision
        /// A decision has been graded (`lastDecision`); its action is not yet applied.
        case feedback
        /// The hand is settled: the dealer's hand and the outcomes are visible.
        case outcome
        /// The session is over.
        case finished
    }

    /// Where hands come from.
    public enum HandSource: Sendable {
        /// `HandGenerator`: a sampled cell, stacked into a fresh shoe of the rules' deck count.
        case generated
        /// These shoes in order, cycling. For tests (spec §7: "fake shoe"). Must not be empty.
        case scripted([Shoe])
    }

    public let rules: BlackjackRules
    public let config: StrategySessionConfig
    /// The sampling weights in use: non-nil only in Weak-spots mode with enough history.
    public let weights: [TrainingCell: Double]?
    public private(set) var phase: Phase
    public private(set) var round: RoundEngine
    /// 1-based number of the hand on the table.
    public private(set) var handNumber: Int
    /// Hands that reached settlement.
    public private(set) var handsCompleted: Int
    public private(set) var decisions: [GradedDecision] = []

    private let table: StrategyTable
    private let source: HandSource
    private var shoe: Shoe
    private var scriptIndex: Int
    /// The action `continueAfterFeedback()` applies.
    private var pendingAction: Action?

    public init<G: RandomNumberGenerator>(rules: BlackjackRules, config: StrategySessionConfig,
                                          table: StrategyTable, weights: [TrainingCell: Double]? = nil,
                                          source: HandSource = .generated, using rng: inout G) throws {
        self.rules = rules
        self.config = config
        self.table = table
        self.weights = config.mode.usesWeakSpotWeights ? weights : nil
        self.source = source
        var shoe = Self.makeShoe(source: source, scriptIndex: 0, rules: rules, config: config,
                                 weights: self.weights, using: &rng)
        self.round = try RoundEngine(rules: rules, shoe: &shoe)
        self.shoe = shoe
        self.scriptIndex = 1
        self.handNumber = 1
        let settled = round.phase == .settled
        self.handsCompleted = settled ? 1 : 0
        self.phase = settled ? .outcome : .decision
    }

    // MARK: - Queries

    /// The decision on the table, only in the `.decision` phase.
    public var currentSpot: DecisionSpot? {
        phase == .decision ? round.currentSpot : nil
    }

    /// Basic strategy's action at `currentSpot`.
    public var correctAction: Action? {
        currentSpot.map { table.action(for: $0) }
    }

    /// Learn mode's brass-ring action; nil in every other mode.
    public var hint: Action? {
        config.mode.showsHint ? correctAction : nil
    }

    /// The decision most recently graded (the FeedbackCard's subject in `.feedback`).
    public var lastDecision: GradedDecision? { decisions.last }

    /// True when the hand on the table is the last one the length allows.
    public var isLastHand: Bool {
        guard let limit = config.length.handLimit else { return false }
        return handNumber >= limit
    }

    public var summary: StrategySessionSummary {
        StrategySessionSummary(decisions: decisions, handsPlayed: handsCompleted)
    }

    // MARK: - Transitions

    /// Grades the player's choice at `currentSpot`. The session moves to `.feedback`.
    @discardableResult
    public mutating func choose(_ choice: DecisionChoice, responseMs: Int?, at date: Date) throws -> GradedDecision {
        guard phase == .decision, let spot = round.currentSpot else { throw StrategySessionError.wrongPhase }
        if let action = choice.action, !spot.legalActions.contains(action) {
            throw StrategySessionError.illegalAction(action)
        }
        let correct = table.action(for: spot)
        let decision = GradedDecision(sequence: decisions.count + 1, handNumber: handNumber, spot: spot,
                                      choice: choice, correctAction: correct, responseMs: responseMs,
                                      decidedAt: date)
        decisions.append(decision)
        pendingAction = choice.action ?? correct
        phase = .feedback
        return decision
    }

    /// NEXT on the FeedbackCard: plays the graded action (the correct one after a timeout).
    /// Moves to the next decision of this hand, or to `.outcome` when the hand settles.
    public mutating func continueAfterFeedback() throws {
        guard phase == .feedback, let action = pendingAction else { throw StrategySessionError.wrongPhase }
        pendingAction = nil
        try round.apply(action, shoe: &shoe)
        if round.phase == .settled {
            handsCompleted += 1
            phase = .outcome
        } else {
            phase = .decision
        }
    }

    /// Deals the next hand from a fresh shoe, or finishes the session after the last hand.
    public mutating func nextHand<G: RandomNumberGenerator>(using rng: inout G) throws {
        guard phase == .outcome else { throw StrategySessionError.wrongPhase }
        if isLastHand {
            phase = .finished
            return
        }
        var shoe = Self.makeShoe(source: source, scriptIndex: scriptIndex, rules: rules, config: config,
                                 weights: weights, using: &rng)
        round = try RoundEngine(rules: rules, shoe: &shoe)
        self.shoe = shoe
        scriptIndex += 1
        handNumber += 1
        pendingAction = nil
        if round.phase == .settled {
            handsCompleted += 1
            phase = .outcome
        } else {
            phase = .decision
        }
    }

    /// Ends the session now (Endless "End", or Save partial). Graded decisions are kept;
    /// an unfinished hand does not count as played.
    public mutating func finish() {
        pendingAction = nil
        phase = .finished
    }

    // MARK: - Dealing

    private static func makeShoe<G: RandomNumberGenerator>(
        source: HandSource, scriptIndex: Int, rules: BlackjackRules, config: StrategySessionConfig,
        weights: [TrainingCell: Double]?, using rng: inout G
    ) -> Shoe {
        switch source {
        case .generated:
            let cell = HandGenerator.sampleCell(filter: config.filter, weights: weights, using: &rng)
            return HandGenerator.stackedShoe(for: cell, deckCount: rules.deckCount.rawValue, using: &rng)
        case .scripted(let shoes):
            precondition(!shoes.isEmpty, "StrategySession.HandSource.scripted needs at least one shoe")
            return shoes[scriptIndex % shoes.count]
        }
    }
}
```

- [ ] **Step 4: Run the tests to see them pass**

```bash
(cd BJSCore && swift build 2>&1 | tail -1 && swift test 2>&1 | tail -1)
```

Expected: `Build complete!`, then `Test run with 223 tests in 30 suites passed …` (208 + 15).

- [ ] **Step 5: Commit**

```bash
git add BJSCore/Sources/BJSCore/Training/StrategySession.swift BJSCore/Tests/BJSCoreTests/TrainingTests/StrategySessionTests.swift
git commit -m "feat(core): StrategySession state machine for the trainer

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller.

---

### Task 3: Decision feedback wording and spot titles (BJSCore)

**Files:**
- Create: `BJSCore/Sources/BJSCore/Explain/DecisionFeedback.swift`
- Test: `BJSCore/Tests/BJSCoreTests/ExplainTests/DecisionFeedbackTests.swift`

**Interfaces:**
- Consumes: Task 1 (`GradedDecision`, `DecisionChoice`, `makeSpot` test helper), `TrainingCell`, `WhyContext`
- Produces: `enum DecisionFeedback { actionName(_:), choiceName(_:), upcardName(_:), pairName(_:), handName(_:), spotTitle(_ cell:), spotTitle(_ context:), headline(for:), reason(for:) }`

- [ ] **Step 1: Write the tests**

Create `BJSCore/Tests/BJSCoreTests/ExplainTests/DecisionFeedbackTests.swift`:

```swift
import Foundation
import Testing
@testable import BJSCore

@Suite("DecisionFeedback")
struct DecisionFeedbackTests {

    private func decision(_ ranks: [Rank], up: Rank, choice: DecisionChoice, correct: Action,
                          legal: Set<Action> = [.hit, .stand, .double, .split]) -> GradedDecision {
        GradedDecision(sequence: 1, handNumber: 1, spot: makeSpot(ranks, up: up, legal: legal), choice: choice,
                       correctAction: correct, responseMs: nil, decidedAt: Date(timeIntervalSinceReferenceDate: 0))
    }

    @Test("Hand, upcard and spot names")
    func names() {
        #expect(DecisionFeedback.handName(TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 7)) == "Hard 16")
        #expect(DecisionFeedback.handName(TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 7)) == "Soft 18")
        #expect(DecisionFeedback.handName(TrainingCell(handType: .pair, playerValue: 8, dealerUpcard: 7)) == "Pair of 8s")
        #expect(DecisionFeedback.handName(TrainingCell(handType: .pair, playerValue: 11, dealerUpcard: 7)) == "Pair of Aces")
        #expect(DecisionFeedback.spotTitle(TrainingCell(handType: .pair, playerValue: 10, dealerUpcard: 11)) == "Pair of 10s vs Ace")
        #expect(DecisionFeedback.actionName(.surrender) == "Surrender")
        #expect(DecisionFeedback.choiceName(.timeout) == "Timeout")
        #expect(DecisionFeedback.choiceName(.action(.double)) == "Double")
    }

    @Test("Correct decision")
    func correct() {
        let d = decision([.ten, .six], up: .seven, choice: .action(.hit), correct: .hit)
        #expect(DecisionFeedback.headline(for: d) == "Correct: Hit")
        #expect(DecisionFeedback.reason(for: d) == "Basic strategy hits hard 16 against a 7.")
    }

    @Test("Incorrect decision names the choice and the play")
    func incorrect() {
        let d = decision([.eight, .eight], up: .ace, choice: .action(.hit), correct: .split)
        #expect(DecisionFeedback.headline(for: d) == "The play is Split")
        #expect(DecisionFeedback.reason(for: d) == "You chose Hit. Basic strategy splits a pair of 8s against an Ace.")
    }

    @Test("Timeout")
    func timeout() {
        let d = decision([.ace, .seven], up: .eight, choice: .timeout, correct: .stand)
        #expect(DecisionFeedback.headline(for: d) == "Time's up: Stand")
        #expect(DecisionFeedback.reason(for: d) == "No action in time. Basic strategy stands on soft 18 against an 8.")
    }

    @Test("WHY title matches the decision's spot title")
    func whyTitle() {
        let cases: [([Rank], Rank, Set<Action>, String)] = [
            ([.king, .king], .ace, [.hit, .stand, .split], "Pair of 10s vs Ace"),
            ([.ace, .ace], .six, [.hit, .stand], "Soft 12 vs 6"),
            ([.ten, .two, .four], .ten, [.hit, .stand], "Hard 16 vs 10"),
        ]
        for (ranks, up, legal, expected) in cases {
            let d = decision(ranks, up: up, choice: .action(.stand), correct: .stand, legal: legal)
            #expect(DecisionFeedback.spotTitle(d.whyContext(rules: BlackjackRules())) == expected)
            #expect(DecisionFeedback.spotTitle(d.cell) == expected)
        }
    }
}
```

- [ ] **Step 2: Run the tests to see them fail**

```bash
(cd BJSCore && swift build --build-tests 2>&1 | grep -m3 "error:")
```

Expected: `cannot find 'DecisionFeedback' in scope`.

- [ ] **Step 3: Implement**

Create `BJSCore/Sources/BJSCore/Explain/DecisionFeedback.swift`:

```swift
/// The FeedbackCard's headline and one-line reason, and the short names the trainer,
/// the WHY sheet and the summary's mistakes list use for a decision.
///
/// Examples (hard 16 vs 7, basic strategy hits):
/// - correct:   "Correct: Hit" / "Basic strategy hits hard 16 against a 7."
/// - incorrect: "The play is Hit" / "You chose Stand. Basic strategy hits hard 16 against a 7."
/// - timeout:   "Time's up: Hit" / "No action in time. Basic strategy hits hard 16 against a 7."
public enum DecisionFeedback {

    /// "Hit", "Stand", "Double", "Split", "Surrender".
    public static func actionName(_ action: Action) -> String {
        action.rawValue.capitalized
    }

    /// "Stand", or "Timeout".
    public static func choiceName(_ choice: DecisionChoice) -> String {
        choice.action.map(actionName) ?? "Timeout"
    }

    /// Dealer upcard in `TrainingCell` form (2...11): "2" … "10", "Ace".
    public static func upcardName(_ value: Int) -> String {
        value == 11 ? "Ace" : String(value)
    }

    /// Pair rank in `TrainingCell` form (2...11): "2s" … "10s", "Aces".
    public static func pairName(_ value: Int) -> String {
        value == 11 ? "Aces" : "\(value)s"
    }

    /// "Hard 16", "Soft 18", "Pair of 8s", "Pair of Aces".
    public static func handName(_ cell: TrainingCell) -> String {
        switch cell.handType {
        case .hard: return "Hard \(cell.playerValue)"
        case .soft: return "Soft \(cell.playerValue)"
        case .pair: return "Pair of \(pairName(cell.playerValue))"
        }
    }

    /// "Hard 16 vs 7", "Pair of Aces vs Ace".
    public static func spotTitle(_ cell: TrainingCell) -> String {
        "\(handName(cell)) vs \(upcardName(cell.dealerUpcard))"
    }

    /// The WHY sheet's title, from its context: "Hard 16 vs 7".
    public static func spotTitle(_ context: WhyContext) -> String {
        let upcard = context.dealerUpCard == .ace ? 11 : context.dealerUpCard.blackjackValue
        let value: Int
        if context.handType == .pair, let rank = context.pairRank {
            value = rank == .ace ? 11 : rank.blackjackValue
        } else {
            value = context.handTotal
        }
        return spotTitle(TrainingCell(handType: context.handType, playerValue: value, dealerUpcard: upcard))
    }

    public static func headline(for decision: GradedDecision) -> String {
        let correct = actionName(decision.correctAction)
        switch decision.choice {
        case .timeout: return "Time's up: \(correct)"
        case .action: return decision.isCorrect ? "Correct: \(correct)" : "The play is \(correct)"
        }
    }

    public static func reason(for decision: GradedDecision) -> String {
        let rule = "Basic strategy \(verb(decision.correctAction)) \(handPhrase(decision.cell)) against \(article(decision.cell.dealerUpcard)) \(upcardName(decision.cell.dealerUpcard))."
        switch decision.choice {
        case .timeout: return "No action in time. \(rule)"
        case .action(let chosen):
            return decision.isCorrect ? rule : "You chose \(actionName(chosen)). \(rule)"
        }
    }

    // MARK: - Helpers

    /// "hits", "stands on", "doubles", "splits", "surrenders".
    private static func verb(_ action: Action) -> String {
        switch action {
        case .hit: return "hits"
        case .stand: return "stands on"
        case .double: return "doubles"
        case .split: return "splits"
        case .surrender: return "surrenders"
        }
    }

    /// "hard 16", "soft 18", "a pair of 8s".
    private static func handPhrase(_ cell: TrainingCell) -> String {
        switch cell.handType {
        case .hard: return "hard \(cell.playerValue)"
        case .soft: return "soft \(cell.playerValue)"
        case .pair: return "a pair of \(pairName(cell.playerValue))"
        }
    }

    /// "an" before 8 and Ace, "a" otherwise.
    private static func article(_ upcard: Int) -> String {
        upcard == 8 || upcard == 11 ? "an" : "a"
    }
}
```

- [ ] **Step 4: Run the tests to see them pass**

```bash
(cd BJSCore && swift build 2>&1 | tail -1 && swift test 2>&1 | tail -1)
```

Expected: `Build complete!`, then `Test run with 228 tests in 31 suites passed …` (223 + 5).

- [ ] **Step 5: Commit**

```bash
git add BJSCore/Sources/BJSCore/Explain/DecisionFeedback.swift BJSCore/Tests/BJSCoreTests/ExplainTests/DecisionFeedbackTests.swift
git commit -m "feat(core): decision feedback wording and spot titles

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller.

---

### Task 4: Linux harness for app logic

**Files:**
- Create: `scripts/dev/linux_app_check.sh` (executable)

**Interfaces:**
- Produces: `scripts/dev/linux_app_check.sh <repo-relative files…>`. Files under `BJS/` form a package target named `BJS`, and files under `BJSTests/` form its test target. It prints build errors/warnings and the `swift test` summary, and exits non-zero on failure. `BJS_APP_CHECK_DIR` overrides the work directory (default `/tmp/bjs-app-check`).

Why: the app target builds only in CI (about 20 minutes per run). Most of Step 3's app logic imports only Foundation, Observation and BJSCore: the ViewModel, `StrategyText`, `LastLaunch`, the stores and the saver protocol. The Linux toolchain has Observation and Swift Testing, so those files and their `BJSTests` suites can run here first. `AppLog` (os.Logger) is the only Apple-only dependency, and the script replaces it with a shim that has the same call shape.

- [ ] **Step 1: Create the script**

Create `scripts/dev/linux_app_check.sh`:

```bash
#!/usr/bin/env bash
# Builds and tests Linux-safe app files in a throwaway Swift package, so app logic
# (ViewModels, stores, text helpers) is checked on the Linux dev container before CI.
#
# Usage (from the repo root):
#   scripts/dev/linux_app_check.sh BJS/Shared/LastLaunch.swift ... BJSTests/LastLaunchStoreTests.swift ...
#
# Files under BJS/ become the package's `BJS` target (so `@testable import BJS` works);
# files under BJSTests/ become its `BJSTests` target. Only pass files that import nothing
# beyond Foundation, Observation, BJSCore and Testing. `AppLog` is replaced by a shim
# (os.Logger does not exist on Linux), so never pass BJS/Shared/AppLog.swift.
# Output: the `swift test` summary; exit status is non-zero on any failure.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="${BJS_APP_CHECK_DIR:-/tmp/bjs-app-check}"
rm -rf "$WORK/Sources" "$WORK/Tests"
mkdir -p "$WORK/Sources/BJS" "$WORK/Tests/BJSTests"

cat > "$WORK/Package.swift" <<SWIFT
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BJSAppCheck",
    platforms: [.macOS(.v15)],
    dependencies: [.package(path: "$REPO/BJSCore")],
    targets: [
        .target(name: "BJS", dependencies: [.product(name: "BJSCore", package: "BJSCore")]),
        .testTarget(name: "BJSTests", dependencies: ["BJS"]),
    ]
)
SWIFT

# Linux stand-in for BJS/Shared/AppLog.swift: same call shape, messages go to stderr.
cat > "$WORK/Sources/BJS/AppLogShim.swift" <<'SWIFT'
import Foundation

enum LogPrivacy { case `public`, `private` }

struct LogMessage: ExpressibleByStringInterpolation {
    struct Interpolation: StringInterpolationProtocol {
        var text = ""
        init(literalCapacity: Int, interpolationCount: Int) {}
        mutating func appendLiteral(_ literal: String) { text += literal }
        mutating func appendInterpolation(_ value: String, privacy: LogPrivacy = .private) { text += value }
    }
    let text: String
    init(stringLiteral value: String) { text = value }
    init(stringInterpolation: Interpolation) { text = stringInterpolation.text }
}

struct ShimLogger: Sendable {
    let category: String
    func error(_ message: LogMessage) {
        FileHandle.standardError.write(Data("[\(category)] \(message.text)\n".utf8))
    }
}

enum AppLog {
    static let persistence = ShimLogger(category: "persistence")
    static let settings = ShimLogger(category: "settings")
}
SWIFT

for file in "$@"; do
    case "$file" in
        BJS/Shared/AppLog.swift) echo "skip $file (replaced by the shim)" ;;
        BJS/*) cp "$REPO/$file" "$WORK/Sources/BJS/" ;;
        BJSTests/*) cp "$REPO/$file" "$WORK/Tests/BJSTests/" ;;
        *) echo "unexpected path: $file" >&2; exit 2 ;;
    esac
done

cd "$WORK"
swift build --build-tests 2>&1 | grep -E "error:|warning:" || true
swift test 2>&1 | grep -E "✘|error:|Test run with"
```

```bash
chmod +x scripts/dev/linux_app_check.sh
```

- [ ] **Step 2: Smoke-test it on existing files**

`ActiveRulesStore`, `Preferences`, `RulesCoding` and `RulesDisplay` import only Foundation, Observation and BJSCore (plus `AppLog`, which the shim replaces). Their existing tests should pass on Linux:

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
scripts/dev/linux_app_check.sh BJS/Shared/ActiveRulesStore.swift BJS/Shared/Preferences.swift \
  BJS/Shared/RulesCoding.swift BJS/Shared/RulesDisplay.swift \
  BJSTests/TestDefaults.swift BJSTests/ActiveRulesStoreTests.swift BJSTests/PreferencesTests.swift
```

Expected (first run builds BJSCore, ~30–60 s): no `error:` lines, then `✔ Test run with 13 tests in 3 suites passed …`. If a test fails only because Linux Foundation differs from Apple's (e.g. `UserDefaults` suite behaviour), note it in the report and drop that test file from the smoke run. Do not change app code for it.

- [ ] **Step 3: Commit**

```bash
git add scripts/dev/linux_app_check.sh
git commit -m "chore(dev): Linux harness for app logic tests

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller.

- [ ] **Step 4: CI verification (controller), covering Tasks 1–4**

Expected: green. "Engine tests (BJSCore)" reports `Test run with 228 tests … passed`, and the app is unchanged: 60 unit tests, 2 UI tests, 16 screenshots per device.

---

### Task 5: `lastLaunch`, training display names and the Strategy seed switch

**Files:**
- Create: `BJS/Shared/LastLaunch.swift`, `BJS/Shared/LastLaunchStore.swift`, `BJS/Shared/TrainingDisplay.swift`
- Modify: `BJS/App/LaunchConfiguration.swift`
- Test: `BJSTests/LastLaunchStoreTests.swift`

**Interfaces:**
- Consumes: `TrainingModule`, `StrategyMode`, `StrategySessionLength`, `HandFilter`, `StrategySessionConfig` (BJSCore); `AppLog.settings`; `TestDefaults`
- Produces:
  - `struct LastLaunch: Codable, Equatable, Sendable { module: TrainingModule; mode: String?; strategy: StrategySessionConfig?; init(module:mode:strategy:); static forStrategy(_:); static encode(_:) -> Data; static decode(_:) throws -> LastLaunch }`
  - `@MainActor @Observable final class LastLaunchStore { nonisolated static storageKey = "lastLaunch"; init(defaults:); private(set) var lastLaunch: LastLaunch?; func record(_:) }`
  - `TrainingModule.displayName`; `StrategyMode.displayName`, `.setupDescription`; `StrategySessionLength.displayName`, `.longName`; `HandFilter.displayName`, `.longName`; `enum LastLaunchText { title(_:), detail(_:) }`
  - `LaunchConfiguration.strategySeedKey = "BJS_STRATEGY_SEED"`, `LaunchConfiguration.strategySeed: UInt64?`

- [ ] **Step 1: Write the tests**

Create `BJSTests/LastLaunchStoreTests.swift`:

```swift
import BJSCore
import Foundation
import Testing
@testable import BJS

@MainActor
@Suite("LastLaunchStore")
struct LastLaunchStoreTests {

    private let config = StrategySessionConfig(mode: .speed, length: .hands50, filter: .soft)

    @Test("First launch: nothing to continue")
    func fresh() {
        #expect(LastLaunchStore(defaults: TestDefaults.make()).lastLaunch == nil)
    }

    @Test("A recorded launch persists across store instances")
    func persists() {
        let defaults = TestDefaults.make()
        LastLaunchStore(defaults: defaults).record(.forStrategy(config))
        let reloaded = LastLaunchStore(defaults: defaults).lastLaunch
        #expect(reloaded == LastLaunch(module: .strategy, mode: "speed", strategy: config))
    }

    @Test("Stored as JSON Data under 'lastLaunch' with module, mode and setup")
    func storageFormat() throws {
        let defaults = TestDefaults.make()
        LastLaunchStore(defaults: defaults).record(.forStrategy(config))
        let data = try #require(defaults.data(forKey: "lastLaunch"))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["module"] as? String == "strategy")
        #expect(json["mode"] as? String == "speed")
        #expect(json["strategy"] != nil)
        #expect(try LastLaunch.decode(data).strategy == config)
    }

    @Test("Corrupt JSON hides Continue instead of crashing")
    func corrupt() {
        let defaults = TestDefaults.make()
        defaults.set(Data("nope".utf8), forKey: "lastLaunch")
        #expect(LastLaunchStore(defaults: defaults).lastLaunch == nil)
    }
}

@Suite("Training display text")
struct TrainingDisplayTests {

    @Test("Setup picker titles")
    func pickerTitles() {
        #expect(StrategyMode.allCases.map(\.displayName) == ["Learn", "Test", "Speed", "Weak spots"])
        #expect(StrategySessionLength.allCases.map(\.displayName) == ["25", "50", "100", "Endless"])
        #expect(HandFilter.allCases.map(\.displayName) == ["All", "Hard", "Soft", "Pairs"])
        #expect(StrategyMode.allCases.allSatisfy { !$0.setupDescription.isEmpty })
    }

    @Test("Continue button text")
    func continueText() {
        let launch = LastLaunch.forStrategy(StrategySessionConfig(mode: .weakSpots, length: .endless, filter: .pairs))
        #expect(LastLaunchText.title(launch) == "Continue: Strategy · Weak spots")
        #expect(LastLaunchText.detail(launch) == "Endless · Pairs")
        let plain = LastLaunch(module: .countingRC, mode: nil, strategy: nil)
        #expect(LastLaunchText.title(plain) == "Continue: Running count")
        #expect(LastLaunchText.detail(plain) == nil)
    }
}

@Suite("LaunchConfiguration seed")
struct LaunchSeedTests {

    @Test("A Strategy seed is read only when it is a valid UInt64")
    func strategySeed() {
        #expect(LaunchConfiguration(environment: [:]).strategySeed == nil)
        #expect(LaunchConfiguration(environment: ["BJS_STRATEGY_SEED": "42"]).strategySeed == 42)
        #expect(LaunchConfiguration(environment: ["BJS_STRATEGY_SEED": "-1"]).strategySeed == nil)
    }
}
```

- [ ] **Step 2: Implement**

Create `BJS/Shared/LastLaunch.swift`:

```swift
import BJSCore
import Foundation

/// What the hub's Continue button relaunches (spec §5 Hub, §6 `lastLaunch`):
/// the module, mode and setup of the last session the user started.
///
/// Stored as JSON. Later modules add their own optional setup field (e.g. `counting`),
/// which older stored values simply lack.
struct LastLaunch: Codable, Equatable, Sendable {
    let module: TrainingModule
    /// The module's mode raw value (e.g. "learn"), or nil for modules without modes.
    let mode: String?
    /// The Strategy setup, when `module == .strategy`.
    let strategy: StrategySessionConfig?

    init(module: TrainingModule, mode: String?, strategy: StrategySessionConfig?) {
        self.module = module
        self.mode = mode
        self.strategy = strategy
    }

    static func forStrategy(_ config: StrategySessionConfig) -> LastLaunch {
        LastLaunch(module: .strategy, mode: config.mode.rawValue, strategy: config)
    }

    static func encode(_ launch: LastLaunch) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            return try encoder.encode(launch)
        } catch {
            // Only enums and strings; encoding cannot fail in practice.
            preconditionFailure("LastLaunch failed to encode: \(error)")
        }
    }

    static func decode(_ data: Data) throws -> LastLaunch {
        try JSONDecoder().decode(LastLaunch.self, from: data)
    }
}
```

Create `BJS/Shared/LastLaunchStore.swift`:

```swift
import Foundation
import Observation

/// The hub's Continue target, persisted as JSON `Data` under the `lastLaunch` key
/// (the same key and type `@AppStorage("lastLaunch") var data: Data` would use).
/// Nil until the first session starts, so Continue is hidden on first launch.
@MainActor
@Observable
final class LastLaunchStore {
    nonisolated static let storageKey = "lastLaunch"

    private let defaults: UserDefaults
    private(set) var lastLaunch: LastLaunch?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.lastLaunch = Self.load(from: defaults)
    }

    /// Called when a session starts (from setup or from Continue).
    func record(_ launch: LastLaunch) {
        lastLaunch = launch
        defaults.set(LastLaunch.encode(launch), forKey: Self.storageKey)
    }

    /// Missing → nil. Undecodable → nil, logged (Continue stays hidden until the next session).
    private static func load(from defaults: UserDefaults) -> LastLaunch? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        do {
            return try LastLaunch.decode(data)
        } catch {
            let message = String(describing: error)
            AppLog.settings.error("lastLaunch failed to decode; hiding Continue. \(message, privacy: .public)")
            return nil
        }
    }
}
```

Create `BJS/Shared/TrainingDisplay.swift`:

```swift
import BJSCore

// Display text for training modules and the Strategy setup. Presentation only; shared by
// the hub's Continue button and the Strategy feature.

extension TrainingModule {
    var displayName: String {
        switch self {
        case .strategy: return "Strategy"
        case .countingRC: return "Running count"
        case .countingTC: return "True count"
        case .shoe: return "Shoe Sim"
        }
    }
}

extension StrategyMode {
    var displayName: String {
        switch self {
        case .learn: return "Learn"
        case .test: return "Test"
        case .speed: return "Speed"
        case .weakSpots: return "Weak spots"
        }
    }

    /// One line under the setup screen's mode picker.
    var setupDescription: String {
        switch self {
        case .learn: return "The correct play is ringed in brass before you choose."
        case .test: return "No hints. Every decision is graded."
        case .speed: return "No hints, and a countdown for every decision."
        case .weakSpots: return "Deals more of the hands you miss most (after 50 decisions)."
        }
    }
}

extension StrategySessionLength {
    /// Picker title: "25", "50", "100", "Endless".
    var displayName: String {
        handLimit.map(String.init) ?? "Endless"
    }

    /// "25 hands", "Endless".
    var longName: String {
        handLimit.map { "\($0) hands" } ?? "Endless"
    }
}

extension HandFilter {
    /// Picker title: "All", "Hard", "Soft", "Pairs".
    var displayName: String {
        switch self {
        case .all: return "All"
        case .hard: return "Hard"
        case .soft: return "Soft"
        case .pairs: return "Pairs"
        }
    }

    /// "All hands", "Hard hands", "Soft hands", "Pairs".
    var longName: String {
        switch self {
        case .all: return "All hands"
        case .hard: return "Hard hands"
        case .soft: return "Soft hands"
        case .pairs: return "Pairs"
        }
    }
}

enum LastLaunchText {
    /// Continue button title, e.g. "Continue: Strategy · Learn".
    static func title(_ launch: LastLaunch) -> String {
        var parts = [launch.module.displayName]
        if let config = launch.strategy {
            parts.append(config.mode.displayName)
        }
        return "Continue: " + parts.joined(separator: " · ")
    }

    /// The line under it, e.g. "25 hands · All hands". Nil when there is no setup to show.
    static func detail(_ launch: LastLaunch) -> String? {
        guard let config = launch.strategy else { return nil }
        return "\(config.length.longName) · \(config.filter.longName)"
    }
}
```

Replace `BJS/App/LaunchConfiguration.swift` with:

```swift
import Foundation

/// Launch-time switches read from the process environment. UI tests set these through
/// `XCUIApplication.launchEnvironment`.
struct LaunchConfiguration: Equatable, Sendable {
    /// "1" → in-memory SwiftData store and a wiped, separate UserDefaults suite.
    static let uiTestingKey = "BJS_UI_TESTING"
    /// A `GalleryPage` raw value → DEBUG builds show that component-gallery page instead of the app.
    static let galleryPageKey = "BJS_GALLERY_PAGE"
    /// A decimal UInt64 → Strategy sessions deal from this seed, so UI tests see the same hands.
    static let strategySeedKey = "BJS_STRATEGY_SEED"
    static let uiTestingDefaultsSuite = "com.bjs.app.uitesting"

    let isUITesting: Bool
    let galleryPageName: String?
    /// nil (the normal case) → every session picks a random seed.
    let strategySeed: UInt64?

    init(environment: [String: String]) {
        isUITesting = environment[Self.uiTestingKey] == "1"
        galleryPageName = environment[Self.galleryPageKey]
        strategySeed = environment[Self.strategySeedKey].flatMap { UInt64($0) }
    }

    static var current: LaunchConfiguration {
        LaunchConfiguration(environment: ProcessInfo.processInfo.environment)
    }

    /// `.standard` normally; a freshly wiped suite under UI testing, so every UI test starts clean.
    func makeUserDefaults() -> UserDefaults {
        guard isUITesting, let defaults = UserDefaults(suiteName: Self.uiTestingDefaultsSuite) else {
            return .standard
        }
        defaults.removePersistentDomain(forName: Self.uiTestingDefaultsSuite)
        return defaults
    }
}
```

- [ ] **Step 3: Local pre-checks**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
(cd BJSCore && swift build 2>&1 | tail -1)
swiftc -swift-version 6 -typecheck -I BJSCore/.build/debug/Modules \
  BJS/Shared/LastLaunch.swift BJS/Shared/TrainingDisplay.swift BJS/App/LaunchConfiguration.swift
swiftc -parse BJS/Shared/LastLaunchStore.swift BJSTests/LastLaunchStoreTests.swift
scripts/dev/linux_app_check.sh BJS/Shared/LastLaunch.swift BJS/Shared/LastLaunchStore.swift \
  BJS/Shared/TrainingDisplay.swift BJS/App/LaunchConfiguration.swift \
  BJSTests/TestDefaults.swift BJSTests/LastLaunchStoreTests.swift
```

Expected: `Build complete!`, no output from the two `swiftc` runs, then `✔ Test run with 7 tests in 3 suites passed …`. The "Corrupt JSON" test also writes a `[settings] lastLaunch failed to decode…` line to stderr, which is expected.

- [ ] **Step 4: Commit**

```bash
git add BJS/Shared/LastLaunch.swift BJS/Shared/LastLaunchStore.swift BJS/Shared/TrainingDisplay.swift \
        BJS/App/LaunchConfiguration.swift BJSTests/LastLaunchStoreTests.swift
git commit -m "feat(app): lastLaunch store, training display names and a Strategy seed switch

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller.

- [ ] **Step 5: CI verification (controller)**

Expected: green; 67 unit tests (60 + 7); UI unchanged (2 tests, 16 screenshots per device).

---

### Task 6: Save Strategy sessions and read decision history

**Files:**
- Create: `BJS/Persistence/StrategySessionSaving.swift`, `BJS/Persistence/StrategySessionWriter.swift`
- Test: `BJSTests/StrategyFixtures.swift`, `BJSTests/StrategySessionWriterTests.swift`

**Interfaces:**
- Consumes: Tasks 1–2 (`GradedDecision`, `StrategySessionSummary`, `StrategySessionConfig`); `Session`, `DecisionRecord` (SchemaV1 typealiases); `RulesCoding`; `ProgressMapper.decisionSamples(_:)`; `WeakSpotWeights.historyWindow`; `AppLog.persistence`
- Produces:
  - `struct StrategySessionSnapshot: Sendable, Equatable { id, config, rules, startedAt, endedAt, summary, decisions }`
  - `@MainActor protocol StrategySessionSaving { func save(_ snapshot: StrategySessionSnapshot) throws }`
  - `@MainActor struct SwiftDataStrategySessionSaver: StrategySessionSaving { init(context: ModelContext) }`: one `Session` (module `strategy`, mode raw value, cached summary) + one `DecisionRecord` per decision with its own `decidedAt`; on a save error it rolls back, logs and rethrows
  - `enum StrategyRecordMapper { static func record(_ decision: GradedDecision) -> DecisionRecord }`
  - `enum DecisionHistory { static func recentSamples(in context: ModelContext) -> [DecisionSample] }`: newest 500, `[]` on a fetch error (logged)
  - Test support: `StrategyFixtures` (`start`, `shoe(_:)`, `hard16vs7`, `eightsVs6`, `decision(_:choice:responseMs:)`, `snapshot(_:mode:)`), `FakeClock`, `FakeSaveError`, `FakeStrategySaver`

- [ ] **Step 1: Write the test support and the tests**

Create `BJSTests/StrategyFixtures.swift`:

```swift
import BJSCore
import Foundation
@testable import BJS

/// Shared builders and fakes for the Strategy tests.
enum StrategyFixtures {
    static let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    /// A shoe dealing `ranks` in order (all spades). Deal order: P1, UP, P2, HOLE, then draws.
    static func shoe(_ ranks: [Rank]) -> Shoe {
        Shoe(orderedCards: ranks.map { Card(rank: $0, suit: .spades) })
    }

    /// Hard 16 (10, 6) vs 7, dealer 17 (7, 10); a hit draws a 5 (21). Basic strategy hits.
    static let hard16vs7: [Rank] = [.ten, .seven, .six, .ten, .five, .nine, .nine]
    /// 8, 8 vs 6 (hole 10); split draws 3 and 10; a double on 11 draws 9; the dealer draws 10 and busts.
    static let eightsVs6: [Rank] = [.eight, .six, .eight, .ten, .three, .ten, .nine, .ten]

    /// A graded hard-16-vs-7 decision (correct play: hit) made `sequence` seconds after `start`.
    static func decision(_ sequence: Int, choice: DecisionChoice, responseMs: Int? = 1_000) -> GradedDecision {
        let spot = DecisionSpot(hand: BlackjackHand(cards: [Card(rank: .ten, suit: .clubs), Card(rank: .six, suit: .hearts)]),
                                dealerUpcard: .seven, legalActions: [.hit, .stand, .double])
        return GradedDecision(sequence: sequence, handNumber: sequence, spot: spot, choice: choice,
                              correctAction: .hit, responseMs: responseMs,
                              decidedAt: start.addingTimeInterval(TimeInterval(sequence)))
    }

    static func snapshot(_ decisions: [GradedDecision], mode: StrategyMode = .test) -> StrategySessionSnapshot {
        StrategySessionSnapshot(id: UUID(), config: StrategySessionConfig(mode: mode, length: .hands25, filter: .all),
                                rules: BlackjackRules(), startedAt: start, endedAt: start.addingTimeInterval(600),
                                summary: StrategySessionSummary(decisions: decisions, handsPlayed: decisions.count),
                                decisions: decisions)
    }
}

/// A clock the tests move by hand.
@MainActor
final class FakeClock {
    var now = StrategyFixtures.start

    func advance(_ seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}

struct FakeSaveError: Error {}

/// Records saved snapshots, or throws when `fails` is set.
@MainActor
final class FakeStrategySaver: StrategySessionSaving {
    var saved: [StrategySessionSnapshot] = []
    var fails = false

    func save(_ snapshot: StrategySessionSnapshot) throws {
        if fails { throw FakeSaveError() }
        saved.append(snapshot)
    }
}
```

Create `BJSTests/StrategySessionWriterTests.swift`:

```swift
import BJSCore
import Foundation
import SwiftData
import Testing
@testable import BJS

/// Every test creates its in-memory container before creating any model object.
@MainActor
@Suite("Strategy session writer", .serialized)
struct StrategySessionWriterTests {

    private let decisions = [
        StrategyFixtures.decision(1, choice: .action(.hit), responseMs: 800),
        StrategyFixtures.decision(2, choice: .action(.stand), responseMs: 1_200),
        StrategyFixtures.decision(3, choice: .timeout, responseMs: 3_000),
        StrategyFixtures.decision(4, choice: .action(.hit), responseMs: 1_000),
    ]

    @Test("Saving writes one strategy Session with its mode, rules and cached summary")
    func session() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let snapshot = StrategyFixtures.snapshot(decisions, mode: .speed)
        try SwiftDataStrategySessionSaver(context: context).save(snapshot)

        let sessions = try context.fetch(FetchDescriptor<Session>())
        let session = try #require(sessions.first)
        #expect(sessions.count == 1)
        #expect(session.id == snapshot.id)
        #expect(session.module == "strategy")
        #expect(session.mode == "speed")
        #expect(session.startedAt == snapshot.startedAt)
        #expect(session.endedAt == snapshot.endedAt)
        #expect(try RulesCoding.decode(session.rulesJSON) == BlackjackRules())
        #expect(session.decisionCount == 4)
        #expect(session.correctDecisions == 2)
        #expect(session.countChecks == 0)
        #expect(session.bestStreak == 1)
        #expect(session.meanResponseMs == 1_500)
        #expect(session.decisions.count == 4)
    }

    @Test("Each decision keeps its own decidedAt; a timeout is stored as \"timeout\"")
    func records() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        try SwiftDataStrategySessionSaver(context: context).save(StrategyFixtures.snapshot(decisions))

        let records = try context.fetch(FetchDescriptor<DecisionRecord>(sortBy: [SortDescriptor(\.decidedAt)]))
        #expect(records.map(\.decidedAt) == decisions.map(\.decidedAt))
        #expect(records.map(\.chosenAction) == ["hit", "stand", "timeout", "hit"])
        #expect(records.map(\.isCorrect) == [true, false, false, true])
        #expect(records.allSatisfy { $0.correctAction == "hit" && $0.handType == "hard" })
        #expect(records.allSatisfy { $0.playerValue == 16 && $0.dealerUpcard == 7 })
        #expect(records.map(\.responseMs) == [800, 1_200, 3_000, 1_000])
        #expect(records.map(\.handNumber) == [1, 2, 3, 4])
    }

    @Test("Saved decisions map back to the same cells and give the hub its streak")
    func mapsBack() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        try SwiftDataStrategySessionSaver(context: context).save(StrategyFixtures.snapshot(decisions))

        let samples = DecisionHistory.recentSamples(in: context)
        #expect(samples.count == 4)
        #expect(Set(samples.map(\.cell)) == [TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 7)])
        #expect(ProgressStats.currentStreak(samples) == 1)          // newest (4) correct, then the timeout
    }

    @Test("Decision history returns only the newest 500 decisions")
    func historyWindow() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        for index in 0..<510 {
            context.insert(DecisionRecord(handNumber: index, handType: "hard", playerValue: 12, dealerUpcard: 2,
                                          chosenAction: "hit", correctAction: "stand", isCorrect: false,
                                          responseMs: nil,
                                          decidedAt: StrategyFixtures.start.addingTimeInterval(TimeInterval(index))))
        }
        try context.save()

        let samples = DecisionHistory.recentSamples(in: context)
        #expect(samples.count == 500)
        #expect(samples.map(\.date).min() == StrategyFixtures.start.addingTimeInterval(10))
    }
}
```

- [ ] **Step 2: Implement**

Create `BJS/Persistence/StrategySessionSaving.swift`:

```swift
import BJSCore
import Foundation

/// Everything persisted for one finished (or partially saved) Strategy session.
struct StrategySessionSnapshot: Sendable, Equatable {
    let id: UUID
    let config: StrategySessionConfig
    /// The rules the session ran under (its snapshot of the active rules).
    let rules: BlackjackRules
    let startedAt: Date
    let endedAt: Date
    let summary: StrategySessionSummary
    let decisions: [GradedDecision]
}

/// Saves Strategy sessions. The app uses `SwiftDataStrategySessionSaver`; ViewModel tests use a fake.
@MainActor
protocol StrategySessionSaving {
    func save(_ snapshot: StrategySessionSnapshot) throws
}
```

Create `BJS/Persistence/StrategySessionWriter.swift`:

```swift
import BJSCore
import Foundation
import SwiftData

/// Writes a Strategy session as one `Session` plus one `DecisionRecord` per graded decision
/// (spec §6). Each record keeps its own `decidedAt`.
@MainActor
struct SwiftDataStrategySessionSaver: StrategySessionSaving {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ snapshot: StrategySessionSnapshot) throws {
        let summary = snapshot.summary
        let session = Session(id: snapshot.id, module: TrainingModule.strategy.rawValue,
                              mode: snapshot.config.mode.rawValue, startedAt: snapshot.startedAt,
                              endedAt: snapshot.endedAt, rulesJSON: RulesCoding.encode(snapshot.rules),
                              decisionCount: summary.decisionCount, correctDecisions: summary.correctDecisions,
                              countChecks: 0, correctCountChecks: 0, bestStreak: summary.bestStreak,
                              meanResponseMs: summary.meanResponseMs)
        context.insert(session)
        for decision in snapshot.decisions {
            session.decisions.append(StrategyRecordMapper.record(decision))
        }
        do {
            try context.save()
        } catch {
            // Leave nothing half-saved behind; the caller shows a non-blocking alert.
            context.rollback()
            let message = String(describing: error)
            AppLog.persistence.error("Saving a strategy session failed: \(message, privacy: .public)")
            throw error
        }
    }
}

/// `GradedDecision` → `DecisionRecord`, using the `TrainingCell` conventions (ace = 11).
enum StrategyRecordMapper {
    static func record(_ decision: GradedDecision) -> DecisionRecord {
        DecisionRecord(handNumber: decision.handNumber,
                       handType: decision.cell.handType.rawValue,
                       playerValue: decision.cell.playerValue,
                       dealerUpcard: decision.cell.dealerUpcard,
                       chosenAction: decision.choice.storageValue,
                       correctAction: decision.correctAction.rawValue,
                       isCorrect: decision.isCorrect,
                       responseMs: decision.responseMs,
                       decidedAt: decision.decidedAt)
    }
}

/// Reads decision history for Weak-spots mode.
enum DecisionHistory {
    /// The newest `WeakSpotWeights.historyWindow` decisions from every module, as samples.
    /// A fetch failure is logged and treated as no history (uniform hands).
    static func recentSamples(in context: ModelContext) -> [DecisionSample] {
        var descriptor = FetchDescriptor<DecisionRecord>(sortBy: [SortDescriptor(\.decidedAt, order: .reverse)])
        descriptor.fetchLimit = WeakSpotWeights.historyWindow
        do {
            return ProgressMapper.decisionSamples(try context.fetch(descriptor))
        } catch {
            let message = String(describing: error)
            AppLog.persistence.error("Reading decision history failed: \(message, privacy: .public)")
            return []
        }
    }
}
```

- [ ] **Step 3: Local pre-checks**

`StrategySessionWriter.swift` and its tests need SwiftData (CI only). The protocol file and the fixtures are Linux-safe. Compile them in the harness alongside Task 5's tests, which proves the fixtures build:

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
swiftc -swift-version 6 -typecheck -I BJSCore/.build/debug/Modules BJS/Persistence/StrategySessionSaving.swift
swiftc -parse BJS/Persistence/StrategySessionWriter.swift BJSTests/StrategySessionWriterTests.swift BJSTests/StrategyFixtures.swift
scripts/dev/linux_app_check.sh BJS/Shared/LastLaunch.swift BJS/Shared/LastLaunchStore.swift \
  BJS/Shared/TrainingDisplay.swift BJS/App/LaunchConfiguration.swift BJS/Persistence/StrategySessionSaving.swift \
  BJSTests/TestDefaults.swift BJSTests/LastLaunchStoreTests.swift BJSTests/StrategyFixtures.swift
```

Expected: no output from `swiftc`, then `✔ Test run with 7 tests in 3 suites passed …`.

Check by eye (CI will confirm) that the writer test's expectations match the fixtures:
- 4 decisions (hit ✓, stand ✕, timeout ✕, hit ✓) → 2 correct, best streak 1, mean (800 + 1200 + 3000 + 1000) / 4 = 1500 ms;
- newest-first streak = 1.

- [ ] **Step 4: Commit**

```bash
git add BJS/Persistence/StrategySessionSaving.swift BJS/Persistence/StrategySessionWriter.swift \
        BJSTests/StrategyFixtures.swift BJSTests/StrategySessionWriterTests.swift
git commit -m "feat(app): save strategy sessions and read decision history

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller.

- [ ] **Step 5: CI verification (controller)**

Expected: green; 71 unit tests (67 + 4). If `context.rollback()` or the `SortDescriptor(\.decidedAt, order: .reverse)` initialiser fails to compile, fix forward in `fix(app)`. The fallback for the rollback is to delete the inserted `session` and call `try? context.save()`.

---

### Task 7: Strategy trainer ViewModel (with the STAND regression test)

**Files:**
- Create: `BJS/Features/Strategy/StrategyTrainerViewModel.swift`, `BJS/Features/Strategy/StrategyText.swift`
- Test: `BJSTests/StrategyTrainerViewModelTests.swift`, `BJSTests/StrategyTextTests.swift`

**Interfaces:**
- Consumes: Tasks 1–3 and 6 (`StrategySession`, `DecisionFeedback`, `StrategySessionSaving`, `StrategySessionSnapshot`, `FakeClock`, `FakeStrategySaver`, `StrategyFixtures`); `WeakSpotWeights.compute(from:)`; `StrategyEngine`
- Produces:
  - `@MainActor @Observable final class StrategyTrainerViewModel`
    - `nonisolated static strategyEngine`
    - `init(config:rules:speedTimerSeconds:history:seed:source: = .generated, saver:, now: = { Date() })`
    - read-only: `config`, `rules`, `speedTimerSeconds`, `startedAt`, `session`, `decisionToken`, `decisionStartedAt`, `isSaved`, `phase`, `isFinished`, `handNumber`, `allowedActions`, `hint`, `feedback`, `summary`, `dealerHand`, `playerHands`, `activeHandIndex`, `isDealerRevealed`, `countdownToken`
    - settable: `presentedWhy: WhyContext?`, `isConfirmingLeave`, `isShowingSaveError`
    - actions: `choose(_:)`, `timeExpired(token:)`, `next()`, `nextHand()`, `endSession()`, `requestLeave() -> Bool`, `savePartial()`, `keepPlaying()`, `discard()`, `showWhy(for:)`
  - `enum StrategyText { progress(handNumber:limit:), total(_:), dealerResult(_:), net(_:), outcome(_:), percent(_:), seconds(fromMs:), mistakeDetail(_:) }`

The ViewModel imports only Foundation, Observation and BJSCore, so the whole suite runs on Linux through the harness before CI. That includes the spec §7 regression test **"STAND always produces feedback before the next hand"**, parameterised over all four modes.

- [ ] **Step 1: Write the tests**

Create `BJSTests/StrategyTextTests.swift`:

```swift
import BJSCore
import Testing
@testable import BJS

@Suite("StrategyText")
struct StrategyTextTests {

    private func hand(_ ranks: [Rank]) -> BlackjackHand {
        BlackjackHand(cards: ranks.map { Card(rank: $0, suit: .clubs) })
    }

    @Test("Progress reads 'Hand n of N', or 'Hand n' in Endless")
    func progress() {
        #expect(StrategyText.progress(handNumber: 3, limit: 25) == "Hand 3 of 25")
        #expect(StrategyText.progress(handNumber: 7, limit: nil) == "Hand 7")
    }

    @Test("Totals: hard, soft as low/high, 21, bust; the dealer's result")
    func totals() {
        #expect(StrategyText.total(hand([.ten, .six])) == "16")
        #expect(StrategyText.total(hand([.ace, .seven])) == "8/18")
        #expect(StrategyText.total(hand([.ace, .ten])) == "21")
        #expect(StrategyText.total(hand([.ten, .six, .nine])) == "Bust")
        #expect(StrategyText.dealerResult(hand([.ten, .nine])) == "Dealer has 19")
        #expect(StrategyText.dealerResult(hand([.ten, .six, .nine])) == "Dealer busts")
    }

    @Test("Net results use a true minus sign and drop '.0'")
    func net() {
        #expect(StrategyText.net(1) == "+1")
        #expect(StrategyText.net(-2) == "\u{2212}2")
        #expect(StrategyText.net(0) == "0")
        #expect(StrategyText.net(1.5) == "+1.5")
        #expect(StrategyText.net(-0.5) == "\u{2212}0.5")
    }

    @Test("Summary numbers")
    func summaryNumbers() {
        #expect(StrategyText.percent(nil) == "—")
        #expect(StrategyText.percent(0.875) == "88%")
        #expect(StrategyText.seconds(fromMs: nil) == "—")
        #expect(StrategyText.seconds(fromMs: 1_440) == "1.4 s")
        #expect(StrategyText.mistakeDetail(StrategyFixtures.decision(1, choice: .timeout)) == "You: Timeout · Play: Hit")
    }
}
```

Create `BJSTests/StrategyTrainerViewModelTests.swift`:

```swift
import BJSCore
import Foundation
import Testing
@testable import BJS

@MainActor
@Suite("StrategyTrainerViewModel")
struct StrategyTrainerViewModelTests {

    private let clock = FakeClock()
    private let saver = FakeStrategySaver()

    private func makeViewModel(_ config: StrategySessionConfig = StrategySessionConfig(mode: .test),
                               shoes: [[Rank]]? = nil, history: [DecisionSample] = [],
                               seed: UInt64 = 7, timer: Double = 3.0) -> StrategyTrainerViewModel {
        let clock = self.clock
        let source: StrategySession.HandSource = shoes.map { .scripted($0.map(StrategyFixtures.shoe)) } ?? .generated
        return StrategyTrainerViewModel(config: config, rules: BlackjackRules(), speedTimerSeconds: timer,
                                        history: history, seed: seed, source: source, saver: saver,
                                        now: { clock.now })
    }

    private func history(_ count: Int) -> [DecisionSample] {
        (0..<count).map { index in
            DecisionSample(date: StrategyFixtures.start.addingTimeInterval(TimeInterval(-index)),
                           cell: TrainingCell(handType: .hard, playerValue: 12, dealerUpcard: 2),
                           isCorrect: index % 2 == 0, responseMs: nil)
        }
    }

    // MARK: - Spec §7 required regression (the Phase 7 bug)

    @Test("STAND always produces feedback before the next hand",
          arguments: StrategyMode.allCases)
    func standAlwaysProducesFeedbackBeforeTheNextHand(mode: StrategyMode) {
        let vm = makeViewModel(StrategySessionConfig(mode: mode, length: .hands50), history: history(60))
        for hand in 1...50 {
            #expect(vm.phase == .decision)
            #expect(vm.handNumber == hand)
            #expect(vm.allowedActions.contains(.stand))

            vm.choose(.stand)
            // Feedback first: same hand, outcome still hidden, dock disabled.
            #expect(vm.phase == .feedback)
            #expect(vm.feedback?.choice == .action(.stand))
            #expect(vm.feedback?.handNumber == hand)
            #expect(vm.handNumber == hand)
            #expect(!vm.isDealerRevealed)
            #expect(vm.allowedActions.isEmpty)

            // Only NEXT reveals the outcome...
            vm.next()
            #expect(vm.phase == .outcome)
            #expect(vm.isDealerRevealed)
            #expect(vm.feedback == nil)

            // ...and only "Next hand" deals the next one.
            vm.nextHand()
        }
        #expect(vm.isFinished)
        #expect(vm.summary.decisionCount == 50)
        #expect(saver.saved.count == 1)
    }

    @Test("STAND on a scripted hard 16 vs 7: feedback, then the loss, then hand 2")
    func standScripted() {
        let vm = makeViewModel(shoes: [StrategyFixtures.hard16vs7])
        vm.choose(.stand)
        #expect(vm.feedback.map(DecisionFeedback.headline) == "The play is Hit")
        #expect(vm.playerHands[0].outcome == nil)
        vm.next()
        #expect(vm.phase == .outcome)
        #expect(StrategyText.outcome(vm.playerHands[0]) == "Loss \u{2212}1")
        vm.nextHand()
        #expect(vm.phase == .decision)
        #expect(vm.handNumber == 2)
    }

    @Test("A double tap grades only one decision")
    func doubleTap() {
        let vm = makeViewModel(shoes: [StrategyFixtures.hard16vs7])
        vm.choose(.stand)
        vm.choose(.stand)
        vm.choose(.hit)
        #expect(vm.summary.decisionCount == 1)
    }

    @Test("Learn mode rings the correct action; Test mode shows no hint")
    func hints() {
        #expect(makeViewModel(StrategySessionConfig(mode: .learn), shoes: [StrategyFixtures.hard16vs7]).hint == .hit)
        #expect(makeViewModel(StrategySessionConfig(mode: .test), shoes: [StrategyFixtures.hard16vs7]).hint == nil)
    }

    @Test("Reaction time and decidedAt come from the clock, per decision")
    func reactionTime() {
        let vm = makeViewModel(shoes: [StrategyFixtures.eightsVs6])
        clock.advance(1.25)
        vm.choose(.split)
        #expect(vm.feedback?.responseMs == 1_250)
        #expect(vm.feedback?.decidedAt == StrategyFixtures.start.addingTimeInterval(1.25))

        clock.advance(4)                     // reading the feedback does not count
        vm.next()
        clock.advance(0.5)
        vm.choose(.double)
        #expect(vm.feedback?.responseMs == 500)
        #expect(vm.feedback?.decidedAt == StrategyFixtures.start.addingTimeInterval(5.75))
    }

    @Test("Each new decision gets a new countdown token (splits included)")
    func tokens() {
        let vm = makeViewModel(StrategySessionConfig(mode: .speed), shoes: [StrategyFixtures.eightsVs6])
        let first = vm.decisionToken
        #expect(vm.countdownToken == first)
        vm.choose(.split)
        #expect(vm.countdownToken == nil)    // no countdown while feedback shows
        vm.next()
        #expect(vm.countdownToken == first + 1)
    }

    @Test("Speed: a timeout records an incorrect 'timeout' at the full countdown; stale timers are ignored")
    func timeout() {
        let vm = makeViewModel(StrategySessionConfig(mode: .speed), shoes: [StrategyFixtures.hard16vs7], timer: 2.5)
        vm.timeExpired(token: vm.decisionToken - 1)
        #expect(vm.phase == .decision)

        vm.timeExpired(token: vm.decisionToken)
        let decision = vm.feedback
        #expect(decision?.choice == .timeout)
        #expect(decision?.isCorrect == false)
        #expect(decision?.responseMs == 2_500)
        #expect(decision.map(DecisionFeedback.headline) == "Time's up: Hit")

        vm.timeExpired(token: vm.decisionToken)
        #expect(vm.summary.decisionCount == 1)
    }

    @Test("Outside Speed mode there is no countdown and timeouts do nothing")
    func noTimeoutInTest() {
        let vm = makeViewModel(StrategySessionConfig(mode: .test), shoes: [StrategyFixtures.hard16vs7])
        #expect(vm.countdownToken == nil)
        vm.timeExpired(token: vm.decisionToken)
        #expect(vm.phase == .decision)
    }

    @Test("Reaching the hand limit shows the summary and saves once, with every decision")
    func completes() throws {
        let vm = makeViewModel(StrategySessionConfig(mode: .learn, length: .hands25))
        while !vm.isFinished {
            clock.advance(1)
            switch vm.phase {
            case .decision: vm.choose(vm.hint ?? .stand)
            case .feedback: vm.next()
            case .outcome: vm.nextHand()
            case .finished: break
            }
        }
        #expect(vm.isSaved)
        #expect(!vm.isShowingSaveError)
        let snapshot = try #require(saver.saved.first)
        #expect(saver.saved.count == 1)
        #expect(snapshot.config.mode == .learn)
        #expect(snapshot.summary.handsPlayed == 25)
        #expect(snapshot.summary.accuracy == 1)
        #expect(snapshot.decisions.count == snapshot.summary.decisionCount)
        let dates = snapshot.decisions.map(\.decidedAt)
        #expect(dates == dates.sorted() && Set(dates).count == dates.count)
        #expect(snapshot.startedAt == StrategyFixtures.start)
        #expect(snapshot.endedAt == clock.now)
    }

    @Test("A save failure shows a non-blocking alert and still shows the summary")
    func saveFailure() {
        saver.fails = true
        let vm = makeViewModel(StrategySessionConfig(mode: .test, length: .endless), shoes: [StrategyFixtures.hard16vs7])
        vm.choose(.hit)
        vm.next()
        vm.endSession()
        #expect(vm.isFinished)
        #expect(vm.isShowingSaveError)
        #expect(!vm.isSaved)
        #expect(vm.summary.decisionCount == 1)
    }

    @Test("Leaving before any graded decision closes at once and saves nothing")
    func leaveEmpty() {
        let vm = makeViewModel(shoes: [StrategyFixtures.hard16vs7])
        #expect(vm.requestLeave())
        #expect(!vm.isConfirmingLeave)
        #expect(saver.saved.isEmpty)
    }

    @Test("Leaving mid-session asks; Save partial saves and shows the summary")
    func leaveSavePartial() throws {
        let vm = makeViewModel(StrategySessionConfig(mode: .speed), shoes: [StrategyFixtures.hard16vs7])
        vm.choose(.stand)
        #expect(!vm.requestLeave())
        #expect(vm.isConfirmingLeave)
        vm.savePartial()
        #expect(vm.isFinished)
        #expect(try #require(saver.saved.first).decisions.count == 1)
        #expect(vm.requestLeave())            // on the summary, close closes
    }

    @Test("Discard saves nothing; Keep playing restarts the Speed countdown")
    func leaveDiscardOrKeep() {
        let vm = makeViewModel(StrategySessionConfig(mode: .speed), shoes: [StrategyFixtures.hard16vs7])
        vm.choose(.hit)
        vm.next()                             // 16 + 5 = 21 → outcome
        vm.nextHand()                         // hand 2 (the script repeats)
        let token = vm.decisionToken
        #expect(!vm.requestLeave())
        #expect(vm.countdownToken == nil)     // paused while the prompt shows
        vm.keepPlaying()
        #expect(vm.countdownToken == token + 1)

        #expect(!vm.requestLeave())
        vm.discard()
        #expect(saver.saved.isEmpty)
    }

    @Test("Weak spots uses weights only with 50+ decisions of history")
    func weakSpots() {
        #expect(makeViewModel(StrategySessionConfig(mode: .weakSpots), history: history(60)).session.weights != nil)
        #expect(makeViewModel(StrategySessionConfig(mode: .weakSpots), history: history(10)).session.weights == nil)
        #expect(makeViewModel(StrategySessionConfig(mode: .test), history: history(60)).session.weights == nil)
    }

    @Test("WHY opens for the exact hand, upcard and rules")
    func why() throws {
        let vm = makeViewModel(shoes: [StrategyFixtures.eightsVs6])
        vm.choose(.hit)
        vm.showWhy(for: try #require(vm.feedback))
        let context = try #require(vm.presentedWhy)
        #expect(context.handType == .pair)
        #expect(context.pairRank == .eight)
        #expect(context.dealerUpCard == .six)
        #expect(context.userAction == .hit)
        #expect(context.correctAction == .split)
        #expect(context.rules == BlackjackRules())
        #expect(DecisionFeedback.spotTitle(context) == "Pair of 8s vs 6")
    }
}
```

- [ ] **Step 2: Run them on Linux to see them fail**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
scripts/dev/linux_app_check.sh BJS/Persistence/StrategySessionSaving.swift \
  BJSTests/StrategyFixtures.swift BJSTests/StrategyTextTests.swift BJSTests/StrategyTrainerViewModelTests.swift
```

Expected: `error: cannot find 'StrategyText' in scope` / `cannot find 'StrategyTrainerViewModel' in scope`.

- [ ] **Step 3: Implement**

Create `BJS/Features/Strategy/StrategyText.swift`:

```swift
import BJSCore
import Foundation

/// Short display strings for the trainer and the summary. Presentation only.
enum StrategyText {
    /// "Hand 3 of 25", or "Hand 3" in Endless.
    static func progress(handNumber: Int, limit: Int?) -> String {
        limit.map { "Hand \(handNumber) of \($0)" } ?? "Hand \(handNumber)"
    }

    /// Hand total label: "16", soft hands as "8/18", "21", "Bust".
    static func total(_ hand: BlackjackHand) -> String {
        if hand.isBust { return "Bust" }
        if hand.isSoft && hand.total < 21 { return "\(hand.total - 10)/\(hand.total)" }
        return "\(hand.total)"
    }

    /// The dealer's result once revealed: "Dealer has 19", "Dealer busts".
    static func dealerResult(_ dealer: BlackjackHand) -> String {
        dealer.isBust ? "Dealer busts" : "Dealer has \(dealer.total)"
    }

    /// Net result in bets: "+1", "−2", "0", "+1.5", "−0.5" (true minus sign).
    static func net(_ units: Double) -> String {
        if units == 0 { return "0" }
        let magnitude = abs(units)
        let number = magnitude == magnitude.rounded() ? String(Int(magnitude)) : String(magnitude)
        return (units > 0 ? "+" : "\u{2212}") + number
    }

    /// One player hand's result: "Win +1", "Bust −2", "Push 0", "Surrendered −0.5".
    static func outcome(_ state: PlayerHandState) -> String {
        let name: String
        switch state.outcome {
        case .blackjack: name = "Blackjack"
        case .win: name = "Win"
        case .push: name = "Push"
        case .loss: name = "Loss"
        case .bust: name = "Bust"
        case .surrendered: name = "Surrendered"
        case nil: return ""
        }
        return "\(name) \(net(state.net))"
    }

    /// "87%", or "—" with no decisions.
    static func percent(_ accuracy: Double?) -> String {
        guard let accuracy else { return "—" }
        return "\(Int((accuracy * 100).rounded()))%"
    }

    /// Mean decision time: "1.4 s", or "—".
    static func seconds(fromMs ms: Double?) -> String {
        guard let ms else { return "—" }
        return String(format: "%.1f s", ms / 1_000)
    }

    /// A mistakes-list row's detail: "You: Stand · Play: Hit".
    static func mistakeDetail(_ decision: GradedDecision) -> String {
        "You: \(DecisionFeedback.choiceName(decision.choice)) · Play: \(DecisionFeedback.actionName(decision.correctAction))"
    }
}
```

Create `BJS/Features/Strategy/StrategyTrainerViewModel.swift`:

```swift
import BJSCore
import Foundation
import Observation

/// Drives one Strategy session for `StrategyTrainerView` (spec §5 Strategy; §3 rule 2).
///
/// A thin adapter over `BJSCore.StrategySession`, which holds all the game logic. This class
/// owns what the engine should not: the random-number generator, the clock (reaction times
/// and each decision's `decidedAt`), the Speed-mode countdown token, the WHY sheet, the
/// leave prompt, and saving.
@MainActor
@Observable
final class StrategyTrainerViewModel {
    /// One engine for the app, so each rule set's table is generated once.
    nonisolated static let strategyEngine = StrategyEngine()

    let config: StrategySessionConfig
    /// The session's snapshot of the active rules.
    let rules: BlackjackRules
    let speedTimerSeconds: Double
    let startedAt: Date

    private(set) var session: StrategySession
    /// Changes whenever a new decision starts. The view restarts the Speed countdown on it.
    private(set) var decisionToken = 0
    /// When the current decision started; reaction time is measured from here.
    private(set) var decisionStartedAt: Date
    /// The WHY sheet's content while it is open.
    var presentedWhy: WhyContext?
    /// The Save partial / Discard prompt.
    var isConfirmingLeave = false
    /// Non-blocking "couldn't save" alert (spec §6). The summary still shows.
    var isShowingSaveError = false
    private(set) var isSaved = false

    @ObservationIgnored private var rng: SeededRandomNumberGenerator
    @ObservationIgnored private var hasCompleted = false
    private let saver: any StrategySessionSaving
    private let now: @MainActor () -> Date
    private let sessionID = UUID()

    /// - Parameters:
    ///   - history: recent decisions for Weak-spots weights (ignored in the other modes).
    ///   - seed: the session's random seed (UI tests pass a fixed one).
    ///   - source: `.generated` in the app; tests may script the shoes.
    init(config: StrategySessionConfig, rules: BlackjackRules, speedTimerSeconds: Double,
         history: [DecisionSample], seed: UInt64, source: StrategySession.HandSource = .generated,
         saver: any StrategySessionSaving, now: @escaping @MainActor () -> Date = { Date() }) {
        self.config = config
        self.rules = rules
        self.speedTimerSeconds = speedTimerSeconds
        self.saver = saver
        self.now = now
        var rng = SeededRandomNumberGenerator(seed: seed)
        let weights = config.mode.usesWeakSpotWeights ? WeakSpotWeights.compute(from: history) : nil
        do {
            session = try StrategySession(rules: rules, config: config,
                                          table: Self.strategyEngine.strategy(for: rules),
                                          weights: weights, source: source, using: &rng)
        } catch {
            // A training shoe holds at least a full deck; dealing four cards cannot run out.
            preconditionFailure("Could not deal the first training hand: \(error)")
        }
        self.rng = rng
        let start = now()
        startedAt = start
        decisionStartedAt = start
    }

    // MARK: - What the view shows

    var phase: StrategySession.Phase { session.phase }
    var isFinished: Bool { session.phase == .finished }
    var handNumber: Int { session.handNumber }

    /// Enabled dock buttons: the legal actions during a decision, none otherwise.
    var allowedActions: Set<Action> { session.currentSpot?.legalActions ?? [] }

    /// Learn mode's brass ring.
    var hint: Action? { session.hint }

    /// The FeedbackCard's decision, only while feedback shows.
    var feedback: GradedDecision? { session.phase == .feedback ? session.lastDecision : nil }

    var summary: StrategySessionSummary { session.summary }

    var dealerHand: BlackjackHand { session.round.dealer }
    var playerHands: [PlayerHandState] { session.round.hands }
    var activeHandIndex: Int { session.round.activeHandIndex }

    /// The hole card stays face down until the hand's outcome.
    var isDealerRevealed: Bool { session.phase == .outcome }

    /// Non-nil while a Speed-mode countdown should run (a decision, no prompt open).
    var countdownToken: Int? {
        guard config.mode.isTimed, session.phase == .decision, !isConfirmingLeave else { return nil }
        return decisionToken
    }

    // MARK: - Player input

    func choose(_ action: Action) {
        grade(.action(action), responseMs: nil)
    }

    /// Speed mode: the countdown for `token` ran out. Stale tokens are ignored.
    func timeExpired(token: Int) {
        guard config.mode.isTimed, token == decisionToken, session.phase == .decision, !isConfirmingLeave else {
            return
        }
        grade(.timeout, responseMs: Int((speedTimerSeconds * 1_000).rounded()))
    }

    /// NEXT on the FeedbackCard.
    func next() {
        guard session.phase == .feedback else { return }
        do {
            try session.continueAfterFeedback()
        } catch {
            endAfterEngineError()
            return
        }
        if session.phase == .decision { startDecision() }
    }

    /// "Next hand" (or "Finish" on the last hand) after the outcome.
    func nextHand() {
        guard session.phase == .outcome else { return }
        do {
            try session.nextHand(using: &rng)
        } catch {
            endAfterEngineError()
            return
        }
        switch session.phase {
        case .decision: startDecision()
        case .finished: completeSession()
        case .feedback, .outcome: break
        }
    }

    /// Endless mode's End button: finish now and show the summary.
    func endSession() {
        guard !isFinished else { return }
        session.finish()
        completeSession()
    }

    // MARK: - Leaving

    /// The close button. Returns true when the view should close right away: on the summary,
    /// or before any decision was graded (there is nothing to save). Otherwise it opens the
    /// Save partial / Discard prompt and returns false.
    func requestLeave() -> Bool {
        if isFinished || session.decisions.isEmpty { return true }
        isConfirmingLeave = true
        return false
    }

    /// "Save partial": ends the session here, saves it, and shows its summary.
    func savePartial() {
        isConfirmingLeave = false
        endSession()
    }

    /// "Keep playing": back to the table. A Speed countdown starts again from full.
    func keepPlaying() {
        isConfirmingLeave = false
        if session.phase == .decision { startDecision() }
    }

    /// "Discard": nothing is saved; the view closes.
    func discard() {
        isConfirmingLeave = false
    }

    // MARK: - WHY

    func showWhy(for decision: GradedDecision) {
        presentedWhy = decision.whyContext(rules: rules)
    }

    // MARK: - Internals

    private func grade(_ choice: DecisionChoice, responseMs: Int?) {
        guard session.phase == .decision else { return }        // double taps, late timeouts
        let date = now()
        let elapsed = Int((date.timeIntervalSince(decisionStartedAt) * 1_000).rounded())
        do {
            try session.choose(choice, responseMs: responseMs ?? max(0, elapsed), at: date)
        } catch {
            // Illegal actions cannot be tapped (the dock dims them); ignore defensively.
        }
    }

    private func startDecision() {
        decisionToken += 1
        decisionStartedAt = now()
    }

    /// The engine cannot fail with a stacked training shoe; if it ever does, end the session
    /// gracefully with what was graded so far.
    private func endAfterEngineError() {
        session.finish()
        completeSession()
    }

    private func completeSession() {
        guard !hasCompleted else { return }
        hasCompleted = true
        let snapshot = StrategySessionSnapshot(id: sessionID, config: config, rules: rules, startedAt: startedAt,
                                               endedAt: now(), summary: session.summary,
                                               decisions: session.decisions)
        do {
            try saver.save(snapshot)
            isSaved = true
        } catch {
            isShowingSaveError = true
        }
    }
}
```

- [ ] **Step 4: Run them on Linux to see them pass**

```bash
swiftc -swift-version 6 -typecheck -I BJSCore/.build/debug/Modules BJS/Persistence/StrategySessionSaving.swift \
  BJS/Features/Strategy/StrategyTrainerViewModel.swift BJS/Features/Strategy/StrategyText.swift
scripts/dev/linux_app_check.sh BJS/Shared/LastLaunch.swift BJS/Shared/LastLaunchStore.swift \
  BJS/Shared/TrainingDisplay.swift BJS/App/LaunchConfiguration.swift BJS/Persistence/StrategySessionSaving.swift \
  BJS/Features/Strategy/StrategyTrainerViewModel.swift BJS/Features/Strategy/StrategyText.swift \
  BJSTests/TestDefaults.swift BJSTests/LastLaunchStoreTests.swift BJSTests/StrategyFixtures.swift \
  BJSTests/StrategyTextTests.swift BJSTests/StrategyTrainerViewModelTests.swift
```

Expected: no output from `swiftc`; no `error:`/`warning:` lines from the build; `✔ Test run with 26 tests in 5 suites passed …` (7 from Task 5 + 4 text + 15 ViewModel).

- [ ] **Step 5: Commit**

```bash
git add BJS/Features/Strategy/StrategyTrainerViewModel.swift BJS/Features/Strategy/StrategyText.swift \
        BJSTests/StrategyTrainerViewModelTests.swift BJSTests/StrategyTextTests.swift
git commit -m "feat(strategy): trainer ViewModel with the STAND regression test

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller.

- [ ] **Step 6: CI verification (controller)**

Expected: green; 90 unit tests (71 + 19). In the unit-test log, find `STAND always produces feedback before the next hand` passing, once for each of the four mode arguments.

---

### Task 8: `CountdownBar` component and gallery page

**Files:**
- Create: `BJS/Design/Components/CountdownBar.swift`
- Modify: `BJS/Design/Gallery/ComponentGallery.swift`, `BJSUITests/DesignScreenshotTests.swift`
- Test: `BJSTests/CountdownBarTests.swift`

**Interfaces:**
- Consumes: `FeltColor.cream`, `FeltColor.surfaceInset`, `FeltSpacing.s` (existing tokens only)
- Produces: `struct CountdownBar: View { init(fraction: Double); static func remainingFraction(startedAt:now:duration:) -> Double }`; `GalleryPage.countdown` ("Countdown bar")

This is a **new** component built from existing tokens (spec §4 allows that after the freeze). No existing token or component changes.

- [ ] **Step 1: Write the test**

Create `BJSTests/CountdownBarTests.swift`:

```swift
import Foundation
import Testing
@testable import BJS

@Suite("CountdownBar")
struct CountdownBarTests {

    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test("Remaining fraction runs from 1 to 0 and is clamped")
    func remaining() {
        #expect(CountdownBar.remainingFraction(startedAt: start, now: start, duration: 3) == 1)
        #expect(CountdownBar.remainingFraction(startedAt: start, now: start.addingTimeInterval(1.5), duration: 3) == 0.5)
        #expect(CountdownBar.remainingFraction(startedAt: start, now: start.addingTimeInterval(5), duration: 3) == 0)
        #expect(CountdownBar.remainingFraction(startedAt: start, now: start.addingTimeInterval(-1), duration: 3) == 1)
        #expect(CountdownBar.remainingFraction(startedAt: start, now: start, duration: 0) == 0)
    }
}
```

- [ ] **Step 2: Implement**

Create `BJS/Design/Components/CountdownBar.swift`:

```swift
import Foundation
import SwiftUI

/// Speed-mode countdown (added in Step 3, built only from existing Felt tokens):
/// a cream bar on a `surfaceInset` track that empties from right to left.
///
/// The caller drives it, e.g. from a `TimelineView`, with `remainingFraction(...)`.
struct CountdownBar: View {
    private let fraction: Double

    /// `fraction` of time left, 0...1 (clamped).
    init(fraction: Double) {
        self.fraction = min(max(fraction, 0), 1)
    }

    /// Time left as a fraction: 1 at `startedAt`, 0 once `duration` has passed.
    static func remainingFraction(startedAt: Date, now: Date, duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        let left = 1 - now.timeIntervalSince(startedAt) / duration
        return min(max(left, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(FeltColor.surfaceInset)
                Capsule(style: .continuous)
                    .fill(FeltColor.cream)
                    .frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: FeltSpacing.s)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Time left")
        .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
    }
}
```

In `BJS/Design/Gallery/ComponentGallery.swift`, make four edits:

1. In `enum GalleryPage`, after `case keypadDecimal`, add:
   ```swift
       case countdown
   ```
2. In `title`, after `case .keypadDecimal: return "Keypad (decimal)"`, add:
   ```swift
           case .countdown: return "Countdown bar"
   ```
3. In `ComponentGalleryView.content`, after `case .keypadDecimal: KeypadGalleryPage(allowsDecimal: true)`, add:
   ```swift
           case .countdown: CountdownGalleryPage()
   ```
4. Directly above `#Preview("Cards") { ComponentGalleryView(page: .cards) }`, add:
   ```swift
   private struct CountdownGalleryPage: View {
       var body: some View {
           GalleryItem("Full") { CountdownBar(fraction: 1) }
           GalleryItem("Half") { CountdownBar(fraction: 0.5) }
           GalleryItem("Nearly out") { CountdownBar(fraction: 0.1) }
           GalleryItem("Empty (timeout)") { CountdownBar(fraction: 0) }
       }
   }

   ```

In `BJSUITests/DesignScreenshotTests.swift`, add `"countdown"` to the end of `galleryPages`:

```swift
    private static let galleryPages = [
        "colors", "type", "cards", "dock", "feedback",
        "buttons", "tiles", "settingsRows", "keypad", "keypadDecimal", "countdown",
    ]
```

The new page's screenshot is named `20-gallery-countdown` (index 10 + 10).

- [ ] **Step 3: Local pre-checks**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
swiftc -parse BJS/Design/Components/CountdownBar.swift BJS/Design/Gallery/ComponentGallery.swift \
  BJSUITests/DesignScreenshotTests.swift BJSTests/CountdownBarTests.swift
grep -c "case countdown\|case .countdown" BJS/Design/Gallery/ComponentGallery.swift
```

Expected: no output from `swiftc`; `3`.

- [ ] **Step 4: Commit**

```bash
git add BJS/Design/Components/CountdownBar.swift BJS/Design/Gallery/ComponentGallery.swift \
        BJSUITests/DesignScreenshotTests.swift BJSTests/CountdownBarTests.swift
git commit -m "feat(app): CountdownBar component and gallery page

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller.

- [ ] **Step 5: CI verification (controller)**

Expected: green; 91 unit tests (90 + 1); 2 UI tests; `Exported 17 screenshots` per device (the new `20-gallery-countdown`).

---

### Task 9: Setup, trainer, WHY sheet, summary and session screens

**Files:**
- Create: `BJS/Features/Strategy/StrategySetupView.swift`, `StrategyTrainerView.swift`, `WhySheet.swift`, `StrategySummaryView.swift`, `StrategySessionScreen.swift`

**Interfaces:**
- Consumes: Tasks 5–8; the existing components `ModePicker`, `PrimaryButton`, `HandView`, `ActionDock`, `FeedbackCard`, `StatChip`, `SettingsSection`, `FeltPressableStyle`, `.feltBackground()`, `.feltType(_:)`, `FeltMotion.panelTransition(reduceMotion:)`; `ActiveRulesStore`, `Preferences`, `RulesSummary.short(_:)`; `DecisionHistory`, `SwiftDataStrategySessionSaver`; `WhyExplanation.explain(_:)`
- Produces (accessibility identifiers are what the UI test uses):
  - `StrategySetupView(initial: StrategySessionConfig?, onStart: (StrategySessionConfig) -> Void)`: `strategy.setup.title`, `strategy.modeDescription`, `strategy.start`; picker segments are buttons labelled "Learn" … "Weak spots", "25" … "Endless", "All" … "Pairs"
  - `StrategyTrainerView(viewModel:onClose:)`:
    - top bar: `trainer.close`, `trainer.progress`, `trainer.end` (Endless) or `trainer.score`
    - `trainer.countdown`, `trainer.dealer`, `trainer.player`, `trainer.handOutcome.<i>`, `trainer.outcome`, `trainer.nextHand`
    - the dock's `action.<name>`, and the FeedbackCard's `feedback.card`, `feedback.why`, `feedback.next`
    - alerts "Leave this session?" (Save partial / Discard / Keep playing) and "Couldn't save this session"
    - the Speed countdown runs as `.task(id: viewModel.countdownToken)`
  - `WhySheet(context:)`: `why.done`, `why.title`, `why.play`, `why.explanation`
  - `StrategySummaryView(viewModel:onDone:)`: `summary.title`, `summary.accuracy`, `summary.mistakes`, `summary.bestStreak`, `summary.hands`, `summary.meanTime` (Speed only), `summary.mistake.<sequence>`, `summary.done`
  - `StrategySessionScreen(config:seed:onClose:)`: builds the ViewModel on appear from the active rules, `Preferences.speedTimerSeconds`, Weak-spots history and a SwiftData saver

These views are not reachable until Task 10 wires them. This task's CI run proves they compile.

- [ ] **Step 1: Create the setup screen**

Create `BJS/Features/Strategy/StrategySetupView.swift`:

```swift
import BJSCore
import SwiftUI

/// Strategy setup (spec §5): mode, length and hand filter, then Start.
///
/// Pushed from the hub. `onStart` comes from the App layer, which records the launch for
/// Continue and presents the trainer full-screen, so this feature never names the hub.
struct StrategySetupView: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(Preferences.self) private var preferences
    @State private var mode: StrategyMode
    @State private var length: StrategySessionLength
    @State private var filter: HandFilter

    private let onStart: (StrategySessionConfig) -> Void

    /// `initial` prefills the pickers (the last setup used), or the defaults when nil.
    init(initial: StrategySessionConfig?, onStart: @escaping (StrategySessionConfig) -> Void) {
        let config = initial ?? StrategySessionConfig()
        self._mode = State(initialValue: config.mode)
        self._length = State(initialValue: config.length)
        self._filter = State(initialValue: config.filter)
        self.onStart = onStart
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                header
                SetupSection("Mode") {
                    ModePicker(StrategyMode.allCases, selection: $mode) { $0.displayName }
                    Text(modeDescription)
                        .feltType(.body)
                        .foregroundStyle(FeltColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("strategy.modeDescription")
                }
                SetupSection("Length") {
                    ModePicker(StrategySessionLength.allCases, selection: $length) { $0.displayName }
                }
                SetupSection("Hands") {
                    ModePicker(HandFilter.allCases, selection: $filter) { $0.displayName }
                }
                PrimaryButton("Start") {
                    onStart(StrategySessionConfig(mode: mode, length: length, filter: filter))
                }
                .accessibilityIdentifier("strategy.start")
            }
            .padding(.horizontal, FeltSpacing.l)
            .padding(.vertical, FeltSpacing.xl)
        }
        .feltBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            Text("Rules: \(RulesSummary.short(rulesStore.rules))")
                .feltType(.label)
                .foregroundStyle(FeltColor.textSecondary)
            Text("Strategy")
                .feltType(.display)
                .foregroundStyle(FeltColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("strategy.setup.title")
        }
    }

    private var modeDescription: String {
        guard mode == .speed else { return mode.setupDescription }
        let seconds = String(format: "%.1f", preferences.speedTimerSeconds)
        return "\(mode.setupDescription) \(seconds) s per decision (change it in Settings)."
    }
}

/// A labelled group on the setup screen: a `label`-style caption over its controls.
private struct SetupSection<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text(title)
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}
```

- [ ] **Step 2: Create the trainer**

Create `BJS/Features/Strategy/StrategyTrainerView.swift`:

```swift
import BJSCore
import SwiftUI

/// The Strategy trainer table (spec §5): dealer and player hands, the ActionDock, the
/// FeedbackCard after every decision (before the outcome), the outcome, and — once the
/// session ends — the summary. Presented full-screen over the tabs.
struct StrategyTrainerView: View {
    @Bindable private var viewModel: StrategyTrainerViewModel
    private let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: StrategyTrainerViewModel, onClose: @escaping () -> Void) {
        self._viewModel = Bindable(wrappedValue: viewModel)
        self.onClose = onClose
    }

    var body: some View {
        Group {
            if viewModel.isFinished {
                StrategySummaryView(viewModel: viewModel, onDone: onClose)
            } else {
                table
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .feltBackground()
        .sheet(item: $viewModel.presentedWhy) { context in
            WhySheet(context: context)
        }
        .alert("Leave this session?", isPresented: $viewModel.isConfirmingLeave) {
            Button("Save partial") { viewModel.savePartial() }
            Button("Discard", role: .destructive) {
                viewModel.discard()
                onClose()
            }
            Button("Keep playing", role: .cancel) { viewModel.keepPlaying() }
        } message: {
            Text("Save the decisions so far and see the summary, or discard this session.")
        }
        .alert("Couldn't save this session", isPresented: $viewModel.isShowingSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your summary is shown, but this session won't count toward your progress.")
        }
        .task(id: viewModel.countdownToken) {
            // Speed mode: one countdown per decision. A new token (next decision) or a
            // nil token (feedback, prompt) cancels this task before it fires.
            guard let token = viewModel.countdownToken else { return }
            try? await Task.sleep(for: .seconds(viewModel.speedTimerSeconds))
            guard !Task.isCancelled else { return }
            viewModel.timeExpired(token: token)
        }
    }

    // MARK: - Table

    private var table: some View {
        VStack(spacing: FeltSpacing.m) {
            topBar
            if viewModel.config.mode.isTimed {
                countdown
            }
            Spacer(minLength: 0)
            dealerArea
            Spacer(minLength: 0)
            playerArea
            Spacer(minLength: 0)
            bottomArea
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.bottom, FeltSpacing.l)
        .animation(reduceMotion ? FeltMotion.crossFade(duration: FeltMotion.uiDuration) : FeltMotion.ui,
                   value: viewModel.phase)
    }

    private var topBar: some View {
        HStack(spacing: FeltSpacing.s) {
            Button {
                if viewModel.requestLeave() { onClose() }
            } label: {
                Image(systemName: "xmark")
                    .feltType(.title)
                    .foregroundStyle(FeltColor.textPrimary)
                    .frame(width: FeltMetrics.minTapTarget, height: FeltMetrics.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(FeltPressableStyle())
            .accessibilityLabel("Close")
            .accessibilityIdentifier("trainer.close")

            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Text(StrategyText.progress(handNumber: viewModel.handNumber, limit: viewModel.config.length.handLimit))
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textPrimary)
                    .accessibilityIdentifier("trainer.progress")
                Text(viewModel.config.mode.displayName)
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textTertiary)
            }
            Spacer(minLength: 0)

            if viewModel.config.length == .endless {
                Button("End") { viewModel.endSession() }
                    .feltType(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(FeltColor.textPrimary)
                    .frame(minWidth: FeltMetrics.minTapTarget, minHeight: FeltMetrics.minTapTarget)
                    .buttonStyle(FeltPressableStyle())
                    .accessibilityHint("Ends the session and shows the summary")
                    .accessibilityIdentifier("trainer.end")
            } else {
                Text("\(viewModel.summary.correctDecisions)/\(viewModel.summary.decisionCount)")
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textSecondary)
                    .frame(minWidth: FeltMetrics.minTapTarget, minHeight: FeltMetrics.minTapTarget)
                    .accessibilityLabel("\(viewModel.summary.correctDecisions) of \(viewModel.summary.decisionCount) correct")
                    .accessibilityIdentifier("trainer.score")
            }
        }
    }

    private var countdown: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.25 : nil, paused: viewModel.countdownToken == nil)) { context in
            CountdownBar(fraction: CountdownBar.remainingFraction(startedAt: viewModel.decisionStartedAt,
                                                                   now: context.date,
                                                                   duration: viewModel.speedTimerSeconds))
        }
        .opacity(viewModel.countdownToken == nil ? 0 : 1)
        .accessibilityIdentifier("trainer.countdown")
    }

    // MARK: - Hands

    private var dealerArea: some View {
        VStack(spacing: FeltSpacing.s) {
            Text("Dealer")
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
            HandView(cards: viewModel.dealerHand.cards,
                     faceDownIndices: viewModel.isDealerRevealed ? [] : [1],
                     cardWidth: 64, overlap: 0.35,
                     totalLabel: viewModel.isDealerRevealed ? StrategyText.total(viewModel.dealerHand) : nil)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("trainer.dealer")
    }

    private var playerArea: some View {
        VStack(spacing: FeltSpacing.s) {
            ViewThatFits(in: .horizontal) {
                playerHands
                ScrollView(.horizontal, showsIndicators: false) {
                    playerHands
                }
            }
            Text("You")
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("trainer.player")
    }

    private var playerHands: some View {
        let hands = viewModel.playerHands
        let cardWidth: CGFloat = hands.count > 1 ? 52 : 72
        return HStack(alignment: .top, spacing: FeltSpacing.l) {
            ForEach(Array(hands.enumerated()), id: \.offset) { index, state in
                VStack(spacing: FeltSpacing.xs) {
                    HandView(cards: state.hand.cards, cardWidth: cardWidth, overlap: 0.35,
                             totalLabel: StrategyText.total(state.hand))
                    if viewModel.phase == .outcome {
                        Text(StrategyText.outcome(state))
                            .feltType(.label)
                            .foregroundStyle(FeltColor.textPrimary)
                            .accessibilityIdentifier("trainer.handOutcome.\(index)")
                    }
                }
                .opacity(isDimmed(index, handCount: hands.count) ? 0.4 : 1)
            }
        }
    }

    /// With split hands, the hands not being played are dimmed while decisions are made.
    private func isDimmed(_ index: Int, handCount: Int) -> Bool {
        handCount > 1 && index != viewModel.activeHandIndex
            && (viewModel.phase == .decision || viewModel.phase == .feedback)
    }

    // MARK: - Bottom: dock + feedback, or the outcome

    @ViewBuilder
    private var bottomArea: some View {
        switch viewModel.phase {
        case .decision, .feedback:
            ActionDock(allowed: viewModel.allowedActions, hint: viewModel.hint) { action in
                viewModel.choose(action)
            }
            .overlay(alignment: .bottom) {
                if let decision = viewModel.feedback {
                    FeedbackCard(isCorrect: decision.isCorrect,
                                 headline: DecisionFeedback.headline(for: decision),
                                 reason: DecisionFeedback.reason(for: decision),
                                 onWhy: { viewModel.showWhy(for: decision) },
                                 onNext: { viewModel.next() })
                        .transition(FeltMotion.panelTransition(reduceMotion: reduceMotion))
                }
            }
        case .outcome:
            VStack(spacing: FeltSpacing.m) {
                Text(StrategyText.dealerResult(viewModel.dealerHand))
                    .feltType(.title)
                    .foregroundStyle(FeltColor.textPrimary)
                    .accessibilityIdentifier("trainer.outcome")
                PrimaryButton(viewModel.session.isLastHand ? "See summary" : "Next hand") {
                    viewModel.nextHand()
                }
                .accessibilityIdentifier("trainer.nextHand")
            }
            .transition(FeltMotion.panelTransition(reduceMotion: reduceMotion))
        case .finished:
            EmptyView()
        }
    }
}
```

- [ ] **Step 3: Create the WHY sheet and the summary**

Create `BJS/Features/Strategy/WhySheet.swift`:

```swift
import BJSCore
import SwiftUI

/// The WHY sheet (spec §5): `WhyExplanation` for this exact hand, upcard and rules.
struct WhySheet: View {
    private let context: WhyContext

    @Environment(\.dismiss) private var dismiss

    init(context: WhyContext) {
        self.context = context
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.l) {
                VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                    HStack {
                        Text("Why")
                            .feltType(.label)
                            .foregroundStyle(FeltColor.textTertiary)
                        Spacer(minLength: FeltSpacing.s)
                        Button("Done") { dismiss() }
                            .feltType(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(FeltColor.textPrimary)
                            .frame(minWidth: FeltMetrics.minTapTarget, minHeight: FeltMetrics.minTapTarget)
                            .buttonStyle(FeltPressableStyle())
                            .accessibilityIdentifier("why.done")
                    }
                    Text(DecisionFeedback.spotTitle(context))
                        .feltType(.display)
                        .foregroundStyle(FeltColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("why.title")
                    Text("Rules: \(RulesSummary.short(context.rules))")
                        .feltType(.label)
                        .foregroundStyle(FeltColor.textSecondary)
                }
                StatChip(label: "Basic strategy", value: DecisionFeedback.actionName(context.correctAction))
                    .accessibilityIdentifier("why.play")
                Text(WhyExplanation.explain(context))
                    .feltType(.body)
                    .foregroundStyle(FeltColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("why.explanation")
            }
            .padding(FeltSpacing.l)
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(FeltRadius.sheet)
        .presentationBackground(FeltColor.feltBase)
    }
}
```

Create `BJS/Features/Strategy/StrategySummaryView.swift`:

```swift
import BJSCore
import SwiftUI

/// Session summary (spec §5): accuracy, mistakes, best streak, hands played, and the mean
/// decision time in Speed mode; each mistake opens its WHY sheet.
struct StrategySummaryView: View {
    private let viewModel: StrategyTrainerViewModel
    private let onDone: () -> Void

    @Environment(\.displayScale) private var displayScale

    init(viewModel: StrategyTrainerViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
    }

    var body: some View {
        let summary = viewModel.summary
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                    Text("\(viewModel.config.mode.displayName) · \(viewModel.config.filter.longName)")
                        .feltType(.label)
                        .foregroundStyle(FeltColor.textSecondary)
                    Text("Summary")
                        .feltType(.display)
                        .foregroundStyle(FeltColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("summary.title")
                }
                stats(summary)
                mistakes(summary)
                PrimaryButton("Done", action: onDone)
                    .accessibilityIdentifier("summary.done")
            }
            .padding(.horizontal, FeltSpacing.l)
            .padding(.vertical, FeltSpacing.xl)
        }
    }

    private func stats(_ summary: StrategySessionSummary) -> some View {
        Grid(horizontalSpacing: FeltSpacing.s, verticalSpacing: FeltSpacing.s) {
            GridRow {
                StatChip(label: "Accuracy", value: StrategyText.percent(summary.accuracy))
                    .accessibilityIdentifier("summary.accuracy")
                StatChip(label: "Mistakes", value: "\(summary.mistakeCount)")
                    .accessibilityIdentifier("summary.mistakes")
            }
            GridRow {
                StatChip(label: "Best streak", value: "\(summary.bestStreak)")
                    .accessibilityIdentifier("summary.bestStreak")
                StatChip(label: "Hands", value: "\(summary.handsPlayed)")
                    .accessibilityIdentifier("summary.hands")
            }
            if viewModel.config.mode.isTimed {
                GridRow {
                    StatChip(label: "Avg decision", value: StrategyText.seconds(fromMs: summary.meanResponseMs))
                        .accessibilityIdentifier("summary.meanTime")
                        .gridCellColumns(2)
                }
            }
        }
    }

    private func mistakes(_ summary: StrategySessionSummary) -> some View {
        SettingsSection("Mistakes") {
            if summary.mistakes.isEmpty {
                Text("No mistakes this session.")
                    .feltType(.body)
                    .foregroundStyle(FeltColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget, alignment: .leading)
                    .padding(.horizontal, FeltSpacing.l)
            } else {
                ForEach(summary.mistakes) { mistake in
                    mistakeRow(mistake, showsSeparator: mistake.sequence != summary.mistakes.last?.sequence)
                }
            }
        }
    }

    private func mistakeRow(_ mistake: GradedDecision, showsSeparator: Bool) -> some View {
        Button {
            viewModel.showWhy(for: mistake)
        } label: {
            HStack(spacing: FeltSpacing.m) {
                VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                    Text("Hand \(mistake.handNumber) · \(DecisionFeedback.spotTitle(mistake.cell))")
                        .feltType(.body)
                        .foregroundStyle(FeltColor.textPrimary)
                    Text(StrategyText.mistakeDetail(mistake))
                        .feltType(.body)
                        .foregroundStyle(FeltColor.textSecondary)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: FeltSpacing.s)
                Text("Why")
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textSecondary)
                Image(systemName: "chevron.right")
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textTertiary)
            }
            .padding(.horizontal, FeltSpacing.l)
            .padding(.vertical, FeltSpacing.s)
            .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget, alignment: .leading)
            .overlay(alignment: .bottom) {
                if showsSeparator {
                    // Same hairline as SettingsRow: textTertiary at 30%, one pixel.
                    Rectangle()
                        .fill(FeltColor.textTertiary.opacity(0.3))
                        .frame(height: 1 / displayScale)
                        .padding(.leading, FeltSpacing.l)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(FeltPressableStyle())
        .accessibilityHint("Shows why")
        .accessibilityIdentifier("summary.mistake.\(mistake.sequence)")
    }
}
```

- [ ] **Step 4: Create the session container**

Create `BJS/Features/Strategy/StrategySessionScreen.swift`:

```swift
import BJSCore
import SwiftData
import SwiftUI

/// One full-screen Strategy session (spec §5: sessions are presented full-screen over the tabs).
///
/// On appear it snapshots the active rules and the Speed timer, loads decision history for
/// Weak-spots mode, and builds the ViewModel with a SwiftData saver.
struct StrategySessionScreen: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(Preferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StrategyTrainerViewModel?

    private let config: StrategySessionConfig
    private let seed: UInt64?
    private let onClose: () -> Void

    /// - Parameter seed: a fixed seed (UI tests), or nil for a random one.
    init(config: StrategySessionConfig, seed: UInt64?, onClose: @escaping () -> Void) {
        self.config = config
        self.seed = seed
        self.onClose = onClose
    }

    var body: some View {
        Group {
            if let viewModel {
                StrategyTrainerView(viewModel: viewModel, onClose: onClose)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .feltBackground()
        .onAppear(perform: startIfNeeded)
    }

    private func startIfNeeded() {
        guard viewModel == nil else { return }
        let history = config.mode.usesWeakSpotWeights ? DecisionHistory.recentSamples(in: modelContext) : []
        viewModel = StrategyTrainerViewModel(config: config, rules: rulesStore.rules,
                                             speedTimerSeconds: preferences.speedTimerSeconds,
                                             history: history,
                                             seed: seed ?? UInt64.random(in: UInt64.min...UInt64.max),
                                             saver: SwiftDataStrategySessionSaver(context: modelContext))
    }
}
```

- [ ] **Step 5: Local pre-checks**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
swiftc -parse BJS/Features/Strategy/*.swift
grep -rn "Hub" BJS/Features/Strategy || echo "no hub references"
grep -rn "FeltColor\.\(brass\|correct\|incorrect\)" BJS/Features/Strategy || echo "no accent/feedback colours"
grep -rn "\.font(" BJS/Features/Strategy || echo "type via FeltType only"
```

Expected: no output from `swiftc`, then `no hub references`, `no accent/feedback colours` (brass reaches the screen only through `ActionDock`'s hint ring, and correct/incorrect only through the `FeedbackCard` badge), and `type via FeltType only`.

- [ ] **Step 6: Commit**

```bash
git add BJS/Features/Strategy/StrategySetupView.swift BJS/Features/Strategy/StrategyTrainerView.swift \
        BJS/Features/Strategy/WhySheet.swift BJS/Features/Strategy/StrategySummaryView.swift \
        BJS/Features/Strategy/StrategySessionScreen.swift
git commit -m "feat(strategy): setup, trainer, WHY sheet and summary screens

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller.

- [ ] **Step 7: CI verification (controller)**

Expected: green; 91 unit tests; 2 UI tests; 17 screenshots per device (nothing new is reachable yet).

These SwiftUI APIs are the ones most likely to need a `fix(strategy)`. Each has a same-look fallback:
- `TimelineView(.animation(minimumInterval:paused:))`: fall back to `.periodic(from: .now, by: 0.05)`.
- `.presentationBackground(FeltColor.feltBase)` / `.presentationCornerRadius(FeltRadius.sheet)`: both iOS 16.4+, so they should compile.
- `Bindable(wrappedValue:)`: fall back to `@Bindable var viewModel` with `self.viewModel = viewModel`.
- Isolation of the `.task` closure (it calls `viewModel.timeExpired(token:)`): fall back to wrapping the call in `await MainActor.run { … }`.

---

### Task 10: Route Strategy from the hub, present sessions full-screen, Continue

**Files:**
- Modify: `BJS/Features/Hub/HubView.swift`, `BJS/App/RootTabView.swift`, `BJS/App/BJSApp.swift`, `BJSUITests/DesignScreenshotTests.swift`

**Interfaces:**
- Consumes: Tasks 5 and 9 (`LastLaunchStore`, `LastLaunchText`, `LaunchConfiguration.strategySeed`, `StrategySetupView`, `StrategySessionScreen`)
- Produces:
  - `HubView(onShowRules:onContinue:destination:)`: shows `hub.continue` (+ `hub.continueDetail`) between the stat chips and the tiles once `lastLaunch` exists
  - `struct ActiveSession: Identifiable, Equatable { id; strategy: StrategySessionConfig }`
  - `RootTabView(strategySeed: UInt64? = nil)`:
    - the `.strategy` route shows `StrategySetupView` (prefilled from `lastLaunch`); the other routes stay placeholders
    - Start and Continue record `lastLaunch` and present `StrategySessionScreen` with `.fullScreenCover`
  - `BJSApp` creates and injects `LastLaunchStore` (the UI-test defaults suite is wiped, so Continue is hidden on a UI-test launch) and passes `launch.strategySeed`

- [ ] **Step 1: Add Continue to the hub**

Replace `BJS/Features/Hub/HubView.swift` with:

```swift
import BJSCore
import SwiftData
import SwiftUI

/// Train tab (spec §5 Hub): rules summary, stat chips, Continue, module tiles.
///
/// Continue is hidden until a session has been started (first launch). `onContinue` and
/// `destination` are supplied by the App layer, so the Hub never names another feature.
struct HubView<Destination: View>: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(LastLaunchStore.self) private var lastLaunchStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var sessions: [Session]
    @Query private var decisions: [DecisionRecord]
    @State private var path: [HubRoute] = []

    private let onShowRules: () -> Void
    private let onContinue: (LastLaunch) -> Void
    private let destination: (HubRoute) -> Destination

    init(onShowRules: @escaping () -> Void, onContinue: @escaping (LastLaunch) -> Void,
         @ViewBuilder destination: @escaping (HubRoute) -> Destination) {
        self.onShowRules = onShowRules
        self.onContinue = onContinue
        self.destination = destination
    }

    private var stats: HubStats {
        HubStats.make(sessions: ProgressMapper.sessionSamples(sessions),
                      decisions: ProgressMapper.decisionSamples(decisions),
                      now: .now)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                    header
                    statChips
                    if let launch = lastLaunchStore.lastLaunch {
                        continueButton(launch)
                    }
                    tiles
                }
                .padding(.horizontal, FeltSpacing.l)
                .padding(.vertical, FeltSpacing.xl)
            }
            .feltBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HubRoute.self) { route in
                destination(route)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            Button(action: onShowRules) {
                HStack(spacing: FeltSpacing.xs) {
                    Text(RulesSummary.short(rulesStore.rules))
                    Image(systemName: "chevron.right")
                }
                .feltType(.label)
                .foregroundStyle(FeltColor.textSecondary)
                .frame(minHeight: FeltMetrics.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(FeltPressableStyle())
            .accessibilityLabel("Table rules: \(RulesSummary.short(rulesStore.rules))")
            .accessibilityHint("Opens Settings")
            .accessibilityIdentifier("hub.rulesSummary")

            Text("Train")
                .feltType(.display)
                .foregroundStyle(FeltColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("hub.title")
        }
    }

    private var statChips: some View {
        let current = stats
        return HStack(alignment: .top, spacing: FeltSpacing.s) {
            StatChip(label: "Strategy 30d", value: HubStats.percentText(current.strategyAccuracy))
            StatChip(label: "Count 30d", value: HubStats.percentText(current.countAccuracy))
            StatChip(label: "Streak", value: "\(current.strategyStreak)")
        }
    }

    private func continueButton(_ launch: LastLaunch) -> some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            PrimaryButton(LastLaunchText.title(launch)) {
                onContinue(launch)
            }
            .accessibilityIdentifier("hub.continue")
            if let detail = LastLaunchText.detail(launch) {
                Text(detail)
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textSecondary)
                    .padding(.horizontal, FeltSpacing.xs)
                    .accessibilityIdentifier("hub.continueDetail")
            }
        }
    }

    @ViewBuilder
    private var tiles: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: FeltSpacing.m) {
                ForEach(HubRoute.allCases) { route in
                    tile(route)
                }
            }
        } else {
            Grid(horizontalSpacing: FeltSpacing.m, verticalSpacing: FeltSpacing.m) {
                GridRow {
                    tile(.strategy)
                    tile(.counting)
                }
                GridRow {
                    tile(.shoeSim)
                    tile(.edge)
                }
            }
        }
    }

    private func tile(_ route: HubRoute) -> some View {
        ModuleTile(title: route.title, subtitle: route.subtitle) {
            path.append(route)
        }
        .accessibilityIdentifier("hub.tile.\(route.rawValue)")
    }
}
```

- [ ] **Step 2: Wire the routes and the full-screen session**

Replace `BJS/App/RootTabView.swift` with:

```swift
import BJSCore
import SwiftUI

/// The three top-level tabs (spec §5 Navigation).
enum AppTab: String, CaseIterable, Identifiable {
    case train = "Train"
    case progress = "Progress"
    case settings = "Settings"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .train: return "suit.spade.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape"
        }
    }
}

/// A training session presented full-screen over the tabs.
struct ActiveSession: Identifiable, Equatable {
    let id = UUID()
    let strategy: StrategySessionConfig
}

/// The composition root for navigation: it is the only place that knows which screen
/// each hub route and tab shows, and it presents training sessions full-screen.
struct RootTabView: View {
    @Environment(LastLaunchStore.self) private var lastLaunchStore
    @State private var selection: AppTab = .train
    @State private var activeSession: ActiveSession?

    /// A fixed seed for Strategy sessions (UI tests), or nil.
    private let strategySeed: UInt64?

    init(strategySeed: UInt64? = nil) {
        self.strategySeed = strategySeed
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab(AppTab.train.rawValue, systemImage: AppTab.train.systemImage, value: AppTab.train) {
                HubView(onShowRules: { selection = .settings },
                        onContinue: { launch in continueLast(launch) }) { route in
                    destination(for: route)
                }
                .feltTabBar()
            }
            Tab(AppTab.progress.rawValue, systemImage: AppTab.progress.systemImage, value: AppTab.progress) {
                PlaceholderScreen(title: AppTab.progress.rawValue)
                    .feltTabBar()
            }
            Tab(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage, value: AppTab.settings) {
                SettingsView()
                    .feltTabBar()
            }
        }
        .tint(FeltColor.cream)
        .fullScreenCover(item: $activeSession) { session in
            StrategySessionScreen(config: session.strategy, seed: strategySeed) {
                activeSession = nil
            }
        }
    }

    @ViewBuilder
    private func destination(for route: HubRoute) -> some View {
        switch route {
        case .strategy:
            StrategySetupView(initial: lastLaunchStore.lastLaunch?.strategy) { config in
                startStrategy(config)
            }
        case .counting, .shoeSim, .edge:
            PlaceholderScreen(title: route.title)
        }
    }

    private func startStrategy(_ config: StrategySessionConfig) {
        lastLaunchStore.record(.forStrategy(config))
        activeSession = ActiveSession(strategy: config)
    }

    /// Continue relaunches the last module and mode with its last setup, skipping setup.
    private func continueLast(_ launch: LastLaunch) {
        switch launch.module {
        case .strategy:
            if let config = launch.strategy { startStrategy(config) }
        case .countingRC, .countingTC, .shoe:
            break   // Steps 4 and 7 add these modules.
        }
    }
}

private extension View {
    /// Tab bar on `feltDeep` (spec §4: "tab bar base").
    func feltTabBar() -> some View {
        toolbarBackground(FeltColor.feltDeep, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}
```

Replace `BJS/App/BJSApp.swift` with:

```swift
import SwiftData
import SwiftUI

@main
struct BJSApp: App {
    private let launch: LaunchConfiguration
    private let modelContainer: ModelContainer
    @State private var rulesStore: ActiveRulesStore
    @State private var preferences: Preferences
    @State private var lastLaunchStore: LastLaunchStore

    init() {
        let launch = LaunchConfiguration.current
        let defaults = launch.makeUserDefaults()
        self.launch = launch
        self.modelContainer = PersistenceController.makeAppContainer(inMemory: launch.isUITesting)
        self._rulesStore = State(initialValue: ActiveRulesStore(defaults: defaults))
        self._preferences = State(initialValue: Preferences(defaults: defaults))
        self._lastLaunchStore = State(initialValue: LastLaunchStore(defaults: defaults))
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environment(rulesStore)
                .environment(preferences)
                .environment(lastLaunchStore)
                .preferredColorScheme(.dark)
                .tint(FeltColor.cream)
        }
        .modelContainer(modelContainer)
    }

    #if DEBUG
    @ViewBuilder
    private var rootView: some View {
        if let name = launch.galleryPageName, let page = GalleryPage(rawValue: name) {
            ComponentGalleryView(page: page)
        } else {
            RootTabView(strategySeed: launch.strategySeed)
        }
    }
    #else
    private var rootView: some View {
        RootTabView(strategySeed: launch.strategySeed)
    }
    #endif
}
```

- [ ] **Step 3: Keep the design walk working**

The Strategy tile no longer opens a placeholder. In `BJSUITests/DesignScreenshotTests.swift`, `testHubPlaceholderAndSettings`, replace:

```swift
        app.buttons["hub.tile.strategy"].tap()
        XCTAssertTrue(app.staticTexts["placeholder.title"].waitForExistence(timeout: 5))
        snapshot("02-placeholder-strategy")
```

with:

```swift
        // Strategy now opens its setup screen (StrategySessionUITests); Counting is still a placeholder.
        app.buttons["hub.tile.counting"].tap()
        XCTAssertTrue(app.staticTexts["placeholder.title"].waitForExistence(timeout: 5))
        snapshot("02-placeholder-counting")
```

- [ ] **Step 4: Local pre-checks**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
swiftc -parse BJS/App/*.swift BJS/Features/Hub/*.swift BJSUITests/DesignScreenshotTests.swift
grep -rnE "Strategy[A-Z]" BJS/Features/Hub || echo "hub names no strategy types"
```

Expected: no output from `swiftc`; `hub names no strategy types` (the Hub names no `Strategy…` feature or BJSCore type; `HubRoute.strategy` and its "Strategy" title are the Hub's own).

- [ ] **Step 5: Commit**

```bash
git add BJS/Features/Hub/HubView.swift BJS/App/RootTabView.swift BJS/App/BJSApp.swift BJSUITests/DesignScreenshotTests.swift
git commit -m "feat(app): route Strategy from the hub, full-screen sessions and Continue

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller.

- [ ] **Step 6: CI verification (controller)**

Expected: green; 91 unit tests; both UI tests pass (the design walk now opens the Counting placeholder); `Exported 17 screenshots` per device, with `02-placeholder-counting` in place of `02-placeholder-strategy`.

---

### Task 11: Strategy UI test and Strategy design screenshots

**Files:**
- Create: `BJSUITests/StrategySessionUITests.swift`

**Interfaces:**
- Consumes: Task 10's wiring and the identifiers listed in Task 9; `BJS_UI_TESTING`, `BJS_STRATEGY_SEED`
- Produces:
  - `testFiveHandStrategySession` (spec §7): launch → hub (no Continue) → Strategy setup → Endless → Start → 5 hands in Learn mode → End → summary shows 5 hands → Done → back to the hub, where Continue now shows → Continue starts the trainer → ✕ closes at once (nothing graded)
  - `testSpeedTimeoutSavePartialAndMistakeWhy`: Speed → no input → the 3 s timeout gives "Time's up" feedback → ✕ → alert → Save partial → summary with Avg decision → mistake row → WHY
  - screenshots `30-strategy-setup` … `41-strategy-why-mistake` (12 per device)

The test plays whatever the seed deals: the Learn ring ("Suggested") if present, otherwise the first enabled dock button. It waits for each transition (`waitForExistence` / "exists == false" expectations) and never taps a disappearing element.

- [ ] **Step 1: Write the UI test**

Create `BJSUITests/StrategySessionUITests.swift`:

```swift
import XCTest

/// Spec §7 UI test: launch → hub → 5-hand Strategy session → summary visible. The walk also
/// attaches the Strategy design-check screenshots (setup, trainer with hint, FeedbackCard,
/// WHY sheet, outcome, summary, Continue, Speed countdown and timeout, leave prompt, mistake WHY).
///
/// Hands come from a fixed seed (`BJS_STRATEGY_SEED`), but the test never assumes which
/// hands: it plays by reading the dock — the brass-ringed ("Suggested") button in Learn
/// mode, otherwise the first enabled one.
final class StrategySessionUITests: XCTestCase {

    private static let seed = "20260924"
    private static let dockActions = ["stand", "hit", "double", "split", "surrender"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["BJS_UI_TESTING"] = "1"
        app.launchEnvironment["BJS_STRATEGY_SEED"] = Self.seed
        app.launch()
        return app
    }

    @MainActor
    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// The first of `elements` that exists within `timeout` (polling every 0.1 s).
    @MainActor
    private func firstExisting(_ elements: [XCUIElement], timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if let found = elements.first(where: { $0.exists }) { return found }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return nil
    }

    @MainActor
    private func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element)
        wait(for: [gone], timeout: timeout)
    }

    /// Learn mode's ringed button if there is one, else the first enabled dock button.
    @MainActor
    private func dockChoice(in app: XCUIApplication) -> XCUIElement? {
        let enabled = Self.dockActions
            .map { app.buttons["action.\($0)"] }
            .filter { $0.exists && $0.isEnabled }
        return enabled.first { ($0.value as? String) == "Suggested" } ?? enabled.first
    }

    @MainActor
    private func openStrategySetup(_ app: XCUIApplication) {
        let tile = app.buttons["hub.tile.strategy"]
        XCTAssertTrue(tile.waitForExistence(timeout: 15))
        tile.tap()
        XCTAssertTrue(app.staticTexts["strategy.setup.title"].waitForExistence(timeout: 5))
    }

    /// Plays until `hands` hands have reached their outcome; returns with that outcome showing.
    /// With `snapshots`, attaches the decision, feedback, WHY and outcome screenshots once each.
    @MainActor
    private func play(hands: Int, in app: XCUIApplication, snapshots: Bool) {
        let next = app.buttons["feedback.next"]
        let nextHand = app.buttons["trainer.nextHand"]
        let stand = app.buttons["action.stand"]
        var completed = 0
        var tookDecision = !snapshots
        var tookFeedback = !snapshots

        for _ in 0..<150 {
            guard let element = firstExisting([next, nextHand, stand], timeout: 10) else {
                XCTFail("Neither feedback, an outcome nor the dock appeared")
                return
            }
            switch element.identifier {
            case "feedback.next":
                if !tookFeedback {
                    tookFeedback = true
                    snapshot("32-strategy-feedback")
                    app.buttons["feedback.why"].tap()
                    XCTAssertTrue(app.staticTexts["why.title"].waitForExistence(timeout: 5))
                    snapshot("33-strategy-why")
                    app.buttons["why.done"].tap()
                    waitUntilGone(app.staticTexts["why.title"])
                }
                next.tap()
                waitUntilGone(next)
            case "trainer.nextHand":
                completed += 1
                if completed == 1 && snapshots { snapshot("34-strategy-outcome") }
                if completed == hands { return }
                nextHand.tap()
                waitUntilGone(nextHand)
            default:
                // The dock: while feedback is still animating in, every button is disabled.
                guard let choice = dockChoice(in: app) else {
                    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
                    continue
                }
                if !tookDecision {
                    tookDecision = true
                    snapshot("31-strategy-decision")
                }
                choice.tap()
                XCTAssertTrue(next.waitForExistence(timeout: 5), "every decision shows feedback")
            }
        }
        XCTFail("Did not finish \(hands) hands in 150 steps")
    }

    // MARK: - Tests

    /// Spec §7: launch → hub → 5-hand Strategy session → summary visible; then Continue.
    @MainActor
    func testFiveHandStrategySession() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["hub.tile.strategy"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["hub.continue"].exists, "Continue is hidden on first launch")

        openStrategySetup(app)
        app.buttons["Endless"].tap()
        snapshot("30-strategy-setup")
        app.buttons["strategy.start"].tap()
        XCTAssertTrue(app.staticTexts["trainer.progress"].waitForExistence(timeout: 10))

        play(hands: 5, in: app, snapshots: true)

        app.buttons["trainer.end"].tap()
        XCTAssertTrue(app.staticTexts["summary.title"].waitForExistence(timeout: 5))
        let hands = app.descendants(matching: .any)["summary.hands"]
        XCTAssertTrue(hands.exists)
        XCTAssertTrue(hands.label.contains("5"), "summary shows 5 hands: \(hands.label)")
        snapshot("35-strategy-summary")

        // Done returns to setup; the hub now offers Continue with the same setup.
        app.buttons["summary.done"].tap()
        XCTAssertTrue(app.staticTexts["strategy.setup.title"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let continueButton = app.buttons["hub.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertTrue(continueButton.label.contains("Strategy"))
        snapshot("36-hub-continue")

        // Continue starts the trainer straight away; closing before any decision just closes.
        continueButton.tap()
        XCTAssertTrue(app.staticTexts["trainer.progress"].waitForExistence(timeout: 10))
        app.buttons["trainer.close"].tap()
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
    }

    /// Speed timeout, the leave prompt with Save partial, and a mistake's WHY from the summary.
    @MainActor
    func testSpeedTimeoutSavePartialAndMistakeWhy() throws {
        let app = launchApp()
        openStrategySetup(app)
        app.buttons["Speed"].tap()
        app.buttons["strategy.start"].tap()
        XCTAssertTrue(app.staticTexts["trainer.progress"].waitForExistence(timeout: 10))
        snapshot("37-strategy-speed")

        // Do nothing: the default 3 s countdown runs out and records a timeout.
        let next = app.buttons["feedback.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        let timeUp = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Time's up")).firstMatch
        XCTAssertTrue(timeUp.exists)
        snapshot("38-strategy-timeout")

        // Leaving with a graded decision asks first.
        app.buttons["trainer.close"].tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        snapshot("39-strategy-leave")
        alert.buttons["Save partial"].tap()

        XCTAssertTrue(app.staticTexts["summary.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["summary.meanTime"].exists)
        snapshot("40-strategy-summary-speed")

        let mistake = app.buttons["summary.mistake.1"]
        XCTAssertTrue(mistake.waitForExistence(timeout: 5))
        mistake.tap()
        XCTAssertTrue(app.staticTexts["why.title"].waitForExistence(timeout: 5))
        snapshot("41-strategy-why-mistake")
        app.buttons["why.done"].tap()
        waitUntilGone(app.staticTexts["why.title"])
        app.buttons["summary.done"].tap()
        XCTAssertTrue(app.staticTexts["strategy.setup.title"].waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 2: Local pre-checks**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
swiftc -parse BJSUITests/StrategySessionUITests.swift
grep -o '"[a-z]*\.[a-zA-Z.]*"' BJSUITests/StrategySessionUITests.swift | sort -u
```

Expected: no output from `swiftc`, then the list `"action.stand" "feedback.next" "feedback.why" "hub.continue" "strategy.start" "summary.done" "summary.hands" "summary.meanTime" "summary.title" "trainer.close" "trainer.end" "trainer.nextHand" "trainer.progress" "why.done" "why.title"` (one per line). Check that each identifier is set in `BJS/`:

```bash
for id in $(grep -o '"[a-z]*\.[a-zA-Z]*"' BJSUITests/StrategySessionUITests.swift | tr -d '"' | sort -u); do
  grep -rq "\"$id" BJS || echo "missing $id"
done
```

Expected: only `missing action.stand`. `ActionDock` builds `action.<raw value>` by interpolation, and so do `summary.mistake.<n>` and `hub.tile.<route>`; check those three by eye.

- [ ] **Step 3: Commit**

```bash
git add BJSUITests/StrategySessionUITests.swift
git commit -m "test(strategy): 5-hand session UI test and Strategy design screenshots

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller.

- [ ] **Step 4: CI verification (controller)**

Expected: green; 91 unit tests; **4 UI tests** passing on both iPhone 16 and iPhone SE; `Exported 29 screenshots` per device. This run meets the §8 "done when" for Step 3: the Strategy UI test and the STAND regression test (Task 7) are green.

If a UI test fails, fetch the `xcresults` artifact. The usual causes, with their fixes:
- An element is found but not hittable. Add `waitUntilGone`/`waitForExistence` around the transition.
- The WHY sheet's Done is off-screen on SE. It sits at the top of the sheet by design; check that the medium detent has not scrolled it out of view.
- The alert title differs on iOS 26. Use `app.alerts.firstMatch`, as the test already does.

Fix forward in `fix(strategy)` or `test(strategy)`, never by weakening the §7 assertions: the 5 hands are played, and the summary is visible.

---

### Task 12: Design check for the Strategy screens and the Step 3 handoff

**Files:**
- Modify: `docs/superpowers/progress.md`

The controller does this task: it needs the CI artifact and image viewing.

- [ ] **Step 1: Get the screenshots**

From the green run of Task 11, download the `design-screenshots` artifact: `gh run download <run-id> --name design-screenshots --dir /tmp/design-check`, or the artifact's `archive_download_url` from the GitHub API. In Step 2 the blob host was blocked from the cloud container. If it still is, ask Luke to download the artifact from the run's Summary page, and hand him the checklist below.

- [ ] **Step 2: Compare every Strategy screenshot against spec §4/§5 and the Decisions above**

This is a conformance check, not a redesign. A mismatch is fixed only when the code does not do what §4, §5 or the Decisions say, in a `fix(strategy)` commit with its own CI run.

| # | Check | Where |
|---|---|---|
| 1 | Setup: rules label, "Strategy" in `display`, three ModePickers (Mode: 4 segments, "Weak spots" readable on SE), mode description line, cream Start button | 30 |
| 2 | Trainer (Learn): top bar ✕ / "Hand 1" over "Learn" / End; dealer upcard + card back; player hand + total; dock rows STAND HIT / SPLIT DOUBLE SURRENDER; **brass ring on exactly one button**; dimmed buttons at 40% | 31 |
| 3 | Feedback: cream card over the dock, badge straddling the top edge (✓ `correct` / ✕ `incorrect`), headline + one-line reason, WHY + NEXT; **the dealer's hole card is still face down** | 32, 38 |
| 4 | WHY sheet: `feltBase`, radius 16, "Why" + Done, spot title in `display`, rules line, "Basic strategy" chip, explanation text | 33, 41 |
| 5 | Outcome: hole card face up, dealer total, per-hand result under the hand, "Dealer has N" / "Dealer busts" in `title`, cream "Next hand" | 34 |
| 6 | Summary: "Summary" in `display`, four StatChips (plus "Avg decision" spanning both columns in Speed only), Mistakes panel (rows with hairlines, "Why ›"), Done | 35, 40 |
| 7 | Hub after a session: Continue `PrimaryButton` + detail line between the chips and the tiles; tiles still 2 × 2 | 36 (and 01: **no** Continue on first launch) |
| 8 | Speed: countdown bar (cream on inset, 8 pt capsule) under the top bar; no brass ring | 37 |
| 9 | Leave alert: Save partial, Discard (destructive), Keep playing | 39 |
| 10 | Gallery countdown page: full / half / nearly out / empty bars | 20 |
| 11 | `brass` only on the hint ring; `correct`/`incorrect` only on the badge; type only from the §4 roles; nothing clipped on iPhone SE that is whole on iPhone 16 | all |
| 12 | Step 2 screens unchanged apart from `02-placeholder-counting` | 01–19 |
| 13 | `ContrastTests` passed in the same run | CI log |

- [ ] **Step 3: Append the Step 3 handoff to `docs/superpowers/progress.md`**

Use the real values (the commit range from `git log --oneline`, the run URL, test counts and device names):

```markdown

## Step 3 — Strategy (YYYY-MM-DD)

- Commits: <first-sha>..<last-sha> (branch `main-8v0ds1`; plan `docs/superpowers/plans/2026-09-24-step-3-strategy.md`).
- CI: run <url> green. It ran:
  - BJSCore: 228 tests;
  - app unit tests: 91 (Swift Testing), including "STAND always produces feedback before the next hand" for all four modes;
  - UI tests: 4 (XCTest), including the spec §7 "5-hand Strategy session → summary", on <iPhone 16 device> and <iPhone SE device>;
  - screenshots: 29 per device.
- Design check: checklist 1–13 in Task 12 of the plan: <all pass | deviations and their fix commits>. Contrast test green.
- Added:
  - BJSCore: `StrategySessionConfig` (`StrategyMode`, `StrategySessionLength`), `DecisionChoice`, `GradedDecision`, `WhyContext(spot:…)`, `StrategySessionSummary`, `StrategySession` (the trainer state machine) and `DecisionFeedback`.
  - App: `LastLaunch` + `LastLaunchStore` (the `lastLaunch` key); `StrategySessionSaving` + `SwiftDataStrategySessionSaver` + `DecisionHistory`; `CountdownBar` (a new component, existing tokens); the `Features/Strategy` setup, trainer, WHY sheet, summary and ViewModel; hub Continue; full-screen sessions from `RootTabView`.
  - `scripts/dev/linux_app_check.sh`: runs Linux-safe app files and their Swift Testing suites locally.
- Decisions for Luke: the plan's "Decisions this plan makes", especially:
  - #1: the engine grades hard 16 vs 10 (6D S17, no surrender) as STAND, which disagrees with the WoO chart (hit). A `fix(core)` needs his decision.
  - #2/#4: the feedback → outcome → next-hand flow.
  - #6: the leave behaviour.
  - #15: the new visual pieces.
- Notes for Step 4:
  - Reuse the ViewModel pattern: a BJSCore state machine plus a thin `@MainActor @Observable` adapter with an injected clock and saver, checked on Linux with `scripts/dev/linux_app_check.sh`.
  - Continue: add a `counting` setup field to `LastLaunch` and a case in `RootTabView.continueLast`.
  - Sessions present through `RootTabView.activeSession`: turn `ActiveSession` into an enum or add a module field.
- Next: Step 4 (Counting) in a fresh session. Step 5 (Edge) can run in parallel.
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/progress.md
git commit -m "docs: Step 3 handoff

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
git push origin main-8v0ds1
```

- [ ] **Step 5: Report to Luke**

Send the run link, the `design-screenshots` artifact, the checklist result, and Decision 1 (hard 16 vs 10) with a recommendation to open a `fix(core)` task that re-validates the stiff-hand rows against Wizard of Odds.

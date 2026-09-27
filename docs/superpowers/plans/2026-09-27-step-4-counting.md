# Step 4 — Counting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Counting module: the running count (RC) drill, the true count (TC) drill, the card values reference with its self-test, and persistence of RC/TC sessions.

**Architecture:** BJSCore gains the pure drill logic: TC question steps and cap, convention targets, the RC card trace, and scoring. The app gets a `Features/Counting` folder. `CountingFlowView` hosts a menu → setup → drill → summary flow. Each drill has its own `@Observable` phase-machine ViewModel with an injected RNG and clock. The drill views reuse the frozen Felt components (`FeedbackCard`, `CountKeypad`, `PlayingCard`, `StatChip`, `ModePicker`, `SettingsRow`, `FeltToast`), plus one new component, `DiscardTray`.

**Tech Stack:** Swift 6.2, SwiftUI, iOS 18+, SwiftData (existing `SchemaV1`, unchanged), Swift Testing, XCTest (UI), XcodeGen.

**Spec:** `docs/superpowers/specs/2026-09-27-step-4-counting-design.md`. Parent spec: `docs/superpowers/specs/2026-09-23-bjs-rebuild-design.md` (§4 design system, §5 Counting, §6 data, §7 testing). Read both before starting.

## Global Constraints

- All game logic lives in `BJSCore`, which never imports SwiftUI or SwiftData. ViewModels are thin `@Observable` adapters.
- Feature folders never import each other. `Features/Counting` must not use anything defined in `Features/Strategy`. Shared code goes in `Design/`, `Shared/`, `Persistence/` or `BJSCore`.
- Randomness is injectable: take a seed or an `inout` RNG. Tests use `SeededRandomNumberGenerator`.
- XcodeGen owns the project. After adding or removing files, run `xcodegen generate`. Never edit `.xcodeproj`.
- The Felt design system is **frozen**:
  - don't change any existing token or component in `BJS/Design/Tokens` or `BJS/Design/Components`;
  - `DiscardTray` is the only new component, built from existing tokens;
  - adding a section to the DEBUG `FeltCatalogue` is allowed.
- The app target is main-actor by default (`SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor`). A `Shape` must be marked `nonisolated`.
- Swift Testing (`@Test`, `#expect`) for unit tests; XCTest only for UI tests. App test suites are marked `@MainActor`.
- No schema change. RC sessions are `module: .countingRC, mode: nil`. TC sessions are `module: .countingTC`, with `mode` = the convention's raw value.
- System `confirmationDialog`s keep iOS styling (an accepted exception).
- Commit after each task with a conventional prefix and a scope: `feat(core)`, `feat(counting)`, `test(counting)`, `refactor(app)`, `docs`. End every commit message with:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
- **Commands:**
  - Engine tests: `cd BJSCore && swift test`. BJSCore has 229 tests today, and they must stay green.
  - App tests: always redirect `xcodebuild` to a log file and grep it afterwards. Piping it straight into `grep | head` can hang.

    ```bash
    xcodegen generate
    xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:BJSTests/<SuiteName> > "$TMPDIR/bjs-test.log" 2>&1; grep -E "✔|✘|error:|\*\* TEST" "$TMPDIR/bjs-test.log" | tail -40
    ```

  - Full app run: the same command without `-only-testing`. The app has 133 unit tests and 2 UI tests today.

## File map

**BJSCore**
- Modify: `BJSCore/Sources/BJSCore/Counting/CountDrills.swift`. Adds TC steps and cap, `target(for:)`, `keypadAnswer(for:)`, the public `RunningCountDrill.init`, `trace(throughGroup:)` and `CountTraceEntry`.
- Create: `BJSCore/Sources/BJSCore/Counting/CountDrillScore.swift`
- Modify: `BJSCore/Tests/BJSCoreTests/CountingTests/CountDrillTests.swift`
- Create: `BJSCore/Tests/BJSCoreTests/CountingTests/CountDrillScoreTests.swift`

**App**
- Create: `BJS/Shared/CloseButton.swift`. This moves `CloseButton` out of `Features/Strategy/StrategySetupView.swift`.
- Modify: `BJS/Features/Strategy/StrategySetupView.swift`, `StrategyTrainerView.swift` and `WhySheet.swift`. They pass `identifier: "strategy.close"`.
- Create in `BJS/Features/Counting/`:
  - `CountingSetup.swift`: setups, lengths, `CountingSetup`
  - `CountingText.swift`: all copy and number formatting
  - `GradedCount.swift`: `GradedCount`, `CountSummaryRow`, `CountSummaryModel`
  - `RunningCountDrillViewModel.swift`
  - `TrueCountDrillViewModel.swift`
  - `CardValuesViewModel.swift`
  - `RunningCountDrillView.swift`, `CountTraceSheet.swift`, `CountSummaryView.swift`
  - `TrueCountDrillView.swift`, `TrueCountWorkingSheet.swift`
  - `CardValuesView.swift`
  - `CountingHeader.swift`, `CountingMenuView.swift`, `RunningCountSetupView.swift`, `TrueCountSetupView.swift`, `CountingFlowView.swift`
- Create: `BJS/Design/Components/DiscardTray.swift`. Modify: `BJS/Design/Catalogue/FeltCatalogue.swift`.
- Modify: `BJS/App/ModuleHost.swift` and `BJS/App/LaunchConfiguration.swift`.

**App tests**
- Create in `BJSTests/Features/`:
  - `CountingSetupTests.swift`
  - `CountingTextTests.swift`
  - `RunningCountDrillViewModelTests.swift`
  - `TrueCountDrillViewModelTests.swift`
  - `CardValuesViewModelTests.swift`
- Create: `BJSTests/Design/CountingComponentTests.swift`.
- Modify: `BJSTests/AppShellTests.swift` and `BJSTests/Persistence/SessionStoreTests.swift`.
- Create: `BJSUITests/CountingUITests.swift`.

---

### Task 1: TC question steps, cap, and convention targets (BJSCore)

**Files:**
- Modify: `BJSCore/Sources/BJSCore/Counting/CountDrills.swift`
- Test: `BJSCore/Tests/BJSCoreTests/CountingTests/CountDrillTests.swift`

**Interfaces:**
- Produces:
  - `CountDrillGenerator.maxTrueCountMagnitude: Double` (10)
  - `CountDrillGenerator.trueCountStep(deckCount: Int) -> Double`
  - `CountDrillGenerator.trueCountQuestion(deckCount:using:)`, same signature, new behaviour
  - `TrueCountQuestion.target(for: TrueCountConvention) -> Double`
  - `TrueCountQuestion.keypadAnswer(for: TrueCountConvention) -> Double`

- [ ] **Step 1: Replace the old question-shape test with failing tests**

In `CountDrillTests.swift`, delete the whole `trueCountQuestionShape()` test, from `@Test("True count questions have half-deck steps within the shoe")` to its closing brace. Add these tests inside the suite:

```swift
    @Test("True count questions step in quarter decks for 1–2 decks and half decks otherwise",
          arguments: [(1, 0.25), (2, 0.25), (6, 0.5), (8, 0.5)])
    func trueCountSteps(deckCount: Int, step: Double) {
        #expect(CountDrillGenerator.trueCountStep(deckCount: deckCount) == step)
        var rng = SeededRandomNumberGenerator(seed: UInt64(deckCount))
        var seen = Set<Double>()
        for _ in 0..<2000 {
            let q = CountDrillGenerator.trueCountQuestion(deckCount: deckCount, using: &rng)
            #expect(q.decksRemaining >= step && q.decksRemaining <= Double(deckCount) - step)
            #expect((q.decksRemaining / step).rounded() == q.decksRemaining / step)
            #expect((-12...12).contains(q.runningCount))
            #expect(abs(q.exactTrueCount) <= CountDrillGenerator.maxTrueCountMagnitude + 1e-9)
            seen.insert(q.decksRemaining)
        }
        // Every step from one step to one step short of the full shoe appears.
        #expect(seen.count == Int((Double(deckCount) / step).rounded()) - 1)
    }

    @Test("The TC cap keeps small-deck questions sane but still allows big counts in a shoe")
    func trueCountCap() {
        var single = SeededRandomNumberGenerator(seed: 11)
        for _ in 0..<500 {
            let q = CountDrillGenerator.trueCountQuestion(deckCount: 1, using: &single)
            if q.decksRemaining == 0.25 { #expect(abs(q.runningCount) <= 2) }
        }
        var shoe = SeededRandomNumberGenerator(seed: 12)
        var sawBig = false
        for _ in 0..<500 where abs(CountDrillGenerator.trueCountQuestion(deckCount: 6, using: &shoe).runningCount) >= 10 {
            sawBig = true
        }
        #expect(sawBig)
    }

    @Test("Target per convention, including negatives")
    func targets() {
        let q = TrueCountQuestion(runningCount: 7, decksRemaining: 3)      // +2.333…
        #expect(abs(q.target(for: .exact) - 7.0 / 3) < 1e-12)
        #expect(q.target(for: .floor) == 2)
        #expect(q.target(for: .truncate) == 2)
        let n = TrueCountQuestion(runningCount: -7, decksRemaining: 3)     // −2.333…
        #expect(n.target(for: .floor) == -3)
        #expect(n.target(for: .truncate) == -2)
    }

    @Test("Keypad answer: nearest half under Exact, the target otherwise")
    func keypadAnswers() {
        #expect(TrueCountQuestion(runningCount: 7, decksRemaining: 3).keypadAnswer(for: .exact) == 2.5)
        #expect(TrueCountQuestion(runningCount: -7, decksRemaining: 3).keypadAnswer(for: .exact) == -2.5)
        #expect(TrueCountQuestion(runningCount: 7, decksRemaining: 3).keypadAnswer(for: .floor) == 2)
        #expect(TrueCountQuestion(runningCount: -7, decksRemaining: 3).keypadAnswer(for: .truncate) == -2)
    }

    @Test("The keypad answer is always graded correct", arguments: TrueCountConvention.allCases)
    func keypadAnswerIsCorrect(convention: TrueCountConvention) {
        var rng = SeededRandomNumberGenerator(seed: 13)
        for deckCount in [1, 2, 6, 8] {
            for _ in 0..<500 {
                let q = CountDrillGenerator.trueCountQuestion(deckCount: deckCount, using: &rng)
                #expect(q.isCorrect(q.keypadAnswer(for: convention), convention: convention))
            }
        }
    }
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `cd BJSCore && swift test --filter CountDrillTests`
Expected: compile errors. `trueCountStep`, `maxTrueCountMagnitude`, `target(for:)` and `keypadAnswer(for:)` don't exist yet.

- [ ] **Step 3: Implement**

In `CountDrills.swift`, add these two methods inside `TrueCountQuestion`, after `exactTrueCount`:

```swift
    /// The value a convention grades against: exact RC ÷ decks, rounded down, or rounded toward zero.
    public func target(for convention: TrueCountConvention) -> Double {
        switch convention {
        case .exact: return exactTrueCount
        case .floor: return exactTrueCount.rounded(.down)
        case .truncate: return exactTrueCount.rounded(.towardZero)
        }
    }

    /// What to enter on the half-step keypad: the nearest half for Exact (always within 0.25),
    /// otherwise the target.
    public func keypadAnswer(for convention: TrueCountConvention) -> Double {
        convention == .exact ? (exactTrueCount * 2).rounded() / 2 : target(for: convention)
    }
```

Replace the body of `isCorrect(_:convention:)` with:

```swift
        switch convention {
        case .exact:
            return abs(answer - exactTrueCount) <= 0.25 + 1e-9
        case .floor, .truncate:
            return abs(answer - target(for: convention)) < 1e-9
        }
```

In `CountDrillGenerator`, replace the doc comment and body of `trueCountQuestion` and add the two statics above it:

```swift
    /// No TC question asks for more than ±10 (Step 4 spec §1).
    public static let maxTrueCountMagnitude = 10.0

    /// Decks-remaining step: quarter decks for 1–2 decks, half decks otherwise (Step 4 spec §1).
    public static func trueCountStep(deckCount: Int) -> Double {
        deckCount <= 2 ? 0.25 : 0.5
    }

    /// Decks remaining in `trueCountStep` steps from one step to `deckCount` minus one step.
    /// Running count in -12...12, redrawn until |RC ÷ decks remaining| ≤ `maxTrueCountMagnitude`
    /// (RC 0 always qualifies, so this terminates).
    public static func trueCountQuestion<G: RandomNumberGenerator>(
        deckCount: Int, using rng: inout G
    ) -> TrueCountQuestion {
        let step = trueCountStep(deckCount: deckCount)
        let stepsPerDeck = Int((1 / step).rounded())
        let maxSteps = max(1, max(1, deckCount) * stepsPerDeck - 1)
        let decksRemaining = Double(Int.random(in: 1...maxSteps, using: &rng)) * step
        var rc: Int
        repeat {
            rc = Int.random(in: -12...12, using: &rng)
        } while abs(Double(rc) / decksRemaining) > maxTrueCountMagnitude + 1e-9
        return TrueCountQuestion(runningCount: rc, decksRemaining: decksRemaining)
    }
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd BJSCore && swift test`
Expected: all tests pass. The old `grading()` test still passes.

- [ ] **Step 5: Commit**

```bash
git add BJSCore/Sources/BJSCore/Counting/CountDrills.swift BJSCore/Tests/BJSCoreTests/CountingTests/CountDrillTests.swift
git commit -m "feat(core): quarter-deck TC questions, TC cap and convention targets

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: RC trace and drill scoring (BJSCore)

**Files:**
- Modify: `BJSCore/Sources/BJSCore/Counting/CountDrills.swift`
- Create: `BJSCore/Sources/BJSCore/Counting/CountDrillScore.swift`
- Test: `BJSCore/Tests/BJSCoreTests/CountingTests/CountDrillTests.swift`
- Test: `BJSCore/Tests/BJSCoreTests/CountingTests/CountDrillScoreTests.swift`

**Interfaces:**
- Produces:
  - `public init(groups: [[Card]], checkpoints: [Int])` on `RunningCountDrill` (was internal; app tests build drills by hand)
  - `public struct CountTraceEntry { card: Card; value: Int; runningCount: Int }`
  - `RunningCountDrill.trace(throughGroup: Int) -> [CountTraceEntry]`
  - `public struct CountDrillScore: Sendable, Equatable { checks: Int; correct: Int; accuracy: Double?; meanAbsoluteError: Double? }`
  - `CountDrillScore.init(_ results: [(expected: Double, answered: Double, isCorrect: Bool)])`
  - `static func secondsPerCard(pace: Double, groupSize: Int) -> Double`

- [ ] **Step 1: Write the failing tests**

Append inside `CountDrillTests`:

```swift
    @Test("Trace covers the cards since the previous checkpoint, with running totals")
    func trace() {
        let c = { (r: Rank) in Card(rank: r, suit: .spades) }
        let drill = RunningCountDrill(
            groups: [[c(.two), c(.king)], [c(.five), c(.five)], [c(.ace), c(.seven)], [c(.three)]],
            checkpoints: [1, 3])
        let first = drill.trace(throughGroup: 1)
        #expect(first.map(\.card.rank) == [.two, .king, .five, .five])
        #expect(first.map(\.value) == [1, -1, 1, 1])
        #expect(first.map(\.runningCount) == [1, 0, 1, 2])
        // The next trace starts after group 1 and continues from its count (+2).
        let later = drill.trace(throughGroup: 3)
        #expect(later.map(\.card.rank) == [.ace, .seven, .three])
        #expect(later.map(\.runningCount) == [1, 1, 2])
    }

    @Test("Traces over every checkpoint cover the drill exactly once", arguments: [1, 2, 3])
    func tracesPartitionDrill(groupSize: Int) {
        var rng = SeededRandomNumberGenerator(seed: 7)
        let drill = CountDrillGenerator.runningCountDrill(
            length: .cards(52), groupSize: groupSize, deckCount: 6, randomCheckpoints: true, using: &rng)
        var all: [CountTraceEntry] = []
        for checkpoint in drill.checkpoints {
            let entries = drill.trace(throughGroup: checkpoint)
            #expect(entries.last?.runningCount == drill.expectedCount(afterGroup: checkpoint))
            all += entries
        }
        #expect(all.map(\.card) == drill.groups.flatMap { $0 })
    }
```

Create `BJSCore/Tests/BJSCoreTests/CountingTests/CountDrillScoreTests.swift`:

```swift
import Testing
@testable import BJSCore

@Suite("Count drill score")
struct CountDrillScoreTests {

    @Test("No checks: no accuracy and no error")
    func empty() {
        let s = CountDrillScore([])
        #expect(s.checks == 0)
        #expect(s.correct == 0)
        #expect(s.accuracy == nil)
        #expect(s.meanAbsoluteError == nil)
    }

    @Test("All correct and exact")
    func allCorrect() {
        let s = CountDrillScore([(expected: 3, answered: 3, isCorrect: true),
                                 (expected: -1, answered: -1, isCorrect: true)])
        #expect(s.accuracy == 1)
        #expect(s.meanAbsoluteError == 0)
    }

    @Test("Mixed: accuracy counts isCorrect; the error is the mean of |answered − expected|")
    func mixed() {
        // A TC answer can be correct (within 0.25) with a non-zero error.
        let s = CountDrillScore([(expected: 3, answered: 3, isCorrect: true),
                                 (expected: -2, answered: 1, isCorrect: false),
                                 (expected: 0.5, answered: 0.25, isCorrect: true),
                                 (expected: 4, answered: 2, isCorrect: false)])
        #expect(s.checks == 4)
        #expect(s.correct == 2)
        #expect(s.accuracy == 0.5)
        #expect(s.meanAbsoluteError == (0 + 3 + 0.25 + 2) / 4)
    }

    @Test("Seconds per card is the pace divided by the group size")
    func secondsPerCard() {
        #expect(abs(CountDrillScore.secondsPerCard(pace: 0.9, groupSize: 3) - 0.3) < 1e-12)
        #expect(CountDrillScore.secondsPerCard(pace: 1.0, groupSize: 1) == 1.0)
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `cd BJSCore && swift test --filter "CountDrill"`
Expected: compile errors. `trace(throughGroup:)`, `CountTraceEntry` and `CountDrillScore` are undefined.

- [ ] **Step 3: Implement**

In `CountDrills.swift`, add this above `RunningCountDrill`:

```swift
/// One card in a running-count trace: its Hi-Lo value and the running count after it.
public struct CountTraceEntry: Sendable, Equatable {
    public let card: Card
    public let value: Int
    public let runningCount: Int

    public init(card: Card, value: Int, runningCount: Int) {
        self.card = card
        self.value = value
        self.runningCount = runningCount
    }
}
```

In `RunningCountDrill`, change `init(groups: [[Card]], checkpoints: [Int])` to `public init`, and add a doc comment above it:

```swift
    /// `checkpoints` must be ascending group indices ending with the last group.
```

Then add this method after `expectedCount(afterGroup:)`:

```swift
    /// Every card from the group after the previous checkpoint through `groupIndex`, with its
    /// Hi-Lo value and the running count after it. The first checkpoint's trace starts at card 1.
    public func trace(throughGroup groupIndex: Int) -> [CountTraceEntry] {
        let first = checkpoints.last(where: { $0 < groupIndex }).map { $0 + 1 } ?? 0
        var running = first == 0 ? 0 : countsAfterGroup[first - 1]
        var entries: [CountTraceEntry] = []
        for group in groups[first...groupIndex] {
            for card in group {
                running += card.rank.hiLoValue
                entries.append(CountTraceEntry(card: card, value: card.rank.hiLoValue, runningCount: running))
            }
        }
        return entries
    }
```

Create `BJSCore/Sources/BJSCore/Counting/CountDrillScore.swift`:

```swift
/// Scores for a finished RC or TC drill (Step 4 spec §3).
public struct CountDrillScore: Sendable, Equatable {
    public let checks: Int
    public let correct: Int
    /// Fraction of checks graded correct; nil with no checks.
    public let accuracy: Double?
    /// Mean of |answered − expected|; nil with no checks.
    public let meanAbsoluteError: Double?

    public init(_ results: [(expected: Double, answered: Double, isCorrect: Bool)]) {
        checks = results.count
        correct = results.filter { $0.isCorrect }.count
        accuracy = results.isEmpty ? nil : Double(correct) / Double(checks)
        meanAbsoluteError = results.isEmpty ? nil
            : results.reduce(0) { $0 + abs($1.answered - $1.expected) } / Double(checks)
    }

    /// How long each card was on screen in an RC drill.
    public static func secondsPerCard(pace: Double, groupSize: Int) -> Double {
        pace / Double(max(1, groupSize))
    }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd BJSCore && swift test`
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJSCore/Sources/BJSCore/Counting BJSCore/Tests/BJSCoreTests/CountingTests
git commit -m "feat(core): running-count trace and count drill scoring

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Counting setups, text and shared types; move `CloseButton` to Shared

**Files:**
- Create: `BJS/Shared/CloseButton.swift`
- Modify:
  - `BJS/Features/Strategy/StrategySetupView.swift`: delete the `CloseButton` struct at the bottom, and pass `identifier: "strategy.close"`
  - `BJS/Features/Strategy/StrategyTrainerView.swift`: pass `identifier: "strategy.close"`
  - `BJS/Features/Strategy/WhySheet.swift`: pass `identifier: "strategy.close"`
- Create:
  - `BJS/Features/Counting/CountingSetup.swift`
  - `BJS/Features/Counting/CountingText.swift`
  - `BJS/Features/Counting/GradedCount.swift`
- Test: `BJSTests/Features/CountingSetupTests.swift` and `BJSTests/Features/CountingTextTests.swift`

**Interfaces:**
- Consumes (Task 1): `TrueCountQuestion.target(for:)` and `keypadAnswer(for:)`. Consumes (Task 2): `CountDrillScore`.
- Produces:
  - `CloseButton(identifier: String = "close", action:)`
  - `RunningCountLength`: `.cards(Int)`, `.fullShoe`; `options`, `title`, `drillLength: DrillLength`
  - `RunningCountSetup`:
    - fields: `groupSize: Int`, `pace: Double`, `length`, `randomCheckpoints: Bool`
    - `paceTenths: Int { get set }`
    - statics: `paceTenthsRange`, `groupSizes`
  - `TrueCountLength`: `.questions(Int)`, `.endless`; `options`, `title`, `questionLimit: Int?`
  - `TrueCountSetup`: `length`
  - `CountingSetup`: `.runningCount(RunningCountSetup)`, `.trueCount(TrueCountSetup)`; `trainingModule`, `lastLaunch() throws -> LastLaunch`, `static decode(_ data: Data) -> CountingSetup?`
  - `CountingText`:
    - `signed(Int)`, `signed(Double)`, `decks(Double)`, `decksLeft(Double)`
    - `pace(Double)`, `seconds(Double)`, `meanError(Double?)`
    - `Feedback { headline; reason }`, `runningFeedback(expected:answered:)`, `trueFeedback(question:convention:answered:isCorrect:)`, `cardValueFeedback(rank:)`
    - `conventionRule(_:)`, `runningRow(_:)`, `trueRow(_:question:convention:)`
  - `GradedCount`:
    - fields: `id`, `kind`, `expected`, `answered`, `isCorrect`, `responseMs`, `cardsSeen`, `checkedAt`
    - `draft: CountCheckDraft`; `static milliseconds(from:to:) -> Int`
  - `CountSummaryRow { id; label; value }`
  - `CountSummaryModel { title; rowsTitle; score: CountDrillScore; secondsPerCard: Double?; rows }`

- [ ] **Step 1: Move `CloseButton` (a refactor with no behaviour change)**

Create `BJS/Shared/CloseButton.swift`:

```swift
import SwiftUI

/// The × that closes a module screen or sheet (not a Felt component; built from tokens).
struct CloseButton: View {
    var identifier = "close"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(FeltColor.textSecondary)
                .frame(width: FeltTapTarget.minimum, height: FeltTapTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
        .accessibilityIdentifier(identifier)
    }
}
```

Delete the `/// The × used on Strategy screens …` comment and the `struct CloseButton` from `StrategySetupView.swift`. Update the three Strategy call sites:
- `StrategySetupView.swift`: `CloseButton(identifier: "strategy.close", action: onClose)`
- `StrategyTrainerView.swift`: `CloseButton(identifier: "strategy.close") {`
- `WhySheet.swift`: `CloseButton(identifier: "strategy.close") { dismiss() }`

- [ ] **Step 2: Write the failing tests**

Create `BJSTests/Features/CountingSetupTests.swift`:

```swift
import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct CountingSetupTests {

    @Test("RC setup defaults (Step 4 spec §4)")
    func runningDefaults() {
        let s = RunningCountSetup()
        #expect(s.groupSize == 1)
        #expect(s.pace == 1.0)
        #expect(s.length == .cards(52))
        #expect(!s.randomCheckpoints)
        #expect(RunningCountSetup.groupSizes == [1, 2, 3])
        #expect(RunningCountLength.options == [.cards(10), .cards(26), .cards(52), .fullShoe])
        #expect(RunningCountLength.options.map(\.title) == ["10", "26", "52", "Shoe"])
        #expect(RunningCountLength.fullShoe.drillLength == .fullShoe)
        #expect(RunningCountLength.cards(26).drillLength == .cards(26))
    }

    @Test("Pace moves in tenths and clamps to 0.3–2.0 s")
    func paceTenths() {
        var s = RunningCountSetup()
        #expect(s.paceTenths == 10)
        s.paceTenths = 3
        #expect(s.pace == 0.3)
        s.paceTenths = 1
        #expect(s.pace == 0.3)
        s.paceTenths = 25
        #expect(s.pace == 2.0)
        #expect(RunningCountSetup.paceTenthsRange == 3...20)
    }

    @Test("TC setup defaults and lengths")
    func trueDefaults() {
        #expect(TrueCountSetup().length == .questions(10))
        #expect(TrueCountLength.options == [.questions(10), .questions(20), .endless])
        #expect(TrueCountLength.options.map(\.title) == ["10", "20", "∞"])
        #expect(TrueCountLength.questions(20).questionLimit == 20)
        #expect(TrueCountLength.endless.questionLimit == nil)
    }

    @Test("lastLaunch records the drill's training module and round-trips the setup")
    func lastLaunchRoundTrip() throws {
        var rc = RunningCountSetup()
        rc.groupSize = 3
        rc.randomCheckpoints = true
        let rcLaunch = try CountingSetup.runningCount(rc).lastLaunch()
        #expect(rcLaunch.module == .countingRC)
        #expect(rcLaunch.mode == nil)
        #expect(CountingSetup.decode(rcLaunch.setup) == .runningCount(rc))

        let tcLaunch = try CountingSetup.trueCount(TrueCountSetup(length: .endless)).lastLaunch()
        #expect(tcLaunch.module == .countingTC)
        #expect(CountingSetup.decode(tcLaunch.setup) == .trueCount(TrueCountSetup(length: .endless)))
    }

    @Test("Undecodable setup data gives nil, so Continue falls back to the menu")
    func decodeFailure() {
        #expect(CountingSetup.decode(Data("nope".utf8)) == nil)
    }
}
```

Create `BJSTests/Features/CountingTextTests.swift`:

```swift
import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct CountingTextTests {

    @Test("Signed integers use a true minus sign")
    func signedInt() {
        #expect(CountingText.signed(3) == "+3")
        #expect(CountingText.signed(-2) == "\u{2212}2")
        #expect(CountingText.signed(0) == "0")
    }

    @Test("Signed doubles round to one decimal and drop .0")
    func signedDouble() {
        #expect(CountingText.signed(7.0 / 3) == "+2.3")
        #expect(CountingText.signed(-3.0) == "\u{2212}3")
        #expect(CountingText.signed(0.5) == "+0.5")
        #expect(CountingText.signed(0.04) == "0")
        #expect(CountingText.signed(-2.5) == "\u{2212}2.5")
    }

    @Test("Decks keep quarters")
    func decks() {
        #expect(CountingText.decks(0.25) == "0.25")
        #expect(CountingText.decks(2.5) == "2.5")
        #expect(CountingText.decks(3) == "3")
        #expect(CountingText.decks(1.75) == "1.75")
        #expect(CountingText.decksLeft(1) == "1 deck left")
        #expect(CountingText.decksLeft(0.75) == "0.75 decks left")
    }

    @Test("Durations and error")
    func numbers() {
        #expect(CountingText.pace(0.3) == "0.3 s")
        #expect(CountingText.seconds(1.0 / 3) == "0.33 s")
        #expect(CountingText.meanError(nil) == "—")
        #expect(CountingText.meanError(0.72) == "0.7")
    }

    @Test("RC feedback: correct, and wrong with the user's answer")
    func runningFeedback() {
        #expect(CountingText.runningFeedback(expected: 3, answered: 3)
                == .init(headline: "Correct", reason: "The running count is +3."))
        #expect(CountingText.runningFeedback(expected: 3, answered: 2)
                == .init(headline: "Running count is +3", reason: "You said +2."))
    }

    @Test("TC feedback shows the keypad answer and the working")
    func trueFeedback() {
        let q = TrueCountQuestion(runningCount: 7, decksRemaining: 3)
        #expect(CountingText.trueFeedback(question: q, convention: .exact, answered: 3, isCorrect: false)
                == .init(headline: "True count is +2.5", reason: "RC +7 ÷ 3 decks left = +2.3. You said +3."))
        #expect(CountingText.trueFeedback(question: q, convention: .exact, answered: 2.5, isCorrect: true)
                == .init(headline: "Correct", reason: "RC +7 ÷ 3 decks left = +2.3."))
        let n = TrueCountQuestion(runningCount: -7, decksRemaining: 3)
        #expect(CountingText.trueFeedback(question: n, convention: .floor, answered: -2, isCorrect: false).headline
                == "True count is \u{2212}3")
    }

    @Test("Card value feedback names the rank and its value")
    func cardValue() {
        #expect(CountingText.cardValueFeedback(rank: .five).headline == "Five is +1")
        #expect(CountingText.cardValueFeedback(rank: .seven).headline == "Seven is 0")
        #expect(CountingText.cardValueFeedback(rank: .king).headline == "King is \u{2212}1")
        #expect(CountingText.cardValueFeedback(rank: .king).reason
                == "2 to 6 are +1, 7 to 9 are 0, and 10 to Ace are \u{2212}1.")
    }

    @Test("Convention rules name each convention")
    func rules() {
        #expect(CountingText.conventionRule(.exact).hasPrefix("Exact:"))
        #expect(CountingText.conventionRule(.floor).hasPrefix("Floor:"))
        #expect(CountingText.conventionRule(.truncate).hasPrefix("Truncate:"))
    }

    @Test("Summary rows")
    func rows() {
        let t = Date(timeIntervalSince1970: 0)
        let right = GradedCount(id: 0, kind: .runningCount, expected: 3, answered: 3, isCorrect: true,
                                responseMs: 900, cardsSeen: 12, checkedAt: t)
        let wrong = GradedCount(id: 1, kind: .runningCount, expected: -1, answered: 2, isCorrect: false,
                                responseMs: 900, cardsSeen: 26, checkedAt: t)
        #expect(CountingText.runningRow(right) == CountSummaryRow(id: 0, label: "After card 12", value: "+3"))
        #expect(CountingText.runningRow(wrong)
                == CountSummaryRow(id: 1, label: "After card 26", value: "\u{2212}1 · you said +2"))

        let q = TrueCountQuestion(runningCount: 7, decksRemaining: 2.5)
        let tc = GradedCount(id: 0, kind: .trueCount, expected: 2.8, answered: 2, isCorrect: false,
                             responseMs: 900, cardsSeen: 182, checkedAt: t)
        #expect(CountingText.trueRow(tc, question: q, convention: .exact)
                == CountSummaryRow(id: 0, label: "+7 · 2.5 decks left", value: "+3 · you said +2"))
    }

    @Test("A graded count maps to its draft; response time never goes negative")
    func gradedCount() {
        let t = Date(timeIntervalSince1970: 100)
        let g = GradedCount(id: 0, kind: .trueCount, expected: 2, answered: 2, isCorrect: true,
                            responseMs: 1500, cardsSeen: 104, checkedAt: t)
        #expect(g.draft == CountCheckDraft(kind: .trueCount, expected: 2, answered: 2, isCorrect: true,
                                           responseMs: 1500, cardsSeen: 104, checkedAt: t))
        #expect(GradedCount.milliseconds(from: t, to: t.addingTimeInterval(1.2345)) == 1235)
        #expect(GradedCount.milliseconds(from: t, to: t.addingTimeInterval(-1)) == 0)
    }
}
```

- [ ] **Step 3: Run the tests and confirm they fail**

Run: `xcodegen generate`, then the app test command with `-only-testing:BJSTests/CountingSetupTests -only-testing:BJSTests/CountingTextTests`.
Expected: the build fails. The counting types are undefined.

- [ ] **Step 4: Implement**

Create `BJS/Features/Counting/CountingSetup.swift`:

```swift
import Foundation
import os
import BJSCore

/// How many cards a running-count drill deals (parent spec §5).
enum RunningCountLength: Hashable, Codable {
    case cards(Int)
    case fullShoe

    static let options: [RunningCountLength] = [.cards(10), .cards(26), .cards(52), .fullShoe]

    var title: String {
        switch self {
        case .cards(let n): return "\(n)"
        case .fullShoe: return "Shoe"
        }
    }

    var drillLength: DrillLength {
        switch self {
        case .cards(let n): return .cards(n)
        case .fullShoe: return .fullShoe
        }
    }
}

struct RunningCountSetup: Codable, Equatable {
    static let groupSizes = [1, 2, 3]
    /// Pace in tenths of a second: 0.3–2.0 s per group.
    static let paceTenthsRange = 3...20

    var groupSize = 1
    /// Seconds each group stays on screen.
    var pace = 1.0
    var length: RunningCountLength = .cards(52)
    var randomCheckpoints = false

    /// The pace in whole tenths, for the setup stepper (avoids 0.1-step drift).
    var paceTenths: Int {
        get { Int((pace * 10).rounded()) }
        set {
            let clamped = min(max(newValue, Self.paceTenthsRange.lowerBound), Self.paceTenthsRange.upperBound)
            pace = Double(clamped) / 10
        }
    }
}

enum TrueCountLength: Hashable, Codable {
    case questions(Int)
    case endless

    static let options: [TrueCountLength] = [.questions(10), .questions(20), .endless]

    var title: String {
        switch self {
        case .questions(let n): return "\(n)"
        case .endless: return "∞"
        }
    }

    var questionLimit: Int? {
        switch self {
        case .questions(let n): return n
        case .endless: return nil
        }
    }
}

struct TrueCountSetup: Codable, Equatable {
    var length: TrueCountLength = .questions(10)
}

/// A counting drill's setup, stored in `LastLaunch.setup` so Continue reopens the same drill.
enum CountingSetup: Codable, Equatable {
    case runningCount(RunningCountSetup)
    case trueCount(TrueCountSetup)

    var trainingModule: TrainingModule {
        switch self {
        case .runningCount: return .countingRC
        case .trueCount: return .countingTC
        }
    }

    func lastLaunch() throws -> LastLaunch {
        LastLaunch(module: trainingModule, mode: nil, setup: try JSONEncoder().encode(self))
    }

    /// nil (logged) when the data doesn't decode, e.g. after a format change.
    static func decode(_ data: Data) -> CountingSetup? {
        do {
            return try JSONDecoder().decode(CountingSetup.self, from: data)
        } catch {
            Logger(subsystem: "com.bjs.app", category: "Counting")
                .error("Counting setup failed to decode: \(error.localizedDescription)")
            return nil
        }
    }
}
```

Create `BJS/Features/Counting/GradedCount.swift`:

```swift
import Foundation
import BJSCore

/// One graded count check, kept in memory for feedback, WHY and the summary.
struct GradedCount: Equatable, Identifiable {
    let id: Int
    let kind: CountKind
    let expected: Double
    let answered: Double
    let isCorrect: Bool
    let responseMs: Int
    let cardsSeen: Int
    let checkedAt: Date

    var draft: CountCheckDraft {
        CountCheckDraft(kind: kind, expected: expected, answered: answered, isCorrect: isCorrect,
                        responseMs: responseMs, cardsSeen: cardsSeen, checkedAt: checkedAt)
    }

    static func milliseconds(from start: Date, to end: Date) -> Int {
        max(0, Int((end.timeIntervalSince(start) * 1000).rounded()))
    }
}

struct CountSummaryRow: Equatable, Identifiable {
    let id: Int
    let label: String
    let value: String
}

/// What `CountSummaryView` shows for either drill.
struct CountSummaryModel: Equatable {
    let title: String
    let rowsTitle: String
    let score: CountDrillScore
    /// RC only.
    let secondsPerCard: Double?
    let rows: [CountSummaryRow]
}
```

Create `BJS/Features/Counting/CountingText.swift`:

```swift
import Foundation
import BJSCore

/// Counting copy and number formatting. Deterministic (no locale) so it is unit-tested exactly.
enum CountingText {
    static let minus = "\u{2212}"

    struct Feedback: Equatable {
        let headline: String
        let reason: String
    }

    /// "+3", "−2", "0".
    static func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : value < 0 ? "\(minus)\(-value)" : "0"
    }

    /// Rounded to one decimal, ".0" dropped: "+2.3", "−3", "+0.5", "0".
    static func signed(_ value: Double) -> String {
        let tenths = Int((value * 10).rounded())
        if tenths == 0 { return "0" }
        let m = abs(tenths)
        return (tenths > 0 ? "+" : minus) + (m % 10 == 0 ? "\(m / 10)" : "\(m / 10).\(m % 10)")
    }

    /// Decks to the quarter: "0.25", "2.5", "3".
    static func decks(_ value: Double) -> String {
        let hundredths = Int((value * 100).rounded())
        let whole = hundredths / 100
        let fraction = hundredths % 100
        if fraction == 0 { return "\(whole)" }
        return fraction % 10 == 0 ? "\(whole).\(fraction / 10)" : "\(whole).\(String(format: "%02d", fraction))"
    }

    static func decksLeft(_ value: Double) -> String {
        value == 1 ? "1 deck left" : "\(decks(value)) decks left"
    }

    static func pace(_ seconds: Double) -> String { String(format: "%.1f s", seconds) }

    static func seconds(_ value: Double) -> String { String(format: "%.2f s", value) }

    static func meanError(_ value: Double?) -> String {
        value.map { String(format: "%.1f", $0) } ?? PercentText.noData
    }

    static func runningFeedback(expected: Int, answered: Int) -> Feedback {
        expected == answered
            ? Feedback(headline: "Correct", reason: "The running count is \(signed(expected)).")
            : Feedback(headline: "Running count is \(signed(expected))", reason: "You said \(signed(answered)).")
    }

    static func trueFeedback(question: TrueCountQuestion, convention: TrueCountConvention,
                             answered: Double, isCorrect: Bool) -> Feedback {
        let working = "RC \(signed(question.runningCount)) ÷ \(decksLeft(question.decksRemaining))"
            + " = \(signed(question.exactTrueCount))."
        if isCorrect { return Feedback(headline: "Correct", reason: working) }
        return Feedback(headline: "True count is \(signed(question.keypadAnswer(for: convention)))",
                        reason: "\(working) You said \(signed(answered)).")
    }

    static func cardValueFeedback(rank: Rank) -> Feedback {
        Feedback(headline: "\(rank.spokenName) is \(signed(rank.hiLoValue))",
                 reason: "2 to 6 are +1, 7 to 9 are 0, and 10 to Ace are \(minus)1.")
    }

    static func conventionRule(_ convention: TrueCountConvention) -> String {
        switch convention {
        case .exact:
            return "Exact: any answer within 0.25 of RC ÷ decks left is correct, so halves are enough."
        case .floor:
            return "Floor: round RC ÷ decks left down to the whole number below (\(minus)2.3 becomes \(minus)3)."
        case .truncate:
            return "Truncate: drop the fraction of RC ÷ decks left, toward zero (\(minus)2.3 becomes \(minus)2)."
        }
    }

    static func runningRow(_ check: GradedCount) -> CountSummaryRow {
        let expected = signed(Int(check.expected))
        let value = check.isCorrect ? expected : "\(expected) · you said \(signed(Int(check.answered)))"
        return CountSummaryRow(id: check.id, label: "After card \(check.cardsSeen)", value: value)
    }

    static func trueRow(_ check: GradedCount, question: TrueCountQuestion,
                        convention: TrueCountConvention) -> CountSummaryRow {
        let answer = signed(question.keypadAnswer(for: convention))
        let value = check.isCorrect ? signed(check.answered) : "\(answer) · you said \(signed(check.answered))"
        return CountSummaryRow(id: check.id,
                               label: "\(signed(question.runningCount)) · \(decksLeft(question.decksRemaining))",
                               value: value)
    }
}
```

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `xcodegen generate`, then the full app test command. That includes `StrategyUITests`, which checks the `strategy.close` identifier still works.
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add BJS/Shared/CloseButton.swift BJS/Features/Strategy BJS/Features/Counting BJSTests/Features/CountingSetupTests.swift BJSTests/Features/CountingTextTests.swift
git commit -m "feat(counting): setups, copy and graded-count types; move CloseButton to Shared

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: `RunningCountDrillViewModel`

**Files:**
- Create: `BJS/Features/Counting/RunningCountDrillViewModel.swift`
- Test: `BJSTests/Features/RunningCountDrillViewModelTests.swift`

**Interfaces:**
- Consumes:
  - from Task 2: `RunningCountDrill.init(groups:checkpoints:)`, `trace(throughGroup:)`, `CountDrillScore`;
  - from Task 3: `RunningCountSetup`, `GradedCount`, `CountSummaryModel`, `CountingText.runningRow`;
  - from Step 3 tests: `SaveSpy` and `SaveFailure` in `BJSTests/Features/StrategySessionTests.swift`, which are reused.
- Produces:
  - `enum RunningCountPhase { presenting(group: Int), answering(group: Int), feedback(GradedCount), summary }`
  - `RunningCountDrillViewModel`:
    - `convenience init(setup:rules:paceOverride:seed:now:persist:)`
    - `init(setup:rules:drill:paceOverride:now:persist:)`
    - read-only: `setup`, `rules`, `drill`, `pace`, `sessionID`, `phase`, `checks`, `presentationToken`, `saveFailed`, `hasSaved`
    - computed: `visibleCards`, `cardsShown`, `totalCards`, `correctCount`, `canSavePartial`, `summary`, `sessionDraft`
    - methods: `advance(token:)`, `submit(_: Double)`, `next()`, `resumeAfterInterruption()`, `finish()`, `trace(for:)`

- [ ] **Step 1: Write the failing tests**

Create `BJSTests/Features/RunningCountDrillViewModelTests.swift`:

```swift
import Foundation
import Testing
import BJSCore
@testable import BJS

/// A clock the test moves by hand.
@MainActor
final class TestClock {
    var date = Date(timeIntervalSince1970: 1000)
    func advance(_ seconds: Double) { date = date.addingTimeInterval(seconds) }
}

func countCard(_ rank: Rank) -> Card { Card(rank: rank, suit: .clubs) }

@MainActor
struct RunningCountDrillViewModelTests {

    /// 2 → +1, K → 0 (checkpoint), 5 → +1, 6 → +2 (checkpoint, last).
    let drill = RunningCountDrill(groups: [[countCard(.two)], [countCard(.king)], [countCard(.five)], [countCard(.six)]],
                                  checkpoints: [1, 3])

    func make(_ spy: SaveSpy = SaveSpy(), clock: TestClock = TestClock(),
              setup: RunningCountSetup = RunningCountSetup()) -> RunningCountDrillViewModel {
        RunningCountDrillViewModel(setup: setup, rules: BlackjackRules(), drill: drill,
                                   now: { clock.date }, persist: { try spy.persist($0) })
    }

    /// Advances past every group up to and including `group`'s presentation.
    func advance(_ vm: RunningCountDrillViewModel, times: Int) {
        for _ in 0..<times { vm.advance(token: vm.presentationToken) }
    }

    @Test("Starts presenting the first group")
    func starts() {
        let vm = make()
        #expect(vm.phase == .presenting(group: 0))
        #expect(vm.visibleCards == [countCard(.two)])
        #expect(vm.cardsShown == 1)
        #expect(vm.totalCards == 4)
        #expect(!vm.canSavePartial)
    }

    @Test("advance moves to the next group; a stale token is ignored")
    func advanceAndStale() {
        let vm = make()
        let stale = vm.presentationToken
        vm.advance(token: stale)
        #expect(vm.phase == .presenting(group: 1))
        vm.advance(token: stale)
        #expect(vm.phase == .presenting(group: 1))
    }

    @Test("A checkpoint group is shown for its interval, then the keypad comes up")
    func checkpoint() {
        let vm = make()
        advance(vm, times: 2)
        #expect(vm.phase == .answering(group: 1))
        #expect(vm.visibleCards.isEmpty)
        #expect(vm.cardsShown == 2)
    }

    @Test("A correct answer grades against the running count and records response time")
    func correctAnswer() {
        let clock = TestClock()
        let vm = make(clock: clock)
        advance(vm, times: 2)
        clock.advance(1.5)
        vm.submit(0)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect)
        #expect(graded.kind == .runningCount)
        #expect(graded.expected == 0)
        #expect(graded.cardsSeen == 2)
        #expect(graded.responseMs == 1500)
        #expect(vm.canSavePartial)
        #expect(vm.trace(for: graded).map(\.runningCount) == [1, 0])
    }

    @Test("A wrong answer is recorded, and NEXT resumes from the correct count")
    func wrongThenResume() {
        let vm = make()
        advance(vm, times: 2)
        vm.submit(3)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(!graded.isCorrect)
        #expect(graded.answered == 3)
        vm.next()
        #expect(vm.phase == .presenting(group: 2))
        advance(vm, times: 2)
        vm.submit(2)
        guard case .feedback(let last) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(last.isCorrect)
        #expect(vm.trace(for: last).map(\.card) == [countCard(.five), countCard(.six)])
    }

    @Test("The last checkpoint's NEXT goes to the summary and saves once as countingRC")
    func finishSaves() throws {
        let spy = SaveSpy()
        let vm = make(spy)
        advance(vm, times: 2); vm.submit(0); vm.next()
        advance(vm, times: 2); vm.submit(1); vm.next()
        #expect(vm.phase == .summary)
        let draft = try #require(spy.drafts.first)
        #expect(spy.drafts.count == 1)
        #expect(draft.id == vm.sessionID)
        #expect(draft.module == .countingRC)
        #expect(draft.mode == nil)
        #expect(draft.countChecks.map(\.kind) == [.runningCount, .runningCount])
        #expect(draft.countChecks.map(\.isCorrect) == [true, false])
        #expect(draft.countChecks.map(\.cardsSeen) == [2, 4])
        vm.finish()
        #expect(spy.drafts.count == 1)
    }

    @Test("Input outside its phase is ignored")
    func guards() {
        let vm = make()
        vm.submit(0)
        vm.next()
        #expect(vm.phase == .presenting(group: 0))
        #expect(vm.checks.isEmpty)
    }

    @Test("Resuming re-arms the current group; while answering it restarts the answer clock")
    func resume() {
        let clock = TestClock()
        let vm = make(clock: clock)
        let before = vm.presentationToken
        vm.resumeAfterInterruption()
        #expect(vm.presentationToken == before + 1)
        #expect(vm.phase == .presenting(group: 0))
        advance(vm, times: 2)
        clock.advance(10)
        vm.resumeAfterInterruption()
        clock.advance(2)
        vm.submit(0)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.responseMs == 2000)
    }

    @Test("Save partial with no checks shows the summary without saving")
    func finishEmpty() {
        let spy = SaveSpy()
        let vm = make(spy)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(spy.drafts.isEmpty)
    }

    @Test("A save failure still shows the summary")
    func saveFailure() {
        let spy = SaveSpy()
        spy.error = SaveFailure()
        let vm = make(spy)
        advance(vm, times: 2); vm.submit(0)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(vm.saveFailed)
    }

    @Test("Summary: score, seconds per card and checkpoint rows")
    func summary() {
        var setup = RunningCountSetup()
        setup.groupSize = 2
        setup.pace = 1.0
        let vm = make(setup: setup)
        advance(vm, times: 2); vm.submit(0); vm.next()
        advance(vm, times: 2); vm.submit(1); vm.next()
        let s = vm.summary
        #expect(s.title == "Running count")
        #expect(s.rowsTitle == "Checkpoints")
        #expect(s.score.accuracy == 0.5)
        #expect(s.score.meanAbsoluteError == 0.5)
        #expect(s.secondsPerCard == 0.5)
        #expect(s.rows.map(\.label) == ["After card 2", "After card 4"])
    }

    @Test("The seeded initialiser builds the drill from the setup and honours a pace override")
    func seeded() {
        var setup = RunningCountSetup()
        setup.length = .cards(10)
        let vm = RunningCountDrillViewModel(setup: setup, rules: BlackjackRules(), paceOverride: 0.3, seed: 1,
                                            persist: { _ in })
        #expect(vm.totalCards == 10)
        #expect(vm.pace == 0.3)
        #expect(vm.drill.checkpoints == [9])
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `xcodegen generate`, then the app test command with `-only-testing:BJSTests/RunningCountDrillViewModelTests`.
Expected: the build fails. `RunningCountDrillViewModel` is undefined.

- [ ] **Step 3: Implement**

Create `BJS/Features/Counting/RunningCountDrillViewModel.swift`:

```swift
import Foundation
import Observation
import os
import BJSCore

enum RunningCountPhase: Equatable {
    /// A group is on screen; the view's timer calls `advance(token:)` after `pace`.
    case presenting(group: Int)
    /// A checkpoint: the keypad is up.
    case answering(group: Int)
    case feedback(GradedCount)
    case summary
}

/// Runs a running-count drill (Step 4 spec §4). BJSCore builds the drill and knows the counts;
/// this type sequences phases, owns the presentation token, and persists.
@MainActor
@Observable
final class RunningCountDrillViewModel {
    let setup: RunningCountSetup
    let rules: BlackjackRules
    let drill: RunningCountDrill
    /// Seconds each group stays on screen.
    let pace: Double
    let sessionID = UUID()
    let startedAt: Date

    private(set) var phase: RunningCountPhase = .presenting(group: 0)
    private(set) var checks: [GradedCount] = []
    /// Bumps whenever a group's interval (re)starts. The view's timer hands it back to `advance`.
    private(set) var presentationToken = 0
    private(set) var answerStartedAt: Date
    private(set) var hasSaved = false
    private(set) var saveFailed = false
    private(set) var endedAt: Date?

    /// The group each check came after, parallel to `checks`.
    @ObservationIgnored private var checkGroups: [Int] = []
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let persist: (SessionDraft) throws -> Void
    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "RunningCountDrill")

    convenience init(setup: RunningCountSetup, rules: BlackjackRules, paceOverride: Double? = nil, seed: UInt64,
                     now: @escaping () -> Date = { Date() },
                     persist: @escaping (SessionDraft) throws -> Void) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let drill = CountDrillGenerator.runningCountDrill(
            length: setup.length.drillLength, groupSize: setup.groupSize, deckCount: rules.deckCount.rawValue,
            randomCheckpoints: setup.randomCheckpoints, using: &rng)
        self.init(setup: setup, rules: rules, drill: drill, paceOverride: paceOverride, now: now, persist: persist)
    }

    init(setup: RunningCountSetup, rules: BlackjackRules, drill: RunningCountDrill, paceOverride: Double? = nil,
         now: @escaping () -> Date = { Date() }, persist: @escaping (SessionDraft) throws -> Void) {
        self.setup = setup
        self.rules = rules
        self.drill = drill
        self.pace = paceOverride ?? setup.pace
        self.now = now
        self.persist = persist
        let start = now()
        self.startedAt = start
        self.answerStartedAt = start
        present(0)
    }

    // MARK: - Display

    var visibleCards: [Card] {
        guard case .presenting(let group) = phase else { return [] }
        return drill.groups[group]
    }

    var cardsShown: Int {
        switch phase {
        case .presenting(let group), .answering(let group): return cardsThrough(group)
        case .feedback(let graded): return graded.cardsSeen
        case .summary: return checks.last?.cardsSeen ?? 0
        }
    }

    var totalCards: Int { drill.cardCount }
    var correctCount: Int { checks.filter(\.isCorrect).count }
    /// Whether "Save partial" has anything to save right now.
    var canSavePartial: Bool { !checks.isEmpty && phase != .summary }

    func trace(for check: GradedCount) -> [CountTraceEntry] {
        drill.trace(throughGroup: checkGroups[check.id])
    }

    var sessionDraft: SessionDraft {
        SessionDraft(id: sessionID, module: .countingRC, mode: nil, startedAt: startedAt,
                     endedAt: endedAt ?? now(), rules: rules, countChecks: checks.map(\.draft))
    }

    var summary: CountSummaryModel {
        CountSummaryModel(
            title: "Running count", rowsTitle: "Checkpoints",
            score: CountDrillScore(checks.map { (expected: $0.expected, answered: $0.answered, isCorrect: $0.isCorrect) }),
            secondsPerCard: CountDrillScore.secondsPerCard(pace: pace, groupSize: setup.groupSize),
            rows: checks.map(CountingText.runningRow))
    }

    // MARK: - Input

    /// The view's timer fired after `pace` for the presentation identified by `token`.
    func advance(token: Int) {
        guard case .presenting(let group) = phase, token == presentationToken else { return }
        if drill.checkpoints.contains(group) {
            answerStartedAt = now()
            phase = .answering(group: group)
        } else {
            present(group + 1)
        }
    }

    /// Keypad ENTER at a checkpoint.
    func submit(_ answer: Double) {
        guard case .answering(let group) = phase else { return }
        let checkedAt = now()
        let expected = Double(drill.expectedCount(afterGroup: group))
        let graded = GradedCount(
            id: checks.count, kind: .runningCount, expected: expected, answered: answer,
            isCorrect: answer == expected,
            responseMs: GradedCount.milliseconds(from: answerStartedAt, to: checkedAt),
            cardsSeen: cardsThrough(group), checkedAt: checkedAt)
        checks.append(graded)
        checkGroups.append(group)
        phase = .feedback(graded)
    }

    /// FeedbackCard NEXT: resume with the next group, or finish after the last.
    func next() {
        guard case .feedback = phase, let group = checkGroups.last else { return }
        if group + 1 < drill.groups.count {
            present(group + 1)
        } else {
            finish()
        }
    }

    /// After the leave dialog closes or the app returns to the foreground: the current group gets a
    /// fresh full interval, or the answer clock restarts. A no-op in other phases.
    func resumeAfterInterruption() {
        switch phase {
        case .presenting(let group): present(group)
        case .answering: answerStartedAt = now()
        case .feedback, .summary: break
        }
    }

    /// Ends the drill (last checkpoint or Save partial): shows the summary and saves once.
    /// A drill with no checks isn't saved.
    func finish() {
        guard phase != .summary else { return }
        endedAt = now()
        phase = .summary
        guard !checks.isEmpty, !hasSaved else { return }
        hasSaved = true
        do {
            try persist(sessionDraft)
        } catch {
            saveFailed = true
            logger.error("Running count drill failed to save: \(error.localizedDescription)")
        }
    }

    // MARK: - Internals

    private func present(_ group: Int) {
        presentationToken += 1
        phase = .presenting(group: group)
    }

    private func cardsThrough(_ group: Int) -> Int {
        drill.groups[0...group].reduce(0) { $0 + $1.count }
    }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: the app test command with `-only-testing:BJSTests/RunningCountDrillViewModelTests`.
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJS/Features/Counting/RunningCountDrillViewModel.swift BJSTests/Features/RunningCountDrillViewModelTests.swift
git commit -m "feat(counting): running count drill view model

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: `TrueCountDrillViewModel`

**Files:**
- Create: `BJS/Features/Counting/TrueCountDrillViewModel.swift`
- Test: `BJSTests/Features/TrueCountDrillViewModelTests.swift`

**Interfaces:**
- Consumes:
  - from Task 1: `target(for:)`, `isCorrect(_:convention:)`, `CountDrillGenerator.trueCountQuestion`;
  - from Task 3: `TrueCountSetup`, `GradedCount`, `CountSummaryModel`, `CountingText.trueRow`;
  - from Task 4: `TestClock`, `SaveSpy`, `SaveFailure`.
- Produces:
  - `enum TrueCountPhase { question, feedback(GradedCount), summary }`
  - `TrueCountDrillViewModel`:
    - `typealias QuestionMaker = (Int, inout SeededRandomNumberGenerator) -> TrueCountQuestion`
    - `init(setup:rules:convention:seed:now:makeQuestion:persist:)`
    - read-only: `phase`, `question`, `questionNumber`, `checks`, `convention`, `sessionID`, `saveFailed`
    - computed: `questionLimit`, `deckCount`, `decksPlayed`, `allowsHalf`, `correctCount`, `canSavePartial`, `summary`, `sessionDraft`
    - methods: `question(for:)`, `submit(_:)`, `next()`, `resumeAfterInterruption()`, `finish()`

- [ ] **Step 1: Write the failing tests**

Create `BJSTests/Features/TrueCountDrillViewModelTests.swift`:

```swift
import Foundation
import Testing
import BJSCore
@testable import BJS

/// Hands out scripted questions in order, repeating the last.
@MainActor
final class ScriptedQuestions {
    var questions: [TrueCountQuestion]
    init(_ questions: [TrueCountQuestion]) { self.questions = questions }
    var maker: TrueCountDrillViewModel.QuestionMaker {
        { [self] _, _ in questions.count > 1 ? questions.removeFirst() : questions[0] }
    }
}

@MainActor
struct TrueCountDrillViewModelTests {

    func make(_ spy: SaveSpy = SaveSpy(), convention: TrueCountConvention = .exact,
              length: TrueCountLength = .questions(10), clock: TestClock = TestClock(),
              questions: [TrueCountQuestion] = [TrueCountQuestion(runningCount: 7, decksRemaining: 2)])
        -> TrueCountDrillViewModel {
        TrueCountDrillViewModel(setup: TrueCountSetup(length: length), rules: BlackjackRules(),
                                convention: convention, seed: 1, now: { clock.date },
                                makeQuestion: ScriptedQuestions(questions).maker,
                                persist: { try spy.persist($0) })
    }

    @Test("Starts on the first question; decks played is the shoe minus decks left")
    func starts() {
        let vm = make()
        #expect(vm.phase == .question)
        #expect(vm.questionNumber == 1)
        #expect(vm.question == TrueCountQuestion(runningCount: 7, decksRemaining: 2))
        #expect(vm.deckCount == 6)
        #expect(vm.decksPlayed == 4)
    }

    @Test("The .5 key is only offered under Exact", arguments: TrueCountConvention.allCases)
    func half(convention: TrueCountConvention) {
        #expect(make(convention: convention).allowsHalf == (convention == .exact))
    }

    @Test("Exact grades within 0.25; expected is the target; cards seen come from decks played")
    func exactGrading() {
        let clock = TestClock()
        let vm = make(clock: clock)
        clock.advance(2)
        vm.submit(3.5)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect)
        #expect(graded.kind == .trueCount)
        #expect(graded.expected == 3.5)
        #expect(graded.cardsSeen == 208)
        #expect(graded.responseMs == 2000)
        #expect(vm.question(for: graded) == TrueCountQuestion(runningCount: 7, decksRemaining: 2))
    }

    @Test("Floor grades the rounded-down value", arguments: [(3.0, true), (3.5, false), (4.0, false)])
    func floorGrading(answer: Double, correct: Bool) {
        let vm = make(convention: .floor)
        vm.submit(answer)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect == correct)
        #expect(graded.expected == 3)
    }

    @Test("NEXT asks a new question; the limit goes to the summary and saves once as countingTC")
    func limitSaves() throws {
        let spy = SaveSpy()
        let vm = make(spy, convention: .floor, length: .questions(2),
                      questions: [TrueCountQuestion(runningCount: 7, decksRemaining: 2),
                                  TrueCountQuestion(runningCount: -4, decksRemaining: 4)])
        vm.submit(3); vm.next()
        #expect(vm.phase == .question)
        #expect(vm.questionNumber == 2)
        #expect(vm.question == TrueCountQuestion(runningCount: -4, decksRemaining: 4))
        vm.submit(0); vm.next()
        #expect(vm.phase == .summary)
        let draft = try #require(spy.drafts.first)
        #expect(spy.drafts.count == 1)
        #expect(draft.module == .countingTC)
        #expect(draft.mode == "floor")
        #expect(draft.countChecks.map(\.isCorrect) == [true, false])
        #expect(draft.countChecks.map(\.expected) == [3, -1])
        vm.finish()
        #expect(spy.drafts.count == 1)
    }

    @Test("Endless keeps asking until finish()")
    func endless() {
        let vm = make(length: .endless)
        #expect(vm.questionLimit == nil)
        for _ in 0..<25 { vm.submit(3.5); vm.next() }
        #expect(vm.phase == .question)
        #expect(vm.questionNumber == 26)
        vm.finish()
        #expect(vm.phase == .summary)
    }

    @Test("Input outside its phase is ignored")
    func guards() {
        let vm = make()
        vm.next()
        #expect(vm.phase == .question)
        vm.submit(3.5)
        vm.submit(1)
        #expect(vm.checks.count == 1)
    }

    @Test("Resuming restarts the answer clock")
    func resume() {
        let clock = TestClock()
        let vm = make(clock: clock)
        clock.advance(30)
        vm.resumeAfterInterruption()
        clock.advance(1)
        vm.submit(3.5)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.responseMs == 1000)
    }

    @Test("Finishing with no checks doesn't save; a save failure still shows the summary")
    func saving() {
        let empty = SaveSpy()
        let vm = make(empty)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(empty.drafts.isEmpty)

        let failing = SaveSpy()
        failing.error = SaveFailure()
        let other = make(failing)
        other.submit(3.5)
        other.finish()
        #expect(other.phase == .summary)
        #expect(other.saveFailed)
    }

    @Test("Summary: score against the target and question rows")
    func summary() {
        let vm = make(length: .questions(2),
                      questions: [TrueCountQuestion(runningCount: 7, decksRemaining: 2),
                                  TrueCountQuestion(runningCount: 5, decksRemaining: 2.5)])
        vm.submit(3.5); vm.next()
        vm.submit(1); vm.next()
        let s = vm.summary
        #expect(s.title == "True count")
        #expect(s.rowsTitle == "Questions")
        #expect(s.secondsPerCard == nil)
        #expect(s.score.accuracy == 0.5)
        #expect(s.score.meanAbsoluteError == 0.5)
        #expect(s.rows.count == 2)
    }

    @Test("The default question maker uses the rules' deck count")
    func defaultMaker() {
        var rules = BlackjackRules()
        rules.deckCount = .one
        let vm = TrueCountDrillViewModel(setup: TrueCountSetup(), rules: rules, convention: .exact, seed: 3,
                                         persist: { _ in })
        #expect([0.25, 0.5, 0.75].contains(vm.question.decksRemaining))
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `xcodegen generate`, then the app test command with `-only-testing:BJSTests/TrueCountDrillViewModelTests`.
Expected: the build fails. `TrueCountDrillViewModel` is undefined.

- [ ] **Step 3: Implement**

Create `BJS/Features/Counting/TrueCountDrillViewModel.swift`:

```swift
import Foundation
import Observation
import os
import BJSCore

enum TrueCountPhase: Equatable {
    case question
    case feedback(GradedCount)
    case summary
}

/// Runs a true-count drill (Step 4 spec §4). BJSCore generates and grades the questions; this type
/// sequences phases and persists. The convention is snapshotted at start.
@MainActor
@Observable
final class TrueCountDrillViewModel {
    typealias QuestionMaker = (Int, inout SeededRandomNumberGenerator) -> TrueCountQuestion

    static let defaultQuestionMaker: QuestionMaker = { deckCount, rng in
        CountDrillGenerator.trueCountQuestion(deckCount: deckCount, using: &rng)
    }

    let setup: TrueCountSetup
    let rules: BlackjackRules
    let convention: TrueCountConvention
    let sessionID = UUID()
    let startedAt: Date

    private(set) var phase: TrueCountPhase = .question
    private(set) var question: TrueCountQuestion
    private(set) var questionNumber = 1
    private(set) var checks: [GradedCount] = []
    private(set) var answerStartedAt: Date
    private(set) var hasSaved = false
    private(set) var saveFailed = false
    private(set) var endedAt: Date?

    /// The question each check answered, parallel to `checks`.
    @ObservationIgnored private var askedQuestions: [TrueCountQuestion] = []
    @ObservationIgnored private var rng: SeededRandomNumberGenerator
    @ObservationIgnored private let makeQuestion: QuestionMaker
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let persist: (SessionDraft) throws -> Void
    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "TrueCountDrill")

    init(setup: TrueCountSetup, rules: BlackjackRules, convention: TrueCountConvention, seed: UInt64,
         now: @escaping () -> Date = { Date() }, makeQuestion: QuestionMaker? = nil,
         persist: @escaping (SessionDraft) throws -> Void) {
        self.setup = setup
        self.rules = rules
        self.convention = convention
        self.now = now
        self.persist = persist
        let maker = makeQuestion ?? Self.defaultQuestionMaker
        self.makeQuestion = maker
        var rng = SeededRandomNumberGenerator(seed: seed)
        self.question = maker(rules.deckCount.rawValue, &rng)
        self.rng = rng
        let start = now()
        self.startedAt = start
        self.answerStartedAt = start
    }

    // MARK: - Display

    var questionLimit: Int? { setup.length.questionLimit }
    var deckCount: Int { rules.deckCount.rawValue }
    var decksPlayed: Double { Double(deckCount) - question.decksRemaining }
    /// Only Exact accepts halves (parent spec §5).
    var allowsHalf: Bool { convention == .exact }
    var correctCount: Int { checks.filter(\.isCorrect).count }
    var canSavePartial: Bool { !checks.isEmpty && phase != .summary }

    func question(for check: GradedCount) -> TrueCountQuestion { askedQuestions[check.id] }

    var sessionDraft: SessionDraft {
        SessionDraft(id: sessionID, module: .countingTC, mode: convention.rawValue, startedAt: startedAt,
                     endedAt: endedAt ?? now(), rules: rules, countChecks: checks.map(\.draft))
    }

    var summary: CountSummaryModel {
        CountSummaryModel(
            title: "True count", rowsTitle: "Questions",
            score: CountDrillScore(checks.map { (expected: $0.expected, answered: $0.answered, isCorrect: $0.isCorrect) }),
            secondsPerCard: nil,
            rows: checks.map { CountingText.trueRow($0, question: question(for: $0), convention: convention) })
    }

    // MARK: - Input

    /// Keypad ENTER.
    func submit(_ answer: Double) {
        guard phase == .question else { return }
        let checkedAt = now()
        let graded = GradedCount(
            id: checks.count, kind: .trueCount, expected: question.target(for: convention), answered: answer,
            isCorrect: question.isCorrect(answer, convention: convention),
            responseMs: GradedCount.milliseconds(from: answerStartedAt, to: checkedAt),
            cardsSeen: Int((decksPlayed * 52).rounded()), checkedAt: checkedAt)
        checks.append(graded)
        askedQuestions.append(question)
        phase = .feedback(graded)
    }

    /// FeedbackCard NEXT: the next question, or the summary when the length is reached.
    func next() {
        guard case .feedback = phase else { return }
        if let questionLimit, checks.count >= questionLimit {
            finish()
            return
        }
        questionNumber += 1
        question = makeQuestion(deckCount, &rng)
        answerStartedAt = now()
        phase = .question
    }

    /// After the leave dialog closes or the app returns to the foreground: restart the answer clock.
    func resumeAfterInterruption() {
        guard phase == .question else { return }
        answerStartedAt = now()
    }

    /// Ends the drill (limit, END, or Save partial): shows the summary and saves once.
    /// A drill with no checks isn't saved.
    func finish() {
        guard phase != .summary else { return }
        endedAt = now()
        phase = .summary
        guard !checks.isEmpty, !hasSaved else { return }
        hasSaved = true
        do {
            try persist(sessionDraft)
        } catch {
            saveFailed = true
            logger.error("True count drill failed to save: \(error.localizedDescription)")
        }
    }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: the app test command with `-only-testing:BJSTests/TrueCountDrillViewModelTests`.
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJS/Features/Counting/TrueCountDrillViewModel.swift BJSTests/Features/TrueCountDrillViewModelTests.swift
git commit -m "feat(counting): true count drill view model

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: `CardValuesViewModel`

**Files:**
- Create: `BJS/Features/Counting/CardValuesViewModel.swift`
- Test: `BJSTests/Features/CardValuesViewModelTests.swift`

**Interfaces:**
- Produces: `CardValuesViewModel`:
  - `init(seed: UInt64)`
  - read-only: `card: Card`, `answered: Int`, `correct: Int`, `streak: Int`, `toastCount: Int`, `mistake: Card?`
  - methods: `answer(_ value: Int)`, `next()`

- [ ] **Step 1: Write the failing tests**

Create `BJSTests/Features/CardValuesViewModelTests.swift`:

```swift
import Testing
import BJSCore
@testable import BJS

@MainActor
struct CardValuesViewModelTests {

    @Test("A correct answer scores, extends the streak, flashes the toast and deals the next card")
    func correct() {
        let vm = CardValuesViewModel(seed: 1)
        vm.answer(vm.card.rank.hiLoValue)
        #expect(vm.answered == 1)
        #expect(vm.correct == 1)
        #expect(vm.streak == 1)
        #expect(vm.toastCount == 1)
        #expect(vm.mistake == nil)
    }

    @Test("A wrong answer resets the streak and holds the card until NEXT")
    func wrong() {
        let vm = CardValuesViewModel(seed: 2)
        vm.answer(vm.card.rank.hiLoValue)
        let card = vm.card
        let wrong = card.rank.hiLoValue == 1 ? -1 : 1
        vm.answer(wrong)
        #expect(vm.answered == 2)
        #expect(vm.correct == 1)
        #expect(vm.streak == 0)
        #expect(vm.mistake == card)
        vm.answer(card.rank.hiLoValue)
        #expect(vm.answered == 2)
        vm.next()
        #expect(vm.mistake == nil)
    }

    @Test("NEXT does nothing without a mistake")
    func nextWithoutMistake() {
        let vm = CardValuesViewModel(seed: 3)
        let card = vm.card
        vm.next()
        #expect(vm.card == card)
    }

    @Test("Cards cover every rank over many draws")
    func coverage() {
        let vm = CardValuesViewModel(seed: 4)
        var ranks = Set<Rank>()
        for _ in 0..<300 {
            ranks.insert(vm.card.rank)
            vm.answer(vm.card.rank.hiLoValue)
        }
        #expect(ranks.count == Rank.allCases.count)
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `xcodegen generate`, then the app test command with `-only-testing:BJSTests/CardValuesViewModelTests`.
Expected: the build fails.

- [ ] **Step 3: Implement**

Create `BJS/Features/Counting/CardValuesViewModel.swift`:

```swift
import Observation
import BJSCore

/// The card-values self-test (Step 4 spec §4): one card at a time, answer +1 / 0 / −1.
/// Endless and not persisted.
@MainActor
@Observable
final class CardValuesViewModel {
    private(set) var card: Card
    private(set) var answered = 0
    private(set) var correct = 0
    private(set) var streak = 0
    /// Bumps on every correct answer; the view flashes the ✓ toast.
    private(set) var toastCount = 0
    /// The card just answered wrongly. The FeedbackCard shows until NEXT.
    private(set) var mistake: Card?

    @ObservationIgnored private var rng: SeededRandomNumberGenerator

    init(seed: UInt64) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        card = Self.randomCard(using: &rng)
        self.rng = rng
    }

    func answer(_ value: Int) {
        guard mistake == nil else { return }
        answered += 1
        if value == card.rank.hiLoValue {
            correct += 1
            streak += 1
            toastCount += 1
            card = Self.randomCard(using: &rng)
        } else {
            streak = 0
            mistake = card
        }
    }

    /// FeedbackCard NEXT after a mistake.
    func next() {
        guard mistake != nil else { return }
        mistake = nil
        card = Self.randomCard(using: &rng)
    }

    private static func randomCard(using rng: inout SeededRandomNumberGenerator) -> Card {
        Card(rank: Rank.allCases.randomElement(using: &rng)!, suit: Suit.allCases.randomElement(using: &rng)!)
    }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: the app test command with `-only-testing:BJSTests/CardValuesViewModelTests`.
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJS/Features/Counting/CardValuesViewModel.swift BJSTests/Features/CardValuesViewModelTests.swift
git commit -m "feat(counting): card values self-test view model

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: `DiscardTray` component

**Files:**
- Create: `BJS/Design/Components/DiscardTray.swift`
- Modify: `BJS/Design/Catalogue/FeltCatalogue.swift`
- Test: `BJSTests/Design/CountingComponentTests.swift`

**Interfaces:**
- Produces:
  - `DiscardTray(decksTotal: Double, decksPlayed: Double, height: CGFloat = 160)`, with `static let width: CGFloat = 64`
  - `DiscardTrayLayout.fillFraction(decksTotal:decksPlayed:) -> Double`
  - `DiscardTrayLayout.tickFractions(decksTotal:) -> [Double]`
  - `DiscardTrayLayout.accessibilityValue(decksPlayed:) -> String`

The component uses only existing tokens: `surfaceInset`, `cream`, `onCreamSecondary`, `textTertiary`, `FeltRadius.chip`. Design code must not use anything from `Features/`.

- [ ] **Step 1: Write the failing tests**

Create `BJSTests/Design/CountingComponentTests.swift`:

```swift
import Testing
@testable import BJS

@MainActor
struct CountingComponentTests {

    @Test("Fill is decks played over the shoe, clamped")
    func fill() {
        #expect(DiscardTrayLayout.fillFraction(decksTotal: 6, decksPlayed: 1.5) == 0.25)
        #expect(DiscardTrayLayout.fillFraction(decksTotal: 6, decksPlayed: 9) == 1)
        #expect(DiscardTrayLayout.fillFraction(decksTotal: 6, decksPlayed: -1) == 0)
        #expect(DiscardTrayLayout.fillFraction(decksTotal: 0, decksPlayed: 1) == 0)
    }

    @Test("Whole-deck ticks sit between decks; none for a single deck")
    func ticks() {
        #expect(DiscardTrayLayout.tickFractions(decksTotal: 4) == [0.25, 0.5, 0.75])
        #expect(DiscardTrayLayout.tickFractions(decksTotal: 2) == [0.5])
        #expect(DiscardTrayLayout.tickFractions(decksTotal: 1).isEmpty)
    }

    @Test("VoiceOver rounds decks played to the nearest half")
    func accessibility() {
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 2.75) == "About 3 decks played")
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 2.6) == "About 2.5 decks played")
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 1) == "About 1 deck played")
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 0.25) == "About 0.5 decks played")
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `xcodegen generate`, then the app test command with `-only-testing:BJSTests/CountingComponentTests`.
Expected: the build fails. `DiscardTrayLayout` is undefined.

- [ ] **Step 3: Implement**

Create `BJS/Design/Components/DiscardTray.swift`:

```swift
import SwiftUI

enum DiscardTrayLayout {
    /// How full the tray is: decks played over the whole shoe, clamped to 0...1.
    static func fillFraction(decksTotal: Double, decksPlayed: Double) -> Double {
        guard decksTotal > 0 else { return 0 }
        return min(max(decksPlayed / decksTotal, 0), 1)
    }

    /// Heights (fractions from the bottom) of the faint whole-deck ticks, between decks.
    static func tickFractions(decksTotal: Double) -> [Double] {
        let whole = Int(decksTotal.rounded(.down))
        guard whole > 1 else { return [] }
        return (1..<whole).map { Double($0) / decksTotal }
    }

    /// Rounded to the nearest half deck, so VoiceOver users still estimate (Step 4 spec §2).
    static func accessibilityValue(decksPlayed: Double) -> String {
        let halves = (decksPlayed * 2).rounded() / 2
        let number = halves == halves.rounded() ? "\(Int(halves))" : String(format: "%.1f", halves)
        return "About \(number) \(halves == 1 ? "deck" : "decks") played"
    }
}

/// A discard tray: an outline the height of the whole shoe, filled from the bottom with the decks
/// already played as stacked cream card edges. Faint whole-deck ticks and no number: the user
/// estimates decks remaining as they would at a table.
struct DiscardTray: View {
    let decksTotal: Double
    let decksPlayed: Double
    var height: CGFloat = 160

    static let width: CGFloat = 64

    var body: some View {
        let fill = DiscardTrayLayout.fillFraction(decksTotal: decksTotal, decksPlayed: decksPlayed)
        let inner = height - 2 * FeltSpacing.xs
        let shape = RoundedRectangle(cornerRadius: FeltRadius.chip)
        ZStack(alignment: .bottom) {
            shape.fill(FeltColor.surfaceInset)
            StackedEdges(spacing: 3)
                .stroke(FeltColor.onCreamSecondary.opacity(0.5), lineWidth: 0.5)
                .background(FeltColor.cream)
                .frame(height: inner * fill)
                .clipShape(RoundedRectangle(cornerRadius: FeltRadius.chip - FeltSpacing.xs))
                .padding(FeltSpacing.xs)
            ForEach(DiscardTrayLayout.tickFractions(decksTotal: decksTotal), id: \.self) { fraction in
                Rectangle()
                    .fill(FeltColor.textTertiary.opacity(0.6))
                    .frame(width: FeltSpacing.m, height: 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(y: -(FeltSpacing.xs + inner * fraction))
            }
            shape.strokeBorder(FeltColor.textTertiary.opacity(0.6), lineWidth: 1)
        }
        .frame(width: Self.width, height: height)
        .accessibilityElement()
        .accessibilityLabel("Discard tray")
        .accessibilityValue(DiscardTrayLayout.accessibilityValue(decksPlayed: decksPlayed))
    }
}

/// Evenly spaced horizontal lines: the edges of stacked cards. `nonisolated` because SwiftUI draws
/// shapes off the main actor.
nonisolated struct StackedEdges: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y = rect.maxY - spacing
        while y > rect.minY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y -= spacing
        }
        return path
    }
}
```

In `FeltCatalogue.swift`, add a section after `section("Strategy components") { strategyComponents }`:

```swift
                    section("Counting components") {
                        HStack(alignment: .bottom, spacing: FeltSpacing.l) {
                            DiscardTray(decksTotal: 6, decksPlayed: 2.5)
                            DiscardTray(decksTotal: 8, decksPlayed: 6)
                            DiscardTray(decksTotal: 2, decksPlayed: 0.75)
                            DiscardTray(decksTotal: 1, decksPlayed: 0.25)
                        }
                    }
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: the app test command with `-only-testing:BJSTests/CountingComponentTests`.
Expected: all tests pass. The build has no warnings. Check the log with `grep -c "warning:" "$TMPDIR/bjs-test.log"`, and confirm no warning comes from `DiscardTray.swift`.

- [ ] **Step 5: Commit**

```bash
git add BJS/Design/Components/DiscardTray.swift BJS/Design/Catalogue/FeltCatalogue.swift BJSTests/Design/CountingComponentTests.swift
git commit -m "feat(counting): DiscardTray component

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: RC drill screen, trace sheet and shared summary

**Files:**
- Create:
  - `BJS/Features/Counting/RunningCountDrillView.swift`
  - `BJS/Features/Counting/CountTraceSheet.swift`
  - `BJS/Features/Counting/CountSummaryView.swift`

**Interfaces:**
- Consumes: Task 4's `RunningCountDrillViewModel` API; Task 3's `CountingText`, `CountSummaryModel` and `CloseButton`; the frozen components `PlayingCard`, `CountKeypad`, `CountEntry`, `FeedbackCard`, `StatChip`, `SettingsSection`, `SettingsRow`, `PrimaryButton`, `SecondaryButton`.
- Produces:
  - `RunningCountDrillView(model:onClose:onAgain:)`
  - `CountTraceSheet(entries:check:)`
  - `CountSummaryView(summary:saveFailed:onAgain:onDone:)`
- Accessibility identifiers used by the UI test: `counting.close`, `counting.progress`, `counting.summary`.

These are views, so there is no unit-test step. The ViewModel carries the behaviour, and Task 12's UI test drives this screen.

- [ ] **Step 1: Create `CountSummaryView.swift`**

```swift
import SwiftUI

struct CountSummaryView: View {
    let summary: CountSummaryModel
    let saveFailed: Bool
    let onAgain: () -> Void
    let onDone: () -> Void

    @State private var showsSaveAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                Text(summary.title).feltText(.display).foregroundStyle(FeltColor.textPrimary)
                    .accessibilityIdentifier("counting.summary")
                LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s),
                                    GridItem(.flexible(), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
                    StatChip(label: "Accuracy", value: PercentText.text(summary.score.accuracy))
                    StatChip(label: "Correct", value: "\(summary.score.correct) / \(summary.score.checks)")
                    StatChip(label: "Mean error", value: CountingText.meanError(summary.score.meanAbsoluteError))
                    if let secondsPerCard = summary.secondsPerCard {
                        StatChip(label: "Per card", value: CountingText.seconds(secondsPerCard))
                    }
                }
                if !summary.rows.isEmpty {
                    SettingsSection(title: summary.rowsTitle) {
                        ForEach(summary.rows) { row in
                            SettingsRow(label: row.label) { Text(row.value) }
                        }
                    }
                }
                PrimaryButton(title: "Again", action: onAgain)
                SecondaryButton(title: "Done", action: onDone)
            }
            .padding(FeltSpacing.l)
        }
        .onAppear { showsSaveAlert = saveFailed }
        .alert("Couldn't save this session", isPresented: $showsSaveAlert) {
            Button("OK") {}
        } message: {
            Text("Your results are shown here but won't appear in your progress.")
        }
    }
}
```

- [ ] **Step 2: Create `CountTraceSheet.swift`**

```swift
import SwiftUI
import BJSCore

/// The RC WHY sheet: every card since the previous checkpoint, its Hi-Lo value, and the count after it.
struct CountTraceSheet: View {
    let entries: [CountTraceEntry]
    let check: GradedCount
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            FeltBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.l) {
                    HStack {
                        Text("Card by card").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                        Spacer()
                        CloseButton(identifier: "counting.sheet.close") { dismiss() }
                    }
                    HStack(spacing: FeltSpacing.s) {
                        StatChip(label: "You said", value: CountingText.signed(Int(check.answered)))
                        StatChip(label: "Running count", value: CountingText.signed(Int(check.expected)))
                    }
                    SettingsSection(title: "Since the last check") {
                        ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                            SettingsRow(label: entry.card.spokenName) {
                                Text("\(CountingText.signed(entry.value))  →  \(CountingText.signed(entry.runningCount))")
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .padding(FeltSpacing.l)
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("counting.trace")
    }
}
```

- [ ] **Step 3: Create `RunningCountDrillView.swift`**

```swift
import SwiftUI
import BJSCore

struct RunningCountDrillView: View {
    @Bindable var model: RunningCountDrillViewModel
    let onClose: () -> Void
    let onAgain: () -> Void

    @Environment(PreferencesStore.self) private var preferences
    @Environment(\.scenePhase) private var scenePhase
    @State private var entry = CountEntry()
    @State private var showsLeaveDialog = false
    @State private var traceCheck: GradedCount?

    /// Three cards and two gaps fit the SE's 343 pt content width.
    private static let cardWidth: CGFloat = 96

    var body: some View {
        if model.phase == .summary {
            CountSummaryView(summary: model.summary, saveFailed: model.saveFailed, onAgain: onAgain, onDone: onClose)
        } else {
            drill
        }
    }

    private var drill: some View {
        GeometryReader { geo in
            VStack(spacing: FeltSpacing.l) {
                topBar
                Spacer(minLength: 0)
                cardArea
                Spacer(minLength: 0)
                bottomContent(bottomInset: geo.safeAreaInsets.bottom)
            }
            .padding(.horizontal, FeltSpacing.l)
            .overlay(alignment: .bottom) {
                // Carry the FeedbackCard's cream down through the home-indicator area.
                if case .feedback = model.phase {
                    FeltColor.cream
                        .frame(height: geo.safeAreaInsets.bottom)
                        .offset(y: geo.safeAreaInsets.bottom)
                        .accessibilityHidden(true)
                }
            }
        }
        .task(id: "\(model.presentationToken)-\(showsLeaveDialog)-\(scenePhase == .active)") {
            await runPresentationTimer()
        }
        .onChange(of: showsLeaveDialog) { wasShowing, isShowing in
            // The timer pauses behind the dialog; the current group gets a fresh interval on return.
            if wasShowing && !isShowing { model.resumeAfterInterruption() }
        }
        .onChange(of: scenePhase) { was, now in
            if was != .active && now == .active { model.resumeAfterInterruption() }
        }
        .sensoryFeedback(trigger: model.checks.count) { _, _ in
            guard preferences.hapticsEnabled, let last = model.checks.last else { return nil }
            return last.isCorrect ? .success : .error
        }
        .confirmationDialog("Leave this drill?", isPresented: $showsLeaveDialog, titleVisibility: .visible) {
            Button("Save partial") { model.finish() }
            Button("Discard", role: .destructive, action: onClose)
            Button("Keep going", role: .cancel) {}
        }
        .sheet(item: $traceCheck) { check in
            CountTraceSheet(entries: model.trace(for: check), check: check)
        }
    }

    private var topBar: some View {
        HStack(spacing: FeltSpacing.m) {
            CloseButton(identifier: "counting.close") {
                if model.canSavePartial { showsLeaveDialog = true } else { onClose() }
            }
            Text("Card \(model.cardsShown) / \(model.totalCards)")
                .feltText(.label).foregroundStyle(FeltColor.textTertiary)
                .accessibilityIdentifier("counting.progress")
            Spacer()
            Text("\(model.correctCount) / \(model.checks.count)")
                .feltText(.stat).foregroundStyle(FeltColor.textPrimary)
                .accessibilityLabel("Correct checks")
                .accessibilityValue("\(model.correctCount) of \(model.checks.count)")
        }
    }

    @ViewBuilder private var cardArea: some View {
        switch model.phase {
        case .presenting:
            HStack(spacing: FeltSpacing.m) {
                ForEach(Array(model.visibleCards.enumerated()), id: \.offset) { _, card in
                    PlayingCard(card: card, width: Self.cardWidth)
                }
            }
            // A fresh identity per group, so a repeated card still reads as a new deal.
            .id(model.presentationToken)
        case .answering:
            Text("Running count?").feltText(.title).foregroundStyle(FeltColor.textPrimary)
        case .feedback, .summary:
            EmptyView()
        }
    }

    @ViewBuilder private func bottomContent(bottomInset: CGFloat) -> some View {
        switch model.phase {
        case .answering:
            CountKeypad(entry: $entry, allowsHalf: false) { model.submit($0) }
                .padding(.bottom, bottomInset > 0 ? 0 : FeltSpacing.l)
        case .feedback(let graded):
            let text = CountingText.runningFeedback(expected: Int(graded.expected), answered: Int(graded.answered))
            FeedbackCard(verdict: graded.isCorrect ? .correct : .incorrect, headline: text.headline,
                         reason: text.reason, onWhy: { traceCheck = graded }, onNext: { model.next() })
                .padding(.horizontal, -FeltSpacing.l)
        case .presenting, .summary:
            EmptyView()
        }
    }

    private func runPresentationTimer() async {
        guard case .presenting = model.phase, !showsLeaveDialog, scenePhase == .active else { return }
        let token = model.presentationToken
        try? await Task.sleep(for: .seconds(model.pace))
        guard !Task.isCancelled else { return }
        model.advance(token: token)
    }
}
```

- [ ] **Step 4: Build**

Run: `xcodegen generate && xcodebuild build -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' > "$TMPDIR/bjs-build.log" 2>&1; grep -E "error:|warning:|BUILD" "$TMPDIR/bjs-build.log" | tail -20`
Expected: `** BUILD SUCCEEDED **` with no new warnings.

- [ ] **Step 5: Commit**

```bash
git add BJS/Features/Counting/RunningCountDrillView.swift BJS/Features/Counting/CountTraceSheet.swift BJS/Features/Counting/CountSummaryView.swift
git commit -m "feat(counting): running count drill screen, trace sheet and summary

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: TC drill screen and working sheet

**Files:**
- Create: `BJS/Features/Counting/TrueCountDrillView.swift` and `BJS/Features/Counting/TrueCountWorkingSheet.swift`

**Interfaces:**
- Consumes: Task 5's `TrueCountDrillViewModel` API, Task 7's `DiscardTray`, and Task 8's `CountSummaryView`.
- Produces: `TrueCountDrillView(model:onClose:onAgain:)` and `TrueCountWorkingSheet(question:convention:deckCount:answered:)`.

- [ ] **Step 1: Create `TrueCountWorkingSheet.swift`**

```swift
import SwiftUI
import BJSCore

/// The TC WHY sheet: the working and the convention's rule.
struct TrueCountWorkingSheet: View {
    let question: TrueCountQuestion
    let convention: TrueCountConvention
    let deckCount: Int
    let answered: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            FeltBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.l) {
                    HStack {
                        Text("The working").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                        Spacer()
                        CloseButton(identifier: "counting.sheet.close") { dismiss() }
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s),
                                        GridItem(.flexible(), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
                        StatChip(label: "Running count", value: CountingText.signed(question.runningCount))
                        StatChip(label: "Decks left", value: CountingText.decks(question.decksRemaining))
                        StatChip(label: "RC ÷ decks", value: CountingText.signed(question.exactTrueCount))
                        StatChip(label: "Answer", value: CountingText.signed(question.keypadAnswer(for: convention)))
                        StatChip(label: "You said", value: CountingText.signed(answered))
                    }
                    Text(CountingText.conventionRule(convention))
                        .feltText(.body).foregroundStyle(FeltColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("The tray shows the decks already played out of a \(deckCount)-deck shoe. "
                         + "Decks left is the shoe minus the tray.")
                        .feltText(.body).foregroundStyle(FeltColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(FeltSpacing.l)
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("counting.working")
    }
}
```

- [ ] **Step 2: Create `TrueCountDrillView.swift`**

```swift
import SwiftUI
import BJSCore

struct TrueCountDrillView: View {
    @Bindable var model: TrueCountDrillViewModel
    let onClose: () -> Void
    let onAgain: () -> Void

    @Environment(PreferencesStore.self) private var preferences
    @Environment(\.scenePhase) private var scenePhase
    @State private var entry = CountEntry()
    @State private var showsLeaveDialog = false
    @State private var workingCheck: GradedCount?

    var body: some View {
        if model.phase == .summary {
            CountSummaryView(summary: model.summary, saveFailed: model.saveFailed, onAgain: onAgain, onDone: onClose)
        } else {
            drill
        }
    }

    private var drill: some View {
        GeometryReader { geo in
            VStack(spacing: FeltSpacing.l) {
                topBar
                Spacer(minLength: 0)
                HStack(alignment: .center, spacing: FeltSpacing.xl) {
                    StatChip(label: "Running count", value: CountingText.signed(model.question.runningCount))
                        .frame(maxWidth: 160)
                    DiscardTray(decksTotal: Double(model.deckCount), decksPlayed: model.decksPlayed)
                }
                Spacer(minLength: 0)
                bottomContent(bottomInset: geo.safeAreaInsets.bottom)
            }
            .padding(.horizontal, FeltSpacing.l)
            .overlay(alignment: .bottom) {
                if case .feedback = model.phase {
                    FeltColor.cream
                        .frame(height: geo.safeAreaInsets.bottom)
                        .offset(y: geo.safeAreaInsets.bottom)
                        .accessibilityHidden(true)
                }
            }
        }
        .onChange(of: showsLeaveDialog) { wasShowing, isShowing in
            if wasShowing && !isShowing { model.resumeAfterInterruption() }
        }
        .onChange(of: scenePhase) { was, now in
            if was != .active && now == .active { model.resumeAfterInterruption() }
        }
        .sensoryFeedback(trigger: model.checks.count) { _, _ in
            guard preferences.hapticsEnabled, let last = model.checks.last else { return nil }
            return last.isCorrect ? .success : .error
        }
        .confirmationDialog("Leave this drill?", isPresented: $showsLeaveDialog, titleVisibility: .visible) {
            Button("Save partial") { model.finish() }
            Button("Discard", role: .destructive, action: onClose)
            Button("Keep going", role: .cancel) {}
        }
        .sheet(item: $workingCheck) { check in
            TrueCountWorkingSheet(question: model.question(for: check), convention: model.convention,
                                  deckCount: model.deckCount, answered: check.answered)
        }
    }

    private var topBar: some View {
        HStack(spacing: FeltSpacing.m) {
            CloseButton(identifier: "counting.close") {
                if model.canSavePartial { showsLeaveDialog = true } else { onClose() }
            }
            Text(model.questionLimit.map { "Question \(model.questionNumber) / \($0)" }
                 ?? "Question \(model.questionNumber)")
                .feltText(.label).foregroundStyle(FeltColor.textTertiary)
                .accessibilityIdentifier("counting.progress")
            Spacer()
            Text("\(model.correctCount) / \(model.checks.count)")
                .feltText(.stat).foregroundStyle(FeltColor.textPrimary)
                .accessibilityLabel("Correct answers")
                .accessibilityValue("\(model.correctCount) of \(model.checks.count)")
            if model.questionLimit == nil {
                Button("END") {
                    if model.checks.isEmpty { onClose() } else { model.finish() }
                }
                .feltText(.label).foregroundStyle(FeltColor.textPrimary)
                .frame(minWidth: FeltTapTarget.minimum, minHeight: FeltTapTarget.minimum)
                .accessibilityIdentifier("counting.end")
            }
        }
    }

    @ViewBuilder private func bottomContent(bottomInset: CGFloat) -> some View {
        switch model.phase {
        case .question:
            CountKeypad(entry: $entry, allowsHalf: model.allowsHalf) { model.submit($0) }
                .padding(.bottom, bottomInset > 0 ? 0 : FeltSpacing.l)
        case .feedback(let graded):
            let text = CountingText.trueFeedback(question: model.question(for: graded), convention: model.convention,
                                                 answered: graded.answered, isCorrect: graded.isCorrect)
            FeedbackCard(verdict: graded.isCorrect ? .correct : .incorrect, headline: text.headline,
                         reason: text.reason, onWhy: { workingCheck = graded }, onNext: { model.next() })
                .padding(.horizontal, -FeltSpacing.l)
        case .summary:
            EmptyView()
        }
    }
}
```

- [ ] **Step 3: Build**

Run: the Task 8 build command.
Expected: `** BUILD SUCCEEDED **` with no new warnings.

- [ ] **Step 4: Commit**

```bash
git add BJS/Features/Counting/TrueCountDrillView.swift BJS/Features/Counting/TrueCountWorkingSheet.swift
git commit -m "feat(counting): true count drill screen and working sheet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Card values screen

**Files:**
- Create: `BJS/Features/Counting/CountingHeader.swift` and `BJS/Features/Counting/CardValuesView.swift`

**Interfaces:**
- Consumes: Task 6's `CardValuesViewModel`; the frozen components `FeltToast`, `FeedbackCard`, `PlayingCard`, `SecondaryButton`, `SettingsSection` and `SettingsRow`.
- Produces:
  - `CountingHeader(title:onBack:)`, with the back button identified as `counting.back`
  - `CardValuesView(model:onBack:)`, with the answer buttons identified as `counting.value.1`, `counting.value.0` and `counting.value.-1`

- [ ] **Step 1: Create `CountingHeader.swift`**

```swift
import SwiftUI

/// Title row for Counting's setup and reference screens, with a back chevron to the Counting menu.
struct CountingHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: FeltSpacing.xs) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FeltColor.textSecondary)
                    .frame(width: FeltTapTarget.minimum, height: FeltTapTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("counting.back")
            Text(title).feltText(.display).foregroundStyle(FeltColor.textPrimary)
            Spacer()
        }
    }
}
```

- [ ] **Step 2: Create `CardValuesView.swift`**

```swift
import SwiftUI
import BJSCore

/// The Hi-Lo values table and an endless one-card self-test (Step 4 spec §4). Nothing is saved.
struct CardValuesView: View {
    @Bindable var model: CardValuesViewModel
    let onBack: () -> Void

    @Environment(PreferencesStore.self) private var preferences
    @State private var showsToast = false

    private struct ValueRow: Identifiable {
        let value: Int
        let ranks: [Rank]
        var id: Int { value }
    }

    private static let rows: [ValueRow] = [
        ValueRow(value: 1, ranks: [.two, .three, .four, .five, .six]),
        ValueRow(value: 0, ranks: [.seven, .eight, .nine]),
        ValueRow(value: -1, ranks: [.ten, .jack, .queen, .king, .ace]),
    ]

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                        CountingHeader(title: "Card values", onBack: onBack)
                        SettingsSection(title: "Hi-Lo values") {
                            ForEach(Self.rows) { row in
                                SettingsRow(label: CountingText.signed(row.value)) {
                                    HStack(spacing: FeltSpacing.xs) {
                                        ForEach(row.ranks, id: \.self) { rank in
                                            PlayingCard(card: Card(rank: rank, suit: .spades), width: 28)
                                        }
                                    }
                                }
                                .id(row.value)
                            }
                        }
                        selfTest
                    }
                    .padding(FeltSpacing.l)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if let mistake = model.mistake {
                        let text = CountingText.cardValueFeedback(rank: mistake.rank)
                        FeedbackCard(verdict: .incorrect, headline: text.headline, reason: text.reason,
                                     onWhy: {
                                         withAnimation(FeltMotion.ui) {
                                             proxy.scrollTo(mistake.rank.hiLoValue, anchor: .top)
                                         }
                                     },
                                     onNext: { model.next() })
                            .overlay(alignment: .bottom) {
                                FeltColor.cream
                                    .frame(height: geo.safeAreaInsets.bottom)
                                    .offset(y: geo.safeAreaInsets.bottom)
                                    .accessibilityHidden(true)
                            }
                    }
                }
            }
        }
        .onChange(of: model.toastCount) { flashToast() }
        .sensoryFeedback(trigger: model.answered) { _, _ in
            guard preferences.hapticsEnabled else { return nil }
            return model.mistake == nil ? .success : .error
        }
    }

    private var selfTest: some View {
        VStack(spacing: FeltSpacing.l) {
            Text("Quick test").feltText(.label).foregroundStyle(FeltColor.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            ZStack {
                if showsToast { FeltToast(text: "Correct").fixedSize().transition(.opacity) }
            }
            .frame(height: FeltTapTarget.minimum)
            PlayingCard(card: model.card, width: 96)
                // A fresh identity per card, so a repeat still reads as a new card.
                .id(model.answered)
            HStack(spacing: FeltSpacing.s) {
                ForEach([1, 0, -1], id: \.self) { value in
                    SecondaryButton(title: CountingText.signed(value)) { model.answer(value) }
                        .accessibilityIdentifier("counting.value.\(value)")
                }
            }
            .disabled(model.mistake != nil)
            Text("Score \(model.correct) / \(model.answered) · Streak \(model.streak)")
                .feltText(.body).foregroundStyle(FeltColor.textSecondary)
        }
    }

    private func flashToast() {
        withAnimation(FeltMotion.ui) { showsToast = true }
        AccessibilityNotification.Announcement("Correct").post()
        Task {
            try? await Task.sleep(for: .seconds(FeltToast.displayDuration))
            withAnimation(FeltMotion.ui) { showsToast = false }
        }
    }
}
```

- [ ] **Step 3: Build**

Run: the Task 8 build command.
Expected: `** BUILD SUCCEEDED **` with no new warnings.

- [ ] **Step 4: Commit**

```bash
git add BJS/Features/Counting/CountingHeader.swift BJS/Features/Counting/CardValuesView.swift
git commit -m "feat(counting): card values reference and self-test screen

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Menu, setup screens, flow, routing and the `-countPace` hook

**Files:**
- Create:
  - `BJS/Features/Counting/CountingMenuView.swift`
  - `BJS/Features/Counting/RunningCountSetupView.swift`
  - `BJS/Features/Counting/TrueCountSetupView.swift`
  - `BJS/Features/Counting/CountingFlowView.swift`
- Modify: `BJS/App/ModuleHost.swift` and `BJS/App/LaunchConfiguration.swift`
- Test: `BJSTests/AppShellTests.swift`

**Interfaces:**
- Consumes: every earlier counting type.
- Produces:
  - `enum CountingScreen { launching, menu, runningSetup, trueSetup, cardValues, running, trueCount }`
  - `CountingFlowView(initialSetup: CountingSetup?, paceOverride: Double?, seed: UInt64?, onClose:)`
  - `LaunchConfiguration.countPace: Double?`
- Identifiers:
  - menu tiles: `counting.menu.running`, `counting.menu.true`, `counting.menu.values`
  - Start: `counting.start`
  - menu close: `counting.close`

- [ ] **Step 1: Write the failing launch-hook test**

In `BJSTests/AppShellTests.swift`, add inside the suite after `strategyHooks()`:

```swift
    @Test("The counting pace hook is read only under -uiTesting")
    func countPaceHook() {
        #expect(LaunchConfiguration(arguments: ["-uiTesting", "-countPace", "0.3"]).countPace == 0.3)
        #expect(LaunchConfiguration(arguments: ["-countPace", "0.3"]).countPace == nil)
        #expect(LaunchConfiguration(arguments: ["-uiTesting"]).countPace == nil)
    }
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `xcodegen generate`, then the app test command with `-only-testing:BJSTests/AppShellTests`.
Expected: the build fails. `countPace` doesn't exist.

- [ ] **Step 3: Add the hook**

In `LaunchConfiguration.swift`, add this property after `seed`:

```swift
    /// UI testing only: overrides the running-count drill's pace (seconds per group).
    let countPace: Double?
```

Add this line in `init` after the `seed = …` line:

```swift
        countPace = isUITesting ? value(after: "-countPace").flatMap { Double($0) } : nil
```

Update the `seed` doc comment to: `/// UI testing only: seeds the Strategy trainer's and the counting drills' random number generators.`

- [ ] **Step 4: Create `CountingMenuView.swift`**

```swift
import SwiftUI

struct CountingMenuView: View {
    let onSelect: (CountingScreen) -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                HStack {
                    Text("Counting").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                    Spacer()
                    CloseButton(identifier: "counting.close", action: onClose)
                }
                VStack(spacing: FeltSpacing.m) {
                    ModuleTile(title: "Running count", subtitle: "Keep the count as cards flash past") {
                        onSelect(.runningSetup)
                    }
                    .accessibilityIdentifier("counting.menu.running")
                    ModuleTile(title: "True count", subtitle: "Turn a running count into a true count") {
                        onSelect(.trueSetup)
                    }
                    .accessibilityIdentifier("counting.menu.true")
                    ModuleTile(title: "Card values", subtitle: "Learn and test the Hi-Lo values") {
                        onSelect(.cardValues)
                    }
                    .accessibilityIdentifier("counting.menu.values")
                }
            }
            .padding(FeltSpacing.l)
        }
    }
}
```

- [ ] **Step 5: Create `RunningCountSetupView.swift`**

```swift
import SwiftUI

struct RunningCountSetupView: View {
    @Binding var setup: RunningCountSetup
    let onStart: () -> Void
    let onBack: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                CountingHeader(title: "Running count", onBack: onBack)
                group("Cards at a time") {
                    ModePicker(options: RunningCountSetup.groupSizes, selection: $setup.groupSize) { "\($0)" }
                }
                group("Cards") {
                    ModePicker(options: RunningCountLength.options, selection: $setup.length) { $0.title }
                }
                SettingsSection(title: "Pace and checks") {
                    SettingsRow(label: "Per group", footnote: "Lower is faster.") {
                        Stepper(value: $setup.paceTenths, in: RunningCountSetup.paceTenthsRange) {
                            Text(CountingText.pace(setup.pace)).feltText(.body)
                        }
                        .fixedSize(horizontal: !FeltAdaptiveLayout.stacksVertically(dynamicTypeSize), vertical: true)
                    }
                    SettingsRow(label: "Random checks",
                                footnote: "You're always asked at the end. Random checks come about once every 8 groups.") {
                        Toggle("Random checks", isOn: $setup.randomCheckpoints).labelsHidden()
                    }
                }
                PrimaryButton(title: "Start", action: onStart)
                    .accessibilityIdentifier("counting.start")
            }
            .padding(FeltSpacing.l)
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text(title).feltText(.label).foregroundStyle(FeltColor.textTertiary)
            content()
        }
    }
}
```

- [ ] **Step 6: Create `TrueCountSetupView.swift`**

```swift
import SwiftUI
import BJSCore

struct TrueCountSetupView: View {
    @Binding var setup: TrueCountSetup
    let convention: TrueCountConvention
    let deckCount: BlackjackRules.DeckCount
    let onStart: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                CountingHeader(title: "True count", onBack: onBack)
                VStack(alignment: .leading, spacing: FeltSpacing.s) {
                    Text("Questions").feltText(.label).foregroundStyle(FeltColor.textTertiary)
                    ModePicker(options: TrueCountLength.options, selection: $setup.length) { $0.title }
                }
                SettingsSection(title: "Grading") {
                    SettingsRow(label: "Rounding",
                                footnote: "\(CountingText.conventionRule(convention)) Change it in Settings.") {
                        Text(convention.label)
                    }
                    SettingsRow(label: "Shoe") { Text(deckCount.label) }
                }
                PrimaryButton(title: "Start", action: onStart)
                    .accessibilityIdentifier("counting.start")
            }
            .padding(FeltSpacing.l)
        }
    }
}
```

- [ ] **Step 7: Create `CountingFlowView.swift`**

```swift
import os
import SwiftUI
import BJSCore

enum CountingScreen: Equatable {
    /// Continue: blank until the saved drill starts, so the menu doesn't flash.
    case launching
    case menu
    case runningSetup
    case trueSetup
    case cardValues
    case running
    case trueCount
}

/// Menu → setup → drill → summary for one full-screen Counting launch (Step 4 spec §2).
struct CountingFlowView: View {
    /// Non-nil (Continue): start that drill straight away.
    let initialSetup: CountingSetup?
    var paceOverride: Double? = nil
    var seed: UInt64? = nil
    let onClose: () -> Void

    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(PreferencesStore.self) private var preferences
    @Environment(SessionStore.self) private var sessionStore
    @State private var screen: CountingScreen
    @State private var runningSetup = RunningCountSetup()
    @State private var trueSetup = TrueCountSetup()
    @State private var running: RunningCountDrillViewModel?
    @State private var trueCount: TrueCountDrillViewModel?
    @State private var cardValues: CardValuesViewModel?
    @State private var didAutoStart = false

    private let logger = Logger(subsystem: "com.bjs.app", category: "CountingFlow")

    init(initialSetup: CountingSetup?, paceOverride: Double? = nil, seed: UInt64? = nil,
         onClose: @escaping () -> Void) {
        self.initialSetup = initialSetup
        self.paceOverride = paceOverride
        self.seed = seed
        self.onClose = onClose
        _screen = State(initialValue: initialSetup == nil ? .menu : .launching)
    }

    var body: some View {
        ZStack {
            FeltBackground()
            content
        }
        .task {
            guard let initialSetup, !didAutoStart else { return }
            didAutoStart = true
            switch initialSetup {
            case .runningCount(let setup):
                runningSetup = setup
                startRunning(setup)
            case .trueCount(let setup):
                trueSetup = setup
                startTrueCount(setup)
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch screen {
        case .launching:
            EmptyView()
        case .menu:
            CountingMenuView(onSelect: open, onClose: onClose)
        case .runningSetup:
            RunningCountSetupView(setup: $runningSetup, onStart: { startRunning(runningSetup) },
                                  onBack: { screen = .menu })
        case .trueSetup:
            TrueCountSetupView(setup: $trueSetup, convention: preferences.trueCountConvention,
                               deckCount: rulesStore.rules.deckCount,
                               onStart: { startTrueCount(trueSetup) }, onBack: { screen = .menu })
        case .cardValues:
            if let cardValues {
                CardValuesView(model: cardValues, onBack: { screen = .menu })
            }
        case .running:
            if let running {
                RunningCountDrillView(model: running, onClose: onClose, onAgain: { startRunning(running.setup) })
                    .id(running.sessionID)
            }
        case .trueCount:
            if let trueCount {
                TrueCountDrillView(model: trueCount, onClose: onClose, onAgain: { startTrueCount(trueCount.setup) })
                    .id(trueCount.sessionID)
            }
        }
    }

    private func open(_ next: CountingScreen) {
        if next == .cardValues {
            cardValues = CardValuesViewModel(seed: seed ?? UInt64.random(in: .min ... .max))
        }
        screen = next
    }

    private func startRunning(_ setup: RunningCountSetup) {
        remember(.runningCount(setup))
        let store = sessionStore
        running = RunningCountDrillViewModel(
            setup: setup, rules: rulesStore.rules, paceOverride: paceOverride,
            seed: seed ?? UInt64.random(in: .min ... .max), persist: { try store.save($0) })
        screen = .running
    }

    private func startTrueCount(_ setup: TrueCountSetup) {
        remember(.trueCount(setup))
        let store = sessionStore
        trueCount = TrueCountDrillViewModel(
            setup: setup, rules: rulesStore.rules, convention: preferences.trueCountConvention,
            seed: seed ?? UInt64.random(in: .min ... .max), persist: { try store.save($0) })
        screen = .trueCount
    }

    private func remember(_ setup: CountingSetup) {
        do {
            preferences.lastLaunch = try setup.lastLaunch()
        } catch {
            logger.error("lastLaunch failed to encode: \(error.localizedDescription)")
        }
    }
}
```

- [ ] **Step 8: Route `.counting` in `ModuleHost`**

Replace the `case .counting, .shoe, .edge:` branch in `ModuleHost.swift` with:

```swift
        case .counting:
            CountingFlowView(initialSetup: launch.setup.flatMap(CountingSetup.decode),
                             paceOverride: configuration.countPace, seed: configuration.seed,
                             onClose: onClose)
        case .shoe, .edge:
            ComingSoonView(title: launch.module.title, message: "Coming in Step \(launch.module.step)",
                           onClose: onClose)
```

- [ ] **Step 9: Run the tests and confirm they pass**

Run: `xcodegen generate`, then the full app test command.
Expected: all unit and UI tests pass, including `countPaceHook`.

- [ ] **Step 10: Commit**

```bash
git add BJS/Features/Counting BJS/App BJSTests/AppShellTests.swift
git commit -m "feat(counting): counting menu, setups, flow and module routing

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12: `countSamples(forStats:)` test and the RC UI test

**Files:**
- Modify: `BJSTests/Persistence/SessionStoreTests.swift`
- Create: `BJSUITests/CountingUITests.swift`

**Interfaces:**
- Consumes: `SessionStore.countSamples(modules:forStats:)` (existing), and the identifiers from Tasks 8 and 11.

- [ ] **Step 1: Add the persistence test (the Step 3 carry-over)**

Add this inside `SessionStoreTests`:

```swift
    @Test("countSamples(forStats:) drops Learn sessions only when asked for stats")
    func countSamplesForStats() throws {
        let learnCheck = CountCheckDraft(kind: .runningCount, expected: 1, answered: 1, isCorrect: true,
                                         responseMs: 900, cardsSeen: 10, checkedAt: t(101))
        try store.save(SessionDraft(module: .strategy, mode: "learn", startedAt: t(100), endedAt: t(160),
                                    rules: BlackjackRules(), countChecks: [learnCheck]))
        let tcCheck = CountCheckDraft(kind: .trueCount, expected: 2, answered: 2, isCorrect: true,
                                      responseMs: 1200, cardsSeen: 104, checkedAt: t(201))
        try store.save(SessionDraft(module: .countingTC, mode: "exact", startedAt: t(200), endedAt: t(260),
                                    rules: BlackjackRules(), countChecks: [tcCheck]))

        #expect(try store.countSamples().map(\.kind) == [.trueCount])
        #expect(try store.countSamples(forStats: false).map(\.kind) == [.runningCount, .trueCount])
        #expect(try store.countSamples(modules: [.countingTC]).count == 1)
        #expect(try store.countSamples(modules: [.countingRC]).isEmpty)
    }
```

- [ ] **Step 2: Run it**

Run: the app test command with `-only-testing:BJSTests/SessionStoreTests`.
Expected: all tests pass. This covers existing behaviour, so it should pass straight away. If it fails, stop and investigate: that would be a real bug.

- [ ] **Step 3: Write the UI test**

Create `BJSUITests/CountingUITests.swift`:

```swift
import XCTest

@MainActor
final class CountingUITests: XCTestCase {

    func testTenCardRunningCountDrillReachesSummary() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-seed", "1", "-countPace", "0.3"]
        app.launch()

        let tile = app.buttons["hub.tile.counting"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.tap()

        let running = app.buttons["counting.menu.running"]
        XCTAssertTrue(running.waitForExistence(timeout: 5))
        running.tap()

        let ten = app.buttons["10"]
        XCTAssertTrue(ten.waitForExistence(timeout: 5))
        ten.tap()
        app.buttons["counting.start"].tap()

        // 10 cards at 0.3 s each, then the end-of-drill checkpoint.
        let enter = app.buttons["Enter"]
        XCTAssertTrue(enter.waitForExistence(timeout: 15), "keypad at the checkpoint")
        app.buttons["0"].tap()
        enter.tap()

        let next = app.buttons["NEXT"]
        XCTAssertTrue(next.waitForExistence(timeout: 5), "feedback after the answer")
        next.tap()

        XCTAssertTrue(app.staticTexts["counting.summary"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        let hubContinue = app.buttons["hub.continue"]
        XCTAssertTrue(hubContinue.waitForExistence(timeout: 5))
        hubContinue.tap()

        // Continue reopens the drill directly: no menu, no setup.
        XCTAssertTrue(app.staticTexts["counting.progress"].waitForExistence(timeout: 5),
                      "Continue should reopen the running count drill")
        XCTAssertFalse(app.buttons["counting.start"].exists)

        app.buttons["counting.close"].tap()
        // No check has been answered yet in this drill, so it closes without the leave dialog; handle
        // the dialog anyway so the test stays deterministic.
        let discard = app.buttons["Discard"]
        if discard.waitForExistence(timeout: 2) { discard.tap() }
        XCTAssertTrue(app.buttons["hub.continue"].waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 4: Run it**

Run: `xcodegen generate`, then the app test command with `-only-testing:BJSUITests/CountingUITests`.
Expected: the test passes.
- If `app.buttons["0"]` or `["Enter"]` doesn't resolve, check the keypad's `accessibilityLabel`s in `CountKeypad.swift` (they are `"0"` and `"Enter"`).
- If `app.buttons["10"]` is ambiguous, scope it with `app.buttons.matching(identifier: "10").firstMatch`.

- [ ] **Step 5: Run the full suite**

Run: `cd BJSCore && swift test`, then the full app test command.
Expected: BJSCore has 229 tests plus the new ones, all passing. The app unit tests all pass, as do 3 UI tests (Foundation, Strategy, Counting). There are no warnings.

- [ ] **Step 6: Commit**

```bash
git add BJSTests/Persistence/SessionStoreTests.swift BJSUITests/CountingUITests.swift
git commit -m "test(counting): countSamples stats filter and RC drill UI test

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 13: Design check and handoff

**Files:**
- Temporary (not committed): `BJSUITests/CountingScreenshotTests.swift`
- Modify: `docs/superpowers/progress.md`

- [ ] **Step 1: Capture the screenshots**

Write a temporary XCUITest, `CountingScreenshotTests`, that launches with `-uiTesting -seed 1 -countPace 2.0`. It saves an `XCTAttachment(screenshot: app.screenshot())` with `lifetime = .keepAlways` at each state:
- the Counting menu;
- the RC setup;
- RC presenting (with 3 cards at a time: select "3" before Start);
- the RC keypad;
- RC feedback;
- the trace sheet (tap WHY);
- the RC summary;
- the TC setup;
- a TC question with `DiscardTray`;
- TC feedback;
- the TC working sheet;
- Card values: the table, and a wrong-answer FeedbackCard (tap the wrong value for the shown card, by reading the card's accessibility label).

Run it on both simulators:
- `name=iPhone 16,OS=18.4`
- `name=iPhone SE (3rd generation),OS=18.3`

Add `-resultBundlePath "$TMPDIR/counting-<device>.xcresult"`. Export the attachments with `xcrun xcresulttool export attachments --path <bundle> --output-path "$TMPDIR/counting-shots-<device>"`.

- [ ] **Step 2: Compare against parent spec §4 (a conformance check, not a redesign)**

For each screenshot, check:
- only Felt tokens are used;
- brass does not appear (there are no hints in Counting);
- text on cream is `onCream` / `onCreamSecondary`;
- tap targets are ≥ 44 pt;
- nothing truncates or overlaps on the SE;
- the three-card group fits the SE width;
- the keypad and FeedbackCard don't clip on the SE;
- the cream runs to the bottom edge under the FeedbackCard;
- `DiscardTray` reads as a tray.

Fix layout problems in the Counting views only. Never touch frozen components or tokens. Commit any fixes as `fix(counting): …`. Also confirm the contrast test (`FeltColorTests`) is still green, and open `FeltCatalogue` (`-showCatalogue`) to check the Counting components section.

- [ ] **Step 3: Delete the temporary screenshot test**

```bash
rm BJSUITests/CountingScreenshotTests.swift
xcodegen generate
```

Keep the screenshots in the session scratchpad for Luke. Don't commit them.

- [ ] **Step 4: Final verification**

Run: `cd BJSCore && swift test`, then the full app test command.
Expected: everything passes with no warnings. Record the exact counts.

- [ ] **Step 5: Append the Step 4 handoff to `docs/superpowers/progress.md`**

Add a `## Step 4 — Counting (YYYY-MM-DD)` entry in the same style as the Step 3 entry:
- spec and plan paths, branch and commit range;
- test counts;
- Luke's decisions (Step 4 spec §1);
- what shipped (BJSCore / Counting / new component);
- deviations from this plan;
- any items that need Luke's decision (with screenshots);
- deferred minors;
- carry-overs still open. Step 3's `countSamples(forStats:)` item is now resolved; keep the Step 5/6/8 carry-overs. Add for Step 8: `DiscardTray` and the counting screens need the AX3 pass.
- `Next: Step 5 (Edge)`.

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/progress.md
git commit -m "docs: Step 4 handoff

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

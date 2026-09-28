# Step 6 — Progress Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Progress tab: per-module headlines, a daily accuracy trend, the strategy heat map, and a session history that opens a read-only session detail with WHY for strategy mistakes.

**Architecture:**
- **BJSCore** gets three pure additions:
  - `ProgressRange`, the calendar-day window, which the hub also adopts;
  - `HeatBin` and `HeatMapLayout`, for binning and row layout;
  - `WhyContext(cell:…)`, which rebuilds WHY from saved data with no schema change.
- **`SessionStore`** gains ranged fetches, `historyEntries()` and `sessionDetail(id:)`.
- **`Features/Progress`** holds:
  - `ProgressText`, all copy;
  - `ProgressViewModel` and `SessionDetailViewModel`, thin mappers;
  - `ProgressTabView` and `SessionDetailView`, built on the new Felt component `HeatMapGrid`.
- **`Shared/`** receives `WhySheet` and the shared text helpers (`TrainingText`), so Progress never imports another feature.
- **Fixture:** a DEBUG `-progressFixture` launch argument seeds a deterministic history for the UI test and the design check.

**Tech Stack:** Swift 6.2, SwiftUI, Swift Charts, SwiftData, iOS 18+, Swift Testing, XCTest (UI), XcodeGen.

**Spec:** `docs/superpowers/specs/2026-09-27-step-6-progress-design.md`. Parent spec: `docs/superpowers/specs/2026-09-23-bjs-rebuild-design.md` (§4 design system, §5 Progress, §6 data, §7 testing). Read both before starting.

## Global Constraints

- **Engine rules:** all game logic lives in `BJSCore`, which never imports SwiftUI or SwiftData. ViewModels are thin adapters.
- **Feature isolation:** feature folders never import each other. `Features/Progress` must not use anything defined in `Features/Strategy`, `Features/Counting`, `Features/Hub`, `Features/Edge` or `Features/Settings`. Shared code comes from `Design/`, `Shared/`, `Persistence/` or `BJSCore`.
- **XcodeGen** owns the project. After adding, moving or removing files, run `xcodegen generate`. Never edit `.xcodeproj`.
- **The Felt design system is frozen:**
  - don't change any existing token or component in `BJS/Design/Tokens` or `BJS/Design/Components`;
  - `HeatMapGrid` (with its `HeatMapSwatch` and `HeatMapLegend`) is the only new component, built from existing tokens;
  - adding a section to the DEBUG `FeltCatalogue` is allowed.
- **Brass** (`FeltColor.brass`) is not used anywhere in Progress.
- **Isolation and tests:**
  - The app target is main-actor by default (`SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor`), and app test suites are marked `@MainActor`.
  - Swift Testing (`@Test`, `#expect`) for unit tests; XCTest only for UI tests.
- **No schema change.** `SchemaV1` stays exactly as it is.
- **Stats vs history:** stats (headlines, trend, heat map) exclude Learn sessions (`forStats: true`, the default). History (`historyEntries`) includes them.
- **Copy** is verbatim from the spec. The em dash `—` (`PercentText.noData`) means no data. The minus sign is `\u{2212}` (`TrainingText.minus`).
- **Commits:** commit after each task with a conventional prefix and a scope: `feat(core)`, `feat(progress)`, `feat(design)`, `refactor(app)`, `test(progress)`, `docs`. End every commit message with:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
- **Commands:**
  - Engine tests: `cd BJSCore && swift test`. BJSCore has 249 tests today, and they must stay green.
  - App tests: always redirect `xcodebuild` to a log file and grep it afterwards. Piping it straight into `grep | head` can hang.

    ```bash
    xcodegen generate
    xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:BJSTests/<SuiteName> > "$TMPDIR/bjs-test.log" 2>&1; grep -E "✔|✘|error:|\*\* TEST" "$TMPDIR/bjs-test.log" | tail -40
    ```

  - Full app run: the same command without `-only-testing`. The app has 201 unit tests and 4 UI tests today, with no compiler warnings. Check with `grep -c "warning:" "$TMPDIR/bjs-test.log"`, and compare against a baseline run if the count isn't 0.
  - The SE simulator is `name=iPhone SE (3rd generation),OS=18.3.1`. `OS=18.3` doesn't resolve on this Mac.

## File map

**BJSCore**
- Create: `BJSCore/Sources/BJSCore/Progress/ProgressRange.swift`
- Create: `BJSCore/Sources/BJSCore/Progress/HeatMap.swift` (`HeatBin` and `HeatMapLayout`)
- Create: `BJSCore/Sources/BJSCore/Explain/WhyContextRebuild.swift`
- Tests:
  - `BJSCore/Tests/BJSCoreTests/ProgressTests/ProgressRangeTests.swift`
  - `BJSCore/Tests/BJSCoreTests/ProgressTests/HeatMapTests.swift`
  - `BJSCore/Tests/BJSCoreTests/ExplainTests/WhyContextRebuildTests.swift`

**App**
- Create: `BJS/Shared/TrainingText.swift`
- Move: `BJS/Features/Strategy/WhySheet.swift` → `BJS/Shared/WhySheet.swift`
- Modify:
  - `BJS/Features/Strategy/StrategyText.swift` and `BJS/Features/Counting/CountingText.swift`, plus their call sites (the moved helpers);
  - `BJS/Features/Hub/HubViewModel.swift` (use `ProgressRange`).
- Persistence:
  - Create: `BJS/Persistence/SessionDetail.swift` (`HistoryEntry` and `SessionDetail`)
  - Modify: `BJS/Persistence/SessionStore.swift` and `BJS/Persistence/RecordMappers.swift`
- Design:
  - Create: `BJS/Design/Components/HeatMapGrid.swift`
  - Modify: `BJS/Design/Catalogue/FeltCatalogue.swift`
- `Features/Progress` (all new):
  - `BJS/Features/Progress/ProgressText.swift`
  - `ProgressViewModel.swift`
  - `SessionDetailViewModel.swift`
  - `ProgressTabView.swift`
  - `SessionDetailView.swift`
- App shell:
  - Create: `BJS/App/ProgressFixture.swift`
  - Modify: `BJS/App/RootTabView.swift`, `BJS/App/BJSApp.swift` and `BJS/App/LaunchConfiguration.swift`. `LaunchConfiguration` lives in the file that defines `struct LaunchConfiguration`; find it with `grep -rln "struct LaunchConfiguration" BJS/App`.

**App tests**
- Create:
  - `BJSTests/Features/ProgressTextTests.swift`
  - `BJSTests/Features/ProgressViewModelTests.swift`
  - `BJSTests/Features/SessionDetailViewModelTests.swift`
  - `BJSTests/Features/ProgressFixtureTests.swift`
  - `BJSTests/Design/ProgressComponentTests.swift`
  - `BJSUITests/ProgressUITests.swift`
- Modify:
  - `BJSTests/Persistence/SessionStoreTests.swift`
  - `BJSTests/Features/HubViewModelTests.swift`
  - `BJSTests/Features/StrategyTextTests.swift`, `BJSTests/Features/CountingTextTests.swift` (renamed references)
  - `BJSTests/AppShellTests.swift`

---

### Task 1: `ProgressRange`, adopted by the hub

**Files:**
- Create: `BJSCore/Sources/BJSCore/Progress/ProgressRange.swift`
- Test: `BJSCore/Tests/BJSCoreTests/ProgressTests/ProgressRangeTests.swift`
- Modify: `BJS/Features/Hub/HubViewModel.swift`, `BJSTests/Features/HubViewModelTests.swift`

**Interfaces:**
- Produces: `public enum ProgressRange: String, CaseIterable, Sendable { case week, month, allTime }` with `public var days: Int?` and `public func since(now: Date, calendar: Calendar) -> Date?`.

- [ ] **Step 1: Write the failing test**

```swift
// BJSCore/Tests/BJSCoreTests/ProgressTests/ProgressRangeTests.swift
import Foundation
import Testing
@testable import BJSCore

struct ProgressRangeTests {

    var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    func day(_ n: Double, hour: Double = 0) -> Date { Date(timeIntervalSince1970: n * 86_400 + hour * 3_600) }

    @Test("An N-day window is today plus the previous N − 1 calendar days")
    func calendarDays() {
        #expect(ProgressRange.week.since(now: day(100, hour: 23.9), calendar: utc) == day(94))
        #expect(ProgressRange.week.since(now: day(100, hour: 0.01), calendar: utc) == day(94))
        #expect(ProgressRange.month.since(now: day(100, hour: 12), calendar: utc) == day(71))
    }

    @Test("All time has no start")
    func allTime() {
        #expect(ProgressRange.allTime.since(now: day(100), calendar: utc) == nil)
        #expect(ProgressRange.allTime.days == nil)
        #expect(ProgressRange.week.days == 7)
        #expect(ProgressRange.month.days == 30)
    }

    @Test("Ranges are listed short to long")
    func order() {
        #expect(ProgressRange.allCases == [.week, .month, .allTime])
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd BJSCore && swift test --filter ProgressRangeTests`
Expected: FAIL, `cannot find 'ProgressRange' in scope`.

- [ ] **Step 3: Implement**

```swift
// BJSCore/Sources/BJSCore/Progress/ProgressRange.swift
import Foundation

/// The Progress tab's time window (Step 6 spec §1). An N-day window is today plus the previous
/// N − 1 calendar days, so a per-day trend chart shows exactly N days.
public enum ProgressRange: String, CaseIterable, Sendable {
    case week
    case month
    case allTime

    /// Calendar days covered; nil for all time.
    public var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .allTime: return nil
        }
    }

    /// The start of the window, or nil for all time.
    public func since(now: Date, calendar: Calendar) -> Date? {
        guard let days else { return nil }
        return calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: now))
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd BJSCore && swift test --filter ProgressRangeTests`
Expected: PASS (3 tests). Then run `swift test` and expect all tests to pass (252).

- [ ] **Step 5: Hub adopts the range (failing test first)**

In `BJSTests/Features/HubViewModelTests.swift`, add:

```swift
    @Test("The 30-day window is today plus the previous 29 calendar days")
    func windowIsCalendarDays() {
        let model = HubViewModel()
        model.update(sessions: [session(.strategy, daysAgo: 29, decisions: 10, correct: 10),
                                session(.strategy, daysAgo: 30, decisions: 10, correct: 0)],
                     decisions: [], now: now, calendar: utc)
        #expect(model.strategyAccuracy == "100%")
    }
```

`now` in this suite is midnight of day 100 UTC. Today the rolling `now − 30 days` window includes the session 30 days ago, so this test fails with `"50%"`. Run:

`xcodegen generate` then the app test command with `-only-testing:BJSTests/HubViewModelTests`. Expected: FAIL on `windowIsCalendarDays`.

- [ ] **Step 6: Change the hub**

In `BJS/Features/Hub/HubViewModel.swift`:
- delete `static let accuracyWindowDays = 30`;
- replace
  `let since = calendar.date(byAdding: .day, value: -Self.accuracyWindowDays, to: now)`
  with
  `let since = ProgressRange.month.since(now: now, calendar: calendar)`.

Run `grep -rn accuracyWindowDays BJS BJSTests` and expect no matches.

- [ ] **Step 7: Run the hub tests**

Same command. Expected: every `HubViewModelTests` test passes.

- [ ] **Step 8: Commit**

```bash
git add BJSCore/Sources/BJSCore/Progress/ProgressRange.swift BJSCore/Tests/BJSCoreTests/ProgressTests/ProgressRangeTests.swift BJS/Features/Hub/HubViewModel.swift BJSTests/Features/HubViewModelTests.swift
git commit -m "feat(core): ProgressRange calendar-day windows, adopted by the hub

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: `HeatBin` and `HeatMapLayout`

**Files:**
- Create: `BJSCore/Sources/BJSCore/Progress/HeatMap.swift`
- Test: `BJSCore/Tests/BJSCoreTests/ProgressTests/HeatMapTests.swift`

**Interfaces:**
- Consumes: `HeatCell` and `ProgressStats.heatMap(_:)` (existing, `ProgressStats.swift`); `TrainingCell`; `HandType`.
- Produces:
  - `public enum HeatBin: Int, CaseIterable, Sendable { case insufficient, none, low, medium, high, severe }` with `public init(_ cell: HeatCell?)`;
  - `public enum HeatMapLayout` with `public static let upcards: [Int]` (2...11) and `public static func rows(for type: HandType, cells: [TrainingCell: HeatCell]) -> [Int]`.

- [ ] **Step 1: Write the failing test**

```swift
// BJSCore/Tests/BJSCoreTests/ProgressTests/HeatMapTests.swift
import Testing
@testable import BJSCore

struct HeatMapTests {

    func heat(_ errors: Int, of attempts: Int) -> HeatCell {
        ProgressStats.heatMap((0..<attempts).map { i in
            DecisionSample(date: .distantPast, cell: TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10),
                           isCorrect: i >= errors, responseMs: nil)
        }).values.first!
    }

    @Test("Fewer than 3 samples, or no cell, is insufficient")
    func insufficient() {
        #expect(HeatBin(nil) == .insufficient)
        #expect(HeatBin(heat(0, of: 2)) == .insufficient)
        #expect(HeatBin(heat(2, of: 2)) == .insufficient)
    }

    @Test("Bins follow the spec's edges; an edge rate belongs to the lower bin")
    func edges() {
        #expect(HeatBin(heat(0, of: 5)) == .none)
        #expect(HeatBin(heat(1, of: 20)) == .low)       // 5%
        #expect(HeatBin(heat(3, of: 20)) == .low)       // 15%, edge
        #expect(HeatBin(heat(4, of: 20)) == .medium)    // 20%
        #expect(HeatBin(heat(3, of: 10)) == .medium)    // 30%, edge
        #expect(HeatBin(heat(7, of: 20)) == .high)      // 35%
        #expect(HeatBin(heat(1, of: 4)) == .medium)      // 25%
        #expect(HeatBin(heat(5, of: 10)) == .high)      // 50%, edge
        #expect(HeatBin(heat(11, of: 20)) == .severe)   // 55%
        #expect(HeatBin(heat(3, of: 3)) == .severe)
    }

    @Test("Standard rows: hard 5–20, soft 13–20, pairs 2–A")
    func standardRows() {
        #expect(HeatMapLayout.rows(for: .hard, cells: [:]) == Array(5...20))
        #expect(HeatMapLayout.rows(for: .soft, cells: [:]) == Array(13...20))
        #expect(HeatMapLayout.rows(for: .pair, cells: [:]) == Array(2...11))
        #expect(HeatMapLayout.upcards == Array(2...11))
    }

    @Test("Hard 4 and soft 12 rows appear only when they have a decision")
    func rareRows() {
        let one = HeatCell(attempts: 1, errors: 0, errorRate: nil)
        let cells: [TrainingCell: HeatCell] = [
            TrainingCell(handType: .hard, playerValue: 4, dealerUpcard: 5): one,
            TrainingCell(handType: .soft, playerValue: 12, dealerUpcard: 11): one,
        ]
        #expect(HeatMapLayout.rows(for: .hard, cells: cells) == [4] + Array(5...20))
        #expect(HeatMapLayout.rows(for: .soft, cells: cells) == [12] + Array(13...20))
        #expect(HeatMapLayout.rows(for: .pair, cells: cells) == Array(2...11))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd BJSCore && swift test --filter HeatMapTests`
Expected: FAIL, `cannot find 'HeatBin' in scope`.

- [ ] **Step 3: Implement**

```swift
// BJSCore/Sources/BJSCore/Progress/HeatMap.swift

/// Error-rate bands for the Progress heat map (Step 6 spec §2). A rate exactly on an edge
/// belongs to the lower bin.
public enum HeatBin: Int, CaseIterable, Sendable {
    /// Fewer than `ProgressStats.heatMapMinimumSamples` decisions.
    case insufficient
    /// 0% errors.
    case none
    /// Above 0% up to 15%.
    case low
    /// Above 15% up to 30%.
    case medium
    /// Above 30% up to 50%.
    case high
    /// Above 50%.
    case severe

    public init(_ cell: HeatCell?) {
        guard let rate = cell?.errorRate else {
            self = .insufficient
            return
        }
        switch rate {
        case ...0: self = .none
        case ...0.15: self = .low
        case ...0.30: self = .medium
        case ...0.50: self = .high
        default: self = .severe
        }
    }
}

/// Which rows each heat-map grid shows (Step 6 spec §1).
public enum HeatMapLayout {

    /// Dealer upcards 2...11 (11 = ace), in column order.
    public static let upcards = Array(2...11)

    /// Player values in row order. Hard 4 (2,2) and soft 12 (A,A) are graded only once split
    /// isn't legal, so their rows appear only when `cells` holds at least one decision in them.
    public static func rows(for type: HandType, cells: [TrainingCell: HeatCell]) -> [Int] {
        switch type {
        case .hard: return (has(.hard, 4, in: cells) ? [4] : []) + Array(5...20)
        case .soft: return (has(.soft, 12, in: cells) ? [12] : []) + Array(13...20)
        case .pair: return Array(2...11)
        }
    }

    private static func has(_ type: HandType, _ value: Int, in cells: [TrainingCell: HeatCell]) -> Bool {
        cells.keys.contains { $0.handType == type && $0.playerValue == value }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd BJSCore && swift test --filter HeatMapTests`, then `swift test`.
Expected: PASS; all tests green (256).

- [ ] **Step 5: Commit**

```bash
git add BJSCore/Sources/BJSCore/Progress/HeatMap.swift BJSCore/Tests/BJSCoreTests/ProgressTests/HeatMapTests.swift
git commit -m "feat(core): heat-map bins and row layout

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Rebuild `WhyContext` from a saved decision

**Files:**
- Create: `BJSCore/Sources/BJSCore/Explain/WhyContextRebuild.swift`
- Test: `BJSCore/Tests/BJSCoreTests/ExplainTests/WhyContextRebuildTests.swift`

**Interfaces:**
- Consumes:
  - the existing `WhyContext` memberwise init and `WhyContext(spot:userAction:table:rules:id:)` (`WhyExplanation.swift`);
  - `StrategyTable.preferences(for:dealerUpcard:legal:)` and `compositionNoteApplies(to:dealerUpcard:)`;
  - `SurrenderContext(rules:)`.
- Produces: `public init(cell: TrainingCell, userAction: Action?, correctAction: Action, rules: BlackjackRules, table: StrategyTable, id: UUID = UUID())` on `WhyContext`, plus `static func representativeHand(for: TrainingCell) -> BlackjackHand` (internal).

**Background (spec §4):**
- Legal actions aren't saved. Inference: if the chart's first preference for the cell differs from the saved correct action, that preference was illegal.
- A composition-note cell is hard 14 vs a ten, under rules whose table has `hard14VsTenSurrenders`. There, the saved data can't tell a first-decision two-card hand from any other hard 14, so the rebuild assumes the two-card hand: `compositionNote = true`, `preferredIllegal = nil`.
- Ranks are canonical: ten-valued cards rebuild as `.ten`, so a pair of kings rebuilds as a pair of 10s, and a king upcard as a 10.

- [ ] **Step 1: Write the failing tests**

```swift
// BJSCore/Tests/BJSCoreTests/ExplainTests/WhyContextRebuildTests.swift
import Foundation
import Testing
@testable import BJSCore

struct WhyContextRebuildTests {

    static let ruleSets: [BlackjackRules] = {
        func rules(_ decks: BlackjackRules.DeckCount, _ soft17: BlackjackRules.DealerSoft17,
                   _ surrender: BlackjackRules.SurrenderRule, das: Bool = true,
                   double: BlackjackRules.DoubleRestriction = .anyTwo) -> BlackjackRules {
            var r = BlackjackRules()
            r.deckCount = decks
            r.dealerSoft17 = soft17
            r.surrenderRule = surrender
            r.doubleAfterSplit = das
            r.doubleRestriction = double
            return r
        }
        return RulePreset.allCases.map(\.rules) + [
            rules(.one, .stands, .early),
            rules(.two, .hits, .early),
            rules(.six, .stands, .early),
            rules(.one, .hits, .late, das: false, double: .tenToEleven),
            rules(.eight, .hits, .none, das: false, double: .nineToEleven),
        ]
    }()

    static let ranks: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .ace]

    func isNoteCell(_ cell: TrainingCell, _ table: StrategyTable) -> Bool {
        table.hard14VsTenSurrenders != nil && cell.handType == .hard && cell.playerValue == 14
            && cell.dealerUpcard == 10
    }

    @Test("Rebuilding from the saved cell matches the live context", arguments: ruleSets)
    func matchesLiveContext(rules: BlackjackRules) {
        let table = StrategyEngine().strategy(for: rules)
        var rng = SeededRandomNumberGenerator(seed: 6)
        var compared = 0
        for _ in 0..<5_000 {
            let count = [2, 2, 2, 3, 4].randomElement(using: &rng)!
            let hand = BlackjackHand(cards: (0..<count).map {
                Card(rank: Self.ranks.randomElement(using: &rng)!, suit: Suit.allCases[$0 % 4])
            })
            guard hand.total < 21 else { continue }
            let upcard = Self.ranks.randomElement(using: &rng)!
            var legal: Set<Action> = [.hit, .stand]
            if count == 2 && Bool.random(using: &rng) { legal.insert(.double) }
            if hand.isPair && Bool.random(using: &rng) { legal.insert(.split) }
            if count == 2 && rules.surrenderRule != .none && Bool.random(using: &rng) { legal.insert(.surrender) }
            let spot = DecisionSpot(hand: hand, dealerUpcard: upcard, legalActions: legal)
            let cell = TrainingCell(spot: spot)
            guard !isNoteCell(cell, table) else { continue }

            let id = UUID()
            let live = WhyContext(spot: spot, userAction: .hit, table: table, rules: rules, id: id)
            let rebuilt = WhyContext(cell: cell, userAction: .hit, correctAction: live.correctAction,
                                     rules: rules, table: table, id: id)
            #expect(rebuilt == live, "\(hand.cards.map(\.rank)) vs \(upcard), legal \(legal)")
            compared += 1
        }
        #expect(compared > 1_000)
    }

    @Test("Composition-note cells assume the first-decision two-card hand")
    func compositionNoteCell() throws {
        var rules = BlackjackRules()
        rules.deckCount = .one
        rules.surrenderRule = .early
        let table = StrategyEngine().strategy(for: rules)
        try #require(table.hard14VsTenSurrenders != nil)
        let cell = TrainingCell(handType: .hard, playerValue: 14, dealerUpcard: 10)

        // Two-card compositions, surrender legal: the rebuild matches the live context exactly.
        for ranks in [[Rank.ten, .four], [.eight, .six], [.nine, .five]] {
            let spot = DecisionSpot(hand: BlackjackHand(cards: ranks.map { Card(rank: $0, suit: .spades) }),
                                    dealerUpcard: .ten, legalActions: [.hit, .stand, .double, .surrender])
            let id = UUID()
            let live = WhyContext(spot: spot, userAction: .stand, table: table, rules: rules, id: id)
            let rebuilt = WhyContext(cell: cell, userAction: .stand, correctAction: live.correctAction,
                                     rules: rules, table: table, id: id)
            #expect(rebuilt == live, "\(ranks)")
        }

        // Whatever was saved, a note cell carries the note and no illegal lead.
        for correct in [Action.hit, .surrender] {
            let rebuilt = WhyContext(cell: cell, userAction: .stand, correctAction: correct, rules: rules, table: table)
            #expect(rebuilt.compositionNote)
            #expect(rebuilt.preferredIllegal == nil)
        }
    }

    @Test("Ten-valued ranks rebuild as ten, ace upcard as ace, timeout as nil")
    func canonicalRanks() {
        let rules = BlackjackRules()
        let table = StrategyEngine().strategy(for: rules)
        let pair = WhyContext(cell: TrainingCell(handType: .pair, playerValue: 10, dealerUpcard: 11),
                              userAction: nil, correctAction: .stand, rules: rules, table: table)
        #expect(pair.pairRank == .ten)
        #expect(pair.handTotal == 20)
        #expect(pair.dealerUpCard == .ace)
        #expect(pair.userAction == nil)

        let aces = WhyContext(cell: TrainingCell(handType: .pair, playerValue: 11, dealerUpcard: 6),
                              userAction: .hit, correctAction: .split, rules: rules, table: table)
        #expect(aces.pairRank == .ace)
        #expect(aces.handTotal == 12)
    }

    @Test("A three-card soft 18 vs 6 saved as stand rebuilds with double as the illegal lead")
    func illegalDouble() {
        let rules = BlackjackRules()
        let table = StrategyEngine().strategy(for: rules)
        let c = WhyContext(cell: TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 6),
                           userAction: .hit, correctAction: .stand, rules: rules, table: table)
        #expect(c.preferredIllegal == .double)
        #expect(WhyExplanation.explain(c).hasPrefix("Doubling would be best"))
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd BJSCore && swift test --filter WhyContextRebuildTests`
Expected: FAIL, `extra argument 'cell' in call` (or `no exact matches`).

- [ ] **Step 3: Implement**

```swift
// BJSCore/Sources/BJSCore/Explain/WhyContextRebuild.swift
import Foundation

extension WhyContext {
    /// Rebuilds the context from a saved decision, for WHY from history (Step 6 spec §4).
    ///
    /// Legal actions aren't saved, so they're inferred: grading picks the first legal preference,
    /// so the chart's first preference for the cell was illegal exactly when it differs from the
    /// saved `correctAction`. One case can't be told apart: in an early-surrender
    /// composition-note cell (hard 14 vs a ten), a first-decision two-card hand and any other
    /// hard 14 save identical records. There the rebuild assumes the two-card hand
    /// (`compositionNote` true, no illegal lead). Ten-valued ranks rebuild as `.ten`.
    public init(cell: TrainingCell, userAction: Action?, correctAction: Action, rules: BlackjackRules,
                table: StrategyTable, id: UUID = UUID()) {
        let hand = Self.representativeHand(for: cell)
        let upcard = Self.rank(cell.dealerUpcard)
        // Split only for pair cells, so a hard 4 (2,2), hard 20 (10,10) or soft 12 (A,A) reads its
        // hard or soft row, as grading did once split wasn't legal.
        var legal: Set<Action> = [.hit, .stand, .double, .surrender]
        if cell.handType == .pair { legal.insert(.split) }
        let noteCell = table.compositionNoteApplies(to: hand, dealerUpcard: upcard)
        let first = table.preferences(for: hand, dealerUpcard: upcard, legal: legal).first
        let illegal = noteCell ? nil : first.flatMap { $0 == correctAction ? nil : $0 }
        self.init(id: id, handTotal: hand.total, handType: cell.handType,
                  pairRank: cell.handType == .pair ? hand.cards[0].rank : nil,
                  dealerUpCard: upcard, userAction: userAction, correctAction: correctAction,
                  rules: rules, preferredIllegal: illegal, surrenderContext: SurrenderContext(rules: rules),
                  compositionNote: noteCell)
    }

    /// A two-card hand in the cell's row: pairs as two of the rank, soft totals as A + x
    /// (A,A for soft 12), hard totals as 2 + x up to 11 and 10 + x from 12.
    static func representativeHand(for cell: TrainingCell) -> BlackjackHand {
        let v = cell.playerValue
        let ranks: [Rank]
        switch cell.handType {
        case .pair: ranks = [rank(v), rank(v)]
        case .soft: ranks = [.ace, v == 12 ? .ace : rank(v - 11)]
        case .hard: ranks = v <= 11 ? [.two, rank(v - 2)] : [.ten, rank(v - 10)]
        }
        return BlackjackHand(cards: ranks.enumerated().map { Card(rank: $1, suit: Suit.allCases[$0 % 4]) })
    }

    /// 2...10 by value; 11 is the ace.
    private static func rank(_ value: Int) -> Rank {
        value == 11 ? .ace : Rank(rawValue: value)!
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd BJSCore && swift test --filter WhyContextRebuildTests`
Expected: PASS.

If `matchesLiveContext` reports a mismatch outside note cells:
- fix the rebuild if the saved data (cell, correct action, rules) can distinguish the case;
- if it can't, add the case to spec §4 as a documented limitation, exclude it in the test with a comment naming it, and note it for the Task 10 handoff.

Don't loosen the equality check.

- [ ] **Step 5: Run the whole engine suite**

Run: `cd BJSCore && swift test`
Expected: all green (the previous count plus the new tests).

- [ ] **Step 6: Commit**

```bash
git add BJSCore/Sources/BJSCore/Explain/WhyContextRebuild.swift BJSCore/Tests/BJSCoreTests/ExplainTests/WhyContextRebuildTests.swift
git commit -m "feat(core): rebuild WhyContext from a saved decision

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Move the shared text helpers and `WhySheet` to `Shared/`

**Files:**
- Create: `BJS/Shared/TrainingText.swift`
- Move: `BJS/Features/Strategy/WhySheet.swift` → `BJS/Shared/WhySheet.swift` (`git mv`)
- Modify:
  - `BJS/Features/Strategy/StrategyText.swift` and `BJS/Features/Counting/CountingText.swift` (remove the moved members);
  - every call site under `BJS/` and `BJSTests/`.

**Interfaces:**
- Produces `enum TrainingText` with these members, bodies moved verbatim:
  - `static let minus: String`
  - `static func actionName(_: Action) -> String`
  - `static func upcardName(_: Rank) -> String`
  - `static func handLabel(_: WhyContext) -> String`
  - `static func signed(_: Int) -> String`
  - `static func signed(_: Double) -> String`
  - `static func meanError(_: Double?) -> String`
  - `static func conventionRule(_: TrueCountConvention) -> String`
- `WhySheet(context:)` is unchanged (same identifiers: `strategy.why`, `strategy.close`).

This is a pure refactor: the existing tests are the safety net, and no behaviour changes.

- [ ] **Step 1: Create `TrainingText`**

```swift
// BJS/Shared/TrainingText.swift
import BJSCore

/// Display strings shared by the training features and Progress (Step 6 spec §5), so no feature
/// folder imports another's text.
enum TrainingText {
    static let minus = "\u{2212}"

    static func actionName(_ action: Action) -> String {
        switch action {
        case .hit: return "Hit"
        case .stand: return "Stand"
        case .double: return "Double"
        case .split: return "Split"
        case .surrender: return "Surrender"
        }
    }

    static func upcardName(_ rank: Rank) -> String {
        rank == .ace ? "A" : "\(rank.blackjackValue)"
    }

    /// "Hard 16 vs 10", "Soft 18 vs A", "Pair of 8s vs 6", "Pair of Aces vs 2".
    static func handLabel(_ c: WhyContext) -> String {
        let up = upcardName(c.dealerUpCard)
        switch c.handType {
        case .hard: return "Hard \(c.handTotal) vs \(up)"
        case .soft: return "Soft \(c.handTotal) vs \(up)"
        case .pair:
            let rank = c.pairRank ?? .two
            let name = rank == .ace ? "Aces" : "\(rank.blackjackValue)s"
            return "Pair of \(name) vs \(up)"
        }
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

    static func meanError(_ value: Double?) -> String {
        value.map { String(format: "%.1f", $0) } ?? PercentText.noData
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
}
```

Before deleting the originals, diff the bodies above against `StrategyText.swift` and `CountingText.swift` to confirm they're identical. If any differs, the original wins: copy it here.

- [ ] **Step 2: Remove the originals and repoint the call sites**

- Delete from `StrategyText`: `actionName`, `upcardName` and `handLabel`.
- Delete from `CountingText`: `minus`, both `signed` overloads, `meanError` and `conventionRule`.
- Then rewrite the qualified call sites:

```bash
grep -rl -E "StrategyText\.(actionName|upcardName|handLabel)|CountingText\.(signed|minus|meanError|conventionRule)" BJS BJSTests \
  | xargs sed -i '' -E 's/StrategyText\.(actionName|upcardName|handLabel)/TrainingText.\1/g; s/CountingText\.(signed|minus|meanError|conventionRule)/TrainingText.\1/g'
git mv BJS/Features/Strategy/WhySheet.swift BJS/Shared/WhySheet.swift
xcodegen generate
```

Unqualified uses inside `StrategyText` (e.g. `actionName(` in `feedback`) and inside `CountingText` (`signed(`, `minus`) won't compile now. Build, and prefix each one the compiler flags with `TrainingText.`:

```bash
xcodebuild build -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' > "$TMPDIR/bjs-build.log" 2>&1; grep -E "error:" "$TMPDIR/bjs-build.log" | sort -u | head -40
```

Repeat until there are no errors.

- [ ] **Step 3: Verify nothing is left behind**

Run:

```bash
grep -rn -E "StrategyText\.(actionName|upcardName|handLabel)|CountingText\.(signed|minus|meanError|conventionRule)" BJS BJSTests
grep -rn -E "func (actionName|upcardName|handLabel|signed|meanError|conventionRule)|let minus" BJS/Features
```

Expected: no output from either.

- [ ] **Step 4: Run the full app suite**

Run the full app test command (no `-only-testing`).
Expected: 201 unit + 4 UI tests pass, with 0 warnings.

- [ ] **Step 5: Commit**

```bash
git add -A BJS BJSTests
git commit -m "refactor(app): move WhySheet and shared text helpers to Shared

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: `SessionStore`: ranged fetches, history entries, session detail

**Files:**
- Create: `BJS/Persistence/SessionDetail.swift`
- Modify: `BJS/Persistence/SessionStore.swift`, `BJS/Persistence/RecordMappers.swift`
- Test: `BJSTests/Persistence/SessionStoreTests.swift`

**Interfaces:**
- Consumes: `Session`, `DecisionRecord` and `CountCheckRecord` (SchemaV1); `RecordedChoice`; `SessionSample`; `CountSample`.
- Produces:
  - `struct HistoryEntry: Equatable, Identifiable { let sample: SessionSample; let mode: String?; var id: UUID }`;
  - `struct SessionDetail: Equatable`, with nested `Decision` and `Check`; fields below;
  - `SessionStore.sessionSamples(forStats: Bool = true, since: Date? = nil) throws -> [SessionSample]` (oldest first, as today);
  - `SessionStore.decisionSamples(modules: Set<TrainingModule>? = nil, forStats: Bool = true, since: Date? = nil) throws -> [DecisionSample]`;
  - `SessionStore.historyEntries() throws -> [HistoryEntry]` (newest first, Learn included);
  - `SessionStore.sessionDetail(id: UUID) throws -> SessionDetail?`.

- [ ] **Step 1: Write the failing tests**

Append inside `struct SessionStoreTests`:

```swift
    @Test("History lists every session newest first, Learn included, with its mode")
    func historyEntries() throws {
        var learn = draft(start: 300)
        learn.mode = "learn"
        try store.save(draft(start: 100))
        try store.save(learn)
        try store.save(draft(.countingRC, start: 200))
        let entries = try store.historyEntries()
        #expect(entries.map(\.sample.startedAt) == [t(300), t(200), t(100)])
        #expect(entries.map(\.mode) == ["learn", "test", "test"])
        #expect(entries.map(\.sample.module) == [.strategy, .countingRC, .strategy])
    }

    @Test("since filters sessions and decisions by date")
    func sinceFilter() throws {
        try store.save(draft(start: 100, decisions: [decision(true, at: 101)]))
        try store.save(draft(start: 500, decisions: [decision(false, at: 501)]))
        #expect(try store.sessionSamples(since: t(400)).map(\.startedAt) == [t(500)])
        #expect(try store.decisionSamples(since: t(400)).map(\.isCorrect) == [false])
        #expect(try store.sessionSamples().count == 2)
        #expect(try store.decisionSamples().count == 2)
    }

    @Test("sessionDetail returns one session's records in order")
    func sessionDetail() throws {
        let d = draft(start: 100,
                      decisions: [decision(true, at: 101, ms: 900), decision(false, at: 102)],
                      checks: [CountCheckDraft(kind: .trueCount, expected: 2.8, answered: 3, isCorrect: true,
                                               responseMs: 400, cardsSeen: 104, checkedAt: t(103))])
        try store.save(d)
        try store.save(draft(start: 200, decisions: [decision(true, at: 201)]))

        let detail = try #require(try store.sessionDetail(id: d.id))
        #expect(detail.sample.id == d.id)
        #expect(detail.mode == "test")
        #expect(detail.rules == RulePreset.downtownVegas.rules)
        #expect(detail.bestStreak == 1)
        #expect(detail.decisions.map(\.isCorrect) == [true, false])
        #expect(detail.decisions[0].responseMs == 900)
        #expect(detail.decisions[1].chosen == .action(.stand))
        #expect(detail.decisions[1].correctAction == .hit)
        #expect(detail.decisions[1].cell == TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10))
        #expect(detail.checks.map(\.cardsSeen) == [104])
        #expect(detail.checks[0].sample.expected == 2.8)
        #expect(detail.checks[0].sample.kind == .trueCount)
    }

    @Test("sessionDetail is nil for an unknown id")
    func sessionDetailMissing() throws {
        try store.save(draft())
        #expect(try store.sessionDetail(id: UUID()) == nil)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodegen generate`, then the app test command with `-only-testing:BJSTests/SessionStoreTests`.
Expected: build FAIL, `value of type 'SessionStore' has no member 'historyEntries'`.

- [ ] **Step 3: Add the value types**

```swift
// BJS/Persistence/SessionDetail.swift
import Foundation
import BJSCore

/// A history row's data: the session's cached summary plus its mode (Step 6 spec §5).
struct HistoryEntry: Equatable, Identifiable {
    let sample: SessionSample
    let mode: String?
    var id: UUID { sample.id }
}

/// One saved session with its records, for the read-only session detail (Step 6 spec §3, §5).
struct SessionDetail: Equatable {
    struct Decision: Equatable {
        let cell: TrainingCell
        let chosen: RecordedChoice
        let correctAction: Action
        let isCorrect: Bool
        let responseMs: Int?
    }

    struct Check: Equatable {
        let sample: CountSample
        let cardsSeen: Int
    }

    let sample: SessionSample
    let mode: String?
    let rules: BlackjackRules
    let bestStreak: Int
    let meanResponseMs: Double?
    /// In the order they happened.
    let decisions: [Decision]
    /// In the order they happened.
    let checks: [Check]
}
```

In `BJS/Persistence/RecordMappers.swift`, add inside `extension SchemaV1.DecisionRecord`:

```swift
    /// nil when `handType`, `chosenAction` or `correctAction` is not a known raw value.
    var detail: SessionDetail.Decision? {
        guard let type = HandType(rawValue: handType),
              let chosen = RecordedChoice(rawValue: chosenAction),
              let correct = Action(rawValue: correctAction) else { return nil }
        return SessionDetail.Decision(cell: TrainingCell(handType: type, playerValue: playerValue,
                                                         dealerUpcard: dealerUpcard),
                                      chosen: chosen, correctAction: correct, isCorrect: isCorrect,
                                      responseMs: responseMs)
    }
```

- [ ] **Step 4: Probe `#Predicate`, then implement the store methods**

In `SessionStore`, replace `sessionSamples(forStats:)` and `decisionSamples(modules:forStats:)` with the versions below, and add the two new methods and the descriptor helpers:

```swift
    /// All sessions since `since` (all when nil), oldest first. `forStats` drops sessions in
    /// `statsExcludedModes`.
    func sessionSamples(forStats: Bool = true, since: Date? = nil) throws -> [SessionSample] {
        let sessions = try context.fetch(Self.sessions(since: since))
            .filter { !forStats || Self.countsForStats($0) }
            .sorted { $0.startedAt < $1.startedAt }
        return mapLogging(sessions, kind: "session") { $0.sample }
    }

    /// Decisions since `since` (all when nil) from sessions in `modules` (all when nil), chronological.
    func decisionSamples(modules: Set<TrainingModule>? = nil, forStats: Bool = true,
                         since: Date? = nil) throws -> [DecisionSample] {
        let records = try context.fetch(Self.decisions(since: since))
            .filter { Self.matches($0.session, modules) && (!forStats || Self.countsForStats($0.session)) }
            .sorted { ($0.decidedAt, $0.sequence) < ($1.decidedAt, $1.sequence) }
        return mapLogging(records, kind: "decision") { $0.sample }
    }

    /// Every session, newest first, Learn included (Step 6 spec §1: history shows what the user did).
    func historyEntries() throws -> [HistoryEntry] {
        let sessions = try context.fetch(FetchDescriptor<Session>())
            .sorted { $0.startedAt > $1.startedAt }
        return mapLogging(sessions, kind: "session") { session in
            session.sample.map { HistoryEntry(sample: $0, mode: session.mode) }
        }
    }

    /// One session with its records in the order they happened; nil when no session has `id`
    /// or its module is unknown.
    func sessionDetail(id: UUID) throws -> SessionDetail? {
        var descriptor = FetchDescriptor<Session>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let session = try context.fetch(descriptor).first, let sample = session.sample else { return nil }
        let rules: BlackjackRules
        do {
            rules = try JSONDecoder().decode(BlackjackRules.self, from: session.rulesJSON)
        } catch {
            logger.error("Session rules failed to decode; showing defaults: \(error.localizedDescription)")
            rules = BlackjackRules()
        }
        let decisions = mapLogging(session.decisions.sorted { $0.sequence < $1.sequence },
                                   kind: "decision") { $0.detail }
        let checks = mapLogging(session.countChecks.sorted { $0.sequence < $1.sequence },
                                kind: "count check") { record in
            record.sample.map { SessionDetail.Check(sample: $0, cardsSeen: record.cardsSeen) }
        }
        return SessionDetail(sample: sample, mode: session.mode, rules: rules,
                             bestStreak: session.bestStreak, meanResponseMs: session.meanResponseMs,
                             decisions: decisions, checks: checks)
    }

    private static func sessions(since: Date?) -> FetchDescriptor<Session> {
        guard let since else { return FetchDescriptor<Session>() }
        return FetchDescriptor<Session>(predicate: #Predicate { $0.startedAt >= since })
    }

    private static func decisions(since: Date?) -> FetchDescriptor<DecisionRecord> {
        guard let since else { return FetchDescriptor<DecisionRecord>() }
        return FetchDescriptor<DecisionRecord>(predicate: #Predicate { $0.decidedAt >= since })
    }
```

**The probe:** build. `#Predicate` hasn't been used in main-actor app code yet (progress.md, Step 3 note).
- If it compiles and the tests pass, keep it, and record "`#Predicate` works in main-actor code" for the handoff.
- If it doesn't compile, filter in memory instead, and record that:
  - `sessions(since:)` and `decisions(since:)` return the plain descriptor;
  - the callers add `.filter { since == nil || $0.startedAt >= since! }` (sessions) and `.filter { since == nil || $0.decidedAt >= since! }` (decisions) before the existing filters;
  - `sessionDetail` fetches all sessions and uses `.first { $0.id == id }`.

- [ ] **Step 5: Run the tests to verify they pass**

Run the `SessionStoreTests` command again, then `-only-testing:BJSTests/HubViewModelTests`, since the hub calls these methods with their defaults.
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add BJS/Persistence BJSTests/Persistence/SessionStoreTests.swift
git commit -m "feat(progress): ranged session fetches, history entries and session detail

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: `HeatMapGrid` component and catalogue section

**Files:**
- Create: `BJS/Design/Components/HeatMapGrid.swift`
- Modify: `BJS/Design/Catalogue/FeltCatalogue.swift`
- Test: `BJSTests/Design/ProgressComponentTests.swift`

**Interfaces:**
- Consumes: `HeatBin` (Task 2); `FeltColor`, `FeltSpacing` and `feltText`.
- Produces:
  - `struct HeatMapGrid: View`, with:
    - nested `Cell(id: Int, bin: HeatBin, accessibilityLabel: String, accessibilityValue: String, isSelected: Bool)`, where `id` is the upcard 2...11;
    - nested `Row(id: Int, label: String, cells: [Cell])`, where `id` is the player value;
    - nested `Fill(color: Color?, opacity: Double)`;
    - `init(columns: [String], rows: [Row], onSelect: (Int, Int) -> Void)`;
    - `static func fill(for: HeatBin) -> Fill`.
  - `struct HeatMapSwatch: View` (`bin`, `isSelected`).
  - `struct HeatMapLegend: View`, with `static let items: [(bin: HeatBin, label: String)]`.

- [ ] **Step 1: Write the failing test**

```swift
// BJSTests/Design/ProgressComponentTests.swift
import SwiftUI
import Testing
import BJSCore
@testable import BJS

@MainActor
struct ProgressComponentTests {

    @Test("Heat-map fills follow the spec: outline only, then correct, then four incorrect strengths")
    func fills() {
        #expect(HeatMapGrid.fill(for: .insufficient) == HeatMapGrid.Fill(color: nil, opacity: 0))
        #expect(HeatMapGrid.fill(for: .none) == HeatMapGrid.Fill(color: FeltColor.correct, opacity: 0.35))
        #expect(HeatMapGrid.fill(for: .low) == HeatMapGrid.Fill(color: FeltColor.incorrect, opacity: 0.30))
        #expect(HeatMapGrid.fill(for: .medium) == HeatMapGrid.Fill(color: FeltColor.incorrect, opacity: 0.50))
        #expect(HeatMapGrid.fill(for: .high) == HeatMapGrid.Fill(color: FeltColor.incorrect, opacity: 0.75))
        #expect(HeatMapGrid.fill(for: .severe) == HeatMapGrid.Fill(color: FeltColor.incorrect, opacity: 1))
    }

    @Test("No fill uses brass")
    func noBrass() {
        for bin in HeatBin.allCases {
            #expect(HeatMapGrid.fill(for: bin).color != FeltColor.brass)
        }
    }

    @Test("The legend lists every bin in order with the spec's labels")
    func legend() {
        #expect(HeatMapLegend.items.map(\.bin) == HeatBin.allCases)
        #expect(HeatMapLegend.items.map(\.label) == ["Not enough data", "0%", "≤15%", "≤30%", "≤50%", ">50%"])
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodegen generate`, then the app test command with `-only-testing:BJSTests/ProgressComponentTests`.
Expected: build FAIL, `cannot find 'HeatMapGrid' in scope`.

- [ ] **Step 3: Implement the component**

```swift
// BJS/Design/Components/HeatMapGrid.swift
import SwiftUI
import BJSCore

/// The Progress heat map (Step 6 spec §2): player-value rows × dealer-upcard columns, each cell
/// filled by its error-rate bin. Built from existing Felt tokens only.
///
/// Cells are narrower than `FeltTapTarget.minimum`; that's accepted for a dense grid. Tapping is
/// an enhancement (it shows a caption), and VoiceOver reaches every cell as its own element.
struct HeatMapGrid: View {
    struct Cell: Identifiable, Equatable {
        /// The dealer upcard, 2...11 (11 = ace).
        let id: Int
        let bin: HeatBin
        let accessibilityLabel: String
        let accessibilityValue: String
        let isSelected: Bool
    }

    struct Row: Identifiable, Equatable {
        /// The player value.
        let id: Int
        let label: String
        let cells: [Cell]
    }

    struct Fill: Equatable {
        /// nil: no fill, outline only.
        let color: Color?
        let opacity: Double
    }

    static let cellHeight: CGFloat = 28
    static let gap: CGFloat = 2
    static let labelWidth: CGFloat = 36
    static let outlineWidth: CGFloat = 1
    static let selectionWidth: CGFloat = 2

    let columns: [String]
    let rows: [Row]
    let onSelect: (_ row: Int, _ column: Int) -> Void

    static func fill(for bin: HeatBin) -> Fill {
        switch bin {
        case .insufficient: return Fill(color: nil, opacity: 0)
        case .none: return Fill(color: FeltColor.correct, opacity: 0.35)
        case .low: return Fill(color: FeltColor.incorrect, opacity: 0.30)
        case .medium: return Fill(color: FeltColor.incorrect, opacity: 0.50)
        case .high: return Fill(color: FeltColor.incorrect, opacity: 0.75)
        case .severe: return Fill(color: FeltColor.incorrect, opacity: 1)
        }
    }

    var body: some View {
        VStack(spacing: Self.gap) {
            HStack(spacing: Self.gap) {
                Color.clear.frame(width: Self.labelWidth, height: 1)
                ForEach(columns, id: \.self) { column in
                    Text(column)
                        .feltText(.label)
                        .foregroundStyle(FeltColor.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
            ForEach(rows) { row in
                HStack(spacing: Self.gap) {
                    Text(row.label)
                        .feltText(.label)
                        .foregroundStyle(FeltColor.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: Self.labelWidth, alignment: .trailing)
                        .accessibilityHidden(true)
                    ForEach(row.cells) { cell in
                        HeatMapSwatch(bin: cell.bin, isSelected: cell.isSelected)
                            .frame(maxWidth: .infinity)
                            .frame(height: Self.cellHeight)
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(row.id, cell.id) }
                            .accessibilityElement()
                            .accessibilityLabel(cell.accessibilityLabel)
                            .accessibilityValue(cell.accessibilityValue)
                            .accessibilityAddTraits(cell.isSelected ? [.isButton, .isSelected] : .isButton)
                            .accessibilityAction { onSelect(row.id, cell.id) }
                    }
                }
            }
        }
    }
}

/// One heat-map fill, shared by the grid's cells and the legend.
struct HeatMapSwatch: View {
    let bin: HeatBin
    var isSelected = false

    var body: some View {
        let fill = HeatMapGrid.fill(for: bin)
        Rectangle()
            .fill((fill.color ?? .clear).opacity(fill.opacity))
            .overlay {
                if fill.color == nil {
                    Rectangle().strokeBorder(FeltColor.surfaceInset, lineWidth: HeatMapGrid.outlineWidth)
                }
            }
            .overlay {
                if isSelected {
                    Rectangle().strokeBorder(FeltColor.cream, lineWidth: HeatMapGrid.selectionWidth)
                }
            }
    }
}

/// The heat map's key: one swatch per bin.
struct HeatMapLegend: View {
    static let items: [(bin: HeatBin, label: String)] = [
        (.insufficient, "Not enough data"), (.none, "0%"), (.low, "≤15%"),
        (.medium, "≤30%"), (.high, "≤50%"), (.severe, ">50%"),
    ]
    static let swatchSize: CGFloat = 12

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3),
                  alignment: .leading, spacing: FeltSpacing.s) {
            ForEach(Self.items, id: \.bin) { item in
                HStack(spacing: FeltSpacing.xs) {
                    HeatMapSwatch(bin: item.bin)
                        .frame(width: Self.swatchSize, height: Self.swatchSize)
                    Text(item.label)
                        .feltText(.label)
                        .foregroundStyle(FeltColor.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Legend")
    }
}
```

- [ ] **Step 4: Add the catalogue section**

In `FeltCatalogue.swift`, insert after the `section("Edge components") { … }` block:

```swift
                    section("Progress components") {
                        HeatMapGrid(columns: ["2", "3", "4", "5", "6", "7", "8", "9", "10", "A"],
                                    rows: Self.heatDemoRows, onSelect: { _, _ in })
                        HeatMapLegend()
                    }
```

Then add this static property to `FeltCatalogue`:

```swift
    /// Two rows cycling through every bin, with hard 16 vs 10 selected.
    private static let heatDemoRows: [HeatMapGrid.Row] = [16, 17].map { value in
        HeatMapGrid.Row(id: value, label: "\(value)", cells: (2...11).map { up in
            let bin = HeatBin.allCases[(up - 2 + value) % HeatBin.allCases.count]
            return HeatMapGrid.Cell(id: up, bin: bin, accessibilityLabel: "Hard \(value) vs \(up)",
                                    accessibilityValue: "\(bin)", isSelected: value == 16 && up == 10)
        })
    }
```

If `FeltCatalogue.swift` doesn't already `import BJSCore`, add it.

- [ ] **Step 5: Run the tests**

Run `-only-testing:BJSTests/ProgressComponentTests`, then `-only-testing:BJSTests/FeltColorTests`.
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add BJS/Design/Components/HeatMapGrid.swift BJS/Design/Catalogue/FeltCatalogue.swift BJSTests/Design/ProgressComponentTests.swift
git commit -m "feat(design): HeatMapGrid built from existing tokens

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: `ProgressText` and `ProgressViewModel`

**Files:**
- Create: `BJS/Features/Progress/ProgressText.swift`, `BJS/Features/Progress/ProgressViewModel.swift`
- Test: `BJSTests/Features/ProgressTextTests.swift`, `BJSTests/Features/ProgressViewModelTests.swift`

**Interfaces:**
- Consumes:
  - from BJSCore: `ProgressRange` (Task 1), `HeatBin` and `HeatMapLayout` (Task 2), and the existing `ProgressStats`;
  - from the store (Task 5): `HistoryEntry`, `SessionStore.historyEntries()`, and `sessionSamples(since:)` / `decisionSamples(modules:since:)`;
  - `HeatMapGrid.Row` and `HeatMapGrid.Cell` (Task 6); `PercentText`.
- Produces:
  - `enum ProgressText`, with:
    - titles: `rangeTitle(_:)`, `moduleTitle(_:)`, `moduleShortTitle(_:)`, `handTypeTitle(_:)`, `modeTitle(_:module:)`, `sessionTitle(module:mode:)`;
    - grid labels: `upcardLabel(_:)`, `rowLabel(type:value:)`;
    - cell text: `cellName(_:)`, `cellDetail(_:)`, `cellCaption(_:_:)`;
    - dates and chart: `dateTime(_:locale:timeZone:)`, `dayLabel(_:)`, `chartSummary(module:range:points:)`;
    - constants: `noPointsCaption`, `noHeatCaption`, `loadFailed`, `emptyTitle`, `emptyMessage`, `emptyButton`.
  - `@Observable final class ProgressViewModel`, with:
    - nested types: `Chip`, `ChartPoint` and `HistoryRow`;
    - statics: `modules`, `heatModules`, `handTypes`, `columnLabels`, `measure(_:)` and `accuracyText(_:)`;
    - inputs: `range`, `trendModule`, `heatType`, `selectedCell`;
    - outputs: `hasAnySessions`, `loadFailed`, `chips`, `history`, `heat`, `chartPoints`, `chartDomain`, `chartSummary`, `gridRows`, `caption`, `hasHeatData`;
    - methods: `select(row:column:)`, `apply(entries:sessions:decisions:now:calendar:)` and `reload(store:now:calendar:)`.

- [ ] **Step 1: Write the failing `ProgressText` tests**

```swift
// BJSTests/Features/ProgressTextTests.swift
import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct ProgressTextTests {

    @Test("Session titles combine module and mode")
    func sessionTitles() {
        #expect(ProgressText.sessionTitle(module: .strategy, mode: "test") == "Strategy · Test")
        #expect(ProgressText.sessionTitle(module: .strategy, mode: "learn") == "Strategy · Learn")
        #expect(ProgressText.sessionTitle(module: .strategy, mode: "weakSpots") == "Strategy · Weak spots")
        #expect(ProgressText.sessionTitle(module: .countingRC, mode: nil) == "Running count")
        #expect(ProgressText.sessionTitle(module: .countingTC, mode: "exact") == "True count · Exact")
        #expect(ProgressText.sessionTitle(module: .countingTC, mode: "floor") == "True count · Floor")
        #expect(ProgressText.sessionTitle(module: .strategy, mode: "unknown") == "Strategy")
        #expect(ProgressText.sessionTitle(module: .shoe, mode: nil) == "Shoe Sim")
    }

    @Test("Range, module and hand-type titles")
    func titles() {
        #expect(ProgressRange.allCases.map(ProgressText.rangeTitle) == ["7 days", "30 days", "All time"])
        #expect(ProgressViewModel.modules.map(ProgressText.moduleTitle)
                == ["Strategy", "Running count", "True count", "Shoe Sim"])
        #expect(ProgressViewModel.modules.map(ProgressText.moduleShortTitle) == ["Strategy", "Running", "True", "Shoe"])
        #expect(ProgressViewModel.handTypes.map(ProgressText.handTypeTitle) == ["Hard", "Soft", "Pairs"])
    }

    @Test("Grid labels")
    func gridLabels() {
        #expect(ProgressViewModel.columnLabels == ["2", "3", "4", "5", "6", "7", "8", "9", "10", "A"])
        #expect(ProgressText.rowLabel(type: .hard, value: 16) == "16")
        #expect(ProgressText.rowLabel(type: .soft, value: 12) == "12")
        #expect(ProgressText.rowLabel(type: .pair, value: 8) == "8,8")
        #expect(ProgressText.rowLabel(type: .pair, value: 10) == "10,10")
        #expect(ProgressText.rowLabel(type: .pair, value: 11) == "A,A")
    }

    @Test("Cell names match the WHY sheet's hand labels")
    func cellNames() {
        #expect(ProgressText.cellName(TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)) == "Hard 16 vs 10")
        #expect(ProgressText.cellName(TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 11)) == "Soft 18 vs A")
        #expect(ProgressText.cellName(TrainingCell(handType: .pair, playerValue: 8, dealerUpcard: 6)) == "Pair of 8s vs 6")
        #expect(ProgressText.cellName(TrainingCell(handType: .pair, playerValue: 11, dealerUpcard: 2)) == "Pair of Aces vs 2")
    }

    @Test("Cell captions: no decisions, not enough data, and the error count")
    func captions() {
        let cell = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)
        #expect(ProgressText.cellCaption(cell, nil) == "Hard 16 vs 10 · no decisions")
        #expect(ProgressText.cellCaption(cell, HeatCell(attempts: 1, errors: 0, errorRate: nil))
                == "Hard 16 vs 10 · 1 decision, not enough data")
        #expect(ProgressText.cellCaption(cell, HeatCell(attempts: 2, errors: 1, errorRate: nil))
                == "Hard 16 vs 10 · 2 decisions, not enough data")
        #expect(ProgressText.cellCaption(cell, HeatCell(attempts: 7, errors: 3, errorRate: 3.0 / 7))
                == "Hard 16 vs 10 · 3 of 7 wrong (43%)")
        #expect(ProgressText.cellDetail(HeatCell(attempts: 7, errors: 3, errorRate: 3.0 / 7)) == "3 of 7 wrong (43%)")
    }

    @Test("Chart summary for VoiceOver")
    func chartSummary() {
        let points = [ProgressViewModel.ChartPoint(day: .distantPast, accuracy: 0.5),
                      ProgressViewModel.ChartPoint(day: .now, accuracy: 0.84)]
        #expect(ProgressText.chartSummary(module: .strategy, range: .week, points: points)
                == "Strategy accuracy, 7 days: 2 days, latest 84%")
        #expect(ProgressText.chartSummary(module: .countingRC, range: .allTime, points: [points[1]])
                == "Running count accuracy, all time: 1 day, latest 84%")
        #expect(ProgressText.chartSummary(module: .shoe, range: .month, points: [])
                == "Shoe Sim accuracy, 30 days: no sessions")
    }

    @Test("Dates use the abbreviated date and short time")
    func dateTime() {
        let text = ProgressText.dateTime(Date(timeIntervalSince1970: 0), locale: Locale(identifier: "en_US"),
                                         timeZone: TimeZone(identifier: "UTC")!)
        #expect(text.contains("1970"))
        #expect(text.contains("Jan"))
        #expect(text.contains("12:00"))
    }
}
```

- [ ] **Step 2: Write the failing `ProgressViewModel` tests**

```swift
// BJSTests/Features/ProgressViewModelTests.swift
import Foundation
import SwiftData
import Testing
import BJSCore
@testable import BJS

@MainActor
struct ProgressViewModelTests {

    /// Day 100, noon UTC.
    let now = Date(timeIntervalSince1970: 100 * 86_400 + 12 * 3_600)
    var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    func ago(_ days: Int) -> Date { now.addingTimeInterval(Double(-days) * 86_400) }
    func startOfDay(_ daysAgo: Int) -> Date { utc.startOfDay(for: ago(daysAgo)) }

    func session(_ module: TrainingModule, daysAgo: Int, decisions: Int = 0, correct: Int = 0,
                 checks: Int = 0, correctChecks: Int = 0) -> SessionSample {
        SessionSample(id: UUID(), module: module, startedAt: ago(daysAgo), decisionCount: decisions,
                      correctDecisions: correct, countChecks: checks, correctCountChecks: correctChecks)
    }

    func decision(_ cell: TrainingCell, _ correct: Bool, daysAgo: Int) -> DecisionSample {
        DecisionSample(date: ago(daysAgo), cell: cell, isCorrect: correct, responseMs: nil)
    }

    let h16 = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)

    @Test("Chips show per-module accuracy in the range; Shoe is combined")
    func chips() {
        let model = ProgressViewModel()
        let sessions = [session(.strategy, daysAgo: 0, decisions: 10, correct: 9),
                        session(.strategy, daysAgo: 8, decisions: 10, correct: 0),
                        session(.countingRC, daysAgo: 1, checks: 4, correctChecks: 3),
                        session(.countingTC, daysAgo: 2, checks: 2, correctChecks: 1),
                        session(.shoe, daysAgo: 3, decisions: 6, correct: 6, checks: 4, correctChecks: 2)]
        model.apply(entries: [], sessions: sessions, decisions: [], now: now, calendar: utc)
        #expect(model.chips.map(\.module) == [.strategy, .countingRC, .countingTC, .shoe])
        #expect(model.chips.map(\.value) == ["90%", "75%", "50%", "80%"])

        model.range = .allTime
        model.apply(entries: [], sessions: sessions, decisions: [], now: now, calendar: utc)
        #expect(model.chips.first?.value == "45%")
    }

    @Test("The trend has one point per day for the selected module, and a domain through today")
    func trend() {
        let model = ProgressViewModel()
        let sessions = [session(.strategy, daysAgo: 0, decisions: 10, correct: 9),
                        session(.strategy, daysAgo: 2, decisions: 4, correct: 2),
                        session(.countingRC, daysAgo: 1, checks: 2, correctChecks: 2)]
        model.apply(entries: [], sessions: sessions, decisions: [], now: now, calendar: utc)
        #expect(model.chartPoints.map(\.day) == [startOfDay(2), startOfDay(0)])
        #expect(model.chartPoints.map(\.accuracy) == [0.5, 0.9])
        #expect(model.chartSummary == "Strategy accuracy, 7 days: 2 days, latest 90%")
        #expect(model.chartDomain == startOfDay(6)...startOfDay(-1))

        model.trendModule = .countingRC
        #expect(model.chartPoints.map(\.accuracy) == [1])

        model.range = .allTime
        model.trendModule = .strategy
        model.apply(entries: [], sessions: sessions, decisions: [], now: now, calendar: utc)
        #expect(model.chartDomain == startOfDay(2)...startOfDay(-1))
    }

    @Test("No sessions at all is the empty state; sessions outside the range are not")
    func emptyStates() {
        let model = ProgressViewModel()
        model.apply(entries: [], sessions: [], decisions: [], now: now, calendar: utc)
        #expect(!model.hasAnySessions)

        let old = session(.strategy, daysAgo: 20, decisions: 5, correct: 5)
        model.apply(entries: [HistoryEntry(sample: old, mode: "test")], sessions: [old], decisions: [],
                    now: now, calendar: utc)
        #expect(model.hasAnySessions)
        #expect(model.chips.map(\.value) == ["—", "—", "—", "—"])
        #expect(model.chartPoints.isEmpty)
        #expect(!model.hasHeatData)
        #expect(model.history.count == 1)
    }

    @Test("Heat-map rows add hard 4 only when present; decisions outside the range are dropped")
    func heatRows() throws {
        let h4 = TrainingCell(handType: .hard, playerValue: 4, dealerUpcard: 5)
        let decisions = [decision(h16, false, daysAgo: 0), decision(h16, false, daysAgo: 1),
                         decision(h16, true, daysAgo: 2), decision(h4, true, daysAgo: 10)]
        let model = ProgressViewModel()
        model.apply(entries: [], sessions: [], decisions: decisions, now: now, calendar: utc)
        #expect(model.gridRows.map(\.id) == Array(5...20))
        let row16 = try #require(model.gridRows.first { $0.id == 16 })
        #expect(row16.label == "16")
        #expect(row16.cells.map(\.id) == Array(2...11))
        #expect(row16.cells.first { $0.id == 10 }?.bin == .severe)
        #expect(row16.cells.first { $0.id == 10 }?.accessibilityLabel == "Hard 16 vs 10")
        #expect(row16.cells.first { $0.id == 10 }?.accessibilityValue == "2 of 3 wrong (67%)")
        #expect(row16.cells.first { $0.id == 9 }?.bin == .insufficient)

        model.range = .allTime
        model.apply(entries: [], sessions: [], decisions: decisions, now: now, calendar: utc)
        #expect(model.gridRows.first?.id == 4)

        model.heatType = .pair
        #expect(model.gridRows.map(\.label).last == "A,A")
    }

    @Test("Selecting a cell shows its caption; selecting it again or changing hand type clears it")
    func selection() {
        let model = ProgressViewModel()
        model.apply(entries: [], sessions: [],
                    decisions: [decision(h16, false, daysAgo: 0), decision(h16, false, daysAgo: 0),
                                 decision(h16, true, daysAgo: 0)],
                    now: now, calendar: utc)
        #expect(model.caption == nil)
        model.select(row: 16, column: 10)
        #expect(model.caption == "Hard 16 vs 10 · 2 of 3 wrong (67%)")
        #expect(model.gridRows.first { $0.id == 16 }?.cells.first { $0.id == 10 }?.isSelected == true)
        model.select(row: 16, column: 10)
        #expect(model.caption == nil)
        model.select(row: 16, column: 10)
        model.heatType = .soft
        #expect(model.caption == nil)
    }

    @Test("History rows carry title, date and accuracy, in the order given")
    func historyRows() {
        let model = ProgressViewModel()
        let entries = [HistoryEntry(sample: session(.strategy, daysAgo: 0, decisions: 10, correct: 9), mode: "test"),
                       HistoryEntry(sample: session(.countingTC, daysAgo: 1, checks: 2, correctChecks: 1), mode: "exact"),
                       HistoryEntry(sample: session(.strategy, daysAgo: 2, decisions: 3, correct: 3), mode: "learn"),
                       HistoryEntry(sample: session(.countingRC, daysAgo: 3), mode: nil)]
        model.apply(entries: entries, sessions: [], decisions: [], now: now, calendar: utc)
        #expect(model.history.map(\.id) == entries.map(\.id))
        #expect(model.history.map(\.title) == ["Strategy · Test", "True count · Exact", "Strategy · Learn", "Running count"])
        #expect(model.history.map(\.accuracy) == ["90%", "50%", "100%", "—"])
        #expect(model.history.allSatisfy { !$0.dateText.isEmpty })
    }

    @Test("reload reads the store, excludes Learn from stats, and follows new saves")
    func reloadFromStore() throws {
        let container = try BJSModelContainer.make(inMemory: true)
        let store = SessionStore(context: container.mainContext)
        func draft(mode: String, correct: Bool) -> SessionDraft {
            SessionDraft(module: .strategy, mode: mode, startedAt: ago(0), endedAt: ago(0), rules: BlackjackRules(),
                         decisions: [DecisionDraft(handNumber: 1, cell: h16, chosen: .action(correct ? .hit : .stand),
                                                   correctAction: .hit, isCorrect: correct, responseMs: nil,
                                                   decidedAt: ago(0))])
        }
        try store.save(draft(mode: "learn", correct: false))
        let model = ProgressViewModel()
        model.reload(store: store, now: now, calendar: utc)
        #expect(model.hasAnySessions)
        #expect(model.history.count == 1)
        #expect(model.chips.first?.value == "—")
        #expect(!model.hasHeatData)

        try store.save(draft(mode: "test", correct: true))
        model.reload(store: store, now: now, calendar: utc)
        #expect(model.chips.first?.value == "100%")
        #expect(model.history.count == 2)
        #expect(!model.loadFailed)
    }
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `xcodegen generate`, then `-only-testing:BJSTests/ProgressTextTests -only-testing:BJSTests/ProgressViewModelTests`.
Expected: build FAIL, `cannot find 'ProgressText' in scope`.

- [ ] **Step 4: Implement `ProgressText`**

```swift
// BJS/Features/Progress/ProgressText.swift
import Foundation
import BJSCore

/// Copy for the Progress tab and session detail (Step 6 spec §2, §3).
enum ProgressText {
    static let noPointsCaption = "No sessions in this range"
    static let noHeatCaption = "No strategy decisions in this range"
    static let loadFailed = "Couldn't load your progress"
    static let emptyTitle = "No sessions yet"
    static let emptyMessage = "Finish a training session and your accuracy, trends and weak spots show up here."
    static let emptyButton = "Start training"

    static func rangeTitle(_ range: ProgressRange) -> String {
        switch range {
        case .week: return "7 days"
        case .month: return "30 days"
        case .allTime: return "All time"
        }
    }

    static func moduleTitle(_ module: TrainingModule) -> String {
        switch module {
        case .strategy: return "Strategy"
        case .countingRC: return "Running count"
        case .countingTC: return "True count"
        case .shoe: return "Shoe Sim"
        }
    }

    /// For the trend picker, where four segments share the width.
    static func moduleShortTitle(_ module: TrainingModule) -> String {
        switch module {
        case .strategy: return "Strategy"
        case .countingRC: return "Running"
        case .countingTC: return "True"
        case .shoe: return "Shoe"
        }
    }

    static func handTypeTitle(_ type: HandType) -> String {
        switch type {
        case .hard: return "Hard"
        case .soft: return "Soft"
        case .pair: return "Pairs"
        }
    }

    /// The saved mode's display name, or nil when there's none to show. Strategy modes are
    /// `StrategyMode` raw values (learn | test | speed | weakSpots); TC modes are
    /// `TrueCountConvention` raw values.
    static func modeTitle(_ mode: String?, module: TrainingModule) -> String? {
        guard let mode else { return nil }
        if module == .countingTC {
            switch TrueCountConvention(rawValue: mode) {
            case .exact: return "Exact"
            case .floor: return "Floor"
            case .truncate: return "Truncate"
            case nil: return nil
            }
        }
        switch mode {
        case "learn": return "Learn"
        case "test": return "Test"
        case "speed": return "Speed"
        case "weakSpots": return "Weak spots"
        default: return nil
        }
    }

    /// "Strategy · Test", "Running count", "True count · Exact".
    static func sessionTitle(module: TrainingModule, mode: String?) -> String {
        guard let modeTitle = modeTitle(mode, module: module) else { return moduleTitle(module) }
        return "\(moduleTitle(module)) · \(modeTitle)"
    }

    /// "2"…"10", "A".
    static func upcardLabel(_ upcard: Int) -> String {
        upcard == 11 ? "A" : "\(upcard)"
    }

    /// "16" for hard and soft rows; "8,8", "10,10", "A,A" for pairs.
    static func rowLabel(type: HandType, value: Int) -> String {
        guard type == .pair else { return "\(value)" }
        let card = upcardLabel(value)
        return "\(card),\(card)"
    }

    /// "Hard 16 vs 10", "Soft 18 vs A", "Pair of 8s vs 6", "Pair of Aces vs 2" (as `TrainingText.handLabel`).
    static func cellName(_ cell: TrainingCell) -> String {
        let up = upcardLabel(cell.dealerUpcard)
        switch cell.handType {
        case .hard: return "Hard \(cell.playerValue) vs \(up)"
        case .soft: return "Soft \(cell.playerValue) vs \(up)"
        case .pair:
            let name = cell.playerValue == 11 ? "Aces" : "\(cell.playerValue)s"
            return "Pair of \(name) vs \(up)"
        }
    }

    /// "no decisions", "2 decisions, not enough data", "3 of 7 wrong (43%)".
    static func cellDetail(_ heat: HeatCell?) -> String {
        guard let heat, heat.attempts > 0 else { return "no decisions" }
        guard let rate = heat.errorRate else {
            return heat.attempts == 1 ? "1 decision, not enough data" : "\(heat.attempts) decisions, not enough data"
        }
        return "\(heat.errors) of \(heat.attempts) wrong (\(PercentText.text(rate)))"
    }

    static func cellCaption(_ cell: TrainingCell, _ heat: HeatCell?) -> String {
        "\(cellName(cell)) · \(cellDetail(heat))"
    }

    static func dateTime(_ date: Date, locale: Locale = .autoupdatingCurrent,
                         timeZone: TimeZone = .autoupdatingCurrent) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, locale: locale, timeZone: timeZone))
    }

    static func dayLabel(_ day: Date) -> String {
        day.formatted(date: .abbreviated, time: .omitted)
    }

    /// "Strategy accuracy, 7 days: 5 days, latest 84%".
    static func chartSummary(module: TrainingModule, range: ProgressRange,
                             points: [ProgressViewModel.ChartPoint]) -> String {
        let head = "\(moduleTitle(module)) accuracy, \(rangeTitle(range).lowercased())"
        guard let last = points.last else { return "\(head): no sessions" }
        let days = points.count == 1 ? "1 day" : "\(points.count) days"
        return "\(head): \(days), latest \(PercentText.text(last.accuracy))"
    }
}
```

- [ ] **Step 5: Implement `ProgressViewModel`**

```swift
// BJS/Features/Progress/ProgressViewModel.swift
import Foundation
import Observation
import os
import BJSCore

/// Maps saved progress to the Progress tab's display values (Step 6 spec §2, §5).
@Observable
final class ProgressViewModel {
    struct Chip: Equatable, Identifiable {
        let module: TrainingModule
        let value: String
        var id: TrainingModule { module }
        var label: String { ProgressText.moduleTitle(module) }
    }

    struct ChartPoint: Equatable, Identifiable {
        let day: Date
        let accuracy: Double
        var id: Date { day }
    }

    struct HistoryRow: Equatable, Identifiable {
        let id: UUID
        let title: String
        let dateText: String
        let accuracy: String
    }

    static let modules: [TrainingModule] = [.strategy, .countingRC, .countingTC, .shoe]
    /// The heat map covers every graded strategy decision: the Strategy trainer's and Shoe Sim's.
    static let heatModules: Set<TrainingModule> = [.strategy, .shoe]
    static let handTypes: [HandType] = [.hard, .soft, .pair]
    static let columnLabels = HeatMapLayout.upcards.map(ProgressText.upcardLabel)

    var range: ProgressRange = .week
    var trendModule: TrainingModule = .strategy
    var heatType: HandType = .hard {
        didSet { if heatType != oldValue { selectedCell = nil } }
    }
    private(set) var selectedCell: TrainingCell?

    private(set) var hasAnySessions = false
    private(set) var loadFailed = false
    private(set) var chips: [Chip] = ProgressViewModel.modules.map { Chip(module: $0, value: PercentText.noData) }
    private(set) var history: [HistoryRow] = []
    private(set) var heat: [TrainingCell: HeatCell] = [:]
    private var trends: [TrainingModule: [ChartPoint]] = [:]
    private var rangeStart: Date?
    private var endOfToday: Date?

    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "ProgressViewModel")

    /// What each module's accuracy counts: decisions, count checks, or both for Shoe Sim.
    static func measure(_ module: TrainingModule) -> ProgressStats.Measure {
        switch module {
        case .strategy: return .decisions
        case .countingRC, .countingTC: return .countChecks
        case .shoe: return .combined
        }
    }

    /// One session's accuracy, measured as its module is.
    static func accuracyText(_ session: SessionSample) -> String {
        PercentText.text(ProgressStats.headline(sessions: [session], modules: [session.module],
                                                measure: measure(session.module), since: nil).accuracy)
    }

    var chartPoints: [ChartPoint] { trends[trendModule] ?? [] }

    /// From the range start (or the first point, for all time) to the end of today.
    var chartDomain: ClosedRange<Date>? {
        guard let start = rangeStart ?? chartPoints.first?.day, let endOfToday, start < endOfToday else { return nil }
        return start...endOfToday
    }

    var chartSummary: String {
        ProgressText.chartSummary(module: trendModule, range: range, points: chartPoints)
    }

    var hasHeatData: Bool { !heat.isEmpty }

    var gridRows: [HeatMapGrid.Row] {
        HeatMapLayout.rows(for: heatType, cells: heat).map { value in
            HeatMapGrid.Row(id: value, label: ProgressText.rowLabel(type: heatType, value: value),
                            cells: HeatMapLayout.upcards.map { upcard in
                let cell = TrainingCell(handType: heatType, playerValue: value, dealerUpcard: upcard)
                return HeatMapGrid.Cell(id: upcard, bin: HeatBin(heat[cell]),
                                        accessibilityLabel: ProgressText.cellName(cell),
                                        accessibilityValue: ProgressText.cellDetail(heat[cell]),
                                        isSelected: cell == selectedCell)
            })
        }
    }

    var caption: String? {
        selectedCell.map { ProgressText.cellCaption($0, heat[$0]) }
    }

    /// Selects the cell, or clears the selection when it's already selected.
    func select(row: Int, column: Int) {
        let cell = TrainingCell(handType: heatType, playerValue: row, dealerUpcard: column)
        selectedCell = selectedCell == cell ? nil : cell
    }

    /// Maps samples to display values. Filters to `range` itself, so callers may pass unfiltered samples.
    func apply(entries: [HistoryEntry], sessions: [SessionSample], decisions: [DecisionSample],
               now: Date, calendar: Calendar) {
        let since = range.since(now: now, calendar: calendar)
        rangeStart = since
        endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        hasAnySessions = !entries.isEmpty
        chips = Self.modules.map { module in
            Chip(module: module, value: PercentText.text(ProgressStats.headline(
                sessions: sessions, modules: [module], measure: Self.measure(module), since: since).accuracy))
        }
        trends = Dictionary(uniqueKeysWithValues: Self.modules.map { module in
            (module, ProgressStats.dailyTrend(sessions: sessions, modules: [module], measure: Self.measure(module),
                                              since: since, calendar: calendar)
                .map { ChartPoint(day: $0.day, accuracy: $0.accuracy) })
        })
        heat = ProgressStats.heatMap(decisions.filter { since == nil || $0.date >= since! })
        history = entries.map { entry in
            HistoryRow(id: entry.id,
                       title: ProgressText.sessionTitle(module: entry.sample.module, mode: entry.mode),
                       dateText: ProgressText.dateTime(entry.sample.startedAt),
                       accuracy: Self.accuracyText(entry.sample))
        }
    }

    /// Reads the store for the current range. A failed fetch shows `ProgressText.loadFailed`, never crashes.
    func reload(store: SessionStore, now: Date = .now, calendar: Calendar = .current) {
        let since = range.since(now: now, calendar: calendar)
        do {
            apply(entries: try store.historyEntries(),
                  sessions: try store.sessionSamples(since: since),
                  decisions: try store.decisionSamples(modules: Self.heatModules, since: since),
                  now: now, calendar: calendar)
            loadFailed = false
        } catch {
            logger.error("Progress failed to load: \(error.localizedDescription)")
            apply(entries: [], sessions: [], decisions: [], now: now, calendar: calendar)
            loadFailed = true
        }
    }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `-only-testing:BJSTests/ProgressTextTests -only-testing:BJSTests/ProgressViewModelTests`.
Expected: PASS.

Notes:
- If the `dateTime` test's `"12:00"` check fails because of an ICU spacing variant (e.g. a narrow no-break space before "AM"), keep the `"12:00"` substring check. Only the text after it varies.
- Leave the in-memory `container` alive for the whole test by keeping it in a local `let`, as written.

- [ ] **Step 7: Commit**

```bash
git add BJS/Features/Progress BJSTests/Features/ProgressTextTests.swift BJSTests/Features/ProgressViewModelTests.swift
git commit -m "feat(progress): ProgressText and ProgressViewModel

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: `SessionDetailViewModel`

**Files:**
- Create: `BJS/Features/Progress/SessionDetailViewModel.swift`
- Test: `BJSTests/Features/SessionDetailViewModelTests.swift`

**Interfaces:**
- Consumes:
  - `SessionDetail` (Task 5); `WhyContext(cell:userAction:correctAction:rules:table:)` (Task 3);
  - `TrainingText` (Task 4); `ProgressText.sessionTitle` and `ProgressText.dateTime`, and `ProgressViewModel.accuracyText` (Task 7);
  - `RulesSummary.text(for:)`, `CountDrillScore` and `StrategyEngine`.
- Produces: `struct SessionDetailViewModel`, with:
  - nested types: `Chip`, `MistakeRow` (has `why: WhyContext`) and `CheckRow`;
  - statics: `learnCaption` and `traceFootnote`;
  - properties: `title`, `dateText`, `captions`, `chips`, `mistakes`, `checks` and `showsTraceFootnote`;
  - `init(detail: SessionDetail, engine: StrategyEngine = StrategyEngine())`.

- [ ] **Step 1: Write the failing tests**

```swift
// BJSTests/Features/SessionDetailViewModelTests.swift
import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct SessionDetailViewModelTests {

    let rules = BlackjackRules()
    let h16 = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)
    let h13 = TrainingCell(handType: .hard, playerValue: 13, dealerUpcard: 2)

    func detail(_ module: TrainingModule, mode: String?, decisions: [SessionDetail.Decision] = [],
                checks: [SessionDetail.Check] = [], bestStreak: Int = 0, meanMs: Double? = nil) -> SessionDetail {
        SessionDetail(sample: SessionSample(id: UUID(), module: module, startedAt: Date(timeIntervalSince1970: 0),
                                            decisionCount: decisions.count,
                                            correctDecisions: decisions.filter(\.isCorrect).count,
                                            countChecks: checks.count,
                                            correctCountChecks: checks.filter(\.sample.isCorrect).count),
                      mode: mode, rules: rules, bestStreak: bestStreak, meanResponseMs: meanMs,
                      decisions: decisions, checks: checks)
    }

    func decision(_ cell: TrainingCell, _ chosen: RecordedChoice, _ correct: Action) -> SessionDetail.Decision {
        SessionDetail.Decision(cell: cell, chosen: chosen, correctAction: correct,
                               isCorrect: chosen == .action(correct), responseMs: 1_000)
    }

    func check(_ kind: CountKind, _ expected: Double, _ answered: Double, _ correct: Bool, cards: Int) -> SessionDetail.Check {
        SessionDetail.Check(sample: CountSample(date: .distantPast, kind: kind, expected: expected, answered: answered,
                                                isCorrect: correct, responseMs: nil),
                            cardsSeen: cards)
    }

    @Test("Strategy: chips, mistakes with WHY, and timeouts")
    func strategy() throws {
        let model = SessionDetailViewModel(detail: detail(.strategy, mode: "test", decisions: [
            decision(h16, .action(.hit), .hit), decision(h16, .action(.stand), .hit), decision(h13, .timeout, .stand),
        ], bestStreak: 1))
        #expect(model.title == "Strategy · Test")
        #expect(model.captions == [RulesSummary.text(for: rules)])
        #expect(model.chips.map(\.label) == ["Accuracy", "Mistakes", "Best streak", "Decisions"])
        #expect(model.chips.map(\.value) == ["33%", "2", "1", "3"])
        #expect(model.mistakes.map(\.label) == ["Hard 16 vs 10", "Hard 13 vs 2"])
        #expect(model.mistakes.map(\.value) == ["Stand → Hit", "Time's up → Stand"])
        let first = try #require(model.mistakes.first)
        #expect(first.why.userAction == .stand)
        #expect(first.why.correctAction == .hit)
        #expect(model.mistakes[1].why.userAction == nil)
        #expect(model.checks.isEmpty)
        #expect(!model.showsTraceFootnote)
    }

    @Test("Speed mode adds the average decision time; Learn adds its caption")
    func speedAndLearn() {
        let speed = SessionDetailViewModel(detail: detail(.strategy, mode: "speed",
                                                          decisions: [decision(h16, .action(.hit), .hit)], meanMs: 1_450))
        #expect(speed.chips.last?.label == "Avg decision")
        #expect(speed.chips.last?.value == "1.4 s" || speed.chips.last?.value == "1.5 s")
        let learn = SessionDetailViewModel(detail: detail(.strategy, mode: "learn",
                                                          decisions: [decision(h16, .action(.hit), .hit)]))
        #expect(learn.title == "Strategy · Learn")
        #expect(learn.captions.last == SessionDetailViewModel.learnCaption)
        #expect(!learn.chips.contains { $0.label == "Avg decision" })
    }

    @Test("Running count: chips and check rows")
    func runningCount() {
        let model = SessionDetailViewModel(detail: detail(.countingRC, mode: nil, checks: [
            check(.runningCount, 4, 4, true, cards: 12), check(.runningCount, 4, 3, false, cards: 26),
        ]))
        #expect(model.title == "Running count")
        #expect(model.chips.map(\.label) == ["Accuracy", "Correct", "Mean error"])
        #expect(model.chips.map(\.value) == ["50%", "1 / 2", "0.5"])
        #expect(model.checks.map(\.label) == ["After card 12", "After card 26"])
        #expect(model.checks.map(\.value) == ["+4", "+4 · you said +3"])
        #expect(model.mistakes.isEmpty)
        #expect(model.showsTraceFootnote)
    }

    @Test("True count: convention caption, targets to one decimal")
    func trueCount() {
        let model = SessionDetailViewModel(detail: detail(.countingTC, mode: "exact", checks: [
            check(.trueCount, 2.8, 3, true, cards: 104), check(.trueCount, -1.5, -1, false, cards: 156),
            check(.trueCount, 2, 2, true, cards: 200),
        ]))
        #expect(model.title == "True count · Exact")
        #expect(model.captions.last == TrainingText.conventionRule(.exact))
        #expect(model.checks.map(\.label) == ["Check 1", "Check 2", "Check 3"])
        #expect(model.checks.map(\.value) == ["+2.8", "\u{2212}1.5 · you said \u{2212}1", "+2"])
        #expect(model.showsTraceFootnote)
    }
}
```

The Speed test accepts either `1.4 s` or `1.5 s` because `%.1f` of 1.45 depends on binary rounding. Leave that alone.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodegen generate`, then `-only-testing:BJSTests/SessionDetailViewModelTests`.
Expected: build FAIL, `cannot find 'SessionDetailViewModel' in scope`.

- [ ] **Step 3: Implement**

```swift
// BJS/Features/Progress/SessionDetailViewModel.swift
import Foundation
import BJSCore

/// Display values for one saved session (Step 6 spec §3). A value type: the detail doesn't
/// change while it's on screen.
struct SessionDetailViewModel {
    struct Chip: Equatable, Identifiable {
        let label: String
        let value: String
        var id: String { label }
    }

    struct MistakeRow: Identifiable {
        let id: Int
        let label: String
        let value: String
        let why: WhyContext
    }

    struct CheckRow: Equatable, Identifiable {
        let id: Int
        let label: String
        let value: String
    }

    static let learnCaption = "Learn mode · not counted in your stats"
    static let traceFootnote = "The card-by-card trace isn't kept after a drill ends."

    let title: String
    let dateText: String
    let captions: [String]
    let chips: [Chip]
    let mistakes: [MistakeRow]
    let checks: [CheckRow]
    let showsTraceFootnote: Bool

    init(detail: SessionDetail, engine: StrategyEngine = StrategyEngine()) {
        let module = detail.sample.module
        title = ProgressText.sessionTitle(module: module, mode: detail.mode)
        dateText = ProgressText.dateTime(detail.sample.startedAt)

        var captions = [RulesSummary.text(for: detail.rules)]
        if detail.mode == "learn" { captions.append(Self.learnCaption) }
        if module == .countingTC, let mode = detail.mode, let convention = TrueCountConvention(rawValue: mode) {
            captions.append(TrainingText.conventionRule(convention))
        }
        self.captions = captions

        let accuracy = ProgressViewModel.accuracyText(detail.sample)
        switch module {
        case .strategy, .shoe:
            var chips = [Chip(label: "Accuracy", value: accuracy),
                         Chip(label: "Mistakes", value: "\(detail.decisions.filter { !$0.isCorrect }.count)"),
                         Chip(label: "Best streak", value: "\(detail.bestStreak)"),
                         Chip(label: "Decisions", value: "\(detail.sample.decisionCount)")]
            if detail.mode == "speed", let ms = detail.meanResponseMs {
                chips.append(Chip(label: "Avg decision", value: String(format: "%.1f s", ms / 1000)))
            }
            self.chips = chips
        case .countingRC, .countingTC:
            let score = CountDrillScore(detail.checks.map {
                (expected: $0.sample.expected, answered: $0.sample.answered, isCorrect: $0.sample.isCorrect)
            })
            self.chips = [Chip(label: "Accuracy", value: accuracy),
                          Chip(label: "Correct", value: "\(score.correct) / \(score.checks)"),
                          Chip(label: "Mean error", value: TrainingText.meanError(score.meanAbsoluteError))]
        }

        let table = engine.strategy(for: detail.rules)
        mistakes = detail.decisions.enumerated().compactMap { index, decision in
            guard !decision.isCorrect else { return nil }
            let userAction: Action?
            let chosenName: String
            switch decision.chosen {
            case .timeout:
                userAction = nil
                chosenName = "Time's up"
            case .action(let action):
                userAction = action
                chosenName = TrainingText.actionName(action)
            }
            let why = WhyContext(cell: decision.cell, userAction: userAction, correctAction: decision.correctAction,
                                 rules: detail.rules, table: table)
            return MistakeRow(id: index, label: TrainingText.handLabel(why),
                              value: "\(chosenName) → \(TrainingText.actionName(decision.correctAction))", why: why)
        }

        checks = detail.checks.enumerated().map { index, check in
            let s = check.sample
            switch s.kind {
            case .runningCount:
                let expected = TrainingText.signed(Int(s.expected))
                return CheckRow(id: index, label: "After card \(check.cardsSeen)",
                                value: s.isCorrect ? expected : "\(expected) · you said \(TrainingText.signed(Int(s.answered)))")
            case .trueCount:
                let target = TrainingText.signed(s.expected)
                return CheckRow(id: index, label: "Check \(index + 1)",
                                value: s.isCorrect ? target : "\(target) · you said \(TrainingText.signed(s.answered))")
            }
        }
        showsTraceFootnote = module == .countingRC || module == .countingTC
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run `-only-testing:BJSTests/SessionDetailViewModelTests`. Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add BJS/Features/Progress/SessionDetailViewModel.swift BJSTests/Features/SessionDetailViewModelTests.swift
git commit -m "feat(progress): SessionDetailViewModel with WHY rebuilt from saved decisions

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: The Progress screens, fixture and UI test

**Files:**
- Create:
  - `BJS/Features/Progress/ProgressTabView.swift`, `BJS/Features/Progress/SessionDetailView.swift`
  - `BJS/App/ProgressFixture.swift`
  - Tests: `BJSTests/Features/ProgressFixtureTests.swift`, `BJSUITests/ProgressUITests.swift`
- Modify:
  - `BJS/App/RootTabView.swift`, `BJS/App/BJSApp.swift`
  - the file that defines `LaunchConfiguration` (`grep -rln "struct LaunchConfiguration" BJS/App`)
  - Test: `BJSTests/AppShellTests.swift`

**Interfaces:**
- Consumes:
  - `ProgressViewModel` (Task 7) and `SessionDetailViewModel` (Task 8);
  - from Task 6: `HeatMapGrid` and `HeatMapLegend`;
  - from Task 4: `WhySheet`;
  - from Task 5: `SessionStore.sessionDetail(id:)`;
  - the Design components `ModePicker`, `StatChip`, `SettingsSection`, `SettingsRow` and `PrimaryButton`;
  - `AppRouter`.
- Produces:
  - `ProgressFixture.drafts(now:calendar:) -> [SessionDraft]` and `ProgressFixture.seed(into:now:calendar:)`, both DEBUG only;
  - `LaunchConfiguration.seedsProgressFixture: Bool`;
  - these accessibility identifiers:
    - `progress.chip.<module raw value>` on each headline chip;
    - `progress.chart`;
    - `progress.heatCaption`;
    - `progress.history.row` on each history row;
    - `progress.mistake` on each mistake row;
    - `progress.empty` on the empty state.

- [ ] **Step 1: Write the failing fixture and launch-argument tests**

```swift
// BJSTests/Features/ProgressFixtureTests.swift
import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct ProgressFixtureTests {

    @Test("The fixture yields the documented numbers")
    func numbers() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let now = Date(timeIntervalSince1970: 100 * 86_400 + 12 * 3_600)
        let container = try BJSModelContainer.make(inMemory: true)
        let store = SessionStore(context: container.mainContext)
        ProgressFixture.seed(into: store, now: now, calendar: utc)

        let model = ProgressViewModel()
        model.reload(store: store, now: now, calendar: utc)
        #expect(model.chips.map(\.value) == ["67%", "67%", "67%", "—"])
        #expect(model.history.count == 9)
        #expect(model.history.first?.title == "Strategy · Test")
        #expect(model.chartSummary == "Strategy accuracy, 7 days: 5 days, latest 57%")

        func bin(_ type: HandType, _ value: Int, _ upcard: Int) -> HeatBin {
            HeatBin(model.heat[TrainingCell(handType: type, playerValue: value, dealerUpcard: upcard)])
        }
        #expect(bin(.hard, 16, 10) == .severe)
        #expect(bin(.hard, 11, 6) == .low)
        #expect(bin(.hard, 12, 4) == .none)
        #expect(bin(.soft, 18, 9) == .high)
        #expect(bin(.pair, 8, 11) == .medium)
        #expect(bin(.hard, 13, 2) == .insufficient)
        #expect(model.gridRows.first?.id == 4)

        model.range = .allTime
        model.reload(store: store, now: now, calendar: utc)
        #expect(model.chips.first?.value == "69%")
    }
}
```

Append to `AppShellTests`:

```swift
    @Test("Launch arguments: the Progress fixture needs UI testing")
    func progressFixtureFlag() {
        #expect(LaunchConfiguration(arguments: ["BJS", "-uiTesting", "-progressFixture"]).seedsProgressFixture)
        #expect(!LaunchConfiguration(arguments: ["BJS", "-progressFixture"]).seedsProgressFixture)
        #expect(!LaunchConfiguration(arguments: ["BJS", "-uiTesting"]).seedsProgressFixture)
    }
```

Run: `xcodegen generate`, then `-only-testing:BJSTests/ProgressFixtureTests -only-testing:BJSTests/AppShellTests`.
Expected: build FAIL, `cannot find 'ProgressFixture' in scope`.

- [ ] **Step 2: Implement the fixture and the launch flag**

In `LaunchConfiguration`:
- add `/// UI testing only (DEBUG): seed the Progress fixture (Step 6 spec §5).` above a new property `let seedsProgressFixture: Bool`;
- in `init(arguments:)`, set `seedsProgressFixture = isUITesting && arguments.contains("-progressFixture")`.

```swift
// BJS/App/ProgressFixture.swift
#if DEBUG
import Foundation
import BJSCore

/// A deterministic saved history for the Progress UI test and design-check screenshots
/// (Step 6 spec §5). DEBUG and `-uiTesting` only.
///
/// Under the default rules (6D S17 DAS 3:2), with the 7-day range:
/// - Strategy is 22 of 33 = 67%; RC and TC are 2 of 3 = 67% each; Shoe has no data.
/// - All time, Strategy is 24 of 35 = 69%.
/// - Heat map: hard 16 vs 10 severe, hard 11 vs 6 low, hard 12 vs 4 none, soft 18 vs 9 high,
///   8,8 vs A medium, and one hard 4 decision.
/// - The day-3 Learn session is in history but not in the stats.
enum ProgressFixture {
    typealias Spec = (cell: TrainingCell, chosen: RecordedChoice, correct: Action)

    static func drafts(now: Date, calendar: Calendar = .current) -> [SessionDraft] {
        let rules = BlackjackRules()
        let today = calendar.startOfDay(for: now)
        let halfToday = now.timeIntervalSince(today) / 2
        /// Halfway through today's elapsed time, `daysAgo` calendar days back: always inside that day.
        func start(_ daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: today)!.addingTimeInterval(halfToday)
        }
        func cell(_ type: HandType, _ value: Int, _ upcard: Int) -> TrainingCell {
            TrainingCell(handType: type, playerValue: value, dealerUpcard: upcard)
        }
        func right(_ c: TrainingCell, _ action: Action) -> Spec { (c, .action(action), action) }
        func wrong(_ c: TrainingCell, _ chose: Action, _ correct: Action) -> Spec { (c, .action(chose), correct) }

        let h16 = cell(.hard, 16, 10), h11 = cell(.hard, 11, 6), h12 = cell(.hard, 12, 4)
        let s18 = cell(.soft, 18, 9), p8 = cell(.pair, 8, 11), h4 = cell(.hard, 4, 5), h13 = cell(.hard, 13, 2)
        let w16 = wrong(h16, .stand, .hit), r16 = right(h16, .hit)
        let r11 = right(h11, .double), w11 = wrong(h11, .hit, .double)
        let r12 = right(h12, .stand)
        let r18 = right(s18, .hit), w18 = wrong(s18, .stand, .hit)
        let r8 = right(p8, .split), w8 = wrong(p8, .hit, .split)
        let r4 = right(h4, .hit)
        let t13: Spec = (h13, .timeout, .stand)

        func strategy(_ daysAgo: Int, mode: String = "test", _ specs: [Spec]) -> SessionDraft {
            let s = start(daysAgo)
            return SessionDraft(module: .strategy, mode: mode, startedAt: s, endedAt: s.addingTimeInterval(300),
                                rules: rules, decisions: specs.enumerated().map { i, d in
                DecisionDraft(handNumber: i + 1, cell: d.cell, chosen: d.chosen, correctAction: d.correct,
                              isCorrect: d.chosen == .action(d.correct), responseMs: 1_500,
                              decidedAt: s.addingTimeInterval(Double(i + 1)))
            })
        }
        func counting(_ module: TrainingModule, mode: String?, _ daysAgo: Int, kind: CountKind,
                      _ values: [(expected: Double, answered: Double, correct: Bool, cards: Int)]) -> SessionDraft {
            let s = start(daysAgo).addingTimeInterval(-60)
            return SessionDraft(module: module, mode: mode, startedAt: s, endedAt: s.addingTimeInterval(120),
                                rules: rules, countChecks: values.enumerated().map { i, v in
                CountCheckDraft(kind: kind, expected: v.expected, answered: v.answered, isCorrect: v.correct,
                                responseMs: 2_000, cardsSeen: v.cards, checkedAt: s.addingTimeInterval(Double(i + 1)))
            })
        }

        return [
            strategy(0, [w16, w16, r16, r11, r11, r12, w18]),
            strategy(1, [w16, r11, r11, w11, r8, r8, r4]),
            strategy(2, [w16, r16, r11, r11, r12, r18, t13]),
            strategy(3, mode: "learn", [r16, r16, r11, r12, r18]),
            strategy(4, [w16, r11, r11, w8, r8, r18, r12]),
            strategy(6, [w16, r11, w18, r18, r12]),
            strategy(9, [r16, r11]),
            counting(.countingRC, mode: nil, 1, kind: .runningCount,
                     [(3, 3, true, 10), (5, 4, false, 20), (2, 2, true, 26)]),
            counting(.countingTC, mode: TrueCountConvention.exact.rawValue, 2, kind: .trueCount,
                     [(2.8, 3, true, 104), (-1.5, -1, false, 156), (1, 1, true, 208)]),
        ]
    }

    static func seed(into store: SessionStore, now: Date, calendar: Calendar = .current) {
        for draft in drafts(now: now, calendar: calendar) {
            try? store.save(draft)
        }
    }
}
#endif
```

In `BJSApp.init()`, replace

```swift
        _sessionStore = State(initialValue: SessionStore(context: container.mainContext,
                                                          isStorageDegraded: isStorageDegraded))
```

with

```swift
        let sessionStore = SessionStore(context: container.mainContext, isStorageDegraded: isStorageDegraded)
        #if DEBUG
        if launch.seedsProgressFixture { ProgressFixture.seed(into: sessionStore, now: .now) }
        #endif
        _sessionStore = State(initialValue: sessionStore)
```

Run the Step 1 command again. Expected: PASS.

If a number is off, recount against the fixture comment rather than changing the expectation. The expectations were derived by hand in the plan, cell by cell.

- [ ] **Step 3: Write `ProgressTabView`**

```swift
// BJS/Features/Progress/ProgressTabView.swift
import Charts
import SwiftUI
import BJSCore

/// The Progress tab (Step 6 spec §2). Named to avoid SwiftUI's `ProgressView`.
struct ProgressTabView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppRouter.self) private var router
    @State private var model = ProgressViewModel()

    private struct ReloadKey: Equatable {
        let revision: Int
        let range: ProgressRange
    }

    static let chartHeight: CGFloat = 180

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ZStack {
                FeltBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                        Text("Progress")
                            .feltText(.display)
                            .foregroundStyle(FeltColor.textPrimary)
                        if model.loadFailed {
                            Text(ProgressText.loadFailed)
                                .feltText(.body)
                                .foregroundStyle(FeltColor.incorrect)
                        }
                        if model.hasAnySessions {
                            ModePicker(options: ProgressRange.allCases, selection: $model.range,
                                       title: ProgressText.rangeTitle)
                            headlines
                            trend(model)
                            heatMap(model)
                            history
                        } else if !model.loadFailed {
                            emptyState
                        }
                    }
                    .padding(FeltSpacing.l)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                SessionDetailView(sessionID: id)
                    .toolbar(.visible, for: .navigationBar)
            }
        }
        .task(id: ReloadKey(revision: sessionStore.revision, range: model.range)) {
            model.reload(store: sessionStore)
        }
    }

    private var headlines: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s),
                            GridItem(.flexible(), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
            ForEach(model.chips) { chip in
                StatChip(label: chip.label, value: chip.value)
                    .accessibilityIdentifier("progress.chip.\(chip.module.rawValue)")
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .feltText(.label)
            .foregroundStyle(FeltColor.textTertiary)
    }

    private func trend(_ model: ProgressViewModel) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: FeltSpacing.m) {
            sectionLabel("Trend")
            ModePicker(options: ProgressViewModel.modules, selection: $model.trendModule,
                       title: ProgressText.moduleShortTitle)
            if let domain = model.chartDomain, !model.chartPoints.isEmpty {
                Chart(model.chartPoints) { point in
                    LineMark(x: .value("Day", point.day, unit: .day), y: .value("Accuracy", point.accuracy))
                        .foregroundStyle(FeltColor.cream)
                    PointMark(x: .value("Day", point.day, unit: .day), y: .value("Accuracy", point.accuracy))
                        .foregroundStyle(FeltColor.cream)
                        .accessibilityLabel(ProgressText.dayLabel(point.day))
                        .accessibilityValue(PercentText.text(point.accuracy))
                }
                .chartYScale(domain: 0...1)
                .chartXScale(domain: domain)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1]) { value in
                        AxisGridLine().foregroundStyle(FeltColor.surfaceInset)
                        AxisValueLabel {
                            if let fraction = value.as(Double.self) {
                                Text(PercentText.text(fraction))
                                    .font(FeltType.label.font)
                                    .foregroundStyle(FeltColor.textTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(FeltColor.surfaceInset)
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(FeltType.label.font)
                            .foregroundStyle(FeltColor.textTertiary)
                    }
                }
                .frame(height: Self.chartHeight)
                .accessibilityLabel(model.chartSummary)
                .accessibilityIdentifier("progress.chart")
            } else {
                Text(ProgressText.noPointsCaption)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: Self.chartHeight)
                    .accessibilityIdentifier("progress.chart")
            }
        }
    }

    private func heatMap(_ model: ProgressViewModel) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: FeltSpacing.m) {
            sectionLabel("Heat map")
            ModePicker(options: ProgressViewModel.handTypes, selection: $model.heatType,
                       title: ProgressText.handTypeTitle)
            if !model.hasHeatData {
                Text(ProgressText.noHeatCaption)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textSecondary)
            }
            HeatMapGrid(columns: ProgressViewModel.columnLabels, rows: model.gridRows) { row, column in
                model.select(row: row, column: column)
            }
            HeatMapLegend()
            if let caption = model.caption {
                Text(caption)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textSecondary)
                    .accessibilityIdentifier("progress.heatCaption")
            }
        }
    }

    private var history: some View {
        SettingsSection(title: "History") {
            ForEach(model.history) { row in
                NavigationLink(value: row.id) {
                    SettingsRow(label: row.title, footnote: row.dateText) {
                        Text(row.accuracy)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("progress.history.row")
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.m) {
            Text(ProgressText.emptyTitle)
                .feltText(.title)
                .foregroundStyle(FeltColor.textPrimary)
            Text(ProgressText.emptyMessage)
                .feltText(.body)
                .foregroundStyle(FeltColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: ProgressText.emptyButton) { router.selectedTab = .train }
        }
        .accessibilityIdentifier("progress.empty")
    }
}
```

Build-error notes:
- **`@Bindable` in helpers:** if the compiler rejects the local `@Bindable var model = model` inside a helper function, pass `Binding`s instead, e.g. `trend(selection: $model.trendModule)`, built in `body` where `@Bindable` is already declared.
- **Axis labels:** if `AxisValueLabel(format:)` doesn't accept `.font`/`.foregroundStyle` chaining, use the closure form: `AxisValueLabel { Text(date, format: .dateTime.day().month(.abbreviated)).font(…).foregroundStyle(…) }`, with `value.as(Date.self)` providing `date`.

- [ ] **Step 4: Write `SessionDetailView`**

```swift
// BJS/Features/Progress/SessionDetailView.swift
import os
import SwiftUI
import BJSCore

/// A read-only saved session, pushed from Progress history (Step 6 spec §3).
struct SessionDetailView: View {
    let sessionID: UUID
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var model: SessionDetailViewModel?
    @State private var loadFailed = false
    @State private var whyContext: WhyContext?

    private let logger = Logger(subsystem: "com.bjs.app", category: "SessionDetailView")

    var body: some View {
        ZStack {
            FeltBackground()
            ScrollView {
                if let model {
                    content(model)
                } else if loadFailed {
                    Text(ProgressText.loadFailed)
                        .feltText(.body)
                        .foregroundStyle(FeltColor.incorrect)
                        .padding(FeltSpacing.l)
                }
            }
        }
        .sheet(item: $whyContext) { WhySheet(context: $0) }
        .task(id: sessionStore.revision) { load() }
    }

    private func content(_ model: SessionDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xl) {
            VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                Text(model.title)
                    .feltText(.display)
                    .foregroundStyle(FeltColor.textPrimary)
                Text(model.dateText)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textSecondary)
            }
            VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                ForEach(model.captions, id: \.self) { caption in
                    Text(caption)
                        .feltText(.body)
                        .foregroundStyle(FeltColor.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s),
                                GridItem(.flexible(), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
                ForEach(model.chips) { StatChip(label: $0.label, value: $0.value) }
            }
            if !model.mistakes.isEmpty {
                SettingsSection(title: "Mistakes") {
                    ForEach(model.mistakes) { mistake in
                        Button { whyContext = mistake.why } label: {
                            SettingsRow(label: mistake.label) { Text(mistake.value) }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Explains the correct play")
                        .accessibilityIdentifier("progress.mistake")
                    }
                }
            }
            if !model.checks.isEmpty {
                SettingsSection(title: "Checks") {
                    ForEach(model.checks) { check in
                        SettingsRow(label: check.label) { Text(check.value) }
                    }
                }
            }
            if model.showsTraceFootnote {
                Text(SessionDetailViewModel.traceFootnote)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(FeltSpacing.l)
    }

    /// Pops back to the list when the session no longer exists (e.g. after a reset).
    private func load() {
        do {
            if let detail = try sessionStore.sessionDetail(id: sessionID) {
                model = SessionDetailViewModel(detail: detail)
                loadFailed = false
            } else {
                dismiss()
            }
        } catch {
            logger.error("Session detail failed to load: \(error.localizedDescription)")
            loadFailed = true
        }
    }
}
```

- [ ] **Step 5: Wire the tab**

In `BJS/App/RootTabView.swift`, replace

```swift
                ComingSoonView(title: "Progress", message: "Coming in Step 6")
```

with

```swift
                ProgressTabView()
```

Run `xcodegen generate`, then the full unit-test command (no UI tests yet):

```bash
xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:BJSTests > "$TMPDIR/bjs-test.log" 2>&1; grep -E "✘|error:|\*\* TEST" "$TMPDIR/bjs-test.log" | tail -20; grep -c "warning:" "$TMPDIR/bjs-test.log"
```

Expected: `** TEST SUCCEEDED **` and 0 warnings. If an existing test asserted the Progress placeholder (`grep -rn "Coming in Step 6" BJSTests BJSUITests`), update it to the new screen.

- [ ] **Step 6: Write the UI test**

```swift
// BJSUITests/ProgressUITests.swift
import XCTest

@MainActor
final class ProgressUITests: XCTestCase {

    private func waitForValue(_ element: XCUIElement, _ value: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "value == %@", value)
        return XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)],
                              timeout: timeout) == .completed
    }

    private func scrollToHittable(_ element: XCUIElement, in app: XCUIApplication) {
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
    }

    func testFixtureHeadlinesHistoryAndWhy() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-progressFixture", "-startTab", "progress"]
        app.launch()

        // 7 days: 22 of 33 strategy decisions.
        let strategy = app.descendants(matching: .any)["progress.chip.strategy"]
        XCTAssertTrue(strategy.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForValue(strategy, "67%"))
        XCTAssertTrue(app.descendants(matching: .any)["progress.chart"].exists)

        // All time adds the day-9 session: 24 of 35.
        app.buttons["All time"].tap()
        XCTAssertTrue(waitForValue(strategy, "69%"))

        // The newest session is a Strategy Test with mistakes.
        let row = app.buttons.matching(identifier: "progress.history.row").firstMatch
        scrollToHittable(row, in: app)
        row.tap()
        let mistake = app.buttons.matching(identifier: "progress.mistake").firstMatch
        XCTAssertTrue(mistake.waitForExistence(timeout: 5))
        mistake.tap()

        let close = app.buttons["strategy.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(mistake.waitForExistence(timeout: 5))
    }

    func testEmptyStateLinksToTrain() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-startTab", "progress"]
        app.launch()

        let start = app.buttons["Start training"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        XCTAssertTrue(app.buttons["hub.tile.strategy"].waitForExistence(timeout: 5))
    }
}
```

`hub.tile.strategy` assumes `AppModule.strategy.rawValue == "strategy"`. Confirm with `grep -n "case strategy" BJS/Shared/AppModule.swift`, and adjust the identifier if the raw value differs.

- [ ] **Step 7: Run the UI tests**

```bash
xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:BJSUITests/ProgressUITests > "$TMPDIR/bjs-ui.log" 2>&1; grep -E "Test Case|error:|\*\* TEST" "$TMPDIR/bjs-ui.log" | tail -20
```

Expected: both tests pass.

If the chip value never matches, the chip's accessibility value may be reported differently. Print `strategy.debugDescription` in a failing run, and adapt the query (not the expected number).

- [ ] **Step 8: Run everything**

Run the full app test command (unit + UI) and `cd BJSCore && swift test`.
Expected: all green; the app has 5 UI tests; 0 warnings.

- [ ] **Step 9: Commit**

```bash
git add -A BJS BJSTests BJSUITests
git commit -m "feat(progress): Progress tab, session detail, fixture and UI test

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Design check and handoff

**Files:**
- Modify: `docs/superpowers/progress.md`, and `docs/superpowers/specs/2026-09-27-step-6-progress-design.md` only if §4 or the heat-map opacities change.
- Screenshots go to the session scratchpad, not the repo.

- [ ] **Step 1: Capture screenshots**

Launch the app on iPhone 16 (18.4) with `-uiTesting -progressFixture -startTab progress`, and capture:
1. the top of the screen (range picker, chips, trend);
2. the trend for each of the four modules (Shoe shows "No sessions in this range");
3. the heat map on Hard (with the hard 4 row visible), Soft and Pairs;
4. a selected cell with its caption (hard 16 vs 10);
5. History;
6. a Strategy detail with its mistakes;
7. WHY from history;
8. the TC detail;
9. the empty state (launch without `-progressFixture`);
10. `FeltCatalogue`'s "Progress components" section (`-showCatalogue`).

Repeat on the SE 3rd gen (`OS=18.3.1`). Use the iOS Simulator tool's screenshot action, or `xcrun simctl io booted screenshot <path>`.

- [ ] **Step 2: Check conformance (spec §2, §3; parent §4)**

- Only Felt tokens; no brass anywhere.
- Nothing truncated on the SE:
  - the four chip labels, the four trend segments, the grid's "10,10" label;
  - the legend, history rows and captions.
- The heat-map bins are distinguishable, and the "not enough data" outline is visible on the felt.
- The selected ring is visible on a severe (full `incorrect`) cell.
- The chart's line, points and axis labels are legible.
- The navigation bar appears only on the detail screen, with a working back button.
- `FeltColorTests` is green.

Fix any issue inside `Features/Progress` or `HeatMapGrid`.
- **Opacities:** they may be tuned once here (spec §2). If you change them, update the spec table, `HeatMapGrid.fill` and `ProgressComponentTests` together.
- **Anything else:** any fix that would touch a frozen token or component goes in the handoff as a decision for Luke. Don't make it here.

- [ ] **Step 3: Write the handoff**

Append a `## Step 6 — Progress (<date>)` entry to `docs/superpowers/progress.md` in the style of the Step 5 entry:
- spec, plan, branch and commit range;
- test counts (BJSCore and app unit/UI);
- deviations from the plan;
- the `#Predicate` probe result;
- any WHY-rebuild limitation found in Task 3;
- the design-check results for both devices;
- deferred minors;
- the carry-overs. Mark the Step 6 items resolved:
  - history `forStats: false`;
  - the heat map's Learn exclusion and hard 4 / soft 12;
  - ranged fetches (and note "All time" still reads whole tables);
  - WHY-from-history legal actions;
  - the RC trace (accepted and stated);
- add for Step 8: the Progress tab, `HeatMapGrid` and the session detail need the AX3 pass;
- "Next: Step 7 (Shoe Sim)".

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/progress.md docs/superpowers/specs/2026-09-27-step-6-progress-design.md
git commit -m "docs: Step 6 handoff

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

## Spec coverage

| Spec item | Task |
|---|---|
| §1 range toggle, range definition, hub adopts it | 1, 7, 9 |
| §1 headlines per module, Shoe combined | 7, 9 |
| §1 trend with module picker, cream line | 7, 9 |
| §1 heat map (picker, Learn excluded, rows incl. hard 4 / soft 12) | 2, 7, 9 |
| §1 history (Learn included, newest first) | 5, 7, 9 |
| §1 session detail and WHY from history with no schema change | 3, 5, 8, 9 |
| §1 RC trace not shown, footnote | 8 |
| §1 empty state vs none in range | 7, 9 |
| §2 `HeatMapGrid` fills, legend, selection, accessibility, catalogue | 6, 7 |
| §2 chart styling and VoiceOver summary | 7, 9 |
| §3 detail captions, chips, mistakes, checks, pop on missing session | 8, 9 |
| §4 `ProgressRange`, `HeatBin`, `HeatMapLayout`, WhyContext rebuild and property test | 1, 2, 3 |
| §5 store additions, `#Predicate` probe, moves to Shared, `RootTabView`, fixture | 4, 5, 9 |
| §6 tests, UI test, design check | 1–10 |

# Steps 0–1: Cleanup and Engine Completion — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the old GSD-era app layer and planning artifacts, then finish `BJSCore` so every piece of game, drill and progress logic the new app needs is pure, seeded, and tested.

**Architecture:** `BJSCore` is a Swift package with no SwiftUI or SwiftData imports. This plan adds:
- a seeded RNG;
- a legal-action-aware strategy lookup;
- a pure `RoundEngine` state machine (deal → naturals → player actions including splits → dealer play → settlement);
- training-cell hand generation, weak-spot weights, count drills, an edge rating, and progress statistics.

The iOS app target is reduced to a compiling three-tab placeholder shell.

**Tech Stack:** Swift 6.2, Swift Testing (`import Testing`, `@Test`, `#expect`), Swift Package Manager (`swift test` inside `BJSCore/`), XcodeGen (`project.yml`), Xcode 27 / iOS 18 simulator.

**Spec:** `docs/superpowers/specs/2026-09-23-bjs-rebuild-design.md`. Read §3 (Architecture), §6 (Data) and §7 (Testing) before starting any task.

## Global Constraints

- `BJSCore` must never `import SwiftUI` or `import SwiftData`. `Foundation` is allowed.
- Every public `BJSCore` type is `Sendable`.
- Anything random takes `inout some RandomNumberGenerator` so tests can pass `SeededRandomNumberGenerator`.
- Tests use Swift Testing, never XCTest (XCTest is reserved for UI tests in later steps).
- The existing 95 `BJSCore` tests must stay green after every task.
- Commit after every task. Every commit message ends with a blank line and then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Commands, all run from the repo root `/Users/luke/Claude Projects/BJS` unless stated:
  - Engine tests: `cd BJSCore && swift test 2>&1 | tail -5`
  - App build + tests: `xcodegen generate && xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -quiet 2>&1 | tail -20`
- Card rank values: `Rank.blackjackValue` gives Ace = 1 and J/Q/K = 10. In `TrainingCell`, Ace is represented as 11 (upcard and pair value).
- Deal order in `RoundEngine` is fixed as: player card 1, dealer upcard, player card 2, dealer hole card.
- Don't add features not listed here (YAGNI). Don't restyle anything; there is no UI work in this plan beyond the placeholder shell.

---

## File map

**Created in `BJSCore/Sources/BJSCore/`:**

| File | Responsibility |
|---|---|
| `Explain/WhyExplanation.swift` | Moved from app: `HandType`, `WhyContext`, `WhyExplanation` |
| `Rules/RulePreset.swift` | Casino presets (pure data) |
| `Support/SeededRandomNumberGenerator.swift` | SplitMix64 deterministic RNG |
| `Round/RoundTypes.swift` | `HandOutcome`, `PlayerHandState`, `RoundError`, `DecisionSpot`, payout multiplier |
| `Round/RoundEngine.swift` | Round state machine |
| `Training/TrainingCell.swift` | `TrainingCell`, `HandFilter`, spot classification |
| `Training/HandGenerator.swift` | Cell sampling, card construction, stacked shoes |
| `Training/WeakSpotWeights.swift` | `DecisionSample`, weight computation |
| `Counting/CountDrills.swift` | `TrueCountConvention`, `DrillLength`, `RunningCountDrill`, `TrueCountQuestion`, `CountDrillGenerator` |
| `Edge/EdgeRating.swift` | Good / OK / Poor rating |
| `Progress/ProgressSamples.swift` | `TrainingModule`, `CountKind`, `CountSample`, `SessionSample` |
| `Progress/ProgressStats.swift` | Headline, trend, heat map, streak |

**Modified:**
- `Models/Shoe.swift`: `standardCards`, `init(orderedCards:)`, `shuffle(using:)`, `dealtCount`
- `Models/BlackjackHand.swift`: add `Equatable`
- `Strategy/StrategyTable.swift`: fallback tables + legal-aware lookup
- `Strategy/StrategyEngine.swift`: build the fallback tables

**App target:**
- `BJS/App/BJSApp.swift` rewritten; `BJS/App/RootTabView.swift` created
- `BJSTests/AppShellTests.swift` created
- Everything else in `BJS/` (except `Assets.xcassets`) and `BJSTests/` deleted

**Repo:**
- `.planning/` removed
- `design-system/` moved to the Trash
- `CLAUDE.md` rewritten
- `docs/superpowers/progress.md` created
- `project.yml` gains an explicit test scheme

---

# STEP 0 — CLEANUP

### Task 1: Move WhyExplanation into BJSCore and add RulePreset

**Files:**
- Move: `BJS/Domain/WhyExplanation.swift` → `BJSCore/Sources/BJSCore/Explain/WhyExplanation.swift`
- Move: `BJSTests/WhyExplanationTests.swift` → `BJSCore/Tests/BJSCoreTests/ExplainTests/WhyExplanationTests.swift`
- Create: `BJSCore/Sources/BJSCore/Rules/RulePreset.swift`
- Test: `BJSCore/Tests/BJSCoreTests/RulesTests/RulePresetTests.swift`

**Interfaces:**
- Produces:
  - `public enum HandType: String, Sendable, Equatable, Hashable, Codable, CaseIterable { case hard, soft, pair }`
  - `WhyContext` and `WhyExplanation.explain(_:) -> String`, unchanged
  - `public enum RulePreset: String, CaseIterable, Sendable, Identifiable` with `displayName: String`, `rules: BlackjackRules`, and `static func matching(_ rules: BlackjackRules) -> RulePreset?`

- [ ] **Step 1: Move the explanation source and its tests with git**

```bash
mkdir -p BJSCore/Sources/BJSCore/Explain BJSCore/Tests/BJSCoreTests/ExplainTests
git mv BJS/Domain/WhyExplanation.swift BJSCore/Sources/BJSCore/Explain/WhyExplanation.swift
git mv BJSTests/WhyExplanationTests.swift BJSCore/Tests/BJSCoreTests/ExplainTests/WhyExplanationTests.swift
```

- [ ] **Step 2: Fix imports and upgrade `HandType`**

In `BJSCore/Sources/BJSCore/Explain/WhyExplanation.swift`:
- delete the line `import BJSCore` (keep `import Foundation`);
- replace `public enum HandType: Sendable, Equatable {` with `public enum HandType: String, Sendable, Equatable, Hashable, Codable, CaseIterable {`.

In `BJSCore/Tests/BJSCoreTests/ExplainTests/WhyExplanationTests.swift`, replace these two lines:

```swift
@testable import BJS
import BJSCore
```

with:

```swift
@testable import BJSCore
```

- [ ] **Step 3: Run the engine tests and confirm the moved tests pass**

Run: `cd BJSCore && swift test 2>&1 | grep -E "WhyExplanation|Test run"`
Expected: WhyExplanation tests listed as passed; the final line says the run passed (more than 95 tests now).

- [ ] **Step 4: Write the failing RulePreset test**

Create `BJSCore/Tests/BJSCoreTests/RulesTests/RulePresetTests.swift`:

```swift
import Testing
@testable import BJSCore

@Suite("RulePreset")
struct RulePresetTests {

    @Test("Vegas Strip is 6D S17 DAS 3:2, no surrender")
    func vegasStrip() {
        let r = RulePreset.vegasStrip.rules
        #expect(r.deckCount == .six)
        #expect(r.dealerSoft17 == .stands)
        #expect(r.doubleAfterSplit)
        #expect(r.blackjackPayout == .threeToTwo)
        #expect(r.surrenderRule == .none)
        #expect(r.peekRule == .americanPeek)
    }

    @Test("Downtown Vegas is 2D H17 DAS late surrender")
    func downtown() {
        let r = RulePreset.downtownVegas.rules
        #expect(r.deckCount == .two)
        #expect(r.dealerSoft17 == .hits)
        #expect(r.surrenderRule == .late)
    }

    @Test("Atlantic City is 8D S17 DAS late surrender")
    func atlanticCity() {
        let r = RulePreset.atlanticCity.rules
        #expect(r.deckCount == .eight)
        #expect(r.dealerSoft17 == .stands)
        #expect(r.surrenderRule == .late)
        #expect(r.doubleAfterSplit)
    }

    @Test("Single deck 6:5 is 1D H17 6:5 no DAS")
    func singleDeck65() {
        let r = RulePreset.singleDeckSixFive.rules
        #expect(r.deckCount == .one)
        #expect(r.dealerSoft17 == .hits)
        #expect(r.blackjackPayout == .sixToFive)
        #expect(!r.doubleAfterSplit)
    }

    @Test("European is 6D S17 DAS with no hole card")
    func european() {
        let r = RulePreset.europeanNoHoleCard.rules
        #expect(r.deckCount == .six)
        #expect(r.peekRule == .europeanNoPeek)
    }

    @Test("Every preset has a distinct rule set and matches itself")
    func matching() {
        let all = RulePreset.allCases.map(\.rules)
        #expect(Set(all).count == RulePreset.allCases.count)
        for preset in RulePreset.allCases {
            #expect(RulePreset.matching(preset.rules) == preset)
        }
    }

    @Test("Custom rules match no preset")
    func customMatchesNothing() {
        var r = BlackjackRules()
        r.maxSplitHands = 2
        r.deckCount = .four
        #expect(RulePreset.matching(r) == nil)
    }

    @Test("Display names are human readable")
    func names() {
        #expect(RulePreset.vegasStrip.displayName == "Vegas Strip")
        #expect(RulePreset.singleDeckSixFive.displayName == "Single Deck 6:5")
    }
}
```

- [ ] **Step 5: Run it and confirm it fails**

Run: `cd BJSCore && swift test --filter RulePreset 2>&1 | tail -5`
Expected: FAIL. Compile error: `cannot find 'RulePreset' in scope`.

- [ ] **Step 6: Implement `RulePreset`**

Create `BJSCore/Sources/BJSCore/Rules/RulePreset.swift`:

```swift
/// Common casino rule sets used to pre-fill the rules form.
///
/// Presets are a UX convenience only: the app stores a plain `BlackjackRules`
/// value, and `matching(_:)` tells the UI which preset (if any) is active.
public enum RulePreset: String, CaseIterable, Sendable, Identifiable {
    case vegasStrip
    case downtownVegas
    case atlanticCity
    case singleDeckSixFive
    case europeanNoHoleCard

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vegasStrip: return "Vegas Strip"
        case .downtownVegas: return "Downtown Vegas"
        case .atlanticCity: return "Atlantic City"
        case .singleDeckSixFive: return "Single Deck 6:5"
        case .europeanNoHoleCard: return "European (No Hole Card)"
        }
    }

    public var rules: BlackjackRules {
        var r = BlackjackRules()
        switch self {
        case .vegasStrip:
            r.deckCount = .six
            r.dealerSoft17 = .stands
            r.doubleAfterSplit = true
            r.surrenderRule = .none
        case .downtownVegas:
            r.deckCount = .two
            r.dealerSoft17 = .hits
            r.doubleAfterSplit = true
            r.surrenderRule = .late
        case .atlanticCity:
            r.deckCount = .eight
            r.dealerSoft17 = .stands
            r.doubleAfterSplit = true
            r.surrenderRule = .late
        case .singleDeckSixFive:
            r.deckCount = .one
            r.dealerSoft17 = .hits
            r.blackjackPayout = .sixToFive
            r.doubleAfterSplit = false
        case .europeanNoHoleCard:
            r.deckCount = .six
            r.dealerSoft17 = .stands
            r.doubleAfterSplit = true
            r.peekRule = .europeanNoPeek
        }
        return r
    }

    /// The preset whose rules exactly equal `rules`, or nil for a custom rule set.
    public static func matching(_ rules: BlackjackRules) -> RulePreset? {
        allCases.first { $0.rules == rules }
    }
}
```

- [ ] **Step 7: Run the engine tests**

Run: `cd BJSCore && swift test 2>&1 | tail -3`
Expected: the test run passed with 0 failures.

- [ ] **Step 8: Commit**

```bash
git add -A BJSCore   # the git mv renames are already staged
git commit -m "refactor(core): move WhyExplanation into BJSCore, add RulePreset

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Delete the old app layer and ship a placeholder three-tab shell

**Files:**
- Delete: `BJS/Views/`, `BJS/Design/`, `BJS/ViewModels/`, `BJS/Models/`, `BJS/Resources/`, `BJS/Utilities/`, `BJS/Domain/` (if still present), and every file in `BJSTests/`
- Rewrite: `BJS/App/BJSApp.swift`
- Create: `BJS/App/RootTabView.swift`, `BJSTests/AppShellTests.swift`
- Modify: `project.yml` (explicit test scheme)

**Interfaces:**
- Produces:
  - `enum AppTab: String, CaseIterable, Identifiable { case train = "Train", progress = "Progress", settings = "Settings" }` with `systemImage: String`
  - `struct RootTabView: View`

  Step 2 (Foundation) replaces the placeholder tab contents.

- [ ] **Step 1: Delete the old app layer**

```bash
git rm -r -q BJS/Views BJS/Design BJS/ViewModels BJS/Models BJS/Resources BJS/Utilities
git rm -r -q --ignore-unmatch BJS/Domain
git rm -r -q BJSTests
ls BJS BJS/App
```

Expected: `BJS` contains only `App` and `Assets.xcassets`; `BJS/App` contains only `BJSApp.swift`.

- [ ] **Step 2: Write the failing shell test**

Create `BJSTests/AppShellTests.swift`:

```swift
import Testing
@testable import BJS

@MainActor
struct AppShellTests {

    @Test("App has exactly three tabs: Train, Progress, Settings")
    func tabsInOrder() {
        #expect(AppTab.allCases.map(\.rawValue) == ["Train", "Progress", "Settings"])
    }

    @Test("Every tab has an SF Symbol")
    func tabsHaveIcons() {
        for tab in AppTab.allCases {
            #expect(!tab.systemImage.isEmpty)
        }
    }
}
```

- [ ] **Step 3: Add an explicit test scheme to `project.yml`**

In `project.yml`, under `targets:` → `BJS:`, add a `scheme` block at the same indentation as `dependencies:`:

```yaml
    scheme:
      testTargets:
        - BJSTests
```

- [ ] **Step 4: Rewrite `BJS/App/BJSApp.swift`**

```swift
import SwiftUI

@main
struct BJSApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
        }
    }
}
```

- [ ] **Step 5: Create `BJS/App/RootTabView.swift`**

```swift
import SwiftUI

/// The three top-level tabs. Tab contents are placeholders until Step 2 (Foundation).
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

struct RootTabView: View {
    @State private var selection: AppTab = .train

    var body: some View {
        TabView(selection: $selection) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.rawValue, systemImage: tab.systemImage, value: tab) {
                    Text(tab.rawValue)
                        .font(.title)
                }
            }
        }
    }
}
```

- [ ] **Step 6: Generate the project, build, and run app tests**

Run: `xcodegen generate && xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -quiet 2>&1 | tail -20`
Expected: `** TEST SUCCEEDED **`, with both `AppShellTests` tests passing. If the destination isn't found, run `xcrun simctl list devices available | grep "iPhone 16"` and use an available iPhone 16 name.

- [ ] **Step 7: Confirm no references to deleted types remain**

Run: `grep -rn "TrainerViewModel\|CasinoPreset\|BJSColors\|HapticManager\|TrainingSession" BJS BJSTests || echo CLEAN`
Expected: `CLEAN`

- [ ] **Step 8: Commit**

```bash
git add -A BJS BJSTests project.yml
git commit -m "chore: remove old app layer, add placeholder three-tab shell

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Remove GSD artifacts, rewrite CLAUDE.md, start the progress log

**Files:**
- Delete: `.planning/` (tracked)
- Move to Trash: `design-system/` (untracked; must not be committed because it contains third-party screenshots)
- Rewrite: `CLAUDE.md`
- Create: `docs/superpowers/progress.md`

**Interfaces:** none (documentation and repo hygiene).

- [ ] **Step 1: Remove the planning directory and trash the old design folder**

```bash
git rm -r -q .planning
mv design-system ~/.Trash/BJS-design-system-2026-09-23
ls
```

Expected: no `.planning` or `design-system` in the listing.

- [ ] **Step 2: Replace `CLAUDE.md` with exactly this content**

````markdown
# BJS — Blackjack Training App

Native iPhone blackjack **trainer** (Swift 6.2 / SwiftUI / iOS 18+). Users get measurably better at basic strategy and Hi-Lo counting through accurate, rule-specific feedback. Educational only: no wagering, no real money. Visually it looks like a casino table (felt green, cream cards); behaviourally it's a serious training tool.

**Source of truth:** `docs/superpowers/specs/2026-09-23-bjs-rebuild-design.md` (the rebuild spec). Read it before planning any work.
**Progress log:** `docs/superpowers/progress.md`. Read the latest entry before starting a step; append a handoff entry when finishing one.
**Plans:** `docs/superpowers/plans/`

## Workflow

- Use superpowers skills: brainstorming → writing-plans → subagent-driven-development (or executing-plans) → verification-before-completion. TDD for all logic.
- Do **not** use GSD (`/gsd:*`); it was retired on 2026-09-23.
- One plan per build step (spec §8). Finish and verify a step before starting the next.
- Manage context: a fresh subagent per task; the main session coordinates. Write the step handoff to `progress.md` and start the next step in a fresh session.

## Architecture rules (spec §3)

1. All game logic lives in `BJSCore` (Swift package, no SwiftUI/SwiftData imports): dealing, rounds, strategy, counting, drills, explanations, weighting, statistics.
2. ViewModels are thin `@Observable` adapters: call the engine, map for display, sequence animations, persist.
3. One app-wide active rule set (`ActiveRulesStore`, `@AppStorage` JSON). Sessions snapshot their rules.
4. Feature folders (`BJS/Features/*`) never import each other; shared code lives in `Design/`, `Shared/`, `Persistence/` or `BJSCore`.
5. Randomness is injectable: take `inout some RandomNumberGenerator`; tests use `SeededRandomNumberGenerator`.
6. XcodeGen owns the project: edit `project.yml`, never the `.xcodeproj` (gitignored).

## Design system freeze (spec §4)

The Felt design system is the only design system. It is **frozen at the end of Step 2**. Later steps may add new components built from existing tokens, but must not restyle or re-tune existing tokens or components. A change to a frozen token needs an explicit decision from Luke in its own change, never inside a feature step. There are no "redesign" steps.

## Commands

```bash
# Engine tests (fast, no simulator)
cd BJSCore && swift test

# App: regenerate project, build, run unit tests
xcodegen generate
xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -quiet
```

## Conventions

- Swift Testing (`@Test`, `#expect`) for unit tests; XCTest only for UI tests.
- Commit after each task; conventional prefixes (`feat`, `fix`, `refactor`, `test`, `docs`, `chore`) with a scope (`core`, `app`, or a feature name).
- Maths correctness is the product's credibility: strategy and edge changes need tests against Wizard of Odds reference values.
````

- [ ] **Step 3: Create `docs/superpowers/progress.md`**

```markdown
# BJS Rebuild — Progress Log

Newest entry last. Each entry: step, date, commit range, what shipped, test status, notes for the next step.

## Step 0 — Cleanup (2026-09-23)

- Old app layer, `.planning/` (GSD) and `design-system/` removed; `WhyExplanation` moved into BJSCore; `RulePreset` added.
- App is a placeholder three-tab shell (`RootTabView`, `AppTab`).
- Next: Step 1 (engine completion), same plan file, Tasks 4–14.
```

- [ ] **Step 4: Remove the GSD mention from `.gitignore`**

In `.gitignore`, change the line `# GSD / Claude Code tooling — not part of shipped code` to `# Claude Code tooling — not part of shipped code`.

- [ ] **Step 5: Confirm no GSD references remain in tracked docs**

Run: `git grep -n -i "gsd" -- ':!docs/superpowers' ':!CLAUDE.md' || echo CLEAN`
Expected: `CLEAN`. The spec and plans in `docs/superpowers` mention GSD historically, and `CLAUDE.md` deliberately says it is retired; both are excluded from the search.

- [ ] **Step 6: Commit**

```bash
git add -A .planning CLAUDE.md .gitignore docs/superpowers/progress.md
git commit -m "docs: retire GSD, rewrite CLAUDE.md for the rebuild, start progress log

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

# STEP 1 — ENGINE COMPLETION

All Step 1 work happens in `BJSCore/`. Run tests with `cd BJSCore && swift test`.

### Task 4: Seeded RNG and injectable Shoe shuffling

**Files:**
- Create: `BJSCore/Sources/BJSCore/Support/SeededRandomNumberGenerator.swift`
- Modify: `BJSCore/Sources/BJSCore/Models/Shoe.swift`
- Modify: `BJSCore/Sources/BJSCore/Models/BlackjackHand.swift:5` (add `Equatable`)
- Test: `BJSCore/Tests/BJSCoreTests/ModelTests/ShoeSeedingTests.swift`

**Interfaces:**
- Produces:
  - `public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable { public init(seed: UInt64) }`
  - `Shoe.standardCards(deckCount: Int) -> [Card]` (static)
  - `Shoe.init(orderedCards: [Card], penetration: Double = 1.0)`: deals exactly in the given order
  - `mutating func shuffle<G: RandomNumberGenerator>(using rng: inout G)`
  - `var dealtCount: Int`
  - `BlackjackHand: Equatable`

- [ ] **Step 1: Write the failing tests**

Create `BJSCore/Tests/BJSCoreTests/ModelTests/ShoeSeedingTests.swift`:

```swift
import Testing
@testable import BJSCore

@Suite("Shoe seeding and stacking")
struct ShoeSeedingTests {

    @Test("Same seed produces the same shuffle")
    func sameSeedSameOrder() {
        var a = Shoe(deckCount: 2)
        var b = Shoe(deckCount: 2)
        var rngA = SeededRandomNumberGenerator(seed: 42)
        var rngB = SeededRandomNumberGenerator(seed: 42)
        a.shuffle(using: &rngA)
        b.shuffle(using: &rngB)
        let first = (0..<104).compactMap { _ in a.deal() }
        let second = (0..<104).compactMap { _ in b.deal() }
        #expect(first == second)
    }

    @Test("Different seeds produce different shuffles")
    func differentSeeds() {
        var a = Shoe(deckCount: 1)
        var b = Shoe(deckCount: 1)
        var rngA = SeededRandomNumberGenerator(seed: 1)
        var rngB = SeededRandomNumberGenerator(seed: 2)
        a.shuffle(using: &rngA)
        b.shuffle(using: &rngB)
        let first = (0..<52).compactMap { _ in a.deal() }
        let second = (0..<52).compactMap { _ in b.deal() }
        #expect(first != second)
    }

    @Test("Ordered shoe deals exactly the given cards then nil")
    func orderedShoe() {
        let cards = [Card(rank: .ace, suit: .spades), Card(rank: .two, suit: .hearts)]
        var shoe = Shoe(orderedCards: cards)
        #expect(shoe.totalCards == 2)
        #expect(shoe.deal() == cards[0])
        #expect(shoe.dealtCount == 1)
        #expect(shoe.deal() == cards[1])
        #expect(shoe.deal() == nil)
    }

    @Test("standardCards has 52 unique cards per deck")
    func standardCards() {
        #expect(Shoe.standardCards(deckCount: 1).count == 52)
        #expect(Set(Shoe.standardCards(deckCount: 1)).count == 52)
        #expect(Shoe.standardCards(deckCount: 6).count == 312)
    }

    @Test("BlackjackHand is Equatable by cards")
    func handEquatable() {
        let a = BlackjackHand(cards: [Card(rank: .ten, suit: .clubs)])
        let b = BlackjackHand(cards: [Card(rank: .ten, suit: .clubs)])
        #expect(a == b)
    }
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `cd BJSCore && swift test --filter "Shoe seeding" 2>&1 | tail -5`
Expected: FAIL. Compile errors for `SeededRandomNumberGenerator`, `orderedCards`, `dealtCount`, `standardCards`, and `==` on `BlackjackHand`.

- [ ] **Step 3: Implement the RNG**

Create `BJSCore/Sources/BJSCore/Support/SeededRandomNumberGenerator.swift`:

```swift
/// Deterministic SplitMix64 generator. Use in tests and anywhere a
/// reproducible shuffle or sample is needed; use `SystemRandomNumberGenerator` otherwise.
public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
```

- [ ] **Step 4: Extend `Shoe`**

In `BJSCore/Sources/BJSCore/Models/Shoe.swift`, replace the body of `public init(deckCount: Int, penetration: Double = 0.75)` so it uses the new static helper, and add the new members. The full new file:

```swift
/// A multi-deck card source (shoe) with shuffle, deal, and penetration tracking.
///
/// The shoe contains one or more standard 52-card decks. Cards are dealt in order
/// from the shuffled shoe. The `needsReshuffle` flag indicates when the dealt
/// percentage has reached or exceeded the configured penetration threshold.
public struct Shoe: Sendable {

    private var cards: [Card]
    private var dealIndex: Int = 0

    /// The total number of cards in the shoe (before any deals).
    public let totalCards: Int

    /// The fraction of the shoe that should be dealt before reshuffling (0.0-1.0).
    public let penetration: Double

    /// Creates an unshuffled shoe with the specified number of decks.
    /// - Parameters:
    ///   - deckCount: Number of standard 52-card decks (1-8).
    ///   - penetration: Fraction of shoe to deal before reshuffle (default 0.75 = 75%).
    public init(deckCount: Int, penetration: Double = 0.75) {
        self.init(orderedCards: Self.standardCards(deckCount: deckCount), penetration: penetration)
    }

    /// Creates a shoe that deals exactly `orderedCards`, first element first.
    /// Used for stacked training hands and deterministic tests.
    public init(orderedCards: [Card], penetration: Double = 1.0) {
        self.cards = orderedCards
        self.totalCards = orderedCards.count
        self.penetration = penetration
    }

    /// All cards of `deckCount` standard decks in a fixed, unshuffled order.
    public static func standardCards(deckCount: Int) -> [Card] {
        var all: [Card] = []
        all.reserveCapacity(deckCount * 52)
        for _ in 0..<deckCount {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    all.append(Card(rank: rank, suit: suit))
                }
            }
        }
        return all
    }

    /// Shuffles all cards using the system RNG and resets the deal position.
    public mutating func shuffle() {
        var rng = SystemRandomNumberGenerator()
        shuffle(using: &rng)
    }

    /// Shuffles all cards using `rng` and resets the deal position.
    public mutating func shuffle<G: RandomNumberGenerator>(using rng: inout G) {
        cards.shuffle(using: &rng)
        dealIndex = 0
    }

    /// Deals the next card from the shoe, or nil if the shoe is exhausted.
    public mutating func deal() -> Card? {
        guard dealIndex < cards.count else { return nil }
        let card = cards[dealIndex]
        dealIndex += 1
        return card
    }

    /// The number of cards dealt since the last shuffle.
    public var dealtCount: Int { dealIndex }

    /// The number of cards remaining to be dealt.
    public var cardsRemaining: Int { cards.count - dealIndex }

    /// The approximate number of decks remaining (cardsRemaining / 52).
    public var decksRemaining: Double { Double(cardsRemaining) / 52.0 }

    /// Whether the shoe has reached its penetration threshold and should be reshuffled.
    public var needsReshuffle: Bool {
        Double(dealIndex) / Double(totalCards) >= penetration
    }
}
```

- [ ] **Step 5: Make `BlackjackHand` Equatable**

In `BJSCore/Sources/BJSCore/Models/BlackjackHand.swift` change `public struct BlackjackHand: Sendable {` to `public struct BlackjackHand: Sendable, Equatable {`.

- [ ] **Step 6: Run all engine tests**

Run: `cd BJSCore && swift test 2>&1 | tail -3`
Expected: passed, 0 failures. The existing `ShoeTests` still pass.

- [ ] **Step 7: Commit**

```bash
git add BJSCore
git commit -m "feat(core): seeded RNG, injectable shoe shuffle, ordered shoes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Legal-action-aware strategy lookup with hit/stand fallback tables

**Why:** The table stores only the single best action. When that action is illegal (double or surrender on 3+ cards, double after split without DAS), the correct play is the best of hit/stand, which is not always "hit". Example: soft 18 vs 2 under H17 is "double, else **stand**". The old app mapped every illegal double to hit, which is wrong.

**Files:**
- Modify: `BJSCore/Sources/BJSCore/Strategy/StrategyTable.swift`
- Modify: `BJSCore/Sources/BJSCore/Strategy/StrategyEngine.swift` (the `bestNonPairAction` local function near line 368, the hard loop near line 413, the soft loop near line 431, the `return StrategyTable(...)` near line 520)
- Test: `BJSCore/Tests/BJSCoreTests/StrategyTests/StrategyFallbackTests.swift`

**Interfaces:**
- Consumes: `StrategyEngine().strategy(for:)`
- Produces:
  - `StrategyTable.hardHitStand: [[Action]]` (17×10) and `softHitStand: [[Action]]` (9×10), containing only `.hit` or `.stand`
  - `public func action(for hand: BlackjackHand, dealerUpcard: Rank, legal: Set<Action>) -> Action`: always returns a member of `legal` when `legal` contains `.stand`
  - The existing `action(for:dealerUpcard:rules:)` stays unchanged

- [ ] **Step 1: Write the failing tests**

Create `BJSCore/Tests/BJSCoreTests/StrategyTests/StrategyFallbackTests.swift`:

```swift
import Testing
@testable import BJSCore

@Suite("Strategy fallback when preferred action is illegal")
struct StrategyFallbackTests {

    private func h17() -> BlackjackRules {
        var r = BlackjackRules()
        r.dealerSoft17 = .hits
        r.surrenderRule = .late
        return r
    }

    private func hand(_ ranks: [Rank]) -> BlackjackHand {
        BlackjackHand(cards: ranks.map { Card(rank: $0, suit: .clubs) })
    }

    @Test("Fallback tables only contain hit or stand")
    func fallbackOnlyHitStand() {
        let table = StrategyEngine().strategy(for: h17())
        let all = table.hardHitStand.flatMap { $0 } + table.softHitStand.flatMap { $0 }
        #expect(all.allSatisfy { $0 == .hit || $0 == .stand })
        #expect(table.hardHitStand.count == 17)
        #expect(table.softHitStand.count == 9)
    }

    @Test("Two-card soft 18 vs 2 under H17 doubles when legal")
    func soft18DoublesWhenLegal() {
        let table = StrategyEngine().strategy(for: h17())
        let action = table.action(for: hand([.ace, .seven]), dealerUpcard: .two,
                                  legal: [.hit, .stand, .double])
        #expect(action == .double)
    }

    @Test("Three-card soft 18 vs 2 under H17 stands (not hit)")
    func soft18ThreeCardsStands() {
        let table = StrategyEngine().strategy(for: h17())
        let action = table.action(for: hand([.ace, .four, .three]), dealerUpcard: .two,
                                  legal: [.hit, .stand])
        #expect(action == .stand)
    }

    @Test("Three-card hard 11 vs 6 hits")
    func hard11ThreeCardsHits() {
        let table = StrategyEngine().strategy(for: h17())
        let action = table.action(for: hand([.two, .four, .five]), dealerUpcard: .six,
                                  legal: [.hit, .stand])
        #expect(action == .hit)
    }

    @Test("Hard 17 vs Ace fallback is stand")
    func hard17VsAceFallbackStand() {
        let table = StrategyEngine().strategy(for: h17())
        #expect(table.hardHitStand[17 - 5][Rank.ace.columnIndex] == .stand)
    }

    @Test("Pair splits only when split is legal")
    func pairNeedsLegalSplit() {
        let table = StrategyEngine().strategy(for: BlackjackRules())
        let eights = hand([.eight, .eight])
        #expect(table.action(for: eights, dealerUpcard: .ten, legal: [.hit, .stand, .split]) == .split)
        // Split no longer legal (max hands reached): played as hard 16 vs 10
        let noSplit = table.action(for: eights, dealerUpcard: .ten, legal: [.hit, .stand])
        #expect(noSplit == table.hardTotals[16 - 5][Rank.ten.columnIndex])
    }

    @Test("Result is always legal when stand is legal", arguments: Rank.allCases)
    func alwaysLegal(upcard: Rank) {
        let table = StrategyEngine().strategy(for: h17())
        let legalSets: [Set<Action>] = [[.stand], [.stand, .hit], [.stand, .hit, .double],
                                        [.stand, .hit, .surrender], [.stand, .split]]
        for a in Rank.allCases {
            for b in Rank.allCases {
                for legal in legalSets {
                    let action = table.action(for: hand([a, b]), dealerUpcard: upcard, legal: legal)
                    #expect(legal.contains(action))
                }
            }
        }
    }
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `cd BJSCore && swift test --filter "Strategy fallback" 2>&1 | tail -5`
Expected: FAIL. `hardHitStand` doesn't exist, and there is no `action(for:dealerUpcard:legal:)`.

- [ ] **Step 3: Extend `StrategyTable`**

Replace the full contents of `BJSCore/Sources/BJSCore/Strategy/StrategyTable.swift` with:

```swift
/// A lookup table containing the optimal basic strategy action for every
/// player hand vs dealer upcard combination under a specific set of rules.
///
/// - `hardTotals[playerTotal - 5][dealerUpcard.columnIndex]` -- 17 rows x 10 columns
/// - `softTotals[playerTotal - 13][dealerUpcard.columnIndex]` -- 9 rows x 10 columns
/// - `pairs[pairRankIndex][dealerUpcard.columnIndex]` -- 10 rows x 10 columns
/// - `hardHitStand` / `softHitStand` -- same shapes as hard/soft, best of hit vs stand only.
///   Used when the preferred action is not legal (e.g. double on three cards).
public struct StrategyTable: Sendable, Equatable {

    public let hardTotals: [[Action]]
    public let softTotals: [[Action]]
    public let pairs: [[Action]]
    public let hardHitStand: [[Action]]
    public let softHitStand: [[Action]]

    /// Returns the optimal action assuming every action the table might pick is available
    /// (two-card hand, no prior split). Kept for the Wizard of Odds validation tests.
    public func action(for hand: BlackjackHand, dealerUpcard: Rank, rules: BlackjackRules) -> Action {
        if hand.isPair && hand.canSplit(rules: rules, currentSplitCount: 0) {
            let pairAction = pairs[hand.pairIndex][dealerUpcard.columnIndex]
            if pairAction == .split { return .split }
        }
        if hand.isSoft {
            return softTotals[hand.softIndex][dealerUpcard.columnIndex]
        }
        return hardTotals[hand.hardIndex][dealerUpcard.columnIndex]
    }

    /// Returns the best action among `legal`.
    ///
    /// Order: split (if legal and the pair table says split) → the hard/soft table's
    /// preferred action if legal → the hit/stand fallback → stand.
    public func action(for hand: BlackjackHand, dealerUpcard: Rank, legal: Set<Action>) -> Action {
        let col = dealerUpcard.columnIndex
        if hand.isPair && legal.contains(.split) && pairs[hand.pairIndex][col] == .split {
            return .split
        }
        let preferred = hand.isSoft ? softTotals[hand.softIndex][col] : hardTotals[hand.hardIndex][col]
        if legal.contains(preferred) { return preferred }
        let fallback = hand.isSoft ? softHitStand[hand.softIndex][col] : hardHitStand[hand.hardIndex][col]
        return legal.contains(fallback) ? fallback : .stand
    }
}
```

- [ ] **Step 4: Build the fallback tables in `StrategyEngine.generateTable`**

In `BJSCore/Sources/BJSCore/Strategy/StrategyEngine.swift`:

(a) Change the local function signature near line 368 from

```swift
        func bestNonPairAction(hardTotal: Int, softBonus: Int, effectiveTotal: Int,
                               dealerCol: Int, allowSurrender: Bool) -> (Action, Double) {
```

to

```swift
        func bestNonPairAction(hardTotal: Int, softBonus: Int, effectiveTotal: Int,
                               dealerCol: Int, allowSurrender: Bool,
                               allowDouble: Bool = true) -> (Action, Double) {
```

and inside it change `if canDoubleCheck(total: effectiveTotal) {` to `if allowDouble && canDoubleCheck(total: effectiveTotal) {`.

(b) Replace the hard-totals block (starting at `var hardTotals: [[Action]] = ...` and ending at that loop's closing brace) with:

```swift
        var hardTotals: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 17)
        var hardHitStand: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 17)

        for dealerCol in 0..<10 {
            evCache = [:]
            currentCardProbs = cardProbsByCol[dealerCol]
            for row in 0..<17 {
                let playerTotal = row + 5
                let (action, _) = bestNonPairAction(
                    hardTotal: playerTotal, softBonus: 0, effectiveTotal: playerTotal,
                    dealerCol: dealerCol, allowSurrender: true
                )
                hardTotals[row][dealerCol] = action
                let (fallback, _) = bestNonPairAction(
                    hardTotal: playerTotal, softBonus: 0, effectiveTotal: playerTotal,
                    dealerCol: dealerCol, allowSurrender: false, allowDouble: false
                )
                hardHitStand[row][dealerCol] = fallback
            }
        }
```

(c) Replace the soft-totals block the same way:

```swift
        var softTotals: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 9)
        var softHitStand: [[Action]] = Array(repeating: Array(repeating: Action.stand, count: 10), count: 9)

        for dealerCol in 0..<10 {
            evCache = [:]
            currentCardProbs = cardProbsByCol[dealerCol]
            for row in 0..<9 {
                let playerTotal = row + 13
                let hardTotal = playerTotal - 10
                let (action, _) = bestNonPairAction(
                    hardTotal: hardTotal, softBonus: 10, effectiveTotal: playerTotal,
                    dealerCol: dealerCol, allowSurrender: true
                )
                softTotals[row][dealerCol] = action
                let (fallback, _) = bestNonPairAction(
                    hardTotal: hardTotal, softBonus: 10, effectiveTotal: playerTotal,
                    dealerCol: dealerCol, allowSurrender: false, allowDouble: false
                )
                softHitStand[row][dealerCol] = fallback
            }
        }
```

(d) Change the final return to:

```swift
        return StrategyTable(hardTotals: hardTotals, softTotals: softTotals, pairs: pairs,
                             hardHitStand: hardHitStand, softHitStand: softHitStand)
```

- [ ] **Step 5: Run all engine tests**

Run: `cd BJSCore && swift test 2>&1 | tail -3`
Expected: passed, 0 failures. The Wizard of Odds validation suite must still pass unchanged. If `hard17VsAceFallbackStand` or `soft18ThreeCardsStands` fail, the engine's hit-vs-stand model is off for that cell. Report it as a finding and don't edit the expected value.

- [ ] **Step 6: Commit**

```bash
git add BJSCore
git commit -m "feat(core): legal-action-aware strategy lookup with hit/stand fallback

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: RoundEngine — deal, naturals, hit/stand/double/surrender, dealer play, settlement

**Files:**
- Create: `BJSCore/Sources/BJSCore/Round/RoundTypes.swift`
- Create: `BJSCore/Sources/BJSCore/Round/RoundEngine.swift`
- Test: `BJSCore/Tests/BJSCoreTests/RoundTests/RoundEngineTests.swift`

**Interfaces:**
- Consumes: `Shoe(orderedCards:)` (Task 4), `StrategyTable.action(for:dealerUpcard:legal:)` (Task 5)
- Produces (later tasks and Step 3/7 ViewModels depend on these exact names):
  - `public enum HandOutcome: String, Sendable, Equatable, Codable { case blackjack, win, push, loss, bust, surrendered }`
  - `public struct PlayerHandState: Sendable, Equatable` with fields `hand`, `isDoubled`, `isSurrendered`, `isFromSplit`, `isSplitAces`, `isFinished`, `outcome: HandOutcome?`, `net: Double`, and computed `betUnits: Double`
  - `public enum RoundError: Error, Equatable, Sendable { case shoeExhausted, illegalAction(Action), notPlayerTurn }`
  - `public struct DecisionSpot: Sendable, Equatable { hand, dealerUpcard: Rank, legalActions: Set<Action> }`
  - `extension BlackjackRules.BlackjackPayout { public var multiplier: Double }`
  - `public struct RoundEngine: Sendable` with:
    - `init(rules:shoe:) throws`
    - `rules`, `dealer: BlackjackHand`, `hands: [PlayerHandState]`, `activeHandIndex: Int`, `phase: Phase` (`.playerTurn` / `.settled`), `drawnCards: [Card]`
    - `legalActions: Set<Action>`, `currentSpot: DecisionSpot?`, `totalNet: Double`
    - `mutating func apply(_ action: Action, shoe: inout Shoe) throws`
  - `extension StrategyTable { public func action(for spot: DecisionSpot) -> Action }`

**Behaviour contract:**
- Deal order: P1, dealer upcard, P2, dealer hole. All four go into `drawnCards` immediately. Every later draw is appended to `drawnCards`.
- Player natural: settles at once as `.push` (dealer also has a natural) or `.blackjack` (net = payout multiplier).
- Dealer natural with American peek:
  - Surrender is not early: settles at once, player `.loss`, net −1.
  - Early surrender: the player gets one decision. `.surrender` gives −0.5. Any other action settles immediately as `.loss` −1, and no card is drawn.
- Dealer natural with European no-peek: the player plays the hand out. At the end, every hand loses its full `betUnits`. A surrendered hand gets −0.5 only under early surrender; otherwise it is −1 `.loss`.
- A hand is finished automatically when its total reaches 21 or busts.
- The dealer draws only if at least one hand is neither bust nor surrendered. The dealer hits below 17, and on soft 17 when `dealerSoft17 == .hits`.
- Insurance is not offered (basic strategy never takes it).
- Splits are implemented in Task 7. In this task `.split` is never legal: `legalActions` doesn't include it yet.

- [ ] **Step 1: Write the failing tests**

Create `BJSCore/Tests/BJSCoreTests/RoundTests/RoundEngineTests.swift`:

```swift
import Testing
@testable import BJSCore

/// Builds a shoe that deals `ranks` in order (all spades; suits don't matter for play).
func stackedShoe(_ ranks: [Rank]) -> Shoe {
    Shoe(orderedCards: ranks.map { Card(rank: $0, suit: .spades) })
}

@Suite("RoundEngine — basics")
struct RoundEngineTests {

    // Deal order: P1, UP, P2, HOLE, then draws.

    @Test("Player blackjack pays according to payout rule",
          arguments: [(BlackjackRules.BlackjackPayout.threeToTwo, 1.5),
                      (.sixToFive, 1.2),
                      (.twoToOne, 2.0)])
    func playerBlackjack(payout: BlackjackRules.BlackjackPayout, expected: Double) throws {
        var rules = BlackjackRules()
        rules.blackjackPayout = payout
        var shoe = stackedShoe([.ace, .nine, .king, .seven])
        let round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].outcome == .blackjack)
        #expect(round.totalNet == expected)
    }

    @Test("Both naturals push")
    func bothNaturals() throws {
        var shoe = stackedShoe([.ace, .ace, .king, .queen])
        let round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        #expect(round.hands[0].outcome == .push)
        #expect(round.totalNet == 0)
    }

    @Test("Dealer natural with American peek settles immediately as a loss")
    func dealerNaturalPeek() throws {
        var shoe = stackedShoe([.ten, .ace, .seven, .king])
        let round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].outcome == .loss)
        #expect(round.totalNet == -1)
        #expect(round.legalActions.isEmpty)
    }

    @Test("ENHC: dealer natural found at the end takes doubled bet")
    func enhcTakesDouble() throws {
        var rules = BlackjackRules()
        rules.peekRule = .europeanNoPeek
        var shoe = stackedShoe([.five, .ace, .six, .king, .two])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.phase == .playerTurn)
        try round.apply(.double, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].outcome == .loss)
        #expect(round.totalNet == -2)
    }

    @Test("Early surrender vs dealer natural returns half")
    func earlySurrenderVsNatural() throws {
        var rules = BlackjackRules()
        rules.surrenderRule = .early
        var shoe = stackedShoe([.ten, .ace, .six, .king])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.legalActions.contains(.surrender))
        try round.apply(.surrender, shoe: &shoe)
        #expect(round.hands[0].outcome == .surrendered)
        #expect(round.totalNet == -0.5)
    }

    @Test("Early surrender declined vs dealer natural loses one unit, no card drawn")
    func earlySurrenderDeclined() throws {
        var rules = BlackjackRules()
        rules.surrenderRule = .early
        var shoe = stackedShoe([.ten, .ace, .six, .king, .five])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.hit, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.totalNet == -1)
        #expect(round.drawnCards.count == 4)
    }

    @Test("Bust loses and dealer does not draw")
    func bustNoDealerDraw() throws {
        var shoe = stackedShoe([.ten, .six, .six, .ten, .king])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.hit, shoe: &shoe)
        #expect(round.hands[0].outcome == .bust)
        #expect(round.totalNet == -1)
        #expect(round.dealer.cards.count == 2)
    }

    @Test("S17: dealer stands on soft 17")
    func s17() throws {
        var shoe = stackedShoe([.ten, .ace, .eight, .six])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.stand, shoe: &shoe)
        #expect(round.dealer.total == 17)
        #expect(round.hands[0].outcome == .win)
        #expect(round.totalNet == 1)
    }

    @Test("H17: dealer hits soft 17")
    func h17() throws {
        var rules = BlackjackRules()
        rules.dealerSoft17 = .hits
        var shoe = stackedShoe([.ten, .ace, .eight, .six, .five, .nine])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.stand, shoe: &shoe)
        #expect(round.dealer.total == 21)
        #expect(round.hands[0].outcome == .loss)
    }

    @Test("Winning double pays two units")
    func doubleWin() throws {
        var shoe = stackedShoe([.six, .six, .five, .ten, .ten, .ten])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.double, shoe: &shoe)
        #expect(round.hands[0].isDoubled)
        #expect(round.hands[0].outcome == .win)
        #expect(round.totalNet == 2)
    }

    @Test("Late surrender returns half")
    func lateSurrender() throws {
        var rules = BlackjackRules()
        rules.surrenderRule = .late
        var shoe = stackedShoe([.ten, .ten, .six, .seven])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.surrender, shoe: &shoe)
        #expect(round.hands[0].outcome == .surrendered)
        #expect(round.totalNet == -0.5)
    }

    @Test("Legal actions for a fresh two-card hand")
    func legalActionsFresh() throws {
        var shoe = stackedShoe([.ten, .nine, .six, .eight, .two])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        #expect(round.legalActions == [.hit, .stand, .double])
        try round.apply(.hit, shoe: &shoe)
        #expect(round.legalActions == [.hit, .stand])
    }

    @Test("Double restriction 10-11 blocks doubling on 9")
    func doubleRestriction() throws {
        var rules = BlackjackRules()
        rules.doubleRestriction = .tenToEleven
        var shoe = stackedShoe([.five, .nine, .four, .eight])
        let round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(!round.legalActions.contains(.double))
    }

    @Test("Illegal action throws")
    func illegalThrows() throws {
        var shoe = stackedShoe([.ten, .nine, .six, .eight])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        #expect(throws: RoundError.illegalAction(.split)) {
            try round.apply(.split, shoe: &shoe)
        }
    }

    @Test("Hitting to 21 finishes the hand automatically")
    func autoFinishOn21() throws {
        var shoe = stackedShoe([.five, .nine, .six, .eight, .ten])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.hit, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].hand.total == 21)
        #expect(round.hands[0].outcome == .win)
    }

    @Test("drawnCards records every card taken from the shoe")
    func drawnCardsMatchesShoe() throws {
        var shoe = stackedShoe([.ten, .six, .two, .ten, .three, .five, .four])
        let before = shoe.dealtCount
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.hit, shoe: &shoe)
        try round.apply(.stand, shoe: &shoe)
        #expect(round.drawnCards.count == shoe.dealtCount - before)
    }

    @Test("Short shoe throws shoeExhausted")
    func shortShoe() {
        var shoe = stackedShoe([.ten, .six])
        #expect(throws: RoundError.shoeExhausted) {
            _ = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        }
    }

    @Test("currentSpot mirrors the active hand and legal actions")
    func currentSpot() throws {
        var shoe = stackedShoe([.ten, .nine, .six, .eight])
        let round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        let spot = try #require(round.currentSpot)
        #expect(spot.hand.total == 16)
        #expect(spot.dealerUpcard == .nine)
        #expect(spot.legalActions == round.legalActions)
        let table = StrategyEngine().strategy(for: BlackjackRules())
        #expect(table.action(for: spot) == .hit)
    }
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `cd BJSCore && swift test --filter "RoundEngine" 2>&1 | tail -5`
Expected: FAIL. `RoundEngine` is not defined.

- [ ] **Step 3: Implement the round types**

Create `BJSCore/Sources/BJSCore/Round/RoundTypes.swift`:

```swift
/// Result of one player hand after the round settles.
public enum HandOutcome: String, Sendable, Equatable, Codable {
    case blackjack, win, push, loss, bust, surrendered
}

/// One player hand inside a round. A round holds several after splits.
public struct PlayerHandState: Sendable, Equatable {
    public internal(set) var hand: BlackjackHand
    public internal(set) var isDoubled = false
    public internal(set) var isSurrendered = false
    /// True when this hand was created by splitting.
    public internal(set) var isFromSplit = false
    /// True when this hand was created by splitting aces.
    public internal(set) var isSplitAces = false
    public internal(set) var isFinished = false
    public internal(set) var outcome: HandOutcome?
    /// Net result in units of the initial bet (e.g. +1.5 for a 3:2 blackjack, -2 for a lost double).
    public internal(set) var net: Double = 0

    /// Units at risk on this hand.
    public var betUnits: Double { isDoubled ? 2 : 1 }

    init(hand: BlackjackHand) {
        self.hand = hand
    }
}

public enum RoundError: Error, Equatable, Sendable {
    case shoeExhausted
    case illegalAction(Action)
    case notPlayerTurn
}

/// Everything needed to grade one player decision.
public struct DecisionSpot: Sendable, Equatable {
    public let hand: BlackjackHand
    public let dealerUpcard: Rank
    public let legalActions: Set<Action>

    public init(hand: BlackjackHand, dealerUpcard: Rank, legalActions: Set<Action>) {
        self.hand = hand
        self.dealerUpcard = dealerUpcard
        self.legalActions = legalActions
    }
}

extension BlackjackRules.BlackjackPayout {
    /// Units won on a natural for a one-unit bet.
    public var multiplier: Double {
        switch self {
        case .threeToTwo: return 1.5
        case .sixToFive: return 1.2
        case .twoToOne: return 2.0
        }
    }
}

extension StrategyTable {
    /// The correct (legal) action for a decision spot.
    public func action(for spot: DecisionSpot) -> Action {
        action(for: spot.hand, dealerUpcard: spot.dealerUpcard, legal: spot.legalActions)
    }
}
```

- [ ] **Step 4: Implement `RoundEngine` (no splits yet)**

Create `BJSCore/Sources/BJSCore/Round/RoundEngine.swift`:

```swift
/// A single blackjack round as a pure value-type state machine.
///
/// Create it with a shoe (deals P1, dealer upcard, P2, dealer hole), then call
/// `apply(_:shoe:)` with player actions until `phase == .settled`. The dealer
/// plays automatically once every player hand is finished.
public struct RoundEngine: Sendable {

    public enum Phase: Sendable, Equatable {
        case playerTurn
        case settled
    }

    public let rules: BlackjackRules
    public private(set) var dealer: BlackjackHand
    public private(set) var hands: [PlayerHandState]
    public private(set) var activeHandIndex: Int = 0
    public private(set) var phase: Phase = .playerTurn
    /// Every card taken from the shoe during this round, in draw order.
    public private(set) var drawnCards: [Card]

    /// True when the dealer holds a natural that is only revealed after the
    /// player's early-surrender decision (American peek + early surrender).
    private var peekPending = false

    public init(rules: BlackjackRules, shoe: inout Shoe) throws {
        guard let p1 = shoe.deal(), let up = shoe.deal(),
              let p2 = shoe.deal(), let hole = shoe.deal() else {
            throw RoundError.shoeExhausted
        }
        self.rules = rules
        self.dealer = BlackjackHand(cards: [up, hole])
        self.hands = [PlayerHandState(hand: BlackjackHand(cards: [p1, p2]))]
        self.drawnCards = [p1, up, p2, hole]
        resolveNaturals()
    }

    // MARK: - Queries

    public var dealerUpcard: Card { dealer.cards[0] }

    public var totalNet: Double { hands.reduce(0) { $0 + $1.net } }

    public var legalActions: Set<Action> {
        guard phase == .playerTurn else { return [] }
        let state = hands[activeHandIndex]
        let hand = state.hand
        var actions: Set<Action> = [.stand]
        if state.isSplitAces && !rules.hitSplitAces { return actions }
        actions.insert(.hit)
        if hand.canDouble(rules: rules) && (!state.isFromSplit || rules.doubleAfterSplit) {
            actions.insert(.double)
        }
        if hands.count == 1 && hand.canSurrender(rules: rules) {
            actions.insert(.surrender)
        }
        return actions
    }

    public var currentSpot: DecisionSpot? {
        guard phase == .playerTurn else { return nil }
        return DecisionSpot(hand: hands[activeHandIndex].hand,
                            dealerUpcard: dealerUpcard.rank,
                            legalActions: legalActions)
    }

    // MARK: - Actions

    public mutating func apply(_ action: Action, shoe: inout Shoe) throws {
        guard phase == .playerTurn else { throw RoundError.notPlayerTurn }
        guard legalActions.contains(action) else { throw RoundError.illegalAction(action) }

        if peekPending {
            peekPending = false
            if action != .surrender {
                // Dealer peeks after the early-surrender window: original bet lost.
                hands[0].isFinished = true
                hands[0].outcome = .loss
                hands[0].net = -1
                phase = .settled
                return
            }
        }

        let i = activeHandIndex
        switch action {
        case .hit:
            try draw(into: i, shoe: &shoe)
            if hands[i].hand.total >= 21 { hands[i].isFinished = true }
        case .stand:
            hands[i].isFinished = true
        case .double:
            hands[i].isDoubled = true
            try draw(into: i, shoe: &shoe)
            hands[i].isFinished = true
        case .surrender:
            hands[i].isSurrendered = true
            hands[i].isFinished = true
        case .split:
            try split(i, shoe: &shoe)
        }
        try advance(shoe: &shoe)
    }

    // MARK: - Internals

    private mutating func resolveNaturals() {
        let player = hands[0].hand
        if player.isBlackjack {
            hands[0].isFinished = true
            if dealer.isBlackjack {
                hands[0].outcome = .push
                hands[0].net = 0
            } else {
                hands[0].outcome = .blackjack
                hands[0].net = rules.blackjackPayout.multiplier
            }
            phase = .settled
            return
        }
        guard dealer.isBlackjack, rules.peekRule == .americanPeek else { return }
        if rules.surrenderRule == .early {
            peekPending = true
        } else {
            hands[0].isFinished = true
            hands[0].outcome = .loss
            hands[0].net = -1
            phase = .settled
        }
    }

    private mutating func draw(into i: Int, shoe: inout Shoe) throws {
        guard let card = shoe.deal() else { throw RoundError.shoeExhausted }
        drawnCards.append(card)
        var hand = hands[i].hand
        hand.addCard(card)
        hands[i].hand = hand
    }

    /// Implemented in Task 7.
    private mutating func split(_ i: Int, shoe: inout Shoe) throws {
        throw RoundError.illegalAction(.split)
    }

    private mutating func advance(shoe: inout Shoe) throws {
        if let next = hands.indices.first(where: { !hands[$0].isFinished }) {
            activeHandIndex = next
            return
        }
        try finishRound(shoe: &shoe)
    }

    private mutating func finishRound(shoe: inout Shoe) throws {
        if dealer.isBlackjack {
            // Reachable only under European no-peek or after an early surrender.
            for i in hands.indices { settleAgainstDealerBlackjack(i) }
            phase = .settled
            return
        }
        let hasLiveHand = hands.contains { !$0.isSurrendered && !$0.hand.isBust }
        if hasLiveHand {
            while shouldDealerHit {
                guard let card = shoe.deal() else { throw RoundError.shoeExhausted }
                drawnCards.append(card)
                dealer.addCard(card)
            }
        }
        for i in hands.indices { settle(i) }
        phase = .settled
    }

    private var shouldDealerHit: Bool {
        let total = dealer.total
        if total < 17 { return true }
        return total == 17 && dealer.isSoft && rules.dealerSoft17 == .hits
    }

    private mutating func settleAgainstDealerBlackjack(_ i: Int) {
        let state = hands[i]
        if state.isSurrendered {
            let early = rules.surrenderRule == .early
            hands[i].outcome = early ? .surrendered : .loss
            hands[i].net = early ? -0.5 : -1
        } else {
            hands[i].outcome = state.hand.isBust ? .bust : .loss
            hands[i].net = -state.betUnits
        }
    }

    private mutating func settle(_ i: Int) {
        let state = hands[i]
        let bet = state.betUnits
        if state.isSurrendered {
            hands[i].outcome = .surrendered
            hands[i].net = -0.5
        } else if state.hand.isBust {
            hands[i].outcome = .bust
            hands[i].net = -bet
        } else if dealer.isBust || state.hand.total > dealer.total {
            hands[i].outcome = .win
            hands[i].net = bet
        } else if state.hand.total < dealer.total {
            hands[i].outcome = .loss
            hands[i].net = -bet
        } else {
            hands[i].outcome = .push
            hands[i].net = 0
        }
    }
}
```

- [ ] **Step 5: Run all engine tests**

Run: `cd BJSCore && swift test 2>&1 | tail -3`
Expected: passed, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add BJSCore
git commit -m "feat(core): RoundEngine with naturals, peek/ENHC, double, surrender, dealer play

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: RoundEngine — splits

**Files:**
- Modify: `BJSCore/Sources/BJSCore/Round/RoundEngine.swift` (`legalActions`, `split(_:shoe:)`, plus a new `autoFinishIfNeeded`)
- Test: `BJSCore/Tests/BJSCoreTests/RoundTests/RoundEngineSplitTests.swift`

**Interfaces:**
- Consumes: `RoundEngine`, `stackedShoe(_:)` (a test helper defined in `RoundEngineTests.swift`, visible to the whole test target)
- Produces: `.split` in `legalActions` when `hand.canSplit(rules:currentSplitCount: hands.count - 1)`.

**Split behaviour contract:**
- Splitting replaces the active hand with two hands. Each gets one new card: the first new card goes to the left hand, the second to the right hand. The right hand is inserted directly after.
- Both new hands have `isFromSplit = true`. When splitting aces, both also have `isSplitAces = true`.
- A split-ace hand with `hitSplitAces == false` may only stand, or resplit if it is A-A and `canSplit` allows. A split-ace hand that cannot resplit is finished automatically.
- Any hand reaching 21 or more is finished automatically. 21 after a split is **not** a blackjack: it pays 1:1.
- Surrender is never legal after a split. Double after split requires `doubleAfterSplit`.

- [ ] **Step 1: Write the failing tests**

Create `BJSCore/Tests/BJSCoreTests/RoundTests/RoundEngineSplitTests.swift`:

```swift
import Testing
@testable import BJSCore

@Suite("RoundEngine — splits")
struct RoundEngineSplitTests {

    @Test("Split 8s vs 6, double first hand (DAS), dealer busts: +3")
    func splitEightsDoubleAfterSplit() throws {
        // P1 8, UP 6, P2 8, HOLE 10 | split draws 3 then 10 | double draws 9 | dealer draws 10
        var shoe = stackedShoe([.eight, .six, .eight, .ten, .three, .ten, .nine, .ten])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        #expect(round.legalActions.contains(.split))
        try round.apply(.split, shoe: &shoe)
        #expect(round.hands.count == 2)
        #expect(round.hands[0].hand.total == 11)
        #expect(round.hands[1].hand.total == 18)
        #expect(round.legalActions.contains(.double))
        #expect(!round.legalActions.contains(.surrender))
        try round.apply(.double, shoe: &shoe)
        #expect(round.activeHandIndex == 1)
        try round.apply(.stand, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.dealer.isBust)
        #expect(round.hands.map(\.net) == [2, 1])
        #expect(round.totalNet == 3)
    }

    @Test("No double after split when DAS is off")
    func noDAS() throws {
        var rules = BlackjackRules()
        rules.doubleAfterSplit = false
        var shoe = stackedShoe([.eight, .six, .eight, .ten, .three, .ten])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(!round.legalActions.contains(.double))
    }

    @Test("Split aces get one card each and 21 pays 1:1")
    func splitAcesOneCard() throws {
        var shoe = stackedShoe([.ace, .seven, .ace, .ten, .nine, .king])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].hand.total == 20)
        #expect(round.hands[1].hand.total == 21)
        #expect(round.hands[1].outcome == .win)
        #expect(round.hands[1].net == 1)
        #expect(round.hands.allSatisfy(\.isSplitAces))
    }

    @Test("Resplit aces allowed: A-A split hand may split again")
    func resplitAces() throws {
        var rules = BlackjackRules()
        rules.resplitAces = true
        // split -> A,A and A,5 ; resplit first -> A,6 and A,4
        var shoe = stackedShoe([.ace, .seven, .ace, .ten, .ace, .five, .six, .four])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.phase == .playerTurn)
        #expect(round.legalActions == [.stand, .split])
        try round.apply(.split, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands.map { $0.hand.total } == [17, 15, 16])
        #expect(round.hands.map(\.outcome) == [.push, .loss, .loss])
    }

    @Test("Resplit aces not allowed: A-A split hand is finished automatically")
    func noResplitAces() throws {
        var shoe = stackedShoe([.ace, .seven, .ace, .ten, .ace, .five])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands.count == 2)
    }

    @Test("Hit split aces allowed: split ace hand can hit")
    func hitSplitAces() throws {
        var rules = BlackjackRules()
        rules.hitSplitAces = true
        var shoe = stackedShoe([.ace, .seven, .ace, .ten, .two, .three, .four, .five])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.legalActions.contains(.hit))
    }

    @Test("maxSplitHands = 2 blocks a second split")
    func maxSplitHands() throws {
        var rules = BlackjackRules()
        rules.maxSplitHands = 2
        var shoe = stackedShoe([.eight, .six, .eight, .ten, .eight, .two])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.hands[0].hand.isPair)
        #expect(!round.legalActions.contains(.split))
    }

    @Test("maxSplitHands = 4 allows resplitting to four hands")
    func resplitToFour() throws {
        var shoe = stackedShoe([.eight, .six, .eight, .ten,
                                .eight, .two,   // split 1 -> [8,8] [8,2]
                                .eight, .three, // split 2 -> [8,8] [8,3] [8,2]
                                .ten, .nine])   // split 3 -> [8,10] [8,9] [8,3] [8,2]
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.hands.count == 4)
        #expect(!round.legalActions.contains(.split))
    }

    @Test("Surrender is not legal after a split")
    func noSurrenderAfterSplit() throws {
        var rules = BlackjackRules()
        rules.surrenderRule = .late
        var shoe = stackedShoe([.eight, .ten, .eight, .seven, .eight, .two])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.legalActions.contains(.surrender))
        try round.apply(.split, shoe: &shoe)
        #expect(!round.legalActions.contains(.surrender))
    }
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `cd BJSCore && swift test --filter "splits" 2>&1 | tail -5`
Expected: FAIL. `legalActions` never contains `.split`, and `split` throws.

- [ ] **Step 3: Allow split in `legalActions`**

In `RoundEngine.legalActions`, replace:

```swift
        var actions: Set<Action> = [.stand]
        if state.isSplitAces && !rules.hitSplitAces { return actions }
```

with:

```swift
        var actions: Set<Action> = [.stand]
        if hand.canSplit(rules: rules, currentSplitCount: hands.count - 1) {
            actions.insert(.split)
        }
        if state.isSplitAces && !rules.hitSplitAces { return actions }
```

- [ ] **Step 4: Implement `split` and auto-finish**

In `RoundEngine.swift` replace the placeholder `split(_:shoe:)` with:

```swift
    private mutating func split(_ i: Int, shoe: inout Shoe) throws {
        let original = hands[i].hand.cards
        guard let first = shoe.deal(), let second = shoe.deal() else {
            throw RoundError.shoeExhausted
        }
        drawnCards.append(first)
        drawnCards.append(second)
        let aces = original[0].rank == .ace

        var left = PlayerHandState(hand: BlackjackHand(cards: [original[0], first]))
        left.isFromSplit = true
        left.isSplitAces = aces
        var right = PlayerHandState(hand: BlackjackHand(cards: [original[1], second]))
        right.isFromSplit = true
        right.isSplitAces = aces

        hands[i] = left
        hands.insert(right, at: i + 1)
        autoFinishIfNeeded(i)
        autoFinishIfNeeded(i + 1)
    }

    /// Finishes a hand that has no meaningful decision left:
    /// 21 or more, or a split-ace hand that may neither hit nor resplit.
    private mutating func autoFinishIfNeeded(_ i: Int) {
        let state = hands[i]
        if state.hand.total >= 21 {
            hands[i].isFinished = true
            return
        }
        if state.isSplitAces && !rules.hitSplitAces
            && !state.hand.canSplit(rules: rules, currentSplitCount: hands.count - 1) {
            hands[i].isFinished = true
        }
    }
```

- [ ] **Step 5: Run all engine tests**

Run: `cd BJSCore && swift test 2>&1 | tail -3`
Expected: passed, 0 failures. That includes all Task 6 tests.

- [ ] **Step 6: Commit**

```bash
git add BJSCore
git commit -m "feat(core): RoundEngine splits (DAS, split aces, resplit, max hands)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: RoundEngine property tests (100k seeded rounds + count invariant)

**Files:**
- Test: `BJSCore/Tests/BJSCoreTests/RoundTests/RoundEnginePropertyTests.swift`

**Interfaces:**
- Consumes: `RoundEngine`, `SeededRandomNumberGenerator`, `HiLoCounter`, `StrategyEngine`

This task adds tests only. If a test fails, it has found a real engine bug. Fix `RoundEngine.swift` (don't weaken the test) and describe the bug in the commit message.

- [ ] **Step 1: Write the property tests**

```swift
import Testing
@testable import BJSCore

@Suite("RoundEngine — properties")
struct RoundEnginePropertyTests {

    static let ruleSets: [BlackjackRules] = {
        var s17 = BlackjackRules()
        var h17ls = BlackjackRules(); h17ls.dealerSoft17 = .hits; h17ls.surrenderRule = .late
        var enhc = BlackjackRules(); enhc.peekRule = .europeanNoPeek; enhc.surrenderRule = .early
        var single = BlackjackRules(); single.deckCount = .one; single.blackjackPayout = .sixToFive
        single.doubleAfterSplit = false; single.maxSplitHands = 2
        var liberal = BlackjackRules(); liberal.resplitAces = true; liberal.hitSplitAces = true
        liberal.surrenderRule = .early; liberal.deckCount = .two
        return [s17, h17ls, enhc, single, liberal]
    }()

    static let allowedNets: Set<Double> = [-2, -1, -0.5, 0, 1, 1.2, 1.5, 2]

    @Test("20k random rounds per rule set keep every invariant",
          arguments: Array(RoundEnginePropertyTests.ruleSets.enumerated()))
    func randomRounds(pair: (offset: Int, element: BlackjackRules)) throws {
        let rules = pair.element
        var rng = SeededRandomNumberGenerator(seed: UInt64(1000 + pair.offset))
        let table = StrategyEngine().strategy(for: rules)
        var shoe = Shoe(deckCount: rules.deckCount.rawValue)
        shoe.shuffle(using: &rng)

        for roundNumber in 0..<20_000 {
            if shoe.cardsRemaining < 60 {
                shoe = Shoe(deckCount: max(rules.deckCount.rawValue, 2))
                shoe.shuffle(using: &rng)
            }
            let before = shoe.dealtCount
            var round = try RoundEngine(rules: rules, shoe: &shoe)
            var steps = 0
            while round.phase == .playerTurn {
                let spot = try #require(round.currentSpot)
                #expect(!spot.legalActions.isEmpty)
                let best = table.action(for: spot)
                #expect(spot.legalActions.contains(best))
                let action: Action = roundNumber % 3 == 0
                    ? best
                    : spot.legalActions.sorted { $0.rawValue < $1.rawValue }.randomElement(using: &rng)!
                try round.apply(action, shoe: &shoe)
                steps += 1
                #expect(steps < 200)
            }
            #expect(round.hands.count <= rules.maxSplitHands)
            #expect(round.drawnCards.count == shoe.dealtCount - before)
            for hand in round.hands {
                #expect(hand.outcome != nil)
                #expect(hand.isFinished)
                #expect(Self.allowedNets.contains(hand.net))
            }
        }
    }

    @Test("Hi-Lo running count over a fully played shoe returns to zero")
    func countBalancesOverShoe() throws {
        var rng = SeededRandomNumberGenerator(seed: 7)
        let rules = BlackjackRules()
        let table = StrategyEngine().strategy(for: rules)
        var shoe = Shoe(deckCount: 6)
        shoe.shuffle(using: &rng)
        var counter = HiLoCounter()

        while shoe.cardsRemaining >= 40 {
            var round = try RoundEngine(rules: rules, shoe: &shoe)
            while round.phase == .playerTurn {
                try round.apply(table.action(for: try #require(round.currentSpot)), shoe: &shoe)
            }
            counter.process(round.drawnCards)
        }
        while let card = shoe.deal() { counter.process(card) }
        #expect(counter.runningCount == 0)
    }
}
```

Save it as `BJSCore/Tests/BJSCoreTests/RoundTests/RoundEnginePropertyTests.swift`.

- [ ] **Step 2: Run the property suite**

Run: `cd BJSCore && swift test --filter "properties" 2>&1 | tail -5`
Expected: PASS. It may take a few seconds. If an invariant fails, find the cause in `RoundEngine.swift`, fix it, and re-run the whole suite.

- [ ] **Step 3: Run all engine tests**

Run: `cd BJSCore && swift test 2>&1 | tail -3`
Expected: passed, 0 failures.

- [ ] **Step 4: Commit**

```bash
git add BJSCore
git commit -m "test(core): RoundEngine property tests over 100k seeded rounds

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: TrainingCell, HandFilter and HandGenerator

**Files:**
- Create: `BJSCore/Sources/BJSCore/Training/TrainingCell.swift`
- Create: `BJSCore/Sources/BJSCore/Training/HandGenerator.swift`
- Test: `BJSCore/Tests/BJSCoreTests/TrainingTests/HandGeneratorTests.swift`

**Interfaces:**
- Consumes: `HandType` (Task 1), `DecisionSpot` / `RoundEngine` (Task 6), `Shoe.standardCards` / `Shoe(orderedCards:)` (Task 4)
- Produces:
  - `public struct TrainingCell: Hashable, Sendable, Codable`, with:
    - `handType: HandType`;
    - `playerValue: Int`: hard/soft total, or the pair rank value 2...11 where 11 = aces;
    - `dealerUpcard: Int`: 2...11, where 10 = any ten-value card and 11 = ace;
    - `init(handType:playerValue:dealerUpcard:)`, `init(spot: DecisionSpot)`, `static let all: [TrainingCell]` (340 cells), `static func cells(matching: HandFilter) -> [TrainingCell]`.
  - `public enum HandFilter: String, CaseIterable, Sendable, Codable { case all, hard, soft, pairs }`
  - `public enum HandGenerator` with:
    - `static let minimumWeight: Double = 0.05`;
    - `sampleCell(filter:weights:using:) -> TrainingCell`;
    - `cards(for:using:) -> (player: [Card], upcard: Card)`;
    - `stackedShoe(for:deckCount:using:) -> Shoe`.

**Cells:** hard 5...20, soft 13...20, pairs 2...11, each against upcards 2...11. That is 16×10 + 8×10 + 10×10 = 340.

- [ ] **Step 1: Write the failing tests**

Create `BJSCore/Tests/BJSCoreTests/TrainingTests/HandGeneratorTests.swift`:

```swift
import Testing
@testable import BJSCore

@Suite("HandGenerator")
struct HandGeneratorTests {

    @Test("There are 340 distinct training cells")
    func cellCount() {
        #expect(TrainingCell.all.count == 340)
        #expect(Set(TrainingCell.all).count == 340)
        #expect(TrainingCell.cells(matching: .hard).count == 160)
        #expect(TrainingCell.cells(matching: .soft).count == 80)
        #expect(TrainingCell.cells(matching: .pairs).count == 100)
        #expect(TrainingCell.cells(matching: .all).count == 340)
    }

    @Test("Every cell deals a round whose first spot classifies back to that cell")
    func roundTripsEveryCell() throws {
        var rng = SeededRandomNumberGenerator(seed: 99)
        let rules = BlackjackRules()
        for cell in TrainingCell.all {
            for _ in 0..<5 {
                var shoe = HandGenerator.stackedShoe(for: cell, deckCount: 6, using: &rng)
                let round = try RoundEngine(rules: rules, shoe: &shoe)
                #expect(round.phase == .playerTurn, "cell \(cell) did not start in player turn")
                let spot = try #require(round.currentSpot)
                #expect(TrainingCell(spot: spot) == cell)
                #expect(!round.dealer.isBlackjack)
            }
        }
    }

    @Test("Single-deck stacked shoes never duplicate a card")
    func singleDeckNoDuplicates() {
        var rng = SeededRandomNumberGenerator(seed: 3)
        for cell in TrainingCell.all {
            var shoe = HandGenerator.stackedShoe(for: cell, deckCount: 1, using: &rng)
            var seen = Set<Card>()
            while let card = shoe.deal() { seen.insert(card) }
            #expect(seen.count == 52)
        }
    }

    @Test("Filter restricts sampled cells", arguments: [HandFilter.hard, .soft, .pairs])
    func filterRespected(filter: HandFilter) {
        var rng = SeededRandomNumberGenerator(seed: 11)
        let allowed = Set(TrainingCell.cells(matching: filter))
        for _ in 0..<2_000 {
            #expect(allowed.contains(HandGenerator.sampleCell(filter: filter, weights: nil, using: &rng)))
        }
    }

    @Test("Weighted sampling converges to the weight share")
    func weightedConvergence() {
        var rng = SeededRandomNumberGenerator(seed: 21)
        let heavy = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)
        var weights: [TrainingCell: Double] = [:]
        for cell in TrainingCell.all { weights[cell] = 0.05 }
        weights[heavy] = 10
        let expectedShare = 10 / (10 + 0.05 * 339)
        var hits = 0
        var seen = Set<TrainingCell>()
        let draws = 40_000
        for _ in 0..<draws {
            let cell = HandGenerator.sampleCell(filter: .all, weights: weights, using: &rng)
            seen.insert(cell)
            if cell == heavy { hits += 1 }
        }
        #expect(abs(Double(hits) / Double(draws) - expectedShare) < 0.02)
        #expect(seen.count == 340)
    }

    @Test("Zero or missing weights are clamped to the minimum, never excluded")
    func zeroWeightsClamped() {
        var rng = SeededRandomNumberGenerator(seed: 5)
        let only = TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 9)
        let weights: [TrainingCell: Double] = [only: 0]
        var seen = Set<TrainingCell>()
        for _ in 0..<5_000 {
            seen.insert(HandGenerator.sampleCell(filter: .soft, weights: weights, using: &rng))
        }
        #expect(seen.count == 80)
    }

    @Test("Hard cells never produce a pair or an ace")
    func hardCellsAreHard() {
        var rng = SeededRandomNumberGenerator(seed: 8)
        for cell in TrainingCell.cells(matching: .hard) {
            let (player, _) = HandGenerator.cards(for: cell, using: &rng)
            let hand = BlackjackHand(cards: player)
            #expect(!hand.isPair)
            #expect(!hand.isSoft)
            #expect(hand.total == cell.playerValue)
        }
    }
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `cd BJSCore && swift test --filter HandGenerator 2>&1 | tail -5`
Expected: FAIL. `TrainingCell` is not defined.

- [ ] **Step 3: Implement `TrainingCell` and `HandFilter`**

Create `BJSCore/Sources/BJSCore/Training/TrainingCell.swift`:

```swift
/// Which hand categories a strategy session deals.
public enum HandFilter: String, CaseIterable, Sendable, Codable {
    case all, hard, soft, pairs

    public func includes(_ type: HandType) -> Bool {
        switch self {
        case .all: return true
        case .hard: return type == .hard
        case .soft: return type == .soft
        case .pairs: return type == .pair
        }
    }
}

/// One strategy decision "cell": hand category × player value × dealer upcard.
///
/// - `playerValue`: the hard or soft total; for pairs, the rank value 2...11 (11 = aces).
/// - `dealerUpcard`: 2...11, where 10 covers T/J/Q/K and 11 = ace.
public struct TrainingCell: Hashable, Sendable, Codable {
    public let handType: HandType
    public let playerValue: Int
    public let dealerUpcard: Int

    public init(handType: HandType, playerValue: Int, dealerUpcard: Int) {
        self.handType = handType
        self.playerValue = playerValue
        self.dealerUpcard = dealerUpcard
    }

    /// Classifies a decision. A two-card pair counts as `.pair` only while splitting is legal.
    public init(spot: DecisionSpot) {
        let hand = spot.hand
        let upcard = spot.dealerUpcard == .ace ? 11 : spot.dealerUpcard.blackjackValue
        if hand.isPair && spot.legalActions.contains(.split) {
            let rank = hand.cards[0].rank
            self.init(handType: .pair, playerValue: rank == .ace ? 11 : rank.blackjackValue,
                      dealerUpcard: upcard)
        } else if hand.isSoft {
            self.init(handType: .soft, playerValue: hand.total, dealerUpcard: upcard)
        } else {
            self.init(handType: .hard, playerValue: hand.total, dealerUpcard: upcard)
        }
    }

    /// Every trainable two-card starting cell: hard 5–20, soft 13–20, pairs 2–A, vs upcards 2–A.
    public static let all: [TrainingCell] = {
        let upcards = Array(2...11)
        var cells: [TrainingCell] = []
        for value in 5...20 {
            for up in upcards { cells.append(TrainingCell(handType: .hard, playerValue: value, dealerUpcard: up)) }
        }
        for value in 13...20 {
            for up in upcards { cells.append(TrainingCell(handType: .soft, playerValue: value, dealerUpcard: up)) }
        }
        for value in 2...11 {
            for up in upcards { cells.append(TrainingCell(handType: .pair, playerValue: value, dealerUpcard: up)) }
        }
        return cells
    }()

    public static func cells(matching filter: HandFilter) -> [TrainingCell] {
        all.filter { filter.includes($0.handType) }
    }
}
```

- [ ] **Step 4: Implement `HandGenerator`**

Create `BJSCore/Sources/BJSCore/Training/HandGenerator.swift`:

```swift
/// Builds training hands: picks a cell (uniformly or by weight) and stacks a shoe
/// so `RoundEngine` deals exactly that starting hand.
public enum HandGenerator {

    /// Floor applied to every cell weight so no cell is ever unreachable.
    public static let minimumWeight: Double = 0.05

    private static let tenRanks: [Rank] = [.ten, .jack, .queen, .king]

    /// Picks a cell matching `filter`. With `weights == nil` the pick is uniform;
    /// otherwise proportional to `max(weights[cell] ?? minimumWeight, minimumWeight)`.
    public static func sampleCell<G: RandomNumberGenerator>(
        filter: HandFilter, weights: [TrainingCell: Double]?, using rng: inout G
    ) -> TrainingCell {
        let candidates = TrainingCell.cells(matching: filter)
        guard let weights else { return candidates.randomElement(using: &rng)! }
        let values = candidates.map { max(weights[$0] ?? minimumWeight, minimumWeight) }
        let total = values.reduce(0, +)
        var target = Double.random(in: 0..<total, using: &rng)
        for (cell, weight) in zip(candidates, values) {
            if target < weight { return cell }
            target -= weight
        }
        return candidates[candidates.count - 1]
    }

    /// Concrete cards for a cell. The three cards always have distinct suits,
    /// so they are distinct cards even in a single deck.
    public static func cards<G: RandomNumberGenerator>(
        for cell: TrainingCell, using rng: inout G
    ) -> (player: [Card], upcard: Card) {
        let suits = Suit.allCases.shuffled(using: &rng)
        let upRank = rank(forValue: cell.dealerUpcard, using: &rng)
        let ranks: (Rank, Rank)
        switch cell.handType {
        case .pair:
            let r = rank(forValue: cell.playerValue, using: &rng)
            ranks = (r, r)
        case .soft:
            ranks = (.ace, rank(forValue: cell.playerValue - 11, using: &rng))
        case .hard:
            ranks = hardRanks(total: cell.playerValue, using: &rng)
        }
        return ([Card(rank: ranks.0, suit: suits[0]), Card(rank: ranks.1, suit: suits[1])],
                Card(rank: upRank, suit: suits[2]))
    }

    /// A shoe that deals the cell's hand in `RoundEngine` order (P1, upcard, P2, hole),
    /// followed by the rest of `deckCount` shuffled decks. The hole card never gives
    /// the dealer a natural, so every training hand starts with a decision.
    public static func stackedShoe<G: RandomNumberGenerator>(
        for cell: TrainingCell, deckCount: Int, using rng: inout G
    ) -> Shoe {
        let (player, up) = cards(for: cell, using: &rng)
        var rest = Shoe.standardCards(deckCount: deckCount)
        for card in player + [up] {
            if let index = rest.firstIndex(of: card) { rest.remove(at: index) }
        }
        rest.shuffle(using: &rng)
        let holeIndex = rest.firstIndex { !completesBlackjack(upcard: up.rank, hole: $0.rank) } ?? 0
        let hole = rest.remove(at: holeIndex)
        return Shoe(orderedCards: [player[0], up, player[1], hole] + rest)
    }

    // MARK: - Helpers

    static func rank<G: RandomNumberGenerator>(forValue value: Int, using rng: inout G) -> Rank {
        switch value {
        case 11: return .ace
        case 10: return tenRanks.randomElement(using: &rng)!
        default: return Rank(rawValue: value)!
        }
    }

    /// Two non-ace ranks summing to `total` that are not a pair (by rank).
    /// Hard 20 uses two different ten-value ranks (e.g. K + Q).
    static func hardRanks<G: RandomNumberGenerator>(total: Int, using rng: inout G) -> (Rank, Rank) {
        var options: [(Int, Int)] = []
        for a in 2...10 {
            let b = total - a
            if b >= a && b <= 10 && (a != b || a == 10) { options.append((a, b)) }
        }
        let (a, b) = options.randomElement(using: &rng)!
        if a == 10 && b == 10 {
            let tens = tenRanks.shuffled(using: &rng)
            return (tens[0], tens[1])
        }
        return (rank(forValue: a, using: &rng), rank(forValue: b, using: &rng))
    }

    static func completesBlackjack(upcard: Rank, hole: Rank) -> Bool {
        (upcard == .ace && hole.blackjackValue == 10) || (upcard.blackjackValue == 10 && hole == .ace)
    }
}
```

- [ ] **Step 5: Run all engine tests**

Run: `cd BJSCore && swift test 2>&1 | tail -3`
Expected: passed, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add BJSCore
git commit -m "feat(core): TrainingCell, HandFilter and weighted HandGenerator

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: DecisionSample and WeakSpotWeights

**Files:**
- Create: `BJSCore/Sources/BJSCore/Training/WeakSpotWeights.swift`
- Test: `BJSCore/Tests/BJSCoreTests/TrainingTests/WeakSpotWeightsTests.swift`

**Interfaces:**
- Consumes: `TrainingCell`, `HandGenerator.minimumWeight` (Task 9)
- Produces:
  - `public struct DecisionSample: Sendable, Equatable { date: Date; cell: TrainingCell; isCorrect: Bool; responseMs: Int? }` with a public memberwise init
  - `public enum WeakSpotWeights` with:
    - `historyWindow = 500` and `minimumHistory = 50`;
    - `static func compute(from: [DecisionSample]) -> [TrainingCell: Double]?`, which returns nil when there is too little history (the caller then samples uniformly).

**Formula (spec §6):**
- Take the newest 500 samples by date. p = the overall error rate in that window.
- For each cell in `TrainingCell.all`: weight = max((errors + 2p) / (attempts + 2), 0.05).

- [ ] **Step 1: Write the failing tests**

Create `BJSCore/Tests/BJSCoreTests/TrainingTests/WeakSpotWeightsTests.swift`:

```swift
import Foundation
import Testing
@testable import BJSCore

@Suite("WeakSpotWeights")
struct WeakSpotWeightsTests {

    let weak = TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 9)
    let strong = TrainingCell(handType: .hard, playerValue: 20, dealerUpcard: 6)
    let unseen = TrainingCell(handType: .pair, playerValue: 9, dealerUpcard: 7)

    func sample(_ cell: TrainingCell, correct: Bool, at seconds: Double) -> DecisionSample {
        DecisionSample(date: Date(timeIntervalSince1970: seconds), cell: cell,
                       isCorrect: correct, responseMs: nil)
    }

    @Test("Fewer than 50 decisions returns nil (uniform)")
    func tooLittleHistory() {
        let samples = (0..<49).map { sample(strong, correct: true, at: Double($0)) }
        #expect(WeakSpotWeights.compute(from: samples) == nil)
    }

    @Test("Weak cells outweigh unseen cells, which outweigh mastered cells")
    func ordering() throws {
        var samples = (0..<10).map { sample(weak, correct: false, at: Double($0)) }
        samples += (0..<90).map { sample(strong, correct: true, at: Double(100 + $0)) }
        let weights = try #require(WeakSpotWeights.compute(from: samples))
        // p = 10/100 = 0.1
        #expect(abs(weights[weak]! - (10 + 0.2) / 12) < 1e-9)
        #expect(abs(weights[unseen]! - 0.1) < 1e-9)
        #expect(weights[strong]! == HandGenerator.minimumWeight)
        #expect(weights[weak]! > weights[unseen]!)
        #expect(weights[unseen]! > weights[strong]!)
        #expect(weights.count == TrainingCell.all.count)
    }

    @Test("Only the newest 500 decisions count")
    func windowIgnoresOldHistory() throws {
        let old = TrainingCell(handType: .hard, playerValue: 12, dealerUpcard: 2)
        var samples = (0..<100).map { sample(old, correct: false, at: Double($0)) }
        samples += (0..<500).map { sample(strong, correct: true, at: Double(1_000 + $0)) }
        let weights = try #require(WeakSpotWeights.compute(from: samples.shuffled()))
        #expect(weights[old]! == HandGenerator.minimumWeight)
    }

    @Test("No weight falls below the minimum")
    func floor() throws {
        let samples = (0..<200).map { sample(strong, correct: true, at: Double($0)) }
        let weights = try #require(WeakSpotWeights.compute(from: samples))
        #expect(weights.values.allSatisfy { $0 >= HandGenerator.minimumWeight })
    }
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `cd BJSCore && swift test --filter WeakSpotWeights 2>&1 | tail -5`
Expected: FAIL. `DecisionSample` is not defined.

- [ ] **Step 3: Implement**

Create `BJSCore/Sources/BJSCore/Training/WeakSpotWeights.swift`:

```swift
import Foundation

/// One graded strategy decision, as read back from persistence.
public struct DecisionSample: Sendable, Equatable {
    public let date: Date
    public let cell: TrainingCell
    public let isCorrect: Bool
    public let responseMs: Int?

    public init(date: Date, cell: TrainingCell, isCorrect: Bool, responseMs: Int?) {
        self.date = date
        self.cell = cell
        self.isCorrect = isCorrect
        self.responseMs = responseMs
    }
}

/// Per-cell sampling weights for Weak-spots mode.
///
/// Error rate per cell over the newest `historyWindow` decisions, smoothed toward the
/// user's overall error rate p: (errors + 2p) / (attempts + 2), floored at
/// `HandGenerator.minimumWeight`. Unseen cells therefore sit at about p, below real weak spots.
public enum WeakSpotWeights {
    public static let historyWindow = 500
    public static let minimumHistory = 50

    public static func compute(from samples: [DecisionSample]) -> [TrainingCell: Double]? {
        guard samples.count >= minimumHistory else { return nil }
        let recent = samples.sorted { $0.date < $1.date }.suffix(historyWindow)

        var attempts: [TrainingCell: Int] = [:]
        var errors: [TrainingCell: Int] = [:]
        var totalErrors = 0
        for sample in recent {
            attempts[sample.cell, default: 0] += 1
            if !sample.isCorrect {
                errors[sample.cell, default: 0] += 1
                totalErrors += 1
            }
        }
        let prior = Double(totalErrors) / Double(recent.count)

        var weights: [TrainingCell: Double] = [:]
        for cell in TrainingCell.all {
            let a = Double(attempts[cell] ?? 0)
            let e = Double(errors[cell] ?? 0)
            let rate = (e + 2 * prior) / (a + 2)
            weights[cell] = max(rate, HandGenerator.minimumWeight)
        }
        return weights
    }
}
```

- [ ] **Step 4: Run all engine tests**

Run: `cd BJSCore && swift test 2>&1 | tail -3`
Expected: passed, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add BJSCore
git commit -m "feat(core): DecisionSample and WeakSpotWeights

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Count drills and true-count grading

**Files:**
- Create: `BJSCore/Sources/BJSCore/Counting/CountDrills.swift`
- Test: `BJSCore/Tests/BJSCoreTests/CountingTests/CountDrillTests.swift`

**Interfaces:**
- Consumes: `Shoe.standardCards`, `SeededRandomNumberGenerator`, `Rank.hiLoValue`
- Produces:
  - `public enum TrueCountConvention: String, CaseIterable, Sendable, Codable { case exact, floor, truncate }`
  - `public enum DrillLength: Sendable, Equatable, Hashable { case cards(Int), fullShoe }`
  - `public struct RunningCountDrill: Sendable, Equatable`, with:
    - `groups: [[Card]]`;
    - `checkpoints: [Int]`: ascending group indices after which the user is asked; always includes the last index;
    - `func expectedCount(afterGroup: Int) -> Int`;
    - `var cardCount: Int`.
  - `public struct TrueCountQuestion: Sendable, Equatable`, with:
    - `runningCount: Int` and `decksRemaining: Double` (a multiple of 0.5, at least 0.5);
    - `exactTrueCount: Double`;
    - `func isCorrect(_ answer: Double, convention: TrueCountConvention) -> Bool`.
  - `public enum CountDrillGenerator`, with:
    - `randomCheckpointProbability = 0.125`;
    - `runningCountDrill(length:groupSize:deckCount:randomCheckpoints:using:)`;
    - `trueCountQuestion(deckCount:using:)`.

- [ ] **Step 1: Write the failing tests**

Create `BJSCore/Tests/BJSCoreTests/CountingTests/CountDrillTests.swift`:

```swift
import Testing
@testable import BJSCore

@Suite("Count drills")
struct CountDrillTests {

    @Test("Card lengths and group sizes", arguments: [(10, 1), (26, 2), (52, 3), (10, 3)])
    func lengthsAndGroups(length: Int, groupSize: Int) {
        var rng = SeededRandomNumberGenerator(seed: 1)
        let drill = CountDrillGenerator.runningCountDrill(
            length: .cards(length), groupSize: groupSize, deckCount: 6,
            randomCheckpoints: false, using: &rng)
        #expect(drill.cardCount == length)
        #expect(drill.groups.dropLast().allSatisfy { $0.count == groupSize })
        #expect(drill.groups.last!.count <= groupSize)
        #expect(drill.checkpoints == [drill.groups.count - 1])
    }

    @Test("Full shoe uses every card of the rules' deck count and ends at count zero")
    func fullShoe() {
        var rng = SeededRandomNumberGenerator(seed: 2)
        let drill = CountDrillGenerator.runningCountDrill(
            length: .fullShoe, groupSize: 2, deckCount: 2, randomCheckpoints: false, using: &rng)
        #expect(drill.cardCount == 104)
        #expect(drill.expectedCount(afterGroup: drill.groups.count - 1) == 0)
    }

    @Test("Expected count matches a HiLoCounter at every group")
    func expectedCountMatchesCounter() {
        var rng = SeededRandomNumberGenerator(seed: 3)
        let drill = CountDrillGenerator.runningCountDrill(
            length: .cards(52), groupSize: 3, deckCount: 1, randomCheckpoints: false, using: &rng)
        var counter = HiLoCounter()
        for (index, group) in drill.groups.enumerated() {
            counter.process(group)
            #expect(drill.expectedCount(afterGroup: index) == counter.runningCount)
        }
    }

    @Test("Random checkpoints are sorted, unique, include the last group, and occur sometimes")
    func randomCheckpoints() {
        var rng = SeededRandomNumberGenerator(seed: 4)
        let drill = CountDrillGenerator.runningCountDrill(
            length: .fullShoe, groupSize: 1, deckCount: 6, randomCheckpoints: true, using: &rng)
        #expect(drill.checkpoints == Array(Set(drill.checkpoints)).sorted())
        #expect(drill.checkpoints.last == drill.groups.count - 1)
        // 311 eligible groups at p = 1/8, so expect roughly 39; allow a wide band.
        #expect((15...70).contains(drill.checkpoints.count - 1))
    }

    @Test("True count questions have half-deck steps within the shoe")
    func trueCountQuestionShape() {
        var rng = SeededRandomNumberGenerator(seed: 5)
        for _ in 0..<500 {
            let q = CountDrillGenerator.trueCountQuestion(deckCount: 6, using: &rng)
            #expect(q.decksRemaining >= 0.5 && q.decksRemaining <= 5.5)
            #expect((q.decksRemaining * 2).rounded() == q.decksRemaining * 2)
            #expect((-12...12).contains(q.runningCount))
        }
        var single = SeededRandomNumberGenerator(seed: 6)
        let q = CountDrillGenerator.trueCountQuestion(deckCount: 1, using: &single)
        #expect(q.decksRemaining == 0.5)
    }

    @Test("Grading conventions")
    func grading() {
        let q = TrueCountQuestion(runningCount: 7, decksRemaining: 2.0)   // exact 3.5
        #expect(q.isCorrect(3.5, convention: .exact))
        #expect(q.isCorrect(3.25, convention: .exact))
        #expect(!q.isCorrect(3.0, convention: .exact))
        #expect(q.isCorrect(3, convention: .floor))
        #expect(!q.isCorrect(4, convention: .floor))
        #expect(q.isCorrect(3, convention: .truncate))

        let negative = TrueCountQuestion(runningCount: -7, decksRemaining: 2.0) // exact -3.5
        #expect(negative.isCorrect(-4, convention: .floor))
        #expect(negative.isCorrect(-3, convention: .truncate))
        #expect(!negative.isCorrect(-3, convention: .floor))
    }
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `cd BJSCore && swift test --filter "Count drills" 2>&1 | tail -5`
Expected: FAIL. `CountDrillGenerator` is not defined.

- [ ] **Step 3: Implement**

Create `BJSCore/Sources/BJSCore/Counting/CountDrills.swift`:

```swift
/// How the user is expected to round a true count.
public enum TrueCountConvention: String, CaseIterable, Sendable, Codable {
    /// Within ±0.25 of RC / decks.
    case exact
    /// ⌊RC / decks⌋.
    case floor
    /// RC / decks rounded toward zero.
    case truncate
}

public enum DrillLength: Sendable, Equatable, Hashable {
    case cards(Int)
    case fullShoe
}

/// A running-count drill: cards shown in groups; the user reports the count at checkpoints.
public struct RunningCountDrill: Sendable, Equatable {
    public let groups: [[Card]]
    /// Ascending group indices after which the user is asked for the running count.
    /// Always includes the last group.
    public let checkpoints: [Int]
    private let countsAfterGroup: [Int]

    init(groups: [[Card]], checkpoints: [Int]) {
        self.groups = groups
        self.checkpoints = checkpoints
        var running = 0
        self.countsAfterGroup = groups.map { group in
            running += group.reduce(0) { $0 + $1.rank.hiLoValue }
            return running
        }
    }

    public var cardCount: Int { groups.reduce(0) { $0 + $1.count } }

    /// The correct running count after the group at `index` has been shown.
    public func expectedCount(afterGroup index: Int) -> Int {
        countsAfterGroup[index]
    }
}

/// A true-count conversion question.
public struct TrueCountQuestion: Sendable, Equatable {
    public let runningCount: Int
    public let decksRemaining: Double

    public init(runningCount: Int, decksRemaining: Double) {
        self.runningCount = runningCount
        self.decksRemaining = decksRemaining
    }

    public var exactTrueCount: Double { Double(runningCount) / decksRemaining }

    public func isCorrect(_ answer: Double, convention: TrueCountConvention) -> Bool {
        switch convention {
        case .exact:
            return abs(answer - exactTrueCount) <= 0.25 + 1e-9
        case .floor:
            return abs(answer - exactTrueCount.rounded(.down)) < 1e-9
        case .truncate:
            return abs(answer - exactTrueCount.rounded(.towardZero)) < 1e-9
        }
    }
}

public enum CountDrillGenerator {

    /// Chance that any non-final group is a surprise checkpoint (about 1 in 8).
    public static let randomCheckpointProbability = 0.125

    public static func runningCountDrill<G: RandomNumberGenerator>(
        length: DrillLength, groupSize: Int, deckCount: Int,
        randomCheckpoints: Bool, using rng: inout G
    ) -> RunningCountDrill {
        let cards: [Card]
        switch length {
        case .cards(let n):
            let decks = max(1, Int((Double(n) / 52).rounded(.up)))
            cards = Array(Shoe.standardCards(deckCount: decks).shuffled(using: &rng).prefix(n))
        case .fullShoe:
            cards = Shoe.standardCards(deckCount: deckCount).shuffled(using: &rng)
        }
        let size = max(1, groupSize)
        let groups = stride(from: 0, to: cards.count, by: size).map {
            Array(cards[$0..<min($0 + size, cards.count)])
        }
        var checkpoints: [Int] = []
        if randomCheckpoints {
            for index in 0..<(groups.count - 1)
            where Double.random(in: 0..<1, using: &rng) < randomCheckpointProbability {
                checkpoints.append(index)
            }
        }
        checkpoints.append(groups.count - 1)
        return RunningCountDrill(groups: groups, checkpoints: checkpoints)
    }

    /// Running count in -12...12; decks remaining in half-deck steps from 0.5
    /// to `deckCount - 0.5` (0.5 for a single deck).
    public static func trueCountQuestion<G: RandomNumberGenerator>(
        deckCount: Int, using rng: inout G
    ) -> TrueCountQuestion {
        let maxHalfDecks = max(1, deckCount * 2 - 1)
        let halfDecks = Int.random(in: 1...maxHalfDecks, using: &rng)
        let rc = Int.random(in: -12...12, using: &rng)
        return TrueCountQuestion(runningCount: rc, decksRemaining: Double(halfDecks) / 2)
    }
}
```

- [ ] **Step 4: Run all engine tests**

Run: `cd BJSCore && swift test 2>&1 | tail -3`
Expected: passed, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add BJSCore
git commit -m "feat(core): running-count drills and true-count grading

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12: EdgeRating

**Files:**
- Create: `BJSCore/Sources/BJSCore/Edge/EdgeRating.swift`
- Test: `BJSCore/Tests/BJSCoreTests/EdgeTests/EdgeRatingTests.swift`

**Interfaces:**
- Consumes: `EdgeCalculator().analyze(rules:).houseEdge` (a percentage: 0.43 means 0.43%)
- Produces: `public enum EdgeRating: String, CaseIterable, Sendable { case good, ok, poor }` with `init(houseEdge: Double)` and `displayName: String` ("Good", "OK", "Poor")

**Thresholds (spec §5):** Good < 0.50; OK from 0.50 to 1.00 inclusive; Poor > 1.00. A negative edge (player advantage) is Good.

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
@testable import BJSCore

@Suite("EdgeRating")
struct EdgeRatingTests {

    @Test("Thresholds including boundaries", arguments: [
        (-0.20, EdgeRating.good), (0.0, .good), (0.49, .good),
        (0.50, .ok), (0.75, .ok), (1.00, .ok),
        (1.01, .poor), (2.0, .poor),
    ])
    func thresholds(edge: Double, expected: EdgeRating) {
        #expect(EdgeRating(houseEdge: edge) == expected)
    }

    @Test("Vegas Strip rates Good; single-deck 6:5 rates Poor")
    func presets() {
        let calc = EdgeCalculator()
        #expect(EdgeRating(houseEdge: calc.houseEdge(for: RulePreset.vegasStrip.rules)) == .good)
        #expect(EdgeRating(houseEdge: calc.houseEdge(for: RulePreset.singleDeckSixFive.rules)) == .poor)
    }

    @Test("Display names")
    func names() {
        #expect(EdgeRating.allCases.map(\.displayName) == ["Good", "OK", "Poor"])
    }
}
```

Save as `BJSCore/Tests/BJSCoreTests/EdgeTests/EdgeRatingTests.swift`.

- [ ] **Step 2: Run and confirm failure**

Run: `cd BJSCore && swift test --filter EdgeRating 2>&1 | tail -5`
Expected: FAIL. `EdgeRating` is not defined.

- [ ] **Step 3: Implement**

Create `BJSCore/Sources/BJSCore/Edge/EdgeRating.swift`:

```swift
/// Qualitative game rating from a house edge percentage (0.43 means 0.43%).
public enum EdgeRating: String, CaseIterable, Sendable {
    case good, ok, poor

    public init(houseEdge: Double) {
        if houseEdge < 0.5 {
            self = .good
        } else if houseEdge <= 1.0 {
            self = .ok
        } else {
            self = .poor
        }
    }

    public var displayName: String {
        switch self {
        case .good: return "Good"
        case .ok: return "OK"
        case .poor: return "Poor"
        }
    }
}
```

- [ ] **Step 4: Run all engine tests**

Run: `cd BJSCore && swift test 2>&1 | tail -3`
Expected: passed, 0 failures. If the preset test fails because the calculator's value for single-deck 6:5 is ≤ 1.00, report the actual number rather than changing thresholds. The spec fixes the thresholds; the test's choice of preset can be swapped for another rule set that is clearly above 1%.

- [ ] **Step 5: Commit**

```bash
git add BJSCore
git commit -m "feat(core): EdgeRating (Good/OK/Poor)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 13: Progress samples and ProgressStats

**Files:**
- Create: `BJSCore/Sources/BJSCore/Progress/ProgressSamples.swift`
- Create: `BJSCore/Sources/BJSCore/Progress/ProgressStats.swift`
- Test: `BJSCore/Tests/BJSCoreTests/ProgressTests/ProgressStatsTests.swift`

**Interfaces:**
- Consumes: `DecisionSample`, `TrainingCell` (Tasks 9–10)
- Produces:
  - `public enum TrainingModule: String, CaseIterable, Sendable, Codable { case strategy, countingRC, countingTC, shoe }`
  - `public enum CountKind: String, Sendable, Codable { case runningCount = "running", trueCount = "true" }`
  - `public struct CountSample: Sendable, Equatable { date, kind, expected: Double, answered: Double, isCorrect: Bool, responseMs: Int? }`
  - `public struct SessionSample: Sendable, Equatable, Identifiable { id: UUID, module, startedAt: Date, decisionCount, correctDecisions, countChecks, correctCountChecks }`
  - `public struct Headline: Sendable, Equatable { attempts: Int; correct: Int; var accuracy: Double? }`, where accuracy is 0...1 and nil when there are no attempts
  - `public struct TrendPoint: Sendable, Equatable { day: Date; attempts: Int; correct: Int; var accuracy: Double }`
  - `public struct HeatCell: Sendable, Equatable { attempts: Int; errors: Int; errorRate: Double? }`, with nil when attempts < 3
  - `public enum ProgressStats`, with:
    - `enum Measure { case decisions, countChecks, combined }` and `heatMapMinimumSamples = 3`;
    - `headline(sessions:modules:measure:since:) -> Headline`;
    - `dailyTrend(sessions:modules:measure:since:calendar:) -> [TrendPoint]`;
    - `heatMap(_:) -> [TrainingCell: HeatCell]`;
    - `currentStreak(_:) -> Int`.

- [ ] **Step 1: Write the failing tests**

```swift
import Foundation
import Testing
@testable import BJSCore

@Suite("ProgressStats")
struct ProgressStatsTests {

    let day: TimeInterval = 86_400
    var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    func session(_ module: TrainingModule, day d: Int, decisions: Int = 0, correct: Int = 0,
                 checks: Int = 0, correctChecks: Int = 0) -> SessionSample {
        SessionSample(id: UUID(), module: module,
                      startedAt: Date(timeIntervalSince1970: Double(d) * day + 3_600),
                      decisionCount: decisions, correctDecisions: correct,
                      countChecks: checks, correctCountChecks: correctChecks)
    }

    @Test("Headline sums the chosen measure over chosen modules")
    func headline() {
        let sessions = [
            session(.strategy, day: 1, decisions: 50, correct: 45),
            session(.shoe, day: 2, decisions: 30, correct: 27, checks: 10, correctChecks: 8),
            session(.countingRC, day: 2, checks: 20, correctChecks: 15),
        ]
        let strategy = ProgressStats.headline(sessions: sessions, modules: [.strategy, .shoe],
                                              measure: .decisions, since: nil)
        #expect(strategy == Headline(attempts: 80, correct: 72))
        #expect(strategy.accuracy == 0.9)

        let counting = ProgressStats.headline(sessions: sessions, modules: [.countingRC, .countingTC, .shoe],
                                              measure: .countChecks, since: nil)
        #expect(counting == Headline(attempts: 30, correct: 23))

        let shoeCombined = ProgressStats.headline(sessions: sessions, modules: [.shoe],
                                                  measure: .combined, since: nil)
        #expect(shoeCombined == Headline(attempts: 40, correct: 35))
    }

    @Test("Headline respects the since date and has nil accuracy when empty")
    func headlineSince() {
        let sessions = [session(.strategy, day: 1, decisions: 10, correct: 5),
                        session(.strategy, day: 40, decisions: 10, correct: 10)]
        let recent = ProgressStats.headline(sessions: sessions, modules: [.strategy], measure: .decisions,
                                            since: Date(timeIntervalSince1970: 10 * day))
        #expect(recent.accuracy == 1.0)
        let none = ProgressStats.headline(sessions: [], modules: [.strategy], measure: .decisions, since: nil)
        #expect(none.accuracy == nil)
    }

    @Test("Daily trend groups by day, skips empty days, ascends")
    func trend() {
        let sessions = [
            session(.strategy, day: 3, decisions: 10, correct: 9),
            session(.strategy, day: 1, decisions: 10, correct: 5),
            session(.strategy, day: 1, decisions: 10, correct: 7),
            session(.countingRC, day: 2, checks: 5, correctChecks: 5),
        ]
        let points = ProgressStats.dailyTrend(sessions: sessions, modules: [.strategy], measure: .decisions,
                                              since: nil, calendar: utc)
        #expect(points.map(\.attempts) == [20, 10])
        #expect(points.map(\.accuracy) == [0.6, 0.9])
        #expect(points[0].day == Date(timeIntervalSince1970: 1 * day))
    }

    @Test("Heat map counts per cell and hides cells under 3 samples")
    func heatMap() {
        let cellA = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)
        let cellB = TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 9)
        let t = Date(timeIntervalSince1970: 0)
        let samples = [
            DecisionSample(date: t, cell: cellA, isCorrect: false, responseMs: nil),
            DecisionSample(date: t, cell: cellA, isCorrect: true, responseMs: nil),
            DecisionSample(date: t, cell: cellA, isCorrect: false, responseMs: nil),
            DecisionSample(date: t, cell: cellA, isCorrect: true, responseMs: nil),
            DecisionSample(date: t, cell: cellB, isCorrect: false, responseMs: nil),
        ]
        let map = ProgressStats.heatMap(samples)
        #expect(map[cellA] == HeatCell(attempts: 4, errors: 2, errorRate: 0.5))
        #expect(map[cellB] == HeatCell(attempts: 1, errors: 1, errorRate: nil))
    }

    @Test("Current streak counts trailing correct decisions by date")
    func streak() {
        let cell = TrainingCell(handType: .hard, playerValue: 12, dealerUpcard: 4)
        func s(_ t: Double, _ ok: Bool) -> DecisionSample {
            DecisionSample(date: Date(timeIntervalSince1970: t), cell: cell, isCorrect: ok, responseMs: nil)
        }
        #expect(ProgressStats.currentStreak([s(3, true), s(1, true), s(2, false), s(4, true)]) == 2)
        #expect(ProgressStats.currentStreak([s(1, false)]) == 0)
        #expect(ProgressStats.currentStreak([]) == 0)
    }
}
```

Save as `BJSCore/Tests/BJSCoreTests/ProgressTests/ProgressStatsTests.swift`.

- [ ] **Step 2: Run and confirm failure**

Run: `cd BJSCore && swift test --filter ProgressStats 2>&1 | tail -5`
Expected: FAIL. `SessionSample` is not defined.

- [ ] **Step 3: Implement the sample types**

Create `BJSCore/Sources/BJSCore/Progress/ProgressSamples.swift`:

```swift
import Foundation

/// The trainable modules, as stored on each persisted session.
public enum TrainingModule: String, CaseIterable, Sendable, Codable {
    case strategy
    case countingRC
    case countingTC
    case shoe
}

public enum CountKind: String, Sendable, Codable {
    case runningCount = "running"
    case trueCount = "true"
}

/// One graded count check, as read back from persistence.
public struct CountSample: Sendable, Equatable {
    public let date: Date
    public let kind: CountKind
    public let expected: Double
    public let answered: Double
    public let isCorrect: Bool
    public let responseMs: Int?

    public init(date: Date, kind: CountKind, expected: Double, answered: Double,
                isCorrect: Bool, responseMs: Int?) {
        self.date = date
        self.kind = kind
        self.expected = expected
        self.answered = answered
        self.isCorrect = isCorrect
        self.responseMs = responseMs
    }
}

/// A persisted session's cached summary.
public struct SessionSample: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let module: TrainingModule
    public let startedAt: Date
    public let decisionCount: Int
    public let correctDecisions: Int
    public let countChecks: Int
    public let correctCountChecks: Int

    public init(id: UUID, module: TrainingModule, startedAt: Date, decisionCount: Int,
                correctDecisions: Int, countChecks: Int, correctCountChecks: Int) {
        self.id = id
        self.module = module
        self.startedAt = startedAt
        self.decisionCount = decisionCount
        self.correctDecisions = correctDecisions
        self.countChecks = countChecks
        self.correctCountChecks = correctCountChecks
    }
}
```

- [ ] **Step 4: Implement `ProgressStats`**

Create `BJSCore/Sources/BJSCore/Progress/ProgressStats.swift`:

```swift
import Foundation

public struct Headline: Sendable, Equatable {
    public let attempts: Int
    public let correct: Int

    public init(attempts: Int, correct: Int) {
        self.attempts = attempts
        self.correct = correct
    }

    /// Fraction correct in 0...1, or nil with no attempts.
    public var accuracy: Double? {
        attempts == 0 ? nil : Double(correct) / Double(attempts)
    }
}

public struct TrendPoint: Sendable, Equatable {
    /// Start of the calendar day.
    public let day: Date
    public let attempts: Int
    public let correct: Int

    public var accuracy: Double { Double(correct) / Double(attempts) }
}

public struct HeatCell: Sendable, Equatable {
    public let attempts: Int
    public let errors: Int
    /// nil when there are fewer than `ProgressStats.heatMapMinimumSamples` attempts.
    public let errorRate: Double?

    public init(attempts: Int, errors: Int, errorRate: Double?) {
        self.attempts = attempts
        self.errors = errors
        self.errorRate = errorRate
    }
}

/// Pure aggregation over persisted samples for the hub and the Progress tab.
public enum ProgressStats {

    public enum Measure: Sendable {
        case decisions
        case countChecks
        case combined
    }

    public static let heatMapMinimumSamples = 3

    public static func headline(sessions: [SessionSample], modules: Set<TrainingModule>,
                                measure: Measure, since: Date?) -> Headline {
        let totals = filtered(sessions, modules: modules, since: since).map { tally($0, measure) }
        return Headline(attempts: totals.reduce(0) { $0 + $1.attempts },
                        correct: totals.reduce(0) { $0 + $1.correct })
    }

    public static func dailyTrend(sessions: [SessionSample], modules: Set<TrainingModule>,
                                  measure: Measure, since: Date?, calendar: Calendar) -> [TrendPoint] {
        var byDay: [Date: (attempts: Int, correct: Int)] = [:]
        for session in filtered(sessions, modules: modules, since: since) {
            let day = calendar.startOfDay(for: session.startedAt)
            let t = tally(session, measure)
            let current = byDay[day] ?? (0, 0)
            byDay[day] = (current.attempts + t.attempts, current.correct + t.correct)
        }
        return byDay
            .filter { $0.value.attempts > 0 }
            .map { TrendPoint(day: $0.key, attempts: $0.value.attempts, correct: $0.value.correct) }
            .sorted { $0.day < $1.day }
    }

    public static func heatMap(_ decisions: [DecisionSample]) -> [TrainingCell: HeatCell] {
        var attempts: [TrainingCell: Int] = [:]
        var errors: [TrainingCell: Int] = [:]
        for d in decisions {
            attempts[d.cell, default: 0] += 1
            if !d.isCorrect { errors[d.cell, default: 0] += 1 }
        }
        var result: [TrainingCell: HeatCell] = [:]
        for (cell, a) in attempts {
            let e = errors[cell] ?? 0
            let rate: Double? = a >= heatMapMinimumSamples ? Double(e) / Double(a) : nil
            result[cell] = HeatCell(attempts: a, errors: e, errorRate: rate)
        }
        return result
    }

    /// Consecutive correct decisions counting back from the newest.
    public static func currentStreak(_ decisions: [DecisionSample]) -> Int {
        var streak = 0
        for d in decisions.sorted(by: { $0.date > $1.date }) {
            guard d.isCorrect else { break }
            streak += 1
        }
        return streak
    }

    // MARK: - Helpers

    private static func filtered(_ sessions: [SessionSample], modules: Set<TrainingModule>,
                                 since: Date?) -> [SessionSample] {
        sessions.filter { modules.contains($0.module) && (since == nil || $0.startedAt >= since!) }
    }

    private static func tally(_ s: SessionSample, _ measure: Measure) -> (attempts: Int, correct: Int) {
        switch measure {
        case .decisions: return (s.decisionCount, s.correctDecisions)
        case .countChecks: return (s.countChecks, s.correctCountChecks)
        case .combined: return (s.decisionCount + s.countChecks, s.correctDecisions + s.correctCountChecks)
        }
    }
}
```

- [ ] **Step 5: Run all engine tests**

Run: `cd BJSCore && swift test 2>&1 | tail -3`
Expected: passed, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add BJSCore
git commit -m "feat(core): progress samples and ProgressStats (headline, trend, heat map, streak)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 14: Step verification and handoff

**Files:**
- Modify: `docs/superpowers/progress.md`

- [ ] **Step 1: Verify `BJSCore` has no UI or persistence imports**

Run: `grep -rn "import SwiftUI\|import SwiftData\|import UIKit" BJSCore/Sources || echo CLEAN`
Expected: `CLEAN`

- [ ] **Step 2: Run the full engine suite and record the count**

Run: `cd BJSCore && swift test 2>&1 | tail -2`
Expected: `Test run with N tests ... passed`. Note N.

- [ ] **Step 3: Build and test the app target (confirms BJSCore still links)**

Run: `xcodegen generate && xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -quiet 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 4: Append the Step 1 handoff to `docs/superpowers/progress.md`**

Use the real test count N and the real commit range from `git log --oneline`:

```markdown

## Step 1 — Engine completion (YYYY-MM-DD)

- Commits: <first-sha>..<last-sha>
- BJSCore tests: N passing (`cd BJSCore && swift test`); app shell tests passing.
- Added: SeededRandomNumberGenerator; Shoe(orderedCards:), shuffle(using:), standardCards, dealtCount;
  StrategyTable hit/stand fallback + action(for:dealerUpcard:legal:) / action(for: DecisionSpot);
  RoundEngine (naturals, peek/ENHC, early/late surrender, double, splits incl. aces/RSA/max hands);
  TrainingCell (340 cells), HandFilter, HandGenerator (weighted, stacked shoes, no dealer naturals);
  DecisionSample + WeakSpotWeights; CountDrillGenerator + TrueCountQuestion/Convention; EdgeRating;
  TrainingModule, CountKind, CountSample, SessionSample, ProgressStats.
- Behaviour notes for Step 2+: RoundEngine auto-finishes hands at 21+; no insurance; 21 after split pays 1:1;
  training hands never start with a dealer natural; TrainingCell uses 11 for aces.
- Next: Step 2 (Foundation) — brainstorm/plan in a fresh session from spec §4 and §8.
```

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/progress.md
git commit -m "docs: Step 1 handoff

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

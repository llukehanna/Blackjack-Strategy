# Architecture Research

**Domain:** iOS blackjack training app (educational, offline-first, single-player)
**Researched:** 2026-03-24
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      SwiftUI View Layer                         │
│  ┌────────────┐ ┌────────────┐ ┌──────────┐ ┌──────────────┐   │
│  │ Strategy   │ │ HiLo       │ │ Edge     │ │ Simulator    │   │
│  │ Trainer    │ │ Practice   │ │ Calc     │ │ View         │   │
│  └─────┬──────┘ └─────┬──────┘ └────┬─────┘ └──────┬───────┘   │
│        │              │             │              │            │
├────────┴──────────────┴─────────────┴──────────────┴────────────┤
│                    ViewModel Layer (@Observable)                 │
│  ┌────────────┐ ┌────────────┐ ┌──────────┐ ┌──────────────┐   │
│  │ Strategy   │ │ HiLo       │ │ Edge     │ │ Simulator    │   │
│  │ TrainerVM  │ │ PracticeVM │ │ CalcVM   │ │ VM           │   │
│  └─────┬──────┘ └─────┬──────┘ └────┬─────┘ └──────┬───────┘   │
│        │              │             │              │            │
├────────┴──────────────┴─────────────┴──────────────┴────────────┤
│                    Core Engine Layer (pure Swift)                │
│  ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ Rules    │ │ Strategy  │ │ Counting │ │ Edge             │  │
│  │ Engine   │ │ Engine    │ │ Engine   │ │ Calculator       │  │
│  └────┬─────┘ └─────┬─────┘ └────┬─────┘ └────────┬─────────┘  │
│       │             │            │                │             │
│  ┌────┴─────────────┴────────────┴────────────────┴──────────┐  │
│  │                    Shared Models                           │  │
│  │  (Card, Hand, Shoe, RuleSet, Action, CountingSystem)      │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    Persistence Layer                             │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │ SwiftData    │  │ UserDefaults │                             │
│  │ (Progress)   │  │ (Settings)   │                             │
│  └──────────────┘  └──────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **Rules Engine** | Card dealing, hand evaluation, game flow (hit/stand/double/split/surrender), bust detection, payout calculation | Pure Swift struct/class with no UI imports. Takes a `RuleSet` config and produces deterministic outcomes. |
| **Strategy Engine** | Lookup correct basic strategy action for any hand vs. dealer upcard under a given rule set | Lookup tables indexed by (hand type, hand total, dealer upcard, rule set). Returns `Action` enum. Must handle S17/H17 deviations, composition-dependent plays. |
| **Counting Engine** | Hi-Lo card value assignment, running count tracking, true count calculation (running count / decks remaining) | Pure functions: `hiLoValue(card:) -> Int`, `trueCount(running:, decksRemaining:) -> Double`. Tracks shoe state. |
| **Edge Calculator** | Compute house edge from a `RuleSet` configuration | Combinatorial analysis for base edge, rule-by-rule adjustment factors. Returns edge percentage + quality rating. |
| **ViewModels** | Own UI state, orchestrate engine calls, handle async operations, expose bindable state to views | `@Observable` classes. One per feature screen. Import Foundation only (not SwiftUI). |
| **Views** | Render UI, capture user input, animate card/game interactions | SwiftUI views. Thin -- delegate all logic to ViewModels. |
| **Persistence** | Store session stats, progress history, user settings | SwiftData for structured progress data; `@AppStorage`/UserDefaults for simple settings (deck count preference, etc.) |

## Recommended Project Structure

```
BJS/
├── BJS.xcodeproj
├── BJS/                          # Main app target
│   ├── BJSApp.swift              # @main entry point
│   ├── ContentView.swift         # Root navigation (TabView)
│   ├── Features/                 # Feature modules (grouped by screen)
│   │   ├── StrategyTrainer/
│   │   │   ├── StrategyTrainerView.swift
│   │   │   ├── StrategyTrainerViewModel.swift
│   │   │   └── Components/       # Feature-specific subviews
│   │   ├── HiLoPractice/
│   │   │   ├── HiLoPracticeView.swift
│   │   │   ├── HiLoPracticeViewModel.swift
│   │   │   └── Components/
│   │   ├── EdgeCalculator/
│   │   │   ├── EdgeCalculatorView.swift
│   │   │   ├── EdgeCalculatorViewModel.swift
│   │   │   └── Components/
│   │   └── Simulator/
│   │       ├── SimulatorView.swift
│   │       ├── SimulatorViewModel.swift
│   │       └── Components/
│   ├── Shared/                   # Cross-feature UI components
│   │   ├── CardView.swift
│   │   ├── HandView.swift
│   │   ├── ChipView.swift
│   │   └── Theme.swift
│   └── Persistence/
│       ├── Models/               # SwiftData @Model classes
│       │   ├── SessionRecord.swift
│       │   └── ProgressSnapshot.swift
│       └── ProgressStore.swift   # Persistence interface
│
├── BJSCore/                      # Local Swift Package (pure logic)
│   ├── Package.swift
│   ├── Sources/
│   │   ├── Models/
│   │   │   ├── Card.swift
│   │   │   ├── Hand.swift
│   │   │   ├── Shoe.swift
│   │   │   ├── RuleSet.swift
│   │   │   └── Action.swift
│   │   ├── RulesEngine/
│   │   │   ├── BlackjackGame.swift
│   │   │   ├── HandEvaluator.swift
│   │   │   └── PayoutCalculator.swift
│   │   ├── StrategyEngine/
│   │   │   ├── BasicStrategyTable.swift
│   │   │   └── StrategyLookup.swift
│   │   ├── CountingEngine/
│   │   │   ├── HiLoCounter.swift
│   │   │   └── TrueCountCalculator.swift
│   │   └── EdgeCalculator/
│   │       ├── HouseEdgeCalculator.swift
│   │       └── RuleEffects.swift
│   └── Tests/
│       ├── RulesEngineTests/
│       ├── StrategyEngineTests/
│       ├── CountingEngineTests/
│       └── EdgeCalculatorTests/
│
└── BJSTests/                     # App-level tests (ViewModel tests)
    ├── StrategyTrainerVMTests.swift
    ├── HiLoPracticeVMTests.swift
    └── ...
```

### Structure Rationale

- **BJSCore/ as local Swift Package:** This is the single most important architectural decision. All blackjack logic lives in a separate Swift Package with zero UI dependencies. This enforces the boundary at the compiler level -- BJSCore cannot import SwiftUI, and tests run without a simulator. It also opens the door to future platforms (macOS, watchOS) without rewriting logic.
- **Features/ grouped by screen:** Each feature is a self-contained folder with its View, ViewModel, and sub-components. This mirrors how users think about the app (four training modes) and keeps related code co-located.
- **Shared/:** Cross-feature UI components (card rendering, theming) live here. Card visuals are reused across Strategy Trainer, Hi-Lo Practice, and Simulator.
- **Persistence/ separate from Features:** Progress tracking spans multiple features, so the persistence layer sits at the app level, injected into ViewModels that need it.

## Architectural Patterns

### Pattern 1: Modern MVVM with @Observable

**What:** Each feature screen has a View (SwiftUI) and a ViewModel (@Observable class). The ViewModel owns state and calls into BJSCore engines. Views bind directly to ViewModel properties.

**When to use:** Every feature screen that has interactive state (all four training modes).

**Trade-offs:**
- Pro: Natural fit for SwiftUI's data flow. @Observable eliminates @Published boilerplate and provides fine-grained observation (only re-renders views that read changed properties).
- Pro: ViewModels are testable without SwiftUI -- just instantiate and assert on state.
- Pro: Simpler than TCA (The Composable Architecture) for an app of this scope. TCA adds significant ceremony (reducers, actions, effects, stores) that pays off in very large apps with complex shared state, but this app has four largely independent features.
- Con: Less structured than TCA for shared cross-feature state (mitigated here because features are mostly independent).

**Why not TCA:** TCA is overkill for this project. The four features share very little state. The main shared concern (RuleSet configuration) is easily passed via the environment or initializer injection. TCA's learning curve and boilerplate are not justified.

**Example:**
```swift
// BJSCore -- pure logic, no UI imports
struct StrategyLookup {
    func correctAction(
        playerHand: Hand,
        dealerUpcard: Card,
        rules: RuleSet
    ) -> Action {
        // Table lookup based on hand type, total, and rules
    }
}

// ViewModel -- @Observable, imports Foundation only
import Foundation

@Observable
final class StrategyTrainerViewModel {
    var currentHand: Hand?
    var dealerUpcard: Card?
    var lastResult: FeedbackResult?
    var sessionStats: SessionStats = .init()

    private let game: BlackjackGame
    private let strategy: StrategyLookup
    private let progressStore: ProgressStoring  // protocol

    init(rules: RuleSet, progressStore: ProgressStoring) {
        self.game = BlackjackGame(rules: rules)
        self.strategy = StrategyLookup()
        self.progressStore = progressStore
    }

    func dealNewHand() {
        let dealt = game.dealHand()
        currentHand = dealt.playerHand
        dealerUpcard = dealt.dealerUpcard
        lastResult = nil
    }

    func playerAction(_ action: Action) {
        let correct = strategy.correctAction(
            playerHand: currentHand!,
            dealerUpcard: dealerUpcard!,
            rules: game.rules
        )
        let isCorrect = action == correct
        lastResult = FeedbackResult(
            chosen: action,
            correct: correct,
            isCorrect: isCorrect
        )
        sessionStats.record(isCorrect: isCorrect)
    }
}

// View -- thin, just renders ViewModel state
struct StrategyTrainerView: View {
    @State var vm: StrategyTrainerViewModel

    var body: some View {
        VStack {
            if let hand = vm.currentHand, let dealer = vm.dealerUpcard {
                HandView(hand: hand)
                CardView(card: dealer)
                ActionButtons { action in vm.playerAction(action) }
            }
            if let result = vm.lastResult {
                FeedbackView(result: result)
            }
        }
        .onAppear { vm.dealNewHand() }
    }
}
```

### Pattern 2: Protocol-Based Dependency Injection

**What:** ViewModels depend on protocols, not concrete types. Core engines and persistence are injected via initializers.

**When to use:** Any ViewModel that needs persistence or engines that you want to mock in tests.

**Trade-offs:**
- Pro: Enables unit testing without real persistence or complex engine setup.
- Pro: Clean boundaries -- ViewModel does not know how data is stored.
- Con: Slight overhead of defining protocols. Worth it for testability.

**Example:**
```swift
protocol ProgressStoring {
    func save(session: SessionRecord) async
    func fetchHistory(limit: Int) async -> [SessionRecord]
}

// Real implementation uses SwiftData
final class SwiftDataProgressStore: ProgressStoring { ... }

// Test mock
final class MockProgressStore: ProgressStoring {
    var savedSessions: [SessionRecord] = []
    func save(session: SessionRecord) async {
        savedSessions.append(session)
    }
    func fetchHistory(limit: Int) async -> [SessionRecord] {
        Array(savedSessions.prefix(limit))
    }
}
```

### Pattern 3: Value-Type Domain Models

**What:** Core domain models (Card, Hand, RuleSet, Action) are Swift structs and enums, not classes. Immutable by default. Game state transitions produce new values rather than mutating in place.

**When to use:** All BJSCore models.

**Trade-offs:**
- Pro: Thread-safe, easy to test, easy to snapshot for undo/replay.
- Pro: Swift's value semantics prevent accidental shared mutation.
- Con: Deep copy cost for large structures (not a concern here -- hands and shoes are small).

## Data Flow

### Strategy Trainer Flow

```
[User taps action button]
    |
    v
StrategyTrainerView
    |  calls vm.playerAction(.hit)
    v
StrategyTrainerViewModel
    |  calls strategy.correctAction(hand, upcard, rules)
    v
StrategyLookup (BJSCore)
    |  returns Action.stand
    v
StrategyTrainerViewModel
    |  compares user action vs correct -> builds FeedbackResult
    |  updates sessionStats
    |  @Observable triggers view update
    v
StrategyTrainerView re-renders feedback
    |
    [Session ends]
    |
    v
StrategyTrainerViewModel
    |  calls progressStore.save(sessionRecord)
    v
SwiftDataProgressStore -> SwiftData (on disk)
```

### Edge Calculator Flow

```
[User adjusts rule toggles]
    |
    v
EdgeCalculatorView
    |  two-way binding to vm.ruleSet via @Bindable
    v
EdgeCalculatorViewModel
    |  on ruleSet change, calls calculator.computeEdge(ruleSet)
    v
HouseEdgeCalculator (BJSCore)
    |  base edge + sum of rule effect adjustments
    |  returns HouseEdgeResult (edge %, quality rating)
    v
EdgeCalculatorViewModel
    |  updates edgeResult property
    |  @Observable triggers view update
    v
EdgeCalculatorView re-renders edge display + quality badge
```

### Hi-Lo Practice Flow

```
[Cards presented on screen]
    |
    v
HiLoPracticeView
    |  user enters running count guess
    v
HiLoPracticeViewModel
    |  calls counter.runningCount for revealed cards
    v
HiLoCounter (BJSCore)
    |  sums hi-lo values: +1 (2-6), 0 (7-9), -1 (10-A)
    |  returns Int running count
    v
HiLoPracticeViewModel
    |  compares user guess vs actual
    |  tracks speed (time between card reveal and answer)
    |  updates sessionStats
    v
HiLoPracticeView re-renders correctness + speed feedback
```

### State Management

```
App Launch
    |
    v
ContentView (TabView)
    |  creates ViewModels, injects shared dependencies:
    |    - RuleSet (from UserDefaults / @AppStorage)
    |    - ProgressStore (SwiftData-backed)
    v
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ Strategy Tab │ HiLo Tab     │ Edge Tab     │ Simulator Tab│
│ (own VM)     │ (own VM)     │ (own VM)     │ (own VM)     │
└──────────────┴──────────────┴──────────────┴──────────────┘

Each ViewModel owns its own screen state.
Shared state (RuleSet, ProgressStore) is injected, not global singletons.
```

### Key Data Flows

1. **RuleSet propagation:** User configures rules in Edge Calculator or a shared settings screen. The RuleSet value is stored in UserDefaults (via @AppStorage) and injected into each ViewModel on creation. When rules change, ViewModels that care about rules pick up the new value.
2. **Progress persistence:** Each training session produces a `SessionRecord` (date, mode, accuracy, hand count, mistakes). ViewModels call `progressStore.save()` at session end. A progress/stats view queries the store for historical data.
3. **Shoe state in Simulator:** The Simulator ViewModel maintains a `Shoe` (ordered deck of cards). As cards are dealt, the shoe depletes. The counting engine tracks running count against the same shoe. This state lives entirely in the ViewModel -- no persistence needed mid-session.

## Build Order (Dependency Chain)

This is critical for roadmap phasing. Components must be built bottom-up because upper layers depend on lower ones.

### Phase 1: Foundation (must come first)

1. **Shared Models** -- Card, Suit, Rank, Hand, Shoe, RuleSet, Action enums/structs. Every other component depends on these.
2. **Rules Engine** -- Hand evaluation, dealing, bust detection, game flow. The Strategy Trainer and Simulator both need this.
3. **Strategy Engine** -- Basic strategy lookup tables. Depends on Models and RuleSet. Required for the Strategy Trainer (the core feature).

### Phase 2: Core Training Feature

4. **Strategy Trainer ViewModel + View** -- The primary training loop. Depends on Rules Engine + Strategy Engine. This is the MVP feature.
5. **Basic Persistence** -- SessionRecord model, SwiftData store. Enables progress tracking from day one.

### Phase 3: Supporting Features

6. **Counting Engine** -- Hi-Lo values, running count, true count. Independent of Rules Engine (just card math).
7. **Hi-Lo Practice ViewModel + View** -- Depends on Counting Engine + Models.
8. **Edge Calculator Engine** -- Depends only on RuleSet model. Can be built in parallel with counting.
9. **Edge Calculator ViewModel + View** -- Depends on Edge Calculator Engine.

### Phase 4: Advanced Feature

10. **Simulator** -- Combines Rules Engine + Strategy Engine + Counting Engine into a full-shoe simulation. This is the most complex feature and depends on everything else being solid.
11. **Progress dashboard / stats views** -- Queries accumulated SwiftData records across all modes.

### Dependency Graph

```
Models (Card, Hand, RuleSet, Action, Shoe)
  |
  ├── Rules Engine
  |     ├── Strategy Engine
  |     |     ├── Strategy Trainer VM + View  [Phase 2]
  |     |     └── Simulator VM + View         [Phase 4]
  |     └── Simulator VM + View               [Phase 4]
  |
  ├── Counting Engine
  |     ├── Hi-Lo Practice VM + View          [Phase 3]
  |     └── Simulator VM + View               [Phase 4]
  |
  ├── Edge Calculator Engine
  |     └── Edge Calculator VM + View         [Phase 3]
  |
  └── Persistence Layer
        ├── All ViewModels (progress tracking)
        └── Stats Dashboard                   [Phase 4]
```

## Anti-Patterns

### Anti-Pattern 1: Fat Views

**What people do:** Put game logic, strategy lookup, and state management directly in SwiftUI view bodies or inside view helper methods.
**Why it's wrong:** Untestable. SwiftUI views are recreated frequently and are not designed to hold complex state. Strategy correctness -- the core product value -- becomes impossible to unit test.
**Do this instead:** Views call ViewModel methods. ViewModels call engine functions. Engine functions are pure and testable.

### Anti-Pattern 2: Global Singletons for Game State

**What people do:** Create a shared `GameManager.shared` singleton that all views access directly.
**Why it's wrong:** Hidden dependencies. Hard to test. Impossible to have two independent game sessions. State leaks between features.
**Do this instead:** Each ViewModel owns its feature's state. Shared dependencies (RuleSet, ProgressStore) are injected via initializer, not accessed globally.

### Anti-Pattern 3: Hardcoded Strategy Tables

**What people do:** Embed one basic strategy chart and treat it as universal truth.
**Why it's wrong:** Basic strategy varies by rule set. S17 vs H17 changes several plays. Surrender availability changes plays. DAS changes pair-splitting decisions. A hardcoded table will give wrong answers for rule sets it was not designed for.
**Do this instead:** Strategy tables must be parameterized by RuleSet. Either maintain multiple tables keyed by rule variations, or compute correct actions from expected-value calculations. The lookup must accept a RuleSet and return the correct action for that specific configuration.

### Anti-Pattern 4: Mixing UI Animation with Game Logic

**What people do:** Tie card dealing animations to actual game state transitions, so the game state depends on animation completion.
**Why it's wrong:** Makes game logic untestable and fragile. Animation timing varies by device. Produces bugs where game state is inconsistent during animation.
**Do this instead:** Game state transitions happen instantly in the engine. The View layer animates the transition independently. ViewModels expose the final state; Views decide how to animate to it.

### Anti-Pattern 5: One Mega-ViewModel

**What people do:** Create a single ViewModel that manages all four training modes.
**Why it's wrong:** Becomes massive, hard to reason about, hard to test. Changes to one feature risk breaking others.
**Do this instead:** One ViewModel per feature screen. They share dependencies (engines, persistence) but own their own state.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| App Store (StoreKit) | Defer until monetization needed | Not required for v1. When needed, use StoreKit 2 with async/await. |
| iCloud (CloudKit) | Optional future sync | SwiftData supports CloudKit sync, but adds complexity. Defer. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| View <-> ViewModel | @Observable property observation + method calls | Views read VM properties; call VM methods for actions |
| ViewModel <-> BJSCore | Direct function calls (synchronous) | Engines are pure Swift, fast, no async needed for single-hand operations |
| ViewModel <-> Persistence | Async calls via protocol | `async` because SwiftData operations should not block the main thread |
| BJSCore engines <-> Models | Shared value types | All engines operate on the same Card/Hand/RuleSet types |
| Feature <-> Feature | No direct communication | Features are independent tabs. Shared config (RuleSet) flows through the app environment |

## Edge Calculator: Implementation Approach

The house edge calculator deserves special attention because mathematical accuracy is a core differentiator.

**Recommended approach: Rule-effect adjustment table.**

Start with a known base edge for a standard rule set (e.g., 6-deck, S17, DAS, no surrender = approximately 0.40% house edge). Then apply additive adjustments for each rule variation:

| Rule Variation | Effect on House Edge |
|----------------|---------------------|
| H17 vs S17 | +0.20% for H17 |
| Single deck vs 6-deck | -0.48% for single deck |
| DAS allowed | -0.14% |
| No DAS | +0.14% |
| Late surrender | -0.07% |
| RSA allowed | -0.08% |
| BJ pays 6:5 vs 3:2 | +1.36% for 6:5 |
| Double on 10-11 only | +0.18% |
| Double on 9-11 only | +0.09% |

These values are well-established in blackjack literature (Wizard of Odds, Stanford Wong). Store them as constants and sum them. This is simpler and more verifiable than Monte Carlo simulation for the edge calculator feature.

**Future enhancement:** Full combinatorial analysis for exact edge calculation. This is computationally expensive but would be a strong differentiator. Can be added as a v2 improvement.

## Scaling Considerations

This is a single-user offline iOS app, so traditional server scaling does not apply. The relevant scaling dimensions are:

| Concern | Current Approach | If It Grows |
|---------|-----------------|-------------|
| Progress data volume | SwiftData, local SQLite | Thousands of sessions -- SwiftData handles this fine |
| Simulation speed | Single-threaded engine | If users want millions of hands simulated, use Swift concurrency (`TaskGroup`) to parallelize across CPU cores |
| Strategy table size | In-memory lookup tables | Even covering all rule permutations, tables fit easily in memory |
| App launch time | Lazy ViewModel creation | Not a concern at this scale |

### First Bottleneck (if any)

Full-shoe simulation with millions of hands. Mitigate by running simulation on a background thread using Swift structured concurrency, updating the UI with progress via `AsyncStream`.

## Sources

- [Apple: Migrating from ObservableObject to @Observable macro](https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [SwiftLee: MVVM architectural pattern for SwiftUI](https://www.avanderlee.com/swiftui/mvvm-architectural-coding-pattern-to-structure-views/)
- [SwiftLee: @Observable macro performance](https://www.avanderlee.com/swiftui/observable-macro-performance-increase-observableobject/)
- [Nalexn: Clean Architecture for SwiftUI](https://nalexn.github.io/clean-architecture-swiftui/)
- [Nimble: Modularizing iOS apps with SPM](https://nimblehq.co/blog/modern-approach-modularize-ios-swiftui-spm)
- [Donnywals: Storage options on iOS compared](https://www.donnywals.com/storage-options-on-ios-compared/)
- [BleepingSwift: @AppStorage vs UserDefaults vs SwiftData](https://bleepingswift.com/blog/appstorage-vs-userdefaults-vs-swiftdata)
- [Wizard of Odds: Blackjack house edge calculator](https://wizardofodds.com/games/blackjack/calculator/)
- [BlackjackInfo: Basic strategy engine](https://www.blackjackinfo.com/blackjack-basic-strategy-engine/)
- [GitHub: Blackjack-Strategy-Simulator (combinatorial approach)](https://github.com/AttackingOrDefending/Blackjack-Strategy-Simulator)
- [Beating Bonuses: House edge calculator with rule adjustments](https://www.beatingbonuses.com/houseedge.htm)

---
*Architecture research for: BJS -- iOS Blackjack Training App*
*Researched: 2026-03-24*

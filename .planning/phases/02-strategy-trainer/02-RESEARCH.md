# Phase 2: Strategy Trainer - Research

**Researched:** 2026-03-24
**Domain:** SwiftUI iOS app project creation, MVVM + @Observable, SwiftData persistence, game-loop UI
**Confidence:** HIGH

## Summary

Phase 2 creates the iOS app project from scratch and delivers the MVP strategy training loop. The technical surface covers five domains: (1) Xcode project creation with a local Swift Package dependency (BJSCore), (2) MVVM architecture using `@Observable` ViewModels with SwiftUI views, (3) SwiftData schema for session persistence, (4) a game-loop interaction pattern (deal-decide-feedback-repeat), and (5) feedback overlay animations.

The BJSCore package provides a complete domain layer. The key integration point is `StrategyTable.action(for:dealerUpcard:rules:)` which returns the correct `Action` for any `BlackjackHand` state. The trainer ViewModel orchestrates the game loop: deal from `Shoe`, present the hand, accept user input, look up the correct action, show feedback, play out the hand, and accumulate session statistics. All domain types (`Card`, `Rank`, `Suit`, `BlackjackHand`, `Shoe`, `BlackjackRules`, `Action`, `StrategyEngine`, `StrategyTable`) are public and `Sendable`.

No Xcode GUI app is installed on this machine -- only Swift 6.2 Command Line Tools. The project `.xcodeproj` must be generated using XcodeGen (installable via Homebrew) from a `project.yml` spec, or created manually via Xcode on another machine. XcodeGen is the recommended approach since it keeps the project definition in version control as a YAML file.

**Primary recommendation:** Use XcodeGen to create the `.xcodeproj` from a declarative spec. Structure the app as MVVM with `@Observable` ViewModels owned by `@State` at screen level and shared via `.environment()`. Use a `TabView` with `NavigationStack` per tab to accommodate future phases (Hi-Lo, Edge Calculator). SwiftData models should be flat: `TrainingSession` owns `SessionDecision` records via cascade relationship.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Cards use minimal text style -- clean white/dark rectangle with rank + suit symbol in text (e.g., `A heart`, `10 club`). No pip layout, no full face rendering.
- **D-02:** Suits are color-coded: red for hearts/diamonds, black/dark for clubs/spades.
- **D-03:** Play area uses standard vertical layout: dealer hand at top (one card face-up, one face-down), player hand in the middle, action buttons below the player hand.
- **D-04:** Feedback is a color flash overlay with a label: green "Correct" or red "Incorrect -- Should: [Action]" displayed for ~1 second, then auto-advances. No tap-to-dismiss required for correct decisions. Fast pacing.
- **D-05:** After the feedback flash, the hand plays out fully -- dealer draws to completion, win/loss/push result is briefly shown before the next hand begins.
- **D-06:** Feedback triggers on every individual decision in a hand (not just the opening action). If a user hits twice then stands, each decision is evaluated against the correct strategy for that state.
- **D-07:** Sessions are open-ended -- the user plays as many hands as they want and taps "End Session" to stop. No fixed hand count.
- **D-08:** Learn mode vs Test mode is selected on a pre-session start screen. Can't switch modes mid-session.
- **D-09:** Mid-session inline stats are always visible: accuracy %, hand count, error count. Compact display.
- **D-10:** End-of-session summary replaces the play area inline (no modal). Shows: hands played, accuracy %, error count, best streak, and mistake log. Includes [Play Again] and [Home] actions.
- **D-11:** Rule configuration accessible from pre-session start screen and via settings icon during play. Rules persist across sessions until changed.
- **D-12:** Ship with 1-2 standard presets + "Custom" option. Exact presets are Claude's discretion.
- **D-13:** Custom rule editing as a SwiftUI Form (sheet or push screen) with toggles and pickers.

### Claude's Discretion
- Exact animation duration/style for feedback flash (1 second is a reasonable target)
- Navigation structure (TabView vs NavigationStack vs sheet-based)
- App color scheme and typography details within "clean, premium, analytical" constraint
- Exact SwiftData model schema and relationship design for session persistence
- Xcode project setup: how BJSCore is linked as a local package dependency
- Exact preset names and rule configurations for the 1-2 built-in presets

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STRAT-01 | User can simulate blackjack hands under active BlackjackRules | Shoe, BlackjackHand, BlackjackRules from BJSCore; TrainerViewModel game loop |
| STRAT-02 | App evaluates each decision against correct basic strategy for active rules | StrategyTable.action(for:dealerUpcard:rules:) + mid-hand action mapping |
| STRAT-03 | Correct/incorrect feedback immediately after each decision, before hand outcome | Feedback overlay animation pattern with withAnimation + Task.sleep |
| STRAT-04 | Track decision accuracy percentage and per-mistake log per session | SessionDecision SwiftData model; ViewModel accumulates stats |
| STRAT-05 | Learn mode displays correct action before user input | TrainerViewModel.mode flag; Learn mode shows hint label before action buttons |
| STRAT-06 | Test mode drills without hints | Same ViewModel, hint label hidden |
| RULE-03 | Casino presets pre-fill rule configuration form | CasinoPreset enum with static BlackjackRules instances; UserDefaults persistence |
| PROG-01 | Session results persisted locally on-device using SwiftData | TrainingSession + SessionDecision @Model classes; ModelContainer in App |
| PROG-02 | Per-session summary: accuracy %, error count, streak | Computed from SessionDecision records; end-of-session view |
| ARCH-03 | All core features work fully offline | No networking code; BJSCore is pure Swift; SwiftData is local SQLite |
| ARCH-04 | User progress persisted on-device only, no cloud sync | SwiftData without CloudKit; no iCloud container |
</phase_requirements>

## Standard Stack

### Core (already decided in CLAUDE.md)
| Technology | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift | 6.2.x | Language | Installed: 6.2.4. MainActor-by-default simplifies ViewModel code. |
| SwiftUI | iOS 18+ | UI layer | Declarative views, `@Observable` integration, built-in animations. |
| SwiftData | iOS 18+ | Persistence | `@Model` classes with `@Query` for reactive data in views. Local SQLite, offline-first. |
| XcodeGen | 2.42+ | Project generation | Generates `.xcodeproj` from YAML spec. Required since no Xcode GUI is installed on this machine. |

### Supporting
| Technology | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| BJSCore | local package | Domain layer | All blackjack logic: Shoe, BlackjackHand, StrategyEngine, BlackjackRules, Action |
| @AppStorage | Built-in | Settings persistence | Active BlackjackRules config, UI preferences, selected preset |
| Core Haptics | Built-in | Tactile feedback | Correct/incorrect decision haptic pulses |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| XcodeGen | Manual Xcode project | Cannot be created without Xcode GUI; XcodeGen keeps project definition in version control |
| SwiftData | UserDefaults for sessions | UserDefaults can't handle growing structured data; SwiftData provides queries and aggregations |
| TabView | Single NavigationStack | TabView accommodates Phases 3-6 adding tabs; avoids future refactor |

**Installation:**
```bash
brew install xcodegen
```

No other external dependencies. BJSCore is a local Swift package already at `./BJSCore/`.

## Architecture Patterns

### Recommended Project Structure
```
BJS/
├── BJSCore/                    # Existing local Swift package (Phase 1 output)
│   ├── Package.swift
│   ├── Sources/BJSCore/
│   └── Tests/BJSCoreTests/
├── BJS/                        # iOS app source directory
│   ├── App/
│   │   └── BJSApp.swift        # @main, ModelContainer, root TabView
│   ├── Models/                 # SwiftData @Model classes
│   │   ├── TrainingSession.swift
│   │   └── SessionDecision.swift
│   ├── ViewModels/
│   │   ├── TrainerViewModel.swift
│   │   └── RulesViewModel.swift
│   ├── Views/
│   │   ├── Trainer/
│   │   │   ├── TrainerView.swift          # Main training screen
│   │   │   ├── SessionStartView.swift     # Pre-session: mode + rules + start
│   │   │   ├── SessionSummaryView.swift   # End-of-session inline summary
│   │   │   ├── CardView.swift             # Single card display component
│   │   │   ├── HandView.swift             # Row of cards
│   │   │   ├── ActionButtonsView.swift    # Hit/Stand/Double/Split/Surrender
│   │   │   └── FeedbackOverlayView.swift  # Color flash overlay
│   │   ├── Rules/
│   │   │   ├── RuleConfigView.swift       # SwiftUI Form for rule editing
│   │   │   └── PresetPickerView.swift     # Casino preset selector
│   │   └── Common/
│   │       └── StatsBarView.swift         # Inline accuracy/hands/errors display
│   ├── Utilities/
│   │   └── CasinoPreset.swift             # Preset enum with static rules
│   └── Assets.xcassets
├── BJSTests/                   # Swift Testing unit tests
│   ├── TrainerViewModelTests.swift
│   └── RulesViewModelTests.swift
├── project.yml                 # XcodeGen spec
└── .gitignore                  # Include *.xcodeproj if using XcodeGen
```

### Pattern 1: @Observable ViewModel with @State Ownership
**What:** Each screen-level view owns its ViewModel via `@State`. Shared state flows via `.environment()`.
**When to use:** Every screen that has non-trivial logic (TrainerView, SessionStartView).
**Example:**
```swift
// Source: Apple docs + nilcoalescing.com/blog/ObservableInSwiftUI/
@Observable
class TrainerViewModel {
    var currentHand: BlackjackHand?
    var dealerUpcard: Card?
    var dealerHand: BlackjackHand?
    var feedbackState: FeedbackState?
    var sessionStats: SessionStats = SessionStats()
    var phase: TrainerPhase = .dealing
    // ...
}

struct TrainerView: View {
    @State private var viewModel = TrainerViewModel()

    var body: some View {
        // View reads only the properties it needs
        // Fine-grained reactivity: only re-renders when read properties change
    }
}
```

### Pattern 2: Game Loop State Machine
**What:** The training loop is modeled as a state machine with explicit phases.
**When to use:** The core training interaction (deal -> decide -> feedback -> play-out -> next hand).
**Example:**
```swift
enum TrainerPhase {
    case preSession          // Selecting mode/rules
    case dealing             // Cards being dealt
    case awaitingDecision    // Player sees hand, must act
    case showingFeedback     // Color overlay visible (~1 sec)
    case playingOut          // Dealer draws to completion
    case showingResult       // Win/loss/push briefly shown
    case sessionSummary      // End-of-session stats
}
```

### Pattern 3: Feedback Overlay with Auto-Dismiss
**What:** A color overlay appears for ~1 second then auto-advances using Task.sleep.
**When to use:** After each player decision (D-04).
**Example:**
```swift
// Source: hackingwithswift.com animation patterns + Apple docs
func showFeedback(_ result: FeedbackResult) {
    withAnimation(.easeIn(duration: 0.15)) {
        feedbackState = result
        phase = .showingFeedback
    }
    Task {
        try? await Task.sleep(for: .seconds(1.0))
        withAnimation(.easeOut(duration: 0.2)) {
            feedbackState = nil
            phase = .playingOut
        }
    }
}
```

### Pattern 4: SwiftData ModelContainer at App Level
**What:** Create the ModelContainer once in the `@main` App struct and pass to views.
**When to use:** App entry point.
**Example:**
```swift
@main
struct BJSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TrainingSession.self, SessionDecision.self])
    }
}
```

### Pattern 5: @Bindable for Two-Way Bindings
**What:** Use `@Bindable` to create bindings from `@Observable` objects for SwiftUI controls.
**When to use:** Forms, toggles, pickers in rule configuration.
**Example:**
```swift
struct RuleConfigView: View {
    @Environment(RulesViewModel.self) private var rulesVM

    var body: some View {
        @Bindable var rulesVM = rulesVM
        Form {
            Picker("Decks", selection: $rulesVM.rules.deckCount) {
                ForEach(BlackjackRules.DeckCount.allCases, id: \.self) { count in
                    Text("\(count.rawValue)").tag(count)
                }
            }
        }
    }
}
```

### Anti-Patterns to Avoid
- **Putting game logic in views:** All dealing, evaluation, and state transitions belong in TrainerViewModel, not in view body closures.
- **Using ObservableObject/@Published:** Legacy pattern. Use `@Observable` macro exclusively per CLAUDE.md.
- **Modal sheets for session summary:** D-10 explicitly says "replaces play area inline (no modal)."
- **Hardcoded single strategy table:** ARCH-02 requires strategy derived from active rules at runtime. Always use `StrategyEngine.strategy(for: rules)`.
- **Networking or cloud sync:** ARCH-03 and ARCH-04 prohibit network dependencies.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Xcode project file | Hand-edit .xcodeproj XML/plist | XcodeGen from `project.yml` | .xcodeproj is binary/complex; XcodeGen is declarative and version-controllable |
| Strategy evaluation | Custom decision logic in ViewModel | `StrategyTable.action(for:dealerUpcard:rules:)` from BJSCore | Already built, tested, and validated against WoO in Phase 1 |
| Card shuffling / dealing | Custom random card generation | `Shoe` from BJSCore | Handles multi-deck, penetration, reshuffle detection |
| Hand total computation | Manual ace/total logic | `BlackjackHand.total`, `.isSoft`, `.isBust` from BJSCore | Edge cases (multiple aces, soft-to-hard transitions) already handled |
| Session persistence schema | Raw file I/O or UserDefaults arrays | SwiftData `@Model` classes | Queryable, relational, survives schema evolution |
| Timed auto-dismiss | Timer/DispatchQueue | `Task.sleep(for:)` in async context | Modern Swift concurrency; cleaner than Timer callbacks |

**Key insight:** The entire domain layer (rules, strategy, cards, shoe) is complete in BJSCore. Phase 2's job is purely UI orchestration and persistence -- zero blackjack logic should be written in the app target.

## Critical Integration Detail: Mid-Hand Decision Evaluation

`StrategyTable.action(for:dealerUpcard:rules:)` returns the optimal action for any hand state, including after hits. However, there is a subtlety the ViewModel must handle:

**After a hit (3+ cards), the table may return `.double` or `.surrender` for the hand's total, but those actions are only available on the initial 2-card hand.** The ViewModel must map the table's recommendation to the available actions:

| Table Says | Cards > 2 | Correct Action for Player |
|-----------|-----------|--------------------------|
| `.hit` | any | `.hit` |
| `.stand` | any | `.stand` |
| `.double` | 3+ cards | `.hit` (double = "hit with extra bet"; the hitting part is still correct) |
| `.surrender` | 3+ cards | `.hit` (surrender unavailable; hitting is the next-best action for surrender hands) |
| `.split` | 3+ cards | N/A (can't have a pair with 3+ cards) |

This mapping is needed both for (a) determining the correct action to evaluate the player against, and (b) filtering the action buttons shown to the player (don't show Double/Split/Surrender buttons when unavailable).

`BlackjackHand` already provides `canDouble(rules:)`, `canSplit(rules:currentSplitCount:)`, and `canSurrender(rules:)` -- these return `false` for 3+ card hands. Use these to filter available actions.

## SwiftData Schema Design

### Recommended Models

```swift
import SwiftData
import BJSCore

@Model
class TrainingSession {
    var startDate: Date
    var endDate: Date?
    var mode: String  // "learn" or "test" -- store as String for SwiftData compatibility
    var rulesJSON: Data  // BlackjackRules encoded as JSON (Codable)

    @Relationship(deleteRule: .cascade, inverse: \SessionDecision.session)
    var decisions: [SessionDecision]

    // Computed summary properties (not stored, computed from decisions)
    var totalDecisions: Int { decisions.count }
    var correctDecisions: Int { decisions.filter(\.isCorrect).count }
    var accuracyPercentage: Double {
        guard totalDecisions > 0 else { return 0 }
        return Double(correctDecisions) / Double(totalDecisions) * 100
    }
}

@Model
class SessionDecision {
    var session: TrainingSession?
    var timestamp: Date
    var handDescription: String     // e.g., "Soft 18 vs 9"
    var playerAction: String        // Action.rawValue
    var correctAction: String       // Action.rawValue
    var isCorrect: Bool
    var handNumber: Int             // Which hand in the session
}
```

### Design Rationale
- **TrainingSession -> SessionDecision** is a one-to-many cascade relationship. Deleting a session deletes all its decisions.
- **rulesJSON** stores the `BlackjackRules` as encoded JSON `Data` rather than flattening 10+ properties into columns. `BlackjackRules` is already `Codable`. This avoids schema complexity and makes it trivial to reconstruct the rules for display.
- **Action stored as String** because SwiftData does not support custom enums from external packages as model properties. Store `.rawValue`, reconstruct with `Action(rawValue:)`.
- **handDescription** as a pre-formatted string (e.g., "Soft 18 vs 9") for the mistake log display. Cheaper than storing full card arrays.
- **Computed properties** for accuracy/totals avoid data duplication. For Phase 5 (analytics), these could be cached as stored properties if query performance requires it.
- **endDate is optional** -- set when user taps "End Session".

### Rules Persistence (UserDefaults)
Active `BlackjackRules` and selected preset are stored in `@AppStorage` / `UserDefaults`:
```swift
// Encode BlackjackRules to JSON Data, store as Data in UserDefaults
// Restore on app launch to populate the rule config form
```

## Casino Presets (Claude's Discretion)

Recommended presets:

| Preset | Description | Key Rules |
|--------|-------------|-----------|
| **Vegas Strip** | Standard 6-deck Las Vegas Strip game | 6 deck, S17, 3:2 BJ, DAS, no RSA, no surrender, double any two, American peek |
| **Downtown Vegas** | Common downtown/H17 game | 2 deck, H17, 3:2 BJ, DAS, late surrender, double any two, American peek |
| **Custom** | User edits all fields | Starts from Vegas Strip defaults |

These two presets cover the most common rule variations players encounter. Vegas Strip is the "standard" reference game; Downtown Vegas introduces H17, fewer decks, and surrender -- all meaningful strategy changes.

## Navigation Architecture (Claude's Discretion)

**Recommendation: TabView with NavigationStack per tab.**

Rationale:
- Phase 2 has one feature (Strategy Trainer), but Phases 3 (Hi-Lo), 4 (Edge Calculator), and 5 (Analytics) each add independent screens. A TabView naturally accommodates this.
- Each tab gets its own `NavigationStack` for push navigation within the feature (e.g., rule config pushed from trainer).
- iOS 18 TabView with `.sidebarAdaptable` style works well on iPhone (bottom tabs) and adapts to iPad later.
- Known iOS 18 bug: NavigationStack path-based navigation can double-push in TabView. Mitigation: use `navigationDestination(for:)` with value-based navigation, avoid mixing with `NavigationLink(destination:)`.

**Phase 2 tab structure:**
- Tab 1: **Practice** (Strategy Trainer) -- the only tab in Phase 2
- Future: Tab 2: Counting, Tab 3: Edge, Tab 4: Progress

Start with a single tab. The TabView shell is created now so future phases just add tabs without restructuring navigation.

## Feedback Animation Pattern

Per D-04: color flash overlay for ~1 second, auto-advances.

**Approach:**
1. Overlay a semi-transparent colored view (green/red) on the play area using `.overlay()` modifier.
2. Show/hide with `withAnimation(.easeIn(duration: 0.15))` for snappy appearance.
3. Auto-dismiss after ~1 second using `Task.sleep(for: .seconds(1.0))`.
4. Dismiss with `withAnimation(.easeOut(duration: 0.2))` for smooth fade-out.
5. Total visible time: ~1.0 seconds (configurable via constant).

```swift
struct FeedbackOverlayView: View {
    let result: FeedbackResult  // .correct or .incorrect(correctAction: Action)

    var body: some View {
        VStack {
            Text(result.message)
                .font(.title2.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(result.color.opacity(0.85))
        .transition(.opacity)
    }
}

enum FeedbackResult {
    case correct
    case incorrect(correctAction: Action)

    var message: String {
        switch self {
        case .correct: return "Correct"
        case .incorrect(let action): return "Incorrect -- Should: \(action.rawValue.capitalized)"
        }
    }

    var color: Color {
        switch self {
        case .correct: return .green
        case .incorrect: return .red
        }
    }
}
```

## Hand Play-Out Logic (D-05)

After feedback, the hand must play out:
1. Dealer reveals hole card.
2. Dealer draws according to rules (S17 or H17) -- use `BlackjackHand` total/isSoft logic.
3. Compare totals: win/loss/push.
4. Brief result display (~0.5-1 second), then auto-advance to next hand.
5. If player busted, skip dealer draw (result is already loss).
6. If player surrendered, skip play-out (result is -0.5 units).
7. If player doubled, the double card was already dealt; proceed to dealer.

The dealer draw loop is simple: while total < 17 (or < 18 if H17 and soft 17), deal a card. This logic belongs in the ViewModel, using BJSCore's `BlackjackHand` for total computation and `Shoe` for dealing.

## Swift 6.2 Concurrency Considerations

- **MainActor by default** (with Approachable Concurrency enabled in build settings): ViewModels and Views automatically run on MainActor. No `@MainActor` annotation needed on ViewModel classes.
- **Shoe and BlackjackHand are Sendable structs** -- safe to use from MainActor context.
- **StrategyEngine is `@unchecked Sendable`** with internal NSLock -- thread-safe for concurrent access, but in practice the trainer only uses it from MainActor.
- **Task.sleep for animation timing** -- runs on MainActor, no concurrency issues.
- **Build setting**: Set "Default Actor Isolation" to "MainActor" and "Strict Concurrency Checking" to "Complete" in the XcodeGen project.yml.

## XcodeGen Project Spec

Key elements for `project.yml`:

```yaml
name: BJS
options:
  bundleIdPrefix: com.bjs
  deploymentTarget:
    iOS: "18.0"
  xcodeVersion: "26.3"
settings:
  base:
    SWIFT_VERSION: "6.2"
    SWIFT_STRICT_CONCURRENCY: complete
    # Enable Approachable Concurrency (MainActor by default)
    OTHER_SWIFT_FLAGS: "-enable-upcoming-feature DefaultIsolationMainActor"
targets:
  BJS:
    type: application
    platform: iOS
    sources: [BJS]
    dependencies:
      - package: BJSCore
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.bjs.app
        INFOPLIST_VALUES:
          CFBundleName: BJS
          UILaunchScreen: {}
  BJSTests:
    type: bundle.unit-test
    platform: iOS
    sources: [BJSTests]
    dependencies:
      - target: BJS
packages:
  BJSCore:
    path: ./BJSCore
```

**Note:** The exact `OTHER_SWIFT_FLAGS` for enabling MainActor-by-default may need verification. In Xcode GUI, this is set via Build Settings > "Default Actor Isolation" > MainActor. In XcodeGen, it maps to a Swift compiler flag. The `-enable-upcoming-feature DefaultIsolationMainActor` flag is the Swift 6.2 mechanism, but should be validated during implementation.

## Common Pitfalls

### Pitfall 1: Strategy Table Returns Unavailable Actions
**What goes wrong:** The StrategyTable returns `.double` for a 3+ card hand total, and the ViewModel evaluates the player as "wrong" for hitting instead of doubling.
**Why it happens:** The strategy table is indexed by total, not by card count. It doesn't know whether doubling is available.
**How to avoid:** Always check `hand.canDouble(rules:)`, `hand.canSplit(rules:currentSplitCount:)`, `hand.canSurrender(rules:)` before comparing against the table's recommendation. Map unavailable actions: double -> hit, surrender -> hit.
**Warning signs:** Player flagged as incorrect for hitting a 3-card soft 18.

### Pitfall 2: SwiftData Cascade Delete Not Working
**What goes wrong:** Deleting a `TrainingSession` leaves orphaned `SessionDecision` records.
**Why it happens:** SwiftData cascade deletes have known bugs when `autosave` is disabled or when explicitly calling `modelContext.save()` before the cascade processes.
**How to avoid:** Keep autosave enabled (the default). Use `@Relationship(deleteRule: .cascade, inverse: \SessionDecision.session)` with the explicit inverse. Make `SessionDecision.session` optional (`TrainingSession?`).
**Warning signs:** Orphaned records accumulating in the database over time.

### Pitfall 3: NavigationStack Double-Push in TabView (iOS 18)
**What goes wrong:** Tapping a NavigationLink in a tab pushes the destination view twice.
**Why it happens:** Known iOS 18 regression when using `NavigationStack(path:)` inside TabView.
**How to avoid:** Use `navigationDestination(for:)` with programmatic navigation via the ViewModel's state. Avoid `NavigationLink(destination:)`. Test on device.
**Warning signs:** Views appearing twice, back button showing wrong title.

### Pitfall 4: @Observable ViewModel Recreated on View Redraw
**What goes wrong:** Game state resets unexpectedly because the ViewModel is re-instantiated.
**Why it happens:** The ViewModel is created as a plain property instead of `@State`.
**How to avoid:** Always use `@State private var viewModel = TrainerViewModel()` in the owning view. `@State` caches the instance across view redraws.
**Warning signs:** Session stats resetting to zero, shoe reshuffling unexpectedly.

### Pitfall 5: Encoding BlackjackRules Enums for SwiftData
**What goes wrong:** SwiftData crashes or silently fails to persist custom enum types from an external package.
**Why it happens:** SwiftData's `@Model` macro has limited support for enums from other modules and non-standard Codable types.
**How to avoid:** Store `BlackjackRules` as `Data` (JSON-encoded) in the SwiftData model, not as individual enum properties. Store `Action` values as `String` via `.rawValue`.
**Warning signs:** Runtime crashes on model save, or empty/nil values after fetch.

### Pitfall 6: Shoe Exhaustion Mid-Hand
**What goes wrong:** `Shoe.deal()` returns `nil` during a hand because the shoe ran out.
**Why it happens:** The shoe `needsReshuffle` flag is checked between hands, but a long hand with splits could exhaust remaining cards.
**How to avoid:** Check `shoe.cardsRemaining` before starting a new hand (need at least ~20 cards for worst case). Reshuffle when `needsReshuffle` is true OR remaining cards are dangerously low. Never start a hand if reshuffle is pending.
**Warning signs:** Force-unwrap crash on `shoe.deal()!`.

## Code Examples

### Complete Game Loop (ViewModel Core)
```swift
// Verified patterns from BJSCore API + Apple SwiftUI docs
@Observable
class TrainerViewModel {
    // State
    var phase: TrainerPhase = .preSession
    var mode: TrainingMode = .test
    var playerHand: BlackjackHand?
    var dealerHand: BlackjackHand?
    var dealerUpcard: Card?
    var shoe: Shoe
    var rules: BlackjackRules
    var feedbackState: FeedbackResult?
    var sessionStats = SessionStats()
    var decisions: [DecisionRecord] = []

    private let engine = StrategyEngine()
    private var strategyTable: StrategyTable

    init(rules: BlackjackRules = BlackjackRules()) {
        self.rules = rules
        self.shoe = Shoe(deckCount: rules.deckCount.rawValue)
        self.shoe.shuffle()
        self.strategyTable = engine.strategy(for: rules)
    }

    func updateRules(_ newRules: BlackjackRules) {
        rules = newRules
        shoe = Shoe(deckCount: newRules.deckCount.rawValue)
        shoe.shuffle()
        strategyTable = engine.strategy(for: newRules)
    }

    func dealNewHand() {
        if shoe.needsReshuffle || shoe.cardsRemaining < 20 {
            shoe = Shoe(deckCount: rules.deckCount.rawValue)
            shoe.shuffle()
        }
        let p1 = shoe.deal()!, d1 = shoe.deal()!
        let p2 = shoe.deal()!, d2 = shoe.deal()!
        playerHand = BlackjackHand(cards: [p1, p2])
        dealerHand = BlackjackHand(cards: [d1, d2])
        dealerUpcard = d1
        phase = .awaitingDecision
    }

    func playerAction(_ action: Action) {
        guard let hand = playerHand, let upcard = dealerUpcard else { return }

        // Determine correct action
        let tableAction = strategyTable.action(for: hand, dealerUpcard: upcard.rank, rules: rules)
        let correctAction = mapToAvailableAction(tableAction, hand: hand)
        let isCorrect = (action == correctAction)

        // Record decision
        let record = DecisionRecord(
            handDescription: describeHand(hand, vs: upcard),
            playerAction: action,
            correctAction: correctAction,
            isCorrect: isCorrect
        )
        decisions.append(record)
        sessionStats.recordDecision(isCorrect: isCorrect)

        // Show feedback
        let result: FeedbackResult = isCorrect ? .correct : .incorrect(correctAction: correctAction)
        showFeedback(result)

        // Execute the action on the hand
        executeAction(action)
    }

    private func mapToAvailableAction(_ tableAction: Action, hand: BlackjackHand) -> Action {
        switch tableAction {
        case .double where !hand.canDouble(rules: rules):
            return .hit
        case .surrender where !hand.canSurrender(rules: rules):
            return .hit
        case .split where !hand.canSplit(rules: rules, currentSplitCount: 0):
            return hand.isSoft ? .hit : .stand  // fallback varies
        default:
            return tableAction
        }
    }
}
```

### Card Display View (D-01, D-02)
```swift
struct CardView: View {
    let card: Card
    let faceDown: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(faceDown ? Color.blue.opacity(0.8) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary, lineWidth: 1)
                )

            if !faceDown {
                Text(cardLabel)
                    .font(.title2.monospaced().bold())
                    .foregroundStyle(suitColor)
            }
        }
        .frame(width: 56, height: 80)
    }

    private var cardLabel: String {
        "\(rankSymbol)\(suitSymbol)"
    }

    private var suitColor: Color {
        switch card.suit {
        case .hearts, .diamonds: return .red
        case .clubs, .spades: return .primary
        }
    }

    private var rankSymbol: String {
        switch card.rank {
        case .ace: return "A"
        case .king: return "K"
        case .queen: return "Q"
        case .jack: return "J"
        default: return "\(card.rank.blackjackValue)"  // 2-10
        }
    }

    private var suitSymbol: String {
        switch card.suit {
        case .hearts: return "\u{2665}"    // filled heart
        case .diamonds: return "\u{2666}"  // filled diamond
        case .clubs: return "\u{2663}"     // filled club
        case .spades: return "\u{2660}"    // filled spade
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 / Swift 5.9 | Fine-grained view updates, less boilerplate |
| `@StateObject` / `@ObservedObject` | `@State` / plain property | iOS 17 | Simpler ownership model |
| `@EnvironmentObject` | `.environment()` type-based | iOS 17 | Type-safe environment injection |
| Core Data | SwiftData | iOS 17 | Declarative `@Model`, `@Query` in views |
| Timer for delayed actions | `Task.sleep(for:)` | Swift 5.5+ | Structured concurrency, cancellation |
| Manual `@MainActor` annotations | MainActor-by-default | Swift 6.2 | Less boilerplate for UI-heavy apps |

**Deprecated/outdated:**
- `ObservableObject` protocol: Still works but `@Observable` is the modern path. Do not use.
- `@StateObject` / `@ObservedObject`: Replaced by `@State` for `@Observable` classes.
- `swift package generate-xcodeproj`: Deprecated. Use XcodeGen or Xcode GUI.

## Open Questions

1. **XcodeGen DefaultIsolationMainActor flag**
   - What we know: Swift 6.2 supports MainActor-by-default via build settings. Xcode GUI exposes it as "Default Actor Isolation."
   - What's unclear: The exact `OTHER_SWIFT_FLAGS` string for XcodeGen. It may be `-default-isolation MainActor` or `-enable-upcoming-feature DefaultIsolationMainActor`.
   - Recommendation: Try `-enable-upcoming-feature DefaultIsolationMainActor` first. If it fails, fall back to explicit `@MainActor` on ViewModel classes (minimal overhead).

2. **Split hand handling in Phase 2**
   - What we know: The strategy table recommends splits. `BlackjackHand.canSplit` checks split eligibility.
   - What's unclear: Whether Phase 2 should implement full split handling (two hands playing independently) or just evaluate the split decision and skip actual split play-out.
   - Recommendation: Implement split evaluation (mark correct/incorrect) but simplify play-out -- when the player correctly splits, play out each hand sequentially. This is complex but necessary for D-06 (feedback on every decision). If scope is too large, the planner could defer split play-out to a later phase and just evaluate the initial split/no-split decision.

3. **Rank display for 10-value cards**
   - What we know: `Card.rank` distinguishes `.ten`, `.jack`, `.queen`, `.king`. The `rankSymbol` in CardView should show J/Q/K not just 10.
   - What's unclear: Whether `rank.blackjackValue` (returns 10 for all face cards) is used in the label.
   - Recommendation: Use the rank enum directly (J, Q, K, 10) for display, not `blackjackValue`. This is natural and expected.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Swift | Build/compile | Yes | 6.2.4 | -- |
| Xcode GUI | Project creation (normally) | No | -- | XcodeGen (see below) |
| XcodeGen | Project generation from YAML | No (installable) | -- | `brew install xcodegen` |
| Homebrew | XcodeGen installation | Yes | -- | -- |
| iOS Simulator | UI testing | Unknown (CLT only) | -- | Test on device; unit tests run without simulator |
| xcodebuild | Building .app | No (CLT only, no full Xcode) | -- | Swift build for package tests only; .xcodeproj build requires Xcode |

**Missing dependencies with no fallback:**
- **Xcode GUI or xcodebuild**: Cannot build the iOS .app target without full Xcode installation. The planner should generate all source files and the XcodeGen spec, but actual compilation and on-device testing requires Xcode to be installed. All code will be written correctly but build verification requires Xcode.

**Missing dependencies with fallback:**
- **XcodeGen**: Not installed but available via `brew install xcodegen`. Include installation as a Wave 0 task.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (Xcode 26 built-in) |
| Config file | Generated by XcodeGen in BJSTests target |
| Quick run command | `swift test --package-path BJSCore` (domain tests only -- app tests need Xcode) |
| Full suite command | `xcodebuild test -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STRAT-01 | Simulate hands under active rules | unit (ViewModel) | `xcodebuild test -scheme BJS -only-testing BJSTests/TrainerViewModelTests/testDealNewHand` | No -- Wave 0 |
| STRAT-02 | Evaluate decision against correct strategy | unit (ViewModel) | `xcodebuild test -scheme BJS -only-testing BJSTests/TrainerViewModelTests/testDecisionEvaluation` | No -- Wave 0 |
| STRAT-03 | Feedback before hand outcome | unit (ViewModel) | `xcodebuild test -scheme BJS -only-testing BJSTests/TrainerViewModelTests/testFeedbackPhase` | No -- Wave 0 |
| STRAT-04 | Accuracy tracking + mistake log | unit (ViewModel) | `xcodebuild test -scheme BJS -only-testing BJSTests/TrainerViewModelTests/testSessionStats` | No -- Wave 0 |
| STRAT-05 | Learn mode shows correct action | unit (ViewModel) | `xcodebuild test -scheme BJS -only-testing BJSTests/TrainerViewModelTests/testLearnMode` | No -- Wave 0 |
| STRAT-06 | Test mode no hints | unit (ViewModel) | `xcodebuild test -scheme BJS -only-testing BJSTests/TrainerViewModelTests/testTestMode` | No -- Wave 0 |
| RULE-03 | Presets pre-fill rules | unit | `xcodebuild test -scheme BJS -only-testing BJSTests/CasinoPresetTests` | No -- Wave 0 |
| PROG-01 | SwiftData persistence | unit | `xcodebuild test -scheme BJS -only-testing BJSTests/PersistenceTests` | No -- Wave 0 |
| PROG-02 | Session summary computation | unit (ViewModel) | `xcodebuild test -scheme BJS -only-testing BJSTests/TrainerViewModelTests/testSessionSummary` | No -- Wave 0 |
| ARCH-03 | Offline operation | manual | Verify no network imports, no URLSession usage | N/A -- code review |
| ARCH-04 | On-device only | manual | Verify no CloudKit container, no iCloud entitlements | N/A -- code review |

### Sampling Rate
- **Per task commit:** ViewModel unit tests (if Xcode available)
- **Per wave merge:** Full test suite
- **Phase gate:** All ViewModel tests green, code review for ARCH-03/ARCH-04

### Wave 0 Gaps
- [ ] `BJSTests/TrainerViewModelTests.swift` -- covers STRAT-01 through STRAT-06, PROG-02
- [ ] `BJSTests/CasinoPresetTests.swift` -- covers RULE-03
- [ ] `BJSTests/PersistenceTests.swift` -- covers PROG-01
- [ ] XcodeGen installation: `brew install xcodegen`
- [ ] `project.yml` -- XcodeGen spec defining BJS target, BJSTests target, BJSCore local package

**Note:** ViewModel tests can be written as pure unit tests (no UI, no simulator) since TrainerViewModel operates on BJSCore domain types. SwiftData persistence tests require a ModelContainer but can use in-memory configuration (`ModelConfiguration(isStoredInMemoryOnly: true)`) for fast, simulator-free testing.

## Sources

### Primary (HIGH confidence)
- BJSCore source code at `/Users/luke/BJS/BJSCore/Sources/BJSCore/` -- direct API surface inspection
- [Apple Developer - Managing model data in your app](https://developer.apple.com/documentation/SwiftUI/Managing-model-data-in-your-app) -- @Observable + SwiftUI patterns
- [Apple Developer - SwiftData documentation](https://developer.apple.com/documentation/swiftdata) -- @Model, @Relationship, ModelContainer
- [Apple Developer - Defining data relationships](https://developer.apple.com/documentation/SwiftData/Defining-data-relationships-with-enumerations-and-model-classes) -- SwiftData relationships

### Secondary (MEDIUM confidence)
- [nilcoalescing.com - @Observable in SwiftUI](https://nilcoalescing.com/blog/ObservableInSwiftUI/) -- @State/@Environment/@Bindable patterns verified
- [Hacking with Swift - SwiftData cascade deletes](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-cascade-deletes-using-relationships) -- cascade delete patterns
- [SwiftLee - Approachable Concurrency](https://www.avanderlee.com/concurrency/approachable-concurrency-in-swift-6-2-a-clear-guide/) -- Swift 6.2 MainActor-by-default
- [XcodeGen GitHub](https://github.com/yonaskolb/XcodeGen) -- project.yml spec
- [tanaschita.com - Local Swift Packages in Xcode](https://tanaschita.com/spm-add-local-packages/) -- local package dependency setup

### Tertiary (LOW confidence)
- XcodeGen `OTHER_SWIFT_FLAGS` for DefaultIsolationMainActor -- needs validation at build time
- iOS 18 TabView + NavigationStack double-push bug -- reported on Apple Developer Forums, may be fixed in iOS 18.x point releases

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all technologies are from CLAUDE.md (locked decisions), versions verified on machine
- Architecture: HIGH -- MVVM + @Observable is well-documented, BJSCore API surface inspected directly
- SwiftData schema: MEDIUM -- patterns are well-known but SwiftData has edge cases with external enums and cascade deletes
- XcodeGen setup: MEDIUM -- straightforward tool but exact Swift 6.2 flags need build-time validation
- Pitfalls: HIGH -- identified from direct API inspection (mid-hand action mapping) and documented community issues

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable technologies, 30-day validity)

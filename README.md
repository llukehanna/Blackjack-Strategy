# BJS — Blackjack Training

A native iOS blackjack training app for players who want to get seriously better at the game. Not a casino app, not a gambling app — an educational tool that covers four skill areas:

1. **Basic Strategy** — drill the correct play for every hand against every upcard, with rule-specific feedback (H17 vs S17, DAS, surrender, etc.)
2. **Hi-Lo Card Counting** — count drills from true counts to betting decisions
3. **Casino Rule / House-Edge Analysis** — see how each rule variation shifts the house edge
4. **Full Card-Counting Simulation** — realistic shoe sim to pressure-test strategy under actual conditions

## Why it exists

Every other blackjack trainer I tried either (a) taught generic strategy that was wrong for the table you were actually sitting at, or (b) hid the math behind cartoons. BJS is rule-aware — you configure the exact rules of the casino you're playing and the app adjusts strategy and edge calculations to match.

The product's credibility rests on one thing: the numbers must be right.

## Status

In active development. Today:

- ✅ **Core engine** (rules, hands, decks, strategy tables, Hi-Lo counting, edge calc) — shipped as a separate Swift Package (`BJSCore`) with its own test suite
- ✅ **Strategy Trainer** — hand generation, decision feedback, "Why" explanation sheet, session stats
- ✅ **Rules Configurator** — H17/S17, DAS, RSA, double rules, surrender, deck count, penetration
- 🚧 **UI foundation rebuild** (dark token system, full-bleed trainer views)
- ⏭️ Hi-Lo Practice UI, Edge Calculator UI, Full Shoe Sim, Analytics — engine done, UI in progress

## Stack

- **Swift 6.2 / SwiftUI / SwiftData** — iOS 18+, strict concurrency enabled
- **Xcode 26.3** — required for the 6.2 toolchain
- **MVVM + `@Observable`** — fine-grained reactivity without Combine or TCA
- **Swift Testing** — parameterized tests for strategy correctness across rule combinations
- **Swift Package Manager** — `BJSCore` as a local package; no third-party dependencies
- **XcodeGen** — deterministic `.xcodeproj` from `project.yml`

## Architecture

```
BJSCore/                 — Pure Swift package, no UIKit/SwiftUI. Testable in isolation.
  Sources/BJSCore/
    Strategy/            — Basic strategy tables (rule-variant aware)
    Counting/            — Hi-Lo running/true count
    Edge/                — House-edge math across rule permutations
    Models/              — Card, Deck, Hand, Shoe
  Tests/                 — Swift Testing, parameterized over rule sets

BJS/                     — iOS app shell
  App/                   — Entry point, DI composition
  Views/                 — SwiftUI views (Trainer, Rules, Common)
  ViewModels/            — @Observable VMs (TrainerViewModel, RulesViewModel)
  Domain/                — App-layer domain types (WhyExplanation)
  Models/                — App-layer models (TrainingSession, SessionDecision)
  Design/                — Design tokens (colors, type, spacing)

BJSTests/                — App-level tests (VM state, integration)
design-system/           — Token reference + component playground
```

The split is deliberate: **all math lives in `BJSCore`**, so the rules engine and edge calculator can be tested without booting SwiftUI. That's the part that has to be right.

## Build + run

```bash
brew install xcodegen    # if you don't have it
xcodegen generate        # produces BJS.xcodeproj from project.yml
open BJS.xcodeproj
# Build + run on iPhone 16 simulator (iOS 18+)
```

Tests:

```bash
# BJSCore tests (Swift Testing)
swift test --package-path BJSCore

# App + UI tests (XCTest + Swift Testing)
xcodebuild test -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Design principles

- **Offline-first.** No network dependency for any training mode.
- **Math is the product.** Strategy tables and edge calculations are compile-time constants where possible, unit-tested exhaustively.
- **Rule-specific, always.** The app never displays "generic" strategy — strategy is always resolved against the current rule configuration.
- **No real-money gambling content.** App Store compliant; this is education.

---

iOS only. Desktop not planned.

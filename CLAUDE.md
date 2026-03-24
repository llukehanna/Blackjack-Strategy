<!-- GSD:project-start source:PROJECT.md -->
## Project

**BJS — Blackjack Training App**

A native iOS blackjack training app built in Swift/SwiftUI for users who want to seriously improve at blackjack. It covers four skill areas: basic strategy decision training, Hi-Lo card counting fundamentals, casino rule / house-edge analysis, and full card-counting simulation under realistic conditions. This is an educational training product, not a casino app or gambling product.

**Core Value:** Users make correct blackjack decisions faster and with more confidence — the app must always give accurate, rule-specific feedback that makes players measurably better.

### Constraints

- **Tech Stack**: Swift + SwiftUI + Xcode only — no cross-platform, no web, no backend required for v1
- **Platform**: iPhone first — iPad and other platforms deferred
- **Distribution**: App Store (consumer iOS app) — must comply with App Store guidelines; no real-money gambling content
- **Offline**: Core features must work fully offline — no network dependency for training modes
- **Accuracy**: Basic strategy tables and house edge calculations must be mathematically correct — this is the product's credibility
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Platform
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Swift | 6.2.x | Language | Current stable (ships with Xcode 26.3). Swift 6.2 "Approachable Concurrency" simplifies strict concurrency with MainActor-by-default, reducing boilerplate for a UI-heavy app. |
| SwiftUI | iOS 18+ framework | UI layer | Declarative, animation-friendly, first-class Apple support. Card flip animations via `rotation3DEffect`, smooth transitions, and the `@Observable` macro all land cleanly. |
| Xcode | 26.3 | IDE / build | Current stable. Required for App Store submission (Apple mandates Xcode 26+ SDK from April 2026). |
### Architecture Pattern
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| MVVM + `@Observable` | N/A (built-in) | App architecture | The right fit for this app's complexity level. See detailed rationale below. |
#### Why MVVM with @Observable (not TCA, not "plain SwiftUI")
- **Fine-grained reactivity**: Views only re-render when properties they actually read change, unlike `ObservableObject` which re-rendered on any `@Published` change.
- **Less boilerplate**: No `@Published` wrappers, no `@StateObject` vs `@ObservedObject` confusion. Just `@State` for owned instances, `@Environment` for shared ones.
- **Native integration**: Works directly with SwiftData, SwiftUI, and Swift concurrency.
- TCA adds significant learning curve and conceptual overhead (Reducers, Effects, Stores, Actions) for a single-developer project.
- This app has straightforward state: game state (current hand, deck, count), user settings, and session statistics. No complex cross-feature state synchronization.
- TCA's Redux-style full-state diffing conflicts with SwiftUI's built-in optimization; `@Observable` aligns with how SwiftUI actually works.
- TCA is best justified for large teams needing enforced consistency. For a solo/small-team app with well-defined domains, MVVM + `@Observable` is simpler and performs better.
- The blackjack rules engine, strategy evaluator, and statistics tracker have non-trivial logic that must be unit-testable independent of UI.
- ViewModels provide a clean boundary between the domain logic layer and SwiftUI views.
- The project requirement explicitly calls for "core rules engine fully independent from UI layer."
#### Recommended Layer Structure
### Data Persistence
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| SwiftData | iOS 18 SDK | Structured persistence (session history, statistics, user progress) | Apple's modern persistence, SwiftUI-native, declarative `@Model` classes. Replaces Core Data for new projects. |
| UserDefaults / @AppStorage | Built-in | Simple key-value settings (rule configurations, preferences, UI state) | Perfect for small, flat settings. No schema needed. `@AppStorage` integrates directly with SwiftUI. |
#### Why SwiftData (not Core Data, not SQLite, not files)
- **SwiftUI integration**: `@Query` macro fetches data reactively in views. `@Model` classes work with `@Observable` naturally.
- **Greenfield advantage**: No legacy Core Data baggage. SwiftData is the recommended path for new projects targeting iOS 17+.
- **Sufficient for this app**: Session stats, progress tracking, and historical data are simple relational models. SwiftData handles this easily.
- **Offline-first by default**: Local SQLite under the hood, no network required.
#### What goes where
| Data | Storage | Rationale |
|------|---------|-----------|
| Casino rule presets | UserDefaults / @AppStorage | Small, flat key-value pairs. User picks from presets or configures custom rules. |
| Session history (per-drill results) | SwiftData | Structured, queryable, grows over time. Need aggregations for progress tracking. |
| Cumulative statistics | SwiftData | Derived from sessions but cached for quick display. |
| UI preferences (theme, speed settings) | UserDefaults / @AppStorage | Trivial key-value, no schema needed. |
| Basic strategy tables | Hardcoded Swift constants | These are mathematical lookup tables, not user data. Compile-time constants for correctness and speed. |
#### Known SwiftData caution
### Testing
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Swift Testing | Built-in (Xcode 26) | Unit tests for domain logic, ViewModels | Apple's modern test framework. Cleaner syntax (`@Test`, `#expect`), parameterized tests, parallel by default. Ideal for testing strategy tables across many rule combinations. |
| XCTest | Built-in | UI tests, performance tests | Swift Testing does not support UI automation or performance benchmarks. XCTest remains necessary for these. |
#### Testing strategy for this app
- **Domain layer (rules engine, strategy evaluator, edge calculator)**: Swift Testing with parameterized tests. Example: `@Test(arguments: ruleVariations)` to verify correct strategy across S17/H17, DAS/no-DAS, etc. This is the most critical test surface -- mathematical correctness is the product's value proposition.
- **ViewModels**: Swift Testing for state transitions and user interaction flows.
- **UI**: XCTest UI tests for critical flows only (launch, complete a drill, view stats). Keep lightweight.
- **No snapshot testing needed**: The UI is functional, not pixel-perfect branded. Standard UI tests suffice.
### Dependency Management
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Swift Package Manager (SPM) | Built-in | Dependency management | The standard. Integrated into Xcode, no Ruby/gems, no `.xcworkspace` hacks. CocoaPods is legacy. |
### Third-Party Dependencies
| Category | Recommendation | Rationale |
|----------|---------------|-----------|
| Blackjack rules/logic | **Build from scratch** | No production-quality Swift blackjack library exists. GitHub projects (sameertotey/BlackJack, willsaid/blackjack) are hobby projects, not maintained, and lack configurable rule sets. The rules engine is the core IP of this app. |
| Card counting logic | **Build from scratch** | Hi-Lo is a simple +1/0/-1 mapping. No library needed. |
| House edge calculation | **Build from scratch** | Mathematical formulas specific to rule variations. This is a differentiator; must be owned. |
| Statistics/charts | **Swift Charts** (Apple, built-in) | First-party framework, no dependency. Sufficient for progress charts and accuracy trends. |
| Animations | **SwiftUI built-in** | `rotation3DEffect` for card flips, `.animation()` and `withAnimation` for transitions. No third-party animation library needed. |
| Haptics | **Core Haptics** (Apple, built-in) | Subtle feedback on correct/incorrect decisions. Built-in framework. |
| Networking | **None** | Offline-first app. No networking layer needed for v1. |
| Analytics | **None for v1** | Defer until post-launch. If needed later, use Apple's built-in App Analytics or a lightweight solution. |
#### Libraries explicitly NOT recommended
| Library | Why Not |
|---------|---------|
| The Composable Architecture (TCA) | Overkill for this app's complexity. See architecture section above. |
| Combine | Legacy reactive framework. `@Observable` + async/await replaces Combine for new SwiftUI code. |
| Realm / GRDB | Unnecessary given SwiftData. Adding a third-party persistence layer adds complexity without benefit for this data model. |
| Lottie | No complex animations needed. SwiftUI's built-in animation system handles card flips and transitions. |
| SnapKit / layout libraries | SwiftUI's layout system is sufficient. These are UIKit-era tools. |
| Firebase | No backend needed. Offline-first. |
| Alamofire / networking libraries | No networking needed for v1. |
## Installation / Project Setup
# No external dependencies to install.
# Project setup is Xcode-only:
# 1. Create new Xcode project
#    - iOS App template
#    - SwiftUI interface
#    - Swift language
#    - SwiftData storage (checkbox in project creation)
# 2. Configure project settings
#    - Deployment target: iOS 18.0
#    - Swift Language Version: 6 (with Approachable Concurrency enabled)
#    - Strict Concurrency Checking: Complete
# 3. Enable Swift Testing
#    - Test target uses Swift Testing by default in Xcode 26
#    - Keep XCTest target for UI tests
## Alternatives Considered
| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Architecture | MVVM + @Observable | TCA | Overkill for solo/small-team, single-domain app. Adds learning curve without proportional benefit. |
| Architecture | MVVM + @Observable | Plain @State in views | Rules engine logic is too complex to live in views. Testability requires separation. |
| Persistence | SwiftData | Core Data | Legacy API, more boilerplate, not SwiftUI-native. No advantage for a new project. |
| Persistence | SwiftData | SQLite (raw) | Too low-level. SwiftData provides the ORM layer this app needs. |
| Persistence | SwiftData | Realm | Third-party dependency for no gain over SwiftData. |
| Testing | Swift Testing | XCTest only | Swift Testing's parameterized tests are ideal for verifying strategy across rule variations. |
| UI | SwiftUI | UIKit | No reason to use UIKit for a greenfield app in 2026. SwiftUI covers all needs. |
| UI | SwiftUI | SpriteKit | This is a training tool, not a visual casino game. Standard UI components suffice. |
| Concurrency | Swift 6.2 async/await | Combine | Combine is effectively legacy for new SwiftUI code. async/await is simpler and first-class. |
| Package manager | SPM | CocoaPods | CocoaPods is legacy, requires Ruby, adds workspace complexity. |
## Swift 6 Concurrency Notes
- **MainActor by default**: UI code runs on MainActor without explicit annotation. This simplifies ViewModel code significantly.
- **Strict concurrency checking**: Catches data races at compile time. Enable from day one to avoid migration pain later.
- **async/await for background work**: Use for any heavy computation (e.g., running thousands of simulated hands for edge calculation). Keep domain logic `Sendable` where possible.
## Sources
- [Apple Developer - Xcode Support](https://developer.apple.com/support/xcode/) -- Xcode 26.3 / Swift 6.2.3 versions
- [Apple Developer - SwiftUI What's New](https://developer.apple.com/swiftui/whats-new/) -- iOS 18/19 SwiftUI features
- [Apple Developer - Swift Testing](https://developer.apple.com/xcode/swift-testing/) -- Swift Testing framework
- [Apple Developer - SwiftData](https://developer.apple.com/documentation/swiftdata) -- SwiftData documentation
- [Apple Developer - Migrating to Observable](https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro) -- @Observable migration guide
- [Apple Developer - Adopting Swift 6](https://developer.apple.com/documentation/swift/adoptingswift6) -- Strict concurrency adoption
- [Apple Developer - SDK Requirements](https://developer.apple.com/news/upcoming-requirements/?id=02212025a) -- App Store submission requirements
- [SwiftLee - Approachable Concurrency](https://www.avanderlee.com/concurrency/approachable-concurrency-in-swift-6-2-a-clear-guide/) -- Swift 6.2 concurrency guide
- [SwiftLee - Minimum iOS Version](https://www.avanderlee.com/workflow/minimum-ios-version/) -- Deployment target guidance
- [Xcode Releases](https://xcodereleases.com/) -- Version history
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->

# Project Research Summary

**Project:** BJS — Blackjack Training App
**Domain:** iOS educational training app (basic strategy, card counting, house edge analysis)
**Researched:** 2026-03-24
**Confidence:** HIGH

## Executive Summary

BJS is a solo-use, offline-first iOS training tool targeting serious blackjack players who want to internalize basic strategy, practice Hi-Lo card counting, and understand the math behind rule variations. Research across four domains converges on a clear build approach: a pure Swift domain core (BJSCore) packaged as a local Swift Package, isolated from UI, sitting beneath a thin MVVM layer built on `@Observable`. The stack is entirely first-party Apple frameworks — Swift 6.2, SwiftUI, SwiftData, Swift Testing — with zero third-party dependencies. This is the right call for a domain this well-defined; it maximizes testability, minimizes risk, and eliminates dependency maintenance overhead.

The market gap is real and specific: no existing app cleanly integrates all four pillars (rule-aware basic strategy, Hi-Lo counting, true count conversion, house edge calculation) under one rule configuration. Competitors either focus on one area or sacrifice correctness for convenience. The single most important architectural decision — and the primary source of failure risk — is the strategy engine. Basic strategy is not one table; it is a family of tables that shifts meaningfully with rule variations (S17/H17 alone changes roughly a dozen plays). Building a hardcoded single-ruleset engine is the single fastest way to destroy product credibility. The strategy engine must be rule-parameterized from commit one.

The main risks are mathematical correctness risks, not technical risks. The stack is mature and well-understood. The danger lies in subtle domain bugs: wrong strategy cells for non-default rule sets, integer division in true count calculation, house edge deltas sourced from unreliable references, and feedback systems that conflate decision quality with hand outcome. Mitigation is straightforward: test every strategy cell against the Wizard of Odds calculator across at least ten rule combinations, write invariant tests for shoe state, and validate the edge calculator against external references before shipping. The build order enforces correctness by requiring the core engine to be verified before any UI is built on top of it.

---

## Key Findings

### Recommended Stack

The stack is all first-party and current. Swift 6.2 with "Approachable Concurrency" (MainActor-by-default) ships with Xcode 26.3 and is the right language version for a UI-heavy app. iOS 18 is the minimum deployment target — it satisfies App Store SDK requirements, ensures SwiftData stability (iOS 17 had breaking changes), and will represent well above 90% adoption by the time BJS ships. There are no third-party dependencies. Every feature the app needs — UI, persistence, charts, haptics, animations, testing — is covered by Apple's built-in frameworks.

**Core technologies:**
- Swift 6.2 / Xcode 26.3: Language and IDE — current stable, required for App Store submission after April 2026
- SwiftUI (iOS 18+): UI layer — declarative, animation-friendly, native `@Observable` integration
- MVVM + `@Observable`: Architecture pattern — fine-grained reactivity, no `@Published` boilerplate, ViewModels testable without a simulator
- SwiftData: Structured persistence (session history, progress) — SwiftUI-native, replaces Core Data for new projects
- UserDefaults / `@AppStorage`: Settings storage — flat key-value, no schema needed
- Swift Testing: Domain unit tests — parameterized tests are ideal for verifying strategy across rule variations
- Swift Package Manager: Dependency management — integrated, no third-party tooling required
- Swift Charts: Progress visualization — first-party, no dependency needed
- Core Haptics: Drill feedback — built-in, subtle tactile signals for correct/incorrect decisions

### Expected Features

All four research files agree on the dependency chain: rules configuration is the foundation, strategy engine is the credibility feature, counting is the next layer, and the full simulation is the capstone. The market gap is integration, not invention.

**Must have (table stakes):**
- Rule-configurable basic strategy feedback — users expect this to be correct for their specific rule set, not a generic chart
- Configurable casino rules — at minimum: deck count (1-8), S17/H17, DAS, RSA, late surrender, BJ payout (3:2 vs 6:5)
- Running count practice (Hi-Lo) — single card and multi-card group modes
- True count conversion drills — TC = RC / decks remaining, configurable deck count
- Session accuracy tracking — percentage correct, streaks, per-session summaries
- Offline functionality — all core features work without network
- Speed control for drills — adjustable pace from slow learning to sub-1s speed mode
- Clean, analytical UI — not casino-themed; "fitness tracker for blackjack" not "slot machine"

**Should have (competitive differentiators):**
- Integrated house edge calculator — currently only available as a separate web tool; in-app integration sharing the same rule config is a genuine differentiator
- Rule-aware strategy engine — generates correct strategy per rule set, not a hardcoded single table; this is the primary credibility feature
- Weak-spot targeting / adaptive practice — weight drills toward the hand types where the user makes the most errors
- Performance analytics dashboard — accuracy breakdowns by hand type (hard/soft/pair) and by true count; improvement trends over time
- Casino rule presets — pre-configured named rule sets for common venues; reduces setup friction
- Bet spread practice with EV feedback — given a true count, user selects bet size; app grades against optimal spread
- Full shoe counting simulation — combines running count, true count, bet sizing, and strategy decisions across a complete shoe

**Defer (v2+):**
- Multiple counting systems (KO, Omega II, Zen, etc.) — Hi-Lo covers 90%+ of counters; scope explosion without proportional value
- Deviation index cards (Illustrious 18, Fab 4) — valuable but requires full simulation to be in place first
- Casino noise / distraction simulation — nice-to-have, not core
- Bet spread EV analysis (detailed) — refine after core simulation works
- Composition-dependent strategy — small benefit (0.036% for single deck); label as "total-dependent" in v1, architecture should allow future extension

### Architecture Approach

The single most consequential architectural decision is packaging all blackjack logic in a local Swift Package (`BJSCore`) with zero UI imports. This enforces the domain/UI boundary at the compiler level: BJSCore cannot reference SwiftUI, tests run without a simulator, and the logic becomes portable to macOS or watchOS without modification. Above this package, the app uses MVVM with one `@Observable` ViewModel per feature screen. Features (Strategy Trainer, Hi-Lo Practice, Edge Calculator, Simulator) are largely independent tabs sharing only two injected dependencies: a `RuleSet` value (sourced from UserDefaults) and a `ProgressStore` protocol (backed by SwiftData).

**Major components:**
1. `BJSCore / Models` — `Card`, `Hand`, `Shoe`, `RuleSet`, `Action` as pure Swift structs/enums; shared foundation for all engines
2. `BJSCore / RulesEngine` — card dealing, hand evaluation, game flow, bust detection, payout; required by Strategy Trainer and Simulator
3. `BJSCore / StrategyEngine` — rule-parameterized lookup tables returning correct `Action` for any hand/upcard/ruleset combination; the credibility engine
4. `BJSCore / CountingEngine` — Hi-Lo value assignment, running count tracking, true count calculation; pure functions
5. `BJSCore / EdgeCalculator` — additive rule-effect model (validated against Wizard of Odds); accepts `RuleSet`, returns edge percentage and quality rating
6. `App / ViewModels` — one `@Observable` class per feature screen; owns UI state, orchestrates engine calls, handles async persistence
7. `App / Views` — thin SwiftUI views; render ViewModel state, capture user input, animate transitions independently of game logic
8. `App / Persistence` — `SwiftDataProgressStore` implementing `ProgressStoring` protocol; `SessionRecord` and `ProgressSnapshot` models

### Critical Pitfalls

1. **Hardcoded single-ruleset strategy table** — destroys product credibility; rule-parameterize the engine from day one; validate every strategy cell against Wizard of Odds for at least 10 rule combinations; never acceptable to ship a hardcoded table
2. **Decision feedback conflates outcome with correctness** — teaches the wrong mental model; evaluate decisions strictly against the strategy table before the hand resolves; decision accuracy (not win/loss ratio) is the primary metric
3. **Wrong true count calculation** — always use floating-point division: `trueCount = Double(runningCount) / (Double(cardsRemaining) / 52.0)`; write invariant tests: end-of-shoe running count must equal zero; TC must never be an integer
4. **House edge calculator sourced from wrong references** — use Wizard of Odds rule-effect deltas as the authoritative source; cross-validate output against the Wizard of Odds online calculator for 10+ rule sets before shipping; acceptable precision is 0.01%, not 0.001%
5. **App Store rejection under Guideline 5.3** — analytical UI design (already specified) and explicit educational positioning in all metadata are non-negotiable; no casino-themed imagery; no gambling keywords in App Store copy

---

## Implications for Roadmap

The dependency graph is clear and non-negotiable. Nothing meaningful can be built until the domain models and engines exist. The strategy engine cannot be built without the rules engine. The simulator cannot be built without all three engines. This dictates a strict bottom-up build order that maps directly to phase structure.

### Phase 1: Core Engine Foundation

**Rationale:** Every other feature in the app depends on these components. Building UI before the engine is verified correct is the single largest risk in this project. Phase 1 is all logic, no UI — it should not be considered done until comprehensive automated tests confirm mathematical correctness.
**Delivers:** `BJSCore` Swift Package with all four engines (Rules, Strategy, Counting, Edge) and shared models; full test suite validating strategy correctness across 10+ rule combinations
**Addresses:** Rule-configurable casino rules, rule-aware basic strategy engine (foundation for everything)
**Avoids:** Hardcoded strategy table (Pitfall 1), shoe simulation bugs (Pitfall 6), decision/outcome conflation design decisions (Pitfall 7 — architecture must support it), App Store visual direction (Pitfall 4), composition-dependent strategy labeling (Pitfall 5)
**Research flag:** Standard patterns for SwiftData and MVVM setup. The strategy engine math (rule variation correctness) deserves a dedicated research-phase pass before implementation.

### Phase 2: Basic Strategy Trainer

**Rationale:** This is the MVP feature and the app's primary value proposition. It must work before counting features are added. The feedback UX (decision evaluated before hand resolves, decision accuracy as primary metric) must be correct from the first interactive prototype — retrofitting this is expensive.
**Delivers:** Fully functional strategy training loop — deal hands, evaluate decisions, show feedback, track session accuracy; SwiftData persistence layer; basic progress tracking
**Addresses:** Basic strategy feedback per hand, session accuracy tracking, speed control, Learn vs Test mode separation
**Avoids:** Decision/outcome conflation (Pitfall 7 — feedback before hand resolves), fat views anti-pattern, global singleton anti-pattern
**Research flag:** Standard MVVM + @Observable patterns apply. No additional research phase needed.

### Phase 3: Counting Fundamentals

**Rationale:** Hi-Lo practice builds directly on the counting engine from Phase 1. True count conversion must be verified correct here before it is used in the full simulator. Running count and true count drills are prerequisite to bet spread practice.
**Delivers:** Hi-Lo running count drills (single card and group modes), true count conversion practice, speed mode for counting drills
**Addresses:** Running count practice, true count conversion, speed control
**Avoids:** Wrong true count calculation (Pitfall 2 — floating-point division, end-of-shoe invariants), card reveal pace UX pitfall
**Research flag:** Standard patterns. Counting math is well-documented. No additional research phase needed.

### Phase 4: Analysis and Intelligence

**Rationale:** House edge calculator and analytics dashboard require accumulated session data (Phases 2-3) to be meaningful. Weak-spot targeting requires error history from the strategy trainer. Casino rule presets can be added here as they depend on the rule configuration system being stable.
**Delivers:** House edge calculator (validated against Wizard of Odds), weak-spot targeting / adaptive practice weighting, performance analytics dashboard with Swift Charts, casino rule presets
**Addresses:** Integrated house edge calculator, performance analytics, weak-spot targeting, casino rule presets
**Avoids:** House edge calculator with wrong rule effects (Pitfall 3 — cross-validate against Wizard of Odds before shipping)
**Research flag:** The house edge calculator math deserves a research-phase pass to confirm rule-effect delta values and interaction accuracy against multiple external references.

### Phase 5: Full Shoe Simulation

**Rationale:** The simulator is the capstone feature that combines all engines. It has the highest complexity and depends on Phases 1-4 being solid. Bet spread practice and deviation index training require the full simulation context.
**Delivers:** Full shoe simulation combining strategy decisions, running count, true count, and bet sizing; end-of-shoe performance report; bet spread practice with EV feedback
**Addresses:** Full shoe counting simulation, bet spread practice, comprehensive performance reporting — the "graduation" feature that separates BJS from fragmented single-purpose apps
**Avoids:** Mixing animation with game logic (Anti-Pattern 4 — game state transitions instant in engine, animations independent in views), one mega-ViewModel (Anti-Pattern 5 — Simulator has its own VM)
**Research flag:** Full shoe simulation with simultaneous strategy + counting + bet sizing is the most complex feature. Recommend a research-phase pass on simulator architecture and bet spread EV calculation methodology.

### Phase Ordering Rationale

- The engine-first order is dictated by the dependency graph: no UI feature can be correct without a correct engine beneath it
- Phase 1 being entirely logic (no UI) means correctness can be verified in isolation before any user-facing code is written
- Phase 2 ships the MVP: a working strategy trainer is a complete v1 if needed
- Phases 3-4 add the counting and analysis layers; they are independent of each other and could be reordered
- Phase 5 is gated on Phases 1-4 because it integrates all engines simultaneously
- The App Store educational positioning concern (Pitfall 4) must be resolved in Phase 1's visual direction decisions and maintained throughout — it is not a final-phase concern

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1 (Strategy Engine):** Rule variation math is subtle and consequential; recommend verifying all strategy table cells against the BlackjackInfo strategy engine and Wizard of Odds calculator before writing production code
- **Phase 4 (Edge Calculator):** Rule-effect delta values and their interaction accuracy need to be sourced from authoritative references with explicit documentation; additive approximation has known limits at unusual rule combinations
- **Phase 5 (Full Simulator):** Bet spread EV calculation methodology and simulator architecture (especially shoe state management with splits) warrant dedicated research before implementation

Phases with standard patterns (skip research-phase):
- **Phase 2 (Strategy Trainer):** MVVM + @Observable patterns are well-documented; SwiftData setup is straightforward
- **Phase 3 (Counting Drills):** Hi-Lo math is simple and well-documented; standard UI patterns apply

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All Apple first-party tools with official documentation; Swift 6.2 / Xcode 26.3 are current stable releases verified against Apple Developer docs |
| Features | HIGH | Based on App Store competitor analysis, user review mining, and community forum research; the four-pillar gap is clearly documented |
| Architecture | HIGH | MVVM + @Observable is Apple's documented modern pattern; local Swift Package for domain separation is an established iOS best practice |
| Pitfalls | HIGH | Domain math pitfalls sourced from Wizard of Odds (authoritative); App Store pitfall sourced from Apple's own review guidelines |

**Overall confidence:** HIGH

### Gaps to Address

- **Composition-dependent strategy scope:** Research confirms this is acceptable to defer, but the architecture must explicitly support future extension. Document the "total-dependent" decision in the strategy engine and ensure the lookup interface accepts a `RuleSet` parameter that could eventually include a `compositionDependent: Bool` flag.
- **House edge calculator precision:** The additive approximation method has known inaccuracy for unusual rule combinations (up to 0.05% off). This is acceptable for v1 if clearly labeled. Validate against at least 10 rule sets before shipping; document the baseline and methodology in the UI.
- **Deviation index training:** Deferred to post-v1, but the strategy engine architecture should be designed to support count-adjusted deviation plays without a rewrite. The `StrategyLookup` interface should accept an optional true count parameter from the start.
- **iCloud sync:** Not needed for v1. SwiftData supports CloudKit sync, but enabling it adds non-trivial complexity. Design the `ProgressStoring` protocol with sync in mind so it can be added later without breaking callers.

---

## Sources

### Primary (HIGH confidence)
- [Apple Developer — Swift Testing](https://developer.apple.com/xcode/swift-testing/) — Swift Testing framework, parameterized tests
- [Apple Developer — SwiftData](https://developer.apple.com/documentation/swiftdata) — persistence, iOS 18 stability
- [Apple Developer — Migrating to @Observable](https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro) — modern MVVM patterns
- [Apple Developer — Adopting Swift 6](https://developer.apple.com/documentation/swift/adoptingswift6) — concurrency, MainActor-by-default
- [Apple Developer — SDK Requirements](https://developer.apple.com/news/upcoming-requirements/?id=02212025a) — App Store submission requirements, iOS 18 SDK mandate
- [Apple Developer — App Store Review Guidelines 5.3](https://developer.apple.com/app-store/review/guidelines/) — gambling app rejection criteria
- [Wizard of Odds — Blackjack Rule Variations](https://wizardofodds.com/games/blackjack/rule-variations/) — authoritative rule-effect delta values
- [Wizard of Odds — Blackjack House Edge Calculator](https://wizardofodds.com/games/blackjack/calculator/) — reference validator for edge calculator
- [Wizard of Odds — Composition-Dependent Strategy Benefit](https://wizardofodds.com/games/blackjack/composition-dependent-benefit/) — CD vs TD strategy analysis
- [BlackjackInfo — Basic Strategy Engine](https://www.blackjackinfo.com/blackjack-basic-strategy-engine/) — rule-dependent strategy chart generation

### Secondary (MEDIUM confidence)
- [Blackjack & Card Counting Pro (BJA) — App Store](https://apps.apple.com/us/app/blackjack-card-counting-pro/id388857410) — competitor feature set and user reviews
- [BlackjackIQ Pro — App Store](https://apps.apple.com/us/app/blackjackiq-pro/id6754751115) — analytics features, adaptive training
- [Protocol 21 Guide](https://protocol21blackjack.com/ultimate-blackjack-card-counting-app-guide) — competitor feature breadth
- [SwiftLee — MVVM architectural pattern for SwiftUI](https://www.avanderlee.com/swiftui/mvvm-architectural-coding-pattern-to-structure-views/) — architectural rationale
- [SwiftLee — @Observable macro performance](https://www.avanderlee.com/swiftui/observable-macro-performance-increase-observableobject/) — fine-grained reactivity benefits
- [SwiftLee — Approachable Concurrency in Swift 6.2](https://www.avanderlee.com/concurrency/approachable-concurrency-in-swift-6-2-a-clear-guide/) — Swift 6.2 concurrency guide
- [Nimble — Modularizing iOS apps with SPM](https://nimblehq.co/blog/modern-approach-modularize-ios-swiftui-spm) — local Swift Package structure rationale
- [Beating Bonuses — House Edge Calculator](https://www.beatingbonuses.com/houseedge.htm) — secondary validation reference for edge deltas
- [Blackjack Apprenticeship — Strategy Charts](https://www.blackjackapprenticeship.com/blackjack-strategy-charts/) — rule-dependent strategy differences
- [BlackjackInfo Community — Training Apps Thread](https://www.blackjackinfo.com/community/threads/training-apps.56364/) — user frustrations, serious player wants
- [Blackjack Review — Training Apps Compared (2025)](https://www.blackjackreview.com/wp/2025/10/15/blackjack-training-apps-compared/) — competitive landscape

### Tertiary (LOW confidence)
- [ShopApper — Fix Apple Gambling App Rejection](https://shopapper.com/fix-apple-gambling-app-rejection-guideline-5-3/) — App Store rejection recovery guidance; directionally correct but not an official Apple source
- [Wizard of Vegas Forum — Depleted Shoe Edge Calculator](https://wizardofvegas.com/forum/gambling/blackjack/34659-blackjack-house-edge-calculator-for-depleted-shoe/) — accuracy limitations of EOR approach; useful context but forum-level confidence

---
*Research completed: 2026-03-24*
*Ready for roadmap: yes*

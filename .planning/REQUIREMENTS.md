# Requirements: BJS — Blackjack Training App

**Defined:** 2026-03-24
**Core Value:** Users make correct blackjack decisions faster and with more confidence — the app must always give accurate, rule-specific feedback that makes players measurably better.

## v1 Requirements

### Rules Model (RULE)

- [x] **RULE-01**: App exposes a canonical `BlackjackRules` model covering: deck count (1–8), S17/H17, blackjack payout (3:2 / 6:5 / 2:1), DAS, RSA, hit split aces, max split hands, surrender rule (none / late / early), double restrictions (any two / 9–11 / 10–11), and peek / no-peek (American hole-card vs ENHC)
- [ ] **RULE-02**: The same `BlackjackRules` value is used by the Strategy Trainer, Edge Calculator, and Full Shoe Simulator — one shared rule configuration, consistent across features
- [ ] **RULE-03**: Casino presets pre-fill the rule configuration form as a UX convenience — presets are not part of the domain model itself

### Basic Strategy Trainer (STRAT)

- [ ] **STRAT-01**: User can simulate blackjack hands under the currently active `BlackjackRules` configuration
- [ ] **STRAT-02**: App evaluates each player decision against the correct basic strategy for the active rule set — no hardcoded single strategy table anywhere in the codebase
- [ ] **STRAT-03**: User receives correct/incorrect feedback immediately after each decision, before the hand outcome is revealed
- [ ] **STRAT-04**: App tracks decision accuracy percentage and a per-mistake log for each session
- [ ] **STRAT-05**: Learn mode displays the correct action before requiring user input (guided practice)
- [ ] **STRAT-06**: Test mode drills decisions without hints (unguided evaluation)
- [ ] **STRAT-07**: Speed mode adds a per-decision timer and tracks reaction time alongside accuracy
- [ ] **STRAT-08**: Weak-spot mode weights hand presentation toward categories where the user has the highest historical error rate

### Hi-Lo Practice (HILO)

- [ ] **HILO-01**: User can run Hi-Lo counting drills with cards presented one at a time or in configurable group sizes
- [ ] **HILO-02**: User inputs a running count value after each card or group; app scores accuracy against the correct count
- [ ] **HILO-03**: Drill sessions track speed (time per card) and accuracy (count error rate) and persist results
- [ ] **HILO-04**: User can practice true count conversion: app presents a running count and decks remaining; user enters the true count (RC / decks remaining, always floating-point)
- [ ] **HILO-05**: Card reveal speed is user-adjustable from slow (learning pace) to sub-1-second (casino pace simulation)

### Edge Calculator (EDGE)

- [ ] **EDGE-01**: User inputs a complete rule configuration and app outputs the estimated house edge percentage under perfect basic strategy
- [ ] **EDGE-02**: App displays a qualitative game quality rating (e.g., good / mediocre / bad) alongside the house edge number
- [ ] **EDGE-03**: App shows a rule-by-rule contribution breakdown — how much each rule adds or subtracts from the base edge
- [ ] **EDGE-04**: Casino presets pre-fill the edge calculator rule form (same preset system as RULE-03)
- [ ] **EDGE-05**: Edge calculation methodology uses Wizard of Odds rule-effect delta values as the authoritative source; output is validated against the Wizard of Odds online calculator for at least 10 distinct rule combinations before shipping

### Full Shoe Simulation (SIM)

- [ ] **SIM-01**: User can simulate a full shoe with configurable `BlackjackRules` and deck penetration setting
- [ ] **SIM-02**: App tracks running count and true count throughout the shoe; user maintains their own count and is evaluated
- [ ] **SIM-03**: User makes strategy decisions during simulation; both count accuracy and decision accuracy are independently tracked
- [ ] **SIM-04**: App presents an end-of-session performance report covering: count accuracy %, decision accuracy %, and total hands played

### Analytics and Progress (PROG)

- [ ] **PROG-01**: Session results are persisted locally on-device using SwiftData; no network connection required
- [ ] **PROG-02**: User can view a per-session summary: decision accuracy %, error count, and current streak
- [ ] **PROG-03**: User can view accuracy broken down by hand type: hard totals, soft totals, and pairs
- [ ] **PROG-04**: User can view an improvement trend chart showing accuracy over time (Swift Charts)
- [ ] **PROG-05**: Strategy Trainer adaptively weights hand presentation toward categories with the highest historical error rate for the user

### Architecture (ARCH)

- [x] **ARCH-01**: All core domain logic — rules engine, strategy evaluation, counting logic, and edge calculation — is packaged as pure Swift with no SwiftUI imports; all domain logic is fully unit-testable without launching a simulator
- [ ] **ARCH-02**: Strategy evaluation always derives the correct action from the active `BlackjackRules` configuration at runtime — no hardcoded or pre-baked single-ruleset strategy table is acceptable at any layer
- [ ] **ARCH-03**: All core training and analysis features work fully offline; no network connection is required for any v1 feature
- [ ] **ARCH-04**: User progress and analytics are persisted on-device only; no cloud sync, user accounts, or backend services are required or included in v1

---

## v2 Requirements

### Counting Systems
- **COUNT-01**: Support for additional counting systems beyond Hi-Lo (KO, Hi-Opt I, Omega II, Zen)

### Advanced Strategy
- **ADV-01**: Composition-dependent strategy (plays that depend on specific cards, not just total) — architecture must allow extension from v1; label v1 as total-dependent strategy
- **ADV-02**: Deviation index training (Illustrious 18, Fab 4) — requires full simulation context from v1

### Simulator Expansion
- **SIM-05**: Bet spread practice with EV feedback — user selects bet size based on true count; app grades against optimal spread

### Platform
- **PLAT-01**: iPad layout optimization
- **PLAT-02**: iCloud sync for progress data (SwiftData + CloudKit)

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Real-money gambling or wagering of any kind | This is a training tool, not a gambling product; violates App Store guidelines |
| Live in-casino table assistance or real-time decision support | Scope: training and analysis only; not an AP tool |
| Camera-based card counting | Out of scope for v1; not a core training need |
| Multiplayer, social features, leaderboards | Niche training tool; no social demand; adds complexity without core value |
| Cloud sync / user accounts / backend services | v1 is offline-first; complexity not justified until product is validated |
| Multiple counting systems beyond Hi-Lo | Hi-Lo covers 90%+ of learners; additional systems are v2+ |
| Composition-dependent strategy in v1 | Small accuracy benefit (0.036% single deck); defer but design architecture to support extension |
| Continuous shuffler modeling | Edge case; not a common serious-player table |
| Side bet analysis | Out of scope for a basic strategy / counting training tool |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| RULE-01 | Phase 1 | Complete |
| RULE-02 | Phase 1 | Pending |
| RULE-03 | Phase 2 | Pending |
| STRAT-01 | Phase 2 | Pending |
| STRAT-02 | Phase 2 | Pending |
| STRAT-03 | Phase 2 | Pending |
| STRAT-04 | Phase 2 | Pending |
| STRAT-05 | Phase 2 | Pending |
| STRAT-06 | Phase 2 | Pending |
| STRAT-07 | Phase 5 | Pending |
| STRAT-08 | Phase 5 | Pending |
| HILO-01 | Phase 3 | Pending |
| HILO-02 | Phase 3 | Pending |
| HILO-03 | Phase 3 | Pending |
| HILO-04 | Phase 3 | Pending |
| HILO-05 | Phase 3 | Pending |
| EDGE-01 | Phase 4 | Pending |
| EDGE-02 | Phase 4 | Pending |
| EDGE-03 | Phase 4 | Pending |
| EDGE-04 | Phase 4 | Pending |
| EDGE-05 | Phase 4 | Pending |
| SIM-01 | Phase 6 | Pending |
| SIM-02 | Phase 6 | Pending |
| SIM-03 | Phase 6 | Pending |
| SIM-04 | Phase 6 | Pending |
| PROG-01 | Phase 2 | Pending |
| PROG-02 | Phase 2 | Pending |
| PROG-03 | Phase 5 | Pending |
| PROG-04 | Phase 5 | Pending |
| PROG-05 | Phase 5 | Pending |
| ARCH-01 | Phase 1 | Complete |
| ARCH-02 | Phase 1 | Pending |
| ARCH-03 | Phase 2 | Pending |
| ARCH-04 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 34 total
- Mapped to phases: 34
- Unmapped: 0

---
*Requirements defined: 2026-03-24*
*Last updated: 2026-03-24 after roadmap creation*

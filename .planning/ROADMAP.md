# Roadmap: BJS — Blackjack Training App

## Overview

BJS delivers a complete blackjack training system in six phases. The build order follows the dependency graph: a pure Swift domain engine first (correctness verified before any UI exists), then the MVP strategy trainer, then independent feature modules (counting and edge analysis), then analytics depth, and finally the capstone full shoe simulation that integrates everything. Each phase delivers a coherent, testable capability.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Core Engine** - Pure Swift domain package with rules, strategy, counting, and edge engines plus comprehensive test suite
- [x] **Phase 2: Strategy Trainer** - MVP feature: interactive basic strategy training with feedback, session tracking, and persistence (completed 2026-03-24)
- [ ] **Phase 3: Hi-Lo Practice** - Card counting drills with running count and true count conversion training
- [ ] **Phase 4: Edge Calculator** - Rule-based house edge analysis with contribution breakdown and game quality rating
- [ ] **Phase 5: Analytics & Adaptive Training** - Deep progress analytics, improvement trends, and adaptive weak-spot modes
- [ ] **Phase 6: Full Shoe Simulation** - Capstone: complete shoe with simultaneous counting and strategy evaluation

## Phase Details

### Phase 1: Core Engine
**Goal**: All blackjack domain logic exists as a tested, pure Swift package — strategy correctness is verified against external references before any UI code is written
**Depends on**: Nothing (first phase)
**Requirements**: ARCH-01, ARCH-02, RULE-01, RULE-02
**Success Criteria** (what must be TRUE):
  1. BJSCore Swift Package compiles with zero SwiftUI imports and all tests run without a simulator
  2. BlackjackRules model covers all specified rule variations (deck count, S17/H17, DAS, RSA, surrender, double restrictions, peek, BJ payout, max splits, hit split aces)
  3. Strategy engine returns the correct action for any hand/upcard/ruleset combination, validated against Wizard of Odds for at least 10 distinct rule sets
  4. Counting engine correctly calculates Hi-Lo running count and true count (floating-point division, end-of-shoe invariant: RC = 0)
  5. Edge calculator returns house edge percentage within 0.01% of Wizard of Odds reference for at least 10 rule combinations
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md — BJSCore package structure + Card, BlackjackRules, Action, BlackjackHand, Shoe models with tests
- [x] 01-02-PLAN.md — Strategy engine: dealer probabilities, EV computation, table generation, WoO validation
- [x] 01-03-PLAN.md — Hi-Lo counting engine + house edge calculator with WoO validation

### Phase 2: Strategy Trainer
**Goal**: Users can practice basic strategy decisions with rule-specific feedback and track their accuracy across sessions
**Depends on**: Phase 1
**Requirements**: STRAT-01, STRAT-02, STRAT-03, STRAT-04, STRAT-05, STRAT-06, RULE-03, PROG-01, PROG-02, ARCH-03, ARCH-04
**Success Criteria** (what must be TRUE):
  1. User can play simulated hands under a configurable rule set and receive correct/incorrect feedback before the hand outcome is revealed
  2. User can select Learn mode (shows correct action first) or Test mode (no hints) before starting a session
  3. User can select a casino preset that pre-fills the rule configuration form
  4. User can view per-session summary showing decision accuracy percentage, error count, and streak
  5. Session results persist on-device and survive app restarts with no network connection required
**Plans**: 3 plans
**UI hint**: yes

Plans:
- [x] 02-01-PLAN.md — Xcode project scaffold, SwiftData models, casino presets, test stubs
- [x] 02-02-PLAN.md — TrainerViewModel game loop + RulesViewModel with tests
- [x] 02-03-PLAN.md — All SwiftUI views wired to ViewModels + human verification

### Phase 02.1: UI/UX System & Layout Stabilization (INSERTED)

**Goal:** Establish a consistent design token system (spacing, typography, color) and fix all layout/safe-area bugs across the 3 main screens, creating a production-ready visual foundation before new feature development continues
**Requirements**: D-01 through D-22 (design decisions from discuss-phase)
**Depends on:** Phase 2
**Plans:** 2/3 plans executed

Plans:
- [x] 02.1-01-PLAN.md — Design tokens (Spacing, BJSColors, Typography) + leaf component refactoring (CardView, HandView, FeedbackOverlayView, StatsBarView, ActionButtonsView)
- [x] 02.1-02-PLAN.md — Screen-level refactoring (SessionStartView, SessionSummaryView, TrainerView safe area fix, BJSApp global tint)
- [ ] 02.1-03-PLAN.md — Visual verification checkpoint (screenshots, light/dark mode, SE device test)

### Phase 02.2: Global UI Redesign (INSERTED)

**Goal:** Refactor all UI to conform tightly to `design-system/bjs/MASTER.md` — premium, minimal, analytical. Fix all MASTER.md violations identified in the Phase 02.2 audit, expand the design token system, and gate continuation to Phase 3 on explicit human approval.
**Requirements**: MASTER.md (design-system/bjs/MASTER.md), V-01 through V-04 (critical violations), T-01 through T-07 (token gaps)
**Depends on:** Phase 02.1
**Plans:** 3/4 plans executed

Plans:
- [x] 02.2-01-PLAN.md — Design token expansion (CornerRadius, Elevation, AnimationTiming, feedback colors, cardFaceDown, Typography.statValue)
- [x] 02.2-02-PLAN.md — Component redesign: FeedbackOverlayView (compact banner), ActionButtonsView (two-row), CardView (token application)
- [x] 02.2-03-PLAN.md — Screen polish: SessionSummaryView monospaced stats, SectionContainerView surface, final literal scan
- [ ] 02.2-04-PLAN.md — Visual verification + human approval gate (screenshots: iPhone 16 light/dark, SE light)

### Phase 3: Hi-Lo Practice
**Goal**: Users can practice Hi-Lo card counting with configurable drills that build speed and accuracy
**Depends on**: Phase 1
**Requirements**: HILO-01, HILO-02, HILO-03, HILO-04, HILO-05
**Success Criteria** (what must be TRUE):
  1. User can run a counting drill with cards presented one at a time or in configurable group sizes, at a user-adjustable speed from learning pace to sub-1-second
  2. User inputs running count after each card or group and sees whether the answer was correct
  3. User can practice true count conversion by entering TC given a running count and decks remaining
  4. Drill sessions track and persist speed (time per card) and accuracy (count error rate) across sessions
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 03-01: TBD
- [ ] 03-02: TBD

### Phase 4: Edge Calculator
**Goal**: Users can analyze any rule set and understand its house edge impact in detail
**Depends on**: Phase 1
**Requirements**: EDGE-01, EDGE-02, EDGE-03, EDGE-04, EDGE-05
**Success Criteria** (what must be TRUE):
  1. User can input a complete rule configuration and see the estimated house edge percentage under perfect basic strategy
  2. User can see a qualitative game quality rating (good / mediocre / bad) alongside the edge number
  3. User can see a rule-by-rule contribution breakdown showing how each rule adds or subtracts from the base edge
  4. Casino presets pre-fill the edge calculator form (same preset system as the Strategy Trainer)
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 04-01: TBD
- [ ] 04-02: TBD

### Phase 5: Analytics & Adaptive Training
**Goal**: Users can see meaningful improvement trends and the app adapts to focus on their weakest areas
**Depends on**: Phase 2
**Requirements**: PROG-03, PROG-04, PROG-05, STRAT-07, STRAT-08
**Success Criteria** (what must be TRUE):
  1. User can view accuracy broken down by hand type: hard totals, soft totals, and pairs
  2. User can view an improvement trend chart showing accuracy over time
  3. Speed mode adds a per-decision timer and tracks reaction time alongside accuracy in the Strategy Trainer
  4. Weak-spot mode weights hand presentation toward categories where the user has the highest historical error rate
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 05-01: TBD
- [ ] 05-02: TBD

### Phase 6: Full Shoe Simulation
**Goal**: Users can run a realistic full-shoe session that combines strategy decisions with live card counting under pressure
**Depends on**: Phase 1, Phase 2, Phase 3
**Requirements**: SIM-01, SIM-02, SIM-03, SIM-04
**Success Criteria** (what must be TRUE):
  1. User can start a full shoe simulation with configurable rules and deck penetration
  2. User maintains their own running count and true count throughout the shoe and is evaluated for accuracy
  3. User makes strategy decisions during the shoe and both count accuracy and decision accuracy are independently tracked
  4. User sees an end-of-session performance report covering count accuracy %, decision accuracy %, and total hands played
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 06-01: TBD
- [ ] 06-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 2.1 -> 2.2 -> 3 -> 4 -> 5 -> 6
Note: Phases 3 and 4 depend only on Phase 1 and are independent of each other.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Engine | 0/3 | Planning complete | - |
| 2. Strategy Trainer | 3/3 | Complete   | 2026-03-24 |
| 2.1 UI/UX Stabilization | 0/3 | Planning complete | - |
| 2.2 Global UI Redesign | 0/4 | Planning complete | - |
| 3. Hi-Lo Practice | 0/2 | Not started | - |
| 4. Edge Calculator | 0/2 | Not started | - |
| 5. Analytics & Adaptive Training | 0/2 | Not started | - |
| 6. Full Shoe Simulation | 0/2 | Not started | - |

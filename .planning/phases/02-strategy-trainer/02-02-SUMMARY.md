---
phase: 02-strategy-trainer
plan: 02
subsystem: viewmodels, testing
tags: [observable, mvvm, strategy-engine, game-loop, state-machine, userdefaults]

# Dependency graph
requires:
  - phase: 01-core-engine
    provides: BJSCore package with StrategyEngine, StrategyTable, BlackjackHand, Shoe, Action
  - phase: 02-01
    provides: SwiftData models, CasinoPreset, HapticManager, test stubs
provides:
  - TrainerViewModel with complete game loop state machine and decision evaluation
  - RulesViewModel with preset management and UserDefaults persistence
  - 17 real TrainerViewModel tests replacing 8 stubs
affects: [02-03-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: [game-loop state machine, mid-hand action mapping, static mapAction for testability, SessionStats value type]

key-files:
  created:
    - BJS/ViewModels/TrainerViewModel.swift
    - BJS/ViewModels/RulesViewModel.swift
  modified:
    - BJSTests/TrainerViewModelTests.swift

key-decisions:
  - "mapAction exposed as static method for direct unit testing without ViewModel instantiation"
  - "correctActionMapped computed property bridges strategy table lookup and action mapping for both learn mode display and decision evaluation"
  - "pendingPlayerAction pattern separates feedback display from action execution via advanceFromFeedback()"

patterns-established:
  - "State machine phase transitions: phase property drives UI reactivity via @Observable"
  - "Static action mapping: TrainerViewModel.mapAction() testable without ViewModel state"
  - "SessionStats as value type with mutating methods for clean accumulation"

requirements-completed: [STRAT-01, STRAT-02, STRAT-03, STRAT-04, STRAT-05, STRAT-06, PROG-02]

# Metrics
duration: 4min
completed: 2026-03-24
---

# Phase 02 Plan 02: ViewModels Summary

**TrainerViewModel game loop state machine with StrategyTable decision evaluation, mid-hand action mapping, learn/test modes, and RulesViewModel with preset persistence**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-24T21:12:28Z
- **Completed:** 2026-03-24T21:16:01Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- TrainerViewModel implementing complete game loop: deal -> await decision -> evaluate -> feedback -> play-out -> result -> next hand
- Decision evaluation using StrategyTable.action(for:dealerUpcard:rules:) with mid-hand mapping (double->hit, surrender->hit for 3+ cards)
- Learn mode exposes correct action via correctActionForDisplay; Test mode hides it
- SessionStats tracking accuracy %, error count, best streak, decision log
- RulesViewModel with Vegas Strip/Downtown Vegas/Custom presets, auto-detection, and UserDefaults persistence
- 17 real tests replacing 8 placeholder stubs

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement TrainerViewModel with game loop state machine** - `c190151` (feat)
2. **Task 2: Implement RulesViewModel for rule configuration and preset management** - `a746624` (feat)

## Files Created/Modified
- `BJS/ViewModels/TrainerViewModel.swift` - @Observable ViewModel with game loop state machine, decision evaluation, session stats, learn/test modes
- `BJS/ViewModels/RulesViewModel.swift` - @Observable ViewModel with preset selection, rule persistence, rules summary
- `BJSTests/TrainerViewModelTests.swift` - 17 real tests covering deal, evaluation, action mapping, stats, learn/test modes, blackjack, bust

## Decisions Made
- mapAction exposed as static method for direct unit testing without requiring full ViewModel instantiation
- correctActionMapped as computed property bridges strategy lookup and action mapping for both learn mode display and playerAction evaluation
- pendingPlayerAction pattern separates the feedback display phase from action execution (advanceFromFeedback)
- Split handling simplified to pass-through to play-out (full sequential split can be enhanced later)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added startSession() method**
- **Found during:** Task 1
- **Issue:** Plan specifies startNewSession() but tests need a way to transition from preSession before dealing. Added startSession() as the entry point that resets stats and decisions.
- **Fix:** Added startSession() method alongside startNewSession()
- **Files modified:** BJS/ViewModels/TrainerViewModel.swift
- **Committed in:** c190151

**2. [Rule 2 - Missing Critical] Added correctActionMapped computed property**
- **Found during:** Task 1
- **Issue:** Tests need access to the mapped correct action for verification. Plan specified mapToAvailableAction as private but tests need it exposed.
- **Fix:** Added correctActionMapped as a public computed property and mapAction as a static method for direct testing
- **Files modified:** BJS/ViewModels/TrainerViewModel.swift
- **Committed in:** c190151

---

**Total deviations:** 2 auto-fixed (2 missing critical)
**Impact on plan:** Both additions necessary for testability. No scope creep.

## Known Stubs

None. All ViewModel logic is fully implemented and wired.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- TrainerViewModel ready for UI binding in Plan 03 views
- RulesViewModel ready for RuleConfigView and SessionStartView form binding
- All state machine phases defined and transition correctly
- availableActions computed property ready for ActionButtonsView consumption

---
*Phase: 02-strategy-trainer*
*Completed: 2026-03-24*

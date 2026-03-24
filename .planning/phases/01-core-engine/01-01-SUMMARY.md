---
phase: 01-core-engine
plan: 01
subsystem: domain
tags: [swift, blackjack, rules-engine, card-model, shoe, hand]

# Dependency graph
requires: []
provides:
  - "BJSCore Swift Package with library and test targets"
  - "Card, Rank, Suit types with blackjackValue, hiLoValue, columnIndex"
  - "BlackjackRules struct covering all 11 RULE-01 rule variations"
  - "Action enum (hit, stand, double, split, surrender)"
  - "BlackjackHand with totals, soft/hard, pair, bust, eligibility flags"
  - "Shoe with multi-deck construction, shuffle, deal, penetration tracking"
affects: [01-02, 01-03, 02-strategy-trainer, 03-hilo, 04-edge-calc, 06-simulator]

# Tech tracking
tech-stack:
  added: [swift-6.2, swift-package-manager, swift-testing]
  patterns: [pure-swift-domain-package, tdd, value-types, sendable-by-default]

key-files:
  created:
    - BJSCore/Package.swift
    - BJSCore/Sources/BJSCore/Models/Card.swift
    - BJSCore/Sources/BJSCore/Models/Action.swift
    - BJSCore/Sources/BJSCore/Models/BlackjackRules.swift
    - BJSCore/Sources/BJSCore/Models/BlackjackHand.swift
    - BJSCore/Sources/BJSCore/Models/Shoe.swift
    - BJSCore/Tests/BJSCoreTests/ModelTests/CardTests.swift
    - BJSCore/Tests/BJSCoreTests/ModelTests/RulesTests.swift
    - BJSCore/Tests/BJSCoreTests/ModelTests/HandTests.swift
    - BJSCore/Tests/BJSCoreTests/ModelTests/ShoeTests.swift
    - BJSCore/Tests/BJSCoreTests/ModelTests/CodableTestHelper.swift
  modified: []

key-decisions:
  - "All types public for downstream consumption via import BJSCore"
  - "Used XCTest-free Swift Testing with CLT framework path workaround"
  - "CodableTestHelper isolates Foundation import to avoid Testing/Foundation cross-import overlay issue"
  - "Rank raw values start at 2, ace is last case (matching pip order)"
  - "Pair detection by rank equality only (10 and King are NOT a pair)"

patterns-established:
  - "Pure value types: Card, BlackjackHand, Shoe, BlackjackRules are all structs"
  - "Sendable by default: all domain types conform to Sendable"
  - "Test helper pattern: CodableTestHelper isolates Foundation from Testing framework"
  - "swift test invocation requires -Xswiftc -F and -Xlinker -rpath for CLT Testing framework"

requirements-completed: [ARCH-01, RULE-01]

# Metrics
duration: 12min
completed: 2026-03-24
---

# Phase 01 Plan 01: Foundation Models Summary

**BJSCore Swift Package with Card/Rank/Suit, BlackjackRules (11 rule variations), BlackjackHand (ace-correct totals + eligibility flags), and Shoe (multi-deck with penetration) -- 61 tests passing**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-24T18:05:56Z
- **Completed:** 2026-03-24T18:18:02Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments
- BJSCore Swift Package compiles as pure Swift with zero SwiftUI/UIKit imports
- BlackjackRules covers all 11 RULE-01 variations with sensible defaults (6-deck S17 DAS)
- BlackjackHand correctly handles all ace edge cases (A-A=12, A-6-8=15 hard, A-6-A=18 soft, A-A-A=13 soft)
- Shoe creates correct deck counts, shuffles, deals, tracks penetration threshold
- 61 tests across 4 suites all pass via `swift test` without a simulator

## Task Commits

Each task was committed atomically:

1. **Task 1: Create BJSCore Swift Package with Card, BlackjackRules, and Action types** - `7443213` (feat)
2. **Task 2: Implement BlackjackHand and Shoe models with comprehensive tests** - `6dd637c` (feat)

## Files Created/Modified
- `BJSCore/Package.swift` - Swift Package manifest with BJSCore library + BJSCoreTests targets
- `BJSCore/Sources/BJSCore/Models/Card.swift` - Card, Rank, Suit types with blackjackValue, hiLoValue, columnIndex
- `BJSCore/Sources/BJSCore/Models/Action.swift` - Player action enum (hit, stand, double, split, surrender)
- `BJSCore/Sources/BJSCore/Models/BlackjackRules.swift` - Complete rule configuration with 11 properties and nested enums
- `BJSCore/Sources/BJSCore/Models/BlackjackHand.swift` - Hand model with totals, soft/hard, pair, eligibility, index helpers
- `BJSCore/Sources/BJSCore/Models/Shoe.swift` - Multi-deck card source with shuffle, deal, penetration tracking
- `BJSCore/Tests/BJSCoreTests/ModelTests/CardTests.swift` - 9 tests for Card, Rank, Suit, Action
- `BJSCore/Tests/BJSCoreTests/ModelTests/RulesTests.swift` - 13 tests for BlackjackRules defaults, Hashable, Codable, enums
- `BJSCore/Tests/BJSCoreTests/ModelTests/HandTests.swift` - 29 tests for hand totals, pairs, eligibility, indices
- `BJSCore/Tests/BJSCoreTests/ModelTests/ShoeTests.swift` - 9 tests for shoe construction, dealing, penetration
- `BJSCore/Tests/BJSCoreTests/ModelTests/CodableTestHelper.swift` - JSON round-trip helper isolating Foundation import

## Decisions Made
- Made all types `public` (not just `internal`) so downstream phases can `import BJSCore` without `@testable`
- Used Swift Testing framework instead of XCTest per CLAUDE.md recommendation, with CLT framework path workaround
- Created CodableTestHelper to isolate Foundation import from Testing framework (CLT missing `_Testing_Foundation` cross-import overlay)
- Pair detection uses rank equality only -- same blackjack value with different ranks (10 vs King) is NOT a pair, matching standard casino rules

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] CLT Testing framework not in default search path**
- **Found during:** Task 1 (running tests)
- **Issue:** Command Line Tools does not include Testing/XCTest in default module search paths; Xcode license (26.3) not accepted (accepted for 26.2 only)
- **Fix:** Added `-Xswiftc -F -Xswiftc /Library/Developer/CommandLineTools/Library/Developer/Frameworks -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks` flags to `swift test`
- **Files modified:** None (runtime flag only)
- **Verification:** All 61 tests pass

**2. [Rule 3 - Blocking] Testing + Foundation cross-import overlay missing in CLT**
- **Found during:** Task 1 (running tests)
- **Issue:** Importing both `Testing` and `Foundation` in same file triggers lookup of `_Testing_Foundation` overlay, which exists as a binary in CLT but has no `.swiftmodule`
- **Fix:** Created `CodableTestHelper.swift` that imports only Foundation, providing JSON round-trip via static method. Test files import only Testing.
- **Files modified:** `BJSCore/Tests/BJSCoreTests/ModelTests/CodableTestHelper.swift`
- **Verification:** All Codable tests pass without cross-import error

**3. [Rule 2 - Missing Critical] All types made public for package consumption**
- **Found during:** Task 1 (implementation)
- **Issue:** Default `internal` access would prevent downstream `import BJSCore` (only `@testable import` would work)
- **Fix:** Added `public` access to all types, properties, methods, and initializers
- **Files modified:** All source files in BJSCore/Sources/
- **Verification:** `@testable import` works in tests; `public` enables future `import BJSCore`

---

**Total deviations:** 3 auto-fixed (2 blocking, 1 missing critical)
**Impact on plan:** All fixes necessary for tests to run and package to be usable. No scope creep.

## Issues Encountered
- Xcode 26.3 license not accepted (plist shows 26.2); requires `sudo xcodebuild -license accept` which needs user password. Worked around by using CLT with explicit framework paths.

## Known Stubs
None -- all models are fully implemented with no placeholder data.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All foundation model types ready for plans 01-02 (strategy engine) and 01-03 (counting/edge)
- BlackjackRules is the shared type used by all engines per RULE-02
- BlackjackHand provides the hand model with eligibility flags needed by strategy evaluation
- Shoe provides the card source needed by all simulation modes
- **Note:** User should accept Xcode 26.3 license (`sudo xcodebuild -license accept`) to simplify future test runs

## Self-Check: PASSED

- All 12 created files exist on disk
- Both task commits (7443213, 6dd637c) found in git log
- 61 tests pass across 4 suites
- `swift build` exits 0
- No SwiftUI/UIKit imports in source

---
*Phase: 01-core-engine*
*Completed: 2026-03-24*

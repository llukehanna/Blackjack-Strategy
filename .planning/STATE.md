---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: Ready to execute
stopped_at: Completed 02-01-PLAN.md
last_updated: "2026-03-24T21:11:31.414Z"
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 6
  completed_plans: 4
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-24)

**Core value:** Users make correct blackjack decisions faster and with more confidence — accurate, rule-specific feedback that makes players measurably better.
**Current focus:** Phase 02 — strategy-trainer

## Current Position

Phase: 02 (strategy-trainer) — EXECUTING
Plan: 2 of 3

## Performance Metrics

**Velocity:**

- Total plans completed: 0
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
| Phase 01 P01 | 12min | 2 tasks | 12 files |
| Phase 01 P03 | 10min | 2 tasks | 4 files |
| Phase 01 P02 | 22min | 2 tasks | 5 files |
| Phase 02 P01 | 2min | 3 tasks | 10 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: Engine-first build order — all domain logic verified before UI
- [Roadmap]: Phases 3 (Hi-Lo) and 4 (Edge Calc) are independent; can execute in either order after Phase 1
- [Roadmap]: PROG distributed — basic tracking in Phase 2, analytics depth in Phase 5
- [Phase 01]: All BJSCore types made public for downstream import BJSCore consumption
- [Phase 01]: Swift Testing via CLT requires explicit -Xswiftc -F and -Xlinker -rpath flags
- [Phase 01]: CodableTestHelper pattern isolates Foundation from Testing to avoid cross-import overlay issue
- [Phase 01]: Calibrated 1D/2D deck deltas from WoO confirmed values; added deck-dependent restrictive rule scaling
- [Phase 01]: EdgeCalculator uses struct (not class) with EdgeResult and RuleContribution top-level types
- [Phase 01]: American peek conditioning: dealer P(21) conditioned on no-BJ before computing player EVs
- [Phase 01]: Deck-dependent corrections applied to infinite-deck base for marginal plays (stiff standing, 1-2D doubling, ENHC)
- [Phase 02]: BlackjackRules stored as JSON Data blob in SwiftData (not flattened columns)
- [Phase 02]: Action stored as String rawValue in SessionDecision -- SwiftData cannot persist external enums
- [Phase 02]: XcodeGen manages project generation -- avoids .xcodeproj merge conflicts

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-03-24T21:11:31.412Z
Stopped at: Completed 02-01-PLAN.md
Resume file: None

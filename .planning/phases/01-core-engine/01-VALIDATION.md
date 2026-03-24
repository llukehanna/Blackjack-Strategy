---
phase: 1
slug: core-engine
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-24
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (built-in Xcode 26) |
| **Config file** | Package.swift — test target defined there |
| **Quick run command** | `swift test --filter BJSCoreTests` |
| **Full suite command** | `swift test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift test --filter BJSCoreTests`
- **After every plan wave:** Run `swift test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Wave 0 Approach

Plans use TDD-inline (`tdd="true"` on tasks): each task creates its test file alongside the implementation in the same wave. No separate Wave 0 plan is needed because:

1. Plan 01-01 Task 1 creates `Package.swift`, source files, AND test files (`CardTests.swift`, `RulesTests.swift`) in one step
2. Plan 01-01 Task 2 creates `HandTests.swift` and `ShoeTests.swift` alongside their implementations
3. Plan 01-02 Task 1 creates `DealerProbabilityTests.swift` alongside strategy source files
4. Plan 01-02 Task 2 creates `StrategyValidationTests.swift` (test-only task)
5. Plan 01-03 Task 1 creates `HiLoTests.swift` alongside `HiLoCounter.swift`
6. Plan 01-03 Task 2 creates `EdgeCalculatorTests.swift` alongside `EdgeCalculator.swift`

Every task that produces source code also produces its tests in the same commit. The `<behavior>` blocks in each task define test expectations before implementation (RED phase of TDD).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 1-01-01 | 01 | 1 | ARCH-01, RULE-01 | unit | `swift test --filter BJSCoreTests` | pending |
| 1-01-02 | 01 | 1 | ARCH-01, RULE-01 | unit | `swift test --filter BJSCoreTests` | pending |
| 1-02-01 | 02 | 2 | ARCH-02, RULE-02 | unit | `swift test --filter StrategyTests` | pending |
| 1-02-02 | 02 | 2 | ARCH-02, RULE-02 | unit | `swift test --filter StrategyValidation` | pending |
| 1-03-01 | 03 | 2 | ARCH-01, RULE-02 | unit | `swift test --filter HiLo` | pending |
| 1-03-02 | 03 | 2 | ARCH-01, RULE-02 | unit | `swift test --filter EdgeCalculator` | pending |

*Status: pending / green / red / flaky*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Strategy tables match Wizard of Odds for 10 distinct rule sets | RULE-02 | Requires cross-referencing external calculator | Run parameterized strategy tests, compare outputs against WoO strategy charts for S17 6D, H17 6D, S17 2D, H17 2D, S17 1D, H17 1D, S17 8D DAS, H17 8D DAS, S17 6D no-DAS, H17 6D no-DAS |
| Edge calculator within 0.01% of WoO for 12 rule combos | RULE-02 | WoO reference values must be manually verified | Check EdgeCalculatorTests parameterized output against WoO house edge calculator for same 12 rule sets |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] TDD-inline approach: tests created alongside implementation (no separate Wave 0 needed)
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

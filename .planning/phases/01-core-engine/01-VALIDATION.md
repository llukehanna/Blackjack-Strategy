---
phase: 1
slug: core-engine
status: draft
nyquist_compliant: false
wave_0_complete: false
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

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | ARCH-01 | unit | `swift test --filter BJSCoreTests` | ❌ W0 | ⬜ pending |
| 1-01-02 | 01 | 1 | ARCH-02 | unit | `swift test --filter BJSCoreTests` | ❌ W0 | ⬜ pending |
| 1-02-01 | 02 | 2 | RULE-01 | unit | `swift test --filter RulesTests` | ❌ W0 | ⬜ pending |
| 1-02-02 | 02 | 2 | RULE-01 | unit | `swift test --filter RulesTests` | ❌ W0 | ⬜ pending |
| 1-03-01 | 03 | 3 | RULE-02 | unit | `swift test --filter StrategyTests` | ❌ W0 | ⬜ pending |
| 1-03-02 | 03 | 3 | RULE-02 | unit | `swift test --filter EdgeTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Tests/BJSCoreTests/RulesTests.swift` — stubs for RULE-01 (BlackjackRules model)
- [ ] `Tests/BJSCoreTests/StrategyTests.swift` — stubs for RULE-02 (strategy engine)
- [ ] `Tests/BJSCoreTests/CountingTests.swift` — stubs for RULE-02 (counting engine)
- [ ] `Tests/BJSCoreTests/EdgeCalculatorTests.swift` — stubs for RULE-02 (edge calculator)
- [ ] `Sources/BJSCore/` — source directory structure

*Wave 0 creates the Swift package structure and empty test stubs before any implementation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Strategy tables match Wizard of Odds for 10 distinct rule sets | RULE-02 | Requires cross-referencing external calculator | Run parameterized strategy tests, compare outputs against WoO strategy charts for S17 6D, H17 6D, S17 2D, H17 2D, S17 1D, H17 1D, S17 8D DAS, H17 8D DAS, S17 6D no-DAS, H17 6D no-DAS |
| Edge calculator within 0.01% of WoO for 10 rule combos | RULE-02 | WoO reference values must be manually verified | Check EdgeCalculatorTests parameterized output against WoO house edge calculator for same 10 rule sets |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---
phase: 7
slug: ui-foundation-rebuild
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-07
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (Xcode 26) + XCTest for UI |
| **Config file** | BJS.xcodeproj (test target) |
| **Quick run command** | `xcodebuild test -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BJSTests/DesignTokenTests` |
| **Full suite command** | `xcodebuild test -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30s quick / ~90s full |

---

## Sampling Rate

- **After every task commit:** Run quick command
- **After every plan wave:** Run full suite
- **Before `/gsd:verify-work`:** Full suite must be green + manual visual diff vs IMG_7841/IMG_7843
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD — populated by planner | — | — | — | unit/structural | — | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BJSTests/DesignTokenTests.swift` — token value assertions (Color hex, Spacing CGFloat, Font sizes)
- [ ] `BJSTests/CardAssetTests.swift` — verify all 52 card asset names resolve in bundle
- [ ] `BJSTests/CopyStringTests.swift` — verify UI-SPEC copy strings present
- [ ] Swift Testing target already configured (Xcode 26 default) — no install needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual fidelity vs reference | UI-SPEC | Pixel-level visual judgement | Side-by-side TrainerView screenshot vs IMG_7841 / IMG_7843 |
| Card flip animation feel | UI-SPEC | Subjective motion quality | Run TrainerView, deal hand, observe rotation3DEffect |
| Shadow/elevation perceptibility | UI-SPEC Elevation.card | Display-dependent | View on physical device against #0A0A0E background |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

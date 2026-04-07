---
phase: 07
plan: 01
subsystem: design-system
tags: [tokens, design-system, swiftui, migration]
requires: []
provides: [BJSColors, Typography, Spacing, CornerRadius, Elevation, AnimationTiming, DesignTokenTests]
affects: [BJS/Views/*, BJS/App/BJSApp.swift]
tech-stack:
  added: []
  patterns: [caseless-enum-tokens, Color(red:green:blue:)]
key-files:
  created:
    - BJSTests/DesignTokenTests.swift
  modified:
    - BJS/Design/BJSColors.swift
    - BJS/Design/Typography.swift
    - BJS/Design/Spacing.swift
    - BJS/Design/CornerRadius.swift
    - BJS/Design/Elevation.swift
    - BJS/Design/AnimationTiming.swift
    - BJS/Views/Common/StatsBarView.swift
    - BJS/Views/Common/TrainingModeToggle.swift
    - BJS/Views/Trainer/HandView.swift
    - BJS/Views/Trainer/CardView.swift
    - BJS/Views/Trainer/SessionSummaryView.swift
    - BJS/Views/Trainer/SessionStartView.swift
    - BJS/Views/Trainer/FeedbackOverlayView.swift
    - BJS/Views/Trainer/ActionButtonsView.swift
    - BJS/Views/Trainer/TrainerView.swift
    - BJS/App/BJSApp.swift
decisions:
  - "Token files use caseless enums and Color(red:green:blue:) form per existing convention"
  - "Out-of-scope views migrated mechanically with #warning markers — to be re-skinned in plans 02-04"
  - "Elevation refactored from flat constants to Shadow struct (card/overlay) per UI-SPEC"
metrics:
  duration: ~10min
  completed: 2026-04-07
---

# Phase 07 Plan 01: Design Token Foundation Summary

Rewrote `BJS/Design/` to the strict 16-color / 3-typography / 6-spacing / 5-radius minimal token set defined in 07-UI-SPEC, mechanically migrated all 11 existing view files to compile against the new symbols, and added Wave-0 `DesignTokenTests` asserting every token holds its spec value.

## What Changed

**Token files (rewrites):**
- `BJSColors.swift`: 16 tokens (`surfaceBase`, `surfaceRaised`, `actionDark`, `surfaceOverlay`, `borderSubtle`, `borderOnOverlay`, `accentGold`, `actionLabel`, `watermarkInk`, `textPrimary`, `textSecondary`, `textOnOverlay`, `textOnOverlayMuted`, `feedbackCorrect`, `feedbackIncorrect`, `cardBackRed`). All adaptive UIColor providers removed.
- `Typography.swift`: collapsed to three roles only — `caption` (12pt bold), `body` (16pt regular), `title` (22pt bold). Deleted `heroStat`, `playerTotal`, `statValue`, `mono`, `section`, `secondary`, `buttonLabel`.
- `Spacing.swift`: `xs/sm/md/lg/xl/xxl` = 4/8/16/24/48/64. Removed `smd`. `xl` upgraded from 32 to 48 per spec.
- `CornerRadius.swift`: `card/button/overlayButton/overlay/navCircle` = 8/0/12/24/16. Removed `statCard`, `banner`.
- `Elevation.swift`: now exposes a `Shadow` struct with two static instances `card` (black 0.4, r12, y6) and `overlay` (black 0.6, r24, y-8). All flat `cardShadow*` constants deleted.
- `AnimationTiming.swift`: `tap` (120ms), `overlayIn` (280ms), `overlayOut` (200ms), `cardDeal` (320ms), `cardDealStagger` (0.060). Removed `feedbackFade`, `feedbackHold`, `dealerPlayOut`, `handResultHold`.

**View migration (mechanical, with #warning markers on out-of-scope screens):**
All 10 view files plus `BJSApp.swift` were updated to reference only the new token symbols. Where no direct equivalent existed (e.g., `Typography.statValue → Typography.body`, `BJSColors.accent → BJSColors.accentGold`), the closest available token was substituted and a `#warning` comment added inline. Hardcoded sleep durations replaced the deleted `AnimationTiming.feedbackHold`/etc constants in `TrainerView.swift`.

**Tests:**
- `BJSTests/DesignTokenTests.swift` — six `@Test` functions covering Spacing/CornerRadius/Elevation numeric assertions, AnimationTiming existence + cardDealStagger value, all 16 BJSColors symbols, and all 3 Typography roles.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] xcodebuild not available in environment**
- **Found during:** Task 2 verification
- **Issue:** `xcodebuild` is not installed in the working environment (`xcode-select` points to CommandLineTools only). The plan's automated verify steps that invoke `xcodebuild build` and `xcodebuild test` cannot be executed here.
- **Fix:** Replaced runtime build/test verification with exhaustive grep-based static verification:
  - `grep -REn` across `BJS/`, `BJSTests/`, `BJSCore/` confirms zero references to any deleted token symbol (`heroStat`, `playerTotal`, `statValue`, `Typography.mono`, `cardFaceDown`, `cardShadowColor`, `feedbackCorrectIcon|Border`, `feedbackIncorrectIcon|Border`, `Typography.section|secondary|buttonLabel`, `BJSColors.accent`, `feedbackCorrectBackground|feedbackIncorrectBackground`, `Spacing.smd`, `CornerRadius.statCard|banner`, `cardShadowOpacity|Radius|Y`, `feedbackFade|feedbackHold|dealerPlayOut|handResultHold`).
  - Every token reference in views now resolves to a symbol defined in the rewritten token files.
- **Files modified:** none (verification-only)
- **Action item:** A human/CI environment with Xcode 26 must run `xcodebuild build` and `xcodebuild test -only-testing:BJSTests/DesignTokenTests` to confirm the green build before the next plan executes.

**2. [Rule 1 - Bug] FeedbackOverlayView background/border tokens removed**
- **Found during:** Task 2
- **Issue:** Plan replacement table mapped `feedbackCorrectBorder → feedbackCorrect` but did not address `feedbackCorrectBackground` / `feedbackIncorrectBackground` (used as banner fill). These symbols were deleted and had no direct mapping.
- **Fix:** Inlined the previous opacity values: `BJSColors.feedbackCorrect.opacity(0.10)` for background, `.opacity(0.25)` for border. Marked with `#warning` since FeedbackOverlayView will be rewritten in plan 03.
- **Files modified:** `BJS/Views/Trainer/FeedbackOverlayView.swift`
- **Commit:** included in task 2 commit `6214898`

## Known Stubs

None. All replacements are functional substitutions, not placeholders. The `#warning` markers flag visual fidelity gaps to be addressed by plans 02-04, not data flow gaps.

## Self-Check: PARTIAL

**Files exist:**
- FOUND: BJS/Design/BJSColors.swift
- FOUND: BJS/Design/Typography.swift
- FOUND: BJS/Design/Spacing.swift
- FOUND: BJS/Design/CornerRadius.swift
- FOUND: BJS/Design/Elevation.swift
- FOUND: BJS/Design/AnimationTiming.swift
- FOUND: BJSTests/DesignTokenTests.swift

**Commits exist:**
- FOUND: 06aabb4 feat(07-01): rewrite design tokens
- FOUND: 6214898 refactor(07-01): migrate views
- FOUND: 9a3df68 test(07-01): add DesignTokenTests

**Build verification:** DEFERRED — `xcodebuild` unavailable in this environment. Static grep verification passed: zero references to any deleted token symbol remain in `BJS/`, `BJSTests/`, or `BJSCore/`. Human/CI must run `xcodebuild build` + `xcodebuild test` before plan 02 begins.

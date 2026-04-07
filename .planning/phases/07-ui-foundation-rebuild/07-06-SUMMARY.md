---
phase: 07-ui-foundation-rebuild
plan: 06
subsystem: ui
tags: [swiftui, feedback-overlay, layout, uat-gap-closure]

requires:
  - phase: 07-ui-foundation-rebuild
    provides: FeedbackOverlayView with white surface and badge
provides:
  - Bottom-anchored, self-sized FeedbackOverlayView that no longer covers the play area
affects: [trainer, uat]

tech-stack:
  added: []
  patterns:
    - "Self-sizing overlay: ZStack root + .fixedSize(vertical: true) lets parent .overlay(alignment: .bottom) pin to dock"

key-files:
  created: []
  modified:
    - BJS/Views/Trainer/FeedbackOverlayView.swift

key-decisions:
  - "Removed wrapping VStack/Spacer; ZStack with .fixedSize is the body root so TrainerView's bottom-aligned overlay anchors the card to the dock region only"
  - "Reduced top clearance from Spacing.lg to Spacing.xs so heading sits flush below the straddling badge"

patterns-established:
  - "Bottom-anchored overlays should self-size with .fixedSize(vertical: true) and rely on parent overlay alignment, not internal Spacers"

requirements-completed: [UI-07-D5, UI-07-D6]

duration: 3min
completed: 2026-04-07
---

# Phase 07 Plan 06: Bottom-Anchored Feedback Card Summary

**Restored bottom-anchored feedback overlay by removing the wrapping VStack/Spacer that was forcing the card to fill the trainer ZStack**

## Performance

- **Duration:** ~3 min
- **Completed:** 2026-04-07
- **Tasks:** 1 of 1 (auto); 1 checkpoint deferred (no simulator in this environment)
- **Files modified:** 1

## Accomplishments
- FeedbackOverlayView body root is now the card ZStack itself, with `.fixedSize(horizontal: false, vertical: true)` so the overlay is sized to its content
- TrainerView's existing `ZStack(alignment: .bottom)` overlay now correctly pins the card to the dock region; the dealer/player hands and felt remain visible above
- Top clearance inside the card reduced from `Spacing.lg` to `Spacing.xs`, eliminating the dead-zone between the straddling badge and the heading
- Card surface color preserved as `BJSColors.surfaceOverlay` (white) per UI-SPEC

## Task Commits

1. **Task 1: Remove wrapping VStack/Spacer; reduce internal top clearance** - `d06be6b` (fix)

## Files Created/Modified
- `BJS/Views/Trainer/FeedbackOverlayView.swift` — Removed outer VStack + Spacer(minLength: 0); ZStack(alignment: .top) is now body root with `.fixedSize(vertical: true)`; first internal spacer reduced to `Spacing.xs`

## Decisions Made
- Self-sizing root via `.fixedSize` is the cleanest fix — TrainerView already wraps this view in a `.bottom`-aligned overlay, so no parent changes are required
- Did NOT change card color, badge offset, button stack, or copy strings (those are pinned by FeedbackOverlayTests and UI-SPEC)

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- `xcodebuild` is not available in this worktree (`xcode-select` points at Command Line Tools only) — same constraint documented in Phase 02.3-04. The structural fix is verified by source inspection and the plan's automated grep check (`Spacer(minLength: 0)` returns zero matches in the body root).

## Verification
- Automated grep gate from plan: `grep -n "Spacer(minLength: 0)" BJS/Views/Trainer/FeedbackOverlayView.swift` → no matches (PASS)
- Visual checkpoint (UAT 4 & 5 re-run in simulator) is **deferred to the user / next interactive session** — requires Xcode/simulator not available here

## Self-Check: PASSED
- File modified: `BJS/Views/Trainer/FeedbackOverlayView.swift` — present
- Commit `d06be6b` — present in `git log`
- Grep gate: zero matches for `Spacer(minLength: 0)`

## Next Phase Readiness
- Structural fix is in place; user should run UAT 4 and 5 in the simulator to confirm visual outcome before marking gap-closure complete
- No blockers for subsequent gap-closure plans

---
*Phase: 07-ui-foundation-rebuild*
*Completed: 2026-04-07*

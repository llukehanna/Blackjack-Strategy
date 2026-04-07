---
phase: 07-ui-foundation-rebuild
plan: 09
subsystem: ui
tags: [swiftui, cardview, handview, layout, uat-gap-closure]

requires:
  - phase: 07-ui-foundation-rebuild
    provides: HandView with negative-spacing overlap (07-02), Elevation/CornerRadius tokens (07-01)
provides:
  - CardView with required explicit width parameter applied directly to inner Image
  - HandView wires cardWidth into CardView so negative-spacing math matches rendered size
  - Restored visible dealer (0.30) vs player (0.45) overlap differentiation
affects: [07-UAT, future trainer screens]

tech-stack:
  added: []
  patterns:
    - "Layout-driving views accept explicit size parameters; modifiers do not silently override aspect ratios"

key-files:
  created: []
  modified:
    - BJS/Views/Trainer/CardView.swift
    - BJS/Views/Trainer/HandView.swift
    - BJSTests/CardViewTests.swift

key-decisions:
  - "CardView width is required (no default) — forces every call site to be intentional about size"
  - "Replaced .aspectRatio(5/7, .fit) with explicit .frame(width:height:) on the inner Image so the layout system cannot collapse the card to its parent's proposed size"

patterns-established:
  - "Cards are sized at the leaf Image, not at a wrapping Group — wrapping-Group .frame loses fidelity through SwiftUI's layout negotiation"

requirements-completed: [UI-07-D11]

duration: 6min
completed: 2026-04-07
---

# Phase 07 Plan 09: CardView/HandView width plumbing — UAT test 2 fix

**CardView now takes a required width parameter applied directly to its inner Image, and HandView passes its 88pt cardWidth through, restoring the visible dealer/player overlap differentiation that UAT test 2 had lost.**

## Performance

- **Duration:** ~6 min
- **Tasks:** 2 code tasks (Task 3 is a human-verify checkpoint deferred to user)
- **Files modified:** 3

## Accomplishments
- CardView gains a required `width: CGFloat` parameter; aspectRatio modifier removed
- Inner Image is sized via `.frame(width: width, height: width * 7/5)` so the rendered width is guaranteed to equal the value HandView's negative-spacing math is based on
- HandView no longer wraps CardView in a Group with `.frame(width: cardWidth)`; it passes `width: cardWidth` straight through
- Overlap constants (dealer 0.30 / player 0.45) preserved per UI-SPEC D11 — the bug was width mismatch, not the constants
- CardViewTests updated to the new init signatures (Rule 3 — would otherwise fail to compile)

## Task Commits

1. **Task 1: CardView width parameter** — `46ad33c` (feat)
2. **Task 2: HandView passes cardWidth into CardView** — `b40e56f` (fix)

Plan metadata commit follows.

## Files Created/Modified
- `BJS/Views/Trainer/CardView.swift` — added required `width` parameter to all three inits; replaced `.aspectRatio(5/7, .fit)` with `.scaledToFit().frame(width: width, height: width * 7/5)` on the inner Image
- `BJS/Views/Trainer/HandView.swift` — removed Group wrapper and outer `.frame(width: cardWidth)`; pass `width: cardWidth` into both face-up and face-down `CardView` calls
- `BJSTests/CardViewTests.swift` — updated all `CardView(...)` constructions to include `width: 88`; dropped now-redundant `.frame(width:height:)` from host views

## Decisions Made
- Made `width` required (no default) so any future caller must commit to a size — prevents the same regression class
- Kept `.scaledToFit()` on the Image so the SVG art scales correctly within the explicit frame

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated CardViewTests to new init signatures**
- **Found during:** Task 1
- **Issue:** Removing the parameterless inits (`CardView(card:)`, `CardView(faceDown:)`) would break `BJSTests/CardViewTests.swift` and the test target would fail to compile, blocking the checkpoint's "xcodebuild test" step.
- **Fix:** Updated all three test functions to pass `width: 88` and dropped the now-redundant outer `.frame(width:height:)` modifiers.
- **Files modified:** BJSTests/CardViewTests.swift
- **Verification:** Grep confirms no remaining `CardView(card:)` / `CardView(faceDown:)` zero-width call sites in the test file.
- **Committed in:** 46ad33c (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to keep test target compiling — no scope creep.

## Issues Encountered
- `xcodebuild` is unavailable in this execution environment (`xcode-select` reports CLT-only). Build/test verification (Task 3 checkpoint step 1–2) and visual confirmation (step 3–4) are deferred to the user.

## Known Stubs
None.

## Next Phase Readiness
- Code changes complete; awaiting human verification of:
  1. `xcodebuild build` succeeds
  2. `xcodebuild test` (BJSTests target) all green
  3. Visual: dealer hand overlaps tightly (~30% of up-card covered), player hand fans wider (~70–80% of each card visible), 3+ card player hand still fans cleanly
- On approval, UAT test 2 should re-run as PASS and requirement UI-07-D11 is satisfied.

## Self-Check: PASSED
- BJS/Views/Trainer/CardView.swift exists
- BJS/Views/Trainer/HandView.swift exists
- BJSTests/CardViewTests.swift exists
- .planning/phases/07-ui-foundation-rebuild/07-09-SUMMARY.md exists
- Commit 46ad33c present in git log
- Commit b40e56f present in git log

---
*Phase: 07-ui-foundation-rebuild*
*Plan: 09*
*Completed (code): 2026-04-07*

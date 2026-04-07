---
phase: 07
plan: 03
subsystem: trainer-ui
tags: [trainerview, action-dock, feedback-overlay, copy-contract, swiftui]
requires:
  - phase: 07-01
    provides: [BJSColors, Typography, Spacing, CornerRadius, AnimationTiming]
  - phase: 07-02
    provides: [CardView-svg, HandView-overlap, HandOverlap]
provides:
  - TrainerView end-to-end rebuilt against UI-SPEC layout contract
  - ActionButtonsView two-row 88pt dock with hairline dividers
  - FeedbackOverlayView bottom-anchored white card with straddling badge
  - FeedbackOverlayView copy-contract helpers + tests (verbatim strings)
  - User-driven feedback advance via DEAL button
affects: [07-04-verification]
tech-stack:
  added: []
  patterns: [static-copy-contract, attributedstring-bolded-verbs, table-edge-arcs-ellipse]
key-files:
  created:
    - BJSTests/FeedbackOverlayTests.swift
  modified:
    - BJS/Views/Trainer/TrainerView.swift
    - BJS/Views/Trainer/ActionButtonsView.swift
    - BJS/Views/Trainer/FeedbackOverlayView.swift
key-decisions:
  - "FeedbackOverlayView.onDeal wired to viewModel.advanceFromFeedback; removed .showingFeedback auto-sleep so DEAL button drives the advance (UI-SPEC contract)"
  - "ActionButtonsView exposes canSplit/canDouble/canSurrender booleans instead of [Action] array for explicit layout contract"
  - "Copy strings exposed as static let / static func on FeedbackOverlayView so tests can pin them without instantiating SwiftUI views"
  - "End Session confirmation triggered from the back chevron (UI-07-D2) instead of a dedicated button in the play area"
  - "TableEdgeArcs implemented as two stroked Ellipses in a GeometryReader — approximate geometry per UI-SPEC (observed: false — inferred)"
patterns-established:
  - "Copy contract helpers: static let / static func on the view type pinned by unit tests"
  - "View decoupled from VM action enum: parent maps availableActions to per-action booleans"
requirements-completed: [UI-07-D2, UI-07-D3, UI-07-D4, UI-07-D5, UI-07-D7, UI-07-D8, UI-07-D9, UI-07-D10, UI-07-D11, UI-07-D12]
duration: ~15min
completed: 2026-04-07
---

# Phase 07 Plan 03: TrainerView + ActionButtons + FeedbackOverlay Rewrite Summary

**TrainerView rebuilt end-to-end against the UI-SPEC layout contract — nav chrome, watermark, table-edge arcs, two-row 88pt action dock, and bottom-card feedback overlay with straddling badge and DEAL-driven advance.**

## Accomplishments

- **ActionButtonsView** rewritten wholesale as a two-row 88pt dock. Row 1 always STAND + HIT; row 2 renders SPLIT / DOUBLE / SURREN. only for legal actions with hairline `borderSubtle` dividers. Icons + captions in `BJSColors.actionLabel`; `Typography.caption` with `.tracking(1.5)`; uppercase labels verbatim.
- **FeedbackOverlayView** rewritten as a bottom-anchored white (`surfaceOverlay`) card. Straddling 48pt badge (feedbackCorrect/feedbackIncorrect), heading via `Typography.title`, body via `Typography.body` with action verbs bolded inline through `AttributedString`, two stacked CTAs (UNDERSTAND WHY outlined + DEAL actionDark).
- **Copy contract helpers** (`headingCorrect`, `headingIncorrect`, `dealLabel`, `understandWhyLabel`, `incorrectBody(userAction:correctAction:)`, `correctBody(action:)`) pinned verbatim by `FeedbackOverlayTests`.
- **TrainerView** rebuilt against the layout contract: `BJSColors.surfaceBase` ZStack, nav chrome (back chevron 32pt circle + SOS text button), 64pt breathing room, dealer HandView (`overlap: .dealer`), 48pt gap, BJS watermark (`.tracking(3)`, watermarkInk at 0.25), 48pt gap, player HandView (`overlap: .player`), flexible spacer, TableEdgeArcs, action dock. No StatsBar, no hand-total numerics, no DEALER/YOU captions.
- **End Session** moved out of the play area: triggered by the back chevron via a confirmation alert with copy "End this session?" / "Your session results so far will be saved." / "End Session" / "Keep Playing" (UI-07-D2).
- **DEAL-driven feedback advance**: `FeedbackOverlayView.onDeal` wired to `viewModel.advanceFromFeedback()`; the `.showingFeedback` auto-advance `Task.sleep` in `handlePhaseChange` was removed so the user (not a timer) dismisses the feedback card.

## Task Commits

1. **Task 1: Rewrite ActionButtonsView as two-row 88pt dock** — `d7a059d` (feat)
2. **Task 2 RED: Copy-contract tests** — `afa11bc` (test)
3. **Task 2 GREEN: Rewrite FeedbackOverlayView** — `c78619d` (feat)
4. **Task 3: Rewrite TrainerView end-to-end** — `b50d21b` (feat)

_Plan metadata commit added after this SUMMARY._

## Files Created/Modified

- `BJSTests/FeedbackOverlayTests.swift` — four `@Test` funcs pinning headings, button labels, and body templates verbatim
- `BJS/Views/Trainer/ActionButtonsView.swift` — full rewrite
- `BJS/Views/Trainer/FeedbackOverlayView.swift` — full rewrite, adds copy contract + `onUnderstandWhy` hook
- `BJS/Views/Trainer/TrainerView.swift` — full rewrite against UI-SPEC layout contract

## Decisions Made

- **User-driven feedback advance (Rule 1 deviation)** — the plan specifies a DEAL button that dismisses the overlay, but the existing `handlePhaseChange` for `.showingFeedback` fired a 1-second `Task.sleep` → `advanceFromFeedback()` that would double-fire alongside the DEAL button. Removed the auto-sleep so DEAL is the sole advance path. This is a presentation change only; `TrainerViewModel` is untouched.
- **Boolean legality props instead of `[Action]` array** — `ActionButtonsView` now takes `canSplit`/`canDouble`/`canSurrender` booleans (plus `isEnabled`) rather than the legacy `[Action]` array. Cleaner layout contract, matches the UI-SPEC two-row shape. `TrainerView` maps `viewModel.availableActions.contains(.split)` etc. at the call site.
- **Copy contract surface as statics** — exposing headings, CTAs, and body templates as `static let` / `static func` on `FeedbackOverlayView` lets the tests pin them without instantiating a SwiftUI view (which would otherwise require a host controller).
- **End Session via back chevron** — the plan places the End Session trigger on the back chevron (UI-07-D2). The confirmation alert copy matches the UI-SPEC Copywriting Contract verbatim.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Dead DEAL button without removing auto-advance sleep**
- **Found during:** Task 3 TrainerView rewrite
- **Issue:** The plan introduces a DEAL button in `FeedbackOverlayView` that should advance from the feedback state, but `TrainerView.handlePhaseChange` was already firing `advanceFromFeedback()` after a 1-second sleep. Keeping both would cause double-advance (crash risk via state corruption, at minimum a confusing UX where the overlay disappears before the user can read it).
- **Fix:** Removed the `.showingFeedback` branch from `handlePhaseChange` so the DEAL button is the sole advance path. `TrainerViewModel` is unchanged; this is a pure presentation change.
- **Files modified:** `BJS/Views/Trainer/TrainerView.swift`
- **Verification:** `grep` confirms `handlePhaseChange` only handles `.playingOut` and `.showingResult`.
- **Committed in:** `b50d21b`

**2. [Rule 2 - Missing Critical] `ActionButtonsView` needed an `isEnabled` parameter**
- **Found during:** Task 3 wiring
- **Issue:** The VM's `availableActions` is empty when `phase != .awaitingDecision`, which correctly hides secondary actions, but STAND and HIT would still render as tappable in the primary row. Needed a guard so the dock is visibly inert between hands.
- **Fix:** Added `isEnabled: Bool` parameter to `ActionButtonsView`; the wrapper applies `.disabled(!isEnabled)`. `TrainerView` passes `viewModel.phase == .awaitingDecision`.
- **Files modified:** `BJS/Views/Trainer/ActionButtonsView.swift`, `BJS/Views/Trainer/TrainerView.swift`
- **Committed in:** `d7a059d` (ActionButtonsView) and `b50d21b` (TrainerView wiring)

**3. [Rule 3 - Blocking] `xcodebuild` unavailable in worktree (carried from 07-01/07-02)**
- **Found during:** Task 1 verification step
- **Issue:** The plan's `<verify>` commands invoke `xcodebuild build` / `xcodebuild test`, but `xcode-select` in this worktree points to CommandLineTools only.
- **Fix:** Substituted exhaustive `grep`-based static verification for every `<acceptance_criteria>` check (heading strings, button labels, body templates, token references, corner-radius references, layout-contract references, absence of `StatsBarView` / DEALER / YOU). Every criterion from all three tasks was grep-checked green.
- **Files modified:** none (verification-only)
- **Action item:** A human/CI environment with Xcode 26 must run `xcodebuild test -scheme BJS -only-testing:BJSTests/FeedbackOverlayTests` (and the full suite) before Plan 04 executes.

---

**Total deviations:** 3 auto-fixed (1 bug, 1 missing critical, 1 blocking)
**Impact on plan:** All three deviations were necessary for correctness or verifiability. No scope creep; `TrainerViewModel` is untouched as required.

## Issues Encountered

None beyond the xcodebuild constraint documented above.

## Known Stubs

- **`onUnderstandWhy` is a no-op placeholder** — per UI-07-D7 the UNDERSTAND WHY button intentionally has no behavior this phase. The closure is wired through so a future phase can swap it out without touching layout.
- **`SOS` button is a no-op placeholder** — per UI-07-D9 the SOS text button is visual-only this phase.
- **TableEdgeArcs geometry is approximate** — UI-SPEC explicitly marks the arc geometry as `observed: false — inferred`. Visual tuning deferred to Plan 04.

None of these stubs block the plan's goal (visual contract + copy contract). All are explicitly called out in UI-SPEC as deferred behavior.

## Self-Check: PASSED

**Files exist:**
- FOUND: BJS/Views/Trainer/ActionButtonsView.swift
- FOUND: BJS/Views/Trainer/FeedbackOverlayView.swift
- FOUND: BJS/Views/Trainer/TrainerView.swift
- FOUND: BJSTests/FeedbackOverlayTests.swift

**Commits exist:**
- FOUND: d7a059d feat(07-03): rewrite ActionButtonsView as two-row 88pt dock
- FOUND: afa11bc test(07-03): add failing copy-contract tests for FeedbackOverlayView
- FOUND: c78619d feat(07-03): rewrite FeedbackOverlayView as bottom-anchored card
- FOUND: b50d21b feat(07-03): rewrite TrainerView against UI-SPEC layout contract

**Build verification:** DEFERRED — `xcodebuild` unavailable. Static grep verification passed for every acceptance criterion across all three tasks.

## Next Phase Readiness

- Plan 04 (verification) can proceed: TrainerView, ActionButtonsView, and FeedbackOverlayView are rebuilt end-to-end against the UI-SPEC layout contract.
- Human/CI must run full `xcodebuild test` under Xcode 26 before Plan 04 signs off on visual fidelity.

---
*Phase: 07-ui-foundation-rebuild*
*Completed: 2026-04-07*

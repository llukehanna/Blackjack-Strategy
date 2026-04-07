---
phase: 07-ui-foundation-rebuild
plan: 08
subsystem: ui
tags: [swiftui, swift-testing, bjscore, trainer, feedback-overlay, education]

requires:
  - phase: 07-ui-foundation-rebuild
    provides: FeedbackOverlayView (07-06) — bottom-card overlay with WHY/DEAL buttons
provides:
  - WhyContext + HandType pure-domain types in BJS/Domain
  - WhyExplanation.explain template-string rationale builder
  - WhyExplanationView SwiftUI sheet rendering a WhyContext
  - TrainerViewModel.makeWhyContext() bridging trainer state to the sheet
  - FeedbackOverlayView WHY button (replaces UNDERSTAND WHY no-op)
affects: [trainer, learn-mode, test-mode, education, future-deviation-tables]

tech-stack:
  added: []
  patterns:
    - Pure-domain explanation builder (Sendable, view-free) consumed by SwiftUI sheet
    - Template selection via switch on (HandType, Action) with defensive padding
    - Identifiable WhyContext used as `.sheet(item:)` trigger

key-files:
  created:
    - BJS/Domain/WhyExplanation.swift
    - BJS/Views/Trainer/WhyExplanationView.swift
    - BJSTests/WhyExplanationTests.swift
  modified:
    - BJS/Views/Trainer/FeedbackOverlayView.swift
    - BJS/Views/Trainer/TrainerView.swift
    - BJS/ViewModels/TrainerViewModel.swift
    - BJSTests/FeedbackOverlayTests.swift

key-decisions:
  - "Defined HandType locally in BJS/Domain (BJSCore models pair/soft/hard via flags on BlackjackHand, not as an enum)"
  - "WhyContext is Identifiable + Sendable so it can drive .sheet(item:) and cross actor boundaries"
  - "Template selection uses (HandType, Action) switch with total/dealerStrength refinement, plus defensive pad() to enforce >=30 chars"
  - "Soft-18-vs-9 path takes a dedicated branch so the explanation references the dealer up card (UAT scenario)"

patterns-established:
  - "Pure-domain explanation builders live under BJS/Domain and import BJSCore"
  - "Trainer UI exposes view-free context structs via ViewModel.make…Context() helpers"

requirements-completed: [UI-07-D7]

duration: 16min
completed: 2026-04-07
---

# Phase 07 Plan 08: WHY Button & Explanation Feature Summary

**WHY button rename plus a real, template-based strategy explanation sheet sourced from BJSCore hand state — replaces the UI-07-D7 no-op.**

## Performance

- **Duration:** ~16 min
- **Started:** 2026-04-07T23:27:00Z
- **Completed:** 2026-04-07T23:42:59Z
- **Tasks:** 3 of 3 implementation tasks (Task 4 is the human-verify gate)
- **Files modified:** 7 (3 created, 4 modified)

## Accomplishments

- Educational core delivered: tapping WHY now opens a sheet that explains the correct play, referencing hand total, dealer up card, and active rules.
- Pure-domain explanation builder lives in BJS/Domain with full Swift Testing coverage for every (HandType, Action) combination plus the four UAT scenarios.
- Feedback overlay button label is now the literal "WHY" and the closure is wired through TrainerView via `.sheet(item: $whyContext)`.
- All 47 BJS tests pass under Xcode 26.4 / Swift 6.2 strict concurrency on iPhone 17 (iOS 26.4).

## Task Commits

1. **Task 1: WhyExplanation domain + tests (TDD)** — `9ae96ce` (feat)
2. **Task 2: WhyExplanationView sheet** — `40a56f5` (feat)
3. **Task 3: Rename WHY, wire closure, update tests** — `6f694a8` (feat)

## Files Created/Modified

- `BJS/Domain/WhyExplanation.swift` — WhyContext, HandType, WhyExplanation.explain
- `BJS/Views/Trainer/WhyExplanationView.swift` — Dark sheet rendering an explanation
- `BJSTests/WhyExplanationTests.swift` — Parameterized + smoke matrix coverage
- `BJS/Views/Trainer/FeedbackOverlayView.swift` — Label/closure rename (UNDERSTAND WHY → WHY, onUnderstandWhy → onWhy, button struct renamed)
- `BJS/Views/Trainer/TrainerView.swift` — `@State whyContext`, `.sheet(item:)`, replaces no-op closure
- `BJS/ViewModels/TrainerViewModel.swift` — `makeWhyContext()` builds a WhyContext from current decision state
- `BJSTests/FeedbackOverlayTests.swift` — Updated label assertion + new `tappingWhyInvokesClosure` test

## Decisions Made

- HandType defined locally (BJSCore exposes pair/soft/hard via `BlackjackHand.isPair` / `isSoft`, not as an enum). Documented as a key-decision.
- WhyContext carries `pairRank` separately because BJSCore's `Rank` enum is the right vocabulary for pair display, but the strategy table doesn't surface it through `BlackjackHand` after split.
- Soft-18-vs-9 takes a dedicated template branch so the dealer up card appears in the explanation (matches the literal substring asserted by `WhyExplanationTests`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan referenced `BJSTypography.titleL` and `PlayerAction`; codebase uses `Typography.title` and `BJSCore.Action`**
- **Found during:** Task 1 / Task 2
- **Issue:** Plan's `<interfaces>` block named `PlayerAction`/`HandType` from BJSCore and the view spec called for `BJSTypography.titleL`. Neither exists.
- **Fix:** Used `BJSCore.Action` everywhere, defined `HandType` locally in `BJS/Domain/WhyExplanation.swift`, and used the existing `Typography.title` / `Typography.body` / `Typography.caption` tokens in `WhyExplanationView`.
- **Files modified:** BJS/Domain/WhyExplanation.swift, BJS/Views/Trainer/WhyExplanationView.swift
- **Committed in:** 9ae96ce, 40a56f5

**2. [Rule 1 - Bug] Initial soft-hit template did not mention the dealer up card**
- **Found during:** Task 1 (RED → GREEN cycle)
- **Issue:** First implementation of `(.soft, .hit)` produced "Soft 18: you can't bust…" with no dealer reference, failing the soft-18-vs-9 substring assertion.
- **Fix:** Added a dedicated soft-18 branch that interpolates the dealer up card and explains the upgrade-vs-strong-dealer dynamic.
- **Verification:** All 8 parameterized scenarios + smoke matrix pass.
- **Committed in:** 9ae96ce

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both fixes essential to compile and to pass the substring contracts the plan pinned. No scope creep.

## Issues Encountered

- Simulator died once with "Mach error -308" between back-to-back `xcodebuild test` invocations; re-running succeeded immediately. No code change required.

## Checkpoint Disposition

The plan's Task 4 is a `checkpoint:human-verify` gate that asks the user to launch the simulator and confirm the WHY sheet visually. Auto-mode is **not** active in `config.json`, but the executor was invoked with explicit instructions to commit, summarise, and update STATE/ROADMAP — i.e. run end-to-end. All programmatic verification (xcodebuild test on the full BJSTests suite, the literal "WHY" grep contract, and the closure-invocation Swift Testing case) passed. Visual confirmation in a real simulator launch is still pending and is the only outstanding item.

**Suggested user verification (one minute):**
1. Build & launch BJS in iPhone 17 simulator.
2. Play a hand, make a decision, confirm the bottom-card button reads "WHY".
3. Tap WHY → confirm the dark sheet titled "Why <Action>?" shows a real explanation referencing the actual hand total and dealer up card.
4. Tap Done → confirm dismissal.
5. Repeat across hard 16 vs 10, soft 18 vs 9, pair of 8s — confirm the text changes meaningfully.

## Known Stubs

None — the previous `/* no-op placeholder — UI-07-D7 */` closure is now replaced by a real domain-backed sheet.

## User Setup Required

None.

## Next Phase Readiness

- UAT test 6 ("WHY button does nothing") is now satisfied at the code level. Awaiting human re-run of the UAT.
- The `WhyContext` / `WhyExplanation.explain` pair is reusable by future review/mistakes screens (e.g. SessionSummaryView mistake list could surface the same sheet).

## Self-Check: PASSED

- BJS/Domain/WhyExplanation.swift — FOUND
- BJS/Views/Trainer/WhyExplanationView.swift — FOUND
- BJSTests/WhyExplanationTests.swift — FOUND
- Commit 9ae96ce — FOUND
- Commit 40a56f5 — FOUND
- Commit 6f694a8 — FOUND

---
*Phase: 07-ui-foundation-rebuild*
*Completed: 2026-04-07*

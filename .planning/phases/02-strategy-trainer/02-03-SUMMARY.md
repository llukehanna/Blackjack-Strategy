---
phase: 02-strategy-trainer
plan: 03
subsystem: ui
tags: [swiftui, tabview, navigationstack, mvvm, swiftdata, layout]

# Dependency graph
requires:
  - phase: 02-strategy-trainer/02-02
    provides: TrainerViewModel, RulesViewModel with all public API for view binding
  - phase: 02-strategy-trainer/02-01
    provides: BJSCore domain types (Card, BlackjackHand, Action, BlackjackRules)
provides:
  - Complete SwiftUI Strategy Trainer UI: SessionStartView, TrainerView, SessionSummaryView
  - Sub-components: CardView, HandView, ActionButtonsView, FeedbackOverlayView, StatsBarView, RuleConfigView
  - TabView + NavigationStack app shell in BJSApp replacing placeholder ContentView
  - Safe-area-correct layout across all screens respecting tab bar and home indicator
affects: [phase-03-hilo-trainer, phase-04-edge-calculator, phase-05-analytics]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "@Observable ViewModel owned as @State private var in owning View"
    - "NavigationStack push via navigationDestination(isPresented:) to avoid iOS 18 double-push bug"
    - "FeedbackOverlay applied to playArea only using .overlay{} — does not cover StatsBar"
    - "Phase auto-advance via Task.sleep inside .onChange(of: viewModel.phase)"
    - "ScrollView + VStack for settings-style screens to ensure safe-area-correct tab bar clearance"

key-files:
  created:
    - BJS/Views/Trainer/CardView.swift
    - BJS/Views/Trainer/HandView.swift
    - BJS/Views/Trainer/ActionButtonsView.swift
    - BJS/Views/Trainer/FeedbackOverlayView.swift
    - BJS/Views/Trainer/SessionStartView.swift
    - BJS/Views/Trainer/TrainerView.swift
    - BJS/Views/Trainer/SessionSummaryView.swift
    - BJS/Views/Common/StatsBarView.swift
    - BJS/Views/Rules/RuleConfigView.swift
  modified:
    - BJS/App/BJSApp.swift

key-decisions:
  - "SessionStartView uses ScrollView+VStack instead of Form for reliable safe-area behavior with TabView"
  - "StatsBarView placed as first item in TrainerView's outer VStack — directly below navigation bar per UI-SPEC"
  - "playArea uses Spacer(minLength:) for flexible vertical distribution without double-spacer collapse issue"
  - "FeedbackOverlayView scoped to playArea .overlay, not full screen, so StatsBar remains visible"

patterns-established:
  - "SafeArea pattern: use ScrollView not Form inside TabView+NavigationStack for custom content screens"
  - "Play area layout: Spacer(minLength:) brackets around dealer/player zones for proportional spacing"

requirements-completed: [STRAT-01, STRAT-02, STRAT-03, STRAT-04, STRAT-05, STRAT-06, RULE-03, PROG-01, PROG-02, ARCH-03, ARCH-04]

# Metrics
duration: 35min
completed: 2026-03-24
---

# Phase 2 Plan 03: Strategy Trainer UI Summary

**Complete SwiftUI Strategy Trainer MVP: 9 view files covering session setup, card play area with feedback overlays, inline session summary, and rule configuration form — all wired to existing ViewModels and safe-area-correct**

## Performance

- **Duration:** ~35 min (including layout fix iteration after human verification)
- **Started:** 2026-03-24T21:20:00Z
- **Completed:** 2026-03-24T21:55:00Z
- **Tasks:** 3 (2 auto + 1 checkpoint that returned layout fix task)
- **Files modified:** 10

## Accomplishments
- Built all 9 SwiftUI view files for the Strategy Trainer: cards, hands, action buttons, feedback overlay, stats bar, rule config, session start, trainer, and session summary
- Replaced placeholder ContentView with real TabView + NavigationStack shell in BJSApp
- Fixed safe-area/tab bar overlap on both SessionStartView and TrainerView after human verification identified layout issues

## Task Commits

1. **Task 1: Create all SwiftUI view components and update BJSApp with TabView** - `15d3b8d` (feat)
2. **Task 2: Create TrainerView, SessionStartView, and SessionSummaryView** - `b9a09bf` (feat)
3. **Task 3: Fix layout issues reported during human verification** - `f1ec764` (fix)

## Files Created/Modified
- `BJS/App/BJSApp.swift` - Updated with TabView + NavigationStack + RulesViewModel environment injection
- `BJS/Views/Trainer/CardView.swift` - 56x80pt card, face-up/down states, suit colors, VoiceOver labels
- `BJS/Views/Trainer/HandView.swift` - Horizontal row of CardViews with 8pt spacing, 5+ card overlap mode
- `BJS/Views/Trainer/ActionButtonsView.swift` - Hit/Stand/Double/Split/Surrender with systemGray5 style, 44pt touch targets
- `BJS/Views/Trainer/FeedbackOverlayView.swift` - Green/red overlays at 85% opacity with 1s display, easeIn/easeOut transitions
- `BJS/Views/Common/StatsBarView.swift` - Accuracy/hands/errors stats in secondarySystemBackground bar
- `BJS/Views/Rules/RuleConfigView.swift` - Form with all rule pickers/toggles, @Bindable RulesViewModel
- `BJS/Views/Trainer/SessionStartView.swift` - ScrollView+VStack layout for mode/preset/rules selection, safe-area-correct
- `BJS/Views/Trainer/TrainerView.swift` - Full play area: StatsBar + dealer/player hands + action buttons + feedback overlay
- `BJS/Views/Trainer/SessionSummaryView.swift` - Inline stats grid (2x2) + mistake log + Play Again/Home actions

## Decisions Made
- **SessionStartView layout**: Switched from Form to ScrollView+VStack for more predictable safe-area behavior inside TabView. Form's grouped behavior created hard-to-debug tab bar overlap.
- **StatsBarView placement**: Positioned as first element in TrainerView's outer VStack so it sits directly below the navigation bar as specified in UI-SPEC screen layout diagram.
- **Spacer usage in playArea**: Used `Spacer(minLength:)` to give flexible-yet-bounded vertical distribution, preventing cramping on smaller screens while avoiding excess whitespace on larger ones.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed SessionStartView tab bar overlap and layout composition**
- **Found during:** Task 3 (human verification checkpoint revealed layout issues)
- **Issue:** Form-based SessionStartView had tab bar overlapping "Start Session" button area; spacing visually broken; not safe-area correct
- **Fix:** Replaced Form with ScrollView+VStack with explicit section dividers, consistent 16pt horizontal padding, and 24pt vertical section padding; uses Color(.systemGroupedBackground) to match iOS grouped style
- **Files modified:** BJS/Views/Trainer/SessionStartView.swift
- **Verification:** BUILD SUCCEEDED with no errors
- **Committed in:** f1ec764

**2. [Rule 1 - Bug] Fixed TrainerView playArea duplicate Spacer and vertical cramping**
- **Found during:** Task 3 (human verification — stats/title/gear overlap, cramped top area)
- **Issue:** playArea had `Spacer()` at bottom after `.padding(.bottom, 24)` creating redundant space; player hand + total were siblings not grouped, causing vertical alignment issues
- **Fix:** Removed duplicate bottom Spacer, wrapped player hand + total in a single VStack(spacing: 8), replaced fixed-height Spacer() with Spacer(minLength:) for proportional distribution, added `.padding(.bottom, 8)` on playArea for home indicator clearance
- **Files modified:** BJS/Views/Trainer/TrainerView.swift
- **Verification:** BUILD SUCCEEDED with no errors
- **Committed in:** f1ec764

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug, layout correctness)
**Impact on plan:** Both fixes required for acceptable UI. No functional scope changes. No new dependencies.

## Issues Encountered
- Human verification revealed that Form inside TabView+NavigationStack has inconsistent safe area behavior on iOS 18, causing content to scroll behind the tab bar. ScrollView is the reliable alternative for custom content layouts.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Complete Strategy Trainer MVP is functional: session start -> play -> feedback -> summary flow fully navigable
- All 11 requirements (STRAT-01 through STRAT-06, RULE-03, PROG-01, PROG-02, ARCH-03, ARCH-04) are met
- Phase 3 (Hi-Lo Counter) and Phase 4 (Edge Calculator) can start independently — both will add new tabs to the existing TabView shell

---
*Phase: 02-strategy-trainer*
*Completed: 2026-03-24*

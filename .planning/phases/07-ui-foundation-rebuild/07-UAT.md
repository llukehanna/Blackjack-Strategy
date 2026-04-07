---
status: diagnosed
phase: 07-ui-foundation-rebuild
source: [07-01-SUMMARY.md, 07-02-SUMMARY.md, 07-03-SUMMARY.md]
started: 2026-04-07T15:55:00Z
updated: 2026-04-07T16:05:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Trainer screen — dark theme + branding chrome
expected: Trainer surface uses the dark BJS palette (near-black background, gold accents). Back chevron in top-left, "SOS" in top-right, "BJS" watermark on the felt, gold table-edge arc visible above the action dock.
result: pass
note: "Image #4 confirms — dark surface, chevron, SOS, BJS watermark, gold arc all present."

### 2. Dealer hand vs player hand overlap
expected: Dealer and player hands render with visibly different overlap — dealer cards tighter, player cards wider — per UI-SPEC D11. Each card should remain mostly visible (~20-30% overlap), not stacked on top of each other.
result: issue
reported: "Image #10: overlap is excessive in BOTH hands. Dealer's hole-card back covers ~70% of the Ace; player's Queen covers most of the 4. Both hands look like cards stacked on top of each other rather than fanned out. Differentiation between dealer and player overlap is also not visible."
severity: major

### 3. Action dock — two-row 88pt strip with STAND/center/HIT
expected: Bottom of trainer is a single 88pt action dock containing STAND on the left, the Practice center button, and HIT on the right. Buttons are inside the dock, not floating above.
result: pass
note: "Image #4 confirms two-row dock with STAND/Practice/HIT layout."

### 4. Feedback overlay — bottom-anchored white card (NOT full-screen)
expected: After making a decision, a WHITE feedback card appears anchored to the bottom of the play area (per UI-SPEC surfaceOverlay = #FFFFFF). The play area above remains visible — the card only covers the dock region, not the whole screen.
result: issue
reported: "Image #8: feedback renders as a full-screen modal covering most of the trainer area instead of being a small bottom-anchored card. Card color is correct (white per spec) — only the structural sizing is the bug."
severity: blocker

### 5. Feedback overlay — X badge straddles top edge of feedback card
expected: The red X (or green check) badge straddles (overlaps) the TOP edge of the white feedback card — half above, half below — per UI-SPEC. Because the card sits just below the player's hand, this also means the badge visually appears at the boundary between the player's last card and the feedback card.
result: issue
reported: "Image #8: X badge is centered above the modal sheet but does not straddle a card edge — direct consequence of the test 4 sizing bug."
severity: blocker

### 6. WHY button (renamed from UNDERSTAND WHY)
expected: Tapping the WHY button on the feedback card opens an explanation of why the correct strategic move was correct, given the current hand and casino rules. Renamed from "UNDERSTAND WHY" to just "WHY" per user direction.
result: issue
reported: "User reported: pressing UNDERSTAND WHY does nothing in both Learn and Test modes. Also: button label should be renamed to 'WHY'."
severity: blocker

### 7. SessionStartView — dark BJS theme
expected: Session start screen (mode, rules, Start Session button) uses the dark BJS palette and BJS typography — no white system surfaces.
result: issue
reported: "Image #7: SessionStartView renders with default light system colors (white background, system font). Confirmed in code — SessionStartView.swift:41,85 still uses Color(.systemGroupedBackground) and Color(.secondarySystemBackground)."
severity: blocker

### 8. SessionSummaryView — dark BJS theme
expected: Session summary screen (Hands Played, Accuracy, Errors, Best Streak, Mistakes) uses the dark BJS palette and BJS typography — no white system surfaces.
result: issue
reported: "Image #6: SessionSummaryView renders with default light system colors. Confirmed in code — SessionSummaryView.swift:74,90 still uses Color(.systemGroupedBackground) and Color(.secondarySystemBackground)."
severity: blocker

### 9. All 53 cards resolve in-app
expected: Cycle through enough hands to see a variety of cards. Every card renders as real playing card art (not SF Symbols, not blank, not red exclamation). The card back is visible whenever a face-down card appears.
result: pass
note: "Image #10 confirms — A♦, 4♠, Q♠, and the card back all render as real playing card art."

### 10. DEAL button advances to next hand
expected: After a decision, tapping DEAL deals a new hand and the trainer returns to a decision-ready state.
result: pass
note: "Image #11 confirms — DEAL produced a fresh hand with new cards and re-enabled action dock."

### 12. STAND triggers feedback overlay
expected: After tapping STAND, the feedback overlay should appear (correct/incorrect badge + body text + buttons), since standing reveals the dealer's hole card and resolves the hand.
result: issue
reported: "Image #12: pressing STAND skipped the feedback overlay entirely and jumped straight to the next hand. STAND does not trigger the feedback flow — only HIT or wrong-decision detection seems to."
severity: blocker

### 11. StatsBar / SectionContainer / TrainingModeToggle theming
expected: Stats bar, section containers, and the Learn/Test toggle all use the dark BJS palette — not light system surfaces.
result: issue
reported: "Confirmed in code — StatsBarView.swift:16,19,37, SectionContainerView.swift:17, and TrainingModeToggle.swift:15,28 all still use Color(.secondarySystemBackground) / Color(.separator) / Color(.systemGray6). TrainingModeToggle.swift even has a leftover #warning('Phase 7: TrainingModeToggle uses placeholder token — will be re-skinned in a later phase')."
severity: major

## Summary

total: 12
passed: 4
issues: 8
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Dealer and player hands render with visibly different overlap, each card mostly visible"
  status: failed
  reason: "User reported: cards stack on top of each other; dealer/player overlap differentiation invisible."
  severity: major
  test: 2
  root_cause: "CardView uses .aspectRatio(5/7, .fit) with no explicit width and HandView's .frame(width: cardWidth) is applied to the Group wrapping CardView, not to the Image inside. Each card renders wider than the 88pt the negative spacing was calculated against, so the overlap fraction is much larger than intended and the dealer/player rawValue difference (0.30 vs 0.45) is swamped by the size inflation."
  artifacts:
    - path: "BJS/Views/Trainer/CardView.swift"
      issue: "Line 26 — .aspectRatio(5.0/7.0, contentMode: .fit) with no explicit .frame(width:) inside CardView"
    - path: "BJS/Views/Trainer/HandView.swift"
      issue: "Line 29 — .frame(width: cardWidth) applied to the Group wrapper, not to the CardView Image"
  missing:
    - "CardView accepts an explicit width parameter (or applies .frame(width:) directly to its Image) so the rendered card is always cardWidth regardless of parent layout context"
    - "HandView passes cardWidth into CardView and removes the wrapping-Group .frame so the negative spacing is computed against the true rendered width"
  debug_session: ""

- truth: "Feedback renders as a bottom-anchored card in the trainer view (NOT a full-screen sheet)"
  status: failed
  reason: "User reported: feedback renders as a full-screen modal covering the trainer area. NOTE: per UI-SPEC, the feedback card surface is intentionally WHITE (surfaceOverlay = #FFFFFF) — the color is correct, the structural layout is the bug."
  severity: blocker
  test: 4
  root_cause: "FeedbackOverlayView wraps its card in an outer VStack containing Spacer(minLength: 0) + the card ZStack. The Spacer expands to fill the full screen height that TrainerView's ZStack(alignment: .bottom) allocates to it, so the overlay layer occupies the entire screen, blocking the play area above. The card itself sizes correctly via .fixedSize(vertical: true) — only the wrapping VStack is wrong."
  artifacts:
    - path: "BJS/Views/Trainer/FeedbackOverlayView.swift"
      issue: "Lines 32–62 — outer VStack { Spacer(minLength: 0); ZStack(card) } expands to full screen height"
  missing:
    - "Remove the outer VStack and Spacer; let the ZStack(card) be the root view of FeedbackOverlayView"
    - "Once the wrapping VStack is removed, the existing .fixedSize(vertical: true) and TrainerView's ZStack(alignment: .bottom) will naturally pin the card to the bottom and only cover the dock area"
  debug_session: ""

- truth: "Feedback X badge straddles the top edge of the white feedback card (which sits just below the player's hand)"
  status: failed
  reason: "User reported: X badge is centered above the full-screen modal, not straddling the player's last card."
  severity: blocker
  test: 5
  root_cause: "Per UI-SPEC, the badge straddles the top edge of the white feedback card itself (not directly the player card). The badge offset logic in FeedbackOverlayView (.offset(y: -24) inside ZStack(.top)) is correct. The visible bug is a CONSEQUENCE of the full-screen-VStack issue (test 4) — once that's fixed, the card top will sit just below the play area and the badge will appear to straddle the player's last card. Secondary minor issue: 40pt of internal top clearance (Spacer lg + padding md) leaves a 16pt dead-zone gap between badge bottom and the heading."
  artifacts:
    - path: "BJS/Views/Trainer/FeedbackOverlayView.swift"
      issue: "Line 59 — badge.offset(y: -24) is geometrically correct; depends on test 4 fix"
    - path: "BJS/Views/Trainer/FeedbackOverlayView.swift"
      issue: "Lines ~38–45 — Spacer.frame(height: Spacing.lg) + .padding(.top, Spacing.md) yields 40pt clearance, leaving a 16pt dead-zone below the badge"
  missing:
    - "Fix test 4 first; verify the badge visually straddles the white card top edge after that"
    - "Reduce internal top clearance to ~8pt so the heading sits flush below the badge"
  debug_session: ""

- truth: "WHY button (renamed from UNDERSTAND WHY) opens a real explanation of the correct strategic move"
  status: failed
  reason: "User reported: pressing the button does nothing. User direction: rename label to 'WHY' and BUILD a real explanation, not a stub."
  severity: blocker
  test: 6
  root_cause: "The onUnderstandWhy closure passed to FeedbackOverlayView in TrainerView is a hardcoded {} no-op — intentionally stubbed in Plan 03 (UI-07-D7) and never wired. No state, no destination view, no explanation content source."
  artifacts:
    - path: "BJS/Views/Trainer/TrainerView.swift"
      issue: "Line 49 — onUnderstandWhy: { /* no-op placeholder — UI-07-D7 */ } is a literal empty closure"
    - path: "BJS/ViewModels/TrainerViewModel.swift"
      issue: "No explanation/why state property exists"
    - path: "BJS/Views/Trainer/FeedbackOverlayView.swift"
      issue: "Button label currently 'UNDERSTAND WHY' — needs to be renamed to 'WHY'"
  missing:
    - "Rename the button label from 'UNDERSTAND WHY' to 'WHY' in FeedbackOverlayView (and update the FeedbackOverlayTests copy contract that asserts the label)"
    - "Add a sheet/state binding on TrainerView (e.g. @State private var whyContext: WhyContext?) that opens when WHY is tapped"
    - "Build a WhyExplanationView that takes the current decision context (hand total/type, dealer up card, action user chose, correct action, casino rules in play) and renders a short explanation of why the correct move is correct"
    - "Source the explanation content from BJSCore strategy logic — the strategy table already encodes the correct decision per (hand_type, hand_total, dealer_up_card, rules); the explanation needs to verbalize WHY (e.g. 'Hard 16 vs dealer 10: standing loses 75%, hitting busts often but loses less in the long run' or similar). Initial implementation can use template strings keyed off (hand_state, correct_action) without needing per-hand probability calculations."
    - "Wire the closure: onWhy: { whyContext = makeContext(from: feedbackState) }"
    - "Add a test that taps the WHY button and asserts the explanation sheet appears with non-empty content"
  debug_session: ""

- truth: "SessionStartView uses the dark BJS palette and BJS typography"
  status: failed
  reason: "User reported via screenshot: SessionStartView still renders with default light system colors. Code confirms SessionStartView.swift:41,85 uses Color(.systemGroupedBackground) and Color(.secondarySystemBackground)."
  severity: blocker
  test: 7
  root_cause: "Wave 1 reported migration complete but never edited SessionStartView.swift to replace system color references with BJSColors tokens. Static grep verification only checked for deleted symbols, missed surviving Color(.system…) calls."
  artifacts:
    - path: "BJS/Views/Trainer/SessionStartView.swift"
      issue: "Lines 41, 85 use Color(.systemGroupedBackground) and Color(.secondarySystemBackground) instead of BJSColors.surfaceBase / BJSColors.surfaceRaised"
  missing:
    - "Replace Color(.systemGroupedBackground) with BJSColors.surfaceBase"
    - "Replace Color(.secondarySystemBackground) with BJSColors.surfaceRaised"
    - "Apply BJSColors.textPrimary / textSecondary to text"
    - "Apply BJS typography roles in place of default system fonts"
  debug_session: ""

- truth: "SessionSummaryView uses the dark BJS palette and BJS typography"
  status: failed
  reason: "User reported via screenshot: SessionSummaryView still renders with default light system colors. Code confirms SessionSummaryView.swift:74,90 uses Color(.systemGroupedBackground) and Color(.secondarySystemBackground)."
  severity: blocker
  test: 8
  root_cause: "Wave 1 reported migration complete but never edited SessionSummaryView.swift to replace system color references with BJSColors tokens."
  artifacts:
    - path: "BJS/Views/Trainer/SessionSummaryView.swift"
      issue: "Lines 74, 90 use Color(.systemGroupedBackground) and Color(.secondarySystemBackground) instead of BJSColors tokens"
  missing:
    - "Replace system color references with BJSColors tokens"
    - "Apply BJS typography roles to all text"
  debug_session: ""

- truth: "Stats bar, section containers, and Learn/Test toggle use the dark BJS palette"
  status: failed
  reason: "Code inspection confirms StatsBarView.swift, SectionContainerView.swift, and TrainingModeToggle.swift still use Color(.secondarySystemBackground) / Color(.separator) / Color(.systemGray6). TrainingModeToggle has a leftover #warning marking itself as a placeholder."
  severity: major
  test: 11
  root_cause: "Wave 1 token migration was incomplete — these three files were never edited even though the SUMMARY claimed full migration."
  artifacts:
    - path: "BJS/Views/Common/StatsBarView.swift"
      issue: "Lines 16, 19, 37 use Color(.secondarySystemBackground) and Color(.separator)"
    - path: "BJS/Views/Common/SectionContainerView.swift"
      issue: "Line 17 uses Color(.secondarySystemBackground)"
    - path: "BJS/Views/Common/TrainingModeToggle.swift"
      issue: "Lines 15, 28 use Color(.separator) and Color(.systemGray6); has leftover #warning placeholder marker"
  missing:
    - "Replace system colors with BJSColors tokens in all three files"
    - "Remove placeholder #warning from TrainingModeToggle.swift"

- truth: "STAND triggers feedback overlay so user learns whether the decision was correct"
  status: failed
  reason: "User reported: pressing STAND skips the feedback overlay entirely and jumps to the next hand."
  severity: blocker
  test: 12
  root_cause: "TrainerView.handlePhaseChange spawns fire-and-forget Tasks for .playingOut (0.3s sleep → playOutDealer) and .showingResult (1.0s sleep → advanceToNextHand → dealNewHand → feedbackState = nil) with NO cancellation. A stale .showingResult Task from a previous hand can complete its sleep during the current hand's .showingFeedback phase and reset feedbackState, causing the STAND overlay to disappear immediately or never become visible. STAND is more affected than HIT because the STAND path goes through both auto-advance timers (.playingOut → .showingResult), while HIT-no-bust returns directly to .awaitingDecision without any timer."
  artifacts:
    - path: "BJS/Views/Trainer/TrainerView.swift"
      issue: "Lines 186–201 — handlePhaseChange spawns Task { try? await Task.sleep(...); ... } with no cancellation tokens"
    - path: "BJS/Views/Trainer/TrainerView.swift"
      issue: "Line 64 — .onChange(of: viewModel.phase) does not cancel previously-launched Tasks when phase resets to .awaitingDecision or .showingFeedback"
  missing:
    - "Store Task handles as @State private var playingOutTask: Task<Void, Never>? and showingResultTask"
    - "At the top of handlePhaseChange (and on phase reset to .awaitingDecision/.showingFeedback), cancel any pending tasks before launching new ones"
    - "Add a phase-guard inside each Task closure: guard viewModel.phase == .playingOut else { return } before calling playOutDealer() — same for .showingResult"
  debug_session: ""

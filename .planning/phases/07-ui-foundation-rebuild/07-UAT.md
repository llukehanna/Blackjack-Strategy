---
status: complete
phase: 07-ui-foundation-rebuild
source: [07-01-SUMMARY.md, 07-02-SUMMARY.md, 07-03-SUMMARY.md]
started: 2026-04-07T15:55:00Z
updated: 2026-04-07T16:00:00Z
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

### 4. Feedback overlay — bottom-anchored dark card
expected: After making a wrong decision, a feedback card appears anchored to the bottom of the play area, in the dark BJS palette, NOT a full-screen white modal sheet.
result: issue
reported: "Image #8: feedback renders as a full-screen WHITE modal sheet covering most of the trainer area, not a bottom-anchored dark card."
severity: blocker

### 5. Feedback overlay — X badge straddles player's last card
expected: The red X (or green check) badge straddles (overlaps) the bottom edge of the player's last card in the play area, per UI-SPEC.
result: issue
reported: "Image #8: X badge is centered above the white modal sheet — it does not straddle the player's last card; the player's hand isn't even visible behind the modal."
severity: blocker

### 6. UNDERSTAND WHY button
expected: Tapping UNDERSTAND WHY opens an explanation of why the correct strategic move was correct.
result: issue
reported: "User reported: pressing UNDERSTAND WHY does nothing for both Learn and Test modes."
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

- truth: "Dealer and player hands render with visibly different overlap"
  status: failed
  reason: "User reported: dealer and player look like simple side-by-side pairs with similar spacing; differentiation is not visually obvious."
  severity: minor
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Feedback renders as a bottom-anchored dark card in the trainer view"
  status: failed
  reason: "User reported: feedback renders as a full-screen WHITE modal sheet covering the trainer area."
  severity: blocker
  test: 4
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Feedback X badge straddles the player's last card"
  status: failed
  reason: "User reported: X badge is centered above the modal sheet, not straddling the player's last card."
  severity: blocker
  test: 5
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "UNDERSTAND WHY button opens an explanation of the correct move"
  status: failed
  reason: "User reported: pressing UNDERSTAND WHY does nothing for both Learn and Test modes."
  severity: blocker
  test: 6
  root_cause: ""
  artifacts: []
  missing: []
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
  reason: "User reported: pressing STAND skips the feedback overlay entirely and jumps to the next hand. STAND does not trigger the feedback flow."
  severity: blocker
  test: 12
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

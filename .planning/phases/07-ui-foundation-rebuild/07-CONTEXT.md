# Phase 07 — UI Foundation Rebuild

## Goal

Rebuild the visual foundation of the BJS iOS app to professional/shippable quality, using the competitor app **21 Blackjack Strategy Trainer** (Growth Garage LLC) as the visual benchmark. Reference screenshots live in `design-system/reference/` (IMG_7838 through IMG_7849).

This phase is **foundation-only**, not a full UI rebuild. The goal is to lock in a strict design system, swap card rendering to real card art, and rebuild a single screen (TrainerView) to professional standard so it can serve as the visual contract for every other screen later. Stats, settings, onboarding, and session summary are explicitly out of scope.

## Scope (in order)

1. **Audit reference screenshots.** Read all images in `design-system/reference/` and extract actual color values, type treatment, spacing rhythm, card rendering style, and feedback overlay style used by 21 Blackjack Strategy Trainer. Document findings in a short notes file before writing any code.

2. **Rewrite `BJS/Design/` as a strict, minimal design system.** Replace the existing Colors/Typography/Spacing/Elevation/CornerRadius/AnimationTiming files with a single coherent token set modeled on the reference: dark navy background, cream/gold accent, generous spacing scale, max ~10 named color tokens, ~5 type sizes, ~6 spacing values. No view file is allowed to use raw colors, fonts, or magic numbers after this phase — everything composes from tokens.

3. **Add real playing card assets.** Drop a CC0/public-domain SVG playing card deck (Byron Knoll's deck or equivalent) into `BJS/Resources/Cards/` and rebuild `BJS/Views/Trainer/CardView.swift` to render real card art instead of SF Symbols. Include a deliberate card-back design matching the new visual language.

4. **Rebuild TrainerView from scratch** against the new design system and card view. Match the reference quality: one focal point per screen, generous breathing room, large definite action buttons, redesigned feedback overlay as a centered card. Move the stats bar and end-session button out of the play area into the navigation chrome. Do not add new features — same behavior, new presentation.

5. **Verify visually.** Render TrainerView in Xcode Previews in pre-decision, awaiting-decision, and feedback-shown states. Take screenshots and place them next to the reference images for side-by-side comparison.

## Out of Scope

- StatsView, SettingsView, SessionStartView, SessionSummaryView, RuleConfigView, onboarding (rebuilt in a later phase using the same tokens)
- The "Know Why" explanation overlay (separate phase, after foundation lands)
- Hi-Lo counting drill UI
- Any new gameplay features, split implementation, etc.
- Tests beyond verifying the existing test suite still passes

## Done Criteria

- [ ] `BJS/Design/` contains a locked token set, all old design files replaced
- [ ] `BJS/Resources/Cards/` contains the public-domain deck, attribution noted
- [ ] CardView renders real cards in Previews
- [ ] TrainerView rebuilt and visually defensible side-by-side against reference IMG_7838–7849
- [ ] All existing tests still pass (BJSCore and BJSTests)
- [ ] No regressions to TrainerViewModel or any non-UI logic

## Constraints

- iOS 18+, Swift 6.2, SwiftUI, MVVM + `@Observable` (no architecture changes)
- No new third-party dependencies
- Engine layer (BJSCore) is not touched in this phase

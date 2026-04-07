---
phase: 7
slug: ui-foundation-rebuild
status: draft
shadcn_initialized: false
preset: not applicable
created: 2026-04-07
---

# Phase 7 — UI Design Contract

> Visual and interaction contract for the UI Foundation Rebuild. Visual benchmark: 21 Blackjack Strategy Trainer (Growth Garage LLC), reference screenshots `design-system/reference/IMG_7838.PNG`–`IMG_7849.PNG`. This phase is foundation-only — TrainerView is the single screen rebuilt and serves as the visual contract for every other screen later.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (native SwiftUI tokens; no shadcn — iOS app) |
| Preset | not applicable |
| Component library | SwiftUI built-in only — no third-party UI deps |
| Icon library | SF Symbols (system) |
| Font | SF Pro (system) — `.rounded` design for headings/numbers, default for body |

Token files (rewritten in this phase, all under `BJS/Design/`): `BJSColors.swift`, `Typography.swift`, `Spacing.swift`, `CornerRadius.swift`, `Elevation.swift`, `AnimationTiming.swift`. No view file may reference raw colors, fonts, or magic numbers after this phase.

Card art: CC0 deck (Byron Knoll public-domain SVG deck or equivalent) under `BJS/Resources/Cards/`, plus a single matching card-back asset. Attribution recorded in `BJS/Resources/Cards/ATTRIBUTION.md`.

---

## Spacing Scale

Strict 6-value scale (multiples of 4). Every layout in TrainerView composes from these tokens only.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Card-internal pip gaps, icon-to-label inline gap |
| sm | 8pt | Compact stacking (badge to text, paired controls) |
| md | 16pt | Default element spacing, action button internal padding |
| lg | 24pt | Group separation (dealer hand to player hand band), screen horizontal padding |
| xl | 40pt | Major vertical breaks between play-field zones |
| xxl | 64pt | Top-of-screen breathing room above dealer cards |

Exceptions: none. Action button minimum tap target is 56pt height — composed as `md` vertical padding around a 24pt icon+label block, not a new token.

---

## Typography

Five-role scale. SF Pro system font. Numerics use `.monospacedDigit()` so totals/counts don't jitter.

| Role | Size | Weight | Line Height | Notes |
|------|------|--------|-------------|-------|
| caption | 12pt | semibold (600) | 1.2 | Action button labels (`STAND`, `HIT`, `SPLIT`, `DOUBLE`, `SURREN.`), zone labels — uppercase, tracked +1.5 |
| body | 16pt | regular (400) | 1.5 | Feedback overlay body copy (`In this situation HIT isn't the right move...`) |
| title | 20pt | semibold (600) | 1.3 | Feedback overlay heading (`Incorrect!`, `Well played!`), nav-chrome titles |
| heroNumeric | 28pt | bold (700), monospaced digits, rounded | 1.1 | Hand totals shown beneath each hand |
| display | 34pt | bold (700), rounded | 1.1 | Reserved — not used by TrainerView this phase; locked here so later screens (SessionSummary hero stat) inherit the same scale |

Two weights total across the entire system: regular (400) and semibold/bold (600/700 — treated as one "emphasis" weight role, with 700 reserved for numerics only).

---

## Color

Strict 10-token palette. Dark-first (matches reference). Light mode is **out of scope for this phase** — TrainerView is dark-only; tokens are declared as fixed values, not adaptive UIColor providers. (This is a deliberate reversal of phase 02.1 D-04. Recorded in Decisions.)

| Role | Token | Value | Usage |
|------|-------|-------|-------|
| Dominant (60%) | `surfaceBase` | `#0B0B0E` | Full-screen background of TrainerView |
| Dominant elevated | `surfaceRaised` | `#15151A` | Action button fill, nav chrome strip |
| Secondary (30%) | `surfaceOverlay` | `#FFFFFF` | Feedback overlay card fill (only place white appears at scale) |
| Secondary border | `borderSubtle` | `#FFFFFF14` (8% white) | Hairline divider between action buttons, table-edge arc strokes |
| Accent (10%) | `accentGold` | `#E0A436` | **Reserved-for list below** |
| Text primary on dark | `textPrimary` | `#FFFFFF` | Hand totals, all text on `surfaceBase`/`surfaceRaised` |
| Text secondary on dark | `textSecondary` | `#FFFFFF7A` (48% white) | Action button labels, zone labels (`YOU`, `DEALER`), watermark |
| Text on light overlay | `textOnOverlay` | `#0B0B0E` | All text inside the white feedback card |
| Semantic success | `feedbackCorrect` | `#2BB673` | Green check badge on "Well played!" overlay only |
| Semantic destructive | `feedbackIncorrect` | `#E5484D` | Red X badge on "Incorrect!" overlay; destructive confirmations |

**Accent reserved for** (exhaustive list — `accentGold` may not appear anywhere else in TrainerView):
1. Primary CTA fill on the "DEAL" / "GET STARTED"-style button when used as the single dominant action (not used inside TrainerView's play loop — locked here so SessionStartView inherits)
2. Table-edge arc strokes flanking the play field (the two ~1pt hairline ovals at left/right edges, see IMG_7841)
3. Active-tab indicator and brand wordmark in nav chrome (out of scope this phase, declared for forward consistency)

In TrainerView itself this phase, `accentGold` appears **only** as the two table-edge arc strokes. Action buttons are `surfaceRaised` with `textSecondary` labels — never gold. This matches IMG_7841 / IMG_7843 exactly.

---

## Card Rendering Contract

Real CC0 card art replaces the current SF-Symbol-based `CardView`.

| Property | Value |
|----------|-------|
| Asset source | Byron Knoll public-domain SVG deck (or equivalent CC0) under `BJS/Resources/Cards/` |
| Face card aspect | 5:7 (standard poker) |
| Default render width | 88pt (player + dealer cards in TrainerView) |
| Corner radius | `CornerRadius.card = 8pt` |
| Elevation | `Elevation.card` = `shadow(color: #00000066, radius: 12, x: 0, y: 6)` — soft drop shadow lifting cards off `surfaceBase` |
| Card back design | Single dedicated asset: deep red (`#8B1E1E`) field with subtle geometric pattern, white border ring, matching corner radius. Used for dealer hole card (see IMG_7841 — red back beside 8♣). |
| Stacking | Hand cards overlap by 40% horizontally (60% of card width visible per non-top card), matching IMG_7841 dealer hand and IMG_7846 player hand offset |
| Pips/face art | Rendered from SVG at native resolution — no SF Symbols, no emoji |

`CardView` API contract:
- `CardView(card: Card)` → renders face-up using asset `cards/{rank}_of_{suit}`
- `CardView(faceDown: true)` → renders the single back asset
- No size parameter — width is fixed by the parent `HandView`'s layout, never overridden inline

---

## TrainerView Layout Contract

Single focal point per screen. Generous breathing room. Stats and end-session moved out of the play area into nav chrome. Reference: IMG_7841 (awaiting decision), IMG_7843 (feedback shown).

### Vertical zones (top → bottom)

```
┌─────────────────────────────────────┐
│  NAV CHROME (44pt)                  │  ← back chevron (left), help/SOS (right)
│  · back chevron · · · · · · sos     │     surfaceBase, no fill, no divider
├─────────────────────────────────────┤  xxl (64pt) breathing room
│                                     │
│         [DEALER HAND]               │  ← 88pt cards, 40% overlap
│         (no "DEALER" label —        │     centered horizontally
│          context is obvious)        │
│                                     │
│  xl (40pt) gap                      │
│                                     │
│      BLACKJACKTRAININGAPP.COM       │  ← textSecondary at 12% opacity
│      (faint brand watermark,        │     caption size, tracked, uppercase
│       caption size)                 │     replace literal with our brand
│                                     │
│  xl (40pt) gap                      │
│                                     │
│         [PLAYER HAND]               │  ← 88pt cards, 40% overlap
│         (no "YOU" label this phase  │     centered
│          — match IMG_7841)          │
│                                     │
│  flexible spacer (Spacer)           │
│                                     │
│   ╱                              ╲  │  ← table-edge arcs: two ~1pt
│  │                                │ │     accentGold strokes, large
│   ╲                              ╱  │     ovals clipped at screen edges
├─────────────────────────────────────┤
│  ACTION DOCK (surfaceRaised)        │
│  ┌─────────────┬─────────────┐     │
│  │  ✋  STAND  │  +  HIT     │     │  Primary row: 2 buttons, 56pt tall
│  ├─────────────┼─────────────┤     │  hairline borderSubtle dividers
│  │ ↔ SPLIT │ ×2 DBL │ ⚑ SUR │     │  Secondary row: 3 buttons, 56pt tall
│  └─────────┴────────┴────────┘     │  rendered ONLY when legal — when no
└─────────────────────────────────────┘  secondary actions, row is omitted
```

### Action button contract

| Property | Value |
|----------|-------|
| Container | `surfaceRaised` fill, no corner radius (full-bleed dock), 1pt `borderSubtle` between cells |
| Layout | VStack(spacing: xs) — icon (24pt SF Symbol) above label |
| Icon | SF Symbol, `textSecondary`, 24pt, weight `.regular` — `hand.raised` (STAND), `plus` (HIT), `arrow.left.and.right` (SPLIT), `multiply` boxed (DOUBLE → use `xmark.square`-style or custom "×2"), `flag` (SURRENDER) |
| Label | `caption` typography, `textSecondary`, uppercase, tracked |
| Tap target | 56pt minimum height, full cell width |
| States | Disabled action: 32% opacity entire cell, no fill change |
| Press feedback | 0.96 scale, `AnimationTiming.tap` (120ms easeOut), no color change |

### Stats / end-session relocation

- Per phase scope, the existing `StatsBarView` content (running session accuracy, decision count, streak) and the "End Session" affordance are **removed from the play area entirely** and moved into the nav chrome strip.
- Top-left: back chevron (`chevron.left` in a 32pt subtle circular hit-target) → ends the session with confirmation.
- Top-right: help/strategy-table icon (`book` SF Symbol, `textSecondary`) — wired in this phase as a placeholder no-op (matches IMG_7841 SOS button position; "Know Why" overlay is a later phase).
- Inline session stats are **not displayed** during play in this phase. They surface in SessionSummaryView (out of scope) and are accessible by ending the session.

### TrainerView states the contract must cover

1. **Pre-decision (dealer hole card hidden):** Dealer = 1 face-up + 1 face-down (red back). Player = 2 face-up. All legal action buttons enabled. No overlay.
2. **Awaiting decision after hit:** Player has ≥3 cards. Hole card still hidden. Hand totals visible below each hand in `heroNumeric`. SPLIT/DOUBLE/SURRENDER cells omitted if no longer legal.
3. **Feedback shown:** White feedback overlay card slides in from the bottom over the action dock — NOT a top banner. Contract below.

---

## Feedback Overlay Contract

Visual reference: IMG_7843 (incorrect) and IMG_7847 (correct).

| Property | Value |
|----------|-------|
| Surface | `surfaceOverlay` (white) card, corner radius `CornerRadius.overlay = 24pt` on top corners only, full-bleed bottom |
| Position | Bottom-anchored, covers the action dock entirely. Does NOT cover the hands. |
| Status badge | 48pt circle, centered horizontally, **half-overlapping the top edge** of the white card (24pt above, 24pt inside). Green `feedbackCorrect` with `checkmark` glyph for correct, red `feedbackIncorrect` with `xmark` glyph for incorrect. White glyph, semibold. |
| Heading | `title` typography, `textOnOverlay`, centered, copy from copywriting contract. `lg` (24pt) top padding inside the card (below the badge). |
| Body | `body` typography, `textOnOverlay` at 70% opacity, centered, max 2 lines, `md` horizontal padding, `sm` top gap below heading |
| Primary action | Single full-width "DEAL" button, `surfaceRaised` fill, `textPrimary` label, `caption` uppercase, 56pt tall, `lg` margin from body, `lg` bottom padding. Icon: `square.on.square` (matches IMG_7843 deal-pile glyph). |
| Secondary action | None this phase. ("Understand Why" from IMG_7843 is deferred to the Know-Why phase — explicit per phase scope.) |
| Entry animation | Slide up from bottom + fade, `AnimationTiming.overlayIn` = 280ms `easeOut` |
| Dismiss | Tapping DEAL dismisses overlay and advances to the next hand |
| Background dim | None — overlay sits over action dock only; play field above remains fully visible |

---

## Copywriting Contract

All copy locked here. Executor uses these strings verbatim — no synonyms.

| Element | Copy |
|---------|------|
| Primary CTA (feedback overlay, both states) | `DEAL` |
| Feedback heading — correct | `Well played!` |
| Feedback heading — incorrect | `Incorrect!` |
| Feedback body — correct | `{ACTION} was the right move.` (e.g. `STAND was the right move.`) |
| Feedback body — incorrect | `In this situation {USER_ACTION} isn't the right move. You should have {CORRECT_ACTION}.` (uppercase action verbs, bolded via attributed string in body weight) |
| Action button labels | `STAND`, `HIT`, `SPLIT`, `DOUBLE`, `SURREN.` (uppercase, tracked, exactly these strings — `SURREN.` truncation matches IMG_7841) |
| Brand watermark | `BLACKJACKTRAINING.APP` (replace competitor wordmark; uppercase, tracked, 12% opacity) |
| Empty state heading | Not applicable — TrainerView always has hands during play |
| Empty state body | Not applicable |
| Error state | If hand cannot be dealt: heading `Something went wrong`, body `Tap DEAL to try again.` |
| Destructive confirmation — end session via back chevron | Title `End this session?` · Body `Your session results so far will be saved.` · Confirm `End Session` (red, `feedbackIncorrect` text on `surfaceRaised`) · Cancel `Keep Playing` (textPrimary on surfaceRaised) |

---

## Token Files — Required Symbols

Executor must produce these exact token symbols. Plan tasks reference them by name.

```
BJSColors.surfaceBase
BJSColors.surfaceRaised
BJSColors.surfaceOverlay
BJSColors.borderSubtle
BJSColors.accentGold
BJSColors.textPrimary
BJSColors.textSecondary
BJSColors.textOnOverlay
BJSColors.feedbackCorrect
BJSColors.feedbackIncorrect

Typography.caption
Typography.body
Typography.title
Typography.heroNumeric
Typography.display

Spacing.xs   // 4
Spacing.sm   // 8
Spacing.md   // 16
Spacing.lg   // 24
Spacing.xl   // 40
Spacing.xxl  // 64

CornerRadius.card     // 8
CornerRadius.button   // 0  (full-bleed action dock cells)
CornerRadius.overlay  // 24 (top corners only)

Elevation.card        // shadow tuple: color #00000066, radius 12, x 0, y 6
Elevation.overlay     // shadow tuple: color #00000099, radius 24, x 0, y -8

AnimationTiming.tap         // 120ms easeOut
AnimationTiming.overlayIn   // 280ms easeOut
AnimationTiming.overlayOut  // 200ms easeIn
AnimationTiming.cardDeal    // 320ms easeOut (per-card stagger 60ms)
```

All previous tokens not listed above are deleted in this phase. No backwards compatibility shims.

---

## Decisions Locked in This Spec

| ID | Decision | Reason |
|----|----------|--------|
| UI-07-D1 | TrainerView is dark-mode-only; tokens are fixed hex values, not adaptive | Reference is dark-only and the visual contract depends on the specific near-black background. Light mode reintroduced in a later phase. |
| UI-07-D2 | StatsBar removed from play area — no inline session stats during play | Reference shows zero competing chrome in the play field; one focal point per screen. |
| UI-07-D3 | Feedback is a bottom centered card, not a top banner | Matches reference IMG_7843/IMG_7847 exactly; reverses prior 02.2 banner decision. |
| UI-07-D4 | Two-row action grid with full-bleed cells and hairline borders, no rounded buttons | Matches IMG_7841 action dock; reduces visual noise vs prior pill-button approach. |
| UI-07-D5 | accentGold appears only as table-edge arcs in TrainerView this phase | Preserves the "10% accent" rule strictly; matches reference (no gold buttons in play view). |
| UI-07-D6 | Real CC0 SVG card deck replaces SF Symbol cards | Reference uses real card art; SF Symbols cannot reach reference quality. |
| UI-07-D7 | "Understand Why" action omitted from feedback overlay this phase | Explicit phase scope — Know Why is a later phase. |
| UI-07-D8 | Destructive end-session confirmation lives on the nav chrome back chevron | Removes End Session button from play area without losing the affordance. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| n/a — native iOS | none | not applicable (no shadcn / no third-party UI registries; iOS SwiftUI project) |

Asset provenance: Byron Knoll public-domain playing card SVG deck (or equivalent CC0). Provenance and license URL recorded in `BJS/Resources/Cards/ATTRIBUTION.md` during execution. No code dependencies added.

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending

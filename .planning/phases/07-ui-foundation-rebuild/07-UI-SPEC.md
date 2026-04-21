---
phase: 7
slug: ui-foundation-rebuild
status: draft
shadcn_initialized: false
preset: not applicable
created: 2026-04-07
revised: 2026-04-07
---

# Phase 7 — UI Design Contract

> Visual and interaction contract for the UI Foundation Rebuild. Visual benchmark: 21 Blackjack Strategy Trainer (Growth Garage LLC), reference screenshots `design-system/reference/IMG_7838.PNG`–`IMG_7849.PNG`. **Every value in this spec is grounded in a specific reference image.** Where a value is inferred rather than directly observed, it is explicitly tagged `observed: false — inferred because {reason}`. Color hex values are visually sampled by eye from the PNGs and should be treated as ±5 per channel until executor confirms with a digital sampler.

This phase is foundation-only — TrainerView is the single screen rebuilt and serves as the visual contract for every other screen later.

---

## Visual Evidence

Per-image catalog of what each reference contributes to the contract.

### IMG_7838.PNG — Strategy home (training mode picker)
- Background sampled: `#0A0A0E` (true near-black, very slight cool cast)
- Gold accent sampled: `#E0A436` — used in wordmark "Strategy", "PRO" pill, and "GET STARTED" outlined button border + label
- "PRO" pill: gold gradient fill, white crown icon, white "PRO" caption, fully rounded
- "GET STARTED" button: **transparent fill**, ~1pt gold stroke, gold caption label, gold crown icon trailing — corner radius ~12pt
- Training mode card "Pairs": warm orange gradient (`#E89A3C` → `#D17A1F` top-to-bottom), white text, lock icons in pill at top-left, info `i` glyph top-right, generous internal padding (~20pt)
- Bottom tab bar: cream/off-white pill (`#EFE8DC`-ish), rounded top corners ~28pt, three tabs Strategy/Counting/Stats — active tab "Strategy" in gold, inactive in muted brown-grey
- **Drives decision:** establishes `accentGold = #E0A436` exactly; establishes that primary CTAs in non-play screens use **outlined gold** style, not filled gold; establishes tab bar is light cream not dark; out of scope for TrainerView this phase but locks the token for later screens.

### IMG_7839.PNG — Counting module (level path)
- Background: same near-black `#0A0A0E`
- Module 1 header card: dark surface with **gold ~1pt border**, rounded ~16pt, "Module 1" caption in muted grey, "Card Counting 101" title in white, book glyph in gold circle on right
- Level chip (active "START"): orange/gold gradient pill with white "START" caption, "Hi-Lo" label below in white, three empty stars below in muted grey
- Locked level chips: grey gradient pill (`#5A5A60`-ish) with white padlock glyph, label below in muted grey, dashed orange `#D17A1F` path connecting chips
- Bottom tab bar: same cream pill, "Counting" tab active in dark with `±` glyph
- **Drives decision:** confirms locked-state treatment (grey + padlock); confirms dashed-path navigation pattern (out of scope this phase but recorded). Background hex confirmed across screens.

### IMG_7840.PNG — Stats list
- Background: `#0A0A0E`
- Stat row cards: rounded ~12pt, fill `#16161B` (slightly lifted from base), three column layout, white numerics, muted-grey caption labels below
- Section headers ("Hard hands", "Pairs", "Level 2 hands"): white, semibold, ~17pt, left-aligned
- "RESET STATS" button at bottom: **transparent fill, gold border ~1pt, gold uppercase label, rounded ~14pt** — same outlined-gold pattern as IMG_7838 GET STARTED
- **Drives decision:** confirms `surfaceRaised = #16161B` (sampled from these stat cards — not the previously-guessed `#15151A`, very close but visibly correct); confirms outlined-gold is the canonical primary CTA shape across the app.

### IMG_7841.PNG — TrainerView pre-decision (THE primary reference for this phase)
- Background: `#0A0A0E` confirmed
- Top nav: back chevron in `#1A1A20` subtle circle (~32pt) top-left; **"SOS" text label** top-right in muted blue-grey `#7A8A9E` — **not a book icon** as previously specified
- Dealer hand: 8♣ face-up + red card back, overlapping by ~30% (back covers ~30% of the 8♣)
- Card back: vibrant red `#B82828` field with thin white inner border, subtle pattern (not solid)
- Watermark "BJS" (placeholder — final brand wordmark TBD; do NOT use any competitor domain string): **distinct cool teal-blue-grey** `#3A5868` at very low opacity (~25%), uppercase, tracked, caption-size, centered between hands
- Player hand: 5♥ + 5♣, overlapping by ~45% (visibly more overlap than dealer pair)
- **No hand-total numerics anywhere** — reference shows zero numeric totals beneath hands
- **No "DEALER" / "YOU" labels** — confirmed
- Table-edge arcs: two large amber `#E0A436` ovals clipped at left/right screen edges, ~1pt stroke, positioned at the player-hand vertical band
- Action dock: lives in the bottom third over a subtle elliptical "table-edge" silhouette (a slightly raised dark band with a soft top highlight) — fill effectively `#0A0A0E` matching base, separated from the play field only by the curved highlight
- Action button row 1 (STAND, HIT): each cell has the SF Symbol icon in **muted blue** `#6B8499` (same cool-blue lane as IMG_7841, intentionally differentiated from competitor's exact value) above an uppercase caption label in the same blue, label tracked +1.5
- Action button row 2 (SPLIT, DOUBLE, SURREN.): same treatment — DOUBLE icon is a "×2" boxed glyph (square outline with "×2" inside), SURREN. uses the flag glyph
- Hairline dividers between cells: very faint `#FFFFFF14`
- Cell tap target: roughly 88pt tall (icon ~24pt + caption + generous vertical padding) — taller than initially specified 56pt
- **Drives decision:** establishes the entire TrainerView contract. Triggers corrections to: action button label color (blue not white-grey), top-right nav (SOS not book), hand totals (omit entirely, not heroNumeric), action cell height (88pt not 56pt), card back red value, watermark color (cool teal not white), surfaceRaised value, dealer/player overlap percentages.

### IMG_7842.PNG — Strategy table modal (out of scope this phase)
- Color-coded grid: H = green `#3FB46B`, ST = orange `#E89A3C`, D = yellow `#E5C84A`, SP = purple `#A057C9`, all with white uppercase labels
- Dealer card icon header strip on dark, X close button top-right in subtle circle
- **Drives decision:** locks the **semantic strategy palette** (`H/ST/D/SP`) for the future Strategy Table view — recorded here so SessionSummary and KnowWhy phases inherit. Not used by TrainerView this phase.

### IMG_7843.PNG — TrainerView feedback overlay (incorrect)
- Play field above unchanged from IMG_7841 (same cards, same watermark, same arcs visible at top edges)
- Feedback card: **white** `#FFFFFF` fill, top corner radius ~24pt, full-bleed bottom, covers the action dock entirely but **not** the play field
- Status badge: red circle `#E5484D` ~48pt, white X glyph (`xmark` semibold), positioned **half above / half inside** the top edge of the white card, centered horizontally
- Heading "Incorrect!": `#0A0A0E`, ~22pt bold, centered, ~24pt below the badge midpoint
- Body: `#0A0A0E` at ~65% opacity, ~16pt regular, centered, "In this situation **HIT** isn't the right move. You should have **DOUBLE**." with the action verbs bolded inline
- **Two stacked buttons** (BOTH visible in the reference):
  1. "UNDERSTAND WHY" — white fill, ~1pt grey `#D8D8DC` border, `#0A0A0E` uppercase caption, question-mark-circle icon, ~56pt tall, rounded ~12pt
  2. "DEAL" — dark fill `#1F1F25`, white uppercase caption, `square.on.square` deal-pile icon, ~56pt tall, rounded ~12pt
- Spacing: card horizontal padding ~20pt, button-to-button gap ~12pt, bottom safe-area padding generous
- **Drives decision:** **REVERSES the previous "Understand Why omitted" decision (D7).** The reference clearly shows both buttons. Honoring the reference: this phase implements both, with UNDERSTAND WHY wired as a placeholder no-op (not a deferral of the button itself). Also locks button corner radius to ~12pt (rounded), not zero.

### IMG_7844.PNG — PRO paywall (out of scope this phase)
- Photographic hero (dealer with cards), gradient overlay to dark at bottom
- White headline "Win more hands with PRO" ~28pt bold
- Gold checklist icons (`graduationcap`, `person.fill`, `checkmark.square.fill`, `info.circle`, `infinity`) — `#E0A436`
- Plan cards: white fill, rounded ~16pt, plan name in dark grey, price bold black, "/mo" muted; **Annual** card has gold border ~2pt and gold "Popular" tag straddling top edge (same badge pattern as feedback overlay)
- "CONTINUE" button: **gold gradient fill** `#E8B850` → `#C99020`, dark uppercase label, rounded ~14pt — **the only filled-gold button in the entire reference set**
- **Drives decision:** confirms the "filled gold" treatment is reserved for a single-purpose paywall CTA only; locks the badge-straddles-edge pattern as a global motif (used for both feedback badges and "Popular" plan tag).

### IMG_7845.PNG — Hi-Lo info modal (out of scope this phase)
- White card overlay, blue book-icon badge straddling top edge (same badge pattern, blue `#3A8AC9` instead of red/green)
- Body copy: dark grey, with bolded inline emphasis on key phrases
- Single dark "UNDERSTOOD" button at bottom — same dark fill `#1F1F25` as DEAL button
- **Drives decision:** confirms badge-straddle pattern works in three colors (red/green/blue); confirms single-button modal layout for info; reinforces the dark `#1F1F25` button as the canonical "primary action on white surface" treatment.

### IMG_7846.PNG — Counting trainer (single card)
- Same dark background, same watermark, same gold arcs
- Single card centered (7♦)
- Action dock: three cells "−1 / 0 / +1" with **white** numerals (large, ~28pt rounded bold) above muted blue captions "SUBSTRACT 1 / DO NOTHING / ADD 1"
- **Drives decision:** confirms the action dock pattern generalizes; confirms numerals use white when they ARE the primary affordance (vs. blue captions which are secondary labels). Out of scope for strategy TrainerView this phase but locks the pattern for the counting phase.

### IMG_7847.PNG — Counting trainer feedback (correct)
- Green badge `#2BB673` with white check, half-straddling top of white card
- Heading "Well played!" black, centered
- Body "High cards (10, J, Q, K, A) have a **VALUE OF -1**" — bold inline
- **Single DEAL button only** — no "UNDERSTAND WHY" in counting flow
- **Drives decision:** locks `feedbackCorrect = #2BB673`; confirms counting flow has 1 button while strategy flow has 2; locks heading copy "Well played!".

### IMG_7848.PNG — Streak milestone overlay
- Gold star badge `#E0A436` (same badge pattern), star glyph white
- Heading "Nice streak!" black, centered, body explains the milestone with bold inline emphasis
- Two stacked buttons: outlined "GO TO NEXT LEVEL" (white fill, grey border, dark label, link/chain icon) + dark "KEEP PRACTICING" (dark fill, white label)
- **Drives decision:** confirms the two-button stacked layout is the canonical multi-action overlay shape (matching IMG_7843); locks gold as a third badge color in addition to red/green; star glyph is the milestone semantic.

### IMG_7849.PNG — Counting trainer feedback (incorrect)
- Same red X badge as IMG_7843
- Heading "Incorrect!" black, centered
- Body "High cards (10, J, Q, K, A) have a **VALUE OF -1**" — bold inline (note: this is the same explanatory body as IMG_7847, just shown after a wrong answer)
- **Single DEAL button only**
- **Drives decision:** redundant with IMG_7847 for color/badge tokens; confirms counting flow always uses single button regardless of correct/incorrect.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (native SwiftUI tokens; no shadcn — iOS app) |
| Preset | not applicable |
| Component library | SwiftUI built-in only — no third-party UI deps |
| Icon library | SF Symbols (system) |
| Font | SF Pro (system) — `.rounded` design for headings/numerics, default for body |

Token files (rewritten in this phase, all under `BJS/Design/`): `BJSColors.swift`, `Typography.swift`, `Spacing.swift`, `CornerRadius.swift`, `Elevation.swift`, `AnimationTiming.swift`. No view file may reference raw colors, fonts, or magic numbers after this phase.

Card art: CC0/public-domain deck (Byron Knoll public-domain SVG deck or equivalent) under `BJS/Resources/Cards/`, plus a single matching card-back asset. **License verification is MANDATORY before commit:** executor must read the source's actual license page/file, confirm it is public domain or CC0, record the verified source URL + license URL in `BJS/Resources/Cards/ATTRIBUTION.md`, and **abort the task** if the license cannot be positively confirmed (no "probably CC0" — only verified).

---

## Spacing Scale

Strict 6-value scale (multiples of 4). Every layout in TrainerView composes from these tokens only.

| Token | Value | Usage | Evidence |
|-------|-------|-------|----------|
| xs | 4pt | Card-internal pip gaps, icon-to-label inline gap | `observed: false — inferred because reference does not expose pixel-level grid; standard 4pt scale assumed` |
| sm | 8pt | Compact stacking (badge to text, paired controls) | `observed: false — inferred` |
| md | 16pt | Default element spacing, action button internal padding | IMG_7841 action-cell internal padding visually ~16pt |
| lg | 24pt | Group separation, screen horizontal padding, feedback-card horizontal padding | IMG_7843 feedback-card horizontal inset visually ~20–24pt |
| xl | 48pt | Major vertical breaks between play-field zones (dealer→watermark→player) | IMG_7841 vertical rhythm between dealer hand, watermark, player hand eye-sampled ~40pt; rounded UP to standard-set value 48pt — 8pt within tolerance of an eye-sample, and adopting the standard 4/8/16/24/32/48/64 grid protects downstream screens |
| xxl | 64pt | Top-of-screen breathing room above dealer cards | IMG_7841 top-of-screen-to-dealer-hand visually ~64pt below status bar |

Action button cell minimum tap target is **88pt tall** (corrected from previous 56pt — IMG_7841 cells are visibly taller than typical 56pt; composed as `lg` vertical padding around a 24pt icon + `xs` gap + caption label).

---

## Typography

Three-role scale. SF Pro system font. Numerics use `.monospacedDigit()` where they appear so any future digit rendering doesn't jitter.

| Role | Size | Weight | Line Height | Notes | Evidence |
|------|------|--------|-------------|-------|----------|
| caption | 12pt | bold (700) | 1.2 | Action button labels, zone labels — uppercase, tracked +1.5 | IMG_7841 action labels visibly small caps ~12pt |
| body | 16pt | regular (400) | 1.5 | Feedback overlay body copy | IMG_7843 body text size visually ~16pt |
| title | 22pt | bold (700) | 1.25 | Feedback overlay heading (`Incorrect!`, `Well played!`) | IMG_7843 / IMG_7847 heading visually ~22pt bold (corrected from 20pt semibold) |

**Three sizes, two weights total:** regular (400) and bold (700). Caption and title both use bold (700) — semibold (600) is not used as a token in this phase.

**Why no `heroNumeric` or `display` token this phase:** TrainerView this phase renders **zero hand-total numerics** (per UI-07-D10 — IMG_7841 shows none). The counting trainer (which would need `heroNumeric` for the −1/0/+1 numerals per IMG_7846) and SessionSummary (which would need a hero stat) are explicitly **out of scope** per `07-CONTEXT.md`. Card rank/pip rendering is drawn from **SVG card art assets** (Byron Knoll CC0 deck) — no text token required. Any future screen needing larger numerics adds the token in its own phase, justified against its own reference.

---

## Color

Strict 11-token palette. Dark-first (matches reference). Light mode is **out of scope for this phase**.

All hex values are visually sampled by eye from the reference PNGs. Executor must confirm with a digital color sampler during implementation; values may shift ±5 per channel.

| Role | Token | Value | Usage | Evidence |
|------|-------|-------|-------|----------|
| Dominant (60%) | `surfaceBase` | `#0A0A0E` | Full-screen background of TrainerView | IMG_7838/7841/7846 sampled — all share the same near-black with very faint cool cast |
| Dominant elevated | `surfaceRaised` | `#16161B` | Stat-row card fill (IMG_7840), top-nav circle hit target (IMG_7841) | IMG_7840 stat card sampled |
| Action-on-overlay | `actionDark` | `#1F1F25` | Dark "DEAL" / "UNDERSTOOD" / "KEEP PRACTICING" buttons inside white feedback cards | IMG_7843/7845/7847/7848 dark button fill sampled |
| Secondary (30%) | `surfaceOverlay` | `#FFFFFF` | Feedback overlay card fill, info modal card fill | IMG_7843/7845/7847/7848/7849 — all overlays |
| Secondary border | `borderSubtle` | `#FFFFFF14` (8% white) | Hairline dividers between action cells | IMG_7841 cell dividers visually ~hairline at very low opacity; `observed: false — opacity inferred` |
| Overlay border | `borderOnOverlay` | `#D8D8DC` | UNDERSTAND WHY button stroke; outlined buttons on white cards | IMG_7843 button border sampled |
| Accent (10%) | `accentGold` | `#E0A436` | **Reserved-for list below** | IMG_7838 wordmark, IMG_7841 table arcs, IMG_7848 star badge — all share same warm gold |
| Action label | `actionLabel` | `#6B8499` | TrainerView action button icons + captions (STAND/HIT/SPLIT/DOUBLE/SURREN.) | Inspired by IMG_7841 action icons + captions (same cool muted blue lane), intentionally differentiated — warmer/lighter than competitor's exact value to avoid palette collision |
| Watermark | `watermarkInk` | `#3A5868` at 25% opacity | "BJS" placeholder wordmark between hands (final brand TBD) | IMG_7841/7846 watermark sampled — distinct cool teal cast, not white-on-low-opacity |
| Text primary on dark | `textPrimary` | `#FFFFFF` | All text on `surfaceBase`/`surfaceRaised` (when not action-label) | IMG_7840 stat numerics, IMG_7841 nav SOS would fall here |
| Text secondary on dark | `textSecondary` | `#FFFFFF99` (60% white) | Stat row caption labels, "Module 1" eyebrow text | IMG_7840 / IMG_7839 caption text |
| Text on light overlay | `textOnOverlay` | `#0A0A0E` | All headings inside white overlay cards | IMG_7843/7845/7847 |
| Body on light overlay | `textOnOverlayMuted` | `#0A0A0E` at 65% opacity | Body copy inside white overlay cards | IMG_7843 body text visibly muted vs heading |
| Semantic success | `feedbackCorrect` | `#2BB673` | Green check badge — IMG_7847 only | IMG_7847 sampled |
| Semantic destructive | `feedbackIncorrect` | `#E5484D` | Red X badge — IMG_7843, IMG_7849 | IMG_7843 sampled |
| Card back red | `cardBackRed` | `#B82828` | Dealer hole card back field | IMG_7841 sampled — clearly more vivid than the previously-guessed `#8B1E1E` |

**Accent reserved for** (exhaustive list — `accentGold` may not appear anywhere else in TrainerView):
1. Table-edge arc strokes flanking the play field — IMG_7841
2. Outlined-gold CTAs on non-play screens (GET STARTED IMG_7838, RESET STATS IMG_7840) — out of scope this phase, locked for forward consistency
3. Brand wordmark and "PRO" pill — IMG_7838 (out of scope this phase)
4. Streak/milestone badges — IMG_7848 (out of scope this phase)

In TrainerView this phase, `accentGold` appears **only** as the two table-edge arcs. Action buttons are NEVER gold; they use `actionLabel` blue per IMG_7841.

---

## Card Rendering Contract

Real CC0 card art replaces SF-Symbol-based `CardView`.

| Property | Value | Evidence |
|----------|-------|----------|
| Asset source | Byron Knoll public-domain SVG deck (or equivalent CC0) under `BJS/Resources/Cards/` | n/a |
| Face card aspect | 5:7 (standard poker) | IMG_7841 visible card aspect matches standard |
| Default render width | 88pt | `observed: false — inferred from visual proportion in IMG_7841 (cards occupy ~25% of screen width on a 393pt iPhone)` |
| Corner radius | `CornerRadius.card = 8pt` | IMG_7841 card corners visually ~8pt |
| Elevation | `Elevation.card` = `shadow(color: #00000066, radius: 12, x: 0, y: 6)` | IMG_7841 cards have a soft drop shadow lifting them off background; opacity/radius `observed: false — inferred values` |
| Card back design | `cardBackRed = #B82828` field, thin white inner border ring, subtle pattern, matching corner radius | IMG_7841 sampled |
| Stacking — dealer hand | Cards overlap by **30%** (back covers ~30% of face-up card width) | IMG_7841 dealer pair measured visually |
| Stacking — player hand | Cards overlap by **45%** | IMG_7841 player pair measured visually — visibly tighter than dealer |
| Pips/face art | Rendered from SVG at native resolution — no SF Symbols, no emoji | IMG_7841 shows real card art |

`CardView` API contract:
- `CardView(card: Card)` → renders face-up using asset `cards/{rank}_of_{suit}`
- `CardView(faceDown: true)` → renders the single back asset
- No size parameter — width is fixed by parent `HandView` layout
- `HandView` accepts an `overlap: HandOverlap` enum with cases `.dealer` (0.30) and `.player` (0.45)

---

## TrainerView Layout Contract

Single focal point per screen. Generous breathing room. Stats and end-session moved out of the play area into nav chrome. Reference: IMG_7841 (awaiting decision), IMG_7843 (feedback shown).

### Vertical zones (top → bottom)

```
┌─────────────────────────────────────┐
│  NAV CHROME (44pt)                  │  ← back chevron in 32pt surfaceRaised circle (left)
│  ◀ · · · · · · · · · · · · · SOS    │     "SOS" text label in actionLabel blue (right)
├─────────────────────────────────────┤  xxl (64pt) breathing room
│                                     │
│         [DEALER HAND]               │  ← 88pt cards, 30% overlap, centered
│         (no label)                  │
│                                     │
│  xl (48pt) gap                      │
│                                     │
│             BJS                     │  ← watermarkInk (#3A5868 @ 25%)
│      (faint cool watermark,         │     caption size, tracked, uppercase
│       caption size)                 │
│                                     │
│  xl (48pt) gap                      │
│                                     │
│         [PLAYER HAND]               │  ← 88pt cards, 45% overlap, centered
│         (no label, no totals)       │
│                                     │
│  flexible Spacer                    │
│                                     │
│   ╱                              ╲  │  ← table-edge arcs: two ~1pt
│  │                                │ │     accentGold strokes, large ovals
│   ╲                              ╱  │     clipped at left/right screen edges
├─────────────────────────────────────┤
│  ACTION DOCK (surfaceBase)          │
│  ┌─────────────┬─────────────┐     │
│  │  ✋ STAND   │  + HIT      │     │  Row 1: 2 cells, 88pt tall each
│  ├──────┬──────┴──┬──────────┤     │  hairline borderSubtle dividers
│  │ ↔ SP │ ×2 DBL │ ⚑ SUR    │     │  Row 2: 3 cells, 88pt tall each
│  └──────┴────────┴───────────┘     │  rendered ONLY when legal
└─────────────────────────────────────┘
```

### Action button contract

| Property | Value | Evidence |
|----------|-------|----------|
| Container | `surfaceBase` fill (matches background — dock distinguished by content, not fill), no per-cell corner radius (full-bleed dock), 1pt `borderSubtle` between cells | IMG_7841 |
| Layout | VStack(spacing: xs) — icon (24pt SF Symbol) above caption label | IMG_7841 |
| Icon | SF Symbol, `actionLabel` blue, 24pt, weight `.regular` — `hand.raised` (STAND), `plus` (HIT), `arrow.left.and.right` (SPLIT), custom "×2" boxed glyph (DOUBLE), `flag` (SURRENDER) | IMG_7841 |
| Label | `caption` typography, `actionLabel` blue, uppercase, tracked +1.5 | IMG_7841 |
| Tap target | **88pt tall** (corrected from 56pt), full cell width | IMG_7841 visual measure |
| States | Disabled action: 32% opacity entire cell, no fill change | `observed: false — inferred (no disabled state visible in references)` |
| Press feedback | 0.96 scale, `AnimationTiming.tap` (120ms easeOut), no color change | `observed: false — inferred standard iOS press feedback` |

### Stats / end-session relocation

- Existing `StatsBarView` content (running session accuracy, decision count, streak) and "End Session" affordance are **removed from the play area entirely**.
- Top-left: back chevron (`chevron.left` SF Symbol in a 32pt `surfaceRaised` circular hit-target, glyph in `textPrimary`) → ends the session with confirmation.
- Top-right: **"SOS" text button** in `actionLabel` blue — `caption` typography (12pt bold, tracked +1.5), uppercase — wired in this phase as a placeholder no-op (corrected from previous "book icon" — IMG_7841 clearly shows the text "SOS").
- Inline session stats are **not displayed** during play. They surface in SessionSummaryView (out of scope).

### TrainerView states the contract must cover

1. **Pre-decision (dealer hole card hidden):** Dealer = 1 face-up + 1 face-down (`cardBackRed` back). Player = 2 face-up. All legal action buttons enabled. No overlay. **No hand-total numerics rendered** (corrected — IMG_7841 shows none).
2. **Awaiting decision after hit:** Player has ≥3 cards. Hole card still hidden. SPLIT/DOUBLE/SURRENDER cells omitted if no longer legal. Still no numeric totals.
3. **Feedback shown:** White feedback overlay slides in from bottom over the action dock — NOT a top banner. Hands above remain fully visible. Contract below.

---

## Feedback Overlay Contract

Visual reference: IMG_7843 (incorrect, strategy), IMG_7847 (correct, counting), IMG_7849 (incorrect, counting), IMG_7848 (streak milestone).

| Property | Value | Evidence |
|----------|-------|----------|
| Surface | `surfaceOverlay` (white) card, top corners radius `CornerRadius.overlay = 24pt`, full-bleed bottom | IMG_7843 |
| Position | Bottom-anchored, covers the action dock entirely. Does NOT cover the hands. | IMG_7843 |
| Status badge | 48pt circle, centered horizontally, **half-overlapping the top edge** of the white card. Green `feedbackCorrect` + white `checkmark` for correct; red `feedbackIncorrect` + white `xmark` for incorrect. Glyph is white, semibold. | IMG_7843, IMG_7847 |
| Heading | `title` typography (22pt bold), `textOnOverlay`, centered, `lg` (24pt) top padding inside the card (below the badge) | IMG_7843 |
| Body | `body` typography, `textOnOverlayMuted` (`#0A0A0E` @ 65%), centered, max 2 lines, `lg` horizontal padding, `sm` top gap below heading. Inline action verbs bolded via attributed string. | IMG_7843 |
| Buttons (strategy TrainerView — 2 buttons) | Stacked vertically with `sm` (8pt) gap between: (1) **UNDERSTAND WHY** — `surfaceOverlay` fill, 1pt `borderOnOverlay` stroke, `textOnOverlay` uppercase caption, `questionmark.circle` icon, 56pt tall, `CornerRadius.overlayButton = 12pt`; (2) **DEAL** — `actionDark` fill, white uppercase caption, `square.on.square` icon, 56pt tall, 12pt corner radius. | IMG_7843 |
| Padding | Card horizontal padding `lg` (24pt), top-to-heading `lg` below badge midpoint, button block bottom padding generous (`xl` 48pt incl. safe area) | IMG_7843 |
| Entry animation | Slide up from bottom + fade, `AnimationTiming.overlayIn` = 280ms `easeOut` | `observed: false — inferred motion timing` |
| Dismiss | Tapping DEAL dismisses overlay and advances to next hand. Tapping UNDERSTAND WHY is a no-op placeholder this phase (button rendered for visual fidelity to reference; Know-Why functionality lands in a later phase). | reference shows the button; behavior decision below |
| Background dim | None — overlay sits over action dock only; play field above remains fully visible | IMG_7843 |

---

## Copywriting Contract

All copy locked here. Executor uses these strings verbatim — no synonyms.

| Element | Copy | Evidence |
|---------|------|----------|
| Primary CTA (feedback overlay, both states) | `DEAL` | IMG_7843, IMG_7847, IMG_7849 |
| Secondary CTA (feedback overlay, strategy only) | `UNDERSTAND WHY` | IMG_7843 |
| Feedback heading — correct | `Well played!` | IMG_7847 |
| Feedback heading — incorrect | `Incorrect!` | IMG_7843, IMG_7849 |
| Feedback body — correct | `{ACTION} was the right move.` (e.g. `STAND was the right move.`) | `observed: false — inferred from incorrect-state phrasing pattern; reference IMG_7847 shows counting-specific copy not strategy-specific` |
| Feedback body — incorrect | `In this situation {USER_ACTION} isn't the right move. You should have {CORRECT_ACTION}.` (uppercase action verbs, bolded inline) | IMG_7843 verbatim |
| Action button labels | `STAND`, `HIT`, `SPLIT`, `DOUBLE`, `SURREN.` (uppercase, tracked, exactly these strings — `SURREN.` truncation matches IMG_7841) | IMG_7841 |
| Brand watermark | `BJS` (placeholder — final brand wordmark TBD; uppercase, tracked, watermarkInk @ 25%; do NOT use any competitor domain string) | IMG_7841 — pattern observed; placeholder string until brand is finalized |
| Empty state | Not applicable — TrainerView always has hands during play | n/a |
| Error state | Heading `Something went wrong`, body `Tap DEAL to try again.` | `observed: false — inferred (no error state in references)` |
| Destructive confirmation — end session via back chevron | Title `End this session?` · Body `Your session results so far will be saved.` · Confirm `End Session` (red `feedbackIncorrect` text on `actionDark`) · Cancel `Keep Playing` (white text on `actionDark`) | `observed: false — inferred (no end-session confirmation visible in references)` |

---

## Token Files — Required Symbols

```
BJSColors.surfaceBase           // #0A0A0E
BJSColors.surfaceRaised         // #16161B
BJSColors.actionDark            // #1F1F25
BJSColors.surfaceOverlay        // #FFFFFF
BJSColors.borderSubtle          // #FFFFFF14 (8% white)
BJSColors.borderOnOverlay       // #D8D8DC
BJSColors.accentGold            // #E0A436
BJSColors.actionLabel           // #6B8499
BJSColors.watermarkInk          // #3A5868 (apply at 25% opacity at usage site)
BJSColors.textPrimary           // #FFFFFF
BJSColors.textSecondary         // #FFFFFF99 (60% white)
BJSColors.textOnOverlay         // #0A0A0E
BJSColors.textOnOverlayMuted    // #0A0A0E at 65% opacity
BJSColors.feedbackCorrect       // #2BB673
BJSColors.feedbackIncorrect     // #E5484D
BJSColors.cardBackRed           // #B82828

Typography.caption              // 12pt bold, tracked +1.5
Typography.body                 // 16pt regular, line-height 1.5
Typography.title                // 22pt bold, line-height 1.25

Spacing.xs   // 4
Spacing.sm   // 8
Spacing.md   // 16
Spacing.lg   // 24
Spacing.xl   // 48
Spacing.xxl  // 64

CornerRadius.card           // 8
CornerRadius.button         // 0   (full-bleed action dock cells)
CornerRadius.overlayButton  // 12  (buttons inside white feedback card)
CornerRadius.overlay        // 24  (top corners of white feedback card)
CornerRadius.navCircle      // 16  (32pt diameter back chevron hit target)

Elevation.card        // shadow(color: #00000066, radius: 12, x: 0, y: 6)    [inferred]
Elevation.overlay     // shadow(color: #00000099, radius: 24, x: 0, y: -8)   [inferred]

AnimationTiming.tap         // 120ms easeOut    [inferred]
AnimationTiming.overlayIn   // 280ms easeOut    [inferred]
AnimationTiming.overlayOut  // 200ms easeIn     [inferred]
AnimationTiming.cardDeal    // 320ms easeOut, per-card stagger 60ms  [inferred]
```

All previous tokens not listed above are deleted in this phase. No backwards-compatibility shims.

---

## Decisions Locked in This Spec

| ID | Decision | Reason |
|----|----------|--------|
| UI-07-D1 | TrainerView is dark-mode-only; tokens are fixed hex values, not adaptive | Reference is dark-only and the visual contract depends on the specific near-black background. |
| UI-07-D2 | StatsBar removed from play area — no inline session stats during play | IMG_7841 shows zero competing chrome in the play field; one focal point per screen. |
| UI-07-D3 | Feedback is a bottom centered card with badge straddling the top edge | IMG_7843/IMG_7847 verbatim. |
| UI-07-D4 | Two-row action grid with full-bleed cells, hairline borders, no rounded buttons | IMG_7841. |
| UI-07-D5 | accentGold appears only as table-edge arcs in TrainerView this phase | IMG_7841 — no gold buttons in play view. |
| UI-07-D6 | Real CC0 SVG card deck replaces SF Symbol cards | IMG_7841 — reference uses real card art. |
| UI-07-D7 | **REVERSED:** "UNDERSTAND WHY" button IS rendered in the feedback overlay this phase, wired as no-op placeholder | IMG_7843 clearly shows the button; honoring the reference is more important than deferring. The Know-Why behavior remains a later phase, but the button shape lands now. |
| UI-07-D8 | Destructive end-session confirmation lives on the nav chrome back chevron | Removes End Session button from play area without losing the affordance. |
| UI-07-D9 | **NEW:** Action button labels and icons use `actionLabel` blue (`#6B8499`) — same cool-blue lane as IMG_7841 but intentionally differentiated from competitor's exact value | Inspired by IMG_7841; warmer/lighter to avoid palette collision with competitor. |
| UI-07-D10 | **NEW:** No hand-total numerics are rendered beneath hands in TrainerView | IMG_7841 shows none; previous spec was incorrect. |
| UI-07-D11 | **NEW:** Top-right nav element is a "SOS" text button, not a book icon | IMG_7841 verbatim. |
| UI-07-D12 | **NEW:** Action dock cells are 88pt tall, not 56pt | IMG_7841 visual measure — cells are noticeably taller than standard 56pt. |
| UI-07-D13 | **NEW:** Dealer hand overlap is 30%, player hand overlap is 45% (not a single shared value) | IMG_7841 — measurably different. |
| UI-07-D14 | **NEW:** Watermark uses cool teal-blue ink (`#3A5868` @ 25%), not white at low opacity | IMG_7841 — distinct cool cast visible. |
| UI-07-D15 | **NEW:** Card back red is `#B82828` (vivid), not the previously-guessed `#8B1E1E` | IMG_7841 sampled. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| n/a — native iOS | none | not applicable (no shadcn / no third-party UI registries; iOS SwiftUI project) |

Asset provenance: Byron Knoll public-domain playing card SVG deck (or equivalent CC0). **License verification is a hard gate:** executor MUST fetch and read the actual license statement at the source before committing assets, record source URL + license URL in `BJS/Resources/Cards/ATTRIBUTION.md`, and abort if public-domain/CC0 status cannot be positively confirmed. No code dependencies added.

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending

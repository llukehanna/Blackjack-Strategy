---
phase: 07
plan: 02
subsystem: trainer-ui
tags: [card-assets, svg, cardview, handview, public-domain]
requires: [BJSColors, CornerRadius, Elevation, Card, Rank, Suit]
provides: [CardsXcassets, CardView-svg, HandView-overlap, HandOverlap, CardAssetTests, CardViewTests, HandViewTests]
affects: [BJS/Views/Trainer/TrainerView.swift]
tech-stack:
  added: [public-domain-card-art]
  patterns: [Image-asset-lookup, negative-HStack-spacing, rawValue-overlap-enum]
key-files:
  created:
    - BJS/Resources/Cards/Cards.xcassets/ (53 imagesets)
    - BJS/Resources/Cards/ATTRIBUTION.md
    - BJSTests/CardAssetTests.swift
    - BJSTests/CardViewTests.swift
    - BJSTests/HandViewTests.swift
  modified:
    - BJS/Views/Trainer/CardView.swift
    - BJS/Views/Trainer/HandView.swift
    - BJS/Views/Trainer/TrainerView.swift
decisions:
  - "Card-back sourced from saulspatz/SVGCards as a placeholder; Byron Knoll deck has no back SVG"
  - "Dual public-domain attribution recorded; card_back flagged for replacement with BJS-branded art"
  - "HandView.overlap is required (no default) to force explicit dealer/player choice at call site"
  - "CardView exposes static rankName/suitName helpers so tests share the exact asset-name mapping"
metrics:
  duration: ~15min
  completed: 2026-04-07
---

# Phase 07 Plan 02: Real Card Art + HandView Overlap Summary

Imported 53 public-domain SVG playing cards (52 faces from Byron Knoll via
notpeter/Vector-Playing-Cards, 1 placeholder back from saulspatz/SVGCards),
rewrote `CardView` to render real SVG art via `Image(assetName)`, rewrote
`HandView` to use negative HStack spacing driven by a `HandOverlap` enum
(`dealer=0.30`, `player=0.45`), updated `TrainerView` call sites, and added
three Wave-0 test files covering asset resolution, render non-crash, and raw
overlap values.

## What Changed

**Assets (new):**
- `BJS/Resources/Cards/Cards.xcassets/` — 53 `.imageset` directories
  (52 face cards + `card_back`). Each has `preserves-vector-representation :
  true` and `template-rendering-intent : original`.
- Upstream filenames like `AC.svg`, `10H.svg`, `KS.svg` were renamed to the
  canonical `{rank}_of_{suit}.svg` form (`ace_of_clubs`, `10_of_hearts`,
  `king_of_spades`, …). Ranks map `A→ace, J→jack, Q→queen, K→king`; suits
  map `C→clubs, D→diamonds, H→hearts, S→spades`. Jokers skipped.
- `BJS/Resources/Cards/ATTRIBUTION.md` — dual-source record with license
  excerpts, verification date (2026-04-07), rename table, and an explicit
  **placeholder** marker on `card_back` with replacement plan.

**Views (rewritten):**
- `CardView.swift` — new `Image(assetName)` path. 5:7 aspect, `CornerRadius.card`
  clip, `Elevation.card` shadow. Exposes `init(card:)`, `init(card:faceDown:)`,
  `init(faceDown:)`. Static `rankName(_:)` / `suitName(_:)` helpers drive both
  the asset lookup and test parity. Zero `Image(systemName:` references.
- `HandView.swift` — `enum HandOverlap: CGFloat { case dealer = 0.30; case
  player = 0.45 }`. Body is a single `HStack(spacing: -cardWidth *
  overlap.rawValue)` with `.frame(width: 88)` on each card. No `.clipped()`
  (Pitfall 4).
- `TrainerView.swift` — dealer hand now `HandView(cards:…, overlap: .dealer)`;
  player hand `HandView(cards:…, overlap: .player)`.

**Tests (new):**
- `CardAssetTests.swift` — `allFaceCardsResolve()` loops every `(Rank, Suit)`
  and asserts `UIImage(named:)` is non-nil; `cardBackResolves()` checks
  `card_back`. Uses a private test-bundle marker class as a fallback lookup
  path so the test still passes if the asset ships in the test host bundle.
- `CardViewTests.swift` — hosts every 52 combinations in a
  `UIHostingController`, asserts non-zero bounds; separate test for
  `faceDown: true`; plus `assetNameMapping()` pinning `ace_of_spades`,
  `10_of_hearts`, `king_of_clubs`, and `card_back`.
- `HandViewTests.swift` — raw value assertions (`0.30` / `0.45`) plus a
  host-without-crash smoke test.

## Deviations from Plan

### Auto-resolved during Task 1 checkpoint

**1. [Rule 3 - Blocking] Byron Knoll deck has no card-back SVG**
- **Found during:** Task 1 license verification
- **Issue:** The `notpeter/Vector-Playing-Cards` fork ships only face cards
  (`2C.svg`…`KS.svg` plus two `Joker*.svg`). Plan 02 requires 53 assets
  including `card_back`, and `UI-SPEC` specifies a `card_back` asset name.
- **Fix:** Sourced `card_back.svg` from a second public-domain repository,
  `saulspatz/SVGCards` (`Decks/Vertical2/svgs/redBack.svg`), with user
  approval captured in the Task 1 checkpoint. Documented as a placeholder
  in `ATTRIBUTION.md` with an explicit replacement plan. Dual attribution
  recorded.
- **Files modified:** `BJS/Resources/Cards/Cards.xcassets/card_back.imageset/`,
  `BJS/Resources/Cards/ATTRIBUTION.md`
- **Commit:** `5af66eb`

### Minor

**2. `project.yml` untouched** — `sources: [BJS]` and `sources: [BJSTests]`
already glob the entire tree, so no XcodeGen regeneration is required to pick
up new asset-catalog directories or the three new test files. The plan's
instruction to "update project.yml" was unnecessary for this repo layout.

**3. `CardView(card:, faceDown:)` compatibility init retained** — the plan
specified only `init(card:)` and `init(faceDown:)`, but `TrainerView` (not in
scope for rewrite) still calls `CardView(card:, faceDown:)` in legacy code
paths. A compatibility initializer was added rather than editing out-of-scope
call sites. No behavioral difference.

## Auth Gates

Task 1 was a `checkpoint:human-action` license gate. User approved both
sources (notpeter fork + saulspatz back as placeholder) before Task 2
executed. No other auth gates.

## Known Stubs

**1. `card_back.svg` is a placeholder** — generic red-back SVG from
saulspatz/SVGCards. Functionally complete (visually distinct, loads via
`UIImage(named:)`), but should be replaced with a BJS-branded back using the
`BJSColors.cardBackRed` token (UI-07-D15) in a later phase. Asset *name*
(`card_back`) is stable; only file contents need swapping.

## Build Verification

`xcodebuild` is unavailable in this worktree environment (same constraint
recorded in 07-01). Static verification performed:

- `grep -c "systemName" BJS/Views/Trainer/CardView.swift` → **0**
- `grep -c '\.clipped()' BJS/Views/Trainer/HandView.swift` → **0**
- `grep "case dealer = 0.30"` / `"case player = 0.45"` → both present
- `ls Cards.xcassets | grep -c '\.imageset$'` → **53**
- `test -f BJS/Resources/Cards/ATTRIBUTION.md` → OK
- `grep -i "public domain" ATTRIBUTION.md` → multiple matches
- `Card` initializer `public init(rank:suit:)` confirmed in BJSCore
- `Rank` / `Suit` enums confirmed `CaseIterable`

Human/CI must run `xcodebuild test -scheme BJS
-only-testing:BJSTests/CardAssetTests -only-testing:BJSTests/CardViewTests
-only-testing:BJSTests/HandViewTests` under Xcode 26 to confirm green.

## Self-Check: PASSED

**Files exist:**
- FOUND: BJS/Resources/Cards/Cards.xcassets/ (53 imagesets)
- FOUND: BJS/Resources/Cards/ATTRIBUTION.md
- FOUND: BJS/Views/Trainer/CardView.swift (rewritten)
- FOUND: BJS/Views/Trainer/HandView.swift (rewritten)
- FOUND: BJSTests/CardAssetTests.swift
- FOUND: BJSTests/CardViewTests.swift
- FOUND: BJSTests/HandViewTests.swift

**Commits exist:**
- FOUND: 5af66eb feat(07-02): import 53 public-domain card SVGs + ATTRIBUTION
- FOUND: 6e351ff feat(07-02): rewrite CardView/HandView against SVG assets + Wave-0 tests

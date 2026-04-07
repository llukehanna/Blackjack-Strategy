# Phase 7: UI Foundation Rebuild — Research

**Researched:** 2026-04-07
**Domain:** SwiftUI design systems, vector card asset integration, SwiftUI visual verification
**Confidence:** HIGH (most decisions already locked in UI-SPEC; research validates execution mechanics)

## Summary

Phase 7 is an unusually constrained research target: the `07-UI-SPEC.md` is exhaustive and locks nearly every visual value — color hexes, spacing scale, typography roles, card overlap percentages, token symbol names, feedback overlay geometry, copy, and decisions D1–D15. The CONTEXT and UI-SPEC together constitute the design contract. Research does NOT need to explore alternative architectures, design patterns, or token strategies — all decided.

What research must validate is **execution mechanics**: (1) where to get a verified CC0 card deck and the exact license chain, (2) how SwiftUI actually renders SVG assets in iOS 18 (native asset catalog vs. runtime SVG parser), (3) how to structure token files as caseless enums matching the existing Phase 02.1/02.2 pattern, (4) how CardView's fixed-width SVG rendering composes with HandView overlap, and (5) whether Nyquist validation for a pure-visual phase should use snapshot tests or structural unit tests (the repo has no UI-test infrastructure today).

**Primary recommendation:** Use the **notpeter/Vector-Playing-Cards** GitHub fork of Byron Knoll's original public-domain SVG deck as the canonical source. Import SVGs directly into the Xcode asset catalog with "Preserve Vector Data" enabled — no third-party SVG parser dependency needed. Rewrite `BJS/Design/` token files as caseless enums matching existing Phase 02.1 convention. For Nyquist validation on a visual-only phase, use **structural unit tests against token values** (no snapshot-testing dependency this phase — the existing test target has zero UI tests and adding `swift-snapshot-testing` is out of scope per CONTEXT "no new third-party dependencies").

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Visual benchmark: 21 Blackjack Strategy Trainer reference screenshots `design-system/reference/IMG_7838–IMG_7849`
- Foundation-only — TrainerView is the ONLY screen rebuilt this phase
- Rewrite `BJS/Design/` as strict minimal token system (~10 colors, ~5 type sizes, ~6 spacing values) — all old files replaced, no backwards-compatibility shims
- Real CC0 playing-card SVG deck under `BJS/Resources/Cards/` with attribution file
- CardView rebuilt to render real card art, NOT SF Symbols
- Dedicated card-back design matching new visual language
- TrainerView rebuilt from scratch: one focal point, generous breathing room, large action buttons, centered-card feedback overlay
- StatsBar and End Session moved OUT of play area into nav chrome
- iOS 18+, Swift 6.2, SwiftUI, MVVM + `@Observable` — no architecture changes
- Engine layer (BJSCore) not touched
- No regressions to TrainerViewModel or any non-UI logic
- All existing tests (BJSCore + BJSTests) must still pass

### Claude's Discretion
- Exact SVG deck source (Byron Knoll original vs. a fork) — verify license before commit
- Token file internal structure (caseless enum vs. struct namespace) — must match existing project convention
- Preview states and screenshot capture mechanism (Xcode Previews variants, device selection)
- Whether to add new unit tests for tokens / card asset lookup (discretionary, within "no new deps")
- Nyquist validation strategy within the "no new third-party dependencies" constraint

### Deferred Ideas (OUT OF SCOPE)
- StatsView, SettingsView, SessionStartView, SessionSummaryView, RuleConfigView, onboarding
- "Know Why" / UNDERSTAND WHY button behavior — button is RENDERED this phase (per UI-07-D7) but wired as no-op placeholder
- Hi-Lo counting drill UI
- New gameplay features, split implementation
- Strategy table modal (IMG_7842), PRO paywall (IMG_7844), Hi-Lo info modal (IMG_7845), counting trainer (IMG_7846/7847/7849), streak milestone (IMG_7848)
- Light mode for TrainerView (dark-only per UI-07-D1)
- Snapshot-testing dependency
- New gameplay tests beyond verifying existing suite still passes

## Phase Requirements

No formal REQ-IDs are mapped to Phase 7 in `REQUIREMENTS.md` (phase is a visual quality rebuild, not a new capability). The authoritative contract is `07-UI-SPEC.md` decisions UI-07-D1 through UI-07-D15 plus the Token Files — Required Symbols block. Planner should treat each UI-07-D# as an implicit requirement and each token symbol as an acceptance item.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 18 SDK | UI layer | Already the project stack; no change |
| Swift | 6.2 | Language | Already the project stack |
| Xcode Asset Catalog | Xcode 26 | SVG card asset storage + vector preservation | Native, zero dependency, handles vector at render time |
| SF Symbols | System | Action dock icons (`hand.raised`, `plus`, `arrow.left.and.right`, `flag`, `square.on.square`, `questionmark.circle`, `chevron.left`, `xmark`, `checkmark`) | Per UI-SPEC — actions use SF Symbols, only card faces/backs use SVG art |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Xcode Previews | Xcode 26 | Visual verification of TrainerView states | Replaces snapshot tests for this phase |
| Swift Testing | Xcode 26 built-in | Token value assertions (if added) | Structural validation only — not pixel comparison |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Asset catalog SVG | `exyte/SVGView` runtime SVG parser | Violates "no new third-party dependencies"; unnecessary — asset catalog handles SVG natively |
| Asset catalog SVG | Convert SVGs to PDFs | Both supported; SVG is fine and source files remain SVG |
| Asset catalog SVG | Rasterize SVG → PNG 1x/2x/3x | Loses vector scalability; more bundle bloat; worse quality at large sizes |
| Structural token tests | `pointfreeco/swift-snapshot-testing` | New dependency — CONTEXT forbids. Defer snapshot testing to a later phase. |
| Byron Knoll direct | `notpeter/Vector-Playing-Cards` fork | Fork is actively hosted on GitHub (easy clone) and explicitly preserves original public-domain license. Same art, simpler fetch. |

**Installation:** None. No new packages. All assets are imported through Xcode asset catalog UI (drag SVGs into `BJS/Resources/Cards/Cards.xcassets` or equivalent).

**Version verification:** No package versions to verify — phase uses only built-in frameworks. Xcode 26.3 / Swift 6.2 / iOS 18 SDK are already locked per `CLAUDE.md`.

## Architecture Patterns

### Recommended Project Structure

```
BJS/
├── Design/
│   ├── BJSColors.swift          # 16 color tokens (rewritten)
│   ├── Typography.swift         # 3 roles: caption, body, title (rewritten)
│   ├── Spacing.swift            # 6 values: xs/sm/md/lg/xl/xxl (rewritten)
│   ├── CornerRadius.swift       # card/button/overlayButton/overlay/navCircle (rewritten)
│   ├── Elevation.swift          # card + overlay shadows (rewritten)
│   └── AnimationTiming.swift    # tap/overlayIn/overlayOut/cardDeal (rewritten)
├── Resources/
│   └── Cards/
│       ├── Cards.xcassets/      # 52 face SVGs + 1 back SVG, vector data preserved
│       └── ATTRIBUTION.md       # source URL + license URL + verification date
└── Views/
    └── Trainer/
        ├── CardView.swift       # rebuilt: Image("cards/{rank}_of_{suit}") from asset catalog
        ├── HandView.swift       # rebuilt: HandOverlap.dealer (0.30) / .player (0.45)
        ├── TrainerView.swift    # rebuilt end-to-end per UI-SPEC layout contract
        ├── ActionButtonsView.swift  # rebuilt: 88pt cells, two-row grid, hairline dividers
        └── FeedbackOverlayView.swift # rebuilt: bottom white card, straddling badge
```

### Pattern 1: Caseless Enum Token Namespace (matches existing project convention)

**What:** Tokens as `enum` with no cases — acts as a non-instantiable namespace for static properties.
**When to use:** All token files this phase. Matches the existing convention established in Phase 02.1 (STATE.md: "Design tokens as caseless enums (Spacing, BJSColors, Typography) for non-instantiable namespaces").
**Example:**
```swift
// Source: existing BJS/Design/Spacing.swift convention
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 48
    static let xxl: CGFloat = 64
}

enum BJSColors {
    static let surfaceBase     = Color(red: 0x0A/255, green: 0x0A/255, blue: 0x0E/255)
    static let surfaceRaised   = Color(red: 0x16/255, green: 0x16/255, blue: 0x1B/255)
    static let accentGold      = Color(red: 0xE0/255, green: 0xA4/255, blue: 0x36/255)
    // … per UI-SPEC Token Files block
}
```

### Pattern 2: Asset Catalog SVG with Preserve Vector Data

**What:** Drop SVG files into an `.xcassets` folder; check "Preserve Vector Data" in the Attributes Inspector so SwiftUI scales without re-rasterizing.
**When to use:** All 53 card assets (52 faces + 1 back).
**Example:**
```swift
// Source: Apple docs + bjango/hackingwithswift guidance
Image("cards/5_of_hearts")
    .resizable()
    .aspectRatio(5.0/7.0, contentMode: .fit)
    .frame(width: 88)
// With Preserve Vector Data ON, the SVG renders sharply at any size.
```

Naming convention: `{rank}_of_{suit}` lowercase (e.g., `5_of_hearts`, `king_of_spades`, `ace_of_clubs`). Back asset: `card_back`. Matches Byron Knoll's original file naming and makes the lookup a simple string interpolation in `CardView`.

### Pattern 3: Overlap Layout via ZStack + Negative Offset

**What:** Render cards in a ZStack; offset each card by `-cardWidth * (1 - overlap)` so they stack with a configurable visible portion.
**Example:**
```swift
// Hand overlap layout (inferred from SwiftUI patterns; no direct Context7 source)
enum HandOverlap: CGFloat {
    case dealer = 0.30  // back covers ~30% of face-up
    case player = 0.45  // tighter stacking
}

struct HandView: View {
    let cards: [CardSlot]
    let overlap: HandOverlap
    private let cardWidth: CGFloat = 88

    var body: some View {
        HStack(spacing: -cardWidth * overlap.rawValue) {
            ForEach(cards) { CardView(slot: $0) }
        }
    }
}
```

Note: negative HStack spacing is the idiomatic SwiftUI way to overlap without manual ZStack offsets. Z-order follows declaration order; later cards render on top.

### Anti-Patterns to Avoid

- **Rasterizing SVGs to @1x/@2x/@3x PNGs:** defeats the point of vector assets and bloats bundle size. Use "Preserve Vector Data."
- **Adding `SVGView` or any runtime SVG parser:** violates CONTEXT constraint; asset catalog handles it natively.
- **Using `Color(hex:)` helper:** the existing project uses `Color(red:green:blue:)` RGB init — don't introduce a new hex-string helper this phase. Stay consistent.
- **Putting hand totals under hands:** UI-07-D10 explicitly forbids this. Reference shows none.
- **Making tokens adaptive (light/dark via `UIColor` dynamic provider):** UI-07-D1 locks dark-only fixed hex values this phase. Reverses the Phase 02.1 adaptive pattern intentionally.
- **Re-using old `cardFaceDown` token:** UI-SPEC deletes all prior tokens not in the new list. No shims.
- **Treating the dock as a separate surface with its own fill:** per UI-SPEC it's `surfaceBase` (same as background) — distinguished by content and hairline dividers only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SVG parsing / rendering | Custom SVG parser or path-drawing in Swift | Asset catalog + `Image("name")` with Preserve Vector Data | Xcode/UIKit already parses SVG at build time; zero runtime cost |
| Playing card artwork | Draw 52 faces from scratch in Swift/Canvas | Byron Knoll / notpeter public-domain SVG deck | Hundreds of hours of work for zero differentiation; a free, verified public-domain deck exists |
| Color hex parsing | `Color(hex: "#0A0A0E")` helper | `Color(red: 0x0A/255, green: 0x0A/255, blue: 0x0E/255)` | Built-in; no helper to maintain; matches project convention |
| Snapshot diffing | Custom image-diff utility | Xcode Previews for visual verification this phase (deferred: swift-snapshot-testing in a later phase) | This phase is human-verified against reference PNGs per CONTEXT scope 5 |

**Key insight:** Phase 7 deliberately avoids adding any code that could become a dependency to maintain. Every non-trivial capability (SVG rendering, vector preservation, shadow rendering, animation timing) is delegated to the platform.

## Common Pitfalls

### Pitfall 1: SVG Without "Preserve Vector Data"
**What goes wrong:** SVG is imported but Xcode rasterizes it to @1x at import time; when scaled up in the UI it blurs.
**Why it happens:** "Preserve Vector Data" is OFF by default in the asset catalog.
**How to avoid:** For every card SVG, in Attributes Inspector: set Scales = "Single Scale" and tick "Preserve Vector Data."
**Warning signs:** Card edges look fuzzy in Previews at 88pt; zooming in shows pixelation.

### Pitfall 2: File Naming Mismatch Between Asset Catalog and CardView Lookup
**What goes wrong:** Byron Knoll's original filenames vs. `notpeter` fork vs. what `CardView` expects diverge; runtime `Image("...")` silently returns a blank image.
**Why it happens:** SwiftUI `Image(_: String)` fails silently when the asset name doesn't match.
**How to avoid:** Define a single `Card.assetName` computed property in the view layer (NOT in `BJSCore` — engine stays SwiftUI-free) that maps `(rank, suit)` → exact asset name, and assert every 52-card combination resolves via a unit test against the bundle.
**Warning signs:** Blank white rectangles where cards should render in Previews.

### Pitfall 3: License Drift from Fork to Fork
**What goes wrong:** A GitHub fork of Byron Knoll's deck adds a modified file under a different license (e.g., MIT), and the committed asset is not actually public domain.
**Why it happens:** Forks accumulate diffs; license headers may not update.
**How to avoid:** Verify against Byron Knoll's original blog post (`http://byronknoll.blogspot.com/2011/03/vector-playing-cards.html`) which states public-domain release; record BOTH the fork URL AND the original URL in `ATTRIBUTION.md`; spot-check at least one face card's SVG metadata for any embedded copyright string.
**Warning signs:** LICENSE file in the fork differs from "public domain"; `README.md` mentions CC BY or another attributional license; SVG `<metadata>` element contains a copyright string.

### Pitfall 4: Negative HStack Spacing Clipping at Container Edge
**What goes wrong:** Overlapped cards near the leading/trailing edge of the screen get clipped by a `ClipShape` or `.frame(maxWidth:)` modifier.
**Why it happens:** Negative spacing lets child views extend past the natural HStack bounds; a parent clip removes the overflow.
**How to avoid:** Do not apply `.clipped()` to HandView. Parent containers should use `.frame(maxWidth: .infinity)` without clipping.
**Warning signs:** First or last card has a visible vertical edge cut off.

### Pitfall 5: Shadow Rendering on Dark Background
**What goes wrong:** `Elevation.card` shadow (`#00000066`) is invisible on `surfaceBase` `#0A0A0E` because the background is already nearly black.
**Why it happens:** Shadows on near-black backgrounds are mathematically valid but visually imperceptible.
**How to avoid:** Verify in Preview that cards have a visible "lift." If not, this may need to be addressed in execution by substituting a subtle inner highlight or accepting no shadow on dealer/player cards. UI-SPEC marks this value as `observed: false — inferred`, so the planner should flag it for visual confirmation.
**Warning signs:** Cards look "pasted" flat against background in Preview.

### Pitfall 6: Xcode Preview Compilation with Rewritten Tokens
**What goes wrong:** Rewriting `BJSColors.swift` in place breaks every existing view file referencing deleted tokens (e.g., `BJSColors.cardFaceDown`); the whole project fails to compile and Previews die for all screens.
**Why it happens:** UI-SPEC mandates "no backwards-compatibility shims." A wholesale token rewrite breaks StatsView/SettingsView/SessionStartView/SessionSummaryView references.
**How to avoid:** **Planner must sequence token rewrite and dependent-view updates as an atomic task set.** Either: (a) rewrite tokens AND stub-migrate out-of-scope screens to use new tokens mechanically in the same commit, OR (b) temporarily keep old token symbols as deprecated `@available` shims for exactly the duration of this phase, then delete at phase end (violates "no shims" — not preferred), OR (c) accept that other screens are visually broken for the phase duration and file a follow-up phase to re-skin them using the new tokens.
**Warning signs:** Build errors in SessionStartView / StatsView / SessionSummaryView after editing `BJSColors.swift`. This is the single biggest execution risk.

**Recommended handling:** Option (a) — rewrite tokens and do a **mechanical symbol replacement** across all existing view files in the same plan. Every old token gets a new-token equivalent where one exists, or `#warning("Phase 7: non-TrainerView screen uses token X pending re-skin")` where no equivalent exists. This keeps the build green without introducing shims. The planner should allocate an explicit task for "token rewrite + mechanical replacement across out-of-scope views."

## Code Examples

### Token file structure
```swift
// Source: existing BJS/Design/Spacing.swift convention (Phase 02.1)
import SwiftUI

enum BJSColors {
    static let surfaceBase = Color(red: 0x0A/255, green: 0x0A/255, blue: 0x0E/255)
    static let surfaceRaised = Color(red: 0x16/255, green: 0x16/255, blue: 0x1B/255)
    static let actionDark = Color(red: 0x1F/255, green: 0x1F/255, blue: 0x25/255)
    static let surfaceOverlay = Color.white
    static let borderSubtle = Color.white.opacity(0.08)  // #FFFFFF14
    static let borderOnOverlay = Color(red: 0xD8/255, green: 0xD8/255, blue: 0xDC/255)
    static let accentGold = Color(red: 0xE0/255, green: 0xA4/255, blue: 0x36/255)
    static let actionLabel = Color(red: 0x6B/255, green: 0x84/255, blue: 0x99/255)
    static let watermarkInk = Color(red: 0x3A/255, green: 0x58/255, blue: 0x68/255)  // apply .opacity(0.25) at site
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textOnOverlay = Color(red: 0x0A/255, green: 0x0A/255, blue: 0x0E/255)
    static let textOnOverlayMuted = Color(red: 0x0A/255, green: 0x0A/255, blue: 0x0E/255).opacity(0.65)
    static let feedbackCorrect = Color(red: 0x2B/255, green: 0xB6/255, blue: 0x73/255)
    static let feedbackIncorrect = Color(red: 0xE5/255, green: 0x48/255, blue: 0x4D/255)
    static let cardBackRed = Color(red: 0xB8/255, green: 0x28/255, blue: 0x28/255)
}
```

### CardView rebuild using asset catalog
```swift
// Source: Apple asset catalog docs + hackingwithswift vector images guidance
import SwiftUI
import BJSCore

struct CardView: View {
    let card: Card?       // nil = face down
    let faceDown: Bool

    var body: some View {
        Image(assetName)
            .resizable()
            .aspectRatio(5.0/7.0, contentMode: .fit)
            .cornerRadius(CornerRadius.card)
            .shadow(
                color: .black.opacity(0.4),
                radius: 12,
                x: 0,
                y: 6
            )
            .accessibilityLabel(accessibilityDescription)
    }

    private var assetName: String {
        if faceDown { return "card_back" }
        guard let card = card else { return "card_back" }
        return "\(rankName(card.rank))_of_\(suitName(card.suit))"
    }
}
```

### Action dock cell (88pt, hairline dividers)
```swift
struct ActionCell: View {
    let icon: String      // SF Symbol name
    let label: String     // already uppercase
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .regular))
                Text(label)
                    .font(Typography.caption)
                    .tracking(1.5)
            }
            .foregroundStyle(BJSColors.actionLabel)
            .frame(maxWidth: .infinity)
            .frame(height: 88)
        }
    }
}
```

## Runtime State Inventory

Phase 7 is a visual rebuild with **no data migration, no service config, no OS-registered state, no secrets, no build artifacts**. Explicit per-category:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — SwiftData models (`SessionRecord`, `SessionDecision`) are untouched. No rename of persisted string keys. | None |
| Live service config | None — offline-first app, no external services. | None |
| OS-registered state | None — no Task Scheduler / launchd / systemd registrations. | None |
| Secrets / env vars | None — no secrets in this project. | None |
| Build artifacts | Xcode asset catalog will have new entries under `BJS/Resources/Cards/Cards.xcassets`. Old card-rendering code deleted. `xcodeproj` may need regeneration via XcodeGen (per STATE.md: "XcodeGen manages project generation"). | Re-run XcodeGen if `project.yml` sources list changes |

**The canonical question answered:** After token files and CardView are rewritten, the only runtime system carrying old state is the Xcode build cache. A clean build resolves it. No persisted data references the old card-rendering approach.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | Build + Previews | Assumed ✓ | 26.3 (per CLAUDE.md) | — |
| Swift 6.2 toolchain | Compile | Assumed ✓ | 6.2.x | — |
| XcodeGen | Project file regeneration (per STATE.md 02-01) | Assumed ✓ | any recent | Manual .xcodeproj edit |
| Internet access (one-time) | Fetch Byron Knoll / notpeter SVG deck | Required during plan execution | — | **None — hard gate**: if fetch fails, phase cannot ship real card art |
| SVG card source | Byron Knoll original or `notpeter/Vector-Playing-Cards` fork | Reachable via public web/git | — | Saulspatz SVGCards (also public domain); Tek Eye SVG playing cards (also public domain) |

**Missing dependencies with no fallback:** None identified — multiple verified public-domain SVG deck sources exist.

**Missing dependencies with fallback:** SVG source has at least three independent public-domain alternatives; license verification protocol chooses between them.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (Xcode 26 built-in) for unit tests; XCTest for any UI tests (none this phase) |
| Config file | `BJSTests/` target as configured in `project.yml` (XcodeGen) |
| Quick run command | `xcodebuild test -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BJSTests` |
| Full suite command | `xcodebuild test -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16'` (runs BJSCoreTests + BJSTests) |

### Phase Requirements → Test Map

Phase 7 has no functional requirements — the contract is visual. Nyquist validation for this phase uses **structural unit tests** (not pixel snapshot tests — CONTEXT forbids new deps) plus **human visual verification** against reference PNGs per CONTEXT scope step 5.

| Req (UI-07-D#) | Behavior | Test Type | Automated Command | File Exists? |
|----------------|----------|-----------|-------------------|--------------|
| D1-D4 (tokens) | All 16 colors, 3 typography roles, 6 spacing values, 5 corner radii exist and hold the specified numeric values | unit (Swift Testing) | `xcodebuild test -only-testing:BJSTests/DesignTokenTests` | ❌ Wave 0 |
| D6 (real cards) | All 52 face assets + card back asset resolve in bundle via `UIImage(named:)` lookup | unit | `xcodebuild test -only-testing:BJSTests/CardAssetTests` | ❌ Wave 0 |
| D6 (CardView) | CardView compiles, renders without crashing for every (rank, suit) combination and faceDown | unit | `xcodebuild test -only-testing:BJSTests/CardViewTests` | ❌ Wave 0 |
| D2, D8, D11 (nav chrome) | TrainerView has no inline StatsBar child; has back chevron and SOS text button | structural unit via view inspection (or: compile-time guarantee via view tree audit) | manual code review | n/a |
| D3, D7, D10 (feedback overlay) | FeedbackOverlayView renders both DEAL and UNDERSTAND WHY buttons in strategy mode; heading/body strings match contract | unit | `xcodebuild test -only-testing:BJSTests/FeedbackOverlayTests` | ❌ Wave 0 |
| D13 (hand overlap) | HandOverlap.dealer == 0.30, HandOverlap.player == 0.45 | unit | `xcodebuild test -only-testing:BJSTests/HandViewTests` | ❌ Wave 0 |
| All UI-07-D# | TrainerView renders without crash in pre-decision, awaiting-decision, and feedback states in Xcode Previews | Preview (manual) | Human visual check, side-by-side with `design-system/reference/IMG_7841.PNG` and `IMG_7843.PNG` | n/a |
| Regression | All existing BJSCore + BJSTests pass unchanged | unit | full suite command | ✅ |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BJSTests` (fast, ~30s)
- **Per wave merge:** Full suite command (BJSCoreTests + BJSTests)
- **Phase gate:** Full suite green + manual visual side-by-side with IMG_7841 / IMG_7843 before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BJSTests/DesignTokenTests.swift` — asserts every token symbol listed in UI-SPEC "Token Files — Required Symbols" block exists and holds the expected value. Covers D1-D4, D14, D15.
- [ ] `BJSTests/CardAssetTests.swift` — loops over every (Rank × Suit) and asserts `UIImage(named: assetName)` is non-nil; also asserts `card_back` resolves. Covers D6.
- [ ] `BJSTests/CardViewTests.swift` — renders `CardView` for every Card into a hosting controller and asserts no crash + non-zero bounds. Covers D6.
- [ ] `BJSTests/FeedbackOverlayTests.swift` — asserts heading / body / button label strings match the copywriting contract verbatim. Covers D7, copy contract.
- [ ] `BJSTests/HandViewTests.swift` — asserts `HandOverlap.dealer == 0.30` and `HandOverlap.player == 0.45`. Covers D13.

*(No framework install needed — Swift Testing is built in; BJSTests target already exists per STATE.md Phase 02.)*

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Rasterized PNG @1x/@2x/@3x per card (156 files) | Single SVG per card with Preserve Vector Data (53 files) | Xcode 12 (2020) | Smaller bundle, sharper at any size |
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 / Xcode 15 | Already adopted project-wide |
| Raw `Color(.sRGB, ...)` per-call-site | Caseless enum token namespace | Phase 02.1 convention | Already adopted project-wide |
| Adaptive light/dark tokens via `UIColor` dynamic provider | Fixed-hex dark-only tokens | Phase 07 (this phase, UI-07-D1) | Intentional narrowing — reference is dark-only |

**Deprecated/outdated:**
- SF-Symbol-based card rendering (previous CardView): replaced by SVG asset catalog this phase.
- `BJSColors.cardFaceDown`: replaced by `cardBackRed` + the card-back SVG asset.
- `Typography.mono`, `Typography.statValue`, `Typography.heroStat`, `Typography.playerTotal`: all deleted — new 3-role scale is caption/body/title only.

## Open Questions

1. **Exact SVG asset naming convention in the chosen source**
   - What we know: Byron Knoll's original and `notpeter` fork use lowercase `{rank}_of_{suit}.svg` with words (`ace_of_spades.svg`, `10_of_hearts.svg`).
   - What's unclear: Jack/Queen/King may be `jack_of_spades.svg` or `jack_of_spades2.svg` (original deck has multiple face-card variants).
   - Recommendation: Planner allocates a small task "inventory the fetched deck and rename assets to match `CardView` lookup" before importing to xcassets.

2. **How much of the existing TrainerView / ActionButtonsView / FeedbackOverlayView can be retained?**
   - What we know: UI-SPEC says "rebuilt end-to-end"; CONTEXT says "no regressions to TrainerViewModel."
   - What's unclear: Whether the executor rewrites these files or deletes and recreates them. Functionally identical if done cleanly.
   - Recommendation: Delete and recreate. Preserving scaffolding invites drift from the contract.

3. **Shadow visibility on `surfaceBase` — visually confirmable?**
   - What we know: UI-SPEC marks `Elevation.card` as inferred. `#00000066` shadow on `#0A0A0E` background may be imperceptible.
   - What's unclear: Whether the reference cards actually show a shadow or whether the visual "lift" comes from the slight edge highlight of the SVG itself.
   - Recommendation: Implement as specified; if Preview shows no visible lift, file a correction during the visual verification step (CONTEXT scope 5).

4. **What exactly happens to StatsView / SettingsView / SessionStartView / SessionSummaryView when old tokens are deleted?**
   - What we know: UI-SPEC mandates "all previous tokens not listed above are deleted; no backwards-compatibility shims." STATE.md shows these views actively use old tokens (e.g., `Typography.heroStat`, `Typography.playerTotal`, `cardFaceDown`).
   - What's unclear: Whether the planner treats the other screens' compile breakage as in-scope cleanup or out-of-scope breakage.
   - Recommendation: **Critical planning decision.** Recommend option (a) from Pitfall 6 — mechanical token-symbol replacement across all out-of-scope views in the same plan as the token rewrite, with `#warning` markers where no direct mapping exists. This keeps the build green and defers the *visual* re-skin to a later phase while honoring the UI-SPEC's "no shims" rule.

## Sources

### Primary (HIGH confidence)
- `CLAUDE.md` project instructions — Swift 6.2 / SwiftUI / iOS 18 / no third-party deps
- `.planning/phases/07-ui-foundation-rebuild/07-CONTEXT.md` — Phase scope, constraints, out-of-scope list
- `.planning/phases/07-ui-foundation-rebuild/07-UI-SPEC.md` — Exhaustive visual contract (UI-07-D1 through D15, token symbols, copy)
- `.planning/STATE.md` — existing token convention (caseless enums), XcodeGen, prior Phase 02.1/02.2 decisions
- [Byron Knoll: Vector Playing Cards blog post (2011)](http://byronknoll.blogspot.com/2011/03/vector-playing-cards.html) — original public-domain release statement
- [notpeter/Vector-Playing-Cards (GitHub)](https://github.com/notpeter/Vector-Playing-Cards) — maintained fork with SVG + PNG
- [Apple Developer Forums: SVG asset catalog support](https://developer.apple.com/forums/thread/119331) — official confirmation SVG is supported since Xcode 12
- [Hacking with Swift: vector images in asset catalog](https://www.hackingwithswift.com/example-code/xcode/how-to-use-vector-images-in-your-asset-catalog) — Preserve Vector Data usage

### Secondary (MEDIUM confidence)
- [bjango: SVGs in asset catalogs](https://bjango.com/articles/svgassetcatalogs/) — explains SVGs are bundled natively, not converted at build time
- [SwiftLee: SVG image assets](https://www.avanderlee.com/xcode/svg-image-assets/) — corroborates single-scale Preserve Vector Data pattern
- [saulspatz/SVGCards (GitHub)](https://github.com/saulspatz/SVGCards) — alternative public-domain jumbo-index deck
- [Tek Eye: SVG Playing Cards, Public Domain](https://www.tekeye.uk/playing_cards/svg-playing-cards) — third public-domain fallback source
- [pointfreeco/swift-snapshot-testing (GitHub)](https://github.com/pointfreeco/swift-snapshot-testing) — referenced but NOT adopted (CONTEXT forbids new deps); noted for a later phase

### Tertiary (LOW confidence)
- UI-SPEC `observed: false — inferred` items: shadow values, animation timings, tap feedback scale, spacing xs/sm (reference doesn't expose pixel grid). These remain LOW until visual verification.

## Project Constraints (from CLAUDE.md)

- **Tech Stack:** Swift + SwiftUI + Xcode only — no cross-platform, no web, no backend
- **Platform:** iPhone first — iPad deferred
- **Offline:** Core features must work fully offline (no impact this phase)
- **Architecture:** MVVM + `@Observable` — no architecture changes (UI-SPEC CONTEXT confirms)
- **Dependencies:** No third-party UI libraries; SwiftUI built-in only (matches CONTEXT "no new third-party dependencies")
- **Concurrency:** MainActor by default (Swift 6.2 Approachable Concurrency) — applies to all View code
- **GSD workflow enforcement:** Planner must structure work as a GSD phase plan, not ad-hoc edits
- **Engine isolation:** `BJSCore` has zero SwiftUI imports — nothing in this phase touches it
- **Forbidden libraries (from CLAUDE.md):** TCA, Combine, Realm, GRDB, Lottie, SnapKit, Firebase, Alamofire — none relevant; none proposed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all built-in frameworks, already in use
- Architecture: HIGH — matches existing Phase 02.1/02.2 caseless-enum token pattern verbatim
- Pitfalls: HIGH for Pitfall 6 (token rewrite blast radius, identified from STATE.md); MEDIUM for Pitfall 5 (shadow visibility, inferred); HIGH for others
- Card source / license: HIGH — Byron Knoll's public-domain release is well-documented on his original blog and mirrored in multiple independent forks
- Visual contract: N/A — locked by UI-SPEC, not a research target

**Research date:** 2026-04-07
**Valid until:** 2026-05-07 (30 days — stack is stable, Xcode 26.3 is current; re-verify if Xcode ships a new release before execution)

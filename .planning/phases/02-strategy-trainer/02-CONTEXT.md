# Phase 2: Strategy Trainer - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the first iOS app UI on top of `BJSCore`: an interactive basic strategy trainer where users deal hands under a configurable rule set, make decisions, get immediate feedback, and track accuracy across a session. Phase 2 creates the Xcode iOS app project itself and delivers the MVP training loop (Learn mode + Test mode), rule configuration with casino presets, inline mid-session stats, and a full end-of-session summary with mistake log. No Xcode project exists before this phase.

</domain>

<decisions>
## Implementation Decisions

### Card & Table Visual Style
- **D-01:** Cards use minimal text style — clean white/dark rectangle with rank + suit symbol in text (e.g., `A♥`, `10♣`). No pip layout, no full face rendering. Matches the analytical, non-casino-themed aesthetic from PROJECT.md.
- **D-02:** Suits are color-coded: red for hearts/diamonds, black/dark for clubs/spades. Standard convention — fast visual parsing.
- **D-03:** Play area uses standard vertical layout: dealer hand at top (one card face-up, one face-down), player hand in the middle, action buttons below the player hand. Natural top-to-bottom read on iPhone.

### Feedback UX
- **D-04:** Feedback is a color flash overlay with a label: green "Correct ✓" or red "Incorrect — Should: [Action]" displayed for ~1 second, then auto-advances. No tap-to-dismiss required for correct decisions. Fast pacing.
- **D-05:** After the feedback flash, the hand plays out fully — dealer draws to completion, win/loss/push result is briefly shown before the next hand begins. This reinforces the consequence of the decision.
- **D-06:** Feedback triggers on every individual decision in a hand (not just the opening action). If a user hits twice then stands, each decision is evaluated against the correct strategy for that state.

### Session Flow
- **D-07:** Sessions are open-ended — the user plays as many hands as they want and taps "End Session" to stop. No fixed hand count.
- **D-08:** Learn mode vs Test mode is selected on a pre-session start screen (same screen as rule/preset selection). The user can't accidentally switch modes mid-session.
- **D-09:** Mid-session inline stats are always visible during play: **accuracy %, hand count, and error count** (e.g., "87% · 24 hands · 3 errors"). Compact display, does not interrupt the training loop.
- **D-10:** End-of-session summary replaces the play area inline (no modal/sheet). Shows: hands played, accuracy %, error count, best streak, and a mistake log (each error listed as "Soft 18 vs 9 → Hit · Correct: Stand"). Includes [Play Again] and [Home] actions.

### Rule Config & Presets
- **D-11:** Rule configuration is accessible from two places: (1) the pre-session start screen as part of session setup, and (2) a settings icon accessible during play for mid-session rule changes. Rules persist across sessions until changed.
- **D-12:** Ship with 1–2 standard presets + a "Custom" option. Minimal preset set — covers a typical starting point without bloat. Exact presets are Claude's discretion (e.g., a standard 6-deck S17 DAS game).
- **D-13:** Custom rule editing is presented as a SwiftUI Form in a sheet or push screen, showing all rule options as toggles and pickers (deck count, S17/H17, DAS, surrender, etc.). Standard iOS settings pattern.

### Claude's Discretion
- Exact animation duration/style for feedback flash (1 second is a reasonable target)
- Navigation structure (TabView vs NavigationStack vs sheet-based)
- App color scheme and typography details within "clean, premium, analytical" constraint
- Exact SwiftData model schema and relationship design for session persistence
- Xcode project setup: how BJSCore is linked as a local package dependency
- Exact preset names and rule configurations for the 1–2 built-in presets

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — Phase 2 requirements: STRAT-01 through STRAT-06 (trainer core), RULE-03 (casino presets), PROG-01 (SwiftData persistence), PROG-02 (per-session summary), ARCH-03 (offline), ARCH-04 (on-device only). The traceability table maps each requirement to its phase.

### Project principles and constraints
- `.planning/PROJECT.md` — Core value ("clean, premium, analytical" feel), constraints (offline-first, no backend, iPhone first), and key decisions table.
- `CLAUDE.md` — Tech stack: Swift 6.2, SwiftUI iOS 18+, MVVM + @Observable, SwiftData for persistence, Swift Testing for unit tests. Explicit non-recommendations (TCA, Combine, Realm, etc.).

### Domain layer (Phase 1 output)
- `BJSCore/Sources/BJSCore/` — The domain package Phase 2 imports. Key types for the trainer:
  - `StrategyEngine.strategy(for:)` → returns `StrategyTable` given `BlackjackRules`
  - `BlackjackHand` — total, isSoft, isPair, isBlackjack, canDouble/canSplit/canSurrender, hardIndex/softIndex/pairIndex
  - `Shoe` — deal(), shuffle(), needsReshuffle, decksRemaining
  - `BlackjackRules` — full rule model with all 10+ variations and S17/H17/DAS/surrender/etc.
  - `Action` — hit, stand, double, split, surrender

No other external specs — requirements fully captured in the files above and in the decisions section.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BJSCore` package (all types listed above) — the entire domain layer is ready. Phase 2 adds `import BJSCore` to the iOS app target.
- No existing UI code — Phase 2 creates the Xcode project and all views from scratch.

### Established Patterns
- From Phase 1: `StrategyEngine` is a class with a `strategy(for:) -> StrategyTable` method. The `StrategyTable` has `hardTotals`, `softTotals`, `pairs` arrays indexed by `BlackjackHand.hardIndex/softIndex/pairIndex` and dealer upcard column (0–9).
- No UI patterns yet — Phase 2 establishes the baseline MVVM + @Observable + SwiftUI patterns that all later phases will follow.

### Integration Points
- BJSCore is a local Swift Package at `./BJSCore/` — the Xcode project links it as a local package dependency.
- Phase 3 (Hi-Lo Practice) and Phase 4 (Edge Calculator) are independent of Phase 2 and will add new screens/tabs to the same app.

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-strategy-trainer*
*Context gathered: 2026-03-24*

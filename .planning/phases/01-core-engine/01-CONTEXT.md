# Phase 1: Core Engine - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Build `BJSCore` — a pure Swift package with zero SwiftUI imports containing all blackjack domain logic: `BlackjackRules` model, strategy engine, Hi-Lo counting engine, house edge calculator, full hand and shoe models, and a comprehensive test suite that validates correctness against Wizard of Odds before any UI is written.

This phase produces no UI. It is infrastructure only. Phase 2 builds the first UI on top of this package.

</domain>

<decisions>
## Implementation Decisions

### Package structure
- **D-01:** Single Swift Package with one `BJSCore` target and one `BJSCoreTests` test target. No sub-modules. All domain types are visible to each other within the package. Later phases `import BJSCore`.

### Strategy engine
- **D-02:** Rule-parameterized lookup tables. Strategy tables are generated (not hardcoded) from the active `BlackjackRules` configuration and cached by rules hash for O(1) lookup. This satisfies ARCH-02 (always derived from active rules, never pre-baked for a single ruleset) while enabling easy visual comparison against reference charts.
- **D-03:** Tables are generated lazily on first use for any `BlackjackRules` config, then cached. This handles arbitrary user-defined rule combinations, not just standard casino presets.
- **D-04:** Strategy table structure: `hardTotals: [[Action]]`, `softTotals: [[Action]]`, `pairs: [[Action]]` indexed by player total and dealer upcard.

### Hand and shoe model
- **D-05:** `BlackjackHand` is defined in Phase 1 as a full game hand model — includes cards, best non-busting total, soft/hard flag, pair flag, bust flag, and rule-aware eligibility flags (`canDouble`, `canSurrender`, `canSplit`). Phase 2 uses this type directly with no duplication.
- **D-06:** `Shoe` type (multi-deck card source with shuffle, deal, and penetration tracking) is defined in Phase 1. Phase 2, 3, and 6 all need it. One authoritative shoe type across the whole app.

### Validation approach
- **D-07:** Correctness is validated via coded Swift Testing test assertions with hardcoded expected values taken from Wizard of Odds. The test suite uses `@Test(arguments:)` parameterized tests over the specified rule combinations.
- **D-08:** The PLAN.md for the edge calculator task must explicitly list the 10+ rule combinations and their expected WoO values (house edge %, strategy decisions for key hands). The developer does not look these up — they are pre-specified in the plan.

### Claude's Discretion
- Exact `Action` enum cases (Hit / Stand / Double / Split / Surrender — standard set is fine)
- `Card` type representation (suit, rank, Hi-Lo value property)
- Internal generation algorithm for strategy tables (decision tree, formulas, or rule-application logic)
- Test file organization within `BJSCoreTests`

</decisions>

<specifics>
## Specific Ideas

- Strategy table caching keyed by `BlackjackRules` hash — the table for a given rule set is generated once and reused
- The `@Test(arguments:)` parameterized test pattern from Swift Testing is the preferred approach for the validation suite (validates all combos in one test function)
- Edge calculator tolerance: within 0.01% of WoO reference (from REQUIREMENTS.md EDGE-05)

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and architecture
- `.planning/REQUIREMENTS.md` — Full requirement list; Phase 1 covers RULE-01, RULE-02, ARCH-01, ARCH-02. The traceability table shows which requirements belong to which phase.
- `.planning/PROJECT.md` — Project principles, constraints, and key decisions table (offline-first, no backend, correctness as product differentiator)
- `CLAUDE.md` — Tech stack decisions: Swift 6.2, SwiftUI iOS 18+, MVVM + @Observable, Swift Testing for unit tests, SwiftData for persistence. The technology table lists explicit non-recommendations.

### External validation source
- Wizard of Odds Blackjack House Edge Calculator (external, no local path) — Authoritative reference for edge calculator validation and strategy chart cross-checking. The planner must specify 10+ rule combinations with their WoO expected values in the plan.

No other external specs exist — requirements are fully captured in the files above and in the decisions section.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, no existing code.

### Established Patterns
- None yet — this is Phase 1. Patterns established here propagate to later phases.

### Integration Points
- `BJSCore` package will be added as a local dependency in the main Xcode project. Phase 2 consumes it via `import BJSCore`.

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-core-engine*
*Context gathered: 2026-03-24*

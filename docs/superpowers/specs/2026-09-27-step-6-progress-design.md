# Step 6 — Progress — Design

**Date:** 2026-09-27
**Status:** Approved in brainstorming; pending written-spec review
**Parent spec:** `2026-09-23-bjs-rebuild-design.md` (§5 Progress tab, §6 data, §7 testing, §8 Step 6)

Step 6 builds the Progress tab: per-module headline numbers, a daily accuracy trend, the strategy heat map, and a session history whose rows open a read-only session detail (with WHY for strategy mistakes). This document records only what the parent spec leaves open or amends, plus the Step 6 carry-overs from `progress.md`. Everything else follows the parent spec as written.

The Felt design system is frozen. This step adds one new component built from existing tokens (`HeatMapGrid`), and it changes no existing token or component.

## 1. Decisions and amendments

| Topic | Decision | Why |
|---|---|---|
| Range toggle | One `ModePicker` at the top (7 days / 30 days / All time) sets the window for the headlines, the trend chart and the heat map. History always lists every session. | One rule for the whole screen. |
| Range definition (**clarifies** parent §5 "last 30 days") | An N-day window is today plus the previous N − 1 calendar days: `since = startOfDay(now) − (N − 1) days`. The hub's 30-day chips switch to the same helper, so the hub and Progress always agree. | The hub's rolling `now − 30 days` window includes part of a 31st day, which a per-day trend chart can't show. |
| Headlines | Four `StatChip`s, one per module: **Strategy** (strategy-module decisions), **Running count** (`countingRC` checks), **True count** (`countingTC` checks), **Shoe Sim** (decisions + checks combined). Each shows "—" with no data. Shoe stays "—" until Step 7. | Matches the parent spec's list. The hub keeps its cross-module chips (strategy + shoe decisions, all count checks) unchanged. |
| Trend chart | A `ModePicker` over the same four modules selects the series. The chart is one cream line with points, 0–100%, one point per day with attempts. | Felt has no categorical palette, and `brass` is reserved for highlights, so a multi-series chart would need new tokens. |
| Heat map | A `ModePicker` (Hard / Soft / Pairs) shows one grid at a time. The data is strategy + shoe decisions, **excluding Learn sessions** (`forStats: true`), within the range. | One grid fits the SE. The Learn exclusion closes a Step 3 carry-over. |
| Heat-map rows | Hard 5–20, soft 13–20, pairs 2–A, each against upcards 2–A. The **hard 4** and **soft 12** rows appear only when the range has at least one decision in them. | They're real graded cells (2,2 or A,A once split isn't legal) but rare. This closes the "ignores hard 4 / soft 12" carry-over without two nearly always empty rows. |
| History | Every session, Learn included (`forStats: false`), newest first. | Closes the Step 3 carry-over: history shows what the user did, stats show what counts. |
| Session detail | A read-only screen owned by Progress, rebuilt from saved records. Strategy mistakes open WHY. `WhySheet` moves from `Features/Strategy` to `Shared/`. No Again / Done. | Feature folders can't import each other, and the live summary views carry Again/Done and feature-only types. |
| WHY from history (closes the legal-actions carry-over) | **No schema change.** A new `WhyContext(cell:userAction:correctAction:rules:table:)` rebuilds the context from the saved cell, actions and rules. Legal actions are inferred: the chart's first preference for the cell was illegal when it differs from the saved correct action. One documented ambiguity is in §4. | The saved correct action already encodes what was legal in every case but one. A schema change would mean a `SchemaV2` migration for a single edge case. |
| RC trace in history (closes that carry-over) | Not shown. The per-card trace was never saved, and the detail says so in a footnote rather than faking one. | — |
| Empty state | With no sessions at all, the tab shows one message and a button that switches to the Train tab. With sessions but none in range, headlines show "—", the chart and heat map show their own empty captions, and History still lists everything. | — |

## 2. Screen

`ProgressView` sits in a `NavigationStack` on `FeltBackground`. It is one `ScrollView`, top to bottom:

1. **Title** "Progress" (`FeltType.display`) and the **range picker**.
2. **Headlines:** a 2 × 2 grid of `StatChip`s.
3. **Trend:** section label, module picker, then the Swift Charts chart (fixed height, about 180 pt).
   - Line and points in `cream`; axis labels in `textTertiary` (`FeltType.label`); gridlines in `surfaceInset`.
   - The y-axis is fixed at 0–100%. The x-axis spans the range; "All time" spans from the first day with data to today.
   - When the selected module has no points in range, the chart area shows "No sessions in this range" instead of an empty axis.
   - VoiceOver: the chart has a summary label, e.g. "Strategy accuracy, 7 days: 5 days, latest 84%". Each point is an element with its date and percentage.
4. **Heat map:** section label, Hard/Soft/Pairs picker, `HeatMapGrid`, legend, then the tap caption.
5. **History:** a `SettingsSection` of rows. Each row:
   - label: module plus mode where there is one ("Strategy · Test", "Strategy · Learn", "Running count", "True count · Exact");
   - secondary line: date and time, formatted with `.abbreviated` date and `.shortened` time;
   - value: that session's accuracy (decisions for Strategy, checks for counting, combined for Shoe), "—" when it has no graded items.
   - Rows push the session detail.

The view model reloads whenever `SessionStore.revision` or the range changes. So a session finished in the Train tab, or a Settings reset, shows up without relaunching.

### `HeatMapGrid` (new component, built from existing tokens)

- **Layout:** a leading column of row labels ("5"…"20", or "A,A", "2,2"…) and a header row of upcards (2…10, A), in `FeltType.label` / `textTertiary`. The columns share the width evenly: about 31 pt per cell on the SE, 28 pt tall, with 2 pt gaps.
- **Fills**, all from existing tokens:

  | State | Fill |
  |---|---|
  | Fewer than 3 samples ("not enough data") | No fill; 1 pt `surfaceInset` outline |
  | 0% errors | `correct` at 35% opacity |
  | > 0–15% errors | `incorrect` at 30% |
  | > 15–30% | `incorrect` at 50% |
  | > 30–50% | `incorrect` at 75% |
  | > 50% | `incorrect` at 100% |

  The opacities may be tuned once at the design check. After that they're part of the component and fixed.
- **Legend:** one row of swatches under the grid: "Not enough data · 0% · ≤15% · ≤30% · ≤50% · >50%".
- **Selection:** tapping a cell selects it with a 2 pt `cream` ring. The caption below the grid then reads e.g. "Hard 16 vs 10 · 3 of 7 wrong (43%)", or "Soft 18 vs 9 · 2 decisions, not enough data". Tapping it again clears the selection.
  - Cells are smaller than the 44 pt `FeltTapTarget.minimum`. That's accepted for a dense grid: the caption is an enhancement, and VoiceOver reaches every cell individually.
- **Accessibility:** each cell is an element labelled "Hard 16 vs 10", with the caption's text as its value.
- **Catalogue:** `FeltCatalogue` gets a "Progress components" section showing a grid with every fill state and a selected cell.

## 3. Session detail

`SessionDetailView` is pushed from a history row. It shows:

1. **Title:** the history row's label; subtitle: date and time.
2. **Captions:**
   - the rules summary (`RulesSummary.text`);
   - Learn sessions: "Learn mode · not counted in your stats";
   - TC sessions: the convention's rule line (the same text as `CountingText.conventionRule`).
3. **Stat chips.**
   - Strategy / Shoe: Accuracy, Mistakes, Best streak, Decisions, plus Avg decision when the session was Speed mode, as in the live summary.
   - Counting: Accuracy, Correct "n / m", Mean error. Seconds per card isn't shown: it needs the pace, which isn't saved.
4. **Strategy / Shoe:** a "Mistakes" section. Each row reads "Hard 16 vs 10" with the value "Stand → Hit" ("Time's up → Hit" for timeouts). Tapping a row opens `WhySheet` with the rebuilt context.
5. **Counting:** a "Checks" section, one row per check, in order.
   - RC: label "After card 12"; value "+4", or "+4 · you said +3" when wrong.
   - TC: label "Check 3"; value the saved target, or "+2.8 · you said +3" when wrong. The target is shown to one decimal when it isn't whole.
   - Footnote: "The card-by-card trace isn't kept after a drill ends."

If the session no longer exists (for example after a reset), the detail pops back to the list.

## 4. Engine (BJSCore)

All new logic is pure and tested with hand-built fixtures (parent §7).

- **`ProgressRange`** (`week`, `month`, `allTime`): `since(now:calendar:) -> Date?`, using the definition in §1. The hub adopts it.
- **Headlines and trend:** the existing `ProgressStats.headline` and `dailyTrend` with module sets `[.strategy]`, `[.countingRC]`, `[.countingTC]` and `[.shoe]`. The first three use the matching measure; Shoe uses `.combined`. There's no new API unless a fixture test shows one is needed.
- **Heat map:**
  - `ProgressStats.heatMap` is reused on decisions already filtered to the range.
  - New `HeatMapLayout.rows(for: HandType, cells: [TrainingCell: HeatCell]) -> [Int]`: the standard rows, plus hard 4 / soft 12 when present.
  - New `HeatBin` (`insufficient`, `none`, `low`, `medium`, `high`, `severe`) with `init(_ cell: HeatCell?)`. The bin edges are in §2. A rate exactly on an edge belongs to the lower bin.
- **`WhyContext(cell:userAction:correctAction:rules:table:)`** rebuilds WHY from saved data:
  - hand type, total and pair rank come from the cell; upcard 11 maps to ace;
  - `userAction` is nil for a timeout;
  - `surrenderContext` comes from the rules, as today;
  - `preferredIllegal` is the table's first preference for the cell when it differs from `correctAction`, otherwise nil.
  - **The ambiguous case:** the early-surrender composition note (hard 14 vs a ten, 1–2 decks, `hard14VsTenSurrenders` set) when the saved correct action isn't surrender and the chart's first preference is surrender. A two-card 10+4 (surrender legal, note applies) and a three-card 14 (surrender illegal) save identical records. The rebuild sets `compositionNote = true` and `preferredIllegal = nil`. That is exactly right for the two-card case. For the three-card case it explains the composition rule instead of "surrender isn't allowed here", which is still true.
  - When the saved correct action is surrender and the note applies, `compositionNote = true`.
  - **Property test:** for seeded random decision spots across every rule preset, `WhyContext(cell:…)` equals `WhyContext(spot:…)`, ignoring `id`. The only exception is the ambiguous case, which has its own test.
  - If the property test finds any other mismatch (for example the unsplittable soft-12 special case), the implementer fixes the rebuild where the saved data allows. Otherwise they document it in this section and flag it in the handoff.

## 5. App layer

- **`SessionStore`** additions:
  - `historyEntries() throws -> [HistoryEntry]`: sessions only (no records), `forStats: false`, newest first. `HistoryEntry` is a small app-side value: the session's `SessionSample` plus its `mode`, which `SessionSample` doesn't carry.
  - `decisionSamples(…, since: Date?)`: the date filter runs in the fetch with `#Predicate` if it compiles in main-actor code (probe first, per the Step 3 note), otherwise in memory. `sessionSamples` gets the same `since`. This addresses "fetches read whole tables" for the ranged views. "All time" still reads everything, which is fine at v1 volumes.
  - `sessionDetail(id: UUID) throws -> SessionDetail?`: one session with its decision and count-check records, sorted by `sequence`. `SessionDetail` is an app-side value holding mode, rules, the summary fields and the records mapped to plain structs (`chosen: RecordedChoice`, `correctAction: Action`, `cell`, `responseMs`; count checks as `CountSample` plus `cardsSeen`). Rows with unknown raw values are dropped and logged, as today.
- **`ProgressViewModel`** (`@Observable`, `@MainActor`, thin):
  - inputs: range, trend module, heat-map hand type, selected cell;
  - `reload(store:now:calendar:)` fetches and calls `ProgressStats` / `HeatMapLayout` / `HeatBin`, then maps the results to display values: chip strings, chart points, grid rows of `(label, [cell display])`, caption, history rows;
  - a fetch error sets a "Couldn't load your progress" caption and logs; it never crashes.
- **`SessionDetailViewModel`:** maps a `SessionDetail` to chips, mistake rows (each with a rebuilt `WhyContext` from `StrategyTable` for the session's rules) and check rows.
- **Moves to `Shared/`** (no behaviour change; Strategy and Counting call the moved code):
  - `WhySheet`;
  - `StrategyText.actionName`, `upcardName` and `handLabel`, as `TrainingText`;
  - `CountingText.signed` (both overloads) and `minus`;
  - `CountingText.conventionRule`.
- **`RootTabView`:** the Progress tab hosts `ProgressView` in place of `ComingSoonView`.
- **Fixture:** a DEBUG, `-uiTesting`-only `-progressFixture` launch argument seeds a deterministic history through `SessionStore.save`, with dates relative to launch:
  - Strategy Test sessions over about 10 days with mistakes (including a timeout);
  - one Learn session;
  - an RC drill and a TC drill (Exact) with a wrong check each;
  - enough decisions in some cells to colour every heat bin, with hard 16 vs 10 reliably "severe";
  - at least one hard 4 decision.

  The UI test and the design-check screenshots use it.

## 6. Testing

- **BJSCore** (Swift Testing, TDD):
  - `ProgressRange` boundaries, including the calendar-day rule across midnight;
  - `HeatBin` at every edge;
  - `HeatMapLayout` with and without hard 4 / soft 12 data;
  - `WhyContext(cell:…)`: the property test plus the ambiguous-case test;
  - per-module headline and trend fixtures with known answers (Learn excluded, Shoe combined).
- **App** (Swift Testing, in-memory store):
  - `SessionStore`: `historyEntries` includes Learn, orders newest first and carries mode; `since` filters decisions and sessions; `sessionDetail` returns records in order and nil for an unknown id.
  - `ProgressViewModel`: chip strings; range switching; reloading on revision; the empty state vs the none-in-range state; heat-map rows; the caption.
  - `SessionDetailViewModel`: strategy mistakes, including a timeout; RC and TC check rows; Learn and TC captions.
  - The hub uses `ProgressRange` (existing hub tests updated only where the window edge moves).
- **UI test** (`ProgressUITests`): launch with `-uiTesting -progressFixture -startTab progress` → headline chips visible → switch range → open a strategy session → open a mistake's WHY → close it.
- **Existing suites** stay green: BJSCore 249, app 201 unit + 4 UI tests, with no new warnings.
- **Design check** on iPhone 16 (18.4) and SE 3rd gen (18.3.1) using the fixture:
  - top of screen;
  - trend for each module;
  - the heat map on each tab, with a selected cell;
  - history;
  - strategy and TC detail;
  - WHY from history;
  - the empty state;
  - `FeltCatalogue`'s new section.

  `FeltColorTests` must pass. This is a conformance check: only Felt tokens, no brass, and nothing truncated on the SE.

**Done when:** the fixtures render correctly (parent §8), all tests above are green, and the design check passes.

## 7. Out of scope

- Deleting individual sessions (Settings' Reset progress covers deletion).
- Export or sharing.
- Shoe Sim data, which arrives in Step 7. This step only reserves the Shoe chip and trend option.
- Per-kind count accuracy across Shoe Sim sessions.
- Any change to frozen tokens or components.
- The open Step 5 decision on Edge breakdown bar scaling.

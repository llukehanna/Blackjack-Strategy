# Step 2 — Foundation — Design

**Date:** 2026-09-24
**Status:** Approved in brainstorming; pending written-spec review
**Parent spec:** `2026-09-23-bjs-rebuild-design.md` (§4 design system, §5 hub/settings, §6 data, §8 Step 2)

Step 2 builds the Felt design system and component kit, the app shell and hub, Settings, the app-wide stores, and SwiftData `SchemaV1`. It ends with Luke's design sign-off, after which Felt is **frozen** (parent spec §4).

This document records only what the parent spec leaves open or amends, plus the carry-overs from `progress.md` (Step 1 and WoO strategy entries). Everything else follows the parent spec as written.

## 1. Amendments to the parent spec

| Parent spec | Amendment | Why |
|---|---|---|
| §4 `FeltBackground`: radial `feltLight` → `feltBase` → `feltDeep` | `feltLight` is layered at **45% opacity** over `feltBase`, giving an effective centre of `#184836`. The `feltLight` token value is unchanged. | At full strength, `textSecondary` (4.33), `textTertiary` (3.51) and `brass` (4.08) fail WCAG AA on the glow centre. At 45% they pass (5.58, 4.53, 5.26). |
| §4 contrast requirement: text on `feltBase` or `cream` | Text tokens are tested against `feltBase`, the glow centre `#184836`, and `surfaceInset` over `feltBase`. | Text sits on all three. |
| §4 `FeedbackCard` badge colours | `correct` / `incorrect` are **never text on cream** (1.48:1 / 2.68:1). Headlines on the card use `onCream`. The badge is a filled `correct`/`incorrect` disc with a `feltDeep` glyph. On felt, `correct`/`incorrect` are large text only (≥ 17 pt semibold; 3:1) or glyphs. | `incorrect` is 3.72:1 on the glow centre. |
| §4 `CountKeypad`: numeric keypad with ± | Keys: 0–9, `±`, `.5`, delete, enter. | The Exact true-count convention has half-integer answers (Step 1 carry-over). |
| §6 `DecisionRecord` | Adds `sequence: Int` (order within session) and `decidedAt: Date`. | Streak and weak-spot windows need a per-decision order (Step 1 carry-over). |
| §6 `CountCheckRecord` | Adds `sequence: Int` and `checkedAt: Date`. | Same ordering need for count samples. |

## 2. Design system (`BJS/Design/`)

- `Tokens/`: `FeltColor`, `FeltType`, `FeltSpacing`, `FeltRadius`, `FeltMotion`, with values from parent spec §4.
- `Components/`: one file each for `FeltBackground`, `PlayingCard`, `HandView`, `ActionDock`, `FeedbackCard`, `StatChip`, `ModuleTile`, `PrimaryButton`, `SecondaryButton`, `ModePicker`, `SettingsRow` and `CountKeypad`.
- `PlayingCard` suits use SF Symbols (`suit.heart.fill` and so on). Height = width × 1.4. The VoiceOver label is derived from `Card` (e.g. "Eight of clubs").
- `ActionDock` state per action: enabled, dimmed (not legal) or hint (brass ring). The state mapping is a pure function of (legal actions, hinted action), and every tap target is at least 44 pt.
- `CountKeypad` input logic lives in a pure `CountEntry` value type: digits, sign toggle, `.5` toggle, delete and value. The view only renders it.
- `FeltMotion` exposes helpers that swap deal and flip animations for cross-fades under Reduce Motion.
- **`FeltCatalogue`** (`#if DEBUG`) shows every colour token with its measured contrast ratios, every type role, and every component in every state: dock enabled/dimmed/hint, feedback ✓/✕, keypad, card face and back, hand with total, chips, tiles, buttons, mode picker and settings rows. It is reached from a DEBUG-only Settings row and stays in DEBUG builds as the reference for later steps.

## 3. App shell and hub

- `BJSApp` builds the `ModelContainer` (SchemaV1). It creates `ActiveRulesStore`, `PreferencesStore`, `SessionStore` and `AppRouter`, and injects them via `.environment`.
- `AppRouter` (`Shared/`, `@Observable`) owns the selected `AppTab`.
- `RootTabView`: Train · Progress · Settings on `FeltBackground`, with a `feltDeep` tab bar. Progress is a placeholder until Step 6.
- **Hub (`Features/Hub`)**:
  - The rules summary header is formatted by `RulesSummary` (`Shared/`), e.g. `6D · H17 · DAS · 3:2`. Tapping it sets `AppRouter` to Settings.
  - Stat chips:
    - strategy accuracy = `ProgressStats.headline(.decisions)` over strategy + shoe sessions, last 30 days;
    - count accuracy = `.countChecks` over countingRC + countingTC + shoe, last 30 days;
    - streak = `ProgressStats.currentStreak` over strategy + shoe decisions.
    A chip with no data shows "—".
  - Continue (`PrimaryButton`) appears only when `lastLaunch` is set, so never in Step 2.
  - Tiles: Strategy, Counting, Shoe Sim, Edge. Each opens a full-screen placeholder ("Strategy — coming in Step 3") with a close button.
  - `HubViewModel` maps samples to chip strings.

## 4. Settings (`Features/Settings`)

- **Table rules**:
  - A preset picker (`RulePreset.allCases`, "Custom" when `RulePreset.matching` is nil).
  - Then every `BlackjackRules` field: decks 1/2/4/6/8, dealer soft 17, blackjack payout, DAS, double restriction, max split hands (stepper **2…4**), resplit aces, hit split aces, surrender none/late/early, and peek rule (American peek / No hole card).
  - Surrender offers all three options under either peek rule. Under no hole card, a footnote says late and early play the same.
  - The form is `RulesForm(rules: Binding<BlackjackRules>)` in `Shared/`, so the Edge screen (Step 5) can reuse it without importing Settings. Display names live in `RuleLabels` (`Shared/`).
- **Preferences**:

  | Preference | Range | Default |
  |---|---|---|
  | Speed timer | 1.0–5.0 s, 0.5 s steps | 3.0 s |
  | True-count convention | Exact / Floor / Truncate | Exact |
  | Shoe Sim count check every N rounds | 2–8 | 4 |
  | Haptics | on / off | on |

- **Reset progress**: a destructive row with a confirmation dialog. It calls `SessionStore.deleteAll()` and keeps rules and preferences.
- **About**: app version and "Strategy by WizardOfOdds.com".
- **DEBUG only**: a "Felt catalogue" row.

## 5. Stores and persistence

- **`ActiveRulesStore`** (`Shared/`, `@Observable`) takes an injected `UserDefaults`. `rules` is persisted as JSON under `activeRules`. If decoding fails, it falls back to `BlackjackRules()` and logs via `os.Logger`. Every set writes through.
- **`PreferencesStore`** (`Shared/`, `@Observable`) takes an injected `UserDefaults`. It uses the keys `speedTimerSeconds`, `trueCountConvention`, `shoeCheckFrequency`, `hapticsEnabled` and `lastLaunch`. Values are clamped to the ranges in this document's §4 on read and write. `lastLaunch` is `LastLaunch { module: TrainingModule, mode: String?, setup: Data }`; each feature encodes its own `setup` from Step 3 on.
- **SwiftData (`Persistence/`)**:
  - `SchemaV1: VersionedSchema` with `Session`, `DecisionRecord` and `CountCheckRecord` per parent §6 plus the §1 additions. `BJSMigrationPlan` has no stages yet.
  - Enums are stored as raw strings. Mappers turn records into `SessionSample`, `DecisionSample` and `CountSample`. A row with an unknown raw value is dropped and logged, never a crash.
- **`SessionStore`** (`Persistence/`) wraps a `ModelContext`:
  - `save(_ draft: SessionDraft) throws`. `SessionDraft` is a plain value holding rules, module, mode, timing, decisions and count checks. The store computes the cached summary fields: counts, best streak, mean response.
  - `sessionSamples()`, `decisionSamples()` and `countSamples()` return chronological order: by timestamp, then `sequence`.
  - `deleteAll() throws`.
  - Failures are thrown. Callers show a non-blocking alert.

## 6. Testing

Swift Testing for unit tests, XCTest for UI tests. Logic is written TDD.

- **Design**:
  - token hex values locked;
  - contrast ratios for every §1 pairing;
  - `PlayingCard` label and aspect;
  - `ActionDock` state mapping;
  - `CountEntry` (digits, sign, `.5`, delete, value).
- **Shared**:
  - `RulesSummary` across all presets and edge cases (ENHC, surrender, 6:5, no DAS);
  - `RuleLabels` covers every enum case;
  - `maxSplitHands` clamps to 2…4;
  - preset matching / "Custom".
- **Stores**:
  - corrupt `activeRules` JSON falls back to defaults;
  - round-trips through a throwaway `UserDefaults` suite;
  - preference clamping and defaults.
- **Persistence** (in-memory container):
  - save/fetch round-trip;
  - cached summary fields;
  - chronological order with tied timestamps;
  - cascade delete;
  - `deleteAll`;
  - unknown raw values are dropped.
- **Hub**: `HubViewModel` chip strings for empty and fixture data.
- **UI test** (new `BJSUITests` target in `project.yml`): launch → Settings → pick a preset → back to Train → the header shows that preset's summary.

## 7. Done when

1. `cd BJSCore && swift test` is green (208+ tests).
2. App unit and UI tests are green.
3. Screenshots of `FeltCatalogue`, hub and Settings on iPhone 16 and iPhone SE (3rd gen) are published as one private review page, and Luke signs off. Fixes found in review are made before sign-off.
4. `progress.md` records the Step 2 handoff and states that Felt is frozen.

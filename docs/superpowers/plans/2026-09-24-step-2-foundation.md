# Step 2: Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the app foundation every later step stands on: the Felt design system (tokens + the full §4 component kit), the three-tab shell with a hub whose tiles route to placeholders, the Settings tab, `ActiveRulesStore` + `Preferences`, SwiftData `SchemaV1` with mappers to the BJSCore sample types, the WCAG contrast test, and the §7 design check (CI screenshots on iPhone 16 and iPhone SE (3rd generation)). Done when the design check passes and Luke approves the freeze.

**Architecture:** All game logic stays in `BJSCore` (untouched in this step). The app gains:
- `BJS/Design/` — tokens (`FeltPalette`, `FeltColor`, `FeltType`, `FeltSpacing`/`FeltRadius`/`FeltMetrics`/`FeltMotion`, `WCAGContrast`) and components; a DEBUG-only component gallery;
- `BJS/Shared/` — `ActiveRulesStore`, `Preferences`, rules JSON coding and display text, `AppLog`;
- `BJS/Persistence/` — `SchemaV1` (`Session`, `DecisionRecord`, `CountCheckRecord`), `BJSMigrationPlan`, container factory, `ProgressMapper`, `ProgressReset`;
- `BJS/Features/Hub/` and `BJS/Features/Settings/`;
- `BJS/App/` — `BJSApp`, `RootTabView` (the composition root that decides what each hub route shows), `LaunchConfiguration`, `PlaceholderScreen`;
- `BJSUITests/` — XCTest UI test that walks the app and attaches screenshots; CI exports and uploads them.

**Tech Stack:** Swift 6.2 (language mode 6, `SWIFT_STRICT_CONCURRENCY: complete`), SwiftUI + Observation + SwiftData (iOS 18+), Swift Testing for unit tests, XCTest for UI tests, XcodeGen, GitHub Actions (`macos-26`, Xcode 26).

**Spec:** `docs/superpowers/specs/2026-09-23-bjs-rebuild-design.md`. Read §3 (Architecture), §4 (Felt), §5 (Navigation, Hub, Settings), §6 (Data), §7 (Testing) and the §8 Step 2 row before starting any task. Read the Step 1 entry in `docs/superpowers/progress.md`.

## Global Constraints

- **The app can only be built in CI.** The dev container is Linux: BJSCore builds and tests locally, but the app target (SwiftUI, SwiftData, Observation on Apple, os.Logger) builds only in `.github/workflows/ios.yml` (macos-26, Xcode 26, runs on every push to `main-8v0ds1`, ~6 min). Every app task therefore ends with:
  1. local pre-checks (below);
  2. **the implementer commits and reports the SHA — it does not push**;
  3. **the controller pushes and checks the CI run** (Step "CI verification (controller)"). If CI fails, the controller hands the failing log lines back to the implementer, who fixes forward in a new commit (`fix(app): …`) until the run is green. Do not start the next task on a red run.
- **Local pre-checks** (run from the repo root; `export PATH=/opt/swiftroot/usr/bin:$PATH` first):
  - Engine still green: `(cd BJSCore && swift build 2>&1 | tail -1 && swift test 2>&1 | tail -1)` → the build line and `Test run with 173 tests … passed`. BJSCore is not changed in this step, so the count stays 173.
  - Syntax of every Swift file you touched: `swiftc -parse <files>` → no output. (`-parse` needs no SDK, so it works on SwiftUI files.)
  - Type-check files that import only Foundation/BJSCore: `swiftc -typecheck -I BJSCore/.build/debug/Modules <files>` → no output. The task says which files qualify.
- **Default actor isolation — decision:** remove `OTHER_SWIFT_FLAGS: "-enable-upcoming-feature DefaultIsolationMainActor"` from `project.yml` and do **not** add `SWIFT_DEFAULT_ACTOR_ISOLATION`. Reasons: (1) `DefaultIsolationMainActor` is not an upcoming-feature flag; Swift 6.2's default isolation is SE-0466's `-default-isolation MainActor` / Xcode's `SWIFT_DEFAULT_ACTOR_ISOLATION`, so the flag is a no-op at best (Step 1 open item); (2) spec §3 rule 2 already asks for explicit `@MainActor` on ViewModels and stores, which keeps isolation visible in code review; (3) nonisolated-by-default keeps SwiftData `@Model` classes, `VersionedSchema`/`SchemaMigrationPlan` witnesses, `Shape.path(in:)` and pure value types free of accidental main-actor isolation. Code rules that make the code correct **either way** (verified with `swiftc -swift-version 6` in both modes on the pure files):
  - `@Observable` stores are `@MainActor final class`; their static constants that must be read from anywhere are `nonisolated static let`.
  - Protocol witnesses whose requirements are nonisolated are marked `nonisolated` (`SchemaV1.versionIdentifier`/`models`, `BJSMigrationPlan.schemas`/`stages`, `DiagonalStripes.path(in:)`).
  - Test suites that touch `@MainActor` types are `@MainActor`.
- **SwiftUI initialiser rule:** a struct with a `private` stored property that has a default value (including `@State private var x = …`) gets a *private* memberwise initialiser. Every view that takes parameters and has such a property declares an explicit `init`. The code below already does this; keep it that way.
- **Architecture:** `Features/Hub` and `Features/Settings` never reference each other or any other feature. `App/RootTabView` is the only place that maps hub routes and tabs to screens. Shared code lives in `Design/`, `Shared/`, `Persistence/` or `BJSCore`. `BJSCore` is not modified in this step.
- **XcodeGen owns the project.** Edit `project.yml` only. New folders under `BJS/` are picked up by `sources: [BJS]`.
- **Tests:** Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`) in `BJSTests`; XCTest only in `BJSUITests`. Tests never touch `UserDefaults.standard` (use `TestDefaults.make()`) or an on-disk store (use `PersistenceController.makeContainer(inMemory: true)`, and create the container before creating any `@Model` object).
- **Accessibility (spec §4):** tap targets ≥ 44 pt; fonts only via `FeltType` roles (Dynamic Type); `PlayingCard` VoiceOver label "Eight of clubs"; movement replaced by cross-fades under Reduce Motion.
- **No restyling beyond §4, no Step 3+ features.** Tiles route to placeholders; there is no Continue button, no `lastLaunch` key, no session UI. YAGNI.
- **Commits:** one per task (plus fix-forward commits), conventional prefix with scope. Every message ends with a blank line and then these two lines (use the model actually doing the work in the first line):
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi
  ```
- **Branch:** `main-8v0ds1`. Stay on it.

## Decisions this plan makes (spec gaps or ambiguities)

Luke reviews these at the design check (Task 12). None changes a §4 token value.

1. **`@AppStorage` vs `@Observable`.** `@AppStorage` only works inside a View and cannot sit inside an `@Observable` class. `ActiveRulesStore` and `Preferences` therefore read and write `UserDefaults` directly, under the spec's key names and with `@AppStorage`-compatible types (`activeRules`: JSON `Data`; `speedTimerSeconds`: Double; `trueCountConvention`: String raw value; `shoeCheckFrequency`: Int; `hapticsEnabled`: Bool). The `UserDefaults` instance is injected, so tests and UI tests use their own suites.
2. **`Session.countChecks` name clash.** §6 lists `countChecks` both as a cached `Int` and as a relationship. The Int keeps the name (it matches `SessionSample.countChecks`); the relationship is `countCheckRecords`. `decisions` stays as named.
3. **Unspecified field types.** `CountCheckRecord.responseMs` is `Int?` (matches `CountSample.responseMs`); `cardsSeen` is `Int`; `Session.endedAt` is non-optional (sessions persist only when they end or are saved partially). `DecisionRecord.playerValue`/`dealerUpcard` use the `TrainingCell` convention (ace = 11).
4. **Hub stat chips.** "Strategy accuracy (30 days)" = graded decisions from Strategy **and** Shoe Sim sessions; "count accuracy (30 days)" = count checks from Counting RC, Counting TC **and** Shoe Sim; the streak runs over every stored decision, newest first. 30 days = 30 calendar days back from now.
5. **Hub rules summary.** Always `decks · S17/H17 · DAS/NDAS · payout`, plus `LS`/`ES` when surrender is offered and `ENHC` for no-hole-card games (e.g. `2D · H17 · DAS · 3:2 · LS`).
6. **Continue button and `lastLaunch`.** Deferred to Step 3. On first launch the button is hidden anyway, and nothing can be continued until a module exists.
7. **Routing.** Hub tiles push placeholder screens on the hub's `NavigationStack` (setup screens will be pushed; sessions will later be presented full-screen per §5). The Progress tab is a placeholder until Step 6.
8. **Preference ranges.** Speed timer options 1.0–5.0 s in 0.5 s steps (default 3.0). Shoe Sim check frequency is stored as "about once every N rounds", options 2, 3, 4, 6, 8 (default 4).
9. **`CountKeypad` ships its decimal key now** (`allowsDecimal`, off by default) and its own display line. Step 4 needs ±0.25 true-count answers (Step 1 open item); adding the key later would modify a frozen component.
10. **Reset confirmation** is an `.alert` with a destructive "Delete all progress" button (spec: "confirmation dialog"); alerts are the most predictable choice on iOS 26 and in UI tests.
11. **§4 details the spec leaves open** (all built from existing tokens): FeedbackCard WHY = `onCream` outline, NEXT = `onCream` fill with cream text; badge 44 pt disc with a 3 pt cream ring; hint ring 3 pt `brass`; secondary buttons and keys get a 1 pt `textTertiary` outline; row hairlines are `textTertiary` at 30 %, one pixel; toggles tint cream (like the selected ModePicker segment); dimmed/disabled = 40 % opacity; pressed = 85 % opacity and 97 % scale (no scale under Reduce Motion); deal uses ease-out, flip ease-in-out; the felt's radial centre sits at (0.5, 0.35) with radius 0.75 × the longer side; card index = 30 % of width, corner suit 20 %, big suit 45 %.
12. **Where the contrast maths lives.** `WCAGContrast` and the raw `FeltPalette` values are Foundation-only files in `BJS/Design/Tokens/`, not BJSCore (they are not game logic). Because they are Foundation-only, the contrast numbers are also computed locally with `swiftc` in Task 1; the unit test in `BJSTests` asserts them against the shipped tokens.
13. **Contrast findings (for Luke).** Every text token passes AA on `feltBase` (lowest: `incorrect` 4.51) and on `surfaceInset` over `feltBase`; `onCream`, `onCreamSecondary` (5.85), `suitRed` (4.54) and `suitBlack` pass on cream. `correct` (1.48), `incorrect` (2.68) and `brass` (1.89) fail on cream, so they are never used as text on cream (badge fills only). At the radial centre (`feltLight`), `textTertiary` (3.51) and `incorrect` (2.89) drop below 4.5:1; the spec only requires `feltBase`, so this is reported, not changed.
14. **UI tests run on every push.** They double as the design-check screenshot run (~3–5 extra minutes per run).

---

## File map

**Created:**

| File | Responsibility |
|---|---|
| `BJS/Design/Tokens/FeltPalette.swift` | `RGBColor`, raw §4 colour values, `surfaceInset(over:)` |
| `BJS/Design/Tokens/WCAGContrast.swift` | Relative luminance and contrast ratio |
| `BJS/Design/Tokens/FeltColor.swift` | SwiftUI colour tokens, `Color(felt:)` |
| `BJS/Design/Tokens/FeltType.swift` | Type roles on Dynamic Type styles, `.feltType(_:)` |
| `BJS/Design/Tokens/FeltLayout.swift` | `FeltSpacing`, `FeltRadius`, `FeltMetrics`, `FeltMotion` |
| `BJS/Design/Components/FeltBackground.swift` | Radial felt, `.feltBackground()` |
| `BJS/Design/Components/CardText.swift` | Card index/name/VoiceOver text, suit symbols |
| `BJS/Design/Components/PlayingCard.swift` | Drawn card face/back, flip; `DiagonalStripes` |
| `BJS/Design/Components/HandView.swift` | Overlapping cards + total |
| `BJS/Design/Components/FeltButtonStyle.swift` | `FeltButtonStyle`, `FeltPressableStyle`, `PrimaryButton`, `SecondaryButton` |
| `BJS/Design/Components/ActionDock.swift` | Two-row action dock with enabled/dimmed/hint |
| `BJS/Design/Components/FeedbackCard.swift` | Cream feedback card with straddling badge |
| `BJS/Design/Components/StatChip.swift` | Label + mono stat |
| `BJS/Design/Components/ModuleTile.swift` | Tappable title + subtitle tile |
| `BJS/Design/Components/ModePicker.swift` | Segmented control |
| `BJS/Design/Components/SettingsRow.swift` | `SettingsRow` (value/toggle/picker/custom), `SettingsSection` |
| `BJS/Design/Components/CountEntry.swift` | Keypad input model |
| `BJS/Design/Components/CountKeypad.swift` | Numeric keypad with ± (and optional decimal) |
| `BJS/Design/Gallery/ComponentGallery.swift` | DEBUG-only gallery pages for the design check |
| `BJS/Shared/AppLog.swift` | `os.Logger`s |
| `BJS/Shared/RulesCoding.swift` | `BlackjackRules` ⇄ JSON |
| `BJS/Shared/RulesDisplay.swift` | Display names, hub rules summary |
| `BJS/Shared/ActiveRulesStore.swift` | App-wide active rules |
| `BJS/Shared/Preferences.swift` | Timer, TC convention, shoe check frequency, haptics |
| `BJS/Persistence/SchemaV1.swift` | `SchemaV1` models, typealiases, `BJSMigrationPlan` |
| `BJS/Persistence/PersistenceController.swift` | `ModelContainer` factory |
| `BJS/Persistence/ProgressMapper.swift` | Records → `SessionSample`/`DecisionSample`/`CountSample` |
| `BJS/Persistence/ProgressReset.swift` | Delete all progress |
| `BJS/Features/Hub/HubRoute.swift` | Hub tiles |
| `BJS/Features/Hub/HubStats.swift` | Stat-chip numbers |
| `BJS/Features/Hub/HubView.swift` | Train tab |
| `BJS/Features/Settings/SettingsView.swift` | Settings tab |
| `BJS/App/LaunchConfiguration.swift` | UI-testing and gallery launch switches |
| `BJS/App/PlaceholderScreen.swift` | Stand-in screen |
| `BJSTests/ContrastTests.swift`, `FeltTokenTests.swift`, `CardTextTests.swift`, `ActionDockTests.swift`, `CountEntryTests.swift`, `TestDefaults.swift`, `ActiveRulesStoreTests.swift`, `PreferencesTests.swift`, `PersistenceTests.swift`, `HubStatsTests.swift` | Unit tests |
| `BJSUITests/DesignScreenshotTests.swift` | UI walk + screenshots |
| `scripts/ci/ensure_simulator.py` | Find/create the design-check simulators |
| `scripts/ci/design_screenshots.sh` | Run UI tests on one simulator |
| `scripts/ci/export_screenshots.py` | Pull PNGs out of an `.xcresult` |

**Modified:** `project.yml` (Task 1: drop the isolation flag; Task 10: `BJSUITests` target), `BJS/App/BJSApp.swift` (Tasks 8, 10), `BJS/App/RootTabView.swift` (Tasks 8, 9), `BJSTests/AppShellTests.swift` (Task 8), `.github/workflows/ios.yml` (Task 11), `docs/superpowers/progress.md` (Task 12).

**Task order and CI:** each task is one commit verified by one CI run. Unit-test count after each task (Swift Testing prints `Test run with N tests … passed`): T1 12 · T2 16 · T3 21 · T4 21 · T5 29 · T6 42 · T7 51 · T8 59 · T9 59 · T10+ 59 unit + 2 UI.

---

### CI verification (controller) — the same procedure closes every app task

Referenced below as **"CI verification"**. The controller (not the implementer) does this:

1. `git push origin main-8v0ds1`
2. Find the run for the pushed SHA: GitHub MCP `actions_list` (workflow `ios.yml`, branch `main-8v0ds1`), or `gh run list --branch main-8v0ds1 --limit 1` where `gh` is installed. Wait for it to finish (~6–10 min).
3. Expected: the run is green. "Engine tests (BJSCore)" ends with `Test run with 173 tests … passed`. The app test step ends with `** TEST SUCCEEDED **` (Tasks 1–10) or `** TEST EXECUTE SUCCEEDED **` (Task 11 onwards) and reports the task's unit-test count from the table above.
4. If red: fetch the failing job log (GitHub MCP `get_job_logs`, or `gh run view --log-failed`), give the error lines to the implementer, and repeat from 1 after their fix commit.

---

# STEP 2 — FOUNDATION

### Task 1: Felt tokens, contrast maths, and the isolation-flag cleanup

**Files:**
- Modify: `project.yml` (remove `OTHER_SWIFT_FLAGS`)
- Create: `BJS/Design/Tokens/FeltPalette.swift`, `WCAGContrast.swift`, `FeltColor.swift`, `FeltType.swift`, `FeltLayout.swift`
- Test: `BJSTests/ContrastTests.swift`, `BJSTests/FeltTokenTests.swift`

**Interfaces:**
- Produces:
  - `struct RGBColor: Equatable, Sendable { init(hex: UInt32); init(red:green:blue:); func composited(over:opacity:) -> RGBColor }`
  - `enum FeltPalette` — one `static let` per §4 colour + `surfaceInsetOpacity` + `surfaceInset(over:)`
  - `enum WCAGContrast { static func relativeLuminance(_:) -> Double; static func ratio(_:_:) -> Double; bodyMinimum = 4.5; largeTextMinimum = 3.0 }`
  - `enum FeltColor` — SwiftUI `Color` per token; `Color(felt: RGBColor)`
  - `enum FeltType: CaseIterable { display, title, body, label, stat }` with `textStyle`, `weight`, `design`, `nominalPointSize`, `isUppercased`, `font`; `View.feltType(_:)`
  - `FeltSpacing` (`xs s m l xl xxl`, `scale`), `FeltRadius` (`chip tile button card sheet`), `FeltMetrics` (`minTapTarget`, `cardAspectRatio`), `FeltMotion` (`uiDuration dealDuration flipDuration`, `ui deal flip`, `crossFade(duration:)`, `dealTransition(reduceMotion:)`, `panelTransition(reduceMotion:)`)

- [ ] **Step 1: Remove the no-op isolation flag**

In `project.yml`, delete this line (and nothing else) from `settings: base:`:

```yaml
    OTHER_SWIFT_FLAGS: "-enable-upcoming-feature DefaultIsolationMainActor"
```

The block becomes:

```yaml
settings:
  base:
    SWIFT_VERSION: "6.2"
    SWIFT_STRICT_CONCURRENCY: complete
```

- [ ] **Step 2: Write the tests**

The app target cannot build locally, so the red phase for these tests happens in CI; Step 4 runs the same contrast numbers locally first.

Create `BJSTests/ContrastTests.swift`:

```swift
import Testing
@testable import BJS

/// Spec §4: text tokens used on `feltBase` or `cream` meet WCAG AA
/// (4.5:1 body, 3:1 for ≥ 17 pt semibold and UI glyphs). Values come from `FeltPalette`,
/// the same values `FeltColor` ships.
@Suite("Felt contrast (WCAG AA)")
struct ContrastTests {

    struct Pair: Sendable, CustomTestStringConvertible {
        let name: String
        let foreground: RGBColor
        let background: RGBColor
        var testDescription: String { name }
    }

    static let feltBase = FeltPalette.feltBase
    static let inset = FeltPalette.surfaceInset(over: FeltPalette.feltBase)
    static let cream = FeltPalette.cream

    /// Text drawn on the felt and on inset surfaces (chips, tiles, rows, secondary buttons).
    static let bodyPairs: [Pair] = [
        Pair(name: "textPrimary on feltBase", foreground: FeltPalette.textPrimary, background: feltBase),
        Pair(name: "textSecondary on feltBase", foreground: FeltPalette.textSecondary, background: feltBase),
        Pair(name: "textTertiary on feltBase", foreground: FeltPalette.textTertiary, background: feltBase),
        Pair(name: "cream on feltBase", foreground: FeltPalette.cream, background: feltBase),
        Pair(name: "brass on feltBase", foreground: FeltPalette.brass, background: feltBase),
        Pair(name: "correct on feltBase", foreground: FeltPalette.correct, background: feltBase),
        Pair(name: "incorrect on feltBase", foreground: FeltPalette.incorrect, background: feltBase),
        Pair(name: "textPrimary on surfaceInset", foreground: FeltPalette.textPrimary, background: inset),
        Pair(name: "textSecondary on surfaceInset", foreground: FeltPalette.textSecondary, background: inset),
        Pair(name: "textTertiary on surfaceInset", foreground: FeltPalette.textTertiary, background: inset),
        Pair(name: "incorrect on surfaceInset", foreground: FeltPalette.incorrect, background: inset),
        Pair(name: "onCream on cream", foreground: FeltPalette.onCream, background: cream),
        Pair(name: "onCreamSecondary on cream", foreground: FeltPalette.onCreamSecondary, background: cream),
        Pair(name: "suitRed on cream", foreground: FeltPalette.suitRed, background: cream),
        Pair(name: "suitBlack on cream", foreground: FeltPalette.suitBlack, background: cream),
    ]

    /// Feedback badge glyphs: `onCream` drawn on a `correct` / `incorrect` disc.
    static let glyphPairs: [Pair] = [
        Pair(name: "onCream on correct", foreground: FeltPalette.onCream, background: FeltPalette.correct),
        Pair(name: "onCream on incorrect", foreground: FeltPalette.onCream, background: FeltPalette.incorrect),
    ]

    @Test("Contrast maths matches WCAG reference values")
    func referenceValues() {
        let black = RGBColor(hex: 0x000000)
        let white = RGBColor(hex: 0xFFFFFF)
        #expect(abs(WCAGContrast.ratio(black, white) - 21) < 0.001)
        #expect(abs(WCAGContrast.ratio(white, white) - 1) < 0.001)
        #expect(WCAGContrast.ratio(black, white) == WCAGContrast.ratio(white, black))
        // #777777 on white is the classic "just fails AA" grey: 4.48:1.
        #expect(abs(WCAGContrast.ratio(RGBColor(hex: 0x777777), white) - 4.48) < 0.01)
    }

    @Test("surfaceInset is black at 22% over the background")
    func insetComposite() {
        let inset = FeltPalette.surfaceInset(over: RGBColor(hex: 0xFFFFFF))
        #expect(abs(inset.red - 0.78) < 0.0001)
        #expect(abs(inset.green - 0.78) < 0.0001)
        #expect(abs(inset.blue - 0.78) < 0.0001)
    }

    @Test("Body text tokens reach 4.5:1", arguments: ContrastTests.bodyPairs)
    func body(_ pair: Pair) {
        #expect(WCAGContrast.ratio(pair.foreground, pair.background) >= WCAGContrast.bodyMinimum)
    }

    @Test("Feedback badge glyphs reach 3:1", arguments: ContrastTests.glyphPairs)
    func glyphs(_ pair: Pair) {
        #expect(WCAGContrast.ratio(pair.foreground, pair.background) >= WCAGContrast.largeTextMinimum)
    }
}
```

Create `BJSTests/FeltTokenTests.swift`:

```swift
import SwiftUI
import Testing
@testable import BJS

/// Pins the §4 token values so a later step cannot re-tune them by accident.
@Suite("Felt tokens")
struct FeltTokenTests {

    @Test("Spacing scale is 4, 8, 12, 16, 24, 32")
    func spacing() {
        #expect(FeltSpacing.scale == [4, 8, 12, 16, 24, 32])
    }

    @Test("Corner radii: chip 10, tile/button 14, card 8, sheet 16")
    func radii() {
        #expect(FeltRadius.chip == 10)
        #expect(FeltRadius.tile == 14)
        #expect(FeltRadius.button == 14)
        #expect(FeltRadius.card == 8)
        #expect(FeltRadius.sheet == 16)
    }

    @Test("Motion: UI 0.2 s, deal 0.25 s, flip 0.35 s")
    func motion() {
        #expect(FeltMotion.uiDuration == 0.2)
        #expect(FeltMotion.dealDuration == 0.25)
        #expect(FeltMotion.flipDuration == 0.35)
    }

    @Test("Cards are 1.4× as tall as wide; tap targets are at least 44 pt")
    func metrics() {
        #expect(FeltMetrics.cardAspectRatio == 1.4)
        #expect(FeltMetrics.minTapTarget == 44)
    }

    @Test("Type roles sit on the specified Dynamic Type styles")
    func typeRoles() {
        #expect(FeltType.display.textStyle == .title)
        #expect(FeltType.title.textStyle == .title3)
        #expect(FeltType.body.textStyle == .subheadline)
        #expect(FeltType.label.textStyle == .caption2)
        #expect(FeltType.stat.textStyle == .title2)
        #expect(FeltType.allCases.map(\.nominalPointSize) == [28, 20, 15, 11, 22])
        #expect(FeltType.display.weight == .bold)
        #expect(FeltType.body.weight == .regular)
        #expect(FeltType.stat.design == .monospaced)
        #expect(FeltType.allCases.filter(\.isUppercased) == [.label])
    }

    @Test("Palette hex values match spec §4")
    func palette() {
        #expect(FeltPalette.feltDeep == RGBColor(hex: 0x0C2A1F))
        #expect(FeltPalette.feltBase == RGBColor(hex: 0x123A2B))
        #expect(FeltPalette.feltLight == RGBColor(hex: 0x1F5A43))
        #expect(FeltPalette.cream == RGBColor(hex: 0xFBFAF6))
        #expect(FeltPalette.onCream == RGBColor(hex: 0x123A2B))
        #expect(FeltPalette.onCreamSecondary == RGBColor(hex: 0x3D6B57))
        #expect(FeltPalette.brass == RGBColor(hex: 0xD9B45A))
        #expect(FeltPalette.correct == RGBColor(hex: 0x6EE7A0))
        #expect(FeltPalette.incorrect == RGBColor(hex: 0xFF6B5B))
        #expect(FeltPalette.suitRed == RGBColor(hex: 0xD23B3B))
        #expect(FeltPalette.suitBlack == RGBColor(hex: 0x111111))
        #expect(FeltPalette.textPrimary == RGBColor(hex: 0xEEF3EE))
        #expect(FeltPalette.textSecondary == RGBColor(hex: 0xA9C4B6))
        #expect(FeltPalette.textTertiary == RGBColor(hex: 0x8FB3A2))
        #expect(FeltPalette.surfaceInsetOpacity == 0.22)
    }
}
```

- [ ] **Step 3: Implement the tokens**

Create `BJS/Design/Tokens/FeltPalette.swift`:

```swift
/// An sRGB colour with channels in 0...1. Plain data, so the contrast test can do maths on it.
struct RGBColor: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// `RGBColor(hex: 0x123A2B)`.
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }

    /// This colour drawn at `opacity` on top of an opaque `background`.
    func composited(over background: RGBColor, opacity: Double) -> RGBColor {
        RGBColor(red: red * opacity + background.red * (1 - opacity),
                 green: green * opacity + background.green * (1 - opacity),
                 blue: blue * opacity + background.blue * (1 - opacity))
    }
}

/// Raw Felt colour values (spec §4). FROZEN at the end of Step 2.
///
/// `FeltColor` builds the SwiftUI colours from these values, and the WCAG contrast
/// test reads them directly, so the tested numbers are the shipped numbers.
enum FeltPalette {
    static let feltDeep = RGBColor(hex: 0x0C2A1F)
    static let feltBase = RGBColor(hex: 0x123A2B)
    static let feltLight = RGBColor(hex: 0x1F5A43)
    static let cream = RGBColor(hex: 0xFBFAF6)
    static let onCream = RGBColor(hex: 0x123A2B)
    static let onCreamSecondary = RGBColor(hex: 0x3D6B57)
    static let brass = RGBColor(hex: 0xD9B45A)
    static let correct = RGBColor(hex: 0x6EE7A0)
    static let incorrect = RGBColor(hex: 0xFF6B5B)
    static let suitRed = RGBColor(hex: 0xD23B3B)
    static let suitBlack = RGBColor(hex: 0x111111)
    static let textPrimary = RGBColor(hex: 0xEEF3EE)
    static let textSecondary = RGBColor(hex: 0xA9C4B6)
    static let textTertiary = RGBColor(hex: 0x8FB3A2)

    /// `surfaceInset` is black at 22% over whatever is behind it.
    static let surfaceInsetOpacity = 0.22

    /// The opaque colour `surfaceInset` produces on top of `background`.
    static func surfaceInset(over background: RGBColor) -> RGBColor {
        RGBColor(hex: 0x000000).composited(over: background, opacity: surfaceInsetOpacity)
    }
}
```

Create `BJS/Design/Tokens/WCAGContrast.swift`:

```swift
import Foundation

/// WCAG 2.x relative luminance and contrast ratio.
/// https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
enum WCAGContrast {
    /// AA minimum for body text.
    static let bodyMinimum = 4.5
    /// AA minimum for large text (≥ 18 pt, or ≥ 14 pt bold; spec §4 uses ≥ 17 pt semibold) and UI glyphs.
    static let largeTextMinimum = 3.0

    static func relativeLuminance(_ color: RGBColor) -> Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
    }

    /// Contrast ratio in 1...21. Order of the arguments does not matter.
    static func ratio(_ first: RGBColor, _ second: RGBColor) -> Double {
        let a = relativeLuminance(first)
        let b = relativeLuminance(second)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}
```

Create `BJS/Design/Tokens/FeltColor.swift`:

```swift
import SwiftUI

extension Color {
    /// A SwiftUI colour from a Felt palette value.
    init(felt rgb: RGBColor) {
        self.init(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: 1)
    }
}

/// Felt colour tokens (spec §4). FROZEN at the end of Step 2.
///
/// - `brass` is an accent for hints, highlights and streaks only. Never decoration.
/// - `correct` / `incorrect` are for feedback only. Never use them as text on `cream`
///   (they fail contrast there); on cream they appear only as badge fills.
enum FeltColor {
    static let feltDeep = Color(felt: FeltPalette.feltDeep)
    static let feltBase = Color(felt: FeltPalette.feltBase)
    static let feltLight = Color(felt: FeltPalette.feltLight)
    static let surfaceInset = Color.black.opacity(FeltPalette.surfaceInsetOpacity)
    static let cream = Color(felt: FeltPalette.cream)
    static let onCream = Color(felt: FeltPalette.onCream)
    static let onCreamSecondary = Color(felt: FeltPalette.onCreamSecondary)
    static let brass = Color(felt: FeltPalette.brass)
    static let correct = Color(felt: FeltPalette.correct)
    static let incorrect = Color(felt: FeltPalette.incorrect)
    static let suitRed = Color(felt: FeltPalette.suitRed)
    static let suitBlack = Color(felt: FeltPalette.suitBlack)
    static let textPrimary = Color(felt: FeltPalette.textPrimary)
    static let textSecondary = Color(felt: FeltPalette.textSecondary)
    static let textTertiary = Color(felt: FeltPalette.textTertiary)
}
```

Create `BJS/Design/Tokens/FeltType.swift`:

```swift
import SwiftUI

/// Felt type roles (spec §4). FROZEN at the end of Step 2.
///
/// Every role is built on a Dynamic Type text style, so it scales with the user's
/// text size. `nominalPointSize` is the size at the default ("Large") setting.
enum FeltType: CaseIterable, Sendable {
    case display
    case title
    case body
    case label
    case stat

    /// Tracking for `label`, as a fraction of the font size (+0.14 em).
    static let labelTrackingEm: CGFloat = 0.14

    var textStyle: Font.TextStyle {
        switch self {
        case .display: return .title
        case .title: return .title3
        case .body: return .subheadline
        case .label: return .caption2
        case .stat: return .title2
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display: return .bold
        case .title, .label, .stat: return .semibold
        case .body: return .regular
        }
    }

    var design: Font.Design {
        self == .stat ? .monospaced : .default
    }

    var nominalPointSize: CGFloat {
        switch self {
        case .display: return 28
        case .title: return 20
        case .body: return 15
        case .label: return 11
        case .stat: return 22
        }
    }

    var isUppercased: Bool { self == .label }

    var font: Font {
        let base = Font.system(textStyle, design: design, weight: weight)
        return self == .stat ? base.monospacedDigit() : base
    }
}

extension View {
    /// Applies a Felt type role: font, plus uppercase and tracking for `label`.
    func feltType(_ role: FeltType) -> some View {
        modifier(FeltTypeModifier(role: role))
    }
}

private struct FeltTypeModifier: ViewModifier {
    let role: FeltType
    /// 0.14 em of the 11 pt label size, scaled with Dynamic Type.
    @ScaledMetric(relativeTo: .caption2) private var labelTracking: CGFloat = 11 * FeltType.labelTrackingEm

    init(role: FeltType) {
        self.role = role
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if role.isUppercased {
            content
                .font(role.font)
                .textCase(.uppercase)
                .tracking(labelTracking)
        } else {
            content.font(role.font)
        }
    }
}
```

Create `BJS/Design/Tokens/FeltLayout.swift`:

```swift
import SwiftUI

/// Spacing scale (spec §4): 4, 8, 12, 16, 24, 32. FROZEN at the end of Step 2.
enum FeltSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    static let scale: [CGFloat] = [xs, s, m, l, xl, xxl]
}

/// Corner radii (spec §4). FROZEN at the end of Step 2.
enum FeltRadius {
    static let chip: CGFloat = 10
    static let tile: CGFloat = 14
    static let button: CGFloat = 14
    static let card: CGFloat = 8
    static let sheet: CGFloat = 16
}

/// Fixed metrics shared by components.
enum FeltMetrics {
    /// Minimum tap target (Apple HIG, spec §4).
    static let minTapTarget: CGFloat = 44
    /// Playing card height = width × 1.4.
    static let cardAspectRatio: CGFloat = 1.4
}

/// Motion (spec §4): 0.2 s ease-out for UI, 0.25 s card deal, 0.35 s card flip.
/// With Reduce Motion on, components cross-fade instead of moving. FROZEN at the end of Step 2.
enum FeltMotion {
    static let uiDuration: TimeInterval = 0.2
    static let dealDuration: TimeInterval = 0.25
    static let flipDuration: TimeInterval = 0.35

    static var ui: Animation { .easeOut(duration: uiDuration) }
    static var deal: Animation { .easeOut(duration: dealDuration) }
    static var flip: Animation { .easeInOut(duration: flipDuration) }

    static func crossFade(duration: TimeInterval) -> Animation {
        .easeInOut(duration: duration)
    }

    /// Cards arrive from above; under Reduce Motion they fade in.
    static func dealTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? AnyTransition.opacity : AnyTransition.move(edge: .top).combined(with: .opacity)
    }

    /// Bottom-anchored panels (FeedbackCard) slide up; under Reduce Motion they fade in.
    static func panelTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? AnyTransition.opacity : AnyTransition.move(edge: .bottom).combined(with: .opacity)
    }
}
```

- [ ] **Step 4: Local pre-check — run the contrast numbers on Linux**

`FeltPalette.swift` and `WCAGContrast.swift` are Foundation-only, so compile them with a scratch `main.swift` (outside the repo) and run it:

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
mkdir -p /tmp/bjs-contrast && cat > /tmp/bjs-contrast/main.swift <<'SWIFT'
let base = FeltPalette.feltBase
let inset = FeltPalette.surfaceInset(over: base)
let checks: [(String, RGBColor, RGBColor, Double)] = [
    ("textPrimary/feltBase", FeltPalette.textPrimary, base, 4.5),
    ("textTertiary/feltBase", FeltPalette.textTertiary, base, 4.5),
    ("incorrect/feltBase", FeltPalette.incorrect, base, 4.5),
    ("textTertiary/inset", FeltPalette.textTertiary, inset, 4.5),
    ("onCreamSecondary/cream", FeltPalette.onCreamSecondary, FeltPalette.cream, 4.5),
    ("suitRed/cream", FeltPalette.suitRed, FeltPalette.cream, 4.5),
    ("onCream/incorrect", FeltPalette.onCream, FeltPalette.incorrect, 3.0),
]
var failed = false
for (name, fg, bg, minimum) in checks {
    let r = WCAGContrast.ratio(fg, bg)
    print(name, (r * 100).rounded() / 100, r >= minimum ? "OK" : "FAIL")
    if r < minimum { failed = true }
}
print(failed ? "CONTRAST FAIL" : "CONTRAST OK")
SWIFT
swiftc -o /tmp/bjs-contrast/run BJS/Design/Tokens/FeltPalette.swift BJS/Design/Tokens/WCAGContrast.swift /tmp/bjs-contrast/main.swift && /tmp/bjs-contrast/run
swiftc -parse BJS/Design/Tokens/*.swift BJSTests/ContrastTests.swift BJSTests/FeltTokenTests.swift
(cd BJSCore && swift test 2>&1 | tail -1)
```

Expected:

```
textPrimary/feltBase 11.22 OK
textTertiary/feltBase 5.49 OK
incorrect/feltBase 4.51 OK
textTertiary/inset 6.43 OK
onCreamSecondary/cream 5.85 OK
suitRed/cream 4.54 OK
onCream/incorrect 4.51 OK
CONTRAST OK
```

then no output from `swiftc -parse`, then `Test run with 173 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add project.yml BJS/Design/Tokens BJSTests/ContrastTests.swift BJSTests/FeltTokenTests.swift
git commit -m "feat(app): Felt tokens and WCAG contrast test; drop no-op isolation flag

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

Report the SHA to the controller.

- [ ] **Step 6: CI verification (controller)**

Expected: green; 12 unit tests (`ContrastTests` 4, `FeltTokenTests` 6, `AppShellTests` 2). Also confirm the build log has no `unknown feature` / `DefaultIsolationMainActor` warning.

---

### Task 2: FeltBackground, PlayingCard and HandView

**Files:**
- Create: `BJS/Design/Components/FeltBackground.swift`, `CardText.swift`, `PlayingCard.swift`, `HandView.swift`
- Test: `BJSTests/CardTextTests.swift`

**Interfaces:**
- Consumes: Task 1 tokens; `BJSCore.Card`, `Rank`, `Suit`
- Produces:
  - `struct FeltBackground: View`; `View.feltBackground()`
  - `enum CardText { rankIndex(_:), rankName(_:), accessibilityLabel(_:), isRed(_:), suitSymbolName(_:), faceDownLabel }`
  - `struct PlayingCard: View { init(_ card: Card, isFaceUp: Bool = true, width: CGFloat) }`
  - `struct DiagonalStripes: Shape { let spacing: CGFloat }`
  - `struct HandView: View { init(cards: [Card], faceDownIndices: Set<Int> = [], cardWidth: CGFloat, overlap: CGFloat, totalLabel: String? = nil) }`

- [ ] **Step 1: Write the tests**

Create `BJSTests/CardTextTests.swift`:

```swift
import BJSCore
import Testing
@testable import BJS

@Suite("CardText")
struct CardTextTests {

    @Test("VoiceOver label reads rank and suit", arguments: [
        (Card(rank: .eight, suit: .clubs), "Eight of clubs"),
        (Card(rank: .ace, suit: .spades), "Ace of spades"),
        (Card(rank: .ten, suit: .hearts), "Ten of hearts"),
        (Card(rank: .queen, suit: .diamonds), "Queen of diamonds"),
    ])
    func label(_ card: Card, _ expected: String) {
        #expect(CardText.accessibilityLabel(card) == expected)
    }

    @Test("Corner index for every rank")
    func index() {
        #expect(Rank.allCases.map(CardText.rankIndex) ==
                ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"])
    }

    @Test("Hearts and diamonds are red; clubs and spades are not")
    func colours() {
        #expect(CardText.isRed(.hearts))
        #expect(CardText.isRed(.diamonds))
        #expect(!CardText.isRed(.clubs))
        #expect(!CardText.isRed(.spades))
    }

    @Test("Every suit has an SF Symbol")
    func symbols() {
        #expect(Suit.allCases.map(CardText.suitSymbolName) ==
                ["suit.heart.fill", "suit.diamond.fill", "suit.club.fill", "suit.spade.fill"])
    }
}
```

- [ ] **Step 2: Implement**

Create `BJS/Design/Components/FeltBackground.swift`:

```swift
import SwiftUI

/// The table felt: a radial gradient `feltLight` → `feltBase` → `feltDeep`, edge to edge.
struct FeltBackground: View {
    var body: some View {
        GeometryReader { proxy in
            RadialGradient(
                stops: [
                    Gradient.Stop(color: FeltColor.feltLight, location: 0),
                    Gradient.Stop(color: FeltColor.feltBase, location: 0.5),
                    Gradient.Stop(color: FeltColor.feltDeep, location: 1),
                ],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 0,
                endRadius: max(proxy.size.width, proxy.size.height) * 0.75
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    /// Puts the felt behind this view, extending under the safe areas.
    func feltBackground() -> some View {
        background { FeltBackground() }
    }
}
```

Create `BJS/Design/Components/CardText.swift`:

```swift
import BJSCore

/// Text and symbols for drawing and announcing a card.
enum CardText {
    static let faceDownLabel = "Face-down card"

    /// The corner index: "A", "2" … "10", "J", "Q", "K".
    static func rankIndex(_ rank: Rank) -> String {
        switch rank {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return String(rank.rawValue)
        }
    }

    static func rankName(_ rank: Rank) -> String {
        switch rank {
        case .two: return "Two"
        case .three: return "Three"
        case .four: return "Four"
        case .five: return "Five"
        case .six: return "Six"
        case .seven: return "Seven"
        case .eight: return "Eight"
        case .nine: return "Nine"
        case .ten: return "Ten"
        case .jack: return "Jack"
        case .queen: return "Queen"
        case .king: return "King"
        case .ace: return "Ace"
        }
    }

    /// VoiceOver label, e.g. "Eight of clubs".
    static func accessibilityLabel(_ card: Card) -> String {
        "\(rankName(card.rank)) of \(card.suit.rawValue)"
    }

    static func isRed(_ suit: Suit) -> Bool {
        suit == .hearts || suit == .diamonds
    }

    /// SF Symbol for the suit.
    static func suitSymbolName(_ suit: Suit) -> String {
        switch suit {
        case .hearts: return "suit.heart.fill"
        case .diamonds: return "suit.diamond.fill"
        case .clubs: return "suit.club.fill"
        case .spades: return "suit.spade.fill"
        }
    }
}
```

Create `BJS/Design/Components/PlayingCard.swift`. The flip uses scoped animations (`animation(_:body:)`, iOS 17+): rotation animates over 0.35 s while the opacity switch jumps at the half-way point, so the mirrored face never shows; under Reduce Motion the angles stay at 0 and only the opacity cross-fades.

```swift
import BJSCore
import SwiftUI

/// A playing card drawn in SwiftUI (spec §4).
///
/// Face: cream, rank + suit index top-left, large suit bottom-right.
/// Back: cream border around diagonal felt stripes.
/// The caller sets the width; height is width × 1.4. Glyph sizes scale with the
/// width, not with Dynamic Type, because the card is a graphic.
/// Changing `isFaceUp` flips the card (0.35 s); under Reduce Motion it cross-fades.
struct PlayingCard: View {
    private let card: Card
    private let isFaceUp: Bool
    private let width: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(_ card: Card, isFaceUp: Bool = true, width: CGFloat) {
        self.card = card
        self.isFaceUp = isFaceUp
        self.width = width
    }

    private var height: CGFloat { width * FeltMetrics.cardAspectRatio }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: FeltRadius.card, style: .continuous) }
    private var suitColor: Color { CardText.isRed(card.suit) ? FeltColor.suitRed : FeltColor.suitBlack }

    /// Opacity switches at the half-way point of the flip, when the card is edge-on.
    private var opacityAnimation: Animation {
        reduceMotion
            ? FeltMotion.crossFade(duration: FeltMotion.flipDuration)
            : .linear(duration: 0.01).delay(FeltMotion.flipDuration / 2)
    }

    private var faceAngle: Double { reduceMotion || isFaceUp ? 0 : 180 }
    private var backAngle: Double { reduceMotion || !isFaceUp ? 0 : -180 }

    var body: some View {
        ZStack {
            back
                .animation(opacityAnimation) { $0.opacity(isFaceUp ? 0 : 1) }
                .animation(FeltMotion.flip) { $0.rotation3DEffect(.degrees(backAngle), axis: (x: 0, y: 1, z: 0)) }
            face
                .animation(opacityAnimation) { $0.opacity(isFaceUp ? 1 : 0) }
                .animation(FeltMotion.flip) { $0.rotation3DEffect(.degrees(faceAngle), axis: (x: 0, y: 1, z: 0)) }
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFaceUp ? CardText.accessibilityLabel(card) : CardText.faceDownLabel)
    }

    private var face: some View {
        shape
            .fill(FeltColor.cream)
            .overlay(alignment: .topLeading) {
                VStack(spacing: 0) {
                    Text(CardText.rankIndex(card.rank))
                        .font(.system(size: width * 0.30, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Image(systemName: CardText.suitSymbolName(card.suit))
                        .font(.system(size: width * 0.20))
                }
                .padding(width * 0.08)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: CardText.suitSymbolName(card.suit))
                    .font(.system(size: width * 0.45))
                    .padding(width * 0.10)
            }
            .foregroundStyle(suitColor)
    }

    private var back: some View {
        shape
            .fill(FeltColor.cream)
            .overlay {
                DiagonalStripes(spacing: width * 0.12)
                    .stroke(FeltColor.feltLight, lineWidth: width * 0.04)
                    .background(FeltColor.feltBase)
                    .clipShape(RoundedRectangle(cornerRadius: FeltRadius.card / 2, style: .continuous))
                    .padding(width * 0.07)
            }
    }
}

/// Parallel 45° lines filling a rectangle; the card-back pattern.
struct DiagonalStripes: Shape {
    let spacing: CGFloat

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        guard spacing > 0 else { return path }
        var x = rect.minX - rect.height
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            x += spacing
        }
        return path
    }
}
```

Create `BJS/Design/Components/HandView.swift`:

```swift
import BJSCore
import SwiftUI

/// A row of overlapping cards with an optional total label (spec §4).
///
/// `overlap` is the fraction of each card's width covered by the next card (0 = side by side).
/// New cards animate in with the 0.25 s deal motion; under Reduce Motion they fade in.
struct HandView: View {
    private let cards: [Card]
    private let faceDownIndices: Set<Int>
    private let cardWidth: CGFloat
    private let overlap: CGFloat
    private let totalLabel: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(cards: [Card], faceDownIndices: Set<Int> = [], cardWidth: CGFloat, overlap: CGFloat, totalLabel: String? = nil) {
        self.cards = cards
        self.faceDownIndices = faceDownIndices
        self.cardWidth = cardWidth
        self.overlap = min(max(overlap, 0), 0.9)
        self.totalLabel = totalLabel
    }

    var body: some View {
        VStack(spacing: FeltSpacing.s) {
            HStack(spacing: -cardWidth * overlap) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    PlayingCard(card, isFaceUp: !faceDownIndices.contains(index), width: cardWidth)
                        .transition(FeltMotion.dealTransition(reduceMotion: reduceMotion))
                }
            }
            .animation(reduceMotion ? FeltMotion.crossFade(duration: FeltMotion.dealDuration) : FeltMotion.deal,
                       value: cards.count)

            if let totalLabel {
                Text(totalLabel)
                    .feltType(.stat)
                    .foregroundStyle(FeltColor.textPrimary)
                    .accessibilityLabel("Total \(totalLabel)")
            }
        }
        .accessibilityElement(children: .contain)
    }
}
```

- [ ] **Step 3: Local pre-checks**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
(cd BJSCore && swift build 2>&1 | tail -1)
swiftc -typecheck -I BJSCore/.build/debug/Modules BJS/Design/Components/CardText.swift
swiftc -parse BJS/Design/Components/*.swift BJSTests/CardTextTests.swift
```

Expected: the build line, then no output from either `swiftc`.

- [ ] **Step 4: Commit**

```bash
git add BJS/Design/Components BJSTests/CardTextTests.swift
git commit -m "feat(app): FeltBackground, PlayingCard and HandView

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

- [ ] **Step 5: CI verification (controller)**

Expected: green; 16 unit tests.

---

### Task 3: Buttons, ActionDock and FeedbackCard

**Files:**
- Create: `BJS/Design/Components/FeltButtonStyle.swift`, `ActionDock.swift`, `FeedbackCard.swift`
- Test: `BJSTests/ActionDockTests.swift`

**Interfaces:**
- Consumes: Task 1 tokens; `BJSCore.Action`
- Produces:
  - `enum FeltButtonKind { primary, secondary, onCreamPrimary, onCreamSecondary }`; `struct FeltButtonStyle: ButtonStyle { let kind }`; `.buttonStyle(.feltPrimary / .feltSecondary / .feltOnCreamPrimary / .feltOnCreamSecondary)`
  - `struct FeltPressableStyle: ButtonStyle` (press feedback, no chrome)
  - `struct PrimaryButton: View { init(_ title: String, action:) }`, `struct SecondaryButton: View { init(_ title: String, action:) }`
  - `enum DockButtonState { enabled, dimmed, hint }`
  - `struct ActionDock: View { init(allowed: Set<Action>, hint: Action? = nil, onAction: @escaping (Action) -> Void); static primaryRow, secondaryRow, state(for:allowed:hint:), title(for:), spokenName(for:) }`
  - `struct FeedbackCard: View { static badgeSize; init(isCorrect:headline:reason:onWhy:onNext:) }`
  - Accessibility identifiers: `action.<raw>` (e.g. `action.stand`), `feedback.card`, `feedback.why`, `feedback.next`

- [ ] **Step 1: Write the tests**

Create `BJSTests/ActionDockTests.swift`:

```swift
import BJSCore
import Testing
@testable import BJS

@MainActor
@Suite("ActionDock")
struct ActionDockTests {

    @Test("Rows are STAND, HIT then SPLIT, DOUBLE, SURRENDER")
    func layout() {
        #expect(ActionDock.primaryRow == [.stand, .hit])
        #expect(ActionDock.secondaryRow == [.split, .double, .surrender])
        #expect(Set(ActionDock.primaryRow + ActionDock.secondaryRow) == Set(Action.allCases))
    }

    @Test("Actions the rules do not allow are dimmed")
    func dimmed() {
        let allowed: Set<Action> = [.hit, .stand]
        #expect(ActionDock.state(for: .double, allowed: allowed, hint: nil) == .dimmed)
        #expect(ActionDock.state(for: .split, allowed: allowed, hint: nil) == .dimmed)
        #expect(ActionDock.state(for: .hit, allowed: allowed, hint: nil) == .enabled)
    }

    @Test("The hinted action gets the hint state; others stay enabled")
    func hint() {
        let allowed = Set(Action.allCases)
        #expect(ActionDock.state(for: .double, allowed: allowed, hint: .double) == .hint)
        #expect(ActionDock.state(for: .hit, allowed: allowed, hint: .double) == .enabled)
    }

    @Test("A hint on a disallowed action is still dimmed")
    func hintNeverOverridesRules() {
        #expect(ActionDock.state(for: .surrender, allowed: [.hit, .stand], hint: .surrender) == .dimmed)
    }

    @Test("Captions are uppercase; VoiceOver names are capitalised")
    func titles() {
        #expect(ActionDock.title(for: .surrender) == "SURRENDER")
        #expect(ActionDock.spokenName(for: .double) == "Double")
    }
}
```

- [ ] **Step 2: Implement**

Create `BJS/Design/Components/FeltButtonStyle.swift`:

```swift
import SwiftUI

/// The four Felt button treatments.
enum FeltButtonKind: Sendable {
    /// Cream fill, `onCream` text. `PrimaryButton`, ActionDock row 1.
    case primary
    /// `surfaceInset` fill with a hairline outline. `SecondaryButton`, ActionDock row 2, keypad keys.
    case secondary
    /// Used on cream surfaces (FeedbackCard NEXT): `onCream` fill, cream text.
    case onCreamPrimary
    /// Used on cream surfaces (FeedbackCard WHY): `onCream` outline and text.
    case onCreamSecondary
}

/// Full-width, ≥ 44 pt Felt button. Disabled buttons dim to 40%.
struct FeltButtonStyle: ButtonStyle {
    let kind: FeltButtonKind

    func makeBody(configuration: Configuration) -> some View {
        FeltButtonBody(configuration: configuration, kind: kind)
    }
}

extension ButtonStyle where Self == FeltButtonStyle {
    static var feltPrimary: FeltButtonStyle { FeltButtonStyle(kind: .primary) }
    static var feltSecondary: FeltButtonStyle { FeltButtonStyle(kind: .secondary) }
    static var feltOnCreamPrimary: FeltButtonStyle { FeltButtonStyle(kind: .onCreamPrimary) }
    static var feltOnCreamSecondary: FeltButtonStyle { FeltButtonStyle(kind: .onCreamSecondary) }
}

private struct FeltButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let kind: FeltButtonKind

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: FeltRadius.button, style: .continuous)
    }

    private var fill: Color {
        switch kind {
        case .primary: return FeltColor.cream
        case .secondary: return FeltColor.surfaceInset
        case .onCreamPrimary: return FeltColor.onCream
        case .onCreamSecondary: return Color.clear
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary, .onCreamSecondary: return FeltColor.onCream
        case .secondary: return FeltColor.textPrimary
        case .onCreamPrimary: return FeltColor.cream
        }
    }

    private var outline: Color? {
        switch kind {
        case .secondary: return FeltColor.textTertiary
        case .onCreamSecondary: return FeltColor.onCream
        case .primary, .onCreamPrimary: return nil
        }
    }

    var body: some View {
        configuration.label
            .feltType(.body)
            .fontWeight(.semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(foreground)
            .padding(.horizontal, FeltSpacing.m)
            .padding(.vertical, FeltSpacing.s)
            .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget)
            .background(fill, in: shape)
            .overlay {
                if let outline {
                    shape.strokeBorder(outline, lineWidth: 1)
                }
            }
            .contentShape(shape)
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(FeltMotion.ui, value: configuration.isPressed)
    }
}

/// Press feedback without chrome, for custom tappable surfaces such as `ModuleTile`.
struct FeltPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FeltPressableBody(configuration: configuration)
    }
}

private struct FeltPressableBody: View {
    let configuration: ButtonStyleConfiguration

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(FeltMotion.ui, value: configuration.isPressed)
    }
}

/// Cream-filled call to action.
struct PrimaryButton: View {
    private let title: String
    private let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.feltPrimary)
    }
}

/// Outlined button on `surfaceInset`.
struct SecondaryButton: View {
    private let title: String
    private let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.feltSecondary)
    }
}
```

Create `BJS/Design/Components/ActionDock.swift`:

```swift
import BJSCore
import SwiftUI

/// How one dock button is drawn.
enum DockButtonState: Equatable, Sendable {
    case enabled
    /// Not allowed by the rules in this spot: disabled and dimmed.
    case dimmed
    /// Learn mode: the correct action carries the brass ring.
    case hint
}

/// The player's action buttons (spec §4).
/// Row 1: STAND, HIT (cream). Row 2: SPLIT, DOUBLE, SURRENDER (inset).
struct ActionDock: View {
    static let primaryRow: [Action] = [.stand, .hit]
    static let secondaryRow: [Action] = [.split, .double, .surrender]

    private let allowed: Set<Action>
    private let hint: Action?
    private let onAction: (Action) -> Void

    init(allowed: Set<Action>, hint: Action? = nil, onAction: @escaping (Action) -> Void) {
        self.allowed = allowed
        self.hint = hint
        self.onAction = onAction
    }

    static func state(for action: Action, allowed: Set<Action>, hint: Action?) -> DockButtonState {
        guard allowed.contains(action) else { return .dimmed }
        return action == hint ? .hint : .enabled
    }

    /// Button caption, e.g. "STAND".
    static func title(for action: Action) -> String {
        action.rawValue.uppercased()
    }

    /// VoiceOver name, e.g. "Stand".
    static func spokenName(for action: Action) -> String {
        action.rawValue.capitalized
    }

    var body: some View {
        VStack(spacing: FeltSpacing.s) {
            HStack(spacing: FeltSpacing.s) {
                ForEach(Self.primaryRow, id: \.self) { action in
                    button(for: action, kind: .primary)
                }
            }
            HStack(spacing: FeltSpacing.s) {
                ForEach(Self.secondaryRow, id: \.self) { action in
                    button(for: action, kind: .secondary)
                }
            }
        }
    }

    private func button(for action: Action, kind: FeltButtonKind) -> some View {
        let state = Self.state(for: action, allowed: allowed, hint: hint)
        return Button {
            onAction(action)
        } label: {
            Text(Self.title(for: action))
        }
        .buttonStyle(FeltButtonStyle(kind: kind))
        .overlay {
            if state == .hint {
                RoundedRectangle(cornerRadius: FeltRadius.button, style: .continuous)
                    .strokeBorder(FeltColor.brass, lineWidth: 3)
                    .allowsHitTesting(false)
            }
        }
        .disabled(state == .dimmed)
        .accessibilityLabel(Self.spokenName(for: action))
        .accessibilityValue(state == .hint ? "Suggested" : "")
        .accessibilityIdentifier("action.\(action.rawValue)")
    }
}
```

Create `BJS/Design/Components/FeedbackCard.swift`:

```swift
import SwiftUI

/// Decision feedback (spec §4): a cream card anchored at the bottom, over the dock.
/// A ✓ / ✕ badge straddles the top edge; then a headline, a one-line reason, and WHY + NEXT.
///
/// The caller positions it (bottom of the screen) and animates it in with
/// `FeltMotion.panelTransition(reduceMotion:)`.
struct FeedbackCard: View {
    static let badgeSize: CGFloat = 44

    private let isCorrect: Bool
    private let headline: String
    private let reason: String
    private let onWhy: () -> Void
    private let onNext: () -> Void

    init(isCorrect: Bool, headline: String, reason: String,
         onWhy: @escaping () -> Void, onNext: @escaping () -> Void) {
        self.isCorrect = isCorrect
        self.headline = headline
        self.reason = reason
        self.onWhy = onWhy
        self.onNext = onNext
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text(headline)
                .feltType(.title)
                .foregroundStyle(FeltColor.onCream)
            Text(reason)
                .feltType(.body)
                .foregroundStyle(FeltColor.onCreamSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: FeltSpacing.s) {
                Button("WHY", action: onWhy)
                    .buttonStyle(.feltOnCreamSecondary)
                    .accessibilityIdentifier("feedback.why")
                Button("NEXT", action: onNext)
                    .buttonStyle(.feltOnCreamPrimary)
                    .accessibilityIdentifier("feedback.next")
            }
            .padding(.top, FeltSpacing.s)
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.top, FeltSpacing.l + Self.badgeSize / 2)
        .padding(.bottom, FeltSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FeltColor.cream, in: RoundedRectangle(cornerRadius: FeltRadius.sheet, style: .continuous))
        .overlay(alignment: .top) {
            badge.offset(y: -Self.badgeSize / 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("feedback.card")
    }

    private var badge: some View {
        Image(systemName: isCorrect ? "checkmark" : "xmark")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(FeltColor.onCream)
            .frame(width: Self.badgeSize, height: Self.badgeSize)
            .background(isCorrect ? FeltColor.correct : FeltColor.incorrect, in: Circle())
            .overlay(Circle().strokeBorder(FeltColor.cream, lineWidth: 3))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isCorrect ? "Correct" : "Incorrect")
    }
}
```

- [ ] **Step 3: Local pre-checks**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
swiftc -parse BJS/Design/Components/*.swift BJSTests/ActionDockTests.swift
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add BJS/Design/Components BJSTests/ActionDockTests.swift
git commit -m "feat(app): Felt button styles, ActionDock and FeedbackCard

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

- [ ] **Step 5: CI verification (controller)**

Expected: green; 21 unit tests.

---

### Task 4: StatChip, ModuleTile, ModePicker and SettingsRow

**Files:**
- Create: `BJS/Design/Components/StatChip.swift`, `ModuleTile.swift`, `ModePicker.swift`, `SettingsRow.swift`

These are layout-only components with no logic to unit-test; the gallery (Task 10) and the design check (Task 12) verify them visually.

**Interfaces:**
- Consumes: Task 1 tokens; `FeltPressableStyle` (Task 3)
- Produces:
  - `struct StatChip: View { init(label: String, value: String) }`
  - `struct ModuleTile: View { init(title: String, subtitle: String, action: @escaping () -> Void) }`
  - `struct ModePicker<Option: Hashable>: View { init(_ options: [Option], selection: Binding<Option>, title: @escaping (Option) -> String) }`
  - `struct SettingsRow<Accessory: View>: View` with initialisers:
    - `init(_ title: String, showsSeparator: Bool = true, @ViewBuilder accessory: () -> Accessory)`
    - `init(_ title: String, value: String, showsSeparator: Bool = true)` (`Accessory == SettingsValueText`)
    - `init(_ title: String, isOn: Binding<Bool>, showsSeparator: Bool = true)` (`Accessory == SettingsToggle`)
    - `init<Value: Hashable>(_ title: String, selection: Binding<Value>, options: [Value], showsSeparator: Bool = true, optionTitle: @escaping (Value) -> String)` (`Accessory == SettingsPicker<Value>`)
  - `struct SettingsSection<Content: View>: View { init(_ title: String, @ViewBuilder content: () -> Content) }`

- [ ] **Step 1: Implement**

Create `BJS/Design/Components/StatChip.swift`:

```swift
import SwiftUI

/// A label over a monospaced stat value, on `surfaceInset` (spec §4).
struct StatChip: View {
    private let label: String
    private let value: String

    init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            Text(label)
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .feltType(.stat)
                .foregroundStyle(FeltColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FeltSpacing.m)
        .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
```

Create `BJS/Design/Components/ModuleTile.swift`:

```swift
import SwiftUI

/// A tappable title + subtitle tile on `surfaceInset` (spec §4). Used for the hub's modules.
struct ModuleTile: View {
    private let title: String
    private let subtitle: String
    private let action: () -> Void

    init(title: String, subtitle: String, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                Text(title)
                    .feltType(.title)
                    .foregroundStyle(FeltColor.textPrimary)
                Text(subtitle)
                    .feltType(.body)
                    .foregroundStyle(FeltColor.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(FeltSpacing.l)
            .frame(minHeight: FeltMetrics.minTapTarget * 2)
            .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.tile, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: FeltRadius.tile, style: .continuous))
        }
        .buttonStyle(FeltPressableStyle())
    }
}
```

Create `BJS/Design/Components/ModePicker.swift`:

```swift
import SwiftUI

/// Segmented control on `surfaceInset`; the selected segment is cream (spec §4).
struct ModePicker<Option: Hashable>: View {
    private let options: [Option]
    @Binding private var selection: Option
    private let title: (Option) -> String

    init(_ options: [Option], selection: Binding<Option>, title: @escaping (Option) -> String) {
        self.options = options
        self._selection = selection
        self.title = title
    }

    var body: some View {
        HStack(spacing: FeltSpacing.xs) {
            ForEach(options, id: \.self) { option in
                segment(option)
            }
        }
        .padding(FeltSpacing.xs)
        .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous))
        .animation(FeltMotion.ui, value: selection)
    }

    private func segment(_ option: Option) -> some View {
        let isSelected = option == selection
        return Button {
            selection = option
        } label: {
            Text(title(option))
                .feltType(.body)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isSelected ? FeltColor.onCream : FeltColor.textSecondary)
                .padding(.horizontal, FeltSpacing.xs)
                .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget)
                .background {
                    if isSelected {
                        // Concentric with the track: track radius minus its padding.
                        RoundedRectangle(cornerRadius: FeltRadius.chip - FeltSpacing.xs, style: .continuous)
                            .fill(FeltColor.cream)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
```

Create `BJS/Design/Components/SettingsRow.swift`. The picker initialiser uses a generic `where Accessory == SettingsPicker<Value>` clause; this pattern was checked with `swiftc` 6.2 on a SwiftUI-free model of the same types.

```swift
import SwiftUI

/// Hairline between rows: `textTertiary` at 30%, one physical pixel.
private let settingsHairline = FeltColor.textTertiary.opacity(0.3)

/// A settings line: title on the left, a value / toggle / picker on the right,
/// hairline separator below (spec §4). At least 44 pt tall.
struct SettingsRow<Accessory: View>: View {
    private let title: String
    private let showsSeparator: Bool
    /// True when the accessory is a control that already carries `title` as its
    /// accessibility label (toggle, picker), so VoiceOver does not read it twice.
    private let accessoryCarriesTitle: Bool
    private let accessory: Accessory

    @Environment(\.displayScale) private var displayScale

    /// A row with a custom accessory.
    init(_ title: String, showsSeparator: Bool = true, @ViewBuilder accessory: () -> Accessory) {
        self.init(title: title, showsSeparator: showsSeparator, accessoryCarriesTitle: false, accessory: accessory())
    }

    fileprivate init(title: String, showsSeparator: Bool, accessoryCarriesTitle: Bool, accessory: Accessory) {
        self.title = title
        self.showsSeparator = showsSeparator
        self.accessoryCarriesTitle = accessoryCarriesTitle
        self.accessory = accessory
    }

    var body: some View {
        HStack(spacing: FeltSpacing.m) {
            Text(title)
                .feltType(.body)
                .foregroundStyle(FeltColor.textPrimary)
                .accessibilityHidden(accessoryCarriesTitle)
            Spacer(minLength: FeltSpacing.s)
            accessory
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.vertical, FeltSpacing.xs)
        .frame(minHeight: FeltMetrics.minTapTarget)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle()
                    .fill(settingsHairline)
                    .frame(height: 1 / displayScale)
                    .padding(.leading, FeltSpacing.l)
            }
        }
        .accessibilityElement(children: accessoryCarriesTitle ? .contain : .combine)
    }
}

/// Read-only value text for a `SettingsRow`.
struct SettingsValueText: View {
    let value: String

    var body: some View {
        Text(value)
            .feltType(.body)
            .foregroundStyle(FeltColor.textSecondary)
    }
}

/// Toggle accessory for a `SettingsRow`. On-state tint is cream, like a selected ModePicker segment.
struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .labelsHidden()
            .tint(FeltColor.cream)
    }
}

/// Menu picker accessory for a `SettingsRow`.
struct SettingsPicker<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let optionTitle: (Value) -> String

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(optionTitle(option)).tag(option)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .tint(FeltColor.textSecondary)
    }
}

extension SettingsRow where Accessory == SettingsValueText {
    init(_ title: String, value: String, showsSeparator: Bool = true) {
        self.init(title: title, showsSeparator: showsSeparator, accessoryCarriesTitle: false,
                  accessory: SettingsValueText(value: value))
    }
}

extension SettingsRow where Accessory == SettingsToggle {
    init(_ title: String, isOn: Binding<Bool>, showsSeparator: Bool = true) {
        self.init(title: title, showsSeparator: showsSeparator, accessoryCarriesTitle: true,
                  accessory: SettingsToggle(title: title, isOn: isOn))
    }
}

extension SettingsRow {
    init<Value: Hashable>(_ title: String, selection: Binding<Value>, options: [Value],
                          showsSeparator: Bool = true,
                          optionTitle: @escaping (Value) -> String) where Accessory == SettingsPicker<Value> {
        self.init(title: title, showsSeparator: showsSeparator, accessoryCarriesTitle: true,
                  accessory: SettingsPicker(title: title, selection: selection, options: options,
                                            optionTitle: optionTitle))
    }
}

/// A titled group of `SettingsRow`s on one `surfaceInset` panel.
struct SettingsSection<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text(title)
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
                .padding(.horizontal, FeltSpacing.l)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                content
            }
            .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.tile, style: .continuous))
        }
    }
}
```

- [ ] **Step 2: Local pre-checks**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
swiftc -parse BJS/Design/Components/*.swift
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add BJS/Design/Components
git commit -m "feat(app): StatChip, ModuleTile, ModePicker and SettingsRow

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

- [ ] **Step 4: CI verification (controller)**

Expected: green; still 21 unit tests (this task only has to compile).

---

### Task 5: CountEntry and CountKeypad

**Files:**
- Create: `BJS/Design/Components/CountEntry.swift`, `BJS/Design/Components/CountKeypad.swift`
- Test: `BJSTests/CountEntryTests.swift`

**Interfaces:**
- Produces:
  - `struct CountEntry: Equatable, Sendable` — `isNegative`, `integerDigits`, `fractionDigits` (read-only), `isEmpty`, `value: Double?`, `display: String` (true minus sign U+2212), `appendDigit(_:)`, `appendDecimalPoint()`, `toggleSign()`, `deleteBackward()`, `clear()`; limits 3 integer digits, 2 fraction digits
  - `struct CountKeypad: View { init(entry: Binding<CountEntry>, allowsDecimal: Bool = false, submitTitle: String = "Enter", onSubmit: @escaping (Double) -> Void) }`
  - Accessibility identifiers: `keypad.display`, `keypad.digit.<n>`, `keypad.sign`, `keypad.decimal`, `keypad.delete`, `keypad.submit`

- [ ] **Step 1: Write the tests**

Create `BJSTests/CountEntryTests.swift`:

```swift
import Testing
@testable import BJS

@Suite("CountEntry")
struct CountEntryTests {

    private func typed(_ keys: String) -> CountEntry {
        var entry = CountEntry()
        for key in keys {
            switch key {
            case "-": entry.toggleSign()
            case ".": entry.appendDecimalPoint()
            case "<": entry.deleteBackward()
            default: entry.appendDigit(Int(String(key))!)
            }
        }
        return entry
    }

    @Test("Empty entry shows 0 and has no value")
    func empty() {
        let entry = CountEntry()
        #expect(entry.isEmpty)
        #expect(entry.value == nil)
        #expect(entry.display == "0")
    }

    @Test("Digits build an integer", arguments: [
        ("12", 12.0, "12"),
        ("-12", -12.0, "\u{2212}12"),
        ("12-", -12.0, "\u{2212}12"),
        ("--7", 7.0, "7"),
        ("0", 0.0, "0"),
        ("-0", 0.0, "\u{2212}0"),
    ])
    func integers(_ keys: String, _ value: Double, _ display: String) {
        let entry = typed(keys)
        #expect(entry.value == value)
        #expect(entry.display == display)
    }

    @Test("No leading zeros")
    func leadingZero() {
        #expect(typed("05").display == "5")
        #expect(typed("00").display == "0")
    }

    @Test("At most three integer digits")
    func integerLimit() {
        #expect(typed("1234").value == 123)
    }

    @Test("Decimals: one point, at most two fraction digits")
    func decimals() {
        #expect(typed("1.25").value == 1.25)
        #expect(typed("1.259").value == 1.25)
        #expect(typed("1..5").value == 1.5)
        #expect(typed(".5").display == "0.5")
        #expect(typed(".5").value == 0.5)
        #expect(typed("-1.5").value == -1.5)
        #expect(typed("2.").display == "2.")
        #expect(typed("2.").value == 2)
    }

    @Test("Delete removes fraction digits, then the point, then digits, then the sign")
    func delete() {
        #expect(typed("1.25<").display == "1.2")
        #expect(typed("1.2<<").display == "1")
        #expect(typed("-12<").display == "\u{2212}1")
        #expect(typed("-1<<").display == "0")
        #expect(typed("-1<<").isEmpty)
        #expect(typed("<").isEmpty)
    }

    @Test("Clear resets everything")
    func clear() {
        var entry = typed("-1.5")
        entry.clear()
        #expect(entry == CountEntry())
    }

    @Test("Out-of-range digits are ignored")
    func badDigit() {
        var entry = CountEntry()
        entry.appendDigit(10)
        entry.appendDigit(-1)
        #expect(entry.isEmpty)
    }
}
```

- [ ] **Step 2: Implement `CountEntry`**

Create `BJS/Design/Components/CountEntry.swift`:

```swift
/// What the user has typed on a `CountKeypad`: an optional minus sign, up to three
/// integer digits and, when the keypad allows it, a decimal point with up to two digits.
struct CountEntry: Equatable, Sendable {
    static let maxIntegerDigits = 3
    static let maxFractionDigits = 2

    private(set) var isNegative = false
    private(set) var integerDigits = ""
    /// nil until the decimal point is typed.
    private(set) var fractionDigits: String?

    init() {}

    var isEmpty: Bool { integerDigits.isEmpty && fractionDigits == nil }

    /// The typed number, or nil when nothing has been typed. "−0" is 0.
    var value: Double? {
        guard !isEmpty else { return nil }
        let whole = Double(integerDigits.isEmpty ? "0" : integerDigits) ?? 0
        var fraction = 0.0
        if let fractionDigits, !fractionDigits.isEmpty {
            fraction = Double("0." + fractionDigits) ?? 0
        }
        let magnitude = whole + fraction
        if magnitude == 0 { return 0 }
        return isNegative ? -magnitude : magnitude
    }

    /// What the display shows, using a true minus sign (U+2212): "0", "−12", "1.25", "0.".
    var display: String {
        let sign = isNegative ? "\u{2212}" : ""
        let whole = integerDigits.isEmpty ? "0" : integerDigits
        let fraction = fractionDigits.map { "." + $0 } ?? ""
        return sign + whole + fraction
    }

    mutating func appendDigit(_ digit: Int) {
        guard (0...9).contains(digit) else { return }
        if let fractionDigits {
            if fractionDigits.count < Self.maxFractionDigits {
                self.fractionDigits = fractionDigits + String(digit)
            }
        } else if integerDigits == "0" {
            integerDigits = String(digit)
        } else if integerDigits.count < Self.maxIntegerDigits {
            integerDigits += String(digit)
        }
    }

    mutating func appendDecimalPoint() {
        if fractionDigits == nil { fractionDigits = "" }
    }

    mutating func toggleSign() {
        isNegative.toggle()
    }

    /// Removes the last typed character: fraction digit, then the point, then integer digits, then the sign.
    mutating func deleteBackward() {
        if let fractionDigits {
            self.fractionDigits = fractionDigits.isEmpty ? nil : String(fractionDigits.dropLast())
        } else if !integerDigits.isEmpty {
            integerDigits.removeLast()
        } else {
            isNegative = false
        }
    }

    mutating func clear() {
        self = CountEntry()
    }
}
```

- [ ] **Step 3: Local pre-check — run the `CountEntry` cases on Linux**

`CountEntry.swift` has no imports, so the same cases run locally:

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
mkdir -p /tmp/bjs-entry && cat > /tmp/bjs-entry/main.swift <<'SWIFT'
func typed(_ keys: String) -> CountEntry {
    var entry = CountEntry()
    for key in keys {
        switch key {
        case "-": entry.toggleSign()
        case ".": entry.appendDecimalPoint()
        case "<": entry.deleteBackward()
        default: entry.appendDigit(Int(String(key))!)
        }
    }
    return entry
}
var fails = 0
func check(_ ok: Bool, _ label: String) { if !ok { fails += 1; print("FAIL", label) } }
check(typed("12").value == 12 && typed("-12").display == "\u{2212}12", "integers")
check(typed("12-").value == -12 && typed("--7").display == "7", "sign")
check(typed("-0").value == 0 && typed("-0").display == "\u{2212}0", "minus zero")
check(typed("05").display == "5" && typed("1234").value == 123, "leading zero, limit")
check(typed("1.259").value == 1.25 && typed("1..5").value == 1.5 && typed(".5").display == "0.5", "decimals")
check(typed("2.").display == "2." && typed("2.").value == 2, "trailing point")
check(typed("1.25<").display == "1.2" && typed("1.2<<").display == "1", "delete fraction")
check(typed("-12<").display == "\u{2212}1" && typed("-1<<").isEmpty && typed("<").isEmpty, "delete sign")
print(fails == 0 ? "COUNTENTRY OK" : "COUNTENTRY FAIL")
SWIFT
swiftc -o /tmp/bjs-entry/run BJS/Design/Components/CountEntry.swift /tmp/bjs-entry/main.swift && /tmp/bjs-entry/run
```

Expected: `COUNTENTRY OK`.

- [ ] **Step 4: Implement `CountKeypad`**

Create `BJS/Design/Components/CountKeypad.swift`:

```swift
import SwiftUI

/// Numeric keypad with ± for entering running and true counts (spec §4).
///
///     [ display ]
///     1  2  3
///     4  5  6
///     7  8  9
///     ±  0  .      ("." only when `allowsDecimal`)
///     ⌫  [ Enter ]
struct CountKeypad: View {
    @Binding private var entry: CountEntry
    private let allowsDecimal: Bool
    private let submitTitle: String
    private let onSubmit: (Double) -> Void

    private static let digitRows: [[Int]] = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    init(entry: Binding<CountEntry>, allowsDecimal: Bool = false, submitTitle: String = "Enter",
         onSubmit: @escaping (Double) -> Void) {
        self._entry = entry
        self.allowsDecimal = allowsDecimal
        self.submitTitle = submitTitle
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(spacing: FeltSpacing.s) {
            Text(entry.display)
                .feltType(.stat)
                .foregroundStyle(entry.isEmpty ? FeltColor.textTertiary : FeltColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget)
                .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous))
                .accessibilityLabel("Entered count")
                .accessibilityValue(entry.isEmpty ? "Empty" : entry.display)
                .accessibilityIdentifier("keypad.display")

            Grid(horizontalSpacing: FeltSpacing.s, verticalSpacing: FeltSpacing.s) {
                ForEach(Self.digitRows, id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { digit in
                            digitKey(digit)
                        }
                    }
                }
                GridRow {
                    key("±", accessibilityLabel: "Change sign", identifier: "keypad.sign") {
                        entry.toggleSign()
                    }
                    digitKey(0)
                    if allowsDecimal {
                        key(".", accessibilityLabel: "Decimal point", identifier: "keypad.decimal") {
                            entry.appendDecimalPoint()
                        }
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget)
                            .accessibilityHidden(true)
                    }
                }
                GridRow {
                    Button {
                        entry.deleteBackward()
                    } label: {
                        Image(systemName: "delete.left")
                    }
                    .buttonStyle(.feltSecondary)
                    .accessibilityLabel("Delete")
                    .accessibilityIdentifier("keypad.delete")

                    Button(submitTitle) {
                        if let value = entry.value { onSubmit(value) }
                    }
                    .buttonStyle(.feltPrimary)
                    .disabled(entry.value == nil)
                    .gridCellColumns(2)
                    .accessibilityIdentifier("keypad.submit")
                }
            }
        }
    }

    private func digitKey(_ digit: Int) -> some View {
        key(String(digit), accessibilityLabel: String(digit), identifier: "keypad.digit.\(digit)") {
            entry.appendDigit(digit)
        }
    }

    private func key(_ text: String, accessibilityLabel: String, identifier: String,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).feltType(.stat)
        }
        .buttonStyle(.feltSecondary)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier)
    }
}
```

- [ ] **Step 5: Local pre-checks**

```bash
swiftc -parse BJS/Design/Components/CountKeypad.swift BJSTests/CountEntryTests.swift
```

Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add BJS/Design/Components BJSTests/CountEntryTests.swift
git commit -m "feat(app): CountEntry and CountKeypad with sign and optional decimal key

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

- [ ] **Step 7: CI verification (controller)**

Expected: green; 29 unit tests.

---

### Task 6: ActiveRulesStore, Preferences and rules display

**Files:**
- Create: `BJS/Shared/AppLog.swift`, `RulesCoding.swift`, `RulesDisplay.swift`, `ActiveRulesStore.swift`, `Preferences.swift`
- Test: `BJSTests/TestDefaults.swift`, `BJSTests/ActiveRulesStoreTests.swift`, `BJSTests/PreferencesTests.swift`

**Interfaces:**
- Consumes: `BJSCore.BlackjackRules` (+ nested enums), `RulePreset`, `TrueCountConvention`
- Produces:
  - `enum AppLog { static let persistence, settings: Logger }`
  - `enum RulesCoding { static func encode(_:) -> Data; static func decode(_:) throws -> BlackjackRules }` (sorted-key JSON)
  - `displayName` on `DeckCount`, `DealerSoft17`, `BlackjackPayout`, `SurrenderRule`, `DoubleRestriction`, `PeekRule`, `TrueCountConvention`; `shortName` on `DeckCount`, `DealerSoft17`, `SurrenderRule` (optional)
  - `enum RulesSummary { static func short(_:) -> String; static func presetName(_: RulePreset?) -> String }`
  - `@MainActor @Observable final class ActiveRulesStore { init(defaults: UserDefaults = .standard); var rules: BlackjackRules; var matchingPreset: RulePreset?; func apply(_:); nonisolated static let storageKey = "activeRules" }`
  - `@MainActor @Observable final class Preferences { init(defaults:); var speedTimerSeconds: Double; var trueCountConvention: TrueCountConvention; var shoeCheckEveryRounds: Int; var hapticsEnabled: Bool; static speedTimerOptions, shoeCheckOptions, defaults and ranges; enum Key }`

- [ ] **Step 1: Write the tests**

Create `BJSTests/TestDefaults.swift`:

```swift
import Foundation

/// A throwaway `UserDefaults` suite so tests never touch `.standard` or each other.
enum TestDefaults {
    static func make() -> UserDefaults {
        let name = "BJSTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else {
            preconditionFailure("could not create UserDefaults suite \(name)")
        }
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
```

Create `BJSTests/ActiveRulesStoreTests.swift`:

```swift
import BJSCore
import Foundation
import Testing
@testable import BJS

@MainActor
@Suite("ActiveRulesStore")
struct ActiveRulesStoreTests {

    @Test("A fresh install uses the default rules (which match Vegas Strip)")
    func defaults() {
        let store = ActiveRulesStore(defaults: TestDefaults.make())
        #expect(store.rules == BlackjackRules())
        #expect(store.matchingPreset == .vegasStrip)
    }

    @Test("Changes persist across store instances")
    func persists() {
        let defaults = TestDefaults.make()
        let store = ActiveRulesStore(defaults: defaults)
        store.rules.deckCount = .two
        store.rules.surrenderRule = .late

        let reloaded = ActiveRulesStore(defaults: defaults)
        #expect(reloaded.rules.deckCount == .two)
        #expect(reloaded.rules.surrenderRule == .late)
    }

    @Test("Stored value is JSON Data under 'activeRules' (readable by @AppStorage Data)")
    func storageFormat() throws {
        let defaults = TestDefaults.make()
        let store = ActiveRulesStore(defaults: defaults)
        store.apply(.atlanticCity)
        let data = try #require(defaults.data(forKey: "activeRules"))
        #expect(try RulesCoding.decode(data) == RulePreset.atlanticCity.rules)
    }

    @Test("Corrupt JSON falls back to default rules")
    func corruptFallsBack() {
        let defaults = TestDefaults.make()
        defaults.set(Data("not json".utf8), forKey: "activeRules")
        #expect(ActiveRulesStore(defaults: defaults).rules == BlackjackRules())
    }

    @Test("Applying a preset sets its rules; custom rules match no preset")
    func presets() {
        let store = ActiveRulesStore(defaults: TestDefaults.make())
        store.apply(.singleDeckSixFive)
        #expect(store.matchingPreset == .singleDeckSixFive)
        store.rules.maxSplitHands = 2
        #expect(store.matchingPreset == nil)
    }
}

@Suite("Rules display")
struct RulesDisplayTests {

    @Test("Hub summary", arguments: [
        (BlackjackRules(), "6D · S17 · DAS · 3:2"),
        (RulePreset.downtownVegas.rules, "2D · H17 · DAS · 3:2 · LS"),
        (RulePreset.singleDeckSixFive.rules, "1D · H17 · NDAS · 6:5"),
        (RulePreset.europeanNoHoleCard.rules, "6D · S17 · DAS · 3:2 · ENHC"),
    ])
    func summary(_ rules: BlackjackRules, _ expected: String) {
        #expect(RulesSummary.short(rules) == expected)
    }

    @Test("Custom rules are named Custom")
    func presetName() {
        #expect(RulesSummary.presetName(nil) == "Custom")
        #expect(RulesSummary.presetName(.vegasStrip) == "Vegas Strip")
    }

    @Test("Rules JSON round-trips")
    func roundTrip() throws {
        for preset in RulePreset.allCases {
            #expect(try RulesCoding.decode(RulesCoding.encode(preset.rules)) == preset.rules)
        }
    }
}
```

Create `BJSTests/PreferencesTests.swift`:

```swift
import BJSCore
import Foundation
import Testing
@testable import BJS

@MainActor
@Suite("Preferences")
struct PreferencesTests {

    @Test("Defaults: 3.0 s timer, Exact, check every 4 rounds, haptics on")
    func defaults() {
        let prefs = Preferences(defaults: TestDefaults.make())
        #expect(prefs.speedTimerSeconds == 3.0)
        #expect(prefs.trueCountConvention == .exact)
        #expect(prefs.shoeCheckEveryRounds == 4)
        #expect(prefs.hapticsEnabled)
    }

    @Test("Changes persist under the spec's @AppStorage keys")
    func persists() {
        let defaults = TestDefaults.make()
        let prefs = Preferences(defaults: defaults)
        prefs.speedTimerSeconds = 2.5
        prefs.trueCountConvention = .floor
        prefs.shoeCheckEveryRounds = 6
        prefs.hapticsEnabled = false

        #expect(defaults.double(forKey: "speedTimerSeconds") == 2.5)
        #expect(defaults.string(forKey: "trueCountConvention") == "floor")
        #expect(defaults.integer(forKey: "shoeCheckFrequency") == 6)
        #expect(defaults.bool(forKey: "hapticsEnabled") == false)

        let reloaded = Preferences(defaults: defaults)
        #expect(reloaded.speedTimerSeconds == 2.5)
        #expect(reloaded.trueCountConvention == .floor)
        #expect(reloaded.shoeCheckEveryRounds == 6)
        #expect(!reloaded.hapticsEnabled)
    }

    @Test("Speed timer is clamped to 1–5 s")
    func clamp() {
        let prefs = Preferences(defaults: TestDefaults.make())
        prefs.speedTimerSeconds = 0.2
        #expect(prefs.speedTimerSeconds == 1)
        prefs.speedTimerSeconds = 9
        #expect(prefs.speedTimerSeconds == 5)
    }

    @Test("Invalid stored values fall back to defaults")
    func invalidStored() {
        let defaults = TestDefaults.make()
        defaults.set("banana", forKey: "trueCountConvention")
        defaults.set(0, forKey: "shoeCheckFrequency")
        defaults.set(42.0, forKey: "speedTimerSeconds")
        let prefs = Preferences(defaults: defaults)
        #expect(prefs.trueCountConvention == .exact)
        #expect(prefs.shoeCheckEveryRounds == 4)
        #expect(prefs.speedTimerSeconds == 5)
    }

    @Test("Picker options stay inside their ranges")
    func options() {
        #expect(Preferences.speedTimerOptions.first == 1.0)
        #expect(Preferences.speedTimerOptions.last == 5.0)
        #expect(Preferences.speedTimerOptions.contains(Preferences.defaultSpeedTimerSeconds))
        #expect(Preferences.shoeCheckOptions.allSatisfy { Preferences.shoeCheckRange.contains($0) })
        #expect(Preferences.shoeCheckOptions.contains(Preferences.defaultShoeCheckEveryRounds))
    }
}
```

- [ ] **Step 2: Implement**

Create `BJS/Shared/AppLog.swift`:

```swift
import os

/// App-wide loggers (subsystem = bundle id).
enum AppLog {
    static let persistence = Logger(subsystem: "com.bjs.app", category: "persistence")
    static let settings = Logger(subsystem: "com.bjs.app", category: "settings")
}
```

Create `BJS/Shared/RulesCoding.swift`:

```swift
import BJSCore
import Foundation

/// JSON encoding for `BlackjackRules`, shared by `ActiveRulesStore` (`activeRules` key)
/// and `Session.rulesJSON`.
enum RulesCoding {
    static func encode(_ rules: BlackjackRules) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            return try encoder.encode(rules)
        } catch {
            // BlackjackRules holds only enums, Bools and Ints; encoding cannot fail in practice.
            preconditionFailure("BlackjackRules failed to encode: \(error)")
        }
    }

    static func decode(_ data: Data) throws -> BlackjackRules {
        try JSONDecoder().decode(BlackjackRules.self, from: data)
    }
}
```

Create `BJS/Shared/RulesDisplay.swift`:

```swift
import BJSCore

// Display text for rules and preferences. Presentation only; the values live in BJSCore.

extension BlackjackRules.DeckCount {
    var displayName: String { rawValue == 1 ? "1 deck" : "\(rawValue) decks" }
    var shortName: String { "\(rawValue)D" }
}

extension BlackjackRules.DealerSoft17 {
    var displayName: String {
        switch self {
        case .stands: return "Stands"
        case .hits: return "Hits"
        }
    }

    var shortName: String {
        switch self {
        case .stands: return "S17"
        case .hits: return "H17"
        }
    }
}

extension BlackjackRules.BlackjackPayout {
    var displayName: String {
        switch self {
        case .threeToTwo: return "3:2"
        case .sixToFive: return "6:5"
        case .twoToOne: return "2:1"
        }
    }
}

extension BlackjackRules.SurrenderRule {
    var displayName: String {
        switch self {
        case .none: return "None"
        case .late: return "Late"
        case .early: return "Early"
        }
    }

    /// nil when there is no surrender.
    var shortName: String? {
        switch self {
        case .none: return nil
        case .late: return "LS"
        case .early: return "ES"
        }
    }
}

extension BlackjackRules.DoubleRestriction {
    var displayName: String {
        switch self {
        case .anyTwo: return "Any two cards"
        case .nineToEleven: return "9–11 only"
        case .tenToEleven: return "10–11 only"
        }
    }
}

extension BlackjackRules.PeekRule {
    var displayName: String {
        switch self {
        case .americanPeek: return "Peeks (US)"
        case .europeanNoPeek: return "No hole card"
        }
    }
}

extension TrueCountConvention {
    var displayName: String {
        switch self {
        case .exact: return "Exact"
        case .floor: return "Floor"
        case .truncate: return "Truncate"
        }
    }
}

enum RulesSummary {
    /// Compact rules line for the hub header, e.g. "6D · H17 · DAS · 3:2".
    /// Surrender ("LS"/"ES") and no-hole-card ("ENHC") are appended only when they apply.
    static func short(_ rules: BlackjackRules) -> String {
        var parts = [
            rules.deckCount.shortName,
            rules.dealerSoft17.shortName,
            rules.doubleAfterSplit ? "DAS" : "NDAS",
            rules.blackjackPayout.displayName,
        ]
        if let surrender = rules.surrenderRule.shortName { parts.append(surrender) }
        if rules.peekRule == .europeanNoPeek { parts.append("ENHC") }
        return parts.joined(separator: " · ")
    }

    /// Preset name, or "Custom" when the rules match no preset.
    static func presetName(_ preset: RulePreset?) -> String {
        preset?.displayName ?? "Custom"
    }
}
```

Create `BJS/Shared/ActiveRulesStore.swift`. `rules` is a computed property over a tracked private stored property, so every write (including `$store.rules.deckCount` bindings) is observed and saved without relying on `didSet` inside `@Observable`:

```swift
import BJSCore
import Foundation
import Observation

/// The one app-wide active rule set (spec §3 rule 4), injected through the environment.
///
/// Persisted as JSON `Data` under the `activeRules` key — the same key and type
/// `@AppStorage("activeRules") var data: Data` would use. `@AppStorage` itself cannot
/// live inside an `@Observable` class (it only publishes changes from inside a View),
/// so the store reads and writes `UserDefaults` directly.
@MainActor
@Observable
final class ActiveRulesStore {
    nonisolated static let storageKey = "activeRules"

    private let defaults: UserDefaults
    private var storedRules: BlackjackRules

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.storedRules = Self.load(from: defaults)
    }

    /// Setting the rules saves them immediately.
    var rules: BlackjackRules {
        get { storedRules }
        set {
            storedRules = newValue
            defaults.set(RulesCoding.encode(newValue), forKey: Self.storageKey)
        }
    }

    /// The preset these rules equal, or nil for a custom rule set.
    var matchingPreset: RulePreset? { RulePreset.matching(rules) }

    func apply(_ preset: RulePreset) {
        rules = preset.rules
    }

    /// Missing data → defaults. Undecodable data → defaults, logged (spec §6 error handling).
    private static func load(from defaults: UserDefaults) -> BlackjackRules {
        guard let data = defaults.data(forKey: storageKey) else { return BlackjackRules() }
        do {
            return try RulesCoding.decode(data)
        } catch {
            let message = String(describing: error)
            AppLog.settings.error("activeRules failed to decode; using defaults. \(message, privacy: .public)")
            return BlackjackRules()
        }
    }
}
```

Create `BJS/Shared/Preferences.swift`:

```swift
import BJSCore
import Foundation
import Observation

/// User preferences (spec §5 Settings, §6 `@AppStorage` keys), injected through the environment.
///
/// Stored in `UserDefaults` under the spec's key names with `@AppStorage`-compatible
/// types (Double, String raw value, Int, Bool). Invalid stored values fall back to the
/// default and are logged.
@MainActor
@Observable
final class Preferences {
    enum Key {
        static let speedTimerSeconds = "speedTimerSeconds"
        static let trueCountConvention = "trueCountConvention"
        static let shoeCheckFrequency = "shoeCheckFrequency"
        static let hapticsEnabled = "hapticsEnabled"
    }

    nonisolated static let defaultSpeedTimerSeconds = 3.0
    nonisolated static let speedTimerRange: ClosedRange<Double> = 1...5
    /// Picker choices: 1.0 s to 5.0 s in 0.5 s steps.
    nonisolated static let speedTimerOptions: [Double] = Array(stride(from: 1.0, through: 5.0, by: 0.5))

    nonisolated static let defaultShoeCheckEveryRounds = 4
    nonisolated static let shoeCheckRange: ClosedRange<Int> = 2...8
    /// Picker choices: a count check about once every N rounds.
    nonisolated static let shoeCheckOptions: [Int] = [2, 3, 4, 6, 8]

    private let defaults: UserDefaults
    private var storedSpeedTimerSeconds: Double
    private var storedTrueCountConvention: TrueCountConvention
    private var storedShoeCheckEveryRounds: Int
    private var storedHapticsEnabled: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let seconds = defaults.object(forKey: Key.speedTimerSeconds) as? Double {
            storedSpeedTimerSeconds = Self.clampedSpeedTimer(seconds)
        } else {
            storedSpeedTimerSeconds = Self.defaultSpeedTimerSeconds
        }

        if let raw = defaults.string(forKey: Key.trueCountConvention) {
            if let convention = TrueCountConvention(rawValue: raw) {
                storedTrueCountConvention = convention
            } else {
                AppLog.settings.error("Unknown trueCountConvention '\(raw, privacy: .public)'; using exact.")
                storedTrueCountConvention = .exact
            }
        } else {
            storedTrueCountConvention = .exact
        }

        if let rounds = defaults.object(forKey: Key.shoeCheckFrequency) as? Int,
           Self.shoeCheckRange.contains(rounds) {
            storedShoeCheckEveryRounds = rounds
        } else {
            storedShoeCheckEveryRounds = Self.defaultShoeCheckEveryRounds
        }

        storedHapticsEnabled = defaults.object(forKey: Key.hapticsEnabled) as? Bool ?? true
    }

    /// Speed-mode countdown per decision, 1–5 s (default 3.0).
    var speedTimerSeconds: Double {
        get { storedSpeedTimerSeconds }
        set {
            let value = Self.clampedSpeedTimer(newValue)
            storedSpeedTimerSeconds = value
            defaults.set(value, forKey: Key.speedTimerSeconds)
        }
    }

    /// How true-count answers are graded (default Exact).
    var trueCountConvention: TrueCountConvention {
        get { storedTrueCountConvention }
        set {
            storedTrueCountConvention = newValue
            defaults.set(newValue.rawValue, forKey: Key.trueCountConvention)
        }
    }

    /// Shoe Sim asks for the count about once every this many rounds (default 4).
    var shoeCheckEveryRounds: Int {
        get { storedShoeCheckEveryRounds }
        set {
            let value = min(max(newValue, Self.shoeCheckRange.lowerBound), Self.shoeCheckRange.upperBound)
            storedShoeCheckEveryRounds = value
            defaults.set(value, forKey: Key.shoeCheckFrequency)
        }
    }

    var hapticsEnabled: Bool {
        get { storedHapticsEnabled }
        set {
            storedHapticsEnabled = newValue
            defaults.set(newValue, forKey: Key.hapticsEnabled)
        }
    }

    private nonisolated static func clampedSpeedTimer(_ seconds: Double) -> Double {
        min(max(seconds, speedTimerRange.lowerBound), speedTimerRange.upperBound)
    }
}
```

- [ ] **Step 3: Local pre-checks**

`RulesCoding` and `RulesDisplay` import only Foundation and BJSCore:

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
(cd BJSCore && swift build 2>&1 | tail -1)
swiftc -typecheck -I BJSCore/.build/debug/Modules BJS/Shared/RulesCoding.swift BJS/Shared/RulesDisplay.swift
swiftc -parse BJS/Shared/*.swift BJSTests/TestDefaults.swift BJSTests/ActiveRulesStoreTests.swift BJSTests/PreferencesTests.swift
```

Expected: the build line, then no output. (While writing this plan, both stores were also compiled in Swift 6 mode on Linux against a stand-in `Logger` and exercised: persistence, corrupt-JSON fallback, clamping and invalid stored values all behaved as the tests expect.)

- [ ] **Step 4: Commit**

```bash
git add BJS/Shared BJSTests/TestDefaults.swift BJSTests/ActiveRulesStoreTests.swift BJSTests/PreferencesTests.swift
git commit -m "feat(app): ActiveRulesStore and Preferences backed by UserDefaults

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

- [ ] **Step 5: CI verification (controller)**

Expected: green; 42 unit tests.

---

### Task 7: SwiftData SchemaV1, migration plan, mappers and reset

**Files:**
- Create: `BJS/Persistence/SchemaV1.swift`, `PersistenceController.swift`, `ProgressMapper.swift`, `ProgressReset.swift`
- Test: `BJSTests/PersistenceTests.swift`

**Interfaces:**
- Consumes: `RulesCoding`, `AppLog` (Task 6); BJSCore `TrainingModule`, `HandType`, `TrainingCell`, `CountKind`, `SessionSample`, `DecisionSample`, `CountSample`, `ProgressStats`
- Produces:
  - `enum SchemaV1: VersionedSchema` (version 1.0.0) with `@Model` classes `Session`, `DecisionRecord`, `CountCheckRecord` (fields per spec §6; relationships `Session.decisions` and `Session.countCheckRecords`, cascade delete; inverse `session: Session?`)
  - top-level `typealias Session / DecisionRecord / CountCheckRecord = SchemaV1.…`
  - `enum BJSMigrationPlan: SchemaMigrationPlan` (schemas `[SchemaV1]`, no stages)
  - `enum PersistenceController { static func makeContainer(inMemory:) throws -> ModelContainer; static func makeAppContainer(inMemory:) -> ModelContainer }`
  - `enum ProgressMapper { sessionSample(_:), decisionSample(_:), countSample(_:), sessionSamples(_:), decisionSamples(_:), countSamples(_:) }` — optional results; unknown strings are skipped and logged
  - `enum ProgressReset { static func deleteAllProgress(in: ModelContext) throws }`

- [ ] **Step 1: Write the tests**

Create `BJSTests/PersistenceTests.swift`. Every test builds its own in-memory container **before** creating any model object, and the suite is `.serialized`:

```swift
import BJSCore
import Foundation
import SwiftData
import Testing
@testable import BJS

/// Every test creates its in-memory container before creating any model object
/// (SwiftData needs a loaded container for a model type before instances exist).
@MainActor
@Suite("Persistence (SchemaV1)", .serialized)
struct PersistenceTests {

    private static let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func makeSession(module: TrainingModule = .strategy) -> Session {
        Session(module: module.rawValue, mode: "test", startedAt: Self.start,
                endedAt: Self.start.addingTimeInterval(600), rulesJSON: RulesCoding.encode(BlackjackRules()),
                decisionCount: 2, correctDecisions: 1, countChecks: 1, correctCountChecks: 1,
                bestStreak: 1, meanResponseMs: 950)
    }

    private func makeDecision(secondsAfterStart: TimeInterval, isCorrect: Bool = true) -> DecisionRecord {
        DecisionRecord(handNumber: 1, handType: "soft", playerValue: 18, dealerUpcard: 11,
                       chosenAction: "stand", correctAction: "hit", isCorrect: isCorrect, responseMs: 1200,
                       decidedAt: Self.start.addingTimeInterval(secondsAfterStart))
    }

    private func makeCountCheck(secondsAfterStart: TimeInterval) -> CountCheckRecord {
        CountCheckRecord(kind: "true", expected: 2.5, answered: 2.0, isCorrect: false, responseMs: 3000,
                         cardsSeen: 104, answeredAt: Self.start.addingTimeInterval(secondsAfterStart))
    }

    @Test("Schema is version 1.0.0 with three models and no migration stages")
    func schemaShape() {
        #expect(SchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(SchemaV1.models.count == 3)
        #expect(BJSMigrationPlan.schemas.count == 1)
        #expect(BJSMigrationPlan.stages.isEmpty)
    }

    @Test("A session with records saves and fetches back")
    func roundTrip() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let session = makeSession()
        context.insert(session)
        session.decisions.append(makeDecision(secondsAfterStart: 10))
        session.decisions.append(makeDecision(secondsAfterStart: 20, isCorrect: false))
        session.countCheckRecords.append(makeCountCheck(secondsAfterStart: 30))
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<Session>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.decisions.count == 2)
        #expect(sessions.first?.countCheckRecords.count == 1)
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 2)
        let rules = try RulesCoding.decode(try #require(sessions.first).rulesJSON)
        #expect(rules == BlackjackRules())
    }

    @Test("Deleting a session cascades to its records")
    func cascade() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let session = makeSession()
        context.insert(session)
        session.decisions.append(makeDecision(secondsAfterStart: 10))
        session.countCheckRecords.append(makeCountCheck(secondsAfterStart: 20))
        try context.save()

        context.delete(session)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Session>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CountCheckRecord>()) == 0)
    }

    @Test("Reset progress deletes every session and record")
    func reset() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        for module in [TrainingModule.strategy, .countingRC, .shoe] {
            let session = makeSession(module: module)
            context.insert(session)
            session.decisions.append(makeDecision(secondsAfterStart: 10))
            session.countCheckRecords.append(makeCountCheck(secondsAfterStart: 20))
        }
        context.insert(makeDecision(secondsAfterStart: 99))   // orphan
        try context.save()

        try ProgressReset.deleteAllProgress(in: context)

        #expect(try context.fetchCount(FetchDescriptor<Session>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CountCheckRecord>()) == 0)
    }

    @Test("Decision mapper uses the record's own decidedAt, not the session start")
    func decisionMapper() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let record = makeDecision(secondsAfterStart: 42, isCorrect: false)
        container.mainContext.insert(record)
        let sample = try #require(ProgressMapper.decisionSample(record))
        #expect(sample.date == Self.start.addingTimeInterval(42))
        #expect(sample.cell == TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 11))
        #expect(sample.isCorrect == false)
        #expect(sample.responseMs == 1200)
    }

    @Test("Decisions in one session keep their order through the mapper")
    func decisionOrder() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let session = makeSession()
        context.insert(session)
        session.decisions.append(makeDecision(secondsAfterStart: 10, isCorrect: false))
        session.decisions.append(makeDecision(secondsAfterStart: 20))
        session.decisions.append(makeDecision(secondsAfterStart: 30))
        try context.save()

        let samples = ProgressMapper.decisionSamples(try context.fetch(FetchDescriptor<DecisionRecord>()))
        // Streak counts back from the newest: two correct, then the miss.
        #expect(ProgressStats.currentStreak(samples) == 2)
    }

    @Test("Count mapper uses answeredAt and the kind raw value")
    func countMapper() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let record = makeCountCheck(secondsAfterStart: 7)
        container.mainContext.insert(record)
        let sample = try #require(ProgressMapper.countSample(record))
        #expect(sample.date == Self.start.addingTimeInterval(7))
        #expect(sample.kind == .trueCount)
        #expect(sample.expected == 2.5)
        #expect(sample.answered == 2.0)
        #expect(!sample.isCorrect)
        #expect(sample.responseMs == 3000)
    }

    @Test("Session mapper copies the cached summary")
    func sessionMapper() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let session = makeSession(module: .countingTC)
        container.mainContext.insert(session)
        let sample = try #require(ProgressMapper.sessionSample(session))
        #expect(sample.id == session.id)
        #expect(sample.module == .countingTC)
        #expect(sample.startedAt == Self.start)
        #expect(sample.decisionCount == 2)
        #expect(sample.correctDecisions == 1)
        #expect(sample.countChecks == 1)
        #expect(sample.correctCountChecks == 1)
    }

    @Test("Unknown enum strings are skipped, not crashed on")
    func unknownStrings() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let session = makeSession()
        context.insert(session)
        session.module = "poker"
        #expect(ProgressMapper.sessionSample(session) == nil)

        let decision = makeDecision(secondsAfterStart: 1)
        context.insert(decision)
        decision.handType = "weird"
        #expect(ProgressMapper.decisionSample(decision) == nil)

        let check = makeCountCheck(secondsAfterStart: 1)
        context.insert(check)
        check.kind = "sideways"
        #expect(ProgressMapper.countSample(check) == nil)
    }
}
```

- [ ] **Step 2: Implement the schema**

Create `BJS/Persistence/SchemaV1.swift`:

```swift
import Foundation
import SwiftData

/// SwiftData schema, version 1 (spec §6). Future changes add `SchemaV2` plus a
/// migration stage in `BJSMigrationPlan`; never edit these models in place once shipped.
enum SchemaV1: VersionedSchema {
    nonisolated static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    nonisolated static var models: [any PersistentModel.Type] {
        [Session.self, DecisionRecord.self, CountCheckRecord.self]
    }

    /// One finished (or partially saved) training session with its cached summary.
    @Model
    final class Session {
        var id: UUID
        /// `TrainingModule` raw value: strategy | countingRC | countingTC | shoe.
        var module: String
        var mode: String?
        var startedAt: Date
        var endedAt: Date
        /// The `BlackjackRules` the session ran under, as `RulesCoding` JSON.
        var rulesJSON: Data

        var decisionCount: Int
        var correctDecisions: Int
        var countChecks: Int
        var correctCountChecks: Int
        var bestStreak: Int
        var meanResponseMs: Double?

        @Relationship(deleteRule: .cascade, inverse: \DecisionRecord.session)
        var decisions: [DecisionRecord] = []

        /// Named `countCheckRecords` because the spec's cached `countChecks: Int` already uses that name.
        @Relationship(deleteRule: .cascade, inverse: \CountCheckRecord.session)
        var countCheckRecords: [CountCheckRecord] = []

        init(id: UUID = UUID(), module: String, mode: String? = nil, startedAt: Date, endedAt: Date,
             rulesJSON: Data, decisionCount: Int = 0, correctDecisions: Int = 0, countChecks: Int = 0,
             correctCountChecks: Int = 0, bestStreak: Int = 0, meanResponseMs: Double? = nil) {
            self.id = id
            self.module = module
            self.mode = mode
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.rulesJSON = rulesJSON
            self.decisionCount = decisionCount
            self.correctDecisions = correctDecisions
            self.countChecks = countChecks
            self.correctCountChecks = correctCountChecks
            self.bestStreak = bestStreak
            self.meanResponseMs = meanResponseMs
        }
    }

    /// One graded strategy decision.
    @Model
    final class DecisionRecord {
        var handNumber: Int
        /// `HandType` raw value: hard | soft | pair.
        var handType: String
        /// Hard/soft total, or the pair's rank value (2...11, 11 = aces), as in `TrainingCell`.
        var playerValue: Int
        /// 2...11, where 11 = ace, as in `TrainingCell`.
        var dealerUpcard: Int
        /// `Action` raw value, or "timeout".
        var chosenAction: String
        var correctAction: String
        var isCorrect: Bool
        var responseMs: Int?
        /// When the decision was made. Copied into `DecisionSample.date`; never the session's start.
        var decidedAt: Date
        var session: Session?

        init(handNumber: Int, handType: String, playerValue: Int, dealerUpcard: Int,
             chosenAction: String, correctAction: String, isCorrect: Bool, responseMs: Int?,
             decidedAt: Date) {
            self.handNumber = handNumber
            self.handType = handType
            self.playerValue = playerValue
            self.dealerUpcard = dealerUpcard
            self.chosenAction = chosenAction
            self.correctAction = correctAction
            self.isCorrect = isCorrect
            self.responseMs = responseMs
            self.decidedAt = decidedAt
        }
    }

    /// One graded running- or true-count check.
    @Model
    final class CountCheckRecord {
        /// `CountKind` raw value: running | true.
        var kind: String
        var expected: Double
        var answered: Double
        var isCorrect: Bool
        var responseMs: Int?
        var cardsSeen: Int
        /// When the answer was given. Copied into `CountSample.date`.
        var answeredAt: Date
        var session: Session?

        init(kind: String, expected: Double, answered: Double, isCorrect: Bool, responseMs: Int?,
             cardsSeen: Int, answeredAt: Date) {
            self.kind = kind
            self.expected = expected
            self.answered = answered
            self.isCorrect = isCorrect
            self.responseMs = responseMs
            self.cardsSeen = cardsSeen
            self.answeredAt = answeredAt
        }
    }
}

/// The current model types. Code outside `Persistence/` uses these names.
typealias Session = SchemaV1.Session
typealias DecisionRecord = SchemaV1.DecisionRecord
typealias CountCheckRecord = SchemaV1.CountCheckRecord

/// Migration plan. V1 is the first shipped schema, so there are no stages yet.
enum BJSMigrationPlan: SchemaMigrationPlan {
    nonisolated static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    nonisolated static var stages: [MigrationStage] { [] }
}
```

- [ ] **Step 3: Implement the container factory, mappers and reset**

Create `BJS/Persistence/PersistenceController.swift`:

```swift
import Foundation
import SwiftData

/// Builds the app's SwiftData container on `SchemaV1` with `BJSMigrationPlan`.
enum PersistenceController {
    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        // In-memory stores get a unique name so parallel tests never share one.
        let configuration = ModelConfiguration(inMemory ? UUID().uuidString : nil,
                                               schema: schema,
                                               isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, migrationPlan: BJSMigrationPlan.self,
                                  configurations: configuration)
    }

    /// The app's container. If the on-disk store cannot open, log it and fall back to
    /// an in-memory store so the app still launches (progress is not saved that run).
    static func makeAppContainer(inMemory: Bool) -> ModelContainer {
        do {
            return try makeContainer(inMemory: inMemory)
        } catch {
            let message = String(describing: error)
            AppLog.persistence.error("Opening the store failed; using memory. \(message, privacy: .public)")
            do {
                return try makeContainer(inMemory: true)
            } catch {
                fatalError("Could not create even an in-memory ModelContainer: \(error)")
            }
        }
    }
}
```

Create `BJS/Persistence/ProgressMapper.swift`. The mappers copy `decidedAt` / `answeredAt` into the sample's `date` (spec §6, decided 2026-09-23); `decisionOrder` in the tests guards the streak consequence:

```swift
import BJSCore
import Foundation

/// SwiftData records → the plain `Sendable` samples `ProgressStats` and `WeakSpotWeights` use (spec §6).
///
/// Each sample's `date` is the record's own timestamp (`decidedAt`, `answeredAt`),
/// never the session's `startedAt`. Records with unknown enum strings are skipped and logged.
enum ProgressMapper {
    static func sessionSample(_ session: Session) -> SessionSample? {
        guard let module = TrainingModule(rawValue: session.module) else {
            let raw = session.module
            AppLog.persistence.error("Skipping session with unknown module '\(raw, privacy: .public)'")
            return nil
        }
        return SessionSample(id: session.id, module: module, startedAt: session.startedAt,
                             decisionCount: session.decisionCount, correctDecisions: session.correctDecisions,
                             countChecks: session.countChecks, correctCountChecks: session.correctCountChecks)
    }

    static func decisionSample(_ record: DecisionRecord) -> DecisionSample? {
        guard let handType = HandType(rawValue: record.handType) else {
            let raw = record.handType
            AppLog.persistence.error("Skipping decision with unknown hand type '\(raw, privacy: .public)'")
            return nil
        }
        let cell = TrainingCell(handType: handType, playerValue: record.playerValue,
                                dealerUpcard: record.dealerUpcard)
        return DecisionSample(date: record.decidedAt, cell: cell, isCorrect: record.isCorrect,
                              responseMs: record.responseMs)
    }

    static func countSample(_ record: CountCheckRecord) -> CountSample? {
        guard let kind = CountKind(rawValue: record.kind) else {
            let raw = record.kind
            AppLog.persistence.error("Skipping count check with unknown kind '\(raw, privacy: .public)'")
            return nil
        }
        return CountSample(date: record.answeredAt, kind: kind, expected: record.expected,
                           answered: record.answered, isCorrect: record.isCorrect,
                           responseMs: record.responseMs)
    }

    static func sessionSamples(_ sessions: [Session]) -> [SessionSample] {
        sessions.compactMap(sessionSample)
    }

    static func decisionSamples(_ records: [DecisionRecord]) -> [DecisionSample] {
        records.compactMap(decisionSample)
    }

    static func countSamples(_ records: [CountCheckRecord]) -> [CountSample] {
        records.compactMap(countSample)
    }
}
```

Create `BJS/Persistence/ProgressReset.swift`:

```swift
import Foundation
import SwiftData

/// Settings → Reset progress: deletes every session and record. Rules and preferences
/// live in `UserDefaults` and are untouched.
enum ProgressReset {
    static func deleteAllProgress(in context: ModelContext) throws {
        // Deleting a Session cascades to its records; orphaned records are removed too.
        for session in try context.fetch(FetchDescriptor<Session>()) {
            context.delete(session)
        }
        for record in try context.fetch(FetchDescriptor<DecisionRecord>()) {
            context.delete(record)
        }
        for record in try context.fetch(FetchDescriptor<CountCheckRecord>()) {
            context.delete(record)
        }
        try context.save()
    }
}
```

- [ ] **Step 4: Local pre-checks**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
swiftc -parse BJS/Persistence/*.swift BJSTests/PersistenceTests.swift
```

Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add BJS/Persistence BJSTests/PersistenceTests.swift
git commit -m "feat(app): SwiftData SchemaV1 with migration plan, sample mappers and reset

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

- [ ] **Step 6: CI verification (controller)**

Expected: green; 51 unit tests. If `schemaShape` fails to compile because `Schema.Version` is not `Equatable` on the runner's SDK, replace that line with `#expect(SchemaV1.versionIdentifier.major == 1 && SchemaV1.versionIdentifier.minor == 0 && SchemaV1.versionIdentifier.patch == 0)` in the fix commit.

---

### Task 8: App wiring, RootTabView and the hub shell

**Files:**
- Create: `BJS/App/LaunchConfiguration.swift`, `BJS/App/PlaceholderScreen.swift`, `BJS/Features/Hub/HubRoute.swift`, `HubStats.swift`, `HubView.swift`
- Modify: `BJS/App/BJSApp.swift`, `BJS/App/RootTabView.swift`, `BJSTests/AppShellTests.swift`
- Test: `BJSTests/HubStatsTests.swift`, `BJSTests/AppShellTests.swift`

**Interfaces:**
- Consumes: everything from Tasks 1–7
- Produces:
  - `struct LaunchConfiguration { init(environment:); isUITesting; galleryPageName; static current; makeUserDefaults(); keys BJS_UI_TESTING, BJS_GALLERY_PAGE }`
  - `struct PlaceholderScreen: View { init(title:) }` (identifier `placeholder.title`)
  - `enum HubRoute: CaseIterable { strategy, counting, shoeSim, edge }` with `title`, `subtitle`
  - `struct HubStats { strategyAccuracy: Double?; countAccuracy: Double?; strategyStreak: Int; static make(sessions:decisions:now:calendar:); static percentText(_:) }`
  - `struct HubView<Destination: View>: View { init(onShowRules:, @ViewBuilder destination: (HubRoute) -> Destination) }` (identifiers `hub.rulesSummary`, `hub.title`, `hub.tile.<route>`)
  - `RootTabView`: Train = `HubView` (tiles → `PlaceholderScreen`), Progress = placeholder, Settings = placeholder until Task 9
  - `BJSApp` builds the container (in-memory under UI testing), `ActiveRulesStore`, `Preferences`, and injects them

- [ ] **Step 1: Write the tests**

Create `BJSTests/HubStatsTests.swift`:

```swift
import BJSCore
import Foundation
import Testing
@testable import BJS

@Suite("HubStats")
struct HubStatsTests {

    private static let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private static let calendar = Calendar(identifier: .gregorian)

    private func daysAgo(_ days: Int) -> Date {
        Self.calendar.date(byAdding: .day, value: -days, to: Self.now)!
    }

    private func session(_ module: TrainingModule, daysAgo days: Int, decisions: (Int, Int) = (0, 0),
                         checks: (Int, Int) = (0, 0)) -> SessionSample {
        SessionSample(id: UUID(), module: module, startedAt: daysAgo(days),
                      decisionCount: decisions.0, correctDecisions: decisions.1,
                      countChecks: checks.0, correctCountChecks: checks.1)
    }

    private func decision(secondsAgo: TimeInterval, correct: Bool) -> DecisionSample {
        DecisionSample(date: Self.now.addingTimeInterval(-secondsAgo),
                       cell: TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10),
                       isCorrect: correct, responseMs: nil)
    }

    @Test("No history: no accuracy, zero streak, dashes on screen")
    func empty() {
        let stats = HubStats.make(sessions: [], decisions: [], now: Self.now, calendar: Self.calendar)
        #expect(stats == HubStats(strategyAccuracy: nil, countAccuracy: nil, strategyStreak: 0))
        #expect(HubStats.percentText(stats.strategyAccuracy) == "—")
    }

    @Test("Last-30-day accuracy combines the right modules and drops older sessions")
    func accuracy() {
        let sessions = [
            session(.strategy, daysAgo: 2, decisions: (10, 8)),
            session(.shoe, daysAgo: 5, decisions: (2, 1), checks: (4, 3)),
            session(.strategy, daysAgo: 40, decisions: (10, 0)),      // outside the window
            session(.countingRC, daysAgo: 1, checks: (8, 5)),
        ]
        let stats = HubStats.make(sessions: sessions, decisions: [], now: Self.now, calendar: Self.calendar)
        #expect(stats.strategyAccuracy == 9.0 / 12.0)                  // (8 + 1) / (10 + 2)
        #expect(stats.countAccuracy == 8.0 / 12.0)                     // (3 + 5) / (4 + 8)
        #expect(HubStats.percentText(stats.strategyAccuracy) == "75%")
        #expect(HubStats.percentText(stats.countAccuracy) == "67%")
    }

    @Test("Streak counts consecutive correct decisions back from the newest")
    func streak() {
        let decisions = [
            decision(secondsAgo: 50, correct: true),
            decision(secondsAgo: 40, correct: false),
            decision(secondsAgo: 30, correct: true),
            decision(secondsAgo: 20, correct: true),
            decision(secondsAgo: 10, correct: true),
        ]
        let stats = HubStats.make(sessions: [], decisions: decisions.shuffled(), now: Self.now,
                                  calendar: Self.calendar)
        #expect(stats.strategyStreak == 3)
    }

    @Test("Percent text rounds to whole percent")
    func percent() {
        #expect(HubStats.percentText(1) == "100%")
        #expect(HubStats.percentText(0) == "0%")
        #expect(HubStats.percentText(0.875) == "88%")
    }
}
```

Replace `BJSTests/AppShellTests.swift` with:

```swift
import Testing
@testable import BJS

@MainActor
struct AppShellTests {

    @Test("App has exactly three tabs: Train, Progress, Settings")
    func tabsInOrder() {
        #expect(AppTab.allCases.map(\.rawValue) == ["Train", "Progress", "Settings"])
    }

    @Test("Every tab has an SF Symbol")
    func tabsHaveIcons() {
        for tab in AppTab.allCases {
            #expect(!tab.systemImage.isEmpty)
        }
    }

    @Test("Hub tiles: Strategy, Counting, Shoe Sim, Edge")
    func hubTiles() {
        #expect(HubRoute.allCases.map(\.title) == ["Strategy", "Counting", "Shoe Sim", "Edge"])
        #expect(HubRoute.allCases.allSatisfy { !$0.subtitle.isEmpty })
    }
}

@Suite("LaunchConfiguration")
struct LaunchConfigurationTests {

    @Test("Plain launch: not UI testing, no gallery")
    func plain() {
        let config = LaunchConfiguration(environment: [:])
        #expect(!config.isUITesting)
        #expect(config.galleryPageName == nil)
    }

    @Test("UI-test launch reads both switches")
    func uiTesting() {
        let config = LaunchConfiguration(environment: ["BJS_UI_TESTING": "1", "BJS_GALLERY_PAGE": "cards"])
        #expect(config.isUITesting)
        #expect(config.galleryPageName == "cards")
    }

    @Test("UI testing uses a wiped, separate defaults suite")
    func uiDefaults() {
        let config = LaunchConfiguration(environment: ["BJS_UI_TESTING": "1"])
        let first = config.makeUserDefaults()
        first.set(true, forKey: "leftover")
        let second = config.makeUserDefaults()
        #expect(second.object(forKey: "leftover") == nil)
    }
}
```

- [ ] **Step 2: Implement launch configuration and the placeholder**

Create `BJS/App/LaunchConfiguration.swift`:

```swift
import Foundation

/// Launch-time switches read from the process environment. UI tests set these through
/// `XCUIApplication.launchEnvironment`.
struct LaunchConfiguration: Equatable, Sendable {
    /// "1" → in-memory SwiftData store and a wiped, separate UserDefaults suite.
    static let uiTestingKey = "BJS_UI_TESTING"
    /// A `GalleryPage` raw value → DEBUG builds show that component-gallery page instead of the app.
    static let galleryPageKey = "BJS_GALLERY_PAGE"
    static let uiTestingDefaultsSuite = "com.bjs.app.uitesting"

    let isUITesting: Bool
    let galleryPageName: String?

    init(environment: [String: String]) {
        isUITesting = environment[Self.uiTestingKey] == "1"
        galleryPageName = environment[Self.galleryPageKey]
    }

    static var current: LaunchConfiguration {
        LaunchConfiguration(environment: ProcessInfo.processInfo.environment)
    }

    /// `.standard` normally; a freshly wiped suite under UI testing, so every UI test starts clean.
    func makeUserDefaults() -> UserDefaults {
        guard isUITesting, let defaults = UserDefaults(suiteName: Self.uiTestingDefaultsSuite) else {
            return .standard
        }
        defaults.removePersistentDomain(forName: Self.uiTestingDefaultsSuite)
        return defaults
    }
}
```

Create `BJS/App/PlaceholderScreen.swift`:

```swift
import SwiftUI

/// Stand-in for screens that later steps build (modules from the hub, the Progress tab).
struct PlaceholderScreen: View {
    private let title: String

    init(title: String) {
        self.title = title
    }

    var body: some View {
        VStack(spacing: FeltSpacing.m) {
            Text(title)
                .feltType(.display)
                .foregroundStyle(FeltColor.textPrimary)
                .accessibilityIdentifier("placeholder.title")
            Text("Coming soon")
                .feltType(.body)
                .foregroundStyle(FeltColor.textSecondary)
        }
        .padding(FeltSpacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .feltBackground()
    }
}
```

- [ ] **Step 3: Implement the hub**

Create `BJS/Features/Hub/HubRoute.swift`:

```swift
/// The hub's module tiles, in display order. The App layer decides what each route shows,
/// so the Hub never references another feature (spec §3 rule 5).
enum HubRoute: String, CaseIterable, Identifiable, Hashable, Sendable {
    case strategy
    case counting
    case shoeSim
    case edge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .strategy: return "Strategy"
        case .counting: return "Counting"
        case .shoeSim: return "Shoe Sim"
        case .edge: return "Edge"
        }
    }

    var subtitle: String {
        switch self {
        case .strategy: return "Basic strategy drills"
        case .counting: return "Hi-Lo running and true count"
        case .shoeSim: return "Play a shoe, keep the count"
        case .edge: return "House edge for any rules"
        }
    }
}
```

Create `BJS/Features/Hub/HubStats.swift`:

```swift
import BJSCore
import Foundation

/// The hub's three stat chips (spec §5 Hub), computed from persisted samples.
///
/// - Strategy accuracy: graded decisions from Strategy and Shoe Sim sessions, last 30 days.
/// - Count accuracy: count checks from Counting (RC and TC) and Shoe Sim sessions, last 30 days.
/// - Streak: consecutive correct decisions, newest first, across all sessions.
struct HubStats: Equatable, Sendable {
    static let windowDays = 30

    let strategyAccuracy: Double?
    let countAccuracy: Double?
    let strategyStreak: Int

    static func make(sessions: [SessionSample], decisions: [DecisionSample], now: Date,
                     calendar: Calendar = .current) -> HubStats {
        let since = calendar.date(byAdding: .day, value: -windowDays, to: now) ?? now
        let strategy = ProgressStats.headline(sessions: sessions, modules: [.strategy, .shoe],
                                              measure: .decisions, since: since)
        let count = ProgressStats.headline(sessions: sessions, modules: [.countingRC, .countingTC, .shoe],
                                           measure: .countChecks, since: since)
        return HubStats(strategyAccuracy: strategy.accuracy, countAccuracy: count.accuracy,
                        strategyStreak: ProgressStats.currentStreak(decisions))
    }

    /// "87%", or "—" with no data.
    static func percentText(_ accuracy: Double?) -> String {
        guard let accuracy else { return "—" }
        return "\(Int((accuracy * 100).rounded()))%"
    }
}
```

Create `BJS/Features/Hub/HubView.swift`:

```swift
import BJSCore
import SwiftData
import SwiftUI

/// Train tab (spec §5 Hub): rules summary, stat chips, module tiles.
///
/// The Continue button arrives with Step 3 (it is hidden until a module has been launched).
/// `destination` is supplied by the App layer, so the Hub never names another feature.
struct HubView<Destination: View>: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var sessions: [Session]
    @Query private var decisions: [DecisionRecord]
    @State private var path: [HubRoute] = []

    private let onShowRules: () -> Void
    private let destination: (HubRoute) -> Destination

    init(onShowRules: @escaping () -> Void, @ViewBuilder destination: @escaping (HubRoute) -> Destination) {
        self.onShowRules = onShowRules
        self.destination = destination
    }

    private var stats: HubStats {
        HubStats.make(sessions: ProgressMapper.sessionSamples(sessions),
                      decisions: ProgressMapper.decisionSamples(decisions),
                      now: .now)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                    header
                    statChips
                    tiles
                }
                .padding(.horizontal, FeltSpacing.l)
                .padding(.vertical, FeltSpacing.xl)
            }
            .feltBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HubRoute.self) { route in
                destination(route)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            Button(action: onShowRules) {
                HStack(spacing: FeltSpacing.xs) {
                    Text(RulesSummary.short(rulesStore.rules))
                    Image(systemName: "chevron.right")
                }
                .feltType(.label)
                .foregroundStyle(FeltColor.textSecondary)
                .frame(minHeight: FeltMetrics.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(FeltPressableStyle())
            .accessibilityLabel("Table rules: \(RulesSummary.short(rulesStore.rules))")
            .accessibilityHint("Opens Settings")
            .accessibilityIdentifier("hub.rulesSummary")

            Text("Train")
                .feltType(.display)
                .foregroundStyle(FeltColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("hub.title")
        }
    }

    private var statChips: some View {
        let current = stats
        return HStack(alignment: .top, spacing: FeltSpacing.s) {
            StatChip(label: "Strategy 30d", value: HubStats.percentText(current.strategyAccuracy))
            StatChip(label: "Count 30d", value: HubStats.percentText(current.countAccuracy))
            StatChip(label: "Streak", value: "\(current.strategyStreak)")
        }
    }

    @ViewBuilder
    private var tiles: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: FeltSpacing.m) {
                ForEach(HubRoute.allCases) { route in
                    tile(route)
                }
            }
        } else {
            Grid(horizontalSpacing: FeltSpacing.m, verticalSpacing: FeltSpacing.m) {
                GridRow {
                    tile(.strategy)
                    tile(.counting)
                }
                GridRow {
                    tile(.shoeSim)
                    tile(.edge)
                }
            }
        }
    }

    private func tile(_ route: HubRoute) -> some View {
        ModuleTile(title: route.title, subtitle: route.subtitle) {
            path.append(route)
        }
        .accessibilityIdentifier("hub.tile.\(route.rawValue)")
    }
}
```

- [ ] **Step 4: Wire the app**

Replace `BJS/App/RootTabView.swift` with (Settings stays a placeholder until Task 9):

```swift
import SwiftUI

/// The three top-level tabs (spec §5 Navigation).
enum AppTab: String, CaseIterable, Identifiable {
    case train = "Train"
    case progress = "Progress"
    case settings = "Settings"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .train: return "suit.spade.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape"
        }
    }
}

/// The composition root for navigation: it is the only place that knows which screen
/// each hub route and tab shows. Module screens arrive in Steps 3–7.
struct RootTabView: View {
    @State private var selection: AppTab = .train

    var body: some View {
        TabView(selection: $selection) {
            Tab(AppTab.train.rawValue, systemImage: AppTab.train.systemImage, value: AppTab.train) {
                HubView(onShowRules: { selection = .settings }) { route in
                    PlaceholderScreen(title: route.title)
                }
                .feltTabBar()
            }
            Tab(AppTab.progress.rawValue, systemImage: AppTab.progress.systemImage, value: AppTab.progress) {
                PlaceholderScreen(title: AppTab.progress.rawValue)
                    .feltTabBar()
            }
            Tab(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage, value: AppTab.settings) {
                PlaceholderScreen(title: AppTab.settings.rawValue)
                    .feltTabBar()
            }
        }
        .tint(FeltColor.cream)
    }
}

private extension View {
    /// Tab bar on `feltDeep` (spec §4: "tab bar base").
    func feltTabBar() -> some View {
        toolbarBackground(FeltColor.feltDeep, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}
```

Replace `BJS/App/BJSApp.swift` with:

```swift
import SwiftData
import SwiftUI

@main
struct BJSApp: App {
    private let launch: LaunchConfiguration
    private let modelContainer: ModelContainer
    @State private var rulesStore: ActiveRulesStore
    @State private var preferences: Preferences

    init() {
        let launch = LaunchConfiguration.current
        let defaults = launch.makeUserDefaults()
        self.launch = launch
        self.modelContainer = PersistenceController.makeAppContainer(inMemory: launch.isUITesting)
        self._rulesStore = State(initialValue: ActiveRulesStore(defaults: defaults))
        self._preferences = State(initialValue: Preferences(defaults: defaults))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(rulesStore)
                .environment(preferences)
                .preferredColorScheme(.dark)
                .tint(FeltColor.cream)
        }
        .modelContainer(modelContainer)
    }
}
```

- [ ] **Step 5: Local pre-checks — run the hub numbers on Linux**

`HubStats`, `HubRoute` and `LaunchConfiguration` import only Foundation/BJSCore. Type-check them, then run the `HubStats` fixture by compiling BJSCore's sources together with `HubStats.swift` (its `import BJSCore` stripped, because it becomes the same module):

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
(cd BJSCore && swift build 2>&1 | tail -1)
swiftc -typecheck -I BJSCore/.build/debug/Modules BJS/Features/Hub/HubStats.swift BJS/Features/Hub/HubRoute.swift BJS/App/LaunchConfiguration.swift
mkdir -p /tmp/bjs-hub && sed '/^import BJSCore/d' BJS/Features/Hub/HubStats.swift > /tmp/bjs-hub/HubStats.swift
cat > /tmp/bjs-hub/main.swift <<'SWIFT'
import Foundation
let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
let cal = Calendar(identifier: .gregorian)
func session(_ m: TrainingModule, _ days: Int, _ d: (Int, Int), _ c: (Int, Int)) -> SessionSample {
    SessionSample(id: UUID(), module: m, startedAt: cal.date(byAdding: .day, value: -days, to: now)!,
                  decisionCount: d.0, correctDecisions: d.1, countChecks: c.0, correctCountChecks: c.1)
}
let stats = HubStats.make(sessions: [session(.strategy, 2, (10, 8), (0, 0)), session(.shoe, 5, (2, 1), (4, 3)),
                                     session(.strategy, 40, (10, 0), (0, 0)), session(.countingRC, 1, (0, 0), (8, 5))],
                          decisions: [], now: now, calendar: cal)
print(HubStats.percentText(stats.strategyAccuracy), HubStats.percentText(stats.countAccuracy),
      HubStats.percentText(nil))
SWIFT
swiftc -o /tmp/bjs-hub/run BJSCore/Sources/BJSCore/*/*.swift /tmp/bjs-hub/*.swift && /tmp/bjs-hub/run
swiftc -parse BJS/App/*.swift BJS/Features/Hub/*.swift BJSTests/HubStatsTests.swift BJSTests/AppShellTests.swift
```

Expected: the build line, `75% 67% —`, and no other output.

- [ ] **Step 6: Commit**

```bash
git add BJS/App BJS/Features/Hub BJSTests/HubStatsTests.swift BJSTests/AppShellTests.swift
git commit -m "feat(app): hub shell with rules summary, stat chips and module tiles

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

- [ ] **Step 7: CI verification (controller)**

Expected: green; 59 unit tests.

---

### Task 9: Settings tab

**Files:**
- Create: `BJS/Features/Settings/SettingsView.swift`
- Modify: `BJS/App/RootTabView.swift` (Settings tab shows `SettingsView`)

**Interfaces:**
- Consumes: `ActiveRulesStore`, `Preferences` (environment), `modelContext` (environment), `ProgressReset`, `SettingsSection`/`SettingsRow`, `RulesSummary`, display names
- Produces: `struct SettingsView: View { init() }` — identifiers `settings.title`, `settings.scroll`, `settings.resetProgress`

Behaviour (spec §5 Settings): presets first ("Custom" appears only while the rules match no preset; choosing a preset applies it), then every `BlackjackRules` field, then preferences, then **Reset progress** → alert "Reset progress?" → "Delete all progress" (destructive) deletes every session and record but leaves rules and preferences; a failure shows a non-blocking alert and is logged.

- [ ] **Step 1: Implement**

Create `BJS/Features/Settings/SettingsView.swift`:

```swift
import BJSCore
import SwiftData
import SwiftUI

/// Settings tab (spec §5): table rules (presets first, then every `BlackjackRules` field),
/// preferences, and Reset progress with a confirmation.
struct SettingsView: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(Preferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext
    @State private var isConfirmingReset = false
    @State private var resetFailed = false

    init() {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                Text("Settings")
                    .feltType(.display)
                    .foregroundStyle(FeltColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("settings.title")
                rulesSection
                preferencesSection
                progressSection
            }
            .padding(.horizontal, FeltSpacing.l)
            .padding(.vertical, FeltSpacing.xl)
        }
        .accessibilityIdentifier("settings.scroll")
        .feltBackground()
        .alert("Reset progress?", isPresented: $isConfirmingReset) {
            Button("Delete all progress", role: .destructive, action: resetProgress)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes every saved session. Your rules and preferences stay.")
        }
        .alert("Couldn't reset progress", isPresented: $resetFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your progress was not changed. Please try again.")
        }
    }

    // MARK: - Table rules

    private var presetSelection: Binding<RulePreset?> {
        let store = rulesStore
        return Binding(
            get: { store.matchingPreset },
            set: { preset in
                if let preset { store.apply(preset) }
            }
        )
    }

    /// Every preset, plus "Custom" while the rules match none of them.
    private var presetOptions: [RulePreset?] {
        let presets: [RulePreset?] = RulePreset.allCases.map { Optional($0) }
        return rulesStore.matchingPreset == nil ? presets + [nil] : presets
    }

    private var rulesSection: some View {
        @Bindable var store = rulesStore
        return SettingsSection("Table rules") {
            SettingsRow("Preset", selection: presetSelection, options: presetOptions,
                        optionTitle: RulesSummary.presetName)
            SettingsRow("Decks", selection: $store.rules.deckCount,
                        options: BlackjackRules.DeckCount.allCases) { $0.displayName }
            SettingsRow("Dealer soft 17", selection: $store.rules.dealerSoft17,
                        options: BlackjackRules.DealerSoft17.allCases) { $0.displayName }
            SettingsRow("Blackjack pays", selection: $store.rules.blackjackPayout,
                        options: BlackjackRules.BlackjackPayout.allCases) { $0.displayName }
            SettingsRow("Double on", selection: $store.rules.doubleRestriction,
                        options: BlackjackRules.DoubleRestriction.allCases) { $0.displayName }
            SettingsRow("Double after split", isOn: $store.rules.doubleAfterSplit)
            SettingsRow("Max split hands", selection: $store.rules.maxSplitHands,
                        options: [2, 3, 4]) { "\($0)" }
            SettingsRow("Resplit aces", isOn: $store.rules.resplitAces)
            SettingsRow("Hit split aces", isOn: $store.rules.hitSplitAces)
            SettingsRow("Surrender", selection: $store.rules.surrenderRule,
                        options: BlackjackRules.SurrenderRule.allCases) { $0.displayName }
            SettingsRow("Dealer hole card", selection: $store.rules.peekRule,
                        options: BlackjackRules.PeekRule.allCases, showsSeparator: false) { $0.displayName }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        @Bindable var prefs = preferences
        return SettingsSection("Preferences") {
            SettingsRow("Speed-mode timer", selection: $prefs.speedTimerSeconds,
                        options: Preferences.speedTimerOptions) { String(format: "%.1f s", $0) }
            SettingsRow("True count", selection: $prefs.trueCountConvention,
                        options: TrueCountConvention.allCases) { $0.displayName }
            SettingsRow("Shoe Sim count check", selection: $prefs.shoeCheckEveryRounds,
                        options: Preferences.shoeCheckOptions) { "1 in \($0) rounds" }
            SettingsRow("Haptics", isOn: $prefs.hapticsEnabled, showsSeparator: false)
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        SettingsSection("Progress") {
            Button {
                isConfirmingReset = true
            } label: {
                Text("Reset progress")
                    .feltType(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(FeltColor.incorrect)
                    .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget, alignment: .leading)
                    .padding(.horizontal, FeltSpacing.l)
                    .contentShape(Rectangle())
            }
            .buttonStyle(FeltPressableStyle())
            .accessibilityHint("Deletes all saved sessions after you confirm")
            .accessibilityIdentifier("settings.resetProgress")
        }
    }

    private func resetProgress() {
        do {
            try ProgressReset.deleteAllProgress(in: modelContext)
        } catch {
            let message = String(describing: error)
            AppLog.persistence.error("Reset progress failed: \(message, privacy: .public)")
            resetFailed = true
        }
    }
}
```

- [ ] **Step 2: Show it in the Settings tab**

In `BJS/App/RootTabView.swift`, replace:

```swift
            Tab(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage, value: AppTab.settings) {
                PlaceholderScreen(title: AppTab.settings.rawValue)
                    .feltTabBar()
            }
```

with:

```swift
            Tab(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage, value: AppTab.settings) {
                SettingsView()
                    .feltTabBar()
            }
```

- [ ] **Step 3: Local pre-checks**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
swiftc -parse BJS/Features/Settings/SettingsView.swift BJS/App/RootTabView.swift
grep -rn "Features/Hub\|HubView\|HubRoute" BJS/Features/Settings || echo "SETTINGS ISOLATED"
```

Expected: no output from `swiftc`, then `SETTINGS ISOLATED`.

- [ ] **Step 4: Commit**

```bash
git add BJS/Features/Settings BJS/App/RootTabView.swift
git commit -m "feat(app): Settings tab with rules, presets, preferences and reset progress

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

- [ ] **Step 5: CI verification (controller)**

Expected: green; 59 unit tests.

---

### Task 10: Component gallery and the UI-test target

**Files:**
- Create: `BJS/Design/Gallery/ComponentGallery.swift` (whole file inside `#if DEBUG`)
- Create: `BJSUITests/DesignScreenshotTests.swift`
- Modify: `BJS/App/BJSApp.swift` (DEBUG gallery launch), `project.yml` (`BJSUITests` target + scheme)

**Interfaces:**
- Produces:
  - `enum GalleryPage: String, CaseIterable { colors, type, cards, dock, feedback, buttons, tiles, settingsRows, keypad, keypadDecimal }` and `struct ComponentGalleryView: View { init(page:) }` (identifier `gallery.title`), DEBUG only
  - Launching with `BJS_GALLERY_PAGE=<raw value>` shows that page instead of the app (DEBUG only)
  - `BJSUITests` target (XCTest) with `DesignScreenshotTests`: `testHubPlaceholderAndSettings` (6 screenshots) and `testComponentGalleryPages` (10 screenshots); every screenshot is an `XCTAttachment` with `lifetime = .keepAlways`

Each gallery page is laid out to fit an iPhone SE (3rd generation) screen, so one screenshot per page shows every state. The page list in the UI test must match `GalleryPage` (the UI-test target cannot import the app).

- [ ] **Step 1: Create the gallery**

Create `BJS/Design/Gallery/ComponentGallery.swift`:

```swift
#if DEBUG
import BJSCore
import SwiftUI

/// DEBUG-only pages showing every Felt component in every state, for the §7 design check.
/// Launch with `BJS_GALLERY_PAGE=<raw value>` (see `LaunchConfiguration`). Each page is
/// sized to fit an iPhone SE (3rd generation) screen.
enum GalleryPage: String, CaseIterable, Identifiable {
    case colors
    case type
    case cards
    case dock
    case feedback
    case buttons
    case tiles
    case settingsRows
    case keypad
    case keypadDecimal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .colors: return "Colours"
        case .type: return "Type & layout"
        case .cards: return "Cards & hands"
        case .dock: return "Action dock"
        case .feedback: return "Feedback"
        case .buttons: return "Buttons & picker"
        case .tiles: return "Chips & tiles"
        case .settingsRows: return "Settings rows"
        case .keypad: return "Count keypad"
        case .keypadDecimal: return "Keypad (decimal)"
        }
    }
}

struct ComponentGalleryView: View {
    private let page: GalleryPage

    init(page: GalleryPage) {
        self.page = page
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.l) {
                Text(page.title)
                    .feltType(.display)
                    .foregroundStyle(FeltColor.textPrimary)
                    .accessibilityIdentifier("gallery.title")
                content
            }
            .padding(.horizontal, FeltSpacing.l)
            .padding(.vertical, FeltSpacing.l)
        }
        .feltBackground()
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .colors: ColorsGalleryPage()
        case .type: TypeGalleryPage()
        case .cards: CardsGalleryPage()
        case .dock: DockGalleryPage()
        case .feedback: FeedbackGalleryPage()
        case .buttons: ButtonsGalleryPage()
        case .tiles: TilesGalleryPage()
        case .settingsRows: SettingsRowsGalleryPage()
        case .keypad: KeypadGalleryPage(allowsDecimal: false)
        case .keypadDecimal: KeypadGalleryPage(allowsDecimal: true)
        }
    }
}

/// A caption above one component state.
private struct GalleryItem<Content: View>: View {
    private let caption: String
    private let content: Content

    init(_ caption: String, @ViewBuilder content: () -> Content) {
        self.caption = caption
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            Text(caption)
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
            content
        }
    }
}

private struct ColorsGalleryPage: View {
    private struct Swatch: Identifiable {
        let name: String
        let color: Color
        var id: String { name }
    }

    private let swatches: [Swatch] = [
        Swatch(name: "feltDeep", color: FeltColor.feltDeep),
        Swatch(name: "feltBase", color: FeltColor.feltBase),
        Swatch(name: "feltLight", color: FeltColor.feltLight),
        Swatch(name: "surfaceInset", color: FeltColor.surfaceInset),
        Swatch(name: "cream", color: FeltColor.cream),
        Swatch(name: "onCream", color: FeltColor.onCream),
        Swatch(name: "onCreamSecondary", color: FeltColor.onCreamSecondary),
        Swatch(name: "brass", color: FeltColor.brass),
        Swatch(name: "correct", color: FeltColor.correct),
        Swatch(name: "incorrect", color: FeltColor.incorrect),
        Swatch(name: "suitRed", color: FeltColor.suitRed),
        Swatch(name: "suitBlack", color: FeltColor.suitBlack),
        Swatch(name: "textPrimary", color: FeltColor.textPrimary),
        Swatch(name: "textSecondary", color: FeltColor.textSecondary),
        Swatch(name: "textTertiary", color: FeltColor.textTertiary),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s), GridItem(.flexible())],
                  alignment: .leading, spacing: FeltSpacing.s) {
            ForEach(swatches) { swatch in
                HStack(spacing: FeltSpacing.s) {
                    RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous)
                        .fill(swatch.color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous)
                                .strokeBorder(FeltColor.textTertiary.opacity(0.4), lineWidth: 1)
                        )
                    Text(swatch.name)
                        .feltType(.body)
                        .foregroundStyle(FeltColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        // Text-on-cream samples.
        HStack(spacing: FeltSpacing.s) {
            Text("onCream").foregroundStyle(FeltColor.onCream)
            Text("secondary").foregroundStyle(FeltColor.onCreamSecondary)
            Text("♥").foregroundStyle(FeltColor.suitRed)
            Text("♠").foregroundStyle(FeltColor.suitBlack)
        }
        .feltType(.body)
        .padding(FeltSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FeltColor.cream, in: RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous))
    }
}

private struct TypeGalleryPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            ForEach(FeltType.allCases, id: \.self) { role in
                Text("\(String(describing: role)) · Soft 18 · 0.42%")
                    .feltType(role)
                    .foregroundStyle(FeltColor.textPrimary)
            }
        }
        GalleryItem("Spacing 4 · 8 · 12 · 16 · 24 · 32") {
            VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                ForEach(FeltSpacing.scale, id: \.self) { value in
                    Rectangle()
                        .fill(FeltColor.textSecondary)
                        .frame(width: value * 4, height: 6)
                }
            }
        }
        GalleryItem("Radius chip · tile · card · sheet") {
            HStack(spacing: FeltSpacing.s) {
                ForEach([FeltRadius.chip, FeltRadius.tile, FeltRadius.card, FeltRadius.sheet], id: \.self) { radius in
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(FeltColor.surfaceInset)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text("\(Int(radius))")
                                .feltType(.label)
                                .foregroundStyle(FeltColor.textSecondary)
                        )
                }
            }
        }
    }
}

private struct CardsGalleryPage: View {
    var body: some View {
        GalleryItem("PlayingCard · four suits · face down") {
            HStack(spacing: FeltSpacing.s) {
                PlayingCard(Card(rank: .ace, suit: .spades), width: 56)
                PlayingCard(Card(rank: .eight, suit: .clubs), width: 56)
                PlayingCard(Card(rank: .ten, suit: .hearts), width: 56)
                PlayingCard(Card(rank: .queen, suit: .diamonds), width: 56)
                PlayingCard(Card(rank: .two, suit: .spades), isFaceUp: false, width: 56)
            }
        }
        GalleryItem("PlayingCard · width 96") {
            HStack(spacing: FeltSpacing.m) {
                PlayingCard(Card(rank: .king, suit: .hearts), width: 96)
                PlayingCard(Card(rank: .king, suit: .hearts), isFaceUp: false, width: 96)
            }
        }
        GalleryItem("HandView · dealer (hole card) · player with total") {
            HStack(alignment: .top, spacing: FeltSpacing.xl) {
                HandView(cards: [Card(rank: .ten, suit: .hearts), Card(rank: .six, suit: .spades)],
                         faceDownIndices: [1], cardWidth: 56, overlap: 0.45)
                HandView(cards: [Card(rank: .ace, suit: .spades), Card(rank: .seven, suit: .diamonds),
                                 Card(rank: .three, suit: .clubs)],
                         cardWidth: 56, overlap: 0.55, totalLabel: "21")
            }
        }
    }
}

private struct DockGalleryPage: View {
    private let all = Set(Action.allCases)

    var body: some View {
        GalleryItem("All actions allowed") {
            ActionDock(allowed: all) { _ in }
        }
        GalleryItem("Dimmed: only hit / stand allowed") {
            ActionDock(allowed: [.hit, .stand]) { _ in }
        }
        GalleryItem("Learn-mode hint on DOUBLE") {
            ActionDock(allowed: all, hint: .double) { _ in }
        }
        GalleryItem("Hint on STAND, split and surrender dimmed") {
            ActionDock(allowed: [.hit, .stand, .double], hint: .stand) { _ in }
        }
    }
}

private struct FeedbackGalleryPage: View {
    var body: some View {
        VStack(spacing: FeltSpacing.xl + FeedbackCard.badgeSize / 2) {
            FeedbackCard(isCorrect: true, headline: "Correct — Stand",
                         reason: "Hard 16 v 6: the dealer busts often enough.",
                         onWhy: {}, onNext: {})
            FeedbackCard(isCorrect: false, headline: "Double, not Hit",
                         reason: "Soft 18 v 6: double while the dealer is weak.",
                         onWhy: {}, onNext: {})
        }
        .padding(.top, FeedbackCard.badgeSize / 2)
    }
}

private struct ButtonsGalleryPage: View {
    @State private var mode = "Learn"
    @State private var length = "50"

    var body: some View {
        GalleryItem("PrimaryButton · enabled / disabled") {
            VStack(spacing: FeltSpacing.s) {
                PrimaryButton("Start session") {}
                PrimaryButton("Start session") {}.disabled(true)
            }
        }
        GalleryItem("SecondaryButton · enabled / disabled") {
            VStack(spacing: FeltSpacing.s) {
                SecondaryButton("Change rules") {}
                SecondaryButton("Change rules") {}.disabled(true)
            }
        }
        GalleryItem("ModePicker") {
            VStack(spacing: FeltSpacing.s) {
                ModePicker(["Learn", "Test", "Speed", "Weak spots"], selection: $mode) { $0 }
                ModePicker(["25", "50", "100", "Endless"], selection: $length) { $0 }
            }
        }
    }
}

private struct TilesGalleryPage: View {
    var body: some View {
        GalleryItem("StatChip · value / no data") {
            HStack(alignment: .top, spacing: FeltSpacing.s) {
                StatChip(label: "Strategy 30d", value: "87%")
                StatChip(label: "Count 30d", value: "—")
                StatChip(label: "Streak", value: "12")
            }
        }
        GalleryItem("ModuleTile") {
            Grid(horizontalSpacing: FeltSpacing.m, verticalSpacing: FeltSpacing.m) {
                GridRow {
                    ModuleTile(title: "Strategy", subtitle: "Basic strategy drills") {}
                    ModuleTile(title: "Counting", subtitle: "Hi-Lo running and true count") {}
                }
            }
        }
    }
}

private struct SettingsRowsGalleryPage: View {
    @State private var isOn = true
    @State private var isOff = false
    @State private var decks = BlackjackRules.DeckCount.six

    var body: some View {
        SettingsSection("Settings section") {
            SettingsRow("Value row", value: "Vegas Strip")
            SettingsRow("Picker row", selection: $decks,
                        options: BlackjackRules.DeckCount.allCases) { $0.displayName }
            SettingsRow("Toggle on", isOn: $isOn)
            SettingsRow("Toggle off", isOn: $isOff, showsSeparator: false)
        }
    }
}

private struct KeypadGalleryPage: View {
    private let allowsDecimal: Bool
    @State private var entry: CountEntry

    init(allowsDecimal: Bool) {
        self.allowsDecimal = allowsDecimal
        var entry = CountEntry()
        entry.toggleSign()
        entry.appendDigit(1)
        if allowsDecimal {
            entry.appendDecimalPoint()
            entry.appendDigit(2)
            entry.appendDigit(5)
        } else {
            entry.appendDigit(2)
        }
        self._entry = State(initialValue: entry)
    }

    var body: some View {
        CountKeypad(entry: $entry, allowsDecimal: allowsDecimal) { _ in }
    }
}

#Preview("Cards") { ComponentGalleryView(page: .cards) }
#Preview("Dock") { ComponentGalleryView(page: .dock) }
#Preview("Feedback") { ComponentGalleryView(page: .feedback) }
#Preview("Keypad") { ComponentGalleryView(page: .keypad) }
#endif
```

- [ ] **Step 2: Launch the gallery from `BJSApp` in DEBUG**

Replace `BJS/App/BJSApp.swift` with:

```swift
import SwiftData
import SwiftUI

@main
struct BJSApp: App {
    private let launch: LaunchConfiguration
    private let modelContainer: ModelContainer
    @State private var rulesStore: ActiveRulesStore
    @State private var preferences: Preferences

    init() {
        let launch = LaunchConfiguration.current
        let defaults = launch.makeUserDefaults()
        self.launch = launch
        self.modelContainer = PersistenceController.makeAppContainer(inMemory: launch.isUITesting)
        self._rulesStore = State(initialValue: ActiveRulesStore(defaults: defaults))
        self._preferences = State(initialValue: Preferences(defaults: defaults))
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environment(rulesStore)
                .environment(preferences)
                .preferredColorScheme(.dark)
                .tint(FeltColor.cream)
        }
        .modelContainer(modelContainer)
    }

    #if DEBUG
    @ViewBuilder
    private var rootView: some View {
        if let name = launch.galleryPageName, let page = GalleryPage(rawValue: name) {
            ComponentGalleryView(page: page)
        } else {
            RootTabView()
        }
    }
    #else
    private var rootView: some View {
        RootTabView()
    }
    #endif
}
```

- [ ] **Step 3: Add the UI-test target**

Replace `project.yml` with:

```yaml
name: BJS
options:
  bundleIdPrefix: com.bjs
  deploymentTarget:
    iOS: "18.0"
  xcodeVersion: "26.3"
  defaultConfig: Debug
settings:
  base:
    SWIFT_VERSION: "6.2"
    SWIFT_STRICT_CONCURRENCY: complete
targets:
  BJS:
    type: application
    platform: iOS
    sources: [BJS]
    dependencies:
      - package: BJSCore
    scheme:
      testTargets:
        - BJSTests
        - BJSUITests
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: com.bjs.app
        INFOPLIST_VALUES:
          CFBundleName: BJS
          UILaunchScreen: {}
  BJSTests:
    type: bundle.unit-test
    platform: iOS
    sources: [BJSTests]
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
    dependencies:
      - target: BJS
  BJSUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [BJSUITests]
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        TEST_TARGET_NAME: BJS
    dependencies:
      - target: BJS
packages:
  BJSCore:
    path: ./BJSCore
```

(`TEST_TARGET_NAME` is set explicitly; XcodeGen would infer it from the dependency, but explicit is safer.)

- [ ] **Step 4: Write the UI test**

Create `BJSUITests/DesignScreenshotTests.swift`:

```swift
import XCTest

/// Spec §7 design check: walks the hub, a placeholder route, Settings (incl. the reset
/// confirmation) and every component-gallery page, attaching a screenshot of each.
/// CI runs this on iPhone 16 and iPhone SE (3rd generation) and uploads the PNGs.
final class DesignScreenshotTests: XCTestCase {

    /// Must match `GalleryPage` raw values in `BJS/Design/Gallery/ComponentGallery.swift`.
    private static let galleryPages = [
        "colors", "type", "cards", "dock", "feedback",
        "buttons", "tiles", "settingsRows", "keypad", "keypadDecimal",
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchApp(galleryPage: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["BJS_UI_TESTING"] = "1"
        if let galleryPage {
            app.launchEnvironment["BJS_GALLERY_PAGE"] = galleryPage
        }
        app.launch()
        return app
    }

    @MainActor
    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testHubPlaceholderAndSettings() throws {
        let app = launchApp()

        let rulesSummary = app.buttons["hub.rulesSummary"]
        XCTAssertTrue(rulesSummary.waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["hub.tile.strategy"].exists)
        XCTAssertTrue(app.buttons["hub.tile.edge"].exists)
        snapshot("01-hub")

        app.buttons["hub.tile.strategy"].tap()
        XCTAssertTrue(app.staticTexts["placeholder.title"].waitForExistence(timeout: 5))
        snapshot("02-placeholder-strategy")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(rulesSummary.waitForExistence(timeout: 5))

        // The rules summary switches to the Settings tab.
        rulesSummary.tap()
        XCTAssertTrue(app.staticTexts["settings.title"].waitForExistence(timeout: 5))
        snapshot("03-settings-top")

        let scrollView = app.scrollViews["settings.scroll"]
        scrollView.swipeUp()
        snapshot("04-settings-middle")
        scrollView.swipeUp()
        snapshot("05-settings-bottom")

        let reset = app.buttons["settings.resetProgress"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5))
        reset.tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        snapshot("06-reset-confirmation")
        alert.buttons["Cancel"].tap()
    }

    @MainActor
    func testComponentGalleryPages() throws {
        for (index, page) in Self.galleryPages.enumerated() {
            let app = launchApp(galleryPage: page)
            XCTAssertTrue(app.staticTexts["gallery.title"].waitForExistence(timeout: 15), "gallery page \(page)")
            snapshot(String(format: "%02d-gallery-%@", 10 + index, page))
            app.terminate()
        }
    }
}
```

- [ ] **Step 5: Local pre-checks**

```bash
export PATH=/opt/swiftroot/usr/bin:$PATH
swiftc -parse -D DEBUG BJS/Design/Gallery/ComponentGallery.swift BJS/App/BJSApp.swift BJSUITests/DesignScreenshotTests.swift
python3 -c "import yaml; print(sorted(yaml.safe_load(open('project.yml'))['targets']))"
python3 - <<'PY'
import re
gallery = re.findall(r"^    case (\w+)$", open("BJS/Design/Gallery/ComponentGallery.swift").read(), re.M)
ui = re.findall(r'"(\w+)"', open("BJSUITests/DesignScreenshotTests.swift").read().split("galleryPages = [")[1].split("]")[0])
print("PAGES MATCH" if gallery == ui else f"MISMATCH {gallery} vs {ui}")
PY
```

Expected: no output from `swiftc`, `['BJS', 'BJSTests', 'BJSUITests']` (if PyYAML is missing, skip that line), and `PAGES MATCH`.

- [ ] **Step 6: Commit**

```bash
git add BJS/Design/Gallery BJS/App/BJSApp.swift BJSUITests project.yml
git commit -m "test(app): DEBUG component gallery and screenshot UI tests

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

- [ ] **Step 7: CI verification (controller)**

The current workflow's `xcodebuild test` runs the whole scheme, so this run executes the UI tests on the auto-picked simulator. Expected: green; 59 unit tests and 2 UI tests (`DesignScreenshotTests`). If the UI-test runner fails to launch because of code signing, change the workflow's `CODE_SIGNING_ALLOWED=NO` to `CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO` in a `fix(ci)` commit (Task 11 then uses the same setting). If an element lookup fails, the log names the identifier; fix the view or the query, not the design.

---

### Task 11: CI design-check pipeline (two devices, screenshots artifact)

**Files:**
- Create: `scripts/ci/ensure_simulator.py`, `scripts/ci/design_screenshots.sh`, `scripts/ci/export_screenshots.py` (all executable)
- Modify: `.github/workflows/ios.yml`

**Interfaces:**
- Produces: every CI run builds once (`build-for-testing`), runs unit tests on the auto-picked simulator, then runs `BJSUITests` on **iPhone 16** and **iPhone SE (3rd generation)** and uploads the artifact **`design-screenshots`** with `iphone-16/*.png` and `iphone-se/*.png` (16 each, named `01-hub.png` … `19-gallery-keypadDecimal.png`).
- Missing device models: `ensure_simulator.py` reuses an existing simulator of the device type on the newest iOS runtime that supports it, otherwise creates one with `xcrun simctl create`. If the model is not installed at all it falls back (iPhone 16 → iPhone 16e → iPhone 17; SE 3rd gen → SE 2nd gen) with a `::warning::`, and if nothing fits it skips that device with a warning instead of failing the run.

- [ ] **Step 1: Add the scripts**

Create `scripts/ci/ensure_simulator.py`:

```python
#!/usr/bin/env python3
"""Find or create an iPhone simulator for the design check and publish its UDID.

Usage:
  ensure_simulator.py --key iphone16 --name "iPhone 16" [--fallback "iPhone 16e" ...]

Tries --name first, then each --fallback, on the newest available iOS runtime that
supports the device type. Reuses an existing simulator of that type and runtime, or
creates one with `xcrun simctl create`. Writes `<key>=<udid>` and `<key>_name=<name>`
to $GITHUB_OUTPUT. If no candidate works it writes an empty UDID, prints a GitHub
warning and exits 0, so the workflow can skip that device and still upload the rest.
"""
import argparse
import json
import os
import subprocess
import sys


def simctl_list(*args):
    out = subprocess.run(["xcrun", "simctl", "list", *args, "-j"],
                         check=True, capture_output=True, text=True).stdout
    return json.loads(out)


def version_key(runtime):
    return tuple(int(part) for part in runtime.get("version", "0").split(".") if part.isdigit())


def write_output(key, udid, name):
    path = os.environ.get("GITHUB_OUTPUT")
    lines = f"{key}={udid}\n{key}_name={name}\n"
    if path:
        with open(path, "a") as handle:
            handle.write(lines)
    print(lines, end="")


def find_or_create(name, device_types, runtimes, devices):
    type_id = device_types.get(name)
    if type_id is None:
        print(f"Device type '{name}' is not installed.", file=sys.stderr)
        return None
    for runtime in runtimes:
        supported = {d.get("identifier") for d in runtime.get("supportedDeviceTypes", [])}
        if supported and type_id not in supported:
            continue
        for device in devices.get(runtime["identifier"], []):
            if device.get("deviceTypeIdentifier") == type_id or device.get("name") == name:
                print(f"Reusing {device['name']} ({runtime['name']}): {device['udid']}", file=sys.stderr)
                return device["udid"]
        created = subprocess.run(
            ["xcrun", "simctl", "create", f"BJS {name}", type_id, runtime["identifier"]],
            capture_output=True, text=True)
        if created.returncode == 0:
            udid = created.stdout.strip()
            print(f"Created BJS {name} ({runtime['name']}): {udid}", file=sys.stderr)
            return udid
        print(f"Could not create {name} on {runtime['name']}: {created.stderr.strip()}", file=sys.stderr)
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--key", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--fallback", action="append", default=[])
    args = parser.parse_args()

    device_types = {d["name"]: d["identifier"] for d in simctl_list("devicetypes")["devicetypes"]}
    runtimes = [r for r in simctl_list("runtimes")["runtimes"]
                if r.get("isAvailable") and r.get("name", "").startswith("iOS")]
    runtimes.sort(key=version_key, reverse=True)
    devices = simctl_list("devices", "available")["devices"]

    for candidate in [args.name, *args.fallback]:
        udid = find_or_create(candidate, device_types, runtimes, devices)
        if udid:
            if candidate != args.name:
                print(f"::warning::{args.name} unavailable; design screenshots use {candidate} instead.")
            write_output(args.key, udid, candidate)
            return
    print(f"::warning::No simulator for {args.name} or its fallbacks; skipping its design screenshots.")
    write_output(args.key, "", "")


if __name__ == "__main__":
    main()
```

Create `scripts/ci/design_screenshots.sh`:

```bash
#!/usr/bin/env bash
# Runs the UI tests (design screenshots) on one simulator.
# Usage: design_screenshots.sh <udid> <label>   e.g. design_screenshots.sh ABC-123 iphone-16
# Needs a prior `xcodebuild build-for-testing ... -derivedDataPath build/DerivedData`.
set -euo pipefail
UDID="$1"
LABEL="$2"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
# Clean, repeatable status bar in the screenshots (best effort).
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4 || true

mkdir -p build/results
rm -rf "build/results/$LABEL.xcresult"
xcodebuild test-without-building -project BJS.xcodeproj -scheme BJS \
  -destination "id=$UDID" \
  -derivedDataPath build/DerivedData \
  -only-testing:BJSUITests \
  -resultBundlePath "build/results/$LABEL.xcresult" 2>&1 | tail -60
```

Create `scripts/ci/export_screenshots.py` (`xcrun xcresulttool export attachments` is Xcode 16+; Xcode names exported files `<name>_<index>_<UUID>.png`, which the script trims back to `<name>.png`):

```python
#!/usr/bin/env python3
"""Copy the screenshot attachments out of an .xcresult bundle.

Usage: export_screenshots.py <bundle.xcresult> <output-dir>

Uses `xcrun xcresulttool export attachments` (Xcode 16+), then names each PNG after
the attachment name set in DesignScreenshotTests (e.g. 01-hub.png).
"""
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile


def attachments(node):
    """Yield every dict that describes one exported attachment, wherever it sits in the manifest."""
    if isinstance(node, dict):
        if "exportedFileName" in node:
            yield node
        for value in node.values():
            yield from attachments(value)
    elif isinstance(node, list):
        for value in node:
            yield from attachments(value)


def clean_name(attachment):
    raw = attachment.get("suggestedHumanReadableName") or attachment["exportedFileName"]
    stem = pathlib.Path(raw).stem
    # Xcode appends "_<index>_<UUID>" to the attachment name; drop it.
    stem = re.sub(r"_\d+_[0-9A-Fa-f-]{36}$", "", stem)
    return re.sub(r"[^A-Za-z0-9._-]", "_", stem) + pathlib.Path(attachment["exportedFileName"]).suffix


def main():
    bundle, output = sys.argv[1], pathlib.Path(sys.argv[2])
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["xcrun", "xcresulttool", "export", "attachments",
                        "--path", bundle, "--output-path", tmp], check=True)
        manifest_path = pathlib.Path(tmp) / "manifest.json"
        count = 0
        if manifest_path.exists():
            for attachment in attachments(json.loads(manifest_path.read_text())):
                source = pathlib.Path(tmp) / attachment["exportedFileName"]
                if source.exists():
                    shutil.copy(source, output / clean_name(attachment))
                    count += 1
        else:
            for source in pathlib.Path(tmp).glob("*.png"):
                shutil.copy(source, output / source.name)
                count += 1
    print(f"Exported {count} screenshots to {output}")


if __name__ == "__main__":
    main()
```

```bash
chmod +x scripts/ci/ensure_simulator.py scripts/ci/design_screenshots.sh scripts/ci/export_screenshots.py
```

- [ ] **Step 2: Replace the workflow**

Replace `.github/workflows/ios.yml` with (if Task 10 had to switch the code-signing setting, use the same setting in "Build for testing"):

```yaml
name: iOS

on:
  push:
    branches: [main, main-8v0ds1]
  pull_request:
  workflow_dispatch:

concurrency:
  group: ios-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-and-test:
    runs-on: macos-26
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v5

      - name: Select Xcode 26
        run: |
          XCODE=$(ls -d /Applications/Xcode_26*.app | sort -V | tail -1)
          sudo xcode-select -s "$XCODE"
          xcodebuild -version
          swift --version

      - name: Engine tests (BJSCore)
        working-directory: BJSCore
        run: swift test

      - name: Install XcodeGen
        run: brew install xcodegen

      - name: Generate project
        run: xcodegen generate

      - name: Pick an iPhone simulator
        id: sim
        run: |
          UDID=$(xcrun simctl list devices available -j | python3 -c '
          import json, sys
          devices = json.load(sys.stdin)["devices"]
          ios = sorted((k for k in devices if "iOS" in k), reverse=True)
          for runtime in ios:
              for d in devices[runtime]:
                  if d["name"].startswith("iPhone"):
                      print(d["udid"]); sys.exit()
          sys.exit("no iPhone simulator")')
          echo "udid=$UDID" >> "$GITHUB_OUTPUT"
          xcrun simctl list devices available | grep "$UDID"

      - name: Build for testing
        run: |
          set -o pipefail
          xcodebuild build-for-testing -project BJS.xcodeproj -scheme BJS \
            -destination "id=${{ steps.sim.outputs.udid }}" \
            -derivedDataPath build/DerivedData \
            CODE_SIGNING_ALLOWED=NO | tail -80

      - name: Unit tests
        run: |
          set -o pipefail
          xcodebuild test-without-building -project BJS.xcodeproj -scheme BJS \
            -destination "id=${{ steps.sim.outputs.udid }}" \
            -derivedDataPath build/DerivedData \
            -only-testing:BJSTests \
            -resultBundlePath build/results/unit.xcresult 2>&1 | tail -150

      - name: Provision design-check simulators
        id: design
        run: |
          python3 scripts/ci/ensure_simulator.py --key iphone16 --name "iPhone 16" \
            --fallback "iPhone 16e" --fallback "iPhone 17"
          python3 scripts/ci/ensure_simulator.py --key iphonese --name "iPhone SE (3rd generation)" \
            --fallback "iPhone SE (2nd generation)"

      - name: UI tests + screenshots (iPhone 16)
        if: steps.design.outputs.iphone16 != ''
        run: |
          set -o pipefail
          echo "Device: ${{ steps.design.outputs.iphone16_name }}"
          scripts/ci/design_screenshots.sh "${{ steps.design.outputs.iphone16 }}" iphone-16

      - name: UI tests + screenshots (iPhone SE)
        if: steps.design.outputs.iphonese != ''
        run: |
          set -o pipefail
          echo "Device: ${{ steps.design.outputs.iphonese_name }}"
          scripts/ci/design_screenshots.sh "${{ steps.design.outputs.iphonese }}" iphone-se

      - name: Export screenshots
        if: always()
        run: |
          for LABEL in iphone-16 iphone-se; do
            if [ -d "build/results/$LABEL.xcresult" ]; then
              python3 scripts/ci/export_screenshots.py "build/results/$LABEL.xcresult" "build/screenshots/$LABEL" \
                || echo "::warning::Could not export screenshots for $LABEL"
            fi
          done

      - name: Upload design screenshots
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: design-screenshots
          path: build/screenshots
          if-no-files-found: warn
          retention-days: 30

      - name: Upload test results on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: xcresults
          path: build/results
          if-no-files-found: ignore
          retention-days: 7
```

- [ ] **Step 3: Local pre-checks**

```bash
python3 -m py_compile scripts/ci/ensure_simulator.py scripts/ci/export_screenshots.py
bash -n scripts/ci/design_screenshots.sh
python3 -c "import yaml; d = yaml.safe_load(open('.github/workflows/ios.yml')); print(len(d['jobs']['build-and-test']['steps']))"
(cd scripts/ci && python3 -c "
import export_screenshots as e
print(e.clean_name({'suggestedHumanReadableName': '01-hub_0_1C8E0A5B-1234-4ABC-9DEF-0123456789AB.png', 'exportedFileName': 'x.png'}))")
rm -rf scripts/ci/__pycache__
```

Expected: no output from the first two, then `14`, then `01-hub.png`.

- [ ] **Step 4: Commit**

```bash
git add scripts/ci .github/workflows/ios.yml
git commit -m "chore(ci): design screenshots on iPhone 16 and iPhone SE as an artifact

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
```

- [ ] **Step 5: CI verification (controller)**

Expected: green. In the log: "Provision design-check simulators" prints `iphone16=<udid>` and `iphonese=<udid>` (note any `::warning::` fallback), both "UI tests + screenshots" steps end with `** TEST EXECUTE SUCCEEDED **`, "Export screenshots" prints `Exported 16 screenshots to build/screenshots/iphone-16` and the same for `iphone-se`, and the run has an artifact named `design-screenshots`. Then check the artifact listing (GitHub MCP `actions_list` with the run's artifacts, or `gh run view <id>`) shows it.

---

### Task 12: Design check and Step 2 handoff (freeze pending Luke)

**Files:**
- Modify: `docs/superpowers/progress.md`

This task is done by the controller (it needs the CI artifact and image viewing).

- [ ] **Step 1: Get the screenshots**

From the latest green run on `main-8v0ds1`, download the `design-screenshots` artifact: `gh run download <run-id> --name design-screenshots --dir /tmp/design-check` where `gh` is available, or the artifact's `archive_download_url` from the GitHub API. If neither works in this environment, ask Luke to download it from the run's Summary page and skip to Step 3 with the checklist for him to fill in.

- [ ] **Step 2: Compare every screenshot against spec §4**

View each PNG (both devices) and tick this checklist. This is a conformance check, not a redesign: a mismatch is fixed only when the code does not do what §4 (or the Decisions section above) says, as a `fix(app)` commit with its own CI run.

| # | Check (spec §4 unless noted) | Where |
|---|---|---|
| 1 | Dark only; felt is a radial `feltLight` → `feltBase` → `feltDeep`, edge to edge, under the status bar | all |
| 2 | Tab bar on `feltDeep`, three tabs Train · Progress · Settings, cream selection | 01, 03 |
| 3 | Hub: rules summary `6D · S17 · DAS · 3:2 ›`, "Train" in `display`, three stat chips (`—`, `—`, `0`), four tiles in a 2 × 2 grid; no Continue button | 01 |
| 4 | Tile tap pushes the placeholder with a back button | 02 |
| 5 | Settings: sections Table rules / Preferences / Progress on `surfaceInset`, hairlines between rows, values in `textSecondary`, preset "Vegas Strip" first | 03–05 |
| 6 | Reset confirmation shows "Delete all progress" (destructive) and Cancel | 06 |
| 7 | Colour swatches match the §4 values; `brass` appears nowhere except the hint ring; `correct`/`incorrect` only on feedback and the reset label | gallery-colors, all |
| 8 | Type roles: display 28 bold, title 20 semibold, body 15, label 11 uppercase tracked, stat 22 mono | gallery-type |
| 9 | Spacing bars 4/8/12/16/24/32; radii chip 10, tile 14, card 8, sheet 16 | gallery-type |
| 10 | PlayingCard: cream face, rank + suit index top-left, large suit bottom-right, red hearts/diamonds; back = cream border + diagonal felt stripes; height = 1.4 × width | gallery-cards |
| 11 | HandView overlaps cards; dealer hole card face down; total label under the player hand | gallery-cards |
| 12 | ActionDock: row 1 STAND, HIT cream; row 2 SPLIT, DOUBLE, SURRENDER inset; dimmed buttons at 40 %; brass hint ring | gallery-dock |
| 13 | FeedbackCard: cream, badge straddling the top edge (✓ on `correct`, ✕ on `incorrect`), headline, one-line reason, WHY + NEXT | gallery-feedback |
| 14 | PrimaryButton cream-filled, SecondaryButton outlined on inset, disabled dimmed; ModePicker selected segment cream | gallery-buttons |
| 15 | StatChip label + mono value on inset; ModuleTile title + subtitle on inset | gallery-tiles |
| 16 | SettingsRow value / picker / toggle variants, hairline separators, last row without separator | gallery-settingsRows |
| 17 | CountKeypad: display, 1–9, ± 0 (and "." in the decimal page), ⌫, Enter; keys ≥ 44 pt | gallery-keypad, gallery-keypadDecimal |
| 18 | iPhone SE: nothing clipped or truncated that is whole on iPhone 16; every gallery page fits the screen | SE set |
| 19 | `ContrastTests` passed in the same run (spec §7) | CI log |

- [ ] **Step 3: Append the Step 2 handoff to `docs/superpowers/progress.md`**

Use the real values (commit range from `git log --oneline`, run URL, test counts, device names actually used):

```markdown

## Step 2 — Foundation (YYYY-MM-DD)

- Commits: <first-sha>..<last-sha> (branch `main-8v0ds1`).
- CI: run <url> green. BJSCore 173 tests; app unit tests 59 (Swift Testing); UI tests 2 (XCTest) on <iPhone 16 device> and <iPhone SE device>.
- Design check (spec §7): screenshots in the run's `design-screenshots` artifact (16 per device). Checklist 1–19: <all pass | list deviations and their fix commits>. Contrast test green.
- **Design freeze: PENDING Luke's approval.** When Luke approves, change this line to "Design freeze: FROZEN on <date> (approved by Luke)". From then on §4 tokens and components change only by Luke's explicit decision in their own commit.
- For Luke to confirm at the freeze: the "Decisions this plan makes" list in `docs/superpowers/plans/2026-09-24-step-2-foundation.md` (esp. #11 visual details and #13 contrast at the `feltLight` centre).
- Added: Felt tokens (`FeltPalette`, `FeltColor`, `FeltType`, `FeltSpacing`, `FeltRadius`, `FeltMetrics`, `FeltMotion`) and `WCAGContrast`; components FeltBackground, PlayingCard, HandView, ActionDock, FeedbackCard, StatChip, ModuleTile, PrimaryButton/SecondaryButton (`FeltButtonStyle`), ModePicker, SettingsRow/SettingsSection, CountKeypad (+ `CountEntry`, optional decimal key); DEBUG ComponentGallery; `ActiveRulesStore`, `Preferences`; SwiftData `SchemaV1` + `BJSMigrationPlan`, `ProgressMapper`, `ProgressReset`; hub shell and Settings tab; `BJSUITests`; CI screenshot pipeline.
- `project.yml`: the no-op `DefaultIsolationMainActor` flag is gone; the app is nonisolated by default with explicit `@MainActor` stores (see the plan's Global Constraints).
- Notes for Step 3: hub tiles route through `RootTabView`'s `destination` closure (replace `PlaceholderScreen` for `.strategy`); records use the typealiases `Session`, `DecisionRecord`, `CountCheckRecord`; write `decidedAt` per decision; "timeout" is a plain `chosenAction` string; Continue + `lastLaunch` are still to build; `LaunchConfiguration` gives UI tests a clean store (`BJS_UI_TESTING=1`).
- Next: after Luke approves the freeze, Step 3 (Strategy) in a fresh session.
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/progress.md
git commit -m "docs: Step 2 handoff (design freeze pending Luke)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XyqkZzZuQ5xb3XY228sQpi"
git push origin main-8v0ds1
```

- [ ] **Step 5: Ask Luke for the freeze decision**

Send Luke the run link, the `design-screenshots` artifact, the checklist result, and the "Decisions this plan makes" list. The freeze is his call; do not mark it frozen yourself.

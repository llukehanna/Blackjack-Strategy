# Step 2 — Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Felt design system and component kit, the app shell and hub, Settings, the app-wide stores and SwiftData `SchemaV1`, then freeze Felt after Luke's design sign-off.

**Architecture:**
- **Tokens:** raw hex values live in `FeltPalette` as `FeltRGB`, a value type that knows WCAG contrast maths. Contrast is unit-tested, and the same requirement list is rendered in a DEBUG catalogue.
- **Stores:** `ActiveRulesStore` and `PreferencesStore` are `@Observable` classes over an injected `UserDefaults`. `SessionStore` wraps a SwiftData `ModelContext` and returns BJSCore sample types.
- **Isolation:** feature folders (`Features/Hub`, `Features/Settings`) only use `Design/`, `Shared/`, `Persistence/` and `BJSCore`.

**Tech Stack:** Swift 6.2, SwiftUI (iOS 18), SwiftData, Observation, Swift Testing (unit), XCTest (UI), XcodeGen.

**Spec:** Read both before starting.
- `docs/superpowers/specs/2026-09-24-step-2-foundation-design.md` (this step)
- `docs/superpowers/specs/2026-09-23-bjs-rebuild-design.md` §4 (tokens, components), §5 (hub, settings), §6 (data)

## Global Constraints

- iOS 18.0 deployment target, iPhone only. The app is dark only: `.preferredColorScheme(.dark)`.
- The app target compiles with `SWIFT_STRICT_CONCURRENCY: complete` and `-enable-upcoming-feature DefaultIsolationMainActor`. Every app type is `@MainActor` by default, and app unit test suites are marked `@MainActor`.
- `BJSCore` never imports SwiftUI or SwiftData. Every public `BJSCore` type is `Sendable`.
- Feature folders never import or reference each other. Shared code goes in `BJS/Design/`, `BJS/Shared/`, `BJS/Persistence/` or `BJSCore`. Only `BJS/App/` may reference features.
- XcodeGen owns the project. New files under `BJS/`, `BJSTests/` and `BJSUITests/` are picked up by `xcodegen generate`. Never edit `BJS.xcodeproj`.
- Colour token values are exactly as in parent spec §4. `FeltBackground` glow opacity is 0.45. Spacing is 4/8/12/16/24/32. Radii: chip 10, tile/button 14, card 8, sheet 16. Motion: UI 0.2 s ease-out, deal 0.25 s, flip 0.35 s.
- The minimum tap target is 44 pt.
- Don't form key paths (`\.prop`, `SortDescriptor(\.prop)`) to properties of app-module types, including `@Model` classes. Under `DefaultIsolationMainActor` they are main-actor isolated, and Swift 6 can reject the key path. Use closures (`.map { $0.prop }`) and sort in memory. Key paths to `BJSCore` types are fine.
- `correct` and `incorrect` are never text on cream.
- Unit tests use Swift Testing (`import Testing`, `@Test`, `#expect`). UI tests use XCTest.
- Commit after every task with a conventional prefix and scope: `feat(design)`, `feat(app)`, `feat(core)`, `feat(persistence)`, `feat(hub)`, `feat(settings)`, `test(app)`, `docs`. Every commit message ends with a blank line and then `Co-Authored-By: Claude <model that made the commit> <noreply@anthropic.com>`.
- Stage files explicitly by path. Never `git add -A` or `git add .`: the untracked `reports/` and `research_notes/` directories are not part of this work.
- Commands, from the repo root `/Users/luke/Claude Projects/BJS`:
  - Engine tests: `cd BJSCore && swift test 2>&1 | tail -5`
  - App tests (all): `xcodegen generate && xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | grep -E "error:|warning: |✘|✔ Test run|Executed|TEST (SUCCEEDED|FAILED)" | tail -30`
  - One app test suite: add `-only-testing:BJSTests/<SuiteStructName>` to the xcodebuild command.
- Build output must stay warning-free in files you touch.

## File map

| File | Task | Responsibility |
|---|---|---|
| `BJS/Design/Tokens/FeltRGB.swift` | 1 | sRGB value + WCAG contrast maths |
| `BJS/Design/Tokens/FeltPalette.swift` | 1 | Raw token values, glow and inset effective colours |
| `BJS/Design/Tokens/FeltColor.swift` | 1 | SwiftUI `Color` tokens |
| `BJS/Design/Tokens/FeltContrast.swift` | 1 | The contrast requirement list (tested + shown in catalogue) |
| `BJS/Design/Tokens/FeltType.swift` | 2 | Type roles + `.feltText(_:)` |
| `BJS/Design/Tokens/FeltLayout.swift` | 2 | `FeltSpacing`, `FeltRadius` |
| `BJS/Design/Tokens/FeltMotion.swift` | 2 | Durations, animations, Reduce Motion helpers |
| `BJS/Design/Components/FeltBackground.swift` | 2 | Felt radial background |
| `BJS/Design/Components/FeltTabBarAppearance.swift` | 2 | `feltDeep` tab bar |
| `BJS/Design/Components/StatChip.swift`, `ModuleTile.swift`, `FeltButtons.swift`, `ModePicker.swift`, `SettingsRow.swift`, `ComingSoonView.swift` | 2 | Surface components |
| `BJS/Design/Components/CardNames.swift`, `PlayingCard.swift`, `HandView.swift` | 3 | Cards and hands |
| `BJS/Design/Components/ActionDock.swift`, `FeedbackCard.swift` | 4 | Trainer controls and feedback |
| `BJS/Design/Components/CountEntry.swift`, `CountKeypad.swift` | 5 | Count entry logic and keypad |
| `BJSCore/Sources/BJSCore/Progress/SessionSummary.swift` | 6 | Cached session summary maths |
| `BJS/Shared/RuleLabels.swift`, `RulesSummary.swift` | 7 | Display names; hub header text |
| `BJS/Shared/ActiveRulesStore.swift`, `PreferencesStore.swift` | 8 | App-wide stores |
| `BJS/Persistence/SchemaV1.swift`, `RecordMappers.swift` | 9 | SwiftData models, migration plan, container, mappers |
| `BJS/Persistence/SessionDraft.swift`, `SessionStore.swift` | 10 | Save/fetch/delete sessions |
| `BJS/Shared/AppRouter.swift`, `BJS/App/LaunchConfiguration.swift`, `BJS/App/BJSApp.swift`, `BJS/App/RootTabView.swift` | 11 | Shell and wiring |
| `BJS/Features/Hub/HubViewModel.swift`, `HubView.swift`, `HubModule.swift` | 12 | Hub |
| `BJS/Design/Catalogue/FeltCatalogue.swift` | 13 | DEBUG catalogue |
| `BJS/Shared/RulesForm.swift`, `BJS/Features/Settings/SettingsView.swift`, `SettingsViewModel.swift`, `PreferenceLabels.swift` | 14 | Settings |
| `BJSUITests/FoundationUITests.swift`, `project.yml` | 15 | UI smoke test |
| `docs/superpowers/progress.md` | 16 | Handoff, freeze record |

Tests mirror the source layout under `BJSTests/` (e.g. `BJSTests/Design/FeltTokenTests.swift`).

---

### Task 1: Colour tokens and contrast requirements

**Files:**
- Create: `BJS/Design/Tokens/FeltRGB.swift`
- Create: `BJS/Design/Tokens/FeltPalette.swift`
- Create: `BJS/Design/Tokens/FeltColor.swift`
- Create: `BJS/Design/Tokens/FeltContrast.swift`
- Test: `BJSTests/Design/FeltColorTests.swift`

**Interfaces:**
- Produces:
  - `struct FeltRGB: Hashable, Sendable` with `init(_ hex: UInt32)`, `hex: UInt32`, `color: Color`, `over(_:opacity:) -> FeltRGB`, `relativeLuminance: Double` and `contrastRatio(with:) -> Double`.
  - `enum FeltPalette`: one `static let` per token, plus `glowOpacity`, `surfaceInsetOpacity`, `glowCentre` and `surfaceInsetOnBase`.
  - `enum FeltColor`: one `static let <token>: Color` per token, plus `surfaceInset`.
  - `struct ContrastRequirement` and `enum FeltContrast` with `static let requirements: [ContrastRequirement]`.

- [ ] **Step 1: Write the failing tests**

`BJSTests/Design/FeltColorTests.swift`:

```swift
import Testing
@testable import BJS

@MainActor
struct FeltColorTests {

    @Test("Token hex values match spec §4")
    func tokenValues() {
        #expect(FeltPalette.feltDeep.hex == 0x0C2A1F)
        #expect(FeltPalette.feltBase.hex == 0x123A2B)
        #expect(FeltPalette.feltLight.hex == 0x1F5A43)
        #expect(FeltPalette.cream.hex == 0xFBFAF6)
        #expect(FeltPalette.onCream.hex == 0x123A2B)
        #expect(FeltPalette.onCreamSecondary.hex == 0x3D6B57)
        #expect(FeltPalette.brass.hex == 0xD9B45A)
        #expect(FeltPalette.correct.hex == 0x6EE7A0)
        #expect(FeltPalette.incorrect.hex == 0xFF6B5B)
        #expect(FeltPalette.suitRed.hex == 0xD23B3B)
        #expect(FeltPalette.suitBlack.hex == 0x111111)
        #expect(FeltPalette.textPrimary.hex == 0xEEF3EE)
        #expect(FeltPalette.textSecondary.hex == 0xA9C4B6)
        #expect(FeltPalette.textTertiary.hex == 0x8FB3A2)
        #expect(FeltPalette.surfaceInsetOpacity == 0.22)
        #expect(FeltPalette.glowOpacity == 0.45)
    }

    @Test("Effective surfaces: glow centre #184836, inset over base #0E2D22")
    func effectiveSurfaces() {
        #expect(FeltPalette.glowCentre.hex == 0x184836)
        #expect(FeltPalette.surfaceInsetOnBase.hex == 0x0E2D22)
    }

    @Test("Contrast maths: black on white is 21:1, a colour on itself is 1:1")
    func contrastMaths() {
        let black = FeltRGB(0x000000), white = FeltRGB(0xFFFFFF)
        #expect(abs(black.contrastRatio(with: white) - 21) < 0.001)
        #expect(abs(white.contrastRatio(with: black) - 21) < 0.001)
        #expect(abs(FeltPalette.cream.contrastRatio(with: FeltPalette.cream) - 1) < 0.001)
    }

    @Test("Compositing rounds each channel")
    func compositing() {
        #expect(FeltRGB(0xFFFFFF).over(FeltRGB(0x000000), opacity: 0.5).hex == 0x808080)
        #expect(FeltRGB(0x123456).over(FeltRGB(0x000000), opacity: 1).hex == 0x123456)
    }

    @Test("Every contrast requirement passes")
    func requirementsPass() {
        for r in FeltContrast.requirements {
            #expect(r.passes, "\(r.id): \(r.ratio) < \(r.minimum)")
        }
    }

    @Test("Requirement list covers every text-on-surface pairing")
    func requirementCoverage() {
        let ids = Set(FeltContrast.requirements.map { $0.id })
        #expect(FeltContrast.requirements.count == 31)
        #expect(ids.count == 31)
        for surface in ["feltBase", "glowCentre", "surfaceInset", "feltDeep"] {
            for text in ["textPrimary", "textSecondary", "textTertiary", "brass", "correct", "incorrect"] {
                #expect(ids.contains("\(text) on \(surface)"))
            }
        }
        for text in ["onCream", "onCreamSecondary", "suitRed", "suitBlack"] {
            #expect(ids.contains("\(text) on cream"))
        }
        #expect(ids.contains("feltDeep on correct"))
        #expect(ids.contains("feltDeep on incorrect"))
        #expect(ids.contains("cream on feltBase"))
        let large = FeltContrast.requirements.filter { $0.foregroundName == "correct" || $0.foregroundName == "incorrect" }
        #expect(large.allSatisfy { $0.minimum == FeltContrast.largeText })
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/FeltColorTests`.
Expected: build failure, `cannot find 'FeltPalette' in scope`.

- [ ] **Step 3: Implement**

`BJS/Design/Tokens/FeltRGB.swift`:

```swift
import SwiftUI

/// An opaque sRGB colour with WCAG 2.x contrast maths, so token pairings can be unit-tested.
struct FeltRGB: Hashable, Sendable {
    let hex: UInt32

    init(_ hex: UInt32) {
        self.hex = hex & 0xFFFFFF
    }

    var red: Double { Double((hex >> 16) & 0xFF) / 255 }
    var green: Double { Double((hex >> 8) & 0xFF) / 255 }
    var blue: Double { Double(hex & 0xFF) / 255 }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }

    /// This colour drawn at `opacity` over `background`, rounded to 8-bit channels.
    func over(_ background: FeltRGB, opacity: Double) -> FeltRGB {
        func channel(_ shift: UInt32) -> UInt32 {
            let fg = Double((hex >> shift) & 0xFF)
            let bg = Double((background.hex >> shift) & 0xFF)
            return UInt32((opacity * fg + (1 - opacity) * bg).rounded()) << shift
        }
        return FeltRGB(channel(16) | channel(8) | channel(0))
    }

    /// WCAG 2.x relative luminance.
    var relativeLuminance: Double {
        func linear(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// WCAG 2.x contrast ratio, 1...21, order-independent.
    func contrastRatio(with other: FeltRGB) -> Double {
        let a = relativeLuminance, b = other.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}
```

`BJS/Design/Tokens/FeltPalette.swift`:

```swift
/// Raw Felt colour tokens (parent spec §4). FROZEN after Step 2: changing a value
/// needs an explicit decision from Luke in its own change.
enum FeltPalette {
    static let feltDeep = FeltRGB(0x0C2A1F)
    static let feltBase = FeltRGB(0x123A2B)
    static let feltLight = FeltRGB(0x1F5A43)
    static let cream = FeltRGB(0xFBFAF6)
    static let onCream = FeltRGB(0x123A2B)
    static let onCreamSecondary = FeltRGB(0x3D6B57)
    static let brass = FeltRGB(0xD9B45A)
    static let correct = FeltRGB(0x6EE7A0)
    static let incorrect = FeltRGB(0xFF6B5B)
    static let suitRed = FeltRGB(0xD23B3B)
    static let suitBlack = FeltRGB(0x111111)
    static let textPrimary = FeltRGB(0xEEF3EE)
    static let textSecondary = FeltRGB(0xA9C4B6)
    static let textTertiary = FeltRGB(0x8FB3A2)

    /// `surfaceInset` is black at this opacity.
    static let surfaceInsetOpacity = 0.22
    /// `FeltBackground` draws `feltLight` at this opacity over `feltBase` (Step 2 spec §1).
    static let glowOpacity = 0.45

    /// The brightest point of the felt: `feltLight` at `glowOpacity` over `feltBase` (#184836).
    static let glowCentre = feltLight.over(feltBase, opacity: glowOpacity)
    /// `surfaceInset` as it renders over `feltBase` (#0E2D22).
    static let surfaceInsetOnBase = FeltRGB(0x000000).over(feltBase, opacity: surfaceInsetOpacity)
}
```

`BJS/Design/Tokens/FeltColor.swift`:

```swift
import SwiftUI

/// Felt colour tokens for views. Values come from `FeltPalette`.
enum FeltColor {
    static let feltDeep = FeltPalette.feltDeep.color
    static let feltBase = FeltPalette.feltBase.color
    static let feltLight = FeltPalette.feltLight.color
    static let surfaceInset = Color.black.opacity(FeltPalette.surfaceInsetOpacity)
    static let cream = FeltPalette.cream.color
    static let onCream = FeltPalette.onCream.color
    static let onCreamSecondary = FeltPalette.onCreamSecondary.color
    static let brass = FeltPalette.brass.color
    static let correct = FeltPalette.correct.color
    static let incorrect = FeltPalette.incorrect.color
    static let suitRed = FeltPalette.suitRed.color
    static let suitBlack = FeltPalette.suitBlack.color
    static let textPrimary = FeltPalette.textPrimary.color
    static let textSecondary = FeltPalette.textSecondary.color
    static let textTertiary = FeltPalette.textTertiary.color
}
```

`BJS/Design/Tokens/FeltContrast.swift`:

```swift
/// One text-or-glyph colour on one surface, with the WCAG minimum it must meet.
struct ContrastRequirement: Identifiable, Sendable {
    let foregroundName: String
    let foreground: FeltRGB
    let backgroundName: String
    let background: FeltRGB
    let minimum: Double

    var id: String { "\(foregroundName) on \(backgroundName)" }
    var ratio: Double { foreground.contrastRatio(with: background) }
    var passes: Bool { ratio >= minimum }
}

/// Every colour pairing the app draws text or glyphs with (Step 2 spec §1).
/// Tested in `FeltColorTests` and shown in the DEBUG `FeltCatalogue`.
enum FeltContrast {
    /// WCAG AA body text.
    static let bodyText = 4.5
    /// WCAG AA large text (≥ 17 pt semibold) and glyphs.
    static let largeText = 3.0

    static let requirements: [ContrastRequirement] = {
        let feltSurfaces: [(String, FeltRGB)] = [
            ("feltBase", FeltPalette.feltBase),
            ("glowCentre", FeltPalette.glowCentre),
            ("surfaceInset", FeltPalette.surfaceInsetOnBase),
            ("feltDeep", FeltPalette.feltDeep),
        ]
        let feltText: [(String, FeltRGB, Double)] = [
            ("textPrimary", FeltPalette.textPrimary, bodyText),
            ("textSecondary", FeltPalette.textSecondary, bodyText),
            ("textTertiary", FeltPalette.textTertiary, bodyText),
            ("brass", FeltPalette.brass, bodyText),
            ("correct", FeltPalette.correct, largeText),
            ("incorrect", FeltPalette.incorrect, largeText),
        ]
        let creamText: [(String, FeltRGB)] = [
            ("onCream", FeltPalette.onCream),
            ("onCreamSecondary", FeltPalette.onCreamSecondary),
            ("suitRed", FeltPalette.suitRed),
            ("suitBlack", FeltPalette.suitBlack),
        ]

        var result: [ContrastRequirement] = []
        for (surfaceName, surface) in feltSurfaces {
            for (textName, text, minimum) in feltText {
                result.append(ContrastRequirement(foregroundName: textName, foreground: text,
                                                  backgroundName: surfaceName, background: surface,
                                                  minimum: minimum))
            }
        }
        for (textName, text) in creamText {
            result.append(ContrastRequirement(foregroundName: textName, foreground: text,
                                              backgroundName: "cream", background: FeltPalette.cream,
                                              minimum: bodyText))
        }
        // FeedbackCard badge glyphs and its NEXT button text.
        result.append(ContrastRequirement(foregroundName: "feltDeep", foreground: FeltPalette.feltDeep,
                                          backgroundName: "correct", background: FeltPalette.correct,
                                          minimum: bodyText))
        result.append(ContrastRequirement(foregroundName: "feltDeep", foreground: FeltPalette.feltDeep,
                                          backgroundName: "incorrect", background: FeltPalette.incorrect,
                                          minimum: bodyText))
        result.append(ContrastRequirement(foregroundName: "cream", foreground: FeltPalette.cream,
                                          backgroundName: "feltBase", background: FeltPalette.feltBase,
                                          minimum: bodyText))
        return result
    }()
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the app test command with `-only-testing:BJSTests/FeltColorTests`.
Expected: 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJS/Design/Tokens BJSTests/Design/FeltColorTests.swift
git commit -m "feat(design): Felt colour tokens with tested WCAG contrast"
```

---

### Task 2: Type, layout and motion tokens; background and surface components

**Files:**
- Create: `BJS/Design/Tokens/FeltType.swift`
- Create: `BJS/Design/Tokens/FeltLayout.swift`
- Create: `BJS/Design/Tokens/FeltMotion.swift`
- Create: `BJS/Design/Components/FeltBackground.swift`
- Create: `BJS/Design/Components/FeltTabBarAppearance.swift`
- Create: `BJS/Design/Components/StatChip.swift`
- Create: `BJS/Design/Components/ModuleTile.swift`
- Create: `BJS/Design/Components/FeltButtons.swift`
- Create: `BJS/Design/Components/ModePicker.swift`
- Create: `BJS/Design/Components/SettingsRow.swift`
- Create: `BJS/Design/Components/ComingSoonView.swift`
- Test: `BJSTests/Design/FeltLayoutTokenTests.swift`

**Interfaces:**
- Consumes: `FeltColor`, `FeltPalette` (Task 1).
- Produces:
  - `enum FeltType { case display, title, body, label, stat }` with `font`, `tracking` and `isUppercase`, plus `View.feltText(_:)`.
  - `enum FeltSpacing` (`xs` 4, `s` 8, `m` 12, `l` 16, `xl` 24, `xxl` 32, `scale`) and `enum FeltRadius` (`chip`, `tile`, `button`, `card`, `sheet`).
  - `enum FeltMotion`: `uiDuration`, `dealDuration`, `flipDuration`, `ui`, `deal`, `flip`, `revealStyle(reduceMotion:)`, `dealTransition(reduceMotion:)` and `CardRevealStyle`.
  - `FeltBackground()`, `FeltTabBarAppearance.apply()`, `StatChip(label:value:)` and `ModuleTile(title:subtitle:action:)`.
  - `PrimaryButton(title:action:)`, `SecondaryButton(title:action:)` and `ModePicker(options:selection:title:)`.
  - `SettingsSection(title:content:)`, `SettingsRow(label:footnote:accessory:)` and `ComingSoonView(title:message:onClose:)`.

- [ ] **Step 1: Write the failing tests**

`BJSTests/Design/FeltLayoutTokenTests.swift`:

```swift
import Testing
@testable import BJS

@MainActor
struct FeltLayoutTokenTests {

    @Test("Spacing scale is 4, 8, 12, 16, 24, 32")
    func spacing() {
        #expect(FeltSpacing.scale == [4, 8, 12, 16, 24, 32])
        #expect([FeltSpacing.xs, FeltSpacing.s, FeltSpacing.m, FeltSpacing.l, FeltSpacing.xl, FeltSpacing.xxl]
                == FeltSpacing.scale)
    }

    @Test("Corner radii: chip 10, tile/button 14, card 8, sheet 16")
    func radii() {
        #expect(FeltRadius.chip == 10)
        #expect(FeltRadius.tile == 14)
        #expect(FeltRadius.button == 14)
        #expect(FeltRadius.card == 8)
        #expect(FeltRadius.sheet == 16)
    }

    @Test("Motion durations: UI 0.2 s, deal 0.25 s, flip 0.35 s")
    func motion() {
        #expect(FeltMotion.uiDuration == 0.2)
        #expect(FeltMotion.dealDuration == 0.25)
        #expect(FeltMotion.flipDuration == 0.35)
    }

    @Test("Reduce Motion swaps the card flip for a cross-fade")
    func reduceMotion() {
        #expect(FeltMotion.revealStyle(reduceMotion: false) == .flip)
        #expect(FeltMotion.revealStyle(reduceMotion: true) == .crossFade)
    }

    @Test("Only the label role is uppercase and tracked (+0.14 em at 11 pt)")
    func typeRoles() {
        #expect(FeltType.label.isUppercase)
        #expect(abs(FeltType.label.tracking - 1.54) < 0.001)
        for role in [FeltType.display, .title, .body, .stat] {
            #expect(!role.isUppercase)
            #expect(role.tracking == 0)
        }
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/FeltLayoutTokenTests`.
Expected: build failure, `cannot find 'FeltSpacing' in scope`.

- [ ] **Step 3: Implement the tokens**

`BJS/Design/Tokens/FeltType.swift`:

```swift
import SwiftUI

/// Felt type roles (parent spec §4). Built on Dynamic Type text styles so they scale.
enum FeltType: CaseIterable {
    case display, title, body, label, stat

    var font: Font {
        switch self {
        case .display: return .title.bold()                       // 28 pt bold
        case .title: return .title3.weight(.semibold)             // 20 pt semibold
        case .body: return .subheadline                           // 15 pt regular
        case .label: return .caption2.weight(.semibold)           // 11 pt semibold
        case .stat: return .system(.title2, design: .monospaced)  // 22 pt semibold SF Mono
            .weight(.semibold).monospacedDigit()
        }
    }

    /// Letter spacing in points: +0.14 em at 11 pt for `label`, none otherwise.
    var tracking: CGFloat { self == .label ? 11 * 0.14 : 0 }

    var isUppercase: Bool { self == .label }
}

extension View {
    /// Applies a Felt type role: font, tracking and case.
    func feltText(_ role: FeltType) -> some View {
        font(role.font)
            .tracking(role.tracking)
            .textCase(role.isUppercase ? .uppercase : nil)
    }
}
```

`BJS/Design/Tokens/FeltLayout.swift`:

```swift
import CoreGraphics

/// Felt spacing scale (parent spec §4).
enum FeltSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    static let scale: [CGFloat] = [xs, s, m, l, xl, xxl]
}

/// Felt corner radii (parent spec §4).
enum FeltRadius {
    static let chip: CGFloat = 10
    static let tile: CGFloat = 14
    static let button: CGFloat = 14
    static let card: CGFloat = 8
    static let sheet: CGFloat = 16
}

/// The minimum tap target for every control.
enum FeltTapTarget {
    static let minimum: CGFloat = 44
}
```

`BJS/Design/Tokens/FeltMotion.swift`:

```swift
import SwiftUI

/// How a face-down card is revealed.
enum CardRevealStyle: Equatable {
    case flip
    case crossFade
}

/// Felt motion (parent spec §4). Every animation honours Reduce Motion by cross-fading.
enum FeltMotion {
    static let uiDuration: Double = 0.2
    static let dealDuration: Double = 0.25
    static let flipDuration: Double = 0.35

    static let ui: Animation = .easeOut(duration: uiDuration)
    static let deal: Animation = .easeOut(duration: dealDuration)
    static let flip: Animation = .easeInOut(duration: flipDuration)

    static func revealStyle(reduceMotion: Bool) -> CardRevealStyle {
        reduceMotion ? .crossFade : .flip
    }

    /// A card arriving on the table: slides in from the top, or cross-fades under Reduce Motion.
    static func dealTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the app test command with `-only-testing:BJSTests/FeltLayoutTokenTests`.
Expected: 5 tests pass.

- [ ] **Step 5: Implement the background and surface components**

`BJS/Design/Components/FeltBackground.swift`:

```swift
import SwiftUI

/// The felt: `feltBase` with a soft `feltLight` glow near the top, darkening to `feltDeep` at the edges.
struct FeltBackground: View {
    var body: some View {
        ZStack {
            FeltColor.feltBase
            RadialGradient(colors: [FeltColor.feltLight.opacity(FeltPalette.glowOpacity), .clear],
                           center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: 420)
            RadialGradient(colors: [.clear, FeltColor.feltDeep],
                           center: .center, startRadius: 300, endRadius: 720)
        }
        .ignoresSafeArea()
    }
}
```

`BJS/Design/Components/FeltTabBarAppearance.swift`:

```swift
import SwiftUI
import UIKit

/// Gives the system tab bar an opaque `feltDeep` base.
enum FeltTabBarAppearance {
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(FeltColor.feltDeep)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
```

`BJS/Design/Components/StatChip.swift`:

```swift
import SwiftUI

/// A label over a mono stat value, on `surfaceInset`.
struct StatChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            Text(label)
                .feltText(.label)
                .foregroundStyle(FeltColor.textTertiary)
            Text(value)
                .feltText(.stat)
                .foregroundStyle(FeltColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FeltSpacing.m)
        .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip))
        .accessibilityElement(children: .combine)
    }
}
```

`BJS/Design/Components/ModuleTile.swift`:

```swift
import SwiftUI

/// A tappable module entry: title and subtitle on `surfaceInset`.
struct ModuleTile: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FeltSpacing.m) {
                VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                    Text(title)
                        .feltText(.title)
                        .foregroundStyle(FeltColor.textPrimary)
                    Text(subtitle)
                        .feltText(.body)
                        .foregroundStyle(FeltColor.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(FeltColor.textTertiary)
            }
            .padding(FeltSpacing.l)
            .frame(maxWidth: .infinity, minHeight: FeltTapTarget.minimum, alignment: .leading)
            .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.tile))
            .contentShape(RoundedRectangle(cornerRadius: FeltRadius.tile))
        }
        .buttonStyle(.plain)
    }
}
```

`BJS/Design/Components/FeltButtons.swift`:

```swift
import SwiftUI

/// Cream-filled primary action.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .feltText(.title)
                .foregroundStyle(FeltColor.onCream)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(FeltColor.cream, in: RoundedRectangle(cornerRadius: FeltRadius.button))
                .contentShape(RoundedRectangle(cornerRadius: FeltRadius.button))
        }
        .buttonStyle(.plain)
    }
}

/// Cream-outlined secondary action on felt.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .feltText(.title)
                .foregroundStyle(FeltColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .overlay(RoundedRectangle(cornerRadius: FeltRadius.button)
                    .strokeBorder(FeltColor.cream.opacity(0.7), lineWidth: 1.5))
                .contentShape(RoundedRectangle(cornerRadius: FeltRadius.button))
        }
        .buttonStyle(.plain)
    }
}
```

`BJS/Design/Components/ModePicker.swift`:

```swift
import SwiftUI

/// Segmented control on `surfaceInset`; the selected segment is cream.
struct ModePicker<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        HStack(spacing: FeltSpacing.xs) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(FeltMotion.ui) { selection = option }
                } label: {
                    Text(title(option))
                        .font(FeltType.body.font.weight(.semibold))
                        .foregroundStyle(isSelected ? FeltColor.onCream : FeltColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: FeltTapTarget.minimum)
                        .background(isSelected ? FeltColor.cream : .clear,
                                    in: RoundedRectangle(cornerRadius: FeltRadius.chip))
                        .contentShape(RoundedRectangle(cornerRadius: FeltRadius.chip))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(FeltSpacing.xs)
        .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip + FeltSpacing.xs))
    }
}
```

`BJS/Design/Components/SettingsRow.swift`:

```swift
import SwiftUI

/// A titled group of `SettingsRow`s on `surfaceInset`, with hairline separators between rows.
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text(title)
                .feltText(.label)
                .foregroundStyle(FeltColor.textTertiary)
                .padding(.leading, FeltSpacing.l)
            VStack(spacing: 0) {
                Group(subviews: content) { rows in
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        if index > 0 {
                            Rectangle()
                                .fill(FeltColor.textTertiary.opacity(0.25))
                                .frame(height: 0.5)
                                .padding(.leading, FeltSpacing.l)
                        }
                        row
                    }
                }
            }
            .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.tile))
        }
    }
}

/// Label on the left, a value/toggle/picker accessory on the right, optional footnote below.
struct SettingsRow<Accessory: View>: View {
    let label: String
    var footnote: String? = nil
    @ViewBuilder let accessory: Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            HStack(spacing: FeltSpacing.m) {
                Text(label)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textPrimary)
                Spacer(minLength: FeltSpacing.s)
                accessory
                    .foregroundStyle(FeltColor.textSecondary)
                    .tint(FeltColor.textSecondary)
            }
            .frame(minHeight: FeltTapTarget.minimum)
            if let footnote {
                Text(footnote)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.vertical, FeltSpacing.xs)
    }
}
```

`BJS/Design/Components/ComingSoonView.swift`:

```swift
import SwiftUI

/// Placeholder screen for modules that later steps build.
struct ComingSoonView: View {
    let title: String
    let message: String
    var onClose: (() -> Void)? = nil

    var body: some View {
        ZStack {
            FeltBackground()
            VStack(spacing: FeltSpacing.m) {
                Text(title)
                    .feltText(.display)
                    .foregroundStyle(FeltColor.textPrimary)
                Text(message)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textSecondary)
                if let onClose {
                    SecondaryButton(title: "Close", action: onClose)
                        .frame(maxWidth: 200)
                        .padding(.top, FeltSpacing.l)
                }
            }
            .padding(FeltSpacing.xl)
        }
    }
}
```

- [ ] **Step 6: Build and run all app tests**

Run the app test command.
Expected: all tests pass (Task 1 and 2 suites, plus `AppShellTests`), and no warnings in `BJS/Design/`.

- [ ] **Step 7: Commit**

```bash
git add BJS/Design BJSTests/Design/FeltLayoutTokenTests.swift
git commit -m "feat(design): Felt type, layout and motion tokens with surface components"
```

---

### Task 3: PlayingCard and HandView

**Files:**
- Create: `BJS/Design/Components/CardNames.swift`
- Create: `BJS/Design/Components/PlayingCard.swift`
- Create: `BJS/Design/Components/HandView.swift`
- Test: `BJSTests/Design/PlayingCardTests.swift`

**Interfaces:**
- Consumes: `Card`, `Rank`, `Suit` (BJSCore); the Task 1–2 tokens.
- Produces:
  - `Rank.indexLabel`, `Rank.spokenName`, `Suit.symbolName`, `Suit.spokenName`, `Suit.isRed` and `Card.spokenName`.
  - `PlayingCardMetrics.aspectRatio`, `PlayingCardMetrics.height(forWidth:)` and `PlayingCard(card:isFaceUp:width:)`.
  - `PlayingCard.accessibilityText(card:isFaceUp:) -> String`.
  - `HandLayout.offsets(count:cardWidth:overlap:)` and `HandLayout.totalWidth(count:cardWidth:overlap:)`.
  - `HandView(cards:faceDownIndices:cardWidth:overlap:totalLabel:)`.

- [ ] **Step 1: Write the failing tests**

`BJSTests/Design/PlayingCardTests.swift`:

```swift
import Testing
import BJSCore
@testable import BJS

@MainActor
struct PlayingCardTests {

    @Test("VoiceOver names read like 'Eight of clubs'")
    func spokenNames() {
        #expect(Card(rank: .eight, suit: .clubs).spokenName == "Eight of clubs")
        #expect(Card(rank: .ace, suit: .spades).spokenName == "Ace of spades")
        #expect(Card(rank: .ten, suit: .hearts).spokenName == "Ten of hearts")
        #expect(Card(rank: .jack, suit: .diamonds).spokenName == "Jack of diamonds")
    }

    @Test("All 52 cards have distinct names")
    func allNamesDistinct() {
        let names = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(rank: $0, suit: suit).spokenName } }
        #expect(Set(names).count == 52)
    }

    @Test("Index labels: A K Q J 10 … 2")
    func indexLabels() {
        #expect(Rank.allCases.map { $0.indexLabel }
                == ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"])
    }

    @Test("Hearts and diamonds are red; suits use SF Symbols")
    func suits() {
        #expect(Suit.hearts.isRed && Suit.diamonds.isRed)
        #expect(!Suit.clubs.isRed && !Suit.spades.isRed)
        #expect(Suit.hearts.symbolName == "suit.heart.fill")
        #expect(Suit.diamonds.symbolName == "suit.diamond.fill")
        #expect(Suit.clubs.symbolName == "suit.club.fill")
        #expect(Suit.spades.symbolName == "suit.spade.fill")
    }

    @Test("A face-down card is announced without revealing it")
    func faceDownLabel() {
        let card = Card(rank: .king, suit: .hearts)
        #expect(PlayingCard.accessibilityText(card: card, isFaceUp: true) == "King of hearts")
        #expect(PlayingCard.accessibilityText(card: card, isFaceUp: false) == "Face-down card")
    }

    @Test("Card height is width × 1.4")
    func aspect() {
        #expect(PlayingCardMetrics.aspectRatio == 1.4)
        #expect(PlayingCardMetrics.height(forWidth: 70) == 98)
    }

    @Test("Hand layout offsets each card by the visible fraction of its width")
    func handLayout() {
        #expect(HandLayout.offsets(count: 3, cardWidth: 100, overlap: 0.5) == [0, 50, 100])
        #expect(HandLayout.totalWidth(count: 3, cardWidth: 100, overlap: 0.5) == 200)
        #expect(HandLayout.totalWidth(count: 1, cardWidth: 100, overlap: 0.5) == 100)
        #expect(HandLayout.totalWidth(count: 0, cardWidth: 100, overlap: 0.5) == 0)
        #expect(HandLayout.offsets(count: 0, cardWidth: 100, overlap: 0.5).isEmpty)
    }
}
```

The `HandLayout` test uses overlap 0.5 and width 100 so every expected value is exact in binary floating point.

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/PlayingCardTests`.
Expected: build failure, `value of type 'Card' has no member 'spokenName'`.

- [ ] **Step 3: Implement**

`BJS/Design/Components/CardNames.swift`:

```swift
import BJSCore

extension Rank {
    /// The corner index: "A", "K", "Q", "J", "10" … "2".
    var indexLabel: String {
        switch self {
        case .ace: return "A"
        case .king: return "K"
        case .queen: return "Q"
        case .jack: return "J"
        default: return String(rawValue)
        }
    }

    var spokenName: String {
        switch self {
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
}

extension Suit {
    var symbolName: String {
        switch self {
        case .hearts: return "suit.heart.fill"
        case .diamonds: return "suit.diamond.fill"
        case .clubs: return "suit.club.fill"
        case .spades: return "suit.spade.fill"
        }
    }

    var spokenName: String { rawValue }

    var isRed: Bool { self == .hearts || self == .diamonds }
}

extension Card {
    /// VoiceOver name, e.g. "Eight of clubs".
    var spokenName: String { "\(rank.spokenName) of \(suit.spokenName)" }
}
```

`BJS/Design/Components/PlayingCard.swift`:

```swift
import SwiftUI
import BJSCore

enum PlayingCardMetrics {
    static let aspectRatio: CGFloat = 1.4

    static func height(forWidth width: CGFloat) -> CGFloat { width * aspectRatio }
}

/// A card drawn in SwiftUI: rank + suit index top-left, large suit bottom-right, cream face.
/// The back is a cream border around diagonal felt stripes.
struct PlayingCard: View {
    let card: Card
    var isFaceUp: Bool = true
    let width: CGFloat

    static func accessibilityText(card: Card, isFaceUp: Bool) -> String {
        isFaceUp ? card.spokenName : "Face-down card"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FeltRadius.card)
                .fill(FeltColor.cream)
            if isFaceUp { face } else { back }
        }
        .frame(width: width, height: PlayingCardMetrics.height(forWidth: width))
        .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
        .accessibilityElement()
        .accessibilityLabel(Self.accessibilityText(card: card, isFaceUp: isFaceUp))
    }

    private var face: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                Text(card.rank.indexLabel)
                    .font(.system(size: width * 0.3, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Image(systemName: card.suit.symbolName)
                    .font(.system(size: width * 0.2))
            }
            .padding(width * 0.08)
            Image(systemName: card.suit.symbolName)
                .font(.system(size: width * 0.42))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(width * 0.1)
        }
        .foregroundStyle(card.suit.isRed ? FeltColor.suitRed : FeltColor.suitBlack)
    }

    private var back: some View {
        let inner = RoundedRectangle(cornerRadius: max(FeltRadius.card - 3, 2))
        return inner
            .fill(FeltColor.feltBase)
            .overlay(DiagonalStripes(spacing: width * 0.12)
                .stroke(FeltColor.feltLight, lineWidth: width * 0.03))
            .clipShape(inner)
            .padding(width * 0.07)
    }
}

/// Parallel 45° lines filling a rectangle.
struct DiagonalStripes: Shape {
    var spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = max(spacing, 2)
        var x = rect.minX - rect.height
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            x += step
        }
        return path
    }
}
```

`BJS/Design/Components/HandView.swift`:

```swift
import SwiftUI
import BJSCore

/// Horizontal positions for overlapping cards. `overlap` is the hidden fraction of each card (0 = side by side).
enum HandLayout {
    static func offsets(count: Int, cardWidth: CGFloat, overlap: CGFloat) -> [CGFloat] {
        (0..<max(count, 0)).map { CGFloat($0) * cardWidth * (1 - overlap) }
    }

    static func totalWidth(count: Int, cardWidth: CGFloat, overlap: CGFloat) -> CGFloat {
        count <= 0 ? 0 : cardWidth + CGFloat(count - 1) * cardWidth * (1 - overlap)
    }
}

/// Overlapping cards with an optional total label beneath.
struct HandView: View {
    let cards: [Card]
    var faceDownIndices: Set<Int> = []
    let cardWidth: CGFloat
    var overlap: CGFloat = 0.55
    var totalLabel: String? = nil

    var body: some View {
        let offsets = HandLayout.offsets(count: cards.count, cardWidth: cardWidth, overlap: overlap)
        VStack(spacing: FeltSpacing.s) {
            ZStack(alignment: .topLeading) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    PlayingCard(card: card, isFaceUp: !faceDownIndices.contains(index), width: cardWidth)
                        .offset(x: offsets[index])
                }
            }
            .frame(width: HandLayout.totalWidth(count: cards.count, cardWidth: cardWidth, overlap: overlap),
                   height: PlayingCardMetrics.height(forWidth: cardWidth),
                   alignment: .topLeading)
            if let totalLabel {
                Text(totalLabel)
                    .feltText(.stat)
                    .foregroundStyle(FeltColor.textPrimary)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the app test command with `-only-testing:BJSTests/PlayingCardTests`.
Expected: 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJS/Design/Components/CardNames.swift BJS/Design/Components/PlayingCard.swift BJS/Design/Components/HandView.swift BJSTests/Design/PlayingCardTests.swift
git commit -m "feat(design): drawn PlayingCard and overlapping HandView"
```

---

### Task 4: ActionDock and FeedbackCard

**Files:**
- Create: `BJS/Design/Components/ActionDock.swift`
- Create: `BJS/Design/Components/FeedbackCard.swift`
- Test: `BJSTests/Design/ActionDockTests.swift`

**Interfaces:**
- Consumes: `Action` (BJSCore) and the tokens.
- Produces:
  - `enum ActionButtonState { case enabled, dimmed, hint }`.
  - `enum ActionDockLayout`: `topRow`, `bottomRow`, `state(for:legal:hint:)` and `title(for:)`.
  - `ActionDock(legal: Set<Action>, hint: Action? = nil, onAction: (Action) -> Void)`.
  - `enum FeedbackVerdict { case correct, incorrect }` with `glyph`, `badgeColor` and `accessibilityLabel`.
  - `FeedbackCard(verdict:headline:reason:onWhy:onNext:)`.

- [ ] **Step 1: Write the failing tests**

`BJSTests/Design/ActionDockTests.swift`:

```swift
import Testing
import BJSCore
@testable import BJS

@MainActor
struct ActionDockTests {

    @Test("Row 1 is STAND, HIT; row 2 is SPLIT, DOUBLE, SURRENDER; every action appears once")
    func rows() {
        #expect(ActionDockLayout.topRow == [.stand, .hit])
        #expect(ActionDockLayout.bottomRow == [.split, .double, .surrender])
        #expect(Set(ActionDockLayout.topRow + ActionDockLayout.bottomRow) == Set(Action.allCases))
    }

    @Test("Illegal actions are dimmed, the hinted legal action is hinted, others enabled")
    func states() {
        let legal: Set<Action> = [.hit, .stand, .double]
        #expect(ActionDockLayout.state(for: .hit, legal: legal, hint: nil) == .enabled)
        #expect(ActionDockLayout.state(for: .split, legal: legal, hint: nil) == .dimmed)
        #expect(ActionDockLayout.state(for: .double, legal: legal, hint: .double) == .hint)
        #expect(ActionDockLayout.state(for: .stand, legal: legal, hint: .double) == .enabled)
    }

    @Test("A hint on an illegal action never un-dims it")
    func illegalHintStaysDimmed() {
        #expect(ActionDockLayout.state(for: .surrender, legal: [.hit, .stand], hint: .surrender) == .dimmed)
    }

    @Test("Button titles are uppercase action names")
    func titles() {
        #expect(Action.allCases.map(ActionDockLayout.title(for:))
                == ["HIT", "STAND", "DOUBLE", "SPLIT", "SURRENDER"])
    }

    @Test("Minimum tap target is 44 pt")
    func tapTarget() {
        #expect(FeltTapTarget.minimum == 44)
        #expect(ActionDockLayout.bottomRowHeight >= FeltTapTarget.minimum)
        #expect(ActionDockLayout.topRowHeight >= FeltTapTarget.minimum)
    }

    @Test("Feedback badge: ✓ on correct, ✕ on incorrect")
    func verdicts() {
        #expect(FeedbackVerdict.correct.glyph == "checkmark")
        #expect(FeedbackVerdict.incorrect.glyph == "xmark")
        #expect(FeedbackVerdict.correct.accessibilityLabel == "Correct")
        #expect(FeedbackVerdict.incorrect.accessibilityLabel == "Incorrect")
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/ActionDockTests`.
Expected: build failure, `cannot find 'ActionDockLayout' in scope`.

- [ ] **Step 3: Implement**

`BJS/Design/Components/ActionDock.swift`:

```swift
import SwiftUI
import BJSCore

enum ActionButtonState: Equatable {
    case enabled
    /// Not allowed by the rules for this hand.
    case dimmed
    /// Learn mode: the correct play carries a brass ring.
    case hint
}

enum ActionDockLayout {
    static let topRow: [Action] = [.stand, .hit]
    static let bottomRow: [Action] = [.split, .double, .surrender]
    static let topRowHeight: CGFloat = 56
    static let bottomRowHeight: CGFloat = 48

    static func state(for action: Action, legal: Set<Action>, hint: Action?) -> ActionButtonState {
        guard legal.contains(action) else { return .dimmed }
        return action == hint ? .hint : .enabled
    }

    static func title(for action: Action) -> String { action.rawValue.uppercased() }
}

/// Row 1: STAND, HIT (cream). Row 2: SPLIT, DOUBLE, SURRENDER (inset).
struct ActionDock: View {
    let legal: Set<Action>
    var hint: Action? = nil
    let onAction: (Action) -> Void

    var body: some View {
        VStack(spacing: FeltSpacing.s) {
            HStack(spacing: FeltSpacing.s) {
                ForEach(ActionDockLayout.topRow, id: \.self) { button($0, prominent: true) }
            }
            HStack(spacing: FeltSpacing.s) {
                ForEach(ActionDockLayout.bottomRow, id: \.self) { button($0, prominent: false) }
            }
        }
    }

    private func button(_ action: Action, prominent: Bool) -> some View {
        let state = ActionDockLayout.state(for: action, legal: legal, hint: hint)
        let shape = RoundedRectangle(cornerRadius: FeltRadius.button)
        return Button { onAction(action) } label: {
            Text(ActionDockLayout.title(for: action))
                .font(prominent ? FeltType.title.font : FeltType.body.font.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(prominent ? FeltColor.onCream : FeltColor.textPrimary)
                .frame(maxWidth: .infinity,
                       minHeight: prominent ? ActionDockLayout.topRowHeight : ActionDockLayout.bottomRowHeight)
                .background(prominent ? FeltColor.cream : FeltColor.surfaceInset, in: shape)
                .overlay {
                    if state == .hint {
                        shape.strokeBorder(FeltColor.brass, lineWidth: 3)
                    }
                }
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(state == .dimmed)
        .opacity(state == .dimmed ? 0.35 : 1)
        .accessibilityHint(state == .hint ? "Suggested play" : "")
    }
}
```

`BJS/Design/Components/FeedbackCard.swift`:

```swift
import SwiftUI

enum FeedbackVerdict: Equatable {
    case correct
    case incorrect

    var glyph: String { self == .correct ? "checkmark" : "xmark" }
    var badgeColor: Color { self == .correct ? FeltColor.correct : FeltColor.incorrect }
    var accessibilityLabel: String { self == .correct ? "Correct" : "Incorrect" }
}

/// Cream card anchored at the bottom over the dock. The verdict badge straddles its top edge.
/// Text on the card is `onCream` / `onCreamSecondary`; `correct`/`incorrect` only fill the badge.
struct FeedbackCard: View {
    let verdict: FeedbackVerdict
    let headline: String
    let reason: String
    let onWhy: () -> Void
    let onNext: () -> Void

    private static let badgeSize: CGFloat = 48

    var body: some View {
        VStack(spacing: FeltSpacing.m) {
            Text(headline)
                .feltText(.title)
                .foregroundStyle(FeltColor.onCream)
                .multilineTextAlignment(.center)
            Text(reason)
                .feltText(.body)
                .foregroundStyle(FeltColor.onCreamSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: FeltSpacing.s) {
                Button(action: onWhy) {
                    Text("WHY")
                        .feltText(.title)
                        .foregroundStyle(FeltColor.onCream)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .overlay(RoundedRectangle(cornerRadius: FeltRadius.button)
                            .strokeBorder(FeltColor.onCream, lineWidth: 1.5))
                        .contentShape(RoundedRectangle(cornerRadius: FeltRadius.button))
                }
                .buttonStyle(.plain)
                Button(action: onNext) {
                    Text("NEXT")
                        .feltText(.title)
                        .foregroundStyle(FeltColor.cream)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(FeltColor.feltBase, in: RoundedRectangle(cornerRadius: FeltRadius.button))
                        .contentShape(RoundedRectangle(cornerRadius: FeltRadius.button))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.top, Self.badgeSize / 2 + FeltSpacing.m)
        .padding(.bottom, FeltSpacing.l)
        .frame(maxWidth: .infinity)
        .background(FeltColor.cream,
                    in: UnevenRoundedRectangle(topLeadingRadius: FeltRadius.sheet,
                                               topTrailingRadius: FeltRadius.sheet))
        .overlay(alignment: .top) { badge.offset(y: -Self.badgeSize / 2) }
        .accessibilityElement(children: .contain)
    }

    private var badge: some View {
        Image(systemName: verdict.glyph)
            .font(.title3.weight(.bold))
            .foregroundStyle(FeltColor.feltDeep)
            .frame(width: Self.badgeSize, height: Self.badgeSize)
            .background(verdict.badgeColor, in: Circle())
            .overlay(Circle().stroke(FeltColor.cream, lineWidth: 3))
            .accessibilityLabel(verdict.accessibilityLabel)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the app test command with `-only-testing:BJSTests/ActionDockTests`.
Expected: 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJS/Design/Components/ActionDock.swift BJS/Design/Components/FeedbackCard.swift BJSTests/Design/ActionDockTests.swift
git commit -m "feat(design): ActionDock with dimmed/hint states and FeedbackCard"
```

---

### Task 5: CountEntry and CountKeypad

**Files:**
- Create: `BJS/Design/Components/CountEntry.swift`
- Create: `BJS/Design/Components/CountKeypad.swift`
- Test: `BJSTests/Design/CountEntryTests.swift`

**Interfaces:**
- Produces:
  - `enum KeypadKey: Hashable { case digit(Int), sign, half, delete, enter }`.
  - `struct CountEntry: Equatable`: `digits`, `isNegative`, `hasHalf`, `isEmpty`, `value: Double?`, `display: String` and `mutating func apply(_ key: KeypadKey) -> Double?`. `apply` returns the submitted value on `.enter` and clears the entry.
  - `CountKeypad(entry: Binding<CountEntry>, allowsHalf: Bool = true, onSubmit: (Double) -> Void)`.

Semantics:
- At most 3 digits. A leading `0` is replaced by the next digit.
- `sign` toggles negative.
- `half` toggles `.5`.
- `delete` removes the half first, then the last digit, then the sign.
- `enter` on an empty entry does nothing and returns nil.
- `value` is nil when empty. A zero magnitude is `0` (never `-0`). The display uses U+2212 for minus.

- [ ] **Step 1: Write the failing tests**

`BJSTests/Design/CountEntryTests.swift`:

```swift
import Testing
@testable import BJS

@MainActor
struct CountEntryTests {

    func entry(_ keys: [KeypadKey]) -> CountEntry {
        var e = CountEntry()
        for key in keys { _ = e.apply(key) }
        return e
    }

    @Test("Empty entry has no value and an empty display")
    func empty() {
        let e = CountEntry()
        #expect(e.isEmpty)
        #expect(e.value == nil)
        #expect(e.display == "")
    }

    @Test("Digits build a whole number")
    func digits() {
        let e = entry([.digit(1), .digit(2)])
        #expect(e.value == 12)
        #expect(e.display == "12")
    }

    @Test("A leading zero is replaced")
    func leadingZero() {
        #expect(entry([.digit(0), .digit(7)]).display == "7")
        #expect(entry([.digit(0), .digit(0)]).display == "0")
    }

    @Test("At most three digits")
    func maxDigits() {
        #expect(entry([.digit(1), .digit(2), .digit(3), .digit(4)]).value == 123)
    }

    @Test("Sign toggles negative and displays a real minus sign")
    func sign() {
        let e = entry([.digit(4), .sign])
        #expect(e.value == -4)
        #expect(e.display == "\u{2212}4")
        #expect(entry([.digit(4), .sign, .sign]).value == 4)
        #expect(entry([.sign]).display == "\u{2212}")
        #expect(entry([.sign]).value == nil)
    }

    @Test("Half adds .5, including on its own and with a sign")
    func half() {
        #expect(entry([.digit(2), .half]).value == 2.5)
        #expect(entry([.digit(2), .half]).display == "2.5")
        #expect(entry([.half]).value == 0.5)
        #expect(entry([.half]).display == "0.5")
        #expect(entry([.digit(1), .half, .sign]).value == -1.5)
        #expect(entry([.digit(2), .half, .half]).value == 2)
    }

    @Test("Negative zero is zero")
    func negativeZero() {
        let e = entry([.digit(0), .sign])
        #expect(e.value == 0)
        #expect(e.value?.sign == .plus)
    }

    @Test("Delete removes the half, then digits, then the sign")
    func delete() {
        var e = entry([.digit(1), .digit(2), .half, .sign])
        _ = e.apply(.delete)
        #expect(e.value == -12)
        _ = e.apply(.delete)
        #expect(e.value == -1)
        _ = e.apply(.delete)
        #expect(e.display == "\u{2212}")
        _ = e.apply(.delete)
        #expect(e == CountEntry())
    }

    @Test("Enter submits the value and clears; enter on empty does nothing")
    func enter() {
        var e = entry([.digit(3), .sign])
        #expect(e.apply(.enter) == -3)
        #expect(e == CountEntry())
        #expect(e.apply(.enter) == nil)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/CountEntryTests`.
Expected: build failure, `cannot find 'CountEntry' in scope`.

- [ ] **Step 3: Implement**

`BJS/Design/Components/CountEntry.swift`:

```swift
enum KeypadKey: Hashable {
    case digit(Int)
    case sign
    case half
    case delete
    case enter
}

/// The value being typed on `CountKeypad`. Pure state, so it is unit-tested without views.
struct CountEntry: Equatable {
    static let maxDigits = 3

    private(set) var digits = ""
    private(set) var isNegative = false
    private(set) var hasHalf = false

    var isEmpty: Bool { digits.isEmpty && !hasHalf }

    var value: Double? {
        guard !isEmpty else { return nil }
        let magnitude = Double(Int(digits) ?? 0) + (hasHalf ? 0.5 : 0)
        if magnitude == 0 { return 0 }
        return isNegative ? -magnitude : magnitude
    }

    var display: String {
        let sign = isNegative ? "\u{2212}" : ""
        guard !isEmpty else { return sign }
        return sign + (digits.isEmpty ? "0" : digits) + (hasHalf ? ".5" : "")
    }

    /// Applies one key press. Returns the submitted value on `.enter` (and clears), else nil.
    mutating func apply(_ key: KeypadKey) -> Double? {
        switch key {
        case .digit(let d):
            precondition((0...9).contains(d), "digit out of range")
            if digits == "0" {
                digits = String(d)
            } else if digits.count < Self.maxDigits {
                digits += String(d)
            }
        case .sign:
            isNegative.toggle()
        case .half:
            hasHalf.toggle()
        case .delete:
            if hasHalf {
                hasHalf = false
            } else if !digits.isEmpty {
                digits.removeLast()
            } else {
                isNegative = false
            }
        case .enter:
            guard let submitted = value else { return nil }
            self = CountEntry()
            return submitted
        }
        return nil
    }
}
```

`BJS/Design/Components/CountKeypad.swift`:

```swift
import SwiftUI

/// Numeric keypad for running and true counts: 0–9, ±, .5, delete, enter.
struct CountKeypad: View {
    @Binding var entry: CountEntry
    var allowsHalf: Bool = true
    let onSubmit: (Double) -> Void

    private let digitRows: [[Int]] = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    var body: some View {
        VStack(spacing: FeltSpacing.s) {
            Text(entry.display.isEmpty ? " " : entry.display)
                .feltText(.stat)
                .foregroundStyle(FeltColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip))
                .accessibilityLabel("Entered count")
                .accessibilityValue(entry.display.isEmpty ? "Empty" : entry.display)
            ForEach(digitRows, id: \.self) { row in
                HStack(spacing: FeltSpacing.s) {
                    ForEach(row, id: \.self) { key(.digit($0)) }
                }
            }
            HStack(spacing: FeltSpacing.s) {
                key(.sign)
                key(.digit(0))
                if allowsHalf {
                    key(.half)
                } else {
                    Color.clear.frame(maxWidth: .infinity, minHeight: 52)
                }
            }
            HStack(spacing: FeltSpacing.s) {
                key(.delete)
                key(.enter)
            }
        }
    }

    private func key(_ key: KeypadKey) -> some View {
        let isEnter = key == .enter
        let shape = RoundedRectangle(cornerRadius: FeltRadius.button)
        return Button {
            if let submitted = entry.apply(key) { onSubmit(submitted) }
        } label: {
            label(for: key)
                .font(FeltType.title.font)
                .foregroundStyle(isEnter ? FeltColor.onCream : FeltColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isEnter ? FeltColor.cream : FeltColor.surfaceInset, in: shape)
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: key))
    }

    @ViewBuilder
    private func label(for key: KeypadKey) -> some View {
        switch key {
        case .digit(let d): Text(String(d))
        case .sign: Text("±")
        case .half: Text(".5")
        case .delete: Image(systemName: "delete.left")
        case .enter: Text("ENTER")
        }
    }

    private func accessibilityLabel(for key: KeypadKey) -> String {
        switch key {
        case .digit(let d): return String(d)
        case .sign: return "Toggle sign"
        case .half: return "Add one half"
        case .delete: return "Delete"
        case .enter: return "Enter"
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the app test command with `-only-testing:BJSTests/CountEntryTests`.
Expected: 9 tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJS/Design/Components/CountEntry.swift BJS/Design/Components/CountKeypad.swift BJSTests/Design/CountEntryTests.swift
git commit -m "feat(design): CountKeypad with tested CountEntry (sign, .5, delete)"
```

---

### Task 6: SessionSummary in BJSCore

The cached summary on each saved session is statistics, so it lives in `BJSCore` (architecture rule 1).

**Files:**
- Create: `BJSCore/Sources/BJSCore/Progress/SessionSummary.swift`
- Test: `BJSCore/Tests/BJSCoreTests/ProgressTests/SessionSummaryTests.swift`

**Interfaces:**
- Produces: `public struct SessionSummary: Sendable, Equatable` with `decisionCount`, `correctDecisions`, `countCheckCount`, `correctCountChecks`, `bestStreak` and `meanResponseMs: Double?`, plus `public init(decisions: [(isCorrect: Bool, responseMs: Int?)], countChecks: [Bool])`.
  - `bestStreak` is the longest run of consecutive correct decisions, in the order given.
  - `meanResponseMs` is the mean over decisions that have a `responseMs`, or nil if none do.

- [ ] **Step 1: Write the failing tests**

`BJSCore/Tests/BJSCoreTests/ProgressTests/SessionSummaryTests.swift`:

```swift
import Testing
@testable import BJSCore

@Suite("SessionSummary")
struct SessionSummaryTests {

    @Test("Empty session")
    func empty() {
        let s = SessionSummary(decisions: [], countChecks: [])
        #expect(s.decisionCount == 0)
        #expect(s.correctDecisions == 0)
        #expect(s.countCheckCount == 0)
        #expect(s.correctCountChecks == 0)
        #expect(s.bestStreak == 0)
        #expect(s.meanResponseMs == nil)
    }

    @Test("Counts and best streak are taken in order")
    func countsAndStreak() {
        let d: [(isCorrect: Bool, responseMs: Int?)] = [
            (true, nil), (true, nil), (false, nil), (true, nil), (true, nil), (true, nil), (false, nil),
        ]
        let s = SessionSummary(decisions: d, countChecks: [true, false, true])
        #expect(s.decisionCount == 7)
        #expect(s.correctDecisions == 5)
        #expect(s.bestStreak == 3)
        #expect(s.countCheckCount == 3)
        #expect(s.correctCountChecks == 2)
    }

    @Test("Mean response ignores decisions without a time")
    func meanResponse() {
        let s = SessionSummary(decisions: [(true, 1000), (false, nil), (true, 2000)], countChecks: [])
        #expect(s.meanResponseMs == 1500)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd BJSCore && swift test --filter SessionSummary 2>&1 | tail -5`
Expected: build failure, `cannot find 'SessionSummary' in scope`.

- [ ] **Step 3: Implement**

`BJSCore/Sources/BJSCore/Progress/SessionSummary.swift`:

```swift
/// The cached summary stored on each saved session.
public struct SessionSummary: Sendable, Equatable {
    public let decisionCount: Int
    public let correctDecisions: Int
    public let countCheckCount: Int
    public let correctCountChecks: Int
    /// Longest run of consecutive correct decisions, in the order given.
    public let bestStreak: Int
    /// Mean response time over decisions that recorded one; nil if none did.
    public let meanResponseMs: Double?

    public init(decisions: [(isCorrect: Bool, responseMs: Int?)], countChecks: [Bool]) {
        decisionCount = decisions.count
        correctDecisions = decisions.filter(\.isCorrect).count
        countCheckCount = countChecks.count
        correctCountChecks = countChecks.filter { $0 }.count

        var best = 0, run = 0
        for d in decisions {
            run = d.isCorrect ? run + 1 : 0
            best = max(best, run)
        }
        bestStreak = best

        let times = decisions.compactMap(\.responseMs)
        meanResponseMs = times.isEmpty ? nil : Double(times.reduce(0, +)) / Double(times.count)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd BJSCore && swift test 2>&1 | tail -5`
Expected: all tests pass (208 existing + 3 new), with no warnings.

- [ ] **Step 5: Commit**

```bash
git add BJSCore/Sources/BJSCore/Progress/SessionSummary.swift BJSCore/Tests/BJSCoreTests/ProgressTests/SessionSummaryTests.swift
git commit -m "feat(core): SessionSummary for cached per-session stats"
```

---

### Task 7: RuleLabels and RulesSummary

**Files:**
- Create: `BJS/Shared/RuleLabels.swift`
- Create: `BJS/Shared/RulesSummary.swift`
- Test: `BJSTests/Shared/RuleLabelsTests.swift`

**Interfaces:**
- Consumes: `BlackjackRules` and its nested enums, `RulePreset` and `TrueCountConvention` (BJSCore).
- Produces:
  - a `label: String` on `BlackjackRules.DeckCount`, `.DealerSoft17`, `.BlackjackPayout`, `.SurrenderRule`, `.DoubleRestriction`, `.PeekRule` and `TrueCountConvention`;
  - `RulePreset.label(for: BlackjackRules) -> String` (the preset name, or "Custom");
  - `RulesSummary.text(for: BlackjackRules) -> String`.

`RulesSummary` format, joined with `" · "` (space, U+00B7, space), in this order:
1. `"{decks}D"`.
2. `"S17"` or `"H17"`.
3. `"DAS"`, only when DAS is on.
4. `"LS"` / `"ES"`, only with surrender.
5. `"ENHC"`, only under no hole card.
6. The payout: `"3:2"` / `"6:5"` / `"2:1"`.

- [ ] **Step 1: Write the failing tests**

`BJSTests/Shared/RuleLabelsTests.swift`:

```swift
import Testing
import BJSCore
@testable import BJS

@MainActor
struct RuleLabelsTests {

    @Test("Hub summary for every preset")
    func presetSummaries() {
        #expect(RulesSummary.text(for: RulePreset.vegasStrip.rules) == "6D · S17 · DAS · 3:2")
        #expect(RulesSummary.text(for: RulePreset.downtownVegas.rules) == "2D · H17 · DAS · LS · 3:2")
        #expect(RulesSummary.text(for: RulePreset.atlanticCity.rules) == "8D · S17 · DAS · LS · 3:2")
        #expect(RulesSummary.text(for: RulePreset.singleDeckSixFive.rules) == "1D · H17 · 6:5")
        #expect(RulesSummary.text(for: RulePreset.europeanNoHoleCard.rules) == "6D · S17 · DAS · ENHC · 3:2")
    }

    @Test("Summary shows early surrender and 2:1")
    func edgeCases() {
        var r = BlackjackRules()
        r.surrenderRule = .early
        r.blackjackPayout = .twoToOne
        r.deckCount = .four
        #expect(RulesSummary.text(for: r) == "4D · S17 · DAS · ES · 2:1")
    }

    @Test("Every rule option has a distinct, non-empty label")
    func labelsCoverEveryCase() {
        func check(_ labels: [String]) {
            #expect(labels.allSatisfy { !$0.isEmpty })
            #expect(Set(labels).count == labels.count)
        }
        check(BlackjackRules.DeckCount.allCases.map { $0.label })
        check(BlackjackRules.DealerSoft17.allCases.map { $0.label })
        check(BlackjackRules.BlackjackPayout.allCases.map { $0.label })
        check(BlackjackRules.SurrenderRule.allCases.map { $0.label })
        check(BlackjackRules.DoubleRestriction.allCases.map { $0.label })
        check(BlackjackRules.PeekRule.allCases.map { $0.label })
        check(TrueCountConvention.allCases.map { $0.label })
    }

    @Test("Specific labels")
    func specificLabels() {
        #expect(BlackjackRules.DeckCount.one.label == "1 deck")
        #expect(BlackjackRules.DeckCount.six.label == "6 decks")
        #expect(BlackjackRules.BlackjackPayout.sixToFive.label == "6:5")
        #expect(BlackjackRules.PeekRule.europeanNoPeek.label == "No hole card")
        #expect(BlackjackRules.DoubleRestriction.nineToEleven.label == "9–11 only")
        #expect(TrueCountConvention.exact.label == "Exact")
    }

    @Test("Preset label is the preset name, or Custom")
    func presetLabel() {
        #expect(RulePreset.label(for: RulePreset.atlanticCity.rules) == "Atlantic City")
        var custom = RulePreset.atlanticCity.rules
        custom.resplitAces = true
        #expect(RulePreset.label(for: custom) == "Custom")
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/RuleLabelsTests`.
Expected: build failure, `cannot find 'RulesSummary' in scope`.

- [ ] **Step 3: Implement**

`BJS/Shared/RuleLabels.swift`:

```swift
import BJSCore

extension BlackjackRules.DeckCount {
    var label: String { rawValue == 1 ? "1 deck" : "\(rawValue) decks" }
}

extension BlackjackRules.DealerSoft17 {
    var label: String {
        switch self {
        case .stands: return "Stands"
        case .hits: return "Hits"
        }
    }
}

extension BlackjackRules.BlackjackPayout {
    var label: String {
        switch self {
        case .threeToTwo: return "3:2"
        case .sixToFive: return "6:5"
        case .twoToOne: return "2:1"
        }
    }
}

extension BlackjackRules.SurrenderRule {
    var label: String {
        switch self {
        case .none: return "None"
        case .late: return "Late"
        case .early: return "Early"
        }
    }
}

extension BlackjackRules.DoubleRestriction {
    var label: String {
        switch self {
        case .anyTwo: return "Any two cards"
        case .nineToEleven: return "9–11 only"
        case .tenToEleven: return "10–11 only"
        }
    }
}

extension BlackjackRules.PeekRule {
    var label: String {
        switch self {
        case .americanPeek: return "Dealer peeks"
        case .europeanNoPeek: return "No hole card"
        }
    }
}

extension TrueCountConvention {
    var label: String {
        switch self {
        case .exact: return "Exact"
        case .floor: return "Floor"
        case .truncate: return "Truncate"
        }
    }
}

extension RulePreset {
    /// The matching preset's name, or "Custom".
    static func label(for rules: BlackjackRules) -> String {
        matching(rules)?.displayName ?? "Custom"
    }
}
```

`BJS/Shared/RulesSummary.swift`:

```swift
import BJSCore

/// The compact rules line in the hub header, e.g. "6D · H17 · DAS · 3:2".
enum RulesSummary {
    static func text(for rules: BlackjackRules) -> String {
        var parts = ["\(rules.deckCount.rawValue)D",
                     rules.dealerSoft17 == .hits ? "H17" : "S17"]
        if rules.doubleAfterSplit { parts.append("DAS") }
        switch rules.surrenderRule {
        case .none: break
        case .late: parts.append("LS")
        case .early: parts.append("ES")
        }
        if rules.peekRule == .europeanNoPeek { parts.append("ENHC") }
        parts.append(rules.blackjackPayout.label)
        return parts.joined(separator: " · ")
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the app test command with `-only-testing:BJSTests/RuleLabelsTests`.
Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJS/Shared/RuleLabels.swift BJS/Shared/RulesSummary.swift BJSTests/Shared/RuleLabelsTests.swift
git commit -m "feat(app): rule display labels and hub rules summary"
```

---

### Task 8: ActiveRulesStore and PreferencesStore

`@Observable` classes support `didSet`. Re-assigning the property inside its own `didSet` does not re-trigger the observer, and observation fires once. Both were verified in a spike on 2026-09-24.

**Files:**
- Create: `BJS/Shared/ActiveRulesStore.swift`
- Create: `BJS/Shared/PreferencesStore.swift`
- Test: `BJSTests/Shared/StoreTests.swift`

**Interfaces:**
- Consumes: `BlackjackRules`, `TrueCountConvention`, `TrainingModule` (BJSCore).
- Produces:
  - `@Observable final class ActiveRulesStore`: `init(defaults: UserDefaults)`, `var rules: BlackjackRules`, `static let key = "activeRules"` and `static let maxSplitHandsRange = 2...4`.
  - `struct LastLaunch: Codable, Equatable` with `module: TrainingModule`, `mode: String?` and `setup: Data`.
  - `@Observable final class PreferencesStore`: `init(defaults: UserDefaults)`, plus `speedTimerSeconds: Double`, `trueCountConvention: TrueCountConvention`, `shoeCheckFrequency: Int`, `hapticsEnabled: Bool` and `lastLaunch: LastLaunch?`. It also exposes the static range and default constants listed below.

- [ ] **Step 1: Write the failing tests**

`BJSTests/Shared/StoreTests.swift`:

```swift
import Foundation
import Testing
import BJSCore
@testable import BJS

func makeTestDefaults() -> UserDefaults {
    let name = "BJSTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

@MainActor
struct ActiveRulesStoreTests {

    @Test("Defaults to BlackjackRules() when nothing is stored")
    func defaults() {
        #expect(ActiveRulesStore(defaults: makeTestDefaults()).rules == BlackjackRules())
    }

    @Test("Rules persist as JSON and reload")
    func roundTrip() throws {
        let d = makeTestDefaults()
        let store = ActiveRulesStore(defaults: d)
        store.rules = RulePreset.downtownVegas.rules
        #expect(d.data(forKey: ActiveRulesStore.key) != nil)
        #expect(ActiveRulesStore(defaults: d).rules == RulePreset.downtownVegas.rules)
    }

    @Test("Corrupt JSON falls back to defaults")
    func corrupt() {
        let d = makeTestDefaults()
        d.set(Data("not json".utf8), forKey: ActiveRulesStore.key)
        #expect(ActiveRulesStore(defaults: d).rules == BlackjackRules())
    }

    @Test("maxSplitHands is clamped to 2…4 on set and on load")
    func clampSplitHands() throws {
        let d = makeTestDefaults()
        let store = ActiveRulesStore(defaults: d)
        var r = BlackjackRules()
        r.maxSplitHands = 1
        store.rules = r
        #expect(store.rules.maxSplitHands == 2)
        r.maxSplitHands = 9
        store.rules = r
        #expect(store.rules.maxSplitHands == 4)
        #expect(ActiveRulesStore(defaults: d).rules.maxSplitHands == 4)

        var stored = BlackjackRules()
        stored.maxSplitHands = 1
        d.set(try JSONEncoder().encode(stored), forKey: ActiveRulesStore.key)
        #expect(ActiveRulesStore(defaults: d).rules.maxSplitHands == 2)
    }
}

@MainActor
struct PreferencesStoreTests {

    @Test("Defaults: 3.0 s, Exact, every 4 rounds, haptics on, no last launch")
    func defaults() {
        let p = PreferencesStore(defaults: makeTestDefaults())
        #expect(p.speedTimerSeconds == 3.0)
        #expect(p.trueCountConvention == .exact)
        #expect(p.shoeCheckFrequency == 4)
        #expect(p.hapticsEnabled)
        #expect(p.lastLaunch == nil)
    }

    @Test("Values persist and reload")
    func roundTrip() {
        let d = makeTestDefaults()
        let p = PreferencesStore(defaults: d)
        p.speedTimerSeconds = 2.5
        p.trueCountConvention = .floor
        p.shoeCheckFrequency = 6
        p.hapticsEnabled = false
        p.lastLaunch = LastLaunch(module: .strategy, mode: "learn", setup: Data([1, 2, 3]))
        let reloaded = PreferencesStore(defaults: d)
        #expect(reloaded.speedTimerSeconds == 2.5)
        #expect(reloaded.trueCountConvention == .floor)
        #expect(reloaded.shoeCheckFrequency == 6)
        #expect(!reloaded.hapticsEnabled)
        #expect(reloaded.lastLaunch == LastLaunch(module: .strategy, mode: "learn", setup: Data([1, 2, 3])))
    }

    @Test("Speed timer clamps to 1.0…5.0 and snaps to 0.5 s steps")
    func speedClamp() {
        let p = PreferencesStore(defaults: makeTestDefaults())
        p.speedTimerSeconds = 0.2
        #expect(p.speedTimerSeconds == 1.0)
        p.speedTimerSeconds = 7
        #expect(p.speedTimerSeconds == 5.0)
        p.speedTimerSeconds = 2.3
        #expect(p.speedTimerSeconds == 2.5)
    }

    @Test("Shoe check frequency clamps to 2…8, also on load")
    func shoeClamp() {
        let d = makeTestDefaults()
        let p = PreferencesStore(defaults: d)
        p.shoeCheckFrequency = 1
        #expect(p.shoeCheckFrequency == 2)
        p.shoeCheckFrequency = 12
        #expect(p.shoeCheckFrequency == 8)
        d.set(0, forKey: PreferencesStore.Key.shoeCheckFrequency)
        #expect(PreferencesStore(defaults: d).shoeCheckFrequency == 2)
    }

    @Test("Clearing lastLaunch removes it")
    func clearLastLaunch() {
        let d = makeTestDefaults()
        let p = PreferencesStore(defaults: d)
        p.lastLaunch = LastLaunch(module: .countingRC, mode: nil, setup: Data())
        p.lastLaunch = nil
        #expect(PreferencesStore(defaults: d).lastLaunch == nil)
    }

    @Test("An unknown stored convention falls back to Exact")
    func unknownConvention() {
        let d = makeTestDefaults()
        d.set("sideways", forKey: PreferencesStore.Key.trueCountConvention)
        #expect(PreferencesStore(defaults: d).trueCountConvention == .exact)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/ActiveRulesStoreTests -only-testing:BJSTests/PreferencesStoreTests`.
Expected: build failure, `cannot find 'ActiveRulesStore' in scope`.

- [ ] **Step 3: Implement**

`BJS/Shared/ActiveRulesStore.swift`:

```swift
import Foundation
import Observation
import os
import BJSCore

/// The one app-wide active rule set (parent spec §3 rule 4), persisted as JSON in UserDefaults.
@Observable
final class ActiveRulesStore {
    static let key = "activeRules"
    /// At 1 the pair cells stop round-tripping; 4 is the engine maximum.
    static let maxSplitHandsRange = 2...4

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "ActiveRulesStore")

    var rules: BlackjackRules {
        didSet {
            let clean = Self.sanitized(rules)
            if clean != rules { rules = clean }
            persist()
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var loaded = BlackjackRules()
        if let data = defaults.data(forKey: Self.key) {
            do {
                loaded = try JSONDecoder().decode(BlackjackRules.self, from: data)
            } catch {
                logger.error("activeRules failed to decode; using defaults: \(error.localizedDescription)")
            }
        }
        self.rules = Self.sanitized(loaded)
    }

    static func sanitized(_ rules: BlackjackRules) -> BlackjackRules {
        var r = rules
        r.maxSplitHands = min(max(r.maxSplitHands, maxSplitHandsRange.lowerBound), maxSplitHandsRange.upperBound)
        return r
    }

    private func persist() {
        do {
            defaults.set(try JSONEncoder().encode(rules), forKey: Self.key)
        } catch {
            logger.error("activeRules failed to encode: \(error.localizedDescription)")
        }
    }
}
```

`BJS/Shared/PreferencesStore.swift`:

```swift
import Foundation
import Observation
import os
import BJSCore

/// What the hub's Continue button relaunches. Each feature encodes its own `setup` (Step 3+).
struct LastLaunch: Codable, Equatable {
    var module: TrainingModule
    var mode: String?
    var setup: Data
}

/// User preferences (parent spec §5 Settings, Step 2 spec §4), persisted in UserDefaults.
@Observable
final class PreferencesStore {
    enum Key {
        static let speedTimerSeconds = "speedTimerSeconds"
        static let trueCountConvention = "trueCountConvention"
        static let shoeCheckFrequency = "shoeCheckFrequency"
        static let hapticsEnabled = "hapticsEnabled"
        static let lastLaunch = "lastLaunch"
    }

    static let speedTimerRange = 1.0...5.0
    static let speedTimerStep = 0.5
    static let defaultSpeedTimer = 3.0
    static let shoeCheckRange = 2...8
    static let defaultShoeCheck = 4

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "PreferencesStore")

    var speedTimerSeconds: Double {
        didSet {
            let clean = Self.clampSpeedTimer(speedTimerSeconds)
            if clean != speedTimerSeconds { speedTimerSeconds = clean }
            defaults.set(speedTimerSeconds, forKey: Key.speedTimerSeconds)
        }
    }

    var trueCountConvention: TrueCountConvention {
        didSet { defaults.set(trueCountConvention.rawValue, forKey: Key.trueCountConvention) }
    }

    /// A Shoe Sim count check comes about once every this many rounds.
    var shoeCheckFrequency: Int {
        didSet {
            let clean = Self.clampShoeCheck(shoeCheckFrequency)
            if clean != shoeCheckFrequency { shoeCheckFrequency = clean }
            defaults.set(shoeCheckFrequency, forKey: Key.shoeCheckFrequency)
        }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.hapticsEnabled) }
    }

    var lastLaunch: LastLaunch? {
        didSet { persistLastLaunch() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let speed = defaults.object(forKey: Key.speedTimerSeconds) as? Double ?? Self.defaultSpeedTimer
        self.speedTimerSeconds = Self.clampSpeedTimer(speed)
        self.trueCountConvention = defaults.string(forKey: Key.trueCountConvention)
            .flatMap(TrueCountConvention.init(rawValue:)) ?? .exact
        let shoe = defaults.object(forKey: Key.shoeCheckFrequency) as? Int ?? Self.defaultShoeCheck
        self.shoeCheckFrequency = Self.clampShoeCheck(shoe)
        self.hapticsEnabled = defaults.object(forKey: Key.hapticsEnabled) as? Bool ?? true
        self.lastLaunch = defaults.data(forKey: Key.lastLaunch)
            .flatMap { try? JSONDecoder().decode(LastLaunch.self, from: $0) }
    }

    static func clampSpeedTimer(_ seconds: Double) -> Double {
        let snapped = (seconds / speedTimerStep).rounded() * speedTimerStep
        return min(max(snapped, speedTimerRange.lowerBound), speedTimerRange.upperBound)
    }

    static func clampShoeCheck(_ rounds: Int) -> Int {
        min(max(rounds, shoeCheckRange.lowerBound), shoeCheckRange.upperBound)
    }

    private func persistLastLaunch() {
        guard let lastLaunch else {
            defaults.removeObject(forKey: Key.lastLaunch)
            return
        }
        do {
            defaults.set(try JSONEncoder().encode(lastLaunch), forKey: Key.lastLaunch)
        } catch {
            logger.error("lastLaunch failed to encode: \(error.localizedDescription)")
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the app test command with `-only-testing:BJSTests/ActiveRulesStoreTests -only-testing:BJSTests/PreferencesStoreTests`.
Expected: 10 tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJS/Shared/ActiveRulesStore.swift BJS/Shared/PreferencesStore.swift BJSTests/Shared/StoreTests.swift
git commit -m "feat(app): ActiveRulesStore and PreferencesStore over UserDefaults"
```

---

### Task 9: SwiftData SchemaV1 and record mappers

This pattern (`VersionedSchema` with nested `@Model` classes, cascade relationships, a stage-less `SchemaMigrationPlan`, an in-memory container, all under `DefaultIsolationMainActor`) was verified in a spike on 2026-09-24.

**Naming:** the parent spec lists both a cached `countChecks` count and a `countChecks` relationship on `Session`, which would collide. Keep the relationships as `decisions` and `countChecks`, and name the cached count `countCheckCount`.

**Files:**
- Create: `BJS/Persistence/SchemaV1.swift`
- Create: `BJS/Persistence/RecordMappers.swift`
- Test: `BJSTests/Persistence/SchemaTests.swift`

**Interfaces:**
- Consumes: `SessionSample`, `DecisionSample`, `CountSample`, `TrainingCell`, `HandType`, `TrainingModule` and `CountKind` (BJSCore).
- Produces:
  - `enum SchemaV1: VersionedSchema`, with the typealiases `Session`, `DecisionRecord` and `CountCheckRecord`.
  - `enum BJSMigrationPlan: SchemaMigrationPlan` and `enum BJSModelContainer { static func make(inMemory: Bool) throws -> ModelContainer }`.
  - The mappers `Session.sample -> SessionSample?`, `DecisionRecord.sample -> DecisionSample?` and `CountCheckRecord.sample -> CountSample?`. Each returns nil on an unknown raw value.

- [ ] **Step 1: Write the failing tests**

`BJSTests/Persistence/SchemaTests.swift`:

```swift
import Foundation
import SwiftData
import Testing
import BJSCore
@testable import BJS

@MainActor
struct SchemaTests {

    func makeSession(module: String = "strategy") -> Session {
        Session(id: UUID(), module: module, mode: "test",
                startedAt: Date(timeIntervalSince1970: 1_000), endedAt: Date(timeIntervalSince1970: 2_000),
                rulesJSON: Data("{}".utf8), decisionCount: 1, correctDecisions: 1,
                countCheckCount: 1, correctCountChecks: 0, bestStreak: 1, meanResponseMs: 800)
    }

    func makeDecision(handType: String = "soft", sequence: Int = 0) -> DecisionRecord {
        DecisionRecord(sequence: sequence, decidedAt: Date(timeIntervalSince1970: 1_500), handNumber: 1,
                       handType: handType, playerValue: 18, dealerUpcard: 9,
                       chosenAction: "stand", correctAction: "hit", isCorrect: false, responseMs: 900)
    }

    func makeCheck(kind: String = "running") -> CountCheckRecord {
        CountCheckRecord(sequence: 0, checkedAt: Date(timeIntervalSince1970: 1_600), kind: kind,
                         expected: 3, answered: 2, isCorrect: false, responseMs: 1200, cardsSeen: 26)
    }

    @Test("Container saves a session with records; deleting it cascades")
    func cascade() throws {
        let container = try BJSModelContainer.make(inMemory: true)
        let context = container.mainContext
        let session = makeSession()
        context.insert(session)
        session.decisions.append(makeDecision())
        session.countChecks.append(makeCheck())
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CountCheckRecord>()) == 1)

        context.delete(session)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Session>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CountCheckRecord>()) == 0)
    }

    @Test("Records map to BJSCore samples")
    func mappers() throws {
        let session = makeSession()
        #expect(session.sample == SessionSample(id: session.id, module: .strategy,
                                                startedAt: Date(timeIntervalSince1970: 1_000),
                                                decisionCount: 1, correctDecisions: 1,
                                                countChecks: 1, correctCountChecks: 0))
        #expect(makeDecision().sample == DecisionSample(
            date: Date(timeIntervalSince1970: 1_500),
            cell: TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 9),
            isCorrect: false, responseMs: 900))
        #expect(makeCheck().sample == CountSample(date: Date(timeIntervalSince1970: 1_600), kind: .runningCount,
                                                  expected: 3, answered: 2, isCorrect: false, responseMs: 1200))
    }

    @Test("Unknown raw values map to nil instead of crashing")
    func unknownRawValues() {
        #expect(makeSession(module: "poker").sample == nil)
        #expect(makeDecision(handType: "weird").sample == nil)
        #expect(makeCheck(kind: "sideways").sample == nil)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/SchemaTests`.
Expected: build failure, `cannot find 'Session' in scope`.

- [ ] **Step 3: Implement**

`BJS/Persistence/SchemaV1.swift`:

```swift
import Foundation
import SwiftData

/// SwiftData schema version 1 (parent spec §6, Step 2 spec §1 and §5).
/// Enums are stored as raw strings; `RecordMappers` converts them back.
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Session.self, DecisionRecord.self, CountCheckRecord.self]
    }

    @Model
    final class Session {
        var id: UUID
        /// `TrainingModule` raw value: strategy | countingRC | countingTC | shoe.
        var module: String
        var mode: String?
        var startedAt: Date
        var endedAt: Date
        /// The `BlackjackRules` the session ran under, JSON-encoded.
        var rulesJSON: Data
        var decisionCount: Int
        var correctDecisions: Int
        var countCheckCount: Int
        var correctCountChecks: Int
        var bestStreak: Int
        var meanResponseMs: Double?

        @Relationship(deleteRule: .cascade, inverse: \DecisionRecord.session)
        var decisions: [DecisionRecord] = []
        @Relationship(deleteRule: .cascade, inverse: \CountCheckRecord.session)
        var countChecks: [CountCheckRecord] = []

        init(id: UUID, module: String, mode: String?, startedAt: Date, endedAt: Date, rulesJSON: Data,
             decisionCount: Int, correctDecisions: Int, countCheckCount: Int, correctCountChecks: Int,
             bestStreak: Int, meanResponseMs: Double?) {
            self.id = id
            self.module = module
            self.mode = mode
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.rulesJSON = rulesJSON
            self.decisionCount = decisionCount
            self.correctDecisions = correctDecisions
            self.countCheckCount = countCheckCount
            self.correctCountChecks = correctCountChecks
            self.bestStreak = bestStreak
            self.meanResponseMs = meanResponseMs
        }
    }

    @Model
    final class DecisionRecord {
        /// Order within the session, from 0.
        var sequence: Int
        var decidedAt: Date
        var handNumber: Int
        /// `HandType` raw value: hard | soft | pair.
        var handType: String
        /// Hard/soft total, or pair rank value (11 = aces).
        var playerValue: Int
        /// 2...11, 11 = ace.
        var dealerUpcard: Int
        /// `Action` raw value, or "timeout".
        var chosenAction: String
        var correctAction: String
        var isCorrect: Bool
        var responseMs: Int?
        var session: Session?

        init(sequence: Int, decidedAt: Date, handNumber: Int, handType: String, playerValue: Int,
             dealerUpcard: Int, chosenAction: String, correctAction: String, isCorrect: Bool,
             responseMs: Int?) {
            self.sequence = sequence
            self.decidedAt = decidedAt
            self.handNumber = handNumber
            self.handType = handType
            self.playerValue = playerValue
            self.dealerUpcard = dealerUpcard
            self.chosenAction = chosenAction
            self.correctAction = correctAction
            self.isCorrect = isCorrect
            self.responseMs = responseMs
        }
    }

    @Model
    final class CountCheckRecord {
        var sequence: Int
        var checkedAt: Date
        /// `CountKind` raw value: running | true.
        var kind: String
        var expected: Double
        var answered: Double
        var isCorrect: Bool
        var responseMs: Int?
        var cardsSeen: Int
        var session: Session?

        init(sequence: Int, checkedAt: Date, kind: String, expected: Double, answered: Double,
             isCorrect: Bool, responseMs: Int?, cardsSeen: Int) {
            self.sequence = sequence
            self.checkedAt = checkedAt
            self.kind = kind
            self.expected = expected
            self.answered = answered
            self.isCorrect = isCorrect
            self.responseMs = responseMs
            self.cardsSeen = cardsSeen
        }
    }
}

typealias Session = SchemaV1.Session
typealias DecisionRecord = SchemaV1.DecisionRecord
typealias CountCheckRecord = SchemaV1.CountCheckRecord

enum BJSMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

enum BJSModelContainer {
    static func make(inMemory: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: Schema(versionedSchema: SchemaV1.self),
                                  migrationPlan: BJSMigrationPlan.self,
                                  configurations: configuration)
    }
}
```

`BJS/Persistence/RecordMappers.swift`:

```swift
import BJSCore

extension SchemaV1.Session {
    /// nil when `module` is not a known `TrainingModule`.
    var sample: SessionSample? {
        guard let module = TrainingModule(rawValue: module) else { return nil }
        return SessionSample(id: id, module: module, startedAt: startedAt,
                             decisionCount: decisionCount, correctDecisions: correctDecisions,
                             countChecks: countCheckCount, correctCountChecks: correctCountChecks)
    }
}

extension SchemaV1.DecisionRecord {
    /// nil when `handType` is not a known `HandType`.
    var sample: DecisionSample? {
        guard let type = HandType(rawValue: handType) else { return nil }
        return DecisionSample(date: decidedAt,
                              cell: TrainingCell(handType: type, playerValue: playerValue,
                                                 dealerUpcard: dealerUpcard),
                              isCorrect: isCorrect, responseMs: responseMs)
    }
}

extension SchemaV1.CountCheckRecord {
    /// nil when `kind` is not a known `CountKind`.
    var sample: CountSample? {
        guard let kind = CountKind(rawValue: kind) else { return nil }
        return CountSample(date: checkedAt, kind: kind, expected: expected, answered: answered,
                           isCorrect: isCorrect, responseMs: responseMs)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the app test command with `-only-testing:BJSTests/SchemaTests`.
Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJS/Persistence/SchemaV1.swift BJS/Persistence/RecordMappers.swift BJSTests/Persistence/SchemaTests.swift
git commit -m "feat(persistence): SwiftData SchemaV1 with migration plan and sample mappers"
```

---

### Task 10: SessionDraft and SessionStore

**Files:**
- Create: `BJS/Persistence/SessionDraft.swift`
- Create: `BJS/Persistence/SessionStore.swift`
- Test: `BJSTests/Persistence/SessionStoreTests.swift`

**Interfaces:**
- Consumes: the Task 9 models and mappers, and `SessionSummary` (Task 6).
- Produces:
  - `enum RecordedChoice: Equatable { case action(Action), timeout }` with `rawValue` and `init?(rawValue:)`.
  - `struct DecisionDraft` with `handNumber`, `cell: TrainingCell`, `chosen: RecordedChoice`, `correctAction: Action`, `isCorrect`, `responseMs: Int?` and `decidedAt: Date`.
  - `struct CountCheckDraft` with `kind: CountKind`, `expected`, `answered`, `isCorrect`, `responseMs: Int?`, `cardsSeen` and `checkedAt: Date`.
  - `struct SessionDraft` with `id`, `module: TrainingModule`, `mode: String?`, `startedAt`, `endedAt`, `rules: BlackjackRules`, `decisions: [DecisionDraft]` and `countChecks: [CountCheckDraft]`.
  - `@Observable final class SessionStore`:
    - `init(context: ModelContext)` and `private(set) var revision: Int`;
    - `save(_:) throws`;
    - `sessionSamples() throws -> [SessionSample]`;
    - `decisionSamples(modules: Set<TrainingModule>? = nil) throws -> [DecisionSample]`;
    - `countSamples(modules: Set<TrainingModule>? = nil) throws -> [CountSample]`;
    - `deleteAll() throws`.

Ordering: sessions come back by `startedAt`. Decisions come back by `decidedAt`, then `sequence`; count checks by `checkedAt`, then `sequence`. `WeakSpotWeights` and `ProgressStats.currentStreak` need this chronological order. `revision` increments after every successful save or delete, so views can refresh with `.task(id:)`.

- [ ] **Step 1: Write the failing tests**

`BJSTests/Persistence/SessionStoreTests.swift`:

```swift
import Foundation
import SwiftData
import Testing
import BJSCore
@testable import BJS

@MainActor
struct SessionStoreTests {

    let container: ModelContainer  // retained: the context does not keep its container alive
    let store: SessionStore
    let context: ModelContext

    init() throws {
        container = try BJSModelContainer.make(inMemory: true)
        context = container.mainContext
        store = SessionStore(context: context)
    }

    func t(_ seconds: Double) -> Date { Date(timeIntervalSince1970: seconds) }

    func decision(_ correct: Bool, at time: Double, ms: Int? = nil, value: Int = 16) -> DecisionDraft {
        DecisionDraft(handNumber: 1, cell: TrainingCell(handType: .hard, playerValue: value, dealerUpcard: 10),
                      chosen: .action(correct ? .hit : .stand), correctAction: .hit,
                      isCorrect: correct, responseMs: ms, decidedAt: t(time))
    }

    func draft(_ module: TrainingModule = .strategy, start: Double = 100,
               decisions: [DecisionDraft] = [], checks: [CountCheckDraft] = []) -> SessionDraft {
        SessionDraft(module: module, mode: "test", startedAt: t(start), endedAt: t(start + 60),
                     rules: RulePreset.downtownVegas.rules, decisions: decisions, countChecks: checks)
    }

    @Test("RecordedChoice round-trips actions and timeout")
    func recordedChoice() {
        #expect(RecordedChoice.timeout.rawValue == "timeout")
        #expect(RecordedChoice(rawValue: "timeout") == .timeout)
        #expect(RecordedChoice(rawValue: "double") == .action(.double))
        #expect(RecordedChoice(rawValue: "fold") == nil)
    }

    @Test("Saving stores the cached summary, rules snapshot and records")
    func saveSummary() throws {
        let d = draft(decisions: [decision(true, at: 101, ms: 1000), decision(true, at: 102, ms: 2000),
                                  decision(false, at: 103)],
                      checks: [CountCheckDraft(kind: .runningCount, expected: 2, answered: 2, isCorrect: true,
                                               responseMs: nil, cardsSeen: 10, checkedAt: t(104))])
        try store.save(d)

        let session = try #require(try context.fetch(FetchDescriptor<Session>()).first)
        #expect(session.id == d.id)
        #expect(session.module == "strategy")
        #expect(session.decisionCount == 3)
        #expect(session.correctDecisions == 2)
        #expect(session.countCheckCount == 1)
        #expect(session.correctCountChecks == 1)
        #expect(session.bestStreak == 2)
        #expect(session.meanResponseMs == 1500)
        #expect(try JSONDecoder().decode(BlackjackRules.self, from: session.rulesJSON)
                == RulePreset.downtownVegas.rules)
        #expect(session.decisions.map { $0.sequence }.sorted() == [0, 1, 2])
        #expect(session.decisions.first { $0.sequence == 2 }?.chosenAction == "stand")
    }

    @Test("Timeouts are stored as 'timeout'")
    func timeoutStored() throws {
        var d = decision(false, at: 101)
        d.chosen = .timeout
        try store.save(draft(decisions: [d]))
        #expect(try context.fetch(FetchDescriptor<DecisionRecord>()).first?.chosenAction == "timeout")
    }

    @Test("Session samples come back oldest first")
    func sessionOrder() throws {
        try store.save(draft(.countingRC, start: 500))
        try store.save(draft(.strategy, start: 100))
        #expect(try store.sessionSamples().map(\.module) == [.strategy, .countingRC])
    }

    @Test("Decisions are chronological, ties broken by sequence")
    func decisionOrder() throws {
        // Three decisions share one timestamp; only sequence orders them.
        try store.save(draft(start: 200, decisions: [decision(true, at: 300, value: 12),
                                                     decision(false, at: 300, value: 13),
                                                     decision(true, at: 300, value: 14)]))
        try store.save(draft(start: 100, decisions: [decision(true, at: 150, value: 5)]))
        #expect(try store.decisionSamples().map(\.cell.playerValue) == [5, 12, 13, 14])
    }

    @Test("Module filter applies to decisions and count checks")
    func moduleFilter() throws {
        let check = CountCheckDraft(kind: .trueCount, expected: 1.5, answered: 1.5, isCorrect: true,
                                    responseMs: 700, cardsSeen: 52, checkedAt: t(120))
        try store.save(draft(.strategy, decisions: [decision(true, at: 110)]))
        try store.save(draft(.shoe, start: 200, decisions: [decision(false, at: 210)], checks: [check]))
        try store.save(draft(.countingTC, start: 300, checks: [check]))
        #expect(try store.decisionSamples().count == 2)
        #expect(try store.decisionSamples(modules: [.strategy]).map(\.isCorrect) == [true])
        #expect(try store.countSamples().count == 2)
        #expect(try store.countSamples(modules: [.countingTC]).count == 1)
    }

    @Test("Rows with unknown raw values are skipped")
    func unknownRowsSkipped() throws {
        try store.save(draft(decisions: [decision(true, at: 101)]))
        let bogus = DecisionRecord(sequence: 9, decidedAt: t(102), handNumber: 1, handType: "weird",
                                   playerValue: 1, dealerUpcard: 1, chosenAction: "hit",
                                   correctAction: "hit", isCorrect: true, responseMs: nil)
        let session = try #require(try context.fetch(FetchDescriptor<Session>()).first)
        session.decisions.append(bogus)
        try context.save()
        #expect(try store.decisionSamples().count == 1)
    }

    @Test("deleteAll removes every session and record and bumps revision")
    func deleteAll() throws {
        try store.save(draft(decisions: [decision(true, at: 101)]))
        let before = store.revision
        try store.deleteAll()
        #expect(store.revision == before + 1)
        #expect(try store.sessionSamples().isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CountCheckRecord>()) == 0)
    }

    @Test("save bumps revision")
    func saveRevision() throws {
        let before = store.revision
        try store.save(draft())
        #expect(store.revision == before + 1)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/SessionStoreTests`.
Expected: build failure, `cannot find 'SessionStore' in scope`.

- [ ] **Step 3: Implement**

`BJS/Persistence/SessionDraft.swift`:

```swift
import Foundation
import BJSCore

/// A strategy decision's chosen play: an action, or running out of time in Speed mode.
enum RecordedChoice: Equatable {
    case action(Action)
    case timeout

    static let timeoutRawValue = "timeout"

    var rawValue: String {
        switch self {
        case .action(let action): return action.rawValue
        case .timeout: return Self.timeoutRawValue
        }
    }

    init?(rawValue: String) {
        if rawValue == Self.timeoutRawValue {
            self = .timeout
        } else if let action = Action(rawValue: rawValue) {
            self = .action(action)
        } else {
            return nil
        }
    }
}

struct DecisionDraft: Equatable {
    var handNumber: Int
    var cell: TrainingCell
    var chosen: RecordedChoice
    var correctAction: Action
    var isCorrect: Bool
    var responseMs: Int?
    var decidedAt: Date
}

struct CountCheckDraft: Equatable {
    var kind: CountKind
    var expected: Double
    var answered: Double
    var isCorrect: Bool
    var responseMs: Int?
    var cardsSeen: Int
    var checkedAt: Date
}

/// A finished (or saved-partial) session, as features hand it to `SessionStore`.
/// `decisions` and `countChecks` are in the order they happened.
struct SessionDraft: Equatable {
    var id = UUID()
    var module: TrainingModule
    var mode: String?
    var startedAt: Date
    var endedAt: Date
    var rules: BlackjackRules
    var decisions: [DecisionDraft] = []
    var countChecks: [CountCheckDraft] = []
}
```

`BJS/Persistence/SessionStore.swift`:

```swift
import Foundation
import Observation
import os
import SwiftData
import BJSCore

/// Saves finished sessions and reads them back as BJSCore samples.
/// Errors are thrown; callers show a non-blocking alert (parent spec §6).
@Observable
final class SessionStore {
    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "SessionStore")

    /// Increments after every successful save or delete.
    private(set) var revision = 0

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ draft: SessionDraft) throws {
        let summary = SessionSummary(decisions: draft.decisions.map { ($0.isCorrect, $0.responseMs) },
                                     countChecks: draft.countChecks.map { $0.isCorrect })
        let session = Session(id: draft.id, module: draft.module.rawValue, mode: draft.mode,
                              startedAt: draft.startedAt, endedAt: draft.endedAt,
                              rulesJSON: try JSONEncoder().encode(draft.rules),
                              decisionCount: summary.decisionCount,
                              correctDecisions: summary.correctDecisions,
                              countCheckCount: summary.countCheckCount,
                              correctCountChecks: summary.correctCountChecks,
                              bestStreak: summary.bestStreak,
                              meanResponseMs: summary.meanResponseMs)
        context.insert(session)
        for (index, d) in draft.decisions.enumerated() {
            session.decisions.append(DecisionRecord(
                sequence: index, decidedAt: d.decidedAt, handNumber: d.handNumber,
                handType: d.cell.handType.rawValue, playerValue: d.cell.playerValue,
                dealerUpcard: d.cell.dealerUpcard, chosenAction: d.chosen.rawValue,
                correctAction: d.correctAction.rawValue, isCorrect: d.isCorrect, responseMs: d.responseMs))
        }
        for (index, c) in draft.countChecks.enumerated() {
            session.countChecks.append(CountCheckRecord(
                sequence: index, checkedAt: c.checkedAt, kind: c.kind.rawValue, expected: c.expected,
                answered: c.answered, isCorrect: c.isCorrect, responseMs: c.responseMs,
                cardsSeen: c.cardsSeen))
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        revision += 1
    }

    /// All sessions, oldest first.
    func sessionSamples() throws -> [SessionSample] {
        let sessions = try context.fetch(FetchDescriptor<Session>()).sorted { $0.startedAt < $1.startedAt }
        return mapLogging(sessions, kind: "session") { $0.sample }
    }

    /// Decisions from sessions in `modules` (all when nil), chronological.
    func decisionSamples(modules: Set<TrainingModule>? = nil) throws -> [DecisionSample] {
        let records = try context.fetch(FetchDescriptor<DecisionRecord>())
            .filter { Self.matches($0.session, modules) }
            .sorted { ($0.decidedAt, $0.sequence) < ($1.decidedAt, $1.sequence) }
        return mapLogging(records, kind: "decision") { $0.sample }
    }

    /// Count checks from sessions in `modules` (all when nil), chronological.
    func countSamples(modules: Set<TrainingModule>? = nil) throws -> [CountSample] {
        let records = try context.fetch(FetchDescriptor<CountCheckRecord>())
            .filter { Self.matches($0.session, modules) }
            .sorted { ($0.checkedAt, $0.sequence) < ($1.checkedAt, $1.sequence) }
        return mapLogging(records, kind: "count check") { $0.sample }
    }

    /// Deletes every session and record. Rules and preferences live elsewhere and are untouched.
    func deleteAll() throws {
        for session in try context.fetch(FetchDescriptor<Session>()) { context.delete(session) }
        for record in try context.fetch(FetchDescriptor<DecisionRecord>()) { context.delete(record) }
        for record in try context.fetch(FetchDescriptor<CountCheckRecord>()) { context.delete(record) }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        revision += 1
    }

    private static func matches(_ session: Session?, _ modules: Set<TrainingModule>?) -> Bool {
        guard let modules else { return true }
        guard let raw = session?.module, let module = TrainingModule(rawValue: raw) else { return false }
        return modules.contains(module)
    }

    private func mapLogging<Record, Sample>(_ records: [Record], kind: String,
                                            _ transform: (Record) -> Sample?) -> [Sample] {
        let samples = records.compactMap(transform)
        let dropped = records.count - samples.count
        if dropped > 0 {
            logger.error("Skipped \(dropped) \(kind) row(s) with unknown raw values")
        }
        return samples
    }
}
```

Tuple comparison `(Date, Int) < (Date, Int)` works because both elements are `Comparable`.

- [ ] **Step 4: Run the tests to verify they pass**

Run the app test command with `-only-testing:BJSTests/SessionStoreTests`.
Expected: 9 tests pass.

- [ ] **Step 5: Commit**

```bash
git add BJS/Persistence/SessionDraft.swift BJS/Persistence/SessionStore.swift BJSTests/Persistence/SessionStoreTests.swift
git commit -m "feat(persistence): SessionStore saves drafts and returns chronological samples"
```

---

### Task 11: App shell wiring

**Files:**
- Create: `BJS/Shared/AppRouter.swift`
- Create: `BJS/App/LaunchConfiguration.swift`
- Modify: `BJS/App/BJSApp.swift` (full replacement below)
- Modify: `BJS/App/RootTabView.swift` (full replacement below; `AppTab` stays in this file, unchanged)
- Test: `BJSTests/AppShellTests.swift` (extend)

**Interfaces:**
- Consumes: the stores (Tasks 8, 10), `BJSModelContainer` (Task 9), `ComingSoonView`, `FeltTabBarAppearance` and `FeltColor` (Task 2).
- Produces:
  - `@Observable final class AppRouter { var selectedTab: AppTab }` with `init(selectedTab: AppTab = .train)`.
  - `struct LaunchConfiguration` with `init(arguments: [String])`, `isUITesting`, `startTab: AppTab?` and `showsCatalogue`.
  - `RootTabView(showsCatalogueAtLaunch: Bool)`. Tab contents are `HubPlaceholder` → `HubView` (Task 12) and `SettingsPlaceholder` → `SettingsView` (Task 14).

Launch arguments:
- `-uiTesting` uses an in-memory SwiftData store and a fresh, empty `UserDefaults` suite, so UI tests and design screenshots start clean.
- `-startTab <train|progress|settings>` picks the initial tab.
- `-showCatalogue` (DEBUG builds only) presents the Felt catalogue at launch. It is parsed here and wired in Task 13.

- [ ] **Step 1: Write the failing tests**

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

    @Test("Router starts on Train")
    func routerDefault() {
        #expect(AppRouter().selectedTab == .train)
    }

    @Test("Launch arguments: none")
    func launchDefaults() {
        let config = LaunchConfiguration(arguments: ["BJS"])
        #expect(!config.isUITesting)
        #expect(config.startTab == nil)
        #expect(!config.showsCatalogue)
    }

    @Test("Launch arguments: UI testing, start tab, catalogue")
    func launchArguments() {
        let config = LaunchConfiguration(arguments: ["BJS", "-uiTesting", "-startTab", "settings", "-showCatalogue"])
        #expect(config.isUITesting)
        #expect(config.startTab == .settings)
        #expect(config.showsCatalogue)
    }

    @Test("Unknown or missing start tab is ignored")
    func badStartTab() {
        #expect(LaunchConfiguration(arguments: ["BJS", "-startTab", "casino"]).startTab == nil)
        #expect(LaunchConfiguration(arguments: ["BJS", "-startTab"]).startTab == nil)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/AppShellTests`.
Expected: build failure, `cannot find 'AppRouter' in scope`.

- [ ] **Step 3: Implement**

`BJS/Shared/AppRouter.swift`:

```swift
import Observation

/// App-level navigation state shared across features (e.g. the hub header opens Settings).
@Observable
final class AppRouter {
    var selectedTab: AppTab

    init(selectedTab: AppTab = .train) {
        self.selectedTab = selectedTab
    }
}
```

`BJS/App/LaunchConfiguration.swift`:

```swift
import Foundation

/// Process launch arguments used by UI tests and design screenshots.
struct LaunchConfiguration {
    /// In-memory SwiftData store and an empty UserDefaults suite.
    let isUITesting: Bool
    let startTab: AppTab?
    /// DEBUG builds only: present the Felt catalogue at launch.
    let showsCatalogue: Bool

    init(arguments: [String]) {
        isUITesting = arguments.contains("-uiTesting")
        showsCatalogue = arguments.contains("-showCatalogue")
        if let index = arguments.firstIndex(of: "-startTab"), index + 1 < arguments.count {
            startTab = AppTab(rawValue: arguments[index + 1].capitalized)
        } else {
            startTab = nil
        }
    }

    static let current = LaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)

    /// Standard defaults normally; a fresh, empty suite under UI testing.
    func makeUserDefaults() -> UserDefaults {
        guard isUITesting else { return .standard }
        let name = "BJSUITests"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
```

`BJS/App/BJSApp.swift`:

```swift
import os
import SwiftData
import SwiftUI

@main
struct BJSApp: App {
    private let launch = LaunchConfiguration.current
    private let container: ModelContainer
    @State private var rulesStore: ActiveRulesStore
    @State private var preferences: PreferencesStore
    @State private var sessionStore: SessionStore
    @State private var router: AppRouter

    init() {
        let launch = LaunchConfiguration.current
        let container: ModelContainer
        do {
            container = try BJSModelContainer.make(inMemory: launch.isUITesting)
        } catch {
            // Never crash on a bad store (parent spec §6): run this launch in memory.
            Logger(subsystem: "com.bjs.app", category: "BJSApp")
                .error("Persistent store failed to open; using in-memory store: \(error.localizedDescription)")
            container = try! BJSModelContainer.make(inMemory: true)
        }
        self.container = container
        let defaults = launch.makeUserDefaults()
        _rulesStore = State(initialValue: ActiveRulesStore(defaults: defaults))
        _preferences = State(initialValue: PreferencesStore(defaults: defaults))
        _sessionStore = State(initialValue: SessionStore(context: container.mainContext))
        _router = State(initialValue: AppRouter(selectedTab: launch.startTab ?? .train))
        FeltTabBarAppearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(showsCatalogueAtLaunch: launch.showsCatalogue)
                .environment(rulesStore)
                .environment(preferences)
                .environment(sessionStore)
                .environment(router)
                .modelContainer(container)
                .preferredColorScheme(.dark)
        }
    }
}
```

`BJS/App/RootTabView.swift`:

```swift
import SwiftUI

/// The three top-level tabs.
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

struct RootTabView: View {
    var showsCatalogueAtLaunch = false
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            Tab(AppTab.train.rawValue, systemImage: AppTab.train.systemImage, value: AppTab.train) {
                HubPlaceholder()
            }
            Tab(AppTab.progress.rawValue, systemImage: AppTab.progress.systemImage, value: AppTab.progress) {
                ComingSoonView(title: "Progress", message: "Coming in Step 6")
            }
            Tab(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage, value: AppTab.settings) {
                SettingsPlaceholder()
            }
        }
        .tint(FeltColor.cream)
    }
}

/// Replaced by `HubView` in Task 12.
private struct HubPlaceholder: View {
    var body: some View { ComingSoonView(title: "Train", message: "Hub arrives in Task 12") }
}

/// Replaced by `SettingsView` in Task 14.
private struct SettingsPlaceholder: View {
    var body: some View { ComingSoonView(title: "Settings", message: "Settings arrive in Task 14") }
}
```

- [ ] **Step 4: Run all app tests**

Run the app test command.
Expected: all suites pass, including the 6 `AppShellTests`.

- [ ] **Step 5: Launch check**

Build and run the app in the iPhone 16 simulator. Confirm that the felt background shows on all three tabs, the tab bar is `feltDeep`, the selected tab is cream, and there are no runtime errors in the console.

- [ ] **Step 6: Commit**

```bash
git add BJS/Shared/AppRouter.swift BJS/App/LaunchConfiguration.swift BJS/App/BJSApp.swift BJS/App/RootTabView.swift BJSTests/AppShellTests.swift
git commit -m "feat(app): wire stores, SwiftData container and router into the tab shell"
```

---

### Task 12: Hub

**Files:**
- Create: `BJS/Features/Hub/HubModule.swift`
- Create: `BJS/Features/Hub/HubViewModel.swift`
- Create: `BJS/Features/Hub/HubView.swift`
- Modify: `BJS/App/RootTabView.swift` (use `HubView()` for the Train tab; delete `HubPlaceholder`)
- Test: `BJSTests/Features/HubViewModelTests.swift`

**Interfaces:**
- Consumes:
  - `ProgressStats.headline(sessions:modules:measure:since:)`, `ProgressStats.currentStreak(_:)`, `Headline.accuracy` (BJSCore);
  - `SessionStore.sessionSamples()` and `decisionSamples(modules:)`;
  - `ActiveRulesStore`, `PreferencesStore`, `AppRouter` and `RulesSummary`;
  - `StatChip`, `ModuleTile`, `PrimaryButton`, `ComingSoonView` and `FeltBackground`.
- Produces:
  - `enum HubModule: String, CaseIterable, Identifiable` (`strategy`, `counting`, `shoe`, `edge`) with `title`, `subtitle` and `step`.
  - `@Observable final class HubViewModel`: `strategyAccuracy`, `countAccuracy`, `streak`, `update(sessions:decisions:now:calendar:)`, `static percent(_:)`, `strategyModules` and `countModules`.
  - `HubView()`.
- Accessibility identifier: the header button is `hub.rulesSummary`. Its accessibility value is the `RulesSummary` text, which the UI test in Task 15 reads.

Chip definitions (Step 2 spec §3):
- Strategy accuracy is `.decisions` over `[.strategy, .shoe]` sessions from the last 30 days.
- Count accuracy is `.countChecks` over `[.countingRC, .countingTC, .shoe]` sessions from the last 30 days.
- Streak is `currentStreak` over strategy and shoe decisions.
- Accuracy is shown as a rounded whole percent. Any chip with no data shows "—" (U+2014).

- [ ] **Step 1: Write the failing tests**

`BJSTests/Features/HubViewModelTests.swift`:

```swift
import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct HubViewModelTests {

    let now = Date(timeIntervalSince1970: 100 * 86_400)
    var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    func session(_ module: TrainingModule, daysAgo: Int, decisions: Int = 0, correct: Int = 0,
                 checks: Int = 0, correctChecks: Int = 0) -> SessionSample {
        SessionSample(id: UUID(), module: module, startedAt: now.addingTimeInterval(Double(-daysAgo) * 86_400),
                      decisionCount: decisions, correctDecisions: correct,
                      countChecks: checks, correctCountChecks: correctChecks)
    }

    func decision(_ correct: Bool, _ second: Double) -> DecisionSample {
        DecisionSample(date: Date(timeIntervalSince1970: second),
                       cell: TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10),
                       isCorrect: correct, responseMs: nil)
    }

    @Test("With no data every chip shows an em dash")
    func empty() {
        let model = HubViewModel()
        model.update(sessions: [], decisions: [], now: now, calendar: utc)
        #expect(model.strategyAccuracy == "—")
        #expect(model.countAccuracy == "—")
        #expect(model.streak == "—")
    }

    @Test("Strategy accuracy covers strategy and shoe sessions from the last 30 days")
    func strategyAccuracy() {
        let model = HubViewModel()
        model.update(sessions: [session(.strategy, daysAgo: 1, decisions: 40, correct: 36),
                                session(.shoe, daysAgo: 5, decisions: 10, correct: 9),
                                session(.strategy, daysAgo: 45, decisions: 100, correct: 0),
                                session(.countingRC, daysAgo: 1, checks: 5, correctChecks: 5)],
                     decisions: [], now: now, calendar: utc)
        #expect(model.strategyAccuracy == "90%")
    }

    @Test("Count accuracy covers RC, TC and shoe checks")
    func countAccuracy() {
        let model = HubViewModel()
        model.update(sessions: [session(.countingRC, daysAgo: 2, checks: 2, correctChecks: 1),
                                session(.countingTC, daysAgo: 3, checks: 1, correctChecks: 1),
                                session(.shoe, daysAgo: 4, checks: 1, correctChecks: 1)],
                     decisions: [], now: now, calendar: utc)
        #expect(model.countAccuracy == "75%")
    }

    @Test("Streak counts consecutive correct decisions from the newest")
    func streak() {
        let model = HubViewModel()
        model.update(sessions: [], decisions: [decision(true, 1), decision(false, 2),
                                               decision(true, 3), decision(true, 4)],
                     now: now, calendar: utc)
        #expect(model.streak == "2")
        model.update(sessions: [], decisions: [decision(false, 1)], now: now, calendar: utc)
        #expect(model.streak == "0")
    }

    @Test("Percent rounds to a whole number")
    func percent() {
        #expect(HubViewModel.percent(2.0 / 3.0) == "67%")
        #expect(HubViewModel.percent(1) == "100%")
        #expect(HubViewModel.percent(nil) == "—")
    }

    @Test("Module tiles: Strategy, Counting, Shoe Sim, Edge")
    func tiles() {
        #expect(HubModule.allCases.map { $0.title } == ["Strategy", "Counting", "Shoe Sim", "Edge"])
        #expect(HubModule.allCases.map { $0.step } == [3, 4, 7, 5])
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/HubViewModelTests`.
Expected: build failure, `cannot find 'HubViewModel' in scope`.

- [ ] **Step 3: Implement**

`BJS/Features/Hub/HubModule.swift`:

```swift
/// The hub's module tiles. Each opens a placeholder until its build step (parent spec §8).
enum HubModule: String, CaseIterable, Identifiable {
    case strategy, counting, shoe, edge

    var id: Self { self }

    var title: String {
        switch self {
        case .strategy: return "Strategy"
        case .counting: return "Counting"
        case .shoe: return "Shoe Sim"
        case .edge: return "Edge"
        }
    }

    var subtitle: String {
        switch self {
        case .strategy: return "Basic strategy drills"
        case .counting: return "Hi-Lo running and true count"
        case .shoe: return "Play and count a full shoe"
        case .edge: return "House edge for any rules"
        }
    }

    /// The build step that delivers this module.
    var step: Int {
        switch self {
        case .strategy: return 3
        case .counting: return 4
        case .shoe: return 7
        case .edge: return 5
        }
    }
}
```

`BJS/Features/Hub/HubViewModel.swift`:

```swift
import Foundation
import Observation
import BJSCore

/// Maps progress samples to the hub's stat chip strings.
@Observable
final class HubViewModel {
    static let accuracyWindowDays = 30
    static let strategyModules: Set<TrainingModule> = [.strategy, .shoe]
    static let countModules: Set<TrainingModule> = [.countingRC, .countingTC, .shoe]
    static let noData = "—"

    private(set) var strategyAccuracy = noData
    private(set) var countAccuracy = noData
    private(set) var streak = noData

    /// - Parameter decisions: strategy and shoe decisions, chronological.
    func update(sessions: [SessionSample], decisions: [DecisionSample], now: Date,
                calendar: Calendar = .current) {
        let since = calendar.date(byAdding: .day, value: -Self.accuracyWindowDays, to: now)
        strategyAccuracy = Self.percent(ProgressStats.headline(
            sessions: sessions, modules: Self.strategyModules, measure: .decisions, since: since).accuracy)
        countAccuracy = Self.percent(ProgressStats.headline(
            sessions: sessions, modules: Self.countModules, measure: .countChecks, since: since).accuracy)
        streak = decisions.isEmpty ? Self.noData : String(ProgressStats.currentStreak(decisions))
    }

    static func percent(_ fraction: Double?) -> String {
        guard let fraction else { return noData }
        return "\(Int((fraction * 100).rounded()))%"
    }
}
```

`BJS/Features/Hub/HubView.swift`:

```swift
import os
import SwiftUI

/// Train tab: rules header, stat chips, Continue, module tiles.
struct HubView: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(PreferencesStore.self) private var preferences
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppRouter.self) private var router
    @State private var model = HubViewModel()
    @State private var presented: HubModule?

    private let logger = Logger(subsystem: "com.bjs.app", category: "HubView")

    var body: some View {
        ZStack {
            FeltBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                    header
                    HStack(spacing: FeltSpacing.s) {
                        StatChip(label: "Strategy", value: model.strategyAccuracy)
                        StatChip(label: "Count", value: model.countAccuracy)
                        StatChip(label: "Streak", value: model.streak)
                    }
                    if preferences.lastLaunch != nil {
                        // Relaunch wiring arrives with the first module (Step 3).
                        PrimaryButton(title: "Continue") {}
                    }
                    VStack(spacing: FeltSpacing.m) {
                        ForEach(HubModule.allCases) { module in
                            ModuleTile(title: module.title, subtitle: module.subtitle) {
                                presented = module
                            }
                        }
                    }
                }
                .padding(FeltSpacing.l)
            }
        }
        .fullScreenCover(item: $presented) { module in
            ComingSoonView(title: module.title, message: "Coming in Step \(module.step)") {
                presented = nil
            }
        }
        .task(id: sessionStore.revision) { refresh() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Button {
                router.selectedTab = .settings
            } label: {
                HStack(spacing: FeltSpacing.xs) {
                    Text(RulesSummary.text(for: rulesStore.rules))
                        .feltText(.body)
                        .foregroundStyle(FeltColor.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FeltColor.textTertiary)
                }
                .frame(minHeight: FeltTapTarget.minimum)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("hub.rulesSummary")
            .accessibilityLabel("Table rules")
            .accessibilityValue(RulesSummary.text(for: rulesStore.rules))
            .accessibilityHint("Opens Settings")
            Text("Train")
                .feltText(.display)
                .foregroundStyle(FeltColor.textPrimary)
        }
    }

    private func refresh() {
        do {
            model.update(sessions: try sessionStore.sessionSamples(),
                         decisions: try sessionStore.decisionSamples(modules: HubViewModel.strategyModules),
                         now: .now)
        } catch {
            logger.error("Hub stats failed to load: \(error.localizedDescription)")
            model.update(sessions: [], decisions: [], now: .now)
        }
    }
}
```

In `BJS/App/RootTabView.swift`, replace `HubPlaceholder()` in the Train tab with `HubView()` and delete the `HubPlaceholder` struct.

- [ ] **Step 4: Run all app tests**

Run the app test command.
Expected: all suites pass, including the 6 `HubViewModelTests`.

- [ ] **Step 5: Launch check**

Run the app on iPhone 16 and on iPhone SE (3rd generation). Check the following:
- The header reads `6D · S17 · DAS · 3:2`, and tapping it switches to the Settings tab.
- The three chips show "—".
- There is no Continue button.
- Each tile opens a full-screen placeholder that closes.
- On SE, nothing truncates except the chip values' allowed scaling.

- [ ] **Step 6: Commit**

```bash
git add BJS/Features/Hub BJS/App/RootTabView.swift BJSTests/Features/HubViewModelTests.swift
git commit -m "feat(hub): rules header, stat chips and module tiles"
```

---

### Task 13: Felt catalogue (DEBUG)

**Files:**
- Create: `BJS/Design/Catalogue/FeltCatalogue.swift` (whole file inside `#if DEBUG`)
- Modify: `BJS/App/RootTabView.swift` (present the catalogue at launch when `showsCatalogueAtLaunch` is set, DEBUG only)

**Interfaces:**
- Consumes: every token and component from Tasks 1–5, and `FeltContrast.requirements`.
- Produces: `FeltCatalogue(onClose: (() -> Void)? = nil)` (DEBUG only).

The catalogue is the reference for the design freeze. It must show every token and every component state listed in Step 2 spec §2. It has no logic of its own; the contrast table renders `FeltContrast.requirements`, which Task 1 already tests.

- [ ] **Step 1: Implement the catalogue**

`BJS/Design/Catalogue/FeltCatalogue.swift`:

```swift
#if DEBUG
import SwiftUI
import BJSCore

/// Every Felt token and component in every state. DEBUG only; the design-freeze reference.
struct FeltCatalogue: View {
    var onClose: (() -> Void)? = nil

    @State private var mode = "Learn"
    @State private var entry = CountEntry()
    @State private var toggle = true
    @State private var stepper = 4

    private let swatches: [(String, FeltRGB)] = [
        ("feltDeep", FeltPalette.feltDeep), ("feltBase", FeltPalette.feltBase),
        ("feltLight", FeltPalette.feltLight), ("glowCentre", FeltPalette.glowCentre),
        ("surfaceInset", FeltPalette.surfaceInsetOnBase), ("cream", FeltPalette.cream),
        ("onCream", FeltPalette.onCream), ("onCreamSecondary", FeltPalette.onCreamSecondary),
        ("brass", FeltPalette.brass), ("correct", FeltPalette.correct),
        ("incorrect", FeltPalette.incorrect), ("suitRed", FeltPalette.suitRed),
        ("suitBlack", FeltPalette.suitBlack), ("textPrimary", FeltPalette.textPrimary),
        ("textSecondary", FeltPalette.textSecondary), ("textTertiary", FeltPalette.textTertiary),
    ]

    var body: some View {
        ZStack {
            FeltBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.xxl) {
                    HStack {
                        Text("Felt catalogue").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                        Spacer()
                        if let onClose {
                            Button("Close", action: onClose)
                                .foregroundStyle(FeltColor.textSecondary)
                                .frame(minHeight: FeltTapTarget.minimum)
                        }
                    }
                    section("Colour") { colours }
                    section("Contrast") { contrast }
                    section("Type") { type }
                    section("Cards") { cards }
                    section("Action dock") { docks }
                    section("Feedback") { feedback }
                    section("Chips, tiles, buttons") { surfaces }
                    section("Mode picker and settings") { controls }
                    section("Count keypad") {
                        CountKeypad(entry: $entry) { _ in }
                    }
                }
                .padding(FeltSpacing.l)
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FeltSpacing.m) {
            Text(title).feltText(.label).foregroundStyle(FeltColor.textTertiary)
            content()
        }
    }

    private var colours: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
            ForEach(swatches, id: \.0) { name, rgb in
                VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                    RoundedRectangle(cornerRadius: FeltRadius.chip)
                        .fill(rgb.color)
                        .frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: FeltRadius.chip)
                            .strokeBorder(FeltColor.textTertiary.opacity(0.4), lineWidth: 0.5))
                    Text(name).font(.caption2).foregroundStyle(FeltColor.textPrimary)
                    Text(String(format: "#%06X", rgb.hex)).font(.caption2.monospaced())
                        .foregroundStyle(FeltColor.textSecondary)
                }
            }
        }
    }

    private var contrast: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            ForEach(FeltContrast.requirements) { r in
                HStack {
                    Text(r.id).font(.caption).foregroundStyle(r.foreground.color)
                        .padding(.horizontal, FeltSpacing.s).padding(.vertical, 2)
                        .background(r.background.color, in: RoundedRectangle(cornerRadius: 4))
                    Spacer()
                    Text(String(format: "%.2f ≥ %.1f", r.ratio, r.minimum)).font(.caption.monospaced())
                        .foregroundStyle(FeltColor.textSecondary)
                    Image(systemName: r.passes ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(r.passes ? FeltColor.correct : FeltColor.incorrect)
                }
            }
        }
    }

    private var type: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text("Display 28 bold").feltText(.display)
            Text("Title 20 semibold").feltText(.title)
            Text("Body 15 regular — the quick brown fox").feltText(.body)
            Text("Label 11 semibold tracked").feltText(.label)
            Text("+12 −3.5 87%").feltText(.stat)
        }
        .foregroundStyle(FeltColor.textPrimary)
    }

    private var cards: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.l) {
            HStack(spacing: FeltSpacing.s) {
                PlayingCard(card: Card(rank: .ace, suit: .spades), width: 64)
                PlayingCard(card: Card(rank: .ten, suit: .hearts), width: 64)
                PlayingCard(card: Card(rank: .queen, suit: .diamonds), width: 64)
                PlayingCard(card: Card(rank: .eight, suit: .clubs), width: 64)
                PlayingCard(card: Card(rank: .two, suit: .hearts), isFaceUp: false, width: 64)
            }
            HStack(alignment: .top, spacing: FeltSpacing.xl) {
                HandView(cards: [Card(rank: .ace, suit: .hearts), Card(rank: .seven, suit: .clubs)],
                         cardWidth: 70, totalLabel: "Soft 18")
                HandView(cards: [Card(rank: .nine, suit: .spades), Card(rank: .king, suit: .diamonds)],
                         faceDownIndices: [1], cardWidth: 70)
            }
        }
    }

    private var docks: some View {
        VStack(spacing: FeltSpacing.l) {
            ActionDock(legal: Set(Action.allCases)) { _ in }
            ActionDock(legal: [.hit, .stand, .double], hint: .double) { _ in }
            ActionDock(legal: [.hit, .stand]) { _ in }
        }
    }

    private var feedback: some View {
        VStack(spacing: FeltSpacing.xxl) {
            FeedbackCard(verdict: .correct, headline: "Correct — double",
                         reason: "Soft 18 vs 6: the dealer busts often; double to press the edge.",
                         onWhy: {}, onNext: {})
            FeedbackCard(verdict: .incorrect, headline: "Hit, not stand",
                         reason: "Hard 16 vs 10: standing loses more often than hitting.",
                         onWhy: {}, onNext: {})
        }
        .padding(.top, FeltSpacing.xl)
    }

    private var surfaces: some View {
        VStack(spacing: FeltSpacing.m) {
            HStack(spacing: FeltSpacing.s) {
                StatChip(label: "Strategy", value: "92%")
                StatChip(label: "Count", value: "—")
                StatChip(label: "Streak", value: "14")
            }
            ModuleTile(title: "Strategy", subtitle: "Basic strategy drills") {}
            PrimaryButton(title: "Continue") {}
            SecondaryButton(title: "Close") {}
        }
    }

    private var controls: some View {
        VStack(spacing: FeltSpacing.l) {
            ModePicker(options: ["Learn", "Test", "Speed", "Weak spots"], selection: $mode) { $0 }
            SettingsSection(title: "Section") {
                SettingsRow(label: "Value") { Text("6 decks") }
                SettingsRow(label: "Toggle") { Toggle("", isOn: $toggle).labelsHidden() }
                SettingsRow(label: "Stepper") {
                    Stepper("\(stepper)", value: $stepper, in: 2...4).fixedSize()
                }
                SettingsRow(label: "With footnote", footnote: "A tertiary footnote under the row.") {
                    Text("Late")
                }
            }
        }
    }
}
#endif
```

- [ ] **Step 2: Present at launch in DEBUG**

In `BJS/App/RootTabView.swift`, add this state to `RootTabView`:

```swift
    @State private var showsCatalogue = false
```

Add these modifiers after `.tint(FeltColor.cream)`:

```swift
        #if DEBUG
        .onAppear { showsCatalogue = showsCatalogueAtLaunch }
        .fullScreenCover(isPresented: $showsCatalogue) {
            FeltCatalogue { showsCatalogue = false }
        }
        #endif
```

- [ ] **Step 3: Build, test and look**

Run the app test command. Expected: all suites pass, with no warnings in `FeltCatalogue.swift`.

Launch with `-uiTesting -showCatalogue` on iPhone 16, for example `xcrun simctl launch booted com.bjs.app -uiTesting -showCatalogue` after installing. Scroll the whole catalogue and check the following:
- every contrast row shows ✓;
- dimmed dock buttons read as disabled, and the hint ring is brass;
- both feedback badges straddle the card's top edge;
- the card back shows diagonal stripes.

- [ ] **Step 4: Commit**

```bash
git add BJS/Design/Catalogue/FeltCatalogue.swift BJS/App/RootTabView.swift
git commit -m "feat(design): DEBUG Felt catalogue of every token and component state"
```

---

### Task 14: Settings

**Files:**
- Create: `BJS/Shared/RulesForm.swift`
- Create: `BJS/Features/Settings/PreferenceLabels.swift`
- Create: `BJS/Features/Settings/SettingsViewModel.swift`
- Create: `BJS/Features/Settings/SettingsView.swift`
- Modify: `BJS/App/RootTabView.swift` (use `SettingsView()` for the Settings tab; delete `SettingsPlaceholder`)
- Modify: `project.yml` (add `MARKETING_VERSION: "1.0"` and `CURRENT_PROJECT_VERSION: "1"` under the `BJS` target's `settings.base`)
- Test: `BJSTests/Features/SettingsTests.swift`

**Interfaces:**
- Consumes:
  - `ActiveRulesStore` (`rules`, `maxSplitHandsRange`), `PreferencesStore` (all properties and range constants) and `SessionStore.deleteAll()`;
  - the `RuleLabels` extensions, `RulePreset.label(for:)`, `SettingsSection` and `SettingsRow`;
  - `FeltCatalogue` (DEBUG).
- Produces:
  - `RulesForm(rules: Binding<BlackjackRules>)`, in `Shared/`, for reuse by Edge in Step 5;
  - `PreferenceLabels.speedTimer(_:) -> String` and `PreferenceLabels.shoeCheck(_:) -> String`;
  - `RulesForm.surrenderFootnote(for:) -> String?`;
  - `@Observable final class SettingsViewModel` with `showsResetError` and `resetProgress(using:)`;
  - `SettingsView()`.
- Accessibility identifier: the preset menu is `settings.preset`. Its options are buttons titled with `RulePreset.displayName`.

- [ ] **Step 1: Write the failing tests**

`BJSTests/Features/SettingsTests.swift`:

```swift
import Foundation
import SwiftData
import Testing
import BJSCore
@testable import BJS

@MainActor
struct SettingsTests {

    @Test("Preference labels")
    func preferenceLabels() {
        #expect(PreferenceLabels.speedTimer(3) == "3.0 s")
        #expect(PreferenceLabels.speedTimer(1.5) == "1.5 s")
        #expect(PreferenceLabels.shoeCheck(4) == "Every 4 rounds")
    }

    @Test("Surrender footnote appears only under no hole card")
    func surrenderFootnote() {
        var r = BlackjackRules()
        #expect(RulesForm.surrenderFootnote(for: r) == nil)
        r.peekRule = .europeanNoPeek
        #expect(RulesForm.surrenderFootnote(for: r) == "With no hole card, late and early surrender play the same.")
    }

    @Test("Max split hands stepper range is 2…4")
    func splitRange() {
        #expect(ActiveRulesStore.maxSplitHandsRange == 2...4)
    }

    @Test("Reset deletes sessions and leaves rules and preferences alone")
    func reset() throws {
        let container = try BJSModelContainer.make(inMemory: true)
        let sessions = SessionStore(context: container.mainContext)
        let defaults = makeTestDefaults()
        let rules = ActiveRulesStore(defaults: defaults)
        let prefs = PreferencesStore(defaults: defaults)
        rules.rules = RulePreset.atlanticCity.rules
        prefs.speedTimerSeconds = 2
        try sessions.save(SessionDraft(module: .strategy, mode: nil, startedAt: .now, endedAt: .now,
                                       rules: rules.rules))

        let model = SettingsViewModel()
        model.resetProgress(using: sessions)

        #expect(try sessions.sessionSamples().isEmpty)
        #expect(!model.showsResetError)
        #expect(ActiveRulesStore(defaults: defaults).rules == RulePreset.atlanticCity.rules)
        #expect(PreferencesStore(defaults: defaults).speedTimerSeconds == 2)
    }
}
```

`makeTestDefaults()` is the helper defined in `BJSTests/Shared/StoreTests.swift` (Task 8).

- [ ] **Step 2: Run the tests to verify they fail**

Run the app test command with `-only-testing:BJSTests/SettingsTests`.
Expected: build failure, `cannot find 'PreferenceLabels' in scope`.

- [ ] **Step 3: Implement**

`BJS/Features/Settings/PreferenceLabels.swift`:

```swift
enum PreferenceLabels {
    static func speedTimer(_ seconds: Double) -> String {
        "\(seconds.formatted(.number.precision(.fractionLength(1)))) s"
    }

    static func shoeCheck(_ rounds: Int) -> String { "Every \(rounds) rounds" }
}
```

`BJS/Features/Settings/SettingsViewModel.swift`:

```swift
import Observation
import os

@Observable
final class SettingsViewModel {
    var showsResetError = false

    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "Settings")

    /// Deletes all sessions. Rules and preferences are untouched (parent spec §5).
    func resetProgress(using store: SessionStore) {
        do {
            try store.deleteAll()
        } catch {
            logger.error("Reset progress failed: \(error.localizedDescription)")
            showsResetError = true
        }
    }
}
```

`BJS/Shared/RulesForm.swift`:

```swift
import SwiftUI
import BJSCore

/// Preset picker plus every `BlackjackRules` field. Shared so Edge (Step 5) can edit rules
/// other than the active set without importing Settings.
struct RulesForm: View {
    @Binding var rules: BlackjackRules

    static func surrenderFootnote(for rules: BlackjackRules) -> String? {
        rules.peekRule == .europeanNoPeek
            ? "With no hole card, late and early surrender play the same."
            : nil
    }

    var body: some View {
        VStack(spacing: FeltSpacing.xl) {
            SettingsSection(title: "Preset") {
                SettingsRow(label: "Rule set") {
                    Menu {
                        ForEach(RulePreset.allCases) { preset in
                            Button(preset.displayName) { rules = preset.rules }
                        }
                    } label: {
                        HStack(spacing: FeltSpacing.xs) {
                            Text(RulePreset.label(for: rules))
                            Image(systemName: "chevron.up.chevron.down").font(.caption)
                        }
                        .feltText(.body)
                        .frame(minHeight: FeltTapTarget.minimum)
                    }
                    .accessibilityIdentifier("settings.preset")
                }
            }
            SettingsSection(title: "Table rules") {
                SettingsRow(label: "Decks") {
                    picker("Decks", $rules.deckCount, BlackjackRules.DeckCount.allCases) { $0.label }
                }
                SettingsRow(label: "Dealer soft 17") {
                    picker("Dealer soft 17", $rules.dealerSoft17, BlackjackRules.DealerSoft17.allCases) { $0.label }
                }
                SettingsRow(label: "Blackjack pays") {
                    picker("Blackjack pays", $rules.blackjackPayout,
                           BlackjackRules.BlackjackPayout.allCases) { $0.label }
                }
                SettingsRow(label: "Double on") {
                    picker("Double on", $rules.doubleRestriction,
                           BlackjackRules.DoubleRestriction.allCases) { $0.label }
                }
                SettingsRow(label: "Double after split") {
                    Toggle("Double after split", isOn: $rules.doubleAfterSplit).labelsHidden()
                }
                SettingsRow(label: "Max split hands") {
                    Stepper(value: $rules.maxSplitHands, in: ActiveRulesStore.maxSplitHandsRange) {
                        Text("\(rules.maxSplitHands)").feltText(.body)
                    }
                    .fixedSize()
                }
                SettingsRow(label: "Resplit aces") {
                    Toggle("Resplit aces", isOn: $rules.resplitAces).labelsHidden()
                }
                SettingsRow(label: "Hit split aces") {
                    Toggle("Hit split aces", isOn: $rules.hitSplitAces).labelsHidden()
                }
                SettingsRow(label: "Surrender", footnote: Self.surrenderFootnote(for: rules)) {
                    picker("Surrender", $rules.surrenderRule, BlackjackRules.SurrenderRule.allCases) { $0.label }
                }
                SettingsRow(label: "Hole card") {
                    picker("Hole card", $rules.peekRule, BlackjackRules.PeekRule.allCases) { $0.label }
                }
            }
        }
    }

    private func picker<Value: Hashable>(_ title: String, _ selection: Binding<Value>, _ options: [Value],
                                         label: @escaping (Value) -> String) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.self) { Text(label($0)).tag($0) }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
}
```

`BJS/Features/Settings/SettingsView.swift`:

```swift
import SwiftUI
import BJSCore

/// Settings tab: table rules, preferences, reset progress, about.
struct SettingsView: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(PreferencesStore.self) private var preferences
    @Environment(SessionStore.self) private var sessionStore
    @State private var model = SettingsViewModel()
    @State private var confirmingReset = false

    var body: some View {
        @Bindable var preferences = preferences
        NavigationStack {
            ZStack {
                FeltBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                        Text("Settings")
                            .feltText(.display)
                            .foregroundStyle(FeltColor.textPrimary)
                        RulesForm(rules: Binding(get: { rulesStore.rules }, set: { rulesStore.rules = $0 }))
                        preferencesSection(preferences)
                        SettingsSection(title: "Progress") {
                            SettingsRow(label: "Reset progress") {
                                Button("Reset", role: .destructive) { confirmingReset = true }
                                    .foregroundStyle(FeltColor.incorrect)
                                    .font(FeltType.body.font.weight(.semibold))
                                    .frame(minHeight: FeltTapTarget.minimum)
                            }
                        }
                        aboutSection
                        #if DEBUG
                        SettingsSection(title: "Debug") {
                            NavigationLink {
                                FeltCatalogue().toolbar(.visible, for: .navigationBar)
                            } label: {
                                SettingsRow(label: "Felt catalogue") { Image(systemName: "chevron.right") }
                            }
                            .buttonStyle(.plain)
                        }
                        #endif
                    }
                    .padding(FeltSpacing.l)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .confirmationDialog("Reset all progress?", isPresented: $confirmingReset, titleVisibility: .visible) {
            Button("Reset progress", role: .destructive) { model.resetProgress(using: sessionStore) }
        } message: {
            Text("This deletes every saved session. Your rules and preferences stay.")
        }
        .alert("Couldn't reset progress", isPresented: $model.showsResetError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Nothing was deleted. Please try again.")
        }
    }

    private func preferencesSection(_ preferences: Bindable<PreferencesStore>) -> some View {
        SettingsSection(title: "Preferences") {
            SettingsRow(label: "Speed timer") {
                Stepper(value: preferences.speedTimerSeconds, in: PreferencesStore.speedTimerRange,
                        step: PreferencesStore.speedTimerStep) {
                    Text(PreferenceLabels.speedTimer(preferences.wrappedValue.speedTimerSeconds)).feltText(.body)
                }
                .fixedSize()
            }
            SettingsRow(label: "True count") {
                Picker("True count", selection: preferences.trueCountConvention) {
                    ForEach(TrueCountConvention.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            SettingsRow(label: "Shoe Sim count check") {
                Stepper(value: preferences.shoeCheckFrequency, in: PreferencesStore.shoeCheckRange) {
                    Text(PreferenceLabels.shoeCheck(preferences.wrappedValue.shoeCheckFrequency)).feltText(.body)
                }
                .fixedSize()
            }
            SettingsRow(label: "Haptics") {
                Toggle("Haptics", isOn: preferences.hapticsEnabled).labelsHidden()
            }
        }
    }

    private var aboutSection: some View {
        SettingsSection(title: "About") {
            SettingsRow(label: "Version") { Text(Self.versionText).feltText(.body) }
            SettingsRow(label: "Strategy") {
                Link("WizardOfOdds.com",
                     destination: URL(string: "https://wizardofodds.com/games/blackjack/strategy/calculator/")!)
                    .feltText(.body)
            }
        }
    }

    private static var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
```

Two binding notes:
- `@Bindable var preferences` is declared inside `body`, and `preferencesSection` takes the `Bindable` wrapper. `preferences.speedTimerSeconds` on a `Bindable` yields a `Binding<Double>`, and `.wrappedValue` reads the current value.
- If the compiler rejects passing `Bindable` as a parameter, declare `@Bindable var preferences = preferences` at the top of `preferencesSection` instead, taking `PreferencesStore`. Behaviour is identical.

About row wording: the spec asks for the credit "Strategy by WizardOfOdds.com". The row label is "Strategy", and the value is the link "WizardOfOdds.com", so it reads as that credit.

In `project.yml`, under `targets.BJS.settings.base`, add:

```yaml
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
```

In `BJS/App/RootTabView.swift`, replace `SettingsPlaceholder()` with `SettingsView()` and delete the `SettingsPlaceholder` struct.

- [ ] **Step 4: Run all app tests**

Run the app test command.
Expected: all suites pass, including the 4 `SettingsTests`.

- [ ] **Step 5: Launch check**

Run on iPhone 16 and iPhone SE (3rd generation) with `-uiTesting`. Check the following:
- Picking "Downtown Vegas" updates every row and the hub header (`2D · H17 · DAS · LS · 3:2`).
- Changing any rule after a preset shows "Custom".
- Max split hands stops at 2 and 4.
- Setting the hole card to "No hole card" shows the surrender footnote.
- Reset shows the confirmation dialog.
- The version shows `1.0 (1)`.
- The Felt catalogue row pushes the catalogue.
- On SE, rows don't clip; long values may wrap the label, but not overlap.

- [ ] **Step 6: Commit**

```bash
git add BJS/Shared/RulesForm.swift BJS/Features/Settings BJS/App/RootTabView.swift project.yml BJSTests/Features/SettingsTests.swift
git commit -m "feat(settings): rules form with presets, preferences, reset and about"
```

---

### Task 15: UI smoke test target

**Files:**
- Modify: `project.yml` (add the `BJSUITests` target and add it to the `BJS` scheme's `testTargets`)
- Create: `BJSUITests/FoundationUITests.swift`

**Interfaces:**
- Consumes:
  - the `-uiTesting` launch argument (Task 11);
  - the `hub.rulesSummary` button, whose accessibility value is the summary text (Task 12);
  - the `settings.preset` menu and its preset name buttons (Task 14);
  - the tab bar button "Train".

- [ ] **Step 1: Add the target**

In `project.yml`, change the `BJS` target's scheme to:

```yaml
    scheme:
      testTargets:
        - BJSTests
        - BJSUITests
```

And add this target under `targets:`:

```yaml
  BJSUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [BJSUITests]
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
    dependencies:
      - target: BJS
```

- [ ] **Step 2: Write the UI test**

`BJSUITests/FoundationUITests.swift`:

```swift
import XCTest

@MainActor
final class FoundationUITests: XCTestCase {

    func testPresetChangeUpdatesHubHeader() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let header = app.buttons["hub.rulesSummary"]
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        XCTAssertEqual(header.value as? String, "6D · S17 · DAS · 3:2")

        header.tap()
        let preset = app.buttons["settings.preset"]
        XCTAssertTrue(preset.waitForExistence(timeout: 5))
        preset.tap()
        let downtown = app.buttons["Downtown Vegas"]
        XCTAssertTrue(downtown.waitForExistence(timeout: 5))
        downtown.tap()

        app.tabBars.buttons["Train"].tap()
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertEqual(header.value as? String, "2D · H17 · DAS · LS · 3:2")
    }
}
```

The test does not override `setUp`. Under `DefaultIsolationMainActor`, a main-actor override of XCTest's nonisolated `setUp` can fail to compile.

- [ ] **Step 3: Run the full app test command**

Run the app test command (it now includes UI tests).
Expected: all unit suites pass and `testPresetChangeUpdatesHubHeader` passes.

If the test cannot find `settings.preset`, the identifier may not propagate to the `Menu` element. Inspect the hierarchy with `print(app.debugDescription)` inside the test. Then move `.accessibilityIdentifier("settings.preset")` onto the `Menu`'s label `HStack`, and keep it off the `SettingsRow`. Don't change the test's intent.

- [ ] **Step 4: Commit**

```bash
git add project.yml BJSUITests/FoundationUITests.swift
git commit -m "test(app): UI smoke test — preset change updates hub header"
```

---

### Task 16: Design check, freeze sign-off and handoff

The **main session** runs this task, not a subagent: it needs Luke's sign-off.

- [ ] **Step 1: Full verification**

Run each of these and read the output:
- `cd BJSCore && swift test 2>&1 | tail -5`. Expect all tests to pass (211).
- The app test command. Expect every unit suite and the UI test to pass, with no warnings in files touched this step.

- [ ] **Step 2: Capture screenshots**

Build the app for the simulator once. Then, on **iPhone 16** and **iPhone SE (3rd generation)**, install and launch it three times:
1. `-uiTesting` (hub);
2. `-uiTesting -startTab settings` (Settings, scrolled top to bottom);
3. `-uiTesting -showCatalogue` (catalogue, scrolled top to bottom).

Capture each screen with the iOS Simulator tool's `screenshot`, using `swipe` to scroll. Save the PNGs under the session scratchpad, e.g. `step2-review/iphone16-hub.png`.

- [ ] **Step 3: Self-check against the spec before showing Luke**

Compare the screenshots with parent spec §4 and Step 2 spec §1–§4:
- tokens, radii and type roles as specified;
- brass used only for the hint ring;
- no `correct`/`incorrect` text on cream;
- 44 pt targets;
- nothing clipped on SE.

Fix any deviations (each fix is its own commit, `fix(design)` etc.) and recapture.

- [ ] **Step 4: Publish the review page**

Load the `artifact-design` skill. Build one private review page with the screenshots grouped by screen, iPhone 16 and SE side by side, and a short checklist of what to look at. Publish it with the Artifact tool and give Luke the link.

- [ ] **Step 5: Sign-off loop**

Ask Luke to approve or list fixes. Apply each requested fix in its own commit, recapture the affected screens, republish to the same artifact, and repeat until Luke approves. **Felt is frozen only after his explicit approval.**

- [ ] **Step 6: Handoff**

Append to `docs/superpowers/progress.md`:

```markdown
## Step 2 — Foundation (2026-MM-DD)

- Spec: `docs/superpowers/specs/2026-09-24-step-2-foundation-design.md`. Plan: `docs/superpowers/plans/2026-09-24-step-2-foundation.md`. Commits: 0cafc73..(this handoff).
- BJSCore tests: N passing. App unit tests: N passing. UI test: preset → hub header passing.
- **Felt design system FROZEN** on YYYY-MM-DD after Luke's sign-off (review page: <artifact link>). Later steps may add
  components built from existing tokens; changing a token or existing component needs Luke's explicit decision in its own change.
- Shipped:
  - Felt tokens (`FeltPalette`/`FeltColor`, `FeltType`, `FeltSpacing`, `FeltRadius`, `FeltMotion`), tested contrast (`FeltContrast`).
  - Components: FeltBackground, PlayingCard, HandView, ActionDock, FeedbackCard, StatChip, ModuleTile, Primary/SecondaryButton, ModePicker, SettingsSection/Row, CountKeypad (+ `CountEntry`), ComingSoonView; DEBUG `FeltCatalogue`.
  - Hub (rules header → Settings, stat chips, tiles → placeholders), Settings (shared `RulesForm`, preferences, reset, about), Progress placeholder.
  - `ActiveRulesStore`, `PreferencesStore` (+ `LastLaunch`), `AppRouter`, `LaunchConfiguration` (`-uiTesting`, `-startTab`, `-showCatalogue`).
  - SwiftData `SchemaV1` + `BJSMigrationPlan`, `SessionStore` (`SessionDraft` → records; chronological samples; `deleteAll`; `revision`), `SessionSummary` in BJSCore.
- Notes for Step 3 (Strategy):
  - Save sessions via `SessionStore.save(SessionDraft)`; decisions in order, `chosen: .timeout` for Speed timeouts; use
    `TrainingCell(spot:)` for the cell and `StrategyTable.action(for: DecisionSpot)` for `correctAction`.
  - Refresh views with `.task(id: sessionStore.revision)`.
  - Set `PreferencesStore.lastLaunch` when a session starts and wire the hub's Continue button (currently a no-op, hidden until set).
  - Replace the hub's Strategy placeholder (`HubModule.strategy`) with the setup screen; keep features from importing each other.
  - Save failures: show a non-blocking alert; still show the summary.
  - `Session` naming: the cached count is `countCheckCount` (relationship is `countChecks`).
- Carry-overs still open: Step 3 items from the WoO entry (H14 vs 10 composition, WHY rules context, A,A vs A ENHC RSA); Step 5 EdgeCalculator ENHC late surrender; Step 6 ignores hard 4 / soft 12 cells in the heat map.
- Next: Step 3 (Strategy) — brainstorm/plan in a fresh session.
```

Fill in the counts, dates and the artifact link. Commit:

```bash
git add docs/superpowers/progress.md
git commit -m "docs: Step 2 handoff; Felt design system frozen"
```

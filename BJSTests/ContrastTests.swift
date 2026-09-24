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

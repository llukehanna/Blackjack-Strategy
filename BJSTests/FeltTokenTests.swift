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

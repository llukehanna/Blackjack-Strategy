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

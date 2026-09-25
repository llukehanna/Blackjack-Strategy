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

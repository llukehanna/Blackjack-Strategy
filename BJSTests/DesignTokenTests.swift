import Testing
@testable import BJS

struct DesignTokenTests {
    @Test func spacingValues() {
        #expect(Spacing.xs == 4)
        #expect(Spacing.sm == 8)
        #expect(Spacing.md == 16)
        #expect(Spacing.lg == 24)
        #expect(Spacing.xl == 48)
        #expect(Spacing.xxl == 64)
    }

    @Test func cornerRadiusValues() {
        #expect(CornerRadius.card == 8)
        #expect(CornerRadius.button == 0)
        #expect(CornerRadius.overlayButton == 12)
        #expect(CornerRadius.overlay == 24)
        #expect(CornerRadius.navCircle == 16)
    }

    @Test func elevationValues() {
        #expect(Elevation.card.radius == 12)
        #expect(Elevation.card.y == 6)
        #expect(Elevation.overlay.radius == 24)
        #expect(Elevation.overlay.y == -8)
    }

    @Test func animationTimingExists() {
        _ = AnimationTiming.tap
        _ = AnimationTiming.overlayIn
        _ = AnimationTiming.overlayOut
        _ = AnimationTiming.cardDeal
        #expect(AnimationTiming.cardDealStagger == 0.060)
    }

    @Test func colorTokensExist() {
        // Compile-time existence check — if any symbol is missing, file won't compile.
        _ = BJSColors.surfaceBase
        _ = BJSColors.surfaceRaised
        _ = BJSColors.actionDark
        _ = BJSColors.surfaceOverlay
        _ = BJSColors.borderSubtle
        _ = BJSColors.borderOnOverlay
        _ = BJSColors.accentGold
        _ = BJSColors.actionLabel
        _ = BJSColors.watermarkInk
        _ = BJSColors.textPrimary
        _ = BJSColors.textSecondary
        _ = BJSColors.textOnOverlay
        _ = BJSColors.textOnOverlayMuted
        _ = BJSColors.feedbackCorrect
        _ = BJSColors.feedbackIncorrect
        _ = BJSColors.cardBackRed
    }

    @Test func typographyRolesExist() {
        _ = Typography.caption
        _ = Typography.body
        _ = Typography.title
    }
}

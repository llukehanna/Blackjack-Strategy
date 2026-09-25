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

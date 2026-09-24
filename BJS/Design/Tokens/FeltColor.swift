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

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

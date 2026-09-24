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

/// An sRGB colour with channels in 0...1. Plain data, so the contrast test can do maths on it.
struct RGBColor: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// `RGBColor(hex: 0x123A2B)`.
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }

    /// This colour drawn at `opacity` on top of an opaque `background`.
    func composited(over background: RGBColor, opacity: Double) -> RGBColor {
        RGBColor(red: red * opacity + background.red * (1 - opacity),
                 green: green * opacity + background.green * (1 - opacity),
                 blue: blue * opacity + background.blue * (1 - opacity))
    }
}

/// Raw Felt colour values (spec §4). FROZEN at the end of Step 2.
///
/// `FeltColor` builds the SwiftUI colours from these values, and the WCAG contrast
/// test reads them directly, so the tested numbers are the shipped numbers.
enum FeltPalette {
    static let feltDeep = RGBColor(hex: 0x0C2A1F)
    static let feltBase = RGBColor(hex: 0x123A2B)
    static let feltLight = RGBColor(hex: 0x1F5A43)
    static let cream = RGBColor(hex: 0xFBFAF6)
    static let onCream = RGBColor(hex: 0x123A2B)
    static let onCreamSecondary = RGBColor(hex: 0x3D6B57)
    static let brass = RGBColor(hex: 0xD9B45A)
    static let correct = RGBColor(hex: 0x6EE7A0)
    static let incorrect = RGBColor(hex: 0xFF6B5B)
    static let suitRed = RGBColor(hex: 0xD23B3B)
    static let suitBlack = RGBColor(hex: 0x111111)
    static let textPrimary = RGBColor(hex: 0xEEF3EE)
    static let textSecondary = RGBColor(hex: 0xA9C4B6)
    static let textTertiary = RGBColor(hex: 0x8FB3A2)

    /// `surfaceInset` is black at 22% over whatever is behind it.
    static let surfaceInsetOpacity = 0.22

    /// The opaque colour `surfaceInset` produces on top of `background`.
    static func surfaceInset(over background: RGBColor) -> RGBColor {
        RGBColor(hex: 0x000000).composited(over: background, opacity: surfaceInsetOpacity)
    }
}

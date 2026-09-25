/// Raw Felt colour tokens (parent spec §4). FROZEN after Step 2: changing a value
/// needs an explicit decision from Luke in its own change.
enum FeltPalette {
    static let feltDeep = FeltRGB(0x0C2A1F)
    static let feltBase = FeltRGB(0x123A2B)
    static let feltLight = FeltRGB(0x1F5A43)
    static let cream = FeltRGB(0xFBFAF6)
    static let onCream = FeltRGB(0x123A2B)
    static let onCreamSecondary = FeltRGB(0x3D6B57)
    static let brass = FeltRGB(0xD9B45A)
    static let correct = FeltRGB(0x6EE7A0)
    static let incorrect = FeltRGB(0xFF6B5B)
    static let suitRed = FeltRGB(0xD23B3B)
    static let suitBlack = FeltRGB(0x111111)
    static let textPrimary = FeltRGB(0xEEF3EE)
    static let textSecondary = FeltRGB(0xA9C4B6)
    static let textTertiary = FeltRGB(0x8FB3A2)

    /// `surfaceInset` is black at this opacity.
    static let surfaceInsetOpacity = 0.22
    /// `FeltBackground` draws `feltLight` at this opacity over `feltBase` (Step 2 spec §1).
    static let glowOpacity = 0.45

    /// The brightest point of the felt: `feltLight` at `glowOpacity` over `feltBase` (#184836).
    static let glowCentre = feltLight.over(feltBase, opacity: glowOpacity)
    /// `surfaceInset` as it renders over `feltBase` (#0E2D22).
    static let surfaceInsetOnBase = FeltRGB(0x000000).over(feltBase, opacity: surfaceInsetOpacity)
}

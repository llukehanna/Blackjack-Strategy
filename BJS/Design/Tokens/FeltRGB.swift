import SwiftUI

/// An opaque sRGB colour with WCAG 2.x contrast maths, so token pairings can be unit-tested.
struct FeltRGB: Hashable, Sendable {
    let hex: UInt32

    init(_ hex: UInt32) {
        self.hex = hex & 0xFFFFFF
    }

    var red: Double { Double((hex >> 16) & 0xFF) / 255 }
    var green: Double { Double((hex >> 8) & 0xFF) / 255 }
    var blue: Double { Double(hex & 0xFF) / 255 }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }

    /// This colour drawn at `opacity` over `background`, rounded to 8-bit channels.
    func over(_ background: FeltRGB, opacity: Double) -> FeltRGB {
        func channel(_ shift: UInt32) -> UInt32 {
            let fg = Double((hex >> shift) & 0xFF)
            let bg = Double((background.hex >> shift) & 0xFF)
            return UInt32((opacity * fg + (1 - opacity) * bg).rounded()) << shift
        }
        return FeltRGB(channel(16) | channel(8) | channel(0))
    }

    /// WCAG 2.x relative luminance.
    var relativeLuminance: Double {
        func linear(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// WCAG 2.x contrast ratio, 1...21, order-independent.
    func contrastRatio(with other: FeltRGB) -> Double {
        let a = relativeLuminance, b = other.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}

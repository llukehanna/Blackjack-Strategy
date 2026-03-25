import SwiftUI

enum BJSColors {
    static let accent = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.82, green: 0.85, blue: 0.88, alpha: 1.0)  // #D1D9E0 light slate
                : UIColor(red: 0.11, green: 0.17, blue: 0.23, alpha: 1.0)  // #1C2B3A dark slate
        }
    )

    /// Muted green tint for correct feedback backgrounds (10% opacity)
    static let feedbackCorrectBackground = Color.green.opacity(0.10)

    /// Muted red tint for incorrect feedback backgrounds (10% opacity)
    static let feedbackIncorrectBackground = Color.red.opacity(0.10)

    /// Subtle green border for correct feedback banner (25% opacity)
    static let feedbackCorrectBorder = Color.green.opacity(0.25)

    /// Subtle red border for incorrect feedback banner (25% opacity)
    static let feedbackIncorrectBorder = Color.red.opacity(0.25)

    /// Icon tint for correct feedback (system semantic green)
    static let feedbackCorrectIcon = Color(UIColor.systemGreen)

    /// Icon tint for incorrect feedback (system semantic red)
    static let feedbackIncorrectIcon = Color(UIColor.systemRed)

    /// Face-down card back color — brand-adjacent slate, adapts to color scheme
    static let cardFaceDown = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.56, green: 0.64, blue: 0.71, alpha: 1.0)  // muted light slate for dark bg
                : UIColor(red: 0.11, green: 0.17, blue: 0.23, alpha: 1.0)  // #1C2B3A dark slate for light bg
        }
    )
}

import SwiftUI

enum BJSColors {
    static let accent = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.82, green: 0.85, blue: 0.88, alpha: 1.0)  // #D1D9E0 light slate
                : UIColor(red: 0.11, green: 0.17, blue: 0.23, alpha: 1.0)  // #1C2B3A dark slate
        }
    )
}

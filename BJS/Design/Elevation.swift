import CoreGraphics
import SwiftUI

enum Elevation {
    static let cardShadowOpacity: Double = 0.12
    static let cardShadowRadius: CGFloat = 4
    static let cardShadowY: CGFloat = 2
    /// Base shadow color for card elevation
    static let cardShadowColor: Color = Color.black.opacity(cardShadowOpacity)
}

import SwiftUI

enum Elevation {
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    static let card    = Shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
    static let overlay = Shadow(color: .black.opacity(0.6), radius: 24, x: 0, y: -8)
}

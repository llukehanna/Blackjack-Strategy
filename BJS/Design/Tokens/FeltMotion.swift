import SwiftUI

/// How a face-down card is revealed.
enum CardRevealStyle: Equatable {
    case flip
    case crossFade
}

/// Felt motion (parent spec §4). Every animation honours Reduce Motion by cross-fading.
enum FeltMotion {
    static let uiDuration: Double = 0.2
    static let dealDuration: Double = 0.25
    static let flipDuration: Double = 0.35

    static let ui: Animation = .easeOut(duration: uiDuration)
    static let deal: Animation = .easeOut(duration: dealDuration)
    static let flip: Animation = .easeInOut(duration: flipDuration)

    static func revealStyle(reduceMotion: Bool) -> CardRevealStyle {
        reduceMotion ? .crossFade : .flip
    }

    /// A card arriving on the table: slides in from the top, or cross-fades under Reduce Motion.
    static func dealTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity)
    }
}

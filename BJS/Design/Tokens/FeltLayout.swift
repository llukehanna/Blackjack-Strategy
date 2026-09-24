import SwiftUI

/// Spacing scale (spec §4): 4, 8, 12, 16, 24, 32. FROZEN at the end of Step 2.
enum FeltSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    static let scale: [CGFloat] = [xs, s, m, l, xl, xxl]
}

/// Corner radii (spec §4). FROZEN at the end of Step 2.
enum FeltRadius {
    static let chip: CGFloat = 10
    static let tile: CGFloat = 14
    static let button: CGFloat = 14
    static let card: CGFloat = 8
    static let sheet: CGFloat = 16
}

/// Fixed metrics shared by components.
enum FeltMetrics {
    /// Minimum tap target (Apple HIG, spec §4).
    static let minTapTarget: CGFloat = 44
    /// Playing card height = width × 1.4.
    static let cardAspectRatio: CGFloat = 1.4
}

/// Motion (spec §4): 0.2 s ease-out for UI, 0.25 s card deal, 0.35 s card flip.
/// With Reduce Motion on, components cross-fade instead of moving. FROZEN at the end of Step 2.
enum FeltMotion {
    static let uiDuration: TimeInterval = 0.2
    static let dealDuration: TimeInterval = 0.25
    static let flipDuration: TimeInterval = 0.35

    static var ui: Animation { .easeOut(duration: uiDuration) }
    static var deal: Animation { .easeOut(duration: dealDuration) }
    static var flip: Animation { .easeInOut(duration: flipDuration) }

    static func crossFade(duration: TimeInterval) -> Animation {
        .easeInOut(duration: duration)
    }

    /// Cards arrive from above; under Reduce Motion they fade in.
    @MainActor
    static func dealTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? AnyTransition.opacity : AnyTransition.move(edge: .top).combined(with: .opacity)
    }

    /// Bottom-anchored panels (FeedbackCard) slide up; under Reduce Motion they fade in.
    @MainActor
    static func panelTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? AnyTransition.opacity : AnyTransition.move(edge: .bottom).combined(with: .opacity)
    }
}

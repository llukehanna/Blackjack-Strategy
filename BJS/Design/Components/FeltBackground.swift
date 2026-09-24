import SwiftUI

/// The table felt: a radial gradient `feltLight` → `feltBase` → `feltDeep`, edge to edge.
struct FeltBackground: View {
    var body: some View {
        GeometryReader { proxy in
            RadialGradient(
                stops: [
                    Gradient.Stop(color: FeltColor.feltLight, location: 0),
                    Gradient.Stop(color: FeltColor.feltBase, location: 0.5),
                    Gradient.Stop(color: FeltColor.feltDeep, location: 1),
                ],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 0,
                endRadius: max(proxy.size.width, proxy.size.height) * 0.75
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    /// Puts the felt behind this view, extending under the safe areas.
    func feltBackground() -> some View {
        background { FeltBackground() }
    }
}

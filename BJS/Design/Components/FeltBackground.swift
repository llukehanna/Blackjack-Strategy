import SwiftUI

/// The felt: `feltBase` with a soft `feltLight` glow near the top, darkening to `feltDeep` at the edges.
struct FeltBackground: View {
    var body: some View {
        ZStack {
            FeltColor.feltBase
            RadialGradient(colors: [FeltColor.feltLight.opacity(FeltPalette.glowOpacity), .clear],
                           center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: 420)
            RadialGradient(colors: [.clear, FeltColor.feltDeep],
                           center: .center, startRadius: 300, endRadius: 720)
        }
        .ignoresSafeArea()
    }
}

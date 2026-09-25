import SwiftUI

/// Placeholder screen for modules that later steps build.
struct ComingSoonView: View {
    let title: String
    let message: String
    var onClose: (() -> Void)? = nil

    var body: some View {
        ZStack {
            FeltBackground()
            VStack(spacing: FeltSpacing.m) {
                Text(title)
                    .feltText(.display)
                    .foregroundStyle(FeltColor.textPrimary)
                Text(message)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textSecondary)
                if let onClose {
                    SecondaryButton(title: "Close", action: onClose)
                        .frame(maxWidth: 200)
                        .padding(.top, FeltSpacing.l)
                }
            }
            .padding(FeltSpacing.xl)
        }
    }
}

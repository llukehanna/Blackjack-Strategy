import SwiftUI

/// A brief checkmark pill for a correct decision that doesn't need the full FeedbackCard.
/// The caller shows it for `displayDuration` and posts a VoiceOver announcement.
struct FeltToast: View {
    let text: String

    static let displayDuration: Double = 0.8

    var body: some View {
        HStack(spacing: FeltSpacing.s) {
            Image(systemName: "checkmark")
                .font(.body.weight(.bold))
                .foregroundStyle(FeltColor.correct)
            Text(text)
                .feltText(.body)
                .foregroundStyle(FeltColor.textPrimary)
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.vertical, FeltSpacing.s)
        .background(FeltColor.surfaceInset, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

import SwiftUI

/// Decision feedback (spec §4): a cream card anchored at the bottom, over the dock.
/// A ✓ / ✕ badge straddles the top edge; then a headline, a one-line reason, and WHY + NEXT.
///
/// The caller positions it (bottom of the screen) and animates it in with
/// `FeltMotion.panelTransition(reduceMotion:)`.
struct FeedbackCard: View {
    static let badgeSize: CGFloat = 44

    private let isCorrect: Bool
    private let headline: String
    private let reason: String
    private let onWhy: () -> Void
    private let onNext: () -> Void

    init(isCorrect: Bool, headline: String, reason: String,
         onWhy: @escaping () -> Void, onNext: @escaping () -> Void) {
        self.isCorrect = isCorrect
        self.headline = headline
        self.reason = reason
        self.onWhy = onWhy
        self.onNext = onNext
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text(headline)
                .feltType(.title)
                .foregroundStyle(FeltColor.onCream)
            Text(reason)
                .feltType(.body)
                .foregroundStyle(FeltColor.onCreamSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: FeltSpacing.s) {
                Button("WHY", action: onWhy)
                    .buttonStyle(.feltOnCreamSecondary)
                    .accessibilityIdentifier("feedback.why")
                Button("NEXT", action: onNext)
                    .buttonStyle(.feltOnCreamPrimary)
                    .accessibilityIdentifier("feedback.next")
            }
            .padding(.top, FeltSpacing.s)
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.top, FeltSpacing.l + Self.badgeSize / 2)
        .padding(.bottom, FeltSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FeltColor.cream, in: RoundedRectangle(cornerRadius: FeltRadius.sheet, style: .continuous))
        .overlay(alignment: .top) {
            badge.offset(y: -Self.badgeSize / 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("feedback.card")
    }

    private var badge: some View {
        Image(systemName: isCorrect ? "checkmark" : "xmark")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(FeltColor.onCream)
            .frame(width: Self.badgeSize, height: Self.badgeSize)
            .background(isCorrect ? FeltColor.correct : FeltColor.incorrect, in: Circle())
            .overlay(Circle().strokeBorder(FeltColor.cream, lineWidth: 3))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isCorrect ? "Correct" : "Incorrect")
    }
}

import SwiftUI

enum FeedbackVerdict: Equatable {
    case correct
    case incorrect

    var glyph: String { self == .correct ? "checkmark" : "xmark" }
    var badgeColor: Color { self == .correct ? FeltColor.correct : FeltColor.incorrect }
    var accessibilityLabel: String { self == .correct ? "Correct" : "Incorrect" }
}

/// Cream card anchored at the bottom over the dock. The verdict badge straddles its top edge.
/// Text on the card is `onCream` / `onCreamSecondary`; `correct`/`incorrect` only fill the badge.
struct FeedbackCard: View {
    let verdict: FeedbackVerdict
    let headline: String
    let reason: String
    let onWhy: () -> Void
    let onNext: () -> Void

    private static let badgeSize: CGFloat = 48

    var body: some View {
        VStack(spacing: FeltSpacing.m) {
            Text(headline)
                .feltText(.title)
                .foregroundStyle(FeltColor.onCream)
                .multilineTextAlignment(.center)
            Text(reason)
                .feltText(.body)
                .foregroundStyle(FeltColor.onCreamSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: FeltSpacing.s) {
                Button(action: onWhy) {
                    Text("WHY")
                        .feltText(.title)
                        .foregroundStyle(FeltColor.onCream)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .overlay(RoundedRectangle(cornerRadius: FeltRadius.button)
                            .strokeBorder(FeltColor.onCream, lineWidth: 1.5))
                        .contentShape(RoundedRectangle(cornerRadius: FeltRadius.button))
                }
                .buttonStyle(.plain)
                Button(action: onNext) {
                    Text("NEXT")
                        .feltText(.title)
                        .foregroundStyle(FeltColor.cream)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(FeltColor.feltBase, in: RoundedRectangle(cornerRadius: FeltRadius.button))
                        .contentShape(RoundedRectangle(cornerRadius: FeltRadius.button))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.top, Self.badgeSize / 2 + FeltSpacing.m)
        .padding(.bottom, FeltSpacing.l)
        .frame(maxWidth: .infinity)
        .background(FeltColor.cream,
                    in: UnevenRoundedRectangle(topLeadingRadius: FeltRadius.sheet,
                                               topTrailingRadius: FeltRadius.sheet))
        .overlay(alignment: .top) { badge.offset(y: -Self.badgeSize / 2) }
        .accessibilityElement(children: .contain)
    }

    private var badge: some View {
        Image(systemName: verdict.glyph)
            .font(.title3.weight(.bold))
            .foregroundStyle(FeltColor.feltDeep)
            .frame(width: Self.badgeSize, height: Self.badgeSize)
            .background(verdict.badgeColor, in: Circle())
            .overlay(Circle().stroke(FeltColor.cream, lineWidth: 3))
            .accessibilityLabel(verdict.accessibilityLabel)
    }
}

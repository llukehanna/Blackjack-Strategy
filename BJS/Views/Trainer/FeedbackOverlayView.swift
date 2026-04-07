import SwiftUI

/// Bottom-anchored white-card feedback overlay per UI-SPEC 07 Feedback Overlay Contract.
/// - Straddling 48pt badge half-overlapping the top edge
/// - Heading + body + two stacked buttons (UNDERSTAND WHY outlined, DEAL dark fill)
/// - All copy strings are pinned verbatim by FeedbackOverlayTests
struct FeedbackOverlayView: View {
    let isCorrect: Bool
    let userActionLabel: String
    let correctActionLabel: String
    let onDeal: () -> Void
    let onUnderstandWhy: () -> Void

    // MARK: - Copy Contract (UI-SPEC verbatim, pinned by tests)

    static let headingCorrect = "Well played!"
    static let headingIncorrect = "Incorrect!"
    static let dealLabel = "DEAL"
    static let understandWhyLabel = "UNDERSTAND WHY"

    static func incorrectBody(userAction: String, correctAction: String) -> String {
        "In this situation \(userAction) isn't the right move. You should have \(correctAction)."
    }

    static func correctBody(action: String) -> String {
        "\(action) was the right move."
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: CornerRadius.overlay)
                .fill(BJSColors.surfaceOverlay)
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: Spacing.md) {
                Spacer().frame(height: Spacing.xs)
                Text(isCorrect ? Self.headingCorrect : Self.headingIncorrect)
                    .font(Typography.title)
                    .foregroundStyle(BJSColors.textOnOverlay)
                Text(bodyAttributedString)
                    .font(Typography.body)
                    .foregroundStyle(BJSColors.textOnOverlayMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                VStack(spacing: Spacing.sm) {
                    UnderstandWhyButton(action: onUnderstandWhy)
                    DealButton(action: onDeal)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .padding(.top, Spacing.md)

            badge
                .offset(y: -24) // half outside top edge (48pt / 2)
        }
        .fixedSize(horizontal: false, vertical: true)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isCorrect ? Self.headingCorrect : Self.headingIncorrect)
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(isCorrect ? BJSColors.feedbackCorrect : BJSColors.feedbackIncorrect)
                .frame(width: 48, height: 48)
            Image(systemName: isCorrect ? "checkmark" : "xmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var bodyAttributedString: AttributedString {
        if isCorrect {
            var s = AttributedString(Self.correctBody(action: correctActionLabel))
            if let range = s.range(of: correctActionLabel) {
                s[range].font = .system(size: 16, weight: .bold)
            }
            return s
        } else {
            var s = AttributedString(Self.incorrectBody(userAction: userActionLabel, correctAction: correctActionLabel))
            if let r1 = s.range(of: userActionLabel) {
                s[r1].font = .system(size: 16, weight: .bold)
            }
            if let r2 = s.range(of: correctActionLabel) {
                s[r2].font = .system(size: 16, weight: .bold)
            }
            return s
        }
    }
}

// MARK: - Buttons

private struct UnderstandWhyButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "questionmark.circle")
                Text(FeedbackOverlayView.understandWhyLabel)
                    .font(Typography.caption)
                    .tracking(1.5)
            }
            .foregroundStyle(BJSColors.textOnOverlay)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.overlayButton)
                    .fill(BJSColors.surfaceOverlay)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.overlayButton)
                    .stroke(BJSColors.borderOnOverlay, lineWidth: 1)
            )
        }
    }
}

private struct DealButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "square.on.square")
                Text(FeedbackOverlayView.dealLabel)
                    .font(Typography.caption)
                    .tracking(1.5)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.overlayButton)
                    .fill(BJSColors.actionDark)
            )
        }
    }
}

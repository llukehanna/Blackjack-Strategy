import SwiftUI

struct FeedbackOverlayView: View {
    let feedback: FeedbackResult

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                Text(feedback.message)
                    .font(Typography.body) // #warning("Phase 7: FeedbackOverlayView uses placeholder token — will be re-skinned in a later phase")
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.overlayButton) // #warning("Phase 7: FeedbackOverlayView uses placeholder token — will be re-skinned in a later phase")
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.overlayButton)
                            .stroke(borderColor, lineWidth: 0.5)
                    )
            )
            .padding(.top, Spacing.md)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityLabel(feedback.message)
    }

    private var iconName: String {
        switch feedback {
        case .correct: return "checkmark.circle.fill"
        case .incorrect: return "xmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch feedback {
        case .correct: return BJSColors.feedbackCorrect
        case .incorrect: return BJSColors.feedbackIncorrect
        }
    }

    private var backgroundColor: Color {
        // #warning("Phase 7: FeedbackOverlayView uses placeholder token — will be re-skinned in a later phase")
        switch feedback {
        case .correct: return BJSColors.feedbackCorrect.opacity(0.10)
        case .incorrect: return BJSColors.feedbackIncorrect.opacity(0.10)
        }
    }

    private var borderColor: Color {
        // #warning("Phase 7: FeedbackOverlayView uses placeholder token — will be re-skinned in a later phase")
        switch feedback {
        case .correct: return BJSColors.feedbackCorrect.opacity(0.25)
        case .incorrect: return BJSColors.feedbackIncorrect.opacity(0.25)
        }
    }
}

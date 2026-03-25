import SwiftUI

struct FeedbackOverlayView: View {
    let feedback: FeedbackResult

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                Text(feedback.message)
                    .font(Typography.buttonLabel)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.banner)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.banner)
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
        case .correct: return BJSColors.feedbackCorrectIcon
        case .incorrect: return BJSColors.feedbackIncorrectIcon
        }
    }

    private var backgroundColor: Color {
        switch feedback {
        case .correct: return BJSColors.feedbackCorrectBackground
        case .incorrect: return BJSColors.feedbackIncorrectBackground
        }
    }

    private var borderColor: Color {
        switch feedback {
        case .correct: return BJSColors.feedbackCorrectBorder
        case .incorrect: return BJSColors.feedbackIncorrectBorder
        }
    }
}

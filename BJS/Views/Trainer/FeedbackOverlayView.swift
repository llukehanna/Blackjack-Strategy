import SwiftUI

struct FeedbackOverlayView: View {
    let feedback: FeedbackResult

    var body: some View {
        ZStack {
            backgroundColor
            Text(feedback.message)
                .font(.title2.bold())
                .foregroundStyle(.white)
        }
        .transition(.opacity)
        .accessibilityLabel(feedback.message)
    }

    private var backgroundColor: Color {
        switch feedback {
        case .correct:
            return Color.green.opacity(0.85)
        case .incorrect:
            return Color.red.opacity(0.85)
        }
    }
}

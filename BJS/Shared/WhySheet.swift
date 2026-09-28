import SwiftUI
import BJSCore

struct WhySheet: View {
    let context: WhyContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            FeltBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.l) {
                    HStack {
                        Text(TrainingText.handLabel(context)).feltText(.display).foregroundStyle(FeltColor.textPrimary)
                        Spacer()
                        CloseButton(identifier: "strategy.close") { dismiss() }
                    }
                    HStack(spacing: FeltSpacing.s) {
                        StatChip(label: "Your play",
                                 value: context.userAction.map(TrainingText.actionName) ?? "Time's up")
                        StatChip(label: "Correct play", value: TrainingText.actionName(context.correctAction))
                    }
                    Text(WhyExplanation.explain(context))
                        .feltText(.body).foregroundStyle(FeltColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(RulesSummary.text(for: context.rules))
                        .feltText(.label).foregroundStyle(FeltColor.textTertiary)
                }
                .padding(FeltSpacing.l)
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("strategy.why")
    }
}

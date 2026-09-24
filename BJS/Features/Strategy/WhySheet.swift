import BJSCore
import SwiftUI

/// The WHY sheet (spec §5): `WhyExplanation` for this exact hand, upcard and rules.
struct WhySheet: View {
    private let context: WhyContext

    @Environment(\.dismiss) private var dismiss

    init(context: WhyContext) {
        self.context = context
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.l) {
                VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                    HStack {
                        Text("Why")
                            .feltType(.label)
                            .foregroundStyle(FeltColor.textTertiary)
                        Spacer(minLength: FeltSpacing.s)
                        Button("Done") { dismiss() }
                            .feltType(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(FeltColor.textPrimary)
                            .frame(minWidth: FeltMetrics.minTapTarget, minHeight: FeltMetrics.minTapTarget)
                            .buttonStyle(FeltPressableStyle())
                            .accessibilityIdentifier("why.done")
                    }
                    Text(DecisionFeedback.spotTitle(context))
                        .feltType(.display)
                        .foregroundStyle(FeltColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("why.title")
                    Text("Rules: \(RulesSummary.short(context.rules))")
                        .feltType(.label)
                        .foregroundStyle(FeltColor.textSecondary)
                }
                StatChip(label: "Basic strategy", value: DecisionFeedback.actionName(context.correctAction))
                    .accessibilityIdentifier("why.play")
                Text(WhyExplanation.explain(context))
                    .feltType(.body)
                    .foregroundStyle(FeltColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("why.explanation")
            }
            .padding(FeltSpacing.l)
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(FeltRadius.sheet)
        .presentationBackground(FeltColor.feltBase)
    }
}

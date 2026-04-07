import SwiftUI
import BJSCore

/// Sheet presented from the feedback overlay's WHY button. Renders a
/// `WhyContext` as a learner-facing explanation of the correct play.
///
/// Visual contract:
/// - Dark surface (BJSColors.surfaceBase) — this is a sheet, not the
///   white feedback card.
/// - All text uses BJS Typography + BJSColors tokens. No system colors.
struct WhyExplanationView: View {
    let context: WhyContext

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BJSColors.surfaceBase.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("Why \(actionName(context.correctAction))?")
                            .font(Typography.title)
                            .foregroundStyle(BJSColors.textPrimary)

                        Text(handSummary)
                            .font(Typography.body)
                            .foregroundStyle(BJSColors.textSecondary)

                        Text(WhyExplanation.explain(context))
                            .font(Typography.body)
                            .foregroundStyle(BJSColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        if !ruleSummary.isEmpty {
                            Text(ruleSummary)
                                .font(Typography.caption)
                                .tracking(1.2)
                                .foregroundStyle(BJSColors.textSecondary)
                                .padding(.top, Spacing.md)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(BJSColors.textPrimary)
                }
            }
        }
        .presentationBackground(BJSColors.surfaceBase)
    }

    // MARK: - Derived copy

    private var handSummary: String {
        let hand: String
        switch context.handType {
        case .hard:
            hand = "Hard \(context.handTotal)"
        case .soft:
            hand = "Soft \(context.handTotal)"
        case .pair:
            hand = "Pair of \(pairRankName(context.pairRank))s"
        }
        return "\(hand) vs Dealer \(upCardName(context.dealerUpCard))"
    }

    private var ruleSummary: String {
        var parts: [String] = []
        switch context.rules.dealerSoft17 {
        case .stands: parts.append("S17")
        case .hits: parts.append("H17")
        }
        if context.rules.doubleAfterSplit { parts.append("DAS") }
        if context.rules.surrenderRule != .none { parts.append("Surrender") }
        guard !parts.isEmpty else { return "" }
        return "Rules: " + parts.joined(separator: " • ")
    }

    // MARK: - Naming helpers

    private func actionName(_ action: Action) -> String {
        switch action {
        case .hit: return "Hit"
        case .stand: return "Stand"
        case .double: return "Double"
        case .split: return "Split"
        case .surrender: return "Surrender"
        }
    }

    private func upCardName(_ rank: Rank) -> String {
        switch rank {
        case .ace: return "Ace"
        case .king, .queen, .jack, .ten: return "10"
        default: return String(rank.blackjackValue)
        }
    }

    private func pairRankName(_ rank: Rank?) -> String {
        guard let rank = rank else { return "card" }
        switch rank {
        case .ace: return "Ace"
        case .king: return "King"
        case .queen: return "Queen"
        case .jack: return "Jack"
        default: return String(rank.blackjackValue)
        }
    }
}

#Preview {
    WhyExplanationView(context: WhyContext(
        handTotal: 16,
        handType: .hard,
        dealerUpCard: .ten,
        userAction: .hit,
        correctAction: .stand,
        rules: BlackjackRules()
    ))
}

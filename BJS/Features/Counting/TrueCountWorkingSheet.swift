import SwiftUI
import BJSCore

/// The TC WHY sheet: the working and the convention's rule.
struct TrueCountWorkingSheet: View {
    let question: TrueCountQuestion
    let convention: TrueCountConvention
    let deckCount: Int
    let answered: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            FeltBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.l) {
                    HStack {
                        Text("The working").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                        Spacer()
                        CloseButton(identifier: "counting.sheet.close") { dismiss() }
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s),
                                        GridItem(.flexible(), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
                        StatChip(label: "Running count", value: TrainingText.signed(question.runningCount))
                        StatChip(label: "Decks left", value: CountingText.decks(question.decksRemaining))
                        StatChip(label: "RC ÷ decks", value: TrainingText.signed(question.exactTrueCount))
                        StatChip(label: "Answer", value: TrainingText.signed(question.keypadAnswer(for: convention)))
                        StatChip(label: "You said", value: TrainingText.signed(answered))
                    }
                    Text(TrainingText.conventionRule(convention))
                        .feltText(.body).foregroundStyle(FeltColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("The tray shows the decks already played out of a \(deckCount)-deck shoe. "
                         + "Decks left is the shoe minus the tray.")
                        .feltText(.body).foregroundStyle(FeltColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(FeltSpacing.l)
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("counting.working")
    }
}

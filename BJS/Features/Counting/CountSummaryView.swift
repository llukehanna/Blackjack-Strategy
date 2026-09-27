import SwiftUI

struct CountSummaryView: View {
    let summary: CountSummaryModel
    let saveFailed: Bool
    let onAgain: () -> Void
    let onDone: () -> Void

    @State private var showsSaveAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                Text(summary.title).feltText(.display).foregroundStyle(FeltColor.textPrimary)
                    .accessibilityIdentifier("counting.summary")
                LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s),
                                    GridItem(.flexible(), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
                    StatChip(label: "Accuracy", value: PercentText.text(summary.score.accuracy))
                    StatChip(label: "Correct", value: "\(summary.score.correct) / \(summary.score.checks)")
                    StatChip(label: "Mean error", value: CountingText.meanError(summary.score.meanAbsoluteError))
                    if let secondsPerCard = summary.secondsPerCard {
                        StatChip(label: "Per card", value: CountingText.seconds(secondsPerCard))
                    }
                }
                if !summary.rows.isEmpty {
                    SettingsSection(title: summary.rowsTitle) {
                        ForEach(summary.rows) { row in
                            SettingsRow(label: row.label) { Text(row.value) }
                        }
                    }
                }
                PrimaryButton(title: "Again", action: onAgain)
                SecondaryButton(title: "Done", action: onDone)
            }
            .padding(FeltSpacing.l)
        }
        .onAppear { showsSaveAlert = saveFailed }
        .alert("Couldn't save this session", isPresented: $showsSaveAlert) {
            Button("OK") {}
        } message: {
            Text("Your results are shown here but won't appear in your progress.")
        }
    }
}

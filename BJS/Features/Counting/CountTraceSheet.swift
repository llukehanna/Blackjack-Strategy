import SwiftUI
import BJSCore

/// The RC WHY sheet: every card since the previous checkpoint, its Hi-Lo value, and the count after it.
struct CountTraceSheet: View {
    let entries: [CountTraceEntry]
    let check: GradedCount
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            FeltBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.l) {
                    HStack {
                        Text("Card by card").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                        Spacer()
                        CloseButton(identifier: "counting.sheet.close") { dismiss() }
                    }
                    HStack(spacing: FeltSpacing.s) {
                        StatChip(label: "You said", value: TrainingText.signed(Int(check.answered)))
                        StatChip(label: "Running count", value: TrainingText.signed(Int(check.expected)))
                    }
                    SettingsSection(title: check.id == 0 ? "Since the start" : "Since the last check") {
                        ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                            SettingsRow(label: entry.card.spokenName) {
                                Text("\(TrainingText.signed(entry.value))  →  \(TrainingText.signed(entry.runningCount))")
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .padding(FeltSpacing.l)
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("counting.trace")
    }
}

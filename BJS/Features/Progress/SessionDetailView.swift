import os
import SwiftUI
import BJSCore

/// A read-only saved session, pushed from Progress history (Step 6 spec §3).
struct SessionDetailView: View {
    let sessionID: UUID
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var model: SessionDetailViewModel?
    @State private var loadFailed = false
    @State private var whyContext: WhyContext?

    private let logger = Logger(subsystem: "com.bjs.app", category: "SessionDetailView")

    var body: some View {
        ZStack {
            FeltBackground()
            ScrollView {
                if let model {
                    content(model)
                } else if loadFailed {
                    Text(ProgressText.loadFailed)
                        .feltText(.body)
                        .foregroundStyle(FeltColor.incorrect)
                        .padding(FeltSpacing.l)
                }
            }
        }
        .sheet(item: $whyContext) { WhySheet(context: $0) }
        .task(id: sessionStore.revision) { load() }
    }

    private func content(_ model: SessionDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xl) {
            VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                Text(model.title)
                    .feltText(.display)
                    .foregroundStyle(FeltColor.textPrimary)
                Text(model.dateText)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textSecondary)
            }
            VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                ForEach(model.captions, id: \.self) { caption in
                    Text(caption)
                        .feltText(.body)
                        .foregroundStyle(FeltColor.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s),
                                GridItem(.flexible(), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
                ForEach(model.chips) { StatChip(label: $0.label, value: $0.value) }
            }
            if !model.mistakes.isEmpty {
                SettingsSection(title: "Mistakes") {
                    ForEach(model.mistakes) { mistake in
                        Button { whyContext = mistake.why } label: {
                            SettingsRow(label: mistake.label) { Text(mistake.value) }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Explains the correct play")
                        .accessibilityIdentifier("progress.mistake")
                    }
                }
            }
            if !model.checks.isEmpty {
                SettingsSection(title: "Checks") {
                    ForEach(model.checks) { check in
                        SettingsRow(label: check.label) { Text(check.value) }
                    }
                }
            }
            if model.showsTraceFootnote {
                Text(SessionDetailViewModel.traceFootnote)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(FeltSpacing.l)
    }

    /// Pops back to the list when the session no longer exists (e.g. after a reset).
    private func load() {
        do {
            if let detail = try sessionStore.sessionDetail(id: sessionID) {
                model = SessionDetailViewModel(detail: detail)
                loadFailed = false
            } else {
                dismiss()
            }
        } catch {
            logger.error("Session detail failed to load: \(error.localizedDescription)")
            loadFailed = true
        }
    }
}

import os
import SwiftUI

/// Train tab: rules header, stat chips, Continue, module tiles.
struct HubView: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(PreferencesStore.self) private var preferences
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppRouter.self) private var router
    @State private var model = HubViewModel()
    @State private var presented: HubModule?
    @State private var showsStorageDegradedNotice = false
    @State private var hasShownStorageDegradedNotice = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let logger = Logger(subsystem: "com.bjs.app", category: "HubView")

    var body: some View {
        // At accessibility Dynamic Type sizes the three stat chips stack vertically (full width)
        // instead of side by side, so their labels have room.
        let chipsLayout: AnyLayout = FeltAdaptiveLayout.stacksVertically(dynamicTypeSize)
            ? AnyLayout(VStackLayout(spacing: FeltSpacing.s))
            : AnyLayout(HStackLayout(spacing: FeltSpacing.s))
        ZStack {
            FeltBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                    header
                    chipsLayout {
                        StatChip(label: "Strategy", value: model.strategyAccuracy)
                        StatChip(label: "Count", value: model.countAccuracy)
                        StatChip(label: "Streak", value: model.streak)
                    }
                    if preferences.lastLaunch != nil {
                        // Relaunch wiring arrives with the first module (Step 3).
                        PrimaryButton(title: "Continue") {}
                    }
                    VStack(spacing: FeltSpacing.m) {
                        ForEach(HubModule.allCases) { module in
                            ModuleTile(title: module.title, subtitle: module.subtitle) {
                                presented = module
                            }
                        }
                    }
                }
                .padding(FeltSpacing.l)
            }
        }
        .fullScreenCover(item: $presented) { module in
            ComingSoonView(title: module.title, message: "Coming in Step \(module.step)") {
                presented = nil
            }
        }
        .task(id: sessionStore.revision) { refresh() }
        .onAppear {
            if sessionStore.isStorageDegraded && !hasShownStorageDegradedNotice {
                hasShownStorageDegradedNotice = true
                showsStorageDegradedNotice = true
            }
        }
        .alert("Progress can't be saved", isPresented: $showsStorageDegradedNotice) {
            Button("OK") {}
        } message: {
            Text("Your progress couldn't be saved right now. Training still works, but sessions from this launch won't be kept.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Button {
                router.selectedTab = .settings
            } label: {
                HStack(spacing: FeltSpacing.xs) {
                    Text(RulesSummary.text(for: rulesStore.rules))
                        .feltText(.body)
                        .foregroundStyle(FeltColor.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FeltColor.textTertiary)
                }
                .frame(minHeight: FeltTapTarget.minimum)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("hub.rulesSummary")
            .accessibilityLabel("Table rules")
            .accessibilityValue(RulesSummary.text(for: rulesStore.rules))
            .accessibilityHint("Opens Settings")
            Text("Train")
                .feltText(.display)
                .foregroundStyle(FeltColor.textPrimary)
        }
    }

    private func refresh() {
        do {
            model.update(sessions: try sessionStore.sessionSamples(),
                         decisions: try sessionStore.decisionSamples(modules: HubViewModel.strategyModules),
                         now: .now)
        } catch {
            logger.error("Hub stats failed to load: \(error.localizedDescription)")
            model.update(sessions: [], decisions: [], now: .now)
        }
    }
}

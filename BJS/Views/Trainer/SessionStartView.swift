import SwiftUI
import BJSCore

struct SessionStartView: View {
    @Environment(RulesViewModel.self) private var rulesVM
    @State private var selectedMode: TrainingMode = .test
    @State private var isSessionActive = false
    @State private var showRuleConfig = false

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable config content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: Spacing.lg)

                    // MODE section
                    sectionLabel("MODE")
                    Spacer().frame(height: Spacing.xs)
                    TrainingModeToggle(selection: $selectedMode)

                    Spacer().frame(height: Spacing.lg)

                    // RULES section
                    sectionLabel("RULES")
                    Spacer().frame(height: Spacing.xs)
                    rulesRow
                }
            }

            // Pinned CTA — outside ScrollView, always visible
            Divider()
            ctaButton
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .padding(.bottom, 0)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 0)
        }
        .background(BJSColors.surfaceBase)
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isSessionActive) {
            TrainerView(mode: selectedMode, rules: rulesVM.rules)
        }
        .sheet(isPresented: $showRuleConfig) {
            RuleConfigView()
        }
        .onChange(of: showRuleConfig) { _, _ in
            // No action needed — rulesVM updates itself
        }
    }

    // MARK: - Components

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Typography.caption)
            .foregroundStyle(BJSColors.textSecondary)
            .tracking(1.2)
            .padding(.horizontal, Spacing.md)
    }

    private var rulesRow: some View {
        Button {
            showRuleConfig = true
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(rulesVM.selectedPreset.rawValue)
                        .font(Typography.body)
                        .foregroundStyle(BJSColors.textPrimary)
                    Text(rulesVM.rulesSummary)
                        .font(Typography.caption)
                        .foregroundStyle(BJSColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Typography.caption)
                    .foregroundStyle(BJSColors.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(BJSColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.md)
    }

    private var ctaButton: some View {
        Button {
            isSessionActive = true
        } label: {
            Text("Start Session")
                .font(Typography.body)
                .foregroundStyle(BJSColors.textOnOverlay)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(BJSColors.accentGold)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
        }
        .buttonStyle(.plain)
    }
}

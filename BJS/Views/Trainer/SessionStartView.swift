import SwiftUI
import BJSCore

struct SessionStartView: View {
    @Environment(RulesViewModel.self) private var rulesVM
    @State private var selectedMode: TrainingMode = .test
    @State private var isSessionActive = false
    @State private var showRuleConfig = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Mode picker
                SectionContainerView {
                    Text("Mode")
                        .font(Typography.section)
                        .foregroundStyle(.secondary)

                    Picker("Training Mode", selection: $selectedMode) {
                        Text("Learn").tag(TrainingMode.learn)
                        Text("Test").tag(TrainingMode.test)
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                // Casino Preset picker
                SectionContainerView {
                    Text("Casino Preset")
                        .font(Typography.section)
                        .foregroundStyle(.secondary)

                    @Bindable var vm = rulesVM
                    Picker("Preset", selection: $vm.selectedPreset) {
                        ForEach(CasinoPreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: rulesVM.selectedPreset) { _, newValue in
                        rulesVM.selectPreset(newValue)
                    }
                }

                Divider()

                // Rules summary
                SectionContainerView {
                    Text("Rules")
                        .font(Typography.section)
                        .foregroundStyle(.secondary)

                    Text(rulesVM.rulesSummary)
                        .font(Typography.secondary)
                        .foregroundStyle(.secondary)

                    Button("Edit Rules") {
                        showRuleConfig = true
                    }
                }

                Divider()

                // Start Session CTA
                Button("Start Session") {
                    isSessionActive = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Practice")
        .navigationDestination(isPresented: $isSessionActive) {
            TrainerView(mode: selectedMode, rules: rulesVM.rules)
        }
        .sheet(isPresented: $showRuleConfig) {
            RuleConfigView()
        }
    }
}

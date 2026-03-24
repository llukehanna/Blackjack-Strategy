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
                // Header
                VStack(spacing: 8) {
                    Text("Ready to Practice")
                        .font(.title2.bold())
                    Text("Choose your rules and mode, then start a session to begin training.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 24)

                Divider()

                // Mode picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mode")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    Picker("Training Mode", selection: $selectedMode) {
                        Text("Learn").tag(TrainingMode.learn)
                        Text("Test").tag(TrainingMode.test)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)

                Divider()

                // Casino Preset picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Casino Preset")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    @Bindable var vm = rulesVM
                    Picker("Preset", selection: $vm.selectedPreset) {
                        ForEach(CasinoPreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .onChange(of: rulesVM.selectedPreset) { _, newValue in
                        rulesVM.selectPreset(newValue)
                    }
                }
                .padding(.vertical, 16)

                Divider()

                // Rules summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rules")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    Text(rulesVM.rulesSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    Button("Edit Rules") {
                        showRuleConfig = true
                    }
                    .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)

                Divider()

                // Start Session CTA
                Button("Start Session") {
                    isSessionActive = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
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

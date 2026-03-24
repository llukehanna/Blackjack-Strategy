import SwiftUI
import BJSCore

struct SessionStartView: View {
    @Environment(RulesViewModel.self) private var rulesVM
    @State private var selectedMode: TrainingMode = .test
    @State private var isSessionActive = false
    @State private var showRuleConfig = false

    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Text("Ready to Practice")
                        .font(.title2.bold())
                    Text("Choose your rules and mode, then start a session to begin training.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Mode") {
                Picker("Training Mode", selection: $selectedMode) {
                    Text("Learn").tag(TrainingMode.learn)
                    Text("Test").tag(TrainingMode.test)
                }
                .pickerStyle(.segmented)
            }

            Section("Casino Preset") {
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

            Section("Rules") {
                Text(rulesVM.rulesSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Edit Rules") {
                    showRuleConfig = true
                }
            }

            Section {
                Button("Start Session") {
                    isSessionActive = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Practice")
        .navigationDestination(isPresented: $isSessionActive) {
            TrainerView(mode: selectedMode, rules: rulesVM.rules)
        }
        .sheet(isPresented: $showRuleConfig) {
            RuleConfigView()
        }
    }
}

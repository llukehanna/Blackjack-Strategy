import SwiftUI
import BJSCore

struct RuleConfigView: View {
    @Environment(RulesViewModel.self) private var rulesVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var vm = rulesVM

        NavigationStack {
            Form {
                Section("Deck Count") {
                    Picker("Decks", selection: $vm.rules.deckCount) {
                        ForEach(BlackjackRules.DeckCount.allCases, id: \.self) { count in
                            Text("\(count.rawValue)").tag(count)
                        }
                    }
                }

                Section("Dealer Rules") {
                    Picker("Dealer Soft 17", selection: $vm.rules.dealerSoft17) {
                        Text("Stands (S17)").tag(BlackjackRules.DealerSoft17.stands)
                        Text("Hits (H17)").tag(BlackjackRules.DealerSoft17.hits)
                    }
                }

                Section("Blackjack Payout") {
                    Picker("Payout", selection: $vm.rules.blackjackPayout) {
                        Text("3:2").tag(BlackjackRules.BlackjackPayout.threeToTwo)
                        Text("6:5").tag(BlackjackRules.BlackjackPayout.sixToFive)
                        Text("2:1").tag(BlackjackRules.BlackjackPayout.twoToOne)
                    }
                }

                Section("Player Options") {
                    Toggle("Double After Split (DAS)", isOn: $vm.rules.doubleAfterSplit)
                    Toggle("Resplit Aces (RSA)", isOn: $vm.rules.resplitAces)
                    Toggle("Hit Split Aces", isOn: $vm.rules.hitSplitAces)
                    Stepper("Max Split Hands: \(vm.rules.maxSplitHands)",
                            value: $vm.rules.maxSplitHands, in: 2...4)
                }

                Section("Surrender") {
                    Picker("Surrender Rule", selection: $vm.rules.surrenderRule) {
                        Text("None").tag(BlackjackRules.SurrenderRule.none)
                        Text("Late").tag(BlackjackRules.SurrenderRule.late)
                        Text("Early").tag(BlackjackRules.SurrenderRule.early)
                    }
                }

                Section("Double Restrictions") {
                    Picker("Double Down On", selection: $vm.rules.doubleRestriction) {
                        Text("Any Two Cards").tag(BlackjackRules.DoubleRestriction.anyTwo)
                        Text("9-11 Only").tag(BlackjackRules.DoubleRestriction.nineToEleven)
                        Text("10-11 Only").tag(BlackjackRules.DoubleRestriction.tenToEleven)
                    }
                }

                Section("Peek Rule") {
                    Picker("Dealer Peek", selection: $vm.rules.peekRule) {
                        Text("American Peek").tag(BlackjackRules.PeekRule.americanPeek)
                        Text("No Peek (European)").tag(BlackjackRules.PeekRule.europeanNoPeek)
                    }
                }
            }
            .navigationTitle("Rule Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: vm.rules) {
                vm.rulesDidChange()
            }
        }
    }
}

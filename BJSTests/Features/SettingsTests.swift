import Foundation
import SwiftData
import Testing
import BJSCore
@testable import BJS

@MainActor
struct SettingsTests {

    @Test("Preference labels")
    func preferenceLabels() {
        #expect(PreferenceLabels.speedTimer(3) == "3.0 s")
        #expect(PreferenceLabels.speedTimer(1.5) == "1.5 s")
        #expect(PreferenceLabels.shoeCheck(4) == "Every 4 rounds")
    }

    @Test("Surrender footnote appears only under no hole card")
    func surrenderFootnote() {
        var r = BlackjackRules()
        #expect(RulesForm.surrenderFootnote(for: r) == nil)
        r.peekRule = .europeanNoPeek
        #expect(RulesForm.surrenderFootnote(for: r) == "With no hole card, late and early surrender play the same.")
    }

    @Test("Max split hands stepper range is 2…4")
    func splitRange() {
        #expect(ActiveRulesStore.maxSplitHandsRange == 2...4)
    }

    @Test("Reset deletes sessions and leaves rules and preferences alone")
    func reset() throws {
        let container = try BJSModelContainer.make(inMemory: true)
        let sessions = SessionStore(context: container.mainContext)
        let defaults = makeTestDefaults()
        let rules = ActiveRulesStore(defaults: defaults)
        let prefs = PreferencesStore(defaults: defaults)
        rules.rules = RulePreset.atlanticCity.rules
        prefs.speedTimerSeconds = 2
        try sessions.save(SessionDraft(module: .strategy, mode: nil, startedAt: .now, endedAt: .now,
                                       rules: rules.rules))

        let model = SettingsViewModel()
        model.resetProgress(using: sessions)

        #expect(try sessions.sessionSamples().isEmpty)
        #expect(!model.showsResetError)
        #expect(ActiveRulesStore(defaults: defaults).rules == RulePreset.atlanticCity.rules)
        #expect(PreferencesStore(defaults: defaults).speedTimerSeconds == 2)
    }
}

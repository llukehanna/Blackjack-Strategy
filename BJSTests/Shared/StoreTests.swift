import Foundation
import Testing
import BJSCore
@testable import BJS

func makeTestDefaults() -> UserDefaults {
    let name = "BJSTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

@MainActor
struct ActiveRulesStoreTests {

    @Test("Defaults to BlackjackRules() when nothing is stored")
    func defaults() {
        #expect(ActiveRulesStore(defaults: makeTestDefaults()).rules == BlackjackRules())
    }

    @Test("Rules persist as JSON and reload")
    func roundTrip() throws {
        let d = makeTestDefaults()
        let store = ActiveRulesStore(defaults: d)
        store.rules = RulePreset.downtownVegas.rules
        #expect(d.data(forKey: ActiveRulesStore.key) != nil)
        #expect(ActiveRulesStore(defaults: d).rules == RulePreset.downtownVegas.rules)
    }

    @Test("Corrupt JSON falls back to defaults")
    func corrupt() {
        let d = makeTestDefaults()
        d.set(Data("not json".utf8), forKey: ActiveRulesStore.key)
        #expect(ActiveRulesStore(defaults: d).rules == BlackjackRules())
    }

    @Test("maxSplitHands is clamped to 2…4 on set and on load")
    func clampSplitHands() throws {
        let d = makeTestDefaults()
        let store = ActiveRulesStore(defaults: d)
        var r = BlackjackRules()
        r.maxSplitHands = 1
        store.rules = r
        #expect(store.rules.maxSplitHands == 2)
        r.maxSplitHands = 9
        store.rules = r
        #expect(store.rules.maxSplitHands == 4)
        #expect(ActiveRulesStore(defaults: d).rules.maxSplitHands == 4)

        var stored = BlackjackRules()
        stored.maxSplitHands = 1
        d.set(try JSONEncoder().encode(stored), forKey: ActiveRulesStore.key)
        #expect(ActiveRulesStore(defaults: d).rules.maxSplitHands == 2)
    }
}

@MainActor
struct PreferencesStoreTests {

    @Test("Defaults: 3.0 s, Exact, every 4 rounds, haptics on, no last launch")
    func defaults() {
        let p = PreferencesStore(defaults: makeTestDefaults())
        #expect(p.speedTimerSeconds == 3.0)
        #expect(p.trueCountConvention == .exact)
        #expect(p.shoeCheckFrequency == 4)
        #expect(p.hapticsEnabled)
        #expect(p.lastLaunch == nil)
    }

    @Test("Values persist and reload")
    func roundTrip() {
        let d = makeTestDefaults()
        let p = PreferencesStore(defaults: d)
        p.speedTimerSeconds = 2.5
        p.trueCountConvention = .floor
        p.shoeCheckFrequency = 6
        p.hapticsEnabled = false
        p.lastLaunch = LastLaunch(module: .strategy, mode: "learn", setup: Data([1, 2, 3]))
        let reloaded = PreferencesStore(defaults: d)
        #expect(reloaded.speedTimerSeconds == 2.5)
        #expect(reloaded.trueCountConvention == .floor)
        #expect(reloaded.shoeCheckFrequency == 6)
        #expect(!reloaded.hapticsEnabled)
        #expect(reloaded.lastLaunch == LastLaunch(module: .strategy, mode: "learn", setup: Data([1, 2, 3])))
    }

    @Test("Speed timer clamps to 1.0…5.0 and snaps to 0.5 s steps")
    func speedClamp() {
        let p = PreferencesStore(defaults: makeTestDefaults())
        p.speedTimerSeconds = 0.2
        #expect(p.speedTimerSeconds == 1.0)
        p.speedTimerSeconds = 7
        #expect(p.speedTimerSeconds == 5.0)
        p.speedTimerSeconds = 2.3
        #expect(p.speedTimerSeconds == 2.5)
    }

    @Test("Shoe check frequency clamps to 2…8, also on load")
    func shoeClamp() {
        let d = makeTestDefaults()
        let p = PreferencesStore(defaults: d)
        p.shoeCheckFrequency = 1
        #expect(p.shoeCheckFrequency == 2)
        p.shoeCheckFrequency = 12
        #expect(p.shoeCheckFrequency == 8)
        d.set(0, forKey: PreferencesStore.Key.shoeCheckFrequency)
        #expect(PreferencesStore(defaults: d).shoeCheckFrequency == 2)
    }

    @Test("Clearing lastLaunch removes it")
    func clearLastLaunch() {
        let d = makeTestDefaults()
        let p = PreferencesStore(defaults: d)
        p.lastLaunch = LastLaunch(module: .countingRC, mode: nil, setup: Data())
        p.lastLaunch = nil
        #expect(PreferencesStore(defaults: d).lastLaunch == nil)
    }

    @Test("An unknown stored convention falls back to Exact")
    func unknownConvention() {
        let d = makeTestDefaults()
        d.set("sideways", forKey: PreferencesStore.Key.trueCountConvention)
        #expect(PreferencesStore(defaults: d).trueCountConvention == .exact)
    }
}

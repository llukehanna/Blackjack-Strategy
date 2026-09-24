import BJSCore
import Foundation
import Testing
@testable import BJS

@MainActor
@Suite("Preferences")
struct PreferencesTests {

    @Test("Defaults: 3.0 s timer, Exact, check every 4 rounds, haptics on")
    func defaults() {
        let prefs = Preferences(defaults: TestDefaults.make())
        #expect(prefs.speedTimerSeconds == 3.0)
        #expect(prefs.trueCountConvention == .exact)
        #expect(prefs.shoeCheckEveryRounds == 4)
        #expect(prefs.hapticsEnabled)
    }

    @Test("Changes persist under the spec's @AppStorage keys")
    func persists() {
        let defaults = TestDefaults.make()
        let prefs = Preferences(defaults: defaults)
        prefs.speedTimerSeconds = 2.5
        prefs.trueCountConvention = .floor
        prefs.shoeCheckEveryRounds = 6
        prefs.hapticsEnabled = false

        #expect(defaults.double(forKey: "speedTimerSeconds") == 2.5)
        #expect(defaults.string(forKey: "trueCountConvention") == "floor")
        #expect(defaults.integer(forKey: "shoeCheckFrequency") == 6)
        #expect(defaults.bool(forKey: "hapticsEnabled") == false)

        let reloaded = Preferences(defaults: defaults)
        #expect(reloaded.speedTimerSeconds == 2.5)
        #expect(reloaded.trueCountConvention == .floor)
        #expect(reloaded.shoeCheckEveryRounds == 6)
        #expect(!reloaded.hapticsEnabled)
    }

    @Test("Speed timer is clamped to 1–5 s")
    func clamp() {
        let prefs = Preferences(defaults: TestDefaults.make())
        prefs.speedTimerSeconds = 0.2
        #expect(prefs.speedTimerSeconds == 1)
        prefs.speedTimerSeconds = 9
        #expect(prefs.speedTimerSeconds == 5)
    }

    @Test("Invalid stored values fall back to defaults")
    func invalidStored() {
        let defaults = TestDefaults.make()
        defaults.set("banana", forKey: "trueCountConvention")
        defaults.set(0, forKey: "shoeCheckFrequency")
        defaults.set(42.0, forKey: "speedTimerSeconds")
        let prefs = Preferences(defaults: defaults)
        #expect(prefs.trueCountConvention == .exact)
        #expect(prefs.shoeCheckEveryRounds == 4)
        #expect(prefs.speedTimerSeconds == 5)
    }

    @Test("Picker options stay inside their ranges")
    func options() {
        #expect(Preferences.speedTimerOptions.first == 1.0)
        #expect(Preferences.speedTimerOptions.last == 5.0)
        #expect(Preferences.speedTimerOptions.contains(Preferences.defaultSpeedTimerSeconds))
        #expect(Preferences.shoeCheckOptions.allSatisfy { Preferences.shoeCheckRange.contains($0) })
        #expect(Preferences.shoeCheckOptions.contains(Preferences.defaultShoeCheckEveryRounds))
    }
}

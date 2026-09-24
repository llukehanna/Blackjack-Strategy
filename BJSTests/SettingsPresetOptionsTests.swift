import BJSCore
import Testing
@testable import BJS

@Suite("SettingsPresetOptions")
struct SettingsPresetOptionsTests {

    @Test("Custom is appended only when the rules match no preset")
    func customOnlyWhenUnmatched() {
        #expect(SettingsPresetOptions.options(matching: .vegasStrip) == RulePreset.allCases.map { Optional($0) })
        #expect(SettingsPresetOptions.options(matching: nil) == RulePreset.allCases.map { Optional($0) } + [nil])
    }
}

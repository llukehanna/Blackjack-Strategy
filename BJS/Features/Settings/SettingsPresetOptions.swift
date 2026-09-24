import BJSCore

/// The preset picker's options (spec §5 Settings): every named preset, plus "Custom" (`nil`)
/// only while the active rules match none of them. Pulled out of `SettingsView` so the
/// "which options does the picker show" question has one pure, tested answer.
enum SettingsPresetOptions {
    static func options(matching preset: RulePreset?) -> [RulePreset?] {
        let presets: [RulePreset?] = RulePreset.allCases.map { Optional($0) }
        return preset == nil ? presets + [nil] : presets
    }
}

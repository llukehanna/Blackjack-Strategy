import SwiftUI

/// Hairline between rows: `textTertiary` at 30%, one physical pixel.
private let settingsHairline = FeltColor.textTertiary.opacity(0.3)

/// A settings line: title on the left, a value / toggle / picker on the right,
/// hairline separator below (spec §4). At least 44 pt tall.
struct SettingsRow<Accessory: View>: View {
    private let title: String
    private let showsSeparator: Bool
    /// True when the accessory is a control that already carries `title` as its
    /// accessibility label (toggle, picker), so VoiceOver does not read it twice.
    private let accessoryCarriesTitle: Bool
    private let accessory: Accessory

    @Environment(\.displayScale) private var displayScale

    /// A row with a custom accessory.
    init(_ title: String, showsSeparator: Bool = true, @ViewBuilder accessory: () -> Accessory) {
        self.init(title: title, showsSeparator: showsSeparator, accessoryCarriesTitle: false, accessory: accessory())
    }

    fileprivate init(title: String, showsSeparator: Bool, accessoryCarriesTitle: Bool, accessory: Accessory) {
        self.title = title
        self.showsSeparator = showsSeparator
        self.accessoryCarriesTitle = accessoryCarriesTitle
        self.accessory = accessory
    }

    var body: some View {
        HStack(spacing: FeltSpacing.m) {
            Text(title)
                .feltType(.body)
                .foregroundStyle(FeltColor.textPrimary)
                .accessibilityHidden(accessoryCarriesTitle)
            Spacer(minLength: FeltSpacing.s)
            accessory
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.vertical, FeltSpacing.xs)
        .frame(minHeight: FeltMetrics.minTapTarget)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle()
                    .fill(settingsHairline)
                    .frame(height: 1 / displayScale)
                    .padding(.leading, FeltSpacing.l)
            }
        }
        .accessibilityElement(children: accessoryCarriesTitle ? .contain : .combine)
    }
}

/// Read-only value text for a `SettingsRow`.
struct SettingsValueText: View {
    let value: String

    var body: some View {
        Text(value)
            .feltType(.body)
            .foregroundStyle(FeltColor.textSecondary)
    }
}

/// Toggle accessory for a `SettingsRow`. On-state tint is cream, like a selected ModePicker segment.
struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .labelsHidden()
            .tint(FeltColor.cream)
    }
}

/// Menu picker accessory for a `SettingsRow`.
struct SettingsPicker<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let optionTitle: (Value) -> String

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(optionTitle(option)).tag(option)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .tint(FeltColor.textSecondary)
    }
}

extension SettingsRow where Accessory == SettingsValueText {
    init(_ title: String, value: String, showsSeparator: Bool = true) {
        self.init(title: title, showsSeparator: showsSeparator, accessoryCarriesTitle: false,
                  accessory: SettingsValueText(value: value))
    }
}

extension SettingsRow where Accessory == SettingsToggle {
    init(_ title: String, isOn: Binding<Bool>, showsSeparator: Bool = true) {
        self.init(title: title, showsSeparator: showsSeparator, accessoryCarriesTitle: true,
                  accessory: SettingsToggle(title: title, isOn: isOn))
    }
}

extension SettingsRow {
    init<Value: Hashable>(_ title: String, selection: Binding<Value>, options: [Value],
                          showsSeparator: Bool = true,
                          optionTitle: @escaping (Value) -> String) where Accessory == SettingsPicker<Value> {
        self.init(title: title, showsSeparator: showsSeparator, accessoryCarriesTitle: true,
                  accessory: SettingsPicker(title: title, selection: selection, options: options,
                                            optionTitle: optionTitle))
    }
}

/// A titled group of `SettingsRow`s on one `surfaceInset` panel.
struct SettingsSection<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text(title)
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
                .padding(.horizontal, FeltSpacing.l)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                content
            }
            .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.tile, style: .continuous))
        }
    }
}

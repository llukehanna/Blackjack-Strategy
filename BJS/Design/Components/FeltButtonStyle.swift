import SwiftUI

/// The four Felt button treatments.
enum FeltButtonKind: Sendable {
    /// Cream fill, `onCream` text. `PrimaryButton`, ActionDock row 1.
    case primary
    /// `surfaceInset` fill with a hairline outline. `SecondaryButton`, ActionDock row 2, keypad keys.
    case secondary
    /// Used on cream surfaces (FeedbackCard NEXT): `onCream` fill, cream text.
    case onCreamPrimary
    /// Used on cream surfaces (FeedbackCard WHY): `onCream` outline and text.
    case onCreamSecondary
}

/// Full-width, ≥ 44 pt Felt button. Disabled buttons dim to 40%.
struct FeltButtonStyle: ButtonStyle {
    let kind: FeltButtonKind

    func makeBody(configuration: Configuration) -> some View {
        FeltButtonBody(configuration: configuration, kind: kind)
    }
}

extension ButtonStyle where Self == FeltButtonStyle {
    static var feltPrimary: FeltButtonStyle { FeltButtonStyle(kind: .primary) }
    static var feltSecondary: FeltButtonStyle { FeltButtonStyle(kind: .secondary) }
    static var feltOnCreamPrimary: FeltButtonStyle { FeltButtonStyle(kind: .onCreamPrimary) }
    static var feltOnCreamSecondary: FeltButtonStyle { FeltButtonStyle(kind: .onCreamSecondary) }
}

private struct FeltButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let kind: FeltButtonKind

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: FeltRadius.button, style: .continuous)
    }

    private var fill: Color {
        switch kind {
        case .primary: return FeltColor.cream
        case .secondary: return FeltColor.surfaceInset
        case .onCreamPrimary: return FeltColor.onCream
        case .onCreamSecondary: return Color.clear
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary, .onCreamSecondary: return FeltColor.onCream
        case .secondary: return FeltColor.textPrimary
        case .onCreamPrimary: return FeltColor.cream
        }
    }

    private var outline: Color? {
        switch kind {
        case .secondary: return FeltColor.textTertiary
        case .onCreamSecondary: return FeltColor.onCream
        case .primary, .onCreamPrimary: return nil
        }
    }

    var body: some View {
        configuration.label
            .feltType(.body)
            .fontWeight(.semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(foreground)
            .padding(.horizontal, FeltSpacing.m)
            .padding(.vertical, FeltSpacing.s)
            .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget)
            .background(fill, in: shape)
            .overlay {
                if let outline {
                    shape.strokeBorder(outline, lineWidth: 1)
                }
            }
            .contentShape(shape)
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(FeltMotion.ui, value: configuration.isPressed)
    }
}

/// Press feedback without chrome, for custom tappable surfaces such as `ModuleTile`.
struct FeltPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FeltPressableBody(configuration: configuration)
    }
}

private struct FeltPressableBody: View {
    let configuration: ButtonStyleConfiguration

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(FeltMotion.ui, value: configuration.isPressed)
    }
}

/// Cream-filled call to action.
struct PrimaryButton: View {
    private let title: String
    private let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.feltPrimary)
    }
}

/// Outlined button on `surfaceInset`.
struct SecondaryButton: View {
    private let title: String
    private let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.feltSecondary)
    }
}

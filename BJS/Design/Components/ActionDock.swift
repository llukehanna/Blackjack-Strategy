import BJSCore
import SwiftUI

/// How one dock button is drawn.
enum DockButtonState: Equatable, Sendable {
    case enabled
    /// Not allowed by the rules in this spot: disabled and dimmed.
    case dimmed
    /// Learn mode: the correct action carries the brass ring.
    case hint
}

/// The player's action buttons (spec §4).
/// Row 1: STAND, HIT (cream). Row 2: SPLIT, DOUBLE, SURRENDER (inset).
struct ActionDock: View {
    static let primaryRow: [Action] = [.stand, .hit]
    static let secondaryRow: [Action] = [.split, .double, .surrender]

    private let allowed: Set<Action>
    private let hint: Action?
    private let onAction: (Action) -> Void

    init(allowed: Set<Action>, hint: Action? = nil, onAction: @escaping (Action) -> Void) {
        self.allowed = allowed
        self.hint = hint
        self.onAction = onAction
    }

    static func state(for action: Action, allowed: Set<Action>, hint: Action?) -> DockButtonState {
        guard allowed.contains(action) else { return .dimmed }
        return action == hint ? .hint : .enabled
    }

    /// Button caption, e.g. "STAND".
    static func title(for action: Action) -> String {
        action.rawValue.uppercased()
    }

    /// VoiceOver name, e.g. "Stand".
    static func spokenName(for action: Action) -> String {
        action.rawValue.capitalized
    }

    var body: some View {
        VStack(spacing: FeltSpacing.s) {
            HStack(spacing: FeltSpacing.s) {
                ForEach(Self.primaryRow, id: \.self) { action in
                    button(for: action, kind: .primary)
                }
            }
            HStack(spacing: FeltSpacing.s) {
                ForEach(Self.secondaryRow, id: \.self) { action in
                    button(for: action, kind: .secondary)
                }
            }
        }
    }

    private func button(for action: Action, kind: FeltButtonKind) -> some View {
        let state = Self.state(for: action, allowed: allowed, hint: hint)
        return Button {
            onAction(action)
        } label: {
            Text(Self.title(for: action))
        }
        .buttonStyle(FeltButtonStyle(kind: kind))
        .overlay {
            if state == .hint {
                RoundedRectangle(cornerRadius: FeltRadius.button, style: .continuous)
                    .strokeBorder(FeltColor.brass, lineWidth: 3)
                    .allowsHitTesting(false)
            }
        }
        .disabled(state == .dimmed)
        .accessibilityLabel(Self.spokenName(for: action))
        .accessibilityValue(state == .hint ? "Suggested" : "")
        .accessibilityIdentifier("action.\(action.rawValue)")
    }
}

import SwiftUI
import BJSCore

enum ActionButtonState: Equatable {
    case enabled
    /// Not allowed by the rules for this hand.
    case dimmed
    /// Learn mode: the correct play carries a brass ring.
    case hint
}

enum ActionDockLayout {
    static let topRow: [Action] = [.stand, .hit]
    static let bottomRow: [Action] = [.split, .double, .surrender]
    static let topRowHeight: CGFloat = 56
    static let bottomRowHeight: CGFloat = 48

    static func state(for action: Action, legal: Set<Action>, hint: Action?) -> ActionButtonState {
        guard legal.contains(action) else { return .dimmed }
        return action == hint ? .hint : .enabled
    }

    static func title(for action: Action) -> String { action.rawValue.uppercased() }
}

/// Row 1: STAND, HIT (cream). Row 2: SPLIT, DOUBLE, SURRENDER (inset).
struct ActionDock: View {
    let legal: Set<Action>
    var hint: Action? = nil
    let onAction: (Action) -> Void

    var body: some View {
        VStack(spacing: FeltSpacing.s) {
            HStack(spacing: FeltSpacing.s) {
                ForEach(ActionDockLayout.topRow, id: \.self) { button($0, prominent: true) }
            }
            HStack(spacing: FeltSpacing.s) {
                ForEach(ActionDockLayout.bottomRow, id: \.self) { button($0, prominent: false) }
            }
        }
    }

    private func button(_ action: Action, prominent: Bool) -> some View {
        let state = ActionDockLayout.state(for: action, legal: legal, hint: hint)
        let shape = RoundedRectangle(cornerRadius: FeltRadius.button)
        return Button { onAction(action) } label: {
            Text(ActionDockLayout.title(for: action))
                .font(prominent ? FeltType.title.font : FeltType.body.font.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(prominent ? FeltColor.onCream : FeltColor.textPrimary)
                .frame(maxWidth: .infinity,
                       minHeight: prominent ? ActionDockLayout.topRowHeight : ActionDockLayout.bottomRowHeight)
                .background(prominent ? FeltColor.cream : FeltColor.surfaceInset, in: shape)
                .overlay {
                    if state == .hint {
                        shape.strokeBorder(FeltColor.brass, lineWidth: 3)
                    }
                }
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(state == .dimmed)
        .opacity(state == .dimmed ? 0.35 : 1)
        .accessibilityHint(state == .hint ? "Suggested play" : "")
    }
}

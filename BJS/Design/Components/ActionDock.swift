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
///
/// At accessibility Dynamic Type sizes each row's buttons stack vertically (full width) instead of
/// side by side, so no title truncates. `AnyLayout` keeps the buttons' view identity stable across
/// that switch.
struct ActionDock: View {
    let legal: Set<Action>
    var hint: Action? = nil
    let onAction: (Action) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let stacksVertically = FeltAdaptiveLayout.stacksVertically(dynamicTypeSize)
        let rowLayout: AnyLayout = stacksVertically
            ? AnyLayout(VStackLayout(spacing: FeltSpacing.s))
            : AnyLayout(HStackLayout(spacing: FeltSpacing.s))
        VStack(spacing: FeltSpacing.s) {
            rowLayout {
                ForEach(ActionDockLayout.topRow, id: \.self) { button($0, prominent: true, stacksVertically: stacksVertically) }
            }
            rowLayout {
                ForEach(ActionDockLayout.bottomRow, id: \.self) { button($0, prominent: false, stacksVertically: stacksVertically) }
            }
        }
    }

    private func button(_ action: Action, prominent: Bool, stacksVertically: Bool) -> some View {
        let state = ActionDockLayout.state(for: action, legal: legal, hint: hint)
        let shape = RoundedRectangle(cornerRadius: FeltRadius.button)
        return Button { onAction(action) } label: {
            Text(ActionDockLayout.title(for: action))
                .font(prominent ? FeltType.title.font : FeltType.body.font.weight(.semibold))
                .lineLimit(stacksVertically ? nil : 1)
                .minimumScaleFactor(stacksVertically ? 1 : 0.7)
                .multilineTextAlignment(.center)
                .foregroundStyle(prominent ? FeltColor.onCream : FeltColor.textPrimary)
                .frame(maxWidth: .infinity,
                       minHeight: prominent ? ActionDockLayout.topRowHeight : ActionDockLayout.bottomRowHeight)
                .padding(.vertical, stacksVertically ? FeltSpacing.xs : 0)
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

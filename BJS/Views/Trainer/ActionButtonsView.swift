import SwiftUI
import BJSCore

/// Two-row 88pt action dock per UI-SPEC 07 action button contract.
/// Row 1 is always STAND + HIT. Row 2 renders SPLIT / DOUBLE / SURREN. only for legal actions.
/// The secondary row is omitted entirely when no secondary action is legal.
struct ActionButtonsView: View {
    let canSplit: Bool
    let canDouble: Bool
    let canSurrender: Bool
    let isEnabled: Bool
    let onStand: () -> Void
    let onHit: () -> Void
    let onSplit: () -> Void
    let onDouble: () -> Void
    let onSurrender: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ActionCell(icon: "hand.raised", label: "STAND", action: onStand)
                verticalDivider
                ActionCell(icon: "plus", label: "HIT", action: onHit)
            }
            if secondaryRowVisible {
                horizontalDivider
                HStack(spacing: 0) {
                    if canSplit {
                        ActionCell(icon: "arrow.left.and.right", label: "SPLIT", action: onSplit)
                    }
                    if canSplit && (canDouble || canSurrender) {
                        verticalDivider
                    }
                    if canDouble {
                        ActionCell(icon: "multiply.square", label: "DOUBLE", action: onDouble)
                    }
                    if canDouble && canSurrender {
                        verticalDivider
                    }
                    if canSurrender {
                        ActionCell(icon: "flag", label: "SURREN.", action: onSurrender)
                    }
                }
            }
        }
        .background(BJSColors.surfaceBase)
        .disabled(!isEnabled)
    }

    private var secondaryRowVisible: Bool { canSplit || canDouble || canSurrender }

    private var verticalDivider: some View {
        Rectangle()
            .fill(BJSColors.borderSubtle)
            .frame(width: 1)
    }

    private var horizontalDivider: some View {
        Rectangle()
            .fill(BJSColors.borderSubtle)
            .frame(height: 1)
    }
}

private struct ActionCell: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .regular))
                Text(label)
                    .font(Typography.caption)
                    .tracking(1.5)
            }
            .foregroundStyle(BJSColors.actionLabel)
            .frame(maxWidth: .infinity)
            .frame(height: 88)
        }
    }
}

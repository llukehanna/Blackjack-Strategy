import SwiftUI

/// Cream-filled primary action.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .feltText(.title)
                .foregroundStyle(FeltColor.onCream)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(FeltColor.cream, in: RoundedRectangle(cornerRadius: FeltRadius.button))
                .contentShape(RoundedRectangle(cornerRadius: FeltRadius.button))
        }
        .buttonStyle(.plain)
    }
}

/// Cream-outlined secondary action on felt.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .feltText(.title)
                .foregroundStyle(FeltColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .overlay(RoundedRectangle(cornerRadius: FeltRadius.button)
                    .strokeBorder(FeltColor.cream.opacity(0.7), lineWidth: 1.5))
                .contentShape(RoundedRectangle(cornerRadius: FeltRadius.button))
        }
        .buttonStyle(.plain)
    }
}

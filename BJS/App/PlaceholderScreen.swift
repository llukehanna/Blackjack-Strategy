import SwiftUI

/// Stand-in for screens that later steps build (modules from the hub, the Progress tab).
struct PlaceholderScreen: View {
    private let title: String

    init(title: String) {
        self.title = title
    }

    var body: some View {
        VStack(spacing: FeltSpacing.m) {
            Text(title)
                .feltType(.display)
                .foregroundStyle(FeltColor.textPrimary)
                .accessibilityIdentifier("placeholder.title")
            Text("Coming soon")
                .feltType(.body)
                .foregroundStyle(FeltColor.textSecondary)
        }
        .padding(FeltSpacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .feltBackground()
    }
}

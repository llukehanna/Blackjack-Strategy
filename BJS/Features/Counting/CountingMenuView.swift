import SwiftUI

struct CountingMenuView: View {
    let onSelect: (CountingScreen) -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                HStack {
                    Text("Counting").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                    Spacer()
                    CloseButton(identifier: "counting.close", action: onClose)
                }
                VStack(spacing: FeltSpacing.m) {
                    ModuleTile(title: "Running count", subtitle: "Keep the count as cards flash past") {
                        onSelect(.runningSetup)
                    }
                    .accessibilityIdentifier("counting.menu.running")
                    ModuleTile(title: "True count", subtitle: "Turn a running count into a true count") {
                        onSelect(.trueSetup)
                    }
                    .accessibilityIdentifier("counting.menu.true")
                    ModuleTile(title: "Card values", subtitle: "Learn and test the Hi-Lo values") {
                        onSelect(.cardValues)
                    }
                    .accessibilityIdentifier("counting.menu.values")
                }
            }
            .padding(FeltSpacing.l)
        }
    }
}

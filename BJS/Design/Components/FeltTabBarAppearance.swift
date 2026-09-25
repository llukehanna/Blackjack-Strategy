import SwiftUI
import UIKit

/// Gives the system tab bar an opaque `feltDeep` base.
enum FeltTabBarAppearance {
    @MainActor
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(FeltColor.feltDeep)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

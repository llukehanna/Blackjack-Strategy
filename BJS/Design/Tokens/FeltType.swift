import SwiftUI

/// Felt type roles (parent spec §4). Built on Dynamic Type text styles so they scale.
enum FeltType: CaseIterable {
    case display, title, body, label, stat

    var font: Font {
        switch self {
        case .display: return .title.bold()                       // 28 pt bold
        case .title: return .title3.weight(.semibold)             // 20 pt semibold
        case .body: return .subheadline                           // 15 pt regular
        case .label: return .caption2.weight(.semibold)           // 11 pt semibold
        case .stat: return .system(.title2, design: .monospaced)  // 22 pt semibold SF Mono
            .weight(.semibold).monospacedDigit()
        }
    }

    /// Letter spacing in points: +0.14 em at 11 pt for `label`, none otherwise.
    var tracking: CGFloat { self == .label ? 11 * 0.14 : 0 }

    var isUppercase: Bool { self == .label }
}

extension View {
    /// Applies a Felt type role: font, tracking and case.
    func feltText(_ role: FeltType) -> some View {
        font(role.font)
            .tracking(role.tracking)
            .textCase(role.isUppercase ? .uppercase : nil)
    }
}

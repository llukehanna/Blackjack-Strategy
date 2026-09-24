import SwiftUI

/// Felt type roles (spec §4). FROZEN at the end of Step 2.
///
/// Every role is built on a Dynamic Type text style, so it scales with the user's
/// text size. `nominalPointSize` is the size at the default ("Large") setting.
enum FeltType: CaseIterable, Sendable {
    case display
    case title
    case body
    case label
    case stat

    /// Tracking for `label`, as a fraction of the font size (+0.14 em).
    static let labelTrackingEm: CGFloat = 0.14

    var textStyle: Font.TextStyle {
        switch self {
        case .display: return .title
        case .title: return .title3
        case .body: return .subheadline
        case .label: return .caption2
        case .stat: return .title2
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display: return .bold
        case .title, .label, .stat: return .semibold
        case .body: return .regular
        }
    }

    var design: Font.Design {
        self == .stat ? .monospaced : .default
    }

    var nominalPointSize: CGFloat {
        switch self {
        case .display: return 28
        case .title: return 20
        case .body: return 15
        case .label: return 11
        case .stat: return 22
        }
    }

    var isUppercased: Bool { self == .label }

    var font: Font {
        let base = Font.system(textStyle, design: design, weight: weight)
        return self == .stat ? base.monospacedDigit() : base
    }
}

extension View {
    /// Applies a Felt type role: font, plus uppercase and tracking for `label`.
    func feltType(_ role: FeltType) -> some View {
        modifier(FeltTypeModifier(role: role))
    }
}

private struct FeltTypeModifier: ViewModifier {
    let role: FeltType
    /// 0.14 em of the 11 pt label size, scaled with Dynamic Type.
    @ScaledMetric(relativeTo: .caption2) private var labelTracking: CGFloat = 11 * FeltType.labelTrackingEm

    init(role: FeltType) {
        self.role = role
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if role.isUppercased {
            content
                .font(role.font)
                .textCase(.uppercase)
                .tracking(labelTracking)
        } else {
            content.font(role.font)
        }
    }
}

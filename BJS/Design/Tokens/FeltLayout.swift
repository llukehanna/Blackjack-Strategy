import CoreGraphics

/// Felt spacing scale (parent spec §4).
enum FeltSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    static let scale: [CGFloat] = [xs, s, m, l, xl, xxl]
}

/// Felt corner radii (parent spec §4).
enum FeltRadius {
    static let chip: CGFloat = 10
    static let tile: CGFloat = 14
    static let button: CGFloat = 14
    static let card: CGFloat = 8
    static let sheet: CGFloat = 16
}

/// The minimum tap target for every control.
enum FeltTapTarget {
    static let minimum: CGFloat = 44
}

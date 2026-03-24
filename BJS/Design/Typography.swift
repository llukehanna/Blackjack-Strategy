import SwiftUI

enum Typography {
    static let title: Font = .title2.bold()
    static let section: Font = .subheadline
    static let body: Font = .body
    static let secondary: Font = .subheadline
    static let mono: Font = .title2.monospaced().bold()
    static let buttonLabel: Font = .body.bold()
    /// Numeric stat values — monospaced digits for visual alignment
    static let statValue: Font = .title3.monospacedDigit().bold()
}

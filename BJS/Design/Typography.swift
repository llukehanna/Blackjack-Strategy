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
    /// 72pt display size for session accuracy hero stat (SessionSummaryView)
    static let heroStat: Font = .system(size: 72, weight: .bold, design: .monospaced)
    /// 34pt for player hand total display (TrainerView)
    static let playerTotal: Font = .system(size: 34, weight: .bold, design: .monospaced)
}

/// Formats an accuracy fraction as a rounded whole-number percent, shared across features
/// so no feature folder needs to import another's formatter.
enum PercentText {
    static let noData = "—"

    static func text(_ fraction: Double?) -> String {
        guard let fraction else { return noData }
        return "\(Int((fraction * 100).rounded()))%"
    }
}

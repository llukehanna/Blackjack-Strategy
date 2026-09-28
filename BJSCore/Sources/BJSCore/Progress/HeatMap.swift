/// Error-rate bands for the Progress heat map (Step 6 spec §2). A rate exactly on an edge
/// belongs to the lower bin.
public enum HeatBin: Int, CaseIterable, Sendable {
    /// Fewer than `ProgressStats.heatMapMinimumSamples` decisions.
    case insufficient
    /// 0% errors.
    case none
    /// Above 0% up to 15%.
    case low
    /// Above 15% up to 30%.
    case medium
    /// Above 30% up to 50%.
    case high
    /// Above 50%.
    case severe

    public init(_ cell: HeatCell?) {
        guard let rate = cell?.errorRate else {
            self = .insufficient
            return
        }
        switch rate {
        case ...0: self = .none
        case ...0.15: self = .low
        case ...0.30: self = .medium
        case ...0.50: self = .high
        default: self = .severe
        }
    }
}

/// Which rows each heat-map grid shows (Step 6 spec §1).
public enum HeatMapLayout {

    /// Dealer upcards 2...11 (11 = ace), in column order.
    public static let upcards = Array(2...11)

    /// Player values in row order. Hard 4 (2,2) and soft 12 (A,A) are graded only once split
    /// isn't legal, so their rows appear only when `cells` holds at least one decision in them.
    public static func rows(for type: HandType, cells: [TrainingCell: HeatCell]) -> [Int] {
        switch type {
        case .hard: return (has(.hard, 4, in: cells) ? [4] : []) + Array(5...20)
        case .soft: return (has(.soft, 12, in: cells) ? [12] : []) + Array(13...20)
        case .pair: return Array(2...11)
        }
    }

    private static func has(_ type: HandType, _ value: Int, in cells: [TrainingCell: HeatCell]) -> Bool {
        cells.keys.contains { $0.handType == type && $0.playerValue == value }
    }
}

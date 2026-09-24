/// Qualitative game rating from a house edge percentage (0.43 means 0.43%).
public enum EdgeRating: String, CaseIterable, Sendable {
    case good, ok, poor

    public init(houseEdge: Double) {
        if houseEdge < 0.5 {
            self = .good
        } else if houseEdge <= 1.0 {
            self = .ok
        } else {
            self = .poor
        }
    }

    public var displayName: String {
        switch self {
        case .good: return "Good"
        case .ok: return "OK"
        case .poor: return "Poor"
        }
    }
}

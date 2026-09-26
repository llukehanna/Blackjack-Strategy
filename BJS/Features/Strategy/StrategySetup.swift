import Foundation
import os
import BJSCore

/// Strategy trainer modes (parent spec §5). The raw value is stored as `Session.mode`.
enum StrategyMode: String, CaseIterable, Codable {
    case learn, test, speed, weakSpots

    var title: String {
        switch self {
        case .learn: return "Learn"
        case .test: return "Test"
        case .speed: return "Speed"
        case .weakSpots: return "Weak spots"
        }
    }

    var blurb: String {
        switch self {
        case .learn: return "The correct play is highlighted before you choose. Doesn't count towards your stats."
        case .test: return "No hints. Every decision is graded."
        case .speed: return "No hints, and a timer on every decision."
        case .weakSpots: return "No hints. Deals more of the hands you miss most."
        }
    }

    var showsHint: Bool { self == .learn }
    var isTimed: Bool { self == .speed }
    var usesWeights: Bool { self == .weakSpots }
}

enum StrategyLength: Hashable, Codable {
    case hands(Int)
    case endless

    static let options: [StrategyLength] = [.hands(25), .hands(50), .hands(100), .endless]

    var title: String {
        switch self {
        case .hands(let n): return "\(n)"
        case .endless: return "∞"
        }
    }

    var handLimit: Int? {
        switch self {
        case .hands(let n): return n
        case .endless: return nil
        }
    }
}

/// What a Strategy session deals; stored in `LastLaunch.setup` for Continue.
struct StrategySetup: Codable, Equatable {
    var mode: StrategyMode = .test
    var length: StrategyLength = .hands(25)
    var filter: HandFilter = .all

    func lastLaunch() throws -> LastLaunch {
        LastLaunch(module: .strategy, mode: mode.rawValue, setup: try JSONEncoder().encode(self))
    }

    /// nil (logged) when the data doesn't decode, e.g. after a format change.
    static func decode(_ data: Data) -> StrategySetup? {
        do {
            return try JSONDecoder().decode(StrategySetup.self, from: data)
        } catch {
            Logger(subsystem: "com.bjs.app", category: "Strategy")
                .error("Strategy setup failed to decode: \(error.localizedDescription)")
            return nil
        }
    }
}

extension HandFilter {
    var title: String {
        switch self {
        case .all: return "All"
        case .hard: return "Hard"
        case .soft: return "Soft"
        case .pairs: return "Pairs"
        }
    }
}

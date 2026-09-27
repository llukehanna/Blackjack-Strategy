import Foundation
import os
import BJSCore

/// How many cards a running-count drill deals (parent spec §5).
enum RunningCountLength: Hashable, Codable {
    case cards(Int)
    case fullShoe

    static let options: [RunningCountLength] = [.cards(10), .cards(26), .cards(52), .fullShoe]

    var title: String {
        switch self {
        case .cards(let n): return "\(n)"
        case .fullShoe: return "Shoe"
        }
    }

    var drillLength: DrillLength {
        switch self {
        case .cards(let n): return .cards(n)
        case .fullShoe: return .fullShoe
        }
    }
}

struct RunningCountSetup: Codable, Equatable {
    static let groupSizes = [1, 2, 3]
    /// Pace in tenths of a second: 0.3–2.0 s per group.
    static let paceTenthsRange = 3...20

    var groupSize = 1
    /// Seconds each group stays on screen.
    var pace = 1.0
    var length: RunningCountLength = .cards(52)
    var randomCheckpoints = false

    /// The pace in whole tenths, for the setup stepper (avoids 0.1-step drift).
    var paceTenths: Int {
        get { Int((pace * 10).rounded()) }
        set {
            let clamped = min(max(newValue, Self.paceTenthsRange.lowerBound), Self.paceTenthsRange.upperBound)
            pace = Double(clamped) / 10
        }
    }
}

enum TrueCountLength: Hashable, Codable {
    case questions(Int)
    case endless

    static let options: [TrueCountLength] = [.questions(10), .questions(20), .endless]

    var title: String {
        switch self {
        case .questions(let n): return "\(n)"
        case .endless: return "∞"
        }
    }

    var questionLimit: Int? {
        switch self {
        case .questions(let n): return n
        case .endless: return nil
        }
    }
}

struct TrueCountSetup: Codable, Equatable {
    var length: TrueCountLength = .questions(10)
}

/// A counting drill's setup, stored in `LastLaunch.setup` so Continue reopens the same drill.
enum CountingSetup: Codable, Equatable {
    case runningCount(RunningCountSetup)
    case trueCount(TrueCountSetup)

    var trainingModule: TrainingModule {
        switch self {
        case .runningCount: return .countingRC
        case .trueCount: return .countingTC
        }
    }

    func lastLaunch() throws -> LastLaunch {
        LastLaunch(module: trainingModule, mode: nil, setup: try JSONEncoder().encode(self))
    }

    /// nil (logged) when the data doesn't decode, e.g. after a format change.
    static func decode(_ data: Data) -> CountingSetup? {
        do {
            return try JSONDecoder().decode(CountingSetup.self, from: data)
        } catch {
            Logger(subsystem: "com.bjs.app", category: "Counting")
                .error("Counting setup failed to decode: \(error.localizedDescription)")
            return nil
        }
    }
}

import BJSCore

// Display text for training modules and the Strategy setup. Presentation only; shared by
// the hub's Continue button and the Strategy feature.

extension TrainingModule {
    var displayName: String {
        switch self {
        case .strategy: return "Strategy"
        case .countingRC: return "Running count"
        case .countingTC: return "True count"
        case .shoe: return "Shoe Sim"
        }
    }
}

extension StrategyMode {
    var displayName: String {
        switch self {
        case .learn: return "Learn"
        case .test: return "Test"
        case .speed: return "Speed"
        case .weakSpots: return "Weak spots"
        }
    }

    /// One line under the setup screen's mode picker.
    var setupDescription: String {
        switch self {
        case .learn: return "The correct play is ringed in brass before you choose."
        case .test: return "No hints. Every decision is graded."
        case .speed: return "No hints, and a countdown for every decision."
        case .weakSpots: return "Deals more of the hands you miss most (after 50 decisions)."
        }
    }
}

extension StrategySessionLength {
    /// Picker title: "25", "50", "100", "Endless".
    var displayName: String {
        handLimit.map(String.init) ?? "Endless"
    }

    /// "25 hands", "Endless".
    var longName: String {
        handLimit.map { "\($0) hands" } ?? "Endless"
    }
}

extension HandFilter {
    /// Picker title: "All", "Hard", "Soft", "Pairs".
    var displayName: String {
        switch self {
        case .all: return "All"
        case .hard: return "Hard"
        case .soft: return "Soft"
        case .pairs: return "Pairs"
        }
    }

    /// "All hands", "Hard hands", "Soft hands", "Pairs".
    var longName: String {
        switch self {
        case .all: return "All hands"
        case .hard: return "Hard hands"
        case .soft: return "Soft hands"
        case .pairs: return "Pairs"
        }
    }
}

enum LastLaunchText {
    /// Continue button title, e.g. "Continue: Strategy · Learn".
    static func title(_ launch: LastLaunch) -> String {
        var parts = [launch.module.displayName]
        if let config = launch.strategy {
            parts.append(config.mode.displayName)
        }
        return "Continue: " + parts.joined(separator: " · ")
    }

    /// The line under it, e.g. "25 hands · All hands". Nil when there is no setup to show.
    static func detail(_ launch: LastLaunch) -> String? {
        guard let config = launch.strategy else { return nil }
        return "\(config.length.longName) · \(config.filter.longName)"
    }
}

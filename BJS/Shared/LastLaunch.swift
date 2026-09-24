import BJSCore
import Foundation

/// What the hub's Continue button relaunches (spec §5 Hub, §6 `lastLaunch`):
/// the module, mode and setup of the last session the user started.
///
/// Stored as JSON. Later modules add their own optional setup field (e.g. `counting`),
/// which older stored values simply lack.
struct LastLaunch: Codable, Equatable, Sendable {
    let module: TrainingModule
    /// The module's mode raw value (e.g. "learn"), or nil for modules without modes.
    let mode: String?
    /// The Strategy setup, when `module == .strategy`.
    let strategy: StrategySessionConfig?

    init(module: TrainingModule, mode: String?, strategy: StrategySessionConfig?) {
        self.module = module
        self.mode = mode
        self.strategy = strategy
    }

    static func forStrategy(_ config: StrategySessionConfig) -> LastLaunch {
        LastLaunch(module: .strategy, mode: config.mode.rawValue, strategy: config)
    }

    static func encode(_ launch: LastLaunch) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            return try encoder.encode(launch)
        } catch {
            // Only enums and strings; encoding cannot fail in practice.
            preconditionFailure("LastLaunch failed to encode: \(error)")
        }
    }

    static func decode(_ data: Data) throws -> LastLaunch {
        try JSONDecoder().decode(LastLaunch.self, from: data)
    }
}

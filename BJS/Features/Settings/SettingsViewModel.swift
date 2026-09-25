import Observation
import os

@Observable
final class SettingsViewModel {
    var showsResetError = false

    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "Settings")

    /// Deletes all sessions. Rules and preferences are untouched (parent spec §5).
    func resetProgress(using store: SessionStore) {
        do {
            try store.deleteAll()
        } catch {
            logger.error("Reset progress failed: \(error.localizedDescription)")
            showsResetError = true
        }
    }
}

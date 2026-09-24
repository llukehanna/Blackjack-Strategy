import Foundation
import SwiftData

/// Settings → Reset progress: deletes every session and record. Rules and preferences
/// live in `UserDefaults` and are untouched.
enum ProgressReset {
    static func deleteAllProgress(in context: ModelContext) throws {
        // Deleting a Session cascades to its records; orphaned records are removed too.
        for session in try context.fetch(FetchDescriptor<Session>()) {
            context.delete(session)
        }
        for record in try context.fetch(FetchDescriptor<DecisionRecord>()) {
            context.delete(record)
        }
        for record in try context.fetch(FetchDescriptor<CountCheckRecord>()) {
            context.delete(record)
        }
        try context.save()
    }
}

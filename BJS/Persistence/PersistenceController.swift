import Foundation
import SwiftData

/// Builds the app's SwiftData container on `SchemaV1` with `BJSMigrationPlan`.
enum PersistenceController {
    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        // In-memory stores get a unique name so parallel tests never share one.
        let configuration = ModelConfiguration(inMemory ? UUID().uuidString : nil,
                                               schema: schema,
                                               isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, migrationPlan: BJSMigrationPlan.self,
                                  configurations: configuration)
    }

    /// The app's container. If the on-disk store cannot open, log it and fall back to
    /// an in-memory store so the app still launches (progress is not saved that run).
    static func makeAppContainer(inMemory: Bool) -> ModelContainer {
        do {
            return try makeContainer(inMemory: inMemory)
        } catch {
            let message = String(describing: error)
            AppLog.persistence.error("Opening the store failed; using memory. \(message, privacy: .public)")
            do {
                return try makeContainer(inMemory: true)
            } catch {
                fatalError("Could not create even an in-memory ModelContainer: \(error)")
            }
        }
    }
}

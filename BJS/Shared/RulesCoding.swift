import BJSCore
import Foundation

/// JSON encoding for `BlackjackRules`, shared by `ActiveRulesStore` (`activeRules` key)
/// and `Session.rulesJSON`.
enum RulesCoding {
    static func encode(_ rules: BlackjackRules) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            return try encoder.encode(rules)
        } catch {
            // BlackjackRules holds only enums, Bools and Ints; encoding cannot fail in practice.
            preconditionFailure("BlackjackRules failed to encode: \(error)")
        }
    }

    static func decode(_ data: Data) throws -> BlackjackRules {
        try JSONDecoder().decode(BlackjackRules.self, from: data)
    }
}

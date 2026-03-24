import Foundation
@testable import BJSCore

/// Helper that performs Codable round-trip encoding/decoding using Foundation's
/// JSONEncoder/JSONDecoder. Isolated to avoid cross-import overlay issues between
/// Testing and Foundation frameworks on Command Line Tools.
enum CodableTestHelper {

    /// Encodes a value to JSON and decodes it back, returning the decoded value.
    static func jsonRoundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

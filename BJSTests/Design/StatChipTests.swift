import Testing
@testable import BJS

@MainActor
struct StatChipTests {

    @Test("Accessibility value maps the em dash to 'No data', passing other values through")
    func accessibilityValue() {
        #expect(StatChip.accessibilityValue(for: "—") == "No data")
        #expect(StatChip.accessibilityValue(for: "87%") == "87%")
    }
}

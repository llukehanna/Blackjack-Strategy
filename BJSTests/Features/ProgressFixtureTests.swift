import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct ProgressFixtureTests {

    @Test("The fixture yields the documented numbers")
    func numbers() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let now = Date(timeIntervalSince1970: 100 * 86_400 + 12 * 3_600)
        let container = try BJSModelContainer.make(inMemory: true)
        let store = SessionStore(context: container.mainContext)
        ProgressFixture.seed(into: store, now: now, calendar: utc)

        let model = ProgressViewModel()
        model.reload(store: store, now: now, calendar: utc)
        #expect(model.chips.map(\.value) == ["67%", "67%", "67%", "—"])
        #expect(model.history.count == 9)
        #expect(model.history.first?.title == "Strategy · Test")
        #expect(model.chartSummary == "Strategy accuracy, 7 days: 5 days, latest 57%")

        func bin(_ type: HandType, _ value: Int, _ upcard: Int) -> HeatBin {
            HeatBin(model.heat[TrainingCell(handType: type, playerValue: value, dealerUpcard: upcard)])
        }
        #expect(bin(.hard, 16, 10) == .severe)
        #expect(bin(.hard, 11, 6) == .low)
        #expect(bin(.hard, 12, 4) == .none)
        #expect(bin(.soft, 18, 9) == .high)
        #expect(bin(.pair, 8, 11) == .medium)
        #expect(bin(.hard, 13, 2) == .insufficient)
        #expect(model.gridRows.first?.id == 4)

        model.range = .allTime
        model.reload(store: store, now: now, calendar: utc)
        #expect(model.chips.first?.value == "69%")
    }
}

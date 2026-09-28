import SwiftUI
import Testing
import BJSCore
@testable import BJS

@MainActor
struct ProgressComponentTests {

    @Test("Heat-map fills follow the spec: outline only, then correct, then four incorrect strengths")
    func fills() {
        #expect(HeatMapGrid.fill(for: .insufficient) == HeatMapGrid.Fill(color: nil, opacity: 0))
        #expect(HeatMapGrid.fill(for: .none) == HeatMapGrid.Fill(color: FeltColor.correct, opacity: 0.35))
        #expect(HeatMapGrid.fill(for: .low) == HeatMapGrid.Fill(color: FeltColor.incorrect, opacity: 0.30))
        #expect(HeatMapGrid.fill(for: .medium) == HeatMapGrid.Fill(color: FeltColor.incorrect, opacity: 0.50))
        #expect(HeatMapGrid.fill(for: .high) == HeatMapGrid.Fill(color: FeltColor.incorrect, opacity: 0.75))
        #expect(HeatMapGrid.fill(for: .severe) == HeatMapGrid.Fill(color: FeltColor.incorrect, opacity: 1))
    }

    @Test("No fill uses brass")
    func noBrass() {
        for bin in HeatBin.allCases {
            #expect(HeatMapGrid.fill(for: bin).color != FeltColor.brass)
        }
    }

    @Test("The legend lists every bin in order with the spec's labels")
    func legend() {
        #expect(HeatMapLegend.items.map(\.bin) == HeatBin.allCases)
        #expect(HeatMapLegend.items.map(\.label) == ["Not enough data", "0%", "≤15%", "≤30%", "≤50%", ">50%"])
    }
}

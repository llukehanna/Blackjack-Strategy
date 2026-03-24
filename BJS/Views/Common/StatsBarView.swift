import SwiftUI

struct StatsBarView: View {
    let stats: SessionStats

    var body: some View {
        Text("\(Int(stats.accuracy))% \u{00B7} \(stats.handCount) hands \u{00B7} \(stats.errorCount) errors")
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
    }
}

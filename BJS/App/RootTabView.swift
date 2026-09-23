import SwiftUI

/// The three top-level tabs. Tab contents are placeholders until Step 2 (Foundation).
enum AppTab: String, CaseIterable, Identifiable {
    case train = "Train"
    case progress = "Progress"
    case settings = "Settings"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .train: return "suit.spade.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape"
        }
    }
}

struct RootTabView: View {
    @State private var selection: AppTab = .train

    var body: some View {
        TabView(selection: $selection) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.rawValue, systemImage: tab.systemImage, value: tab) {
                    Text(tab.rawValue)
                        .font(.title)
                }
            }
        }
    }
}

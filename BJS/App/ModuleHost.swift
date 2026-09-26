import SwiftUI

/// Presents a launched module. The App layer is the only place that knows every feature.
struct ModuleHost: View {
    let launch: ModuleLaunch
    let onClose: () -> Void
    private let configuration = LaunchConfiguration.current

    var body: some View {
        switch launch.module {
        case .strategy:
            StrategyFlowView(initialSetup: launch.setup.flatMap(StrategySetup.decode),
                             handLimitOverride: configuration.strategyLength, seed: configuration.seed,
                             onClose: onClose)
        case .counting, .shoe, .edge:
            ComingSoonView(title: launch.module.title, message: "Coming in Step \(launch.module.step)",
                           onClose: onClose)
        }
    }
}

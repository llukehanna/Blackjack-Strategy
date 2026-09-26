import SwiftUI

/// Presents a launched module. The App layer is the only place that knows every feature.
struct ModuleHost: View {
    let launch: ModuleLaunch
    let onClose: () -> Void

    var body: some View {
        // Strategy is wired to its flow in Step 3 Task 9.
        ComingSoonView(title: launch.module.title, message: "Coming in Step \(launch.module.step)",
                       onClose: onClose)
    }
}

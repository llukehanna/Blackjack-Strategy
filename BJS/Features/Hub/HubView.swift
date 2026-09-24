import BJSCore
import SwiftData
import SwiftUI

/// Train tab (spec §5 Hub): rules summary, stat chips, Continue, module tiles.
///
/// Continue is hidden until a session has been started (first launch). `onContinue` and
/// `destination` are supplied by the App layer, so the Hub never names another feature.
struct HubView<Destination: View>: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(LastLaunchStore.self) private var lastLaunchStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var sessions: [Session]
    @Query private var decisions: [DecisionRecord]
    @State private var path: [HubRoute] = []

    private let onShowRules: () -> Void
    private let onContinue: (LastLaunch) -> Void
    private let destination: (HubRoute) -> Destination

    init(onShowRules: @escaping () -> Void, onContinue: @escaping (LastLaunch) -> Void,
         @ViewBuilder destination: @escaping (HubRoute) -> Destination) {
        self.onShowRules = onShowRules
        self.onContinue = onContinue
        self.destination = destination
    }

    private var stats: HubStats {
        HubStats.make(sessions: ProgressMapper.sessionSamples(sessions),
                      decisions: ProgressMapper.decisionSamples(decisions),
                      now: .now)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                    header
                    statChips
                    if let launch = lastLaunchStore.lastLaunch {
                        continueButton(launch)
                    }
                    tiles
                }
                .padding(.horizontal, FeltSpacing.l)
                .padding(.vertical, FeltSpacing.xl)
            }
            .feltBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HubRoute.self) { route in
                destination(route)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            Button(action: onShowRules) {
                HStack(spacing: FeltSpacing.xs) {
                    Text(RulesSummary.short(rulesStore.rules))
                    Image(systemName: "chevron.right")
                }
                .feltType(.label)
                .foregroundStyle(FeltColor.textSecondary)
                .frame(minHeight: FeltMetrics.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(FeltPressableStyle())
            .accessibilityLabel("Table rules: \(RulesSummary.short(rulesStore.rules))")
            .accessibilityHint("Opens Settings")
            .accessibilityIdentifier("hub.rulesSummary")

            Text("Train")
                .feltType(.display)
                .foregroundStyle(FeltColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("hub.title")
        }
    }

    private var statChips: some View {
        let current = stats
        return HStack(alignment: .top, spacing: FeltSpacing.s) {
            StatChip(label: "Strategy 30d", value: HubStats.percentText(current.strategyAccuracy))
            StatChip(label: "Count 30d", value: HubStats.percentText(current.countAccuracy))
            StatChip(label: "Streak", value: "\(current.strategyStreak)")
        }
    }

    private func continueButton(_ launch: LastLaunch) -> some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            PrimaryButton(LastLaunchText.title(launch)) {
                onContinue(launch)
            }
            .accessibilityIdentifier("hub.continue")
            if let detail = LastLaunchText.detail(launch) {
                Text(detail)
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textSecondary)
                    .padding(.horizontal, FeltSpacing.xs)
                    .accessibilityIdentifier("hub.continueDetail")
            }
        }
    }

    @ViewBuilder
    private var tiles: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: FeltSpacing.m) {
                ForEach(HubRoute.allCases) { route in
                    tile(route)
                }
            }
        } else {
            Grid(horizontalSpacing: FeltSpacing.m, verticalSpacing: FeltSpacing.m) {
                GridRow {
                    tile(.strategy)
                    tile(.counting)
                }
                GridRow {
                    tile(.shoeSim)
                    tile(.edge)
                }
            }
        }
    }

    private func tile(_ route: HubRoute) -> some View {
        ModuleTile(title: route.title, subtitle: route.subtitle) {
            path.append(route)
        }
        .accessibilityIdentifier("hub.tile.\(route.rawValue)")
    }
}

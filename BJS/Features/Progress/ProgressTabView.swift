import Charts
import SwiftUI
import BJSCore

/// The Progress tab (Step 6 spec §2). Named to avoid SwiftUI's `ProgressView`.
struct ProgressTabView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppRouter.self) private var router
    @State private var model = ProgressViewModel()

    private struct ReloadKey: Equatable {
        let revision: Int
        let range: ProgressRange
    }

    static let chartHeight: CGFloat = 180

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ZStack {
                FeltBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                        Text("Progress")
                            .feltText(.display)
                            .foregroundStyle(FeltColor.textPrimary)
                        if model.loadFailed {
                            Text(ProgressText.loadFailed)
                                .feltText(.body)
                                .foregroundStyle(FeltColor.incorrect)
                        }
                        if model.hasAnySessions {
                            ModePicker(options: ProgressRange.allCases, selection: $model.range,
                                       title: ProgressText.rangeTitle)
                            headlines
                            trend(model)
                            heatMap(model)
                            history
                        } else if !model.loadFailed {
                            emptyState
                        }
                    }
                    .padding(FeltSpacing.l)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                SessionDetailView(sessionID: id)
                    .toolbar(.visible, for: .navigationBar)
            }
        }
        .task(id: ReloadKey(revision: sessionStore.revision, range: model.range)) {
            model.reload(store: sessionStore)
        }
    }

    private var headlines: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s),
                            GridItem(.flexible(), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
            ForEach(model.chips) { chip in
                StatChip(label: chip.label, value: chip.value)
                    .accessibilityIdentifier("progress.chip.\(chip.module.rawValue)")
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .feltText(.label)
            .foregroundStyle(FeltColor.textTertiary)
    }

    private func trend(_ model: ProgressViewModel) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: FeltSpacing.m) {
            sectionLabel("Trend")
            ModePicker(options: ProgressViewModel.modules, selection: $model.trendModule,
                       title: ProgressText.moduleShortTitle)
            if let domain = model.chartDomain, !model.chartPoints.isEmpty {
                Chart(model.chartPoints) { point in
                    LineMark(x: .value("Day", point.day, unit: .day), y: .value("Accuracy", point.accuracy))
                        .foregroundStyle(FeltColor.cream)
                    PointMark(x: .value("Day", point.day, unit: .day), y: .value("Accuracy", point.accuracy))
                        .foregroundStyle(FeltColor.cream)
                        .accessibilityLabel(ProgressText.dayLabel(point.day))
                        .accessibilityValue(PercentText.text(point.accuracy))
                }
                .chartYScale(domain: 0...1)
                .chartXScale(domain: domain)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1]) { value in
                        AxisGridLine().foregroundStyle(FeltColor.surfaceInset)
                        AxisValueLabel {
                            if let fraction = value.as(Double.self) {
                                Text(PercentText.text(fraction))
                                    .font(FeltType.label.font)
                                    .foregroundStyle(FeltColor.textTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(FeltColor.surfaceInset)
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(FeltType.label.font)
                            .foregroundStyle(FeltColor.textTertiary)
                    }
                }
                .frame(height: Self.chartHeight)
                .accessibilityLabel(model.chartSummary)
                .accessibilityIdentifier("progress.chart")
            } else {
                Text(ProgressText.noPointsCaption)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: Self.chartHeight)
                    .accessibilityIdentifier("progress.chart")
            }
        }
    }

    private func heatMap(_ model: ProgressViewModel) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: FeltSpacing.m) {
            sectionLabel("Heat map")
            ModePicker(options: ProgressViewModel.handTypes, selection: $model.heatType,
                       title: ProgressText.handTypeTitle)
            if !model.hasHeatData {
                Text(ProgressText.noHeatCaption)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textSecondary)
            }
            HeatMapGrid(columns: ProgressViewModel.columnLabels, rows: model.gridRows) { row, column in
                model.select(row: row, column: column)
            }
            HeatMapLegend()
            if let caption = model.caption {
                Text(caption)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textSecondary)
                    .accessibilityIdentifier("progress.heatCaption")
            }
        }
    }

    private var history: some View {
        SettingsSection(title: "History") {
            ForEach(model.history) { row in
                NavigationLink(value: row.id) {
                    SettingsRow(label: row.title, footnote: row.dateText) {
                        Text(row.accuracy)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("progress.history.row")
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.m) {
            Text(ProgressText.emptyTitle)
                .feltText(.title)
                .foregroundStyle(FeltColor.textPrimary)
            Text(ProgressText.emptyMessage)
                .feltText(.body)
                .foregroundStyle(FeltColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: ProgressText.emptyButton) { router.selectedTab = .train }
        }
        .accessibilityIdentifier("progress.empty")
    }
}

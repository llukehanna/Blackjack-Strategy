import SwiftUI
import BJSCore

/// The Progress heat map (Step 6 spec §2): player-value rows × dealer-upcard columns, each cell
/// filled by its error-rate bin. Built from existing Felt tokens only.
///
/// Cells are narrower than `FeltTapTarget.minimum`; that's accepted for a dense grid. Tapping is
/// an enhancement (it shows a caption), and VoiceOver reaches every cell as its own element.
struct HeatMapGrid: View {
    struct Cell: Identifiable, Equatable {
        /// The dealer upcard, 2...11 (11 = ace).
        let id: Int
        let bin: HeatBin
        let accessibilityLabel: String
        let accessibilityValue: String
        let isSelected: Bool
    }

    struct Row: Identifiable, Equatable {
        /// The player value.
        let id: Int
        let label: String
        let cells: [Cell]
    }

    struct Fill: Equatable {
        /// nil: no fill, outline only.
        let color: Color?
        let opacity: Double
    }

    static let cellHeight: CGFloat = 28
    static let gap: CGFloat = 2
    static let labelWidth: CGFloat = 36
    static let outlineWidth: CGFloat = 1
    static let selectionWidth: CGFloat = 2

    let columns: [String]
    let rows: [Row]
    let onSelect: (_ row: Int, _ column: Int) -> Void

    static func fill(for bin: HeatBin) -> Fill {
        switch bin {
        case .insufficient: return Fill(color: nil, opacity: 0)
        case .none: return Fill(color: FeltColor.correct, opacity: 0.35)
        case .low: return Fill(color: FeltColor.incorrect, opacity: 0.30)
        case .medium: return Fill(color: FeltColor.incorrect, opacity: 0.50)
        case .high: return Fill(color: FeltColor.incorrect, opacity: 0.75)
        case .severe: return Fill(color: FeltColor.incorrect, opacity: 1)
        }
    }

    var body: some View {
        VStack(spacing: Self.gap) {
            HStack(spacing: Self.gap) {
                Color.clear.frame(width: Self.labelWidth, height: 1)
                ForEach(columns, id: \.self) { column in
                    Text(column)
                        .feltText(.label)
                        .foregroundStyle(FeltColor.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
            ForEach(rows) { row in
                HStack(spacing: Self.gap) {
                    Text(row.label)
                        .feltText(.label)
                        .foregroundStyle(FeltColor.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: Self.labelWidth, alignment: .trailing)
                        .accessibilityHidden(true)
                    ForEach(row.cells) { cell in
                        HeatMapSwatch(bin: cell.bin, isSelected: cell.isSelected)
                            .frame(maxWidth: .infinity)
                            .frame(height: Self.cellHeight)
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(row.id, cell.id) }
                            .accessibilityElement()
                            .accessibilityLabel(cell.accessibilityLabel)
                            .accessibilityValue(cell.accessibilityValue)
                            .accessibilityAddTraits(cell.isSelected ? [.isButton, .isSelected] : .isButton)
                            .accessibilityAction { onSelect(row.id, cell.id) }
                    }
                }
            }
        }
    }
}

/// One heat-map fill, shared by the grid's cells and the legend.
struct HeatMapSwatch: View {
    let bin: HeatBin
    var isSelected = false

    var body: some View {
        let fill = HeatMapGrid.fill(for: bin)
        Rectangle()
            .fill((fill.color ?? .clear).opacity(fill.opacity))
            .overlay {
                if fill.color == nil {
                    Rectangle().strokeBorder(FeltColor.surfaceInset, lineWidth: HeatMapGrid.outlineWidth)
                }
            }
            .overlay {
                if isSelected {
                    Rectangle().strokeBorder(FeltColor.cream, lineWidth: HeatMapGrid.selectionWidth)
                }
            }
    }
}

/// The heat map's key: one swatch per bin.
struct HeatMapLegend: View {
    static let items: [(bin: HeatBin, label: String)] = [
        (.insufficient, "Not enough data"), (.none, "0%"), (.low, "≤15%"),
        (.medium, "≤30%"), (.high, "≤50%"), (.severe, ">50%"),
    ]
    static let swatchSize: CGFloat = 12

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3),
                  alignment: .leading, spacing: FeltSpacing.s) {
            ForEach(Self.items, id: \.bin) { item in
                HStack(spacing: FeltSpacing.xs) {
                    HeatMapSwatch(bin: item.bin)
                        .frame(width: Self.swatchSize, height: Self.swatchSize)
                    Text(item.label)
                        .feltText(.label)
                        .foregroundStyle(FeltColor.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Legend")
    }
}

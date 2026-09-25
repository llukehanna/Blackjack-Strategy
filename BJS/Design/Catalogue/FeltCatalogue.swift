#if DEBUG
import SwiftUI
import BJSCore

/// Every Felt token and component in every state. DEBUG only; the design-freeze reference.
struct FeltCatalogue: View {
    var onClose: (() -> Void)? = nil

    @State private var mode = "Learn"
    @State private var entry = CountEntry()
    @State private var toggle = true
    @State private var stepper = 4

    private let swatches: [(String, FeltRGB)] = [
        ("feltDeep", FeltPalette.feltDeep), ("feltBase", FeltPalette.feltBase),
        ("feltLight", FeltPalette.feltLight), ("glowCentre", FeltPalette.glowCentre),
        ("surfaceInset", FeltPalette.surfaceInsetOnBase), ("cream", FeltPalette.cream),
        ("onCream", FeltPalette.onCream), ("onCreamSecondary", FeltPalette.onCreamSecondary),
        ("brass", FeltPalette.brass), ("correct", FeltPalette.correct),
        ("incorrect", FeltPalette.incorrect), ("suitRed", FeltPalette.suitRed),
        ("suitBlack", FeltPalette.suitBlack), ("textPrimary", FeltPalette.textPrimary),
        ("textSecondary", FeltPalette.textSecondary), ("textTertiary", FeltPalette.textTertiary),
    ]

    var body: some View {
        ZStack {
            FeltBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.xxl) {
                    HStack {
                        Text("Felt catalogue").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                        Spacer()
                        if let onClose {
                            Button("Close", action: onClose)
                                .foregroundStyle(FeltColor.textSecondary)
                                .frame(minHeight: FeltTapTarget.minimum)
                        }
                    }
                    section("Colour") { colours }
                    section("Contrast") { contrast }
                    section("Type") { type }
                    section("Cards") { cards }
                    section("Action dock") { docks }
                    section("Feedback") { feedback }
                    section("Chips, tiles, buttons") { surfaces }
                    section("Mode picker and settings") { controls }
                    section("Count keypad") {
                        CountKeypad(entry: $entry) { _ in }
                    }
                }
                .padding(FeltSpacing.l)
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FeltSpacing.m) {
            Text(title).feltText(.label).foregroundStyle(FeltColor.textTertiary)
            content()
        }
    }

    private var colours: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
            ForEach(swatches, id: \.0) { name, rgb in
                VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                    RoundedRectangle(cornerRadius: FeltRadius.chip)
                        .fill(rgb.color)
                        .frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: FeltRadius.chip)
                            .strokeBorder(FeltColor.textTertiary.opacity(0.4), lineWidth: 0.5))
                    Text(name).font(.caption2).foregroundStyle(FeltColor.textPrimary)
                    Text(String(format: "#%06X", rgb.hex)).font(.caption2.monospaced())
                        .foregroundStyle(FeltColor.textSecondary)
                }
            }
        }
    }

    private var contrast: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            ForEach(FeltContrast.requirements) { r in
                HStack {
                    Text(r.id).font(.caption).foregroundStyle(r.foreground.color)
                        .padding(.horizontal, FeltSpacing.s).padding(.vertical, 2)
                        .background(r.background.color, in: RoundedRectangle(cornerRadius: 4))
                    Spacer()
                    Text(String(format: "%.2f ≥ %.1f", r.ratio, r.minimum)).font(.caption.monospaced())
                        .foregroundStyle(FeltColor.textSecondary)
                    Image(systemName: r.passes ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(r.passes ? FeltColor.correct : FeltColor.incorrect)
                }
            }
        }
    }

    private var type: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text("Display 28 bold").feltText(.display)
            Text("Title 20 semibold").feltText(.title)
            Text("Body 15 regular — the quick brown fox").feltText(.body)
            Text("Label 11 semibold tracked").feltText(.label)
            Text("+12 −3.5 87%").feltText(.stat)
        }
        .foregroundStyle(FeltColor.textPrimary)
    }

    private var cards: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.l) {
            HStack(spacing: FeltSpacing.s) {
                PlayingCard(card: Card(rank: .ace, suit: .spades), width: 64)
                PlayingCard(card: Card(rank: .ten, suit: .hearts), width: 64)
                PlayingCard(card: Card(rank: .queen, suit: .diamonds), width: 64)
                PlayingCard(card: Card(rank: .eight, suit: .clubs), width: 64)
                PlayingCard(card: Card(rank: .two, suit: .hearts), isFaceUp: false, width: 64)
            }
            HStack(alignment: .top, spacing: FeltSpacing.xl) {
                HandView(cards: [Card(rank: .ace, suit: .hearts), Card(rank: .seven, suit: .clubs)],
                         cardWidth: 70, totalLabel: "Soft 18")
                HandView(cards: [Card(rank: .nine, suit: .spades), Card(rank: .king, suit: .diamonds)],
                         faceDownIndices: [1], cardWidth: 70)
            }
        }
    }

    private var docks: some View {
        VStack(spacing: FeltSpacing.l) {
            ActionDock(legal: Set(Action.allCases)) { _ in }
            ActionDock(legal: [.hit, .stand, .double], hint: .double) { _ in }
            ActionDock(legal: [.hit, .stand]) { _ in }
        }
    }

    private var feedback: some View {
        VStack(spacing: FeltSpacing.xxl) {
            FeedbackCard(verdict: .correct, headline: "Correct — double",
                         reason: "Soft 18 vs 6: the dealer busts often; double to press the edge.",
                         onWhy: {}, onNext: {})
            FeedbackCard(verdict: .incorrect, headline: "Hit, not stand",
                         reason: "Hard 16 vs 10: standing loses more often than hitting.",
                         onWhy: {}, onNext: {})
        }
        .padding(.top, FeltSpacing.xl)
    }

    private var surfaces: some View {
        VStack(spacing: FeltSpacing.m) {
            HStack(spacing: FeltSpacing.s) {
                StatChip(label: "Strategy", value: "92%")
                StatChip(label: "Count", value: "—")
                StatChip(label: "Streak", value: "14")
            }
            ModuleTile(title: "Strategy", subtitle: "Basic strategy drills") {}
            PrimaryButton(title: "Continue") {}
            SecondaryButton(title: "Close") {}
        }
    }

    private var controls: some View {
        VStack(spacing: FeltSpacing.l) {
            ModePicker(options: ["Learn", "Test", "Speed", "Weak spots"], selection: $mode) { $0 }
            SettingsSection(title: "Section") {
                SettingsRow(label: "Value") { Text("6 decks") }
                SettingsRow(label: "Toggle") { Toggle("", isOn: $toggle).labelsHidden() }
                SettingsRow(label: "Stepper") {
                    Stepper("\(stepper)", value: $stepper, in: 2...4).fixedSize()
                }
                SettingsRow(label: "With footnote", footnote: "A tertiary footnote under the row.") {
                    Text("Late")
                }
            }
        }
    }
}
#endif

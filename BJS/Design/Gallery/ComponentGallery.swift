#if DEBUG
import BJSCore
import SwiftUI

/// DEBUG-only pages showing every Felt component in every state, for the §7 design check.
/// Launch with `BJS_GALLERY_PAGE=<raw value>` (see `LaunchConfiguration`). Each page is
/// sized to fit an iPhone SE (3rd generation) screen.
enum GalleryPage: String, CaseIterable, Identifiable {
    case colors
    case type
    case cards
    case dock
    case feedback
    case buttons
    case tiles
    case settingsRows
    case keypad
    case keypadDecimal
    case countdown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .colors: return "Colours"
        case .type: return "Type & layout"
        case .cards: return "Cards & hands"
        case .dock: return "Action dock"
        case .feedback: return "Feedback"
        case .buttons: return "Buttons & picker"
        case .tiles: return "Chips & tiles"
        case .settingsRows: return "Settings rows"
        case .keypad: return "Count keypad"
        case .keypadDecimal: return "Keypad (decimal)"
        case .countdown: return "Countdown bar"
        }
    }
}

struct ComponentGalleryView: View {
    private let page: GalleryPage

    init(page: GalleryPage) {
        self.page = page
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.l) {
                Text(page.title)
                    .feltType(.display)
                    .foregroundStyle(FeltColor.textPrimary)
                    .accessibilityIdentifier("gallery.title")
                content
            }
            .padding(.horizontal, FeltSpacing.l)
            .padding(.vertical, FeltSpacing.l)
        }
        .feltBackground()
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .colors: ColorsGalleryPage()
        case .type: TypeGalleryPage()
        case .cards: CardsGalleryPage()
        case .dock: DockGalleryPage()
        case .feedback: FeedbackGalleryPage()
        case .buttons: ButtonsGalleryPage()
        case .tiles: TilesGalleryPage()
        case .settingsRows: SettingsRowsGalleryPage()
        case .keypad: KeypadGalleryPage(allowsDecimal: false)
        case .keypadDecimal: KeypadGalleryPage(allowsDecimal: true)
        case .countdown: CountdownGalleryPage()
        }
    }
}

/// A caption above one component state.
private struct GalleryItem<Content: View>: View {
    private let caption: String
    private let content: Content

    init(_ caption: String, @ViewBuilder content: () -> Content) {
        self.caption = caption
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            Text(caption)
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
            content
        }
    }
}

private struct ColorsGalleryPage: View {
    private struct Swatch: Identifiable {
        let name: String
        let color: Color
        var id: String { name }
    }

    private let swatches: [Swatch] = [
        Swatch(name: "feltDeep", color: FeltColor.feltDeep),
        Swatch(name: "feltBase", color: FeltColor.feltBase),
        Swatch(name: "feltLight", color: FeltColor.feltLight),
        Swatch(name: "surfaceInset", color: FeltColor.surfaceInset),
        Swatch(name: "cream", color: FeltColor.cream),
        Swatch(name: "onCream", color: FeltColor.onCream),
        Swatch(name: "onCreamSecondary", color: FeltColor.onCreamSecondary),
        Swatch(name: "brass", color: FeltColor.brass),
        Swatch(name: "correct", color: FeltColor.correct),
        Swatch(name: "incorrect", color: FeltColor.incorrect),
        Swatch(name: "suitRed", color: FeltColor.suitRed),
        Swatch(name: "suitBlack", color: FeltColor.suitBlack),
        Swatch(name: "textPrimary", color: FeltColor.textPrimary),
        Swatch(name: "textSecondary", color: FeltColor.textSecondary),
        Swatch(name: "textTertiary", color: FeltColor.textTertiary),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s), GridItem(.flexible())],
                  alignment: .leading, spacing: FeltSpacing.s) {
            ForEach(swatches) { swatch in
                HStack(spacing: FeltSpacing.s) {
                    RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous)
                        .fill(swatch.color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous)
                                .strokeBorder(FeltColor.textTertiary.opacity(0.4), lineWidth: 1)
                        )
                    Text(swatch.name)
                        .feltType(.body)
                        .foregroundStyle(FeltColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        // Text-on-cream samples.
        HStack(spacing: FeltSpacing.s) {
            Text("onCream").foregroundStyle(FeltColor.onCream)
            Text("secondary").foregroundStyle(FeltColor.onCreamSecondary)
            Text("♥").foregroundStyle(FeltColor.suitRed)
            Text("♠").foregroundStyle(FeltColor.suitBlack)
        }
        .feltType(.body)
        .padding(FeltSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FeltColor.cream, in: RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous))
    }
}

private struct TypeGalleryPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            ForEach(FeltType.allCases, id: \.self) { role in
                Text("\(String(describing: role)) · Soft 18 · 0.42%")
                    .feltType(role)
                    .foregroundStyle(FeltColor.textPrimary)
            }
        }
        GalleryItem("Spacing 4 · 8 · 12 · 16 · 24 · 32") {
            VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                ForEach(FeltSpacing.scale, id: \.self) { value in
                    Rectangle()
                        .fill(FeltColor.textSecondary)
                        .frame(width: value * 4, height: 6)
                }
            }
        }
        GalleryItem("Radius chip · tile · card · sheet") {
            HStack(spacing: FeltSpacing.s) {
                ForEach([FeltRadius.chip, FeltRadius.tile, FeltRadius.card, FeltRadius.sheet], id: \.self) { radius in
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(FeltColor.surfaceInset)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text("\(Int(radius))")
                                .feltType(.label)
                                .foregroundStyle(FeltColor.textSecondary)
                        )
                }
            }
        }
    }
}

private struct CardsGalleryPage: View {
    var body: some View {
        GalleryItem("PlayingCard · four suits · face down") {
            HStack(spacing: FeltSpacing.s) {
                PlayingCard(Card(rank: .ace, suit: .spades), width: 56)
                PlayingCard(Card(rank: .eight, suit: .clubs), width: 56)
                PlayingCard(Card(rank: .ten, suit: .hearts), width: 56)
                PlayingCard(Card(rank: .queen, suit: .diamonds), width: 56)
                PlayingCard(Card(rank: .two, suit: .spades), isFaceUp: false, width: 56)
            }
        }
        GalleryItem("PlayingCard · width 96") {
            HStack(spacing: FeltSpacing.m) {
                PlayingCard(Card(rank: .king, suit: .hearts), width: 96)
                PlayingCard(Card(rank: .king, suit: .hearts), isFaceUp: false, width: 96)
            }
        }
        GalleryItem("HandView · dealer (hole card) · player with total") {
            HStack(alignment: .top, spacing: FeltSpacing.xl) {
                HandView(cards: [Card(rank: .ten, suit: .hearts), Card(rank: .six, suit: .spades)],
                         faceDownIndices: [1], cardWidth: 56, overlap: 0.45)
                HandView(cards: [Card(rank: .ace, suit: .spades), Card(rank: .seven, suit: .diamonds),
                                 Card(rank: .three, suit: .clubs)],
                         cardWidth: 56, overlap: 0.55, totalLabel: "21")
            }
        }
    }
}

private struct DockGalleryPage: View {
    private let all = Set(Action.allCases)

    var body: some View {
        GalleryItem("All actions allowed") {
            ActionDock(allowed: all) { _ in }
        }
        GalleryItem("Dimmed: only hit / stand allowed") {
            ActionDock(allowed: [.hit, .stand]) { _ in }
        }
        GalleryItem("Learn-mode hint on DOUBLE") {
            ActionDock(allowed: all, hint: .double) { _ in }
        }
    }
}

private struct FeedbackGalleryPage: View {
    var body: some View {
        VStack(spacing: FeltSpacing.xl + FeedbackCard.badgeSize / 2) {
            FeedbackCard(isCorrect: true, headline: "Correct — Stand",
                         reason: "Hard 16 v 6: the dealer busts often enough.",
                         onWhy: {}, onNext: {})
            FeedbackCard(isCorrect: false, headline: "Double, not Hit",
                         reason: "Soft 18 v 6: double while the dealer is weak.",
                         onWhy: {}, onNext: {})
        }
        .padding(.top, FeedbackCard.badgeSize / 2)
    }
}

private struct ButtonsGalleryPage: View {
    @State private var mode = "Learn"
    @State private var length = "50"

    var body: some View {
        GalleryItem("PrimaryButton · enabled / disabled") {
            VStack(spacing: FeltSpacing.s) {
                PrimaryButton("Start session") {}
                PrimaryButton("Start session") {}.disabled(true)
            }
        }
        GalleryItem("SecondaryButton · enabled / disabled") {
            VStack(spacing: FeltSpacing.s) {
                SecondaryButton("Change rules") {}
                SecondaryButton("Change rules") {}.disabled(true)
            }
        }
        GalleryItem("ModePicker") {
            VStack(spacing: FeltSpacing.s) {
                ModePicker(["Learn", "Test", "Speed", "Weak spots"], selection: $mode) { $0 }
                ModePicker(["25", "50", "100", "Endless"], selection: $length) { $0 }
            }
        }
    }
}

private struct TilesGalleryPage: View {
    var body: some View {
        GalleryItem("StatChip · value / no data") {
            HStack(alignment: .top, spacing: FeltSpacing.s) {
                StatChip(label: "Strategy 30d", value: "87%")
                StatChip(label: "Count 30d", value: "—")
                StatChip(label: "Streak", value: "12")
            }
        }
        GalleryItem("ModuleTile") {
            Grid(horizontalSpacing: FeltSpacing.m, verticalSpacing: FeltSpacing.m) {
                GridRow {
                    ModuleTile(title: "Strategy", subtitle: "Basic strategy drills") {}
                    ModuleTile(title: "Counting", subtitle: "Hi-Lo running and true count") {}
                }
            }
        }
    }
}

private struct SettingsRowsGalleryPage: View {
    @State private var isOn = true
    @State private var isOff = false
    @State private var decks = BlackjackRules.DeckCount.six

    var body: some View {
        SettingsSection("Settings section") {
            SettingsRow("Value row", value: "Vegas Strip")
            SettingsRow("Picker row", selection: $decks,
                        options: BlackjackRules.DeckCount.allCases) { $0.displayName }
            SettingsRow("Toggle on", isOn: $isOn)
            SettingsRow("Toggle off", isOn: $isOff, showsSeparator: false)
        }
    }
}

private struct KeypadGalleryPage: View {
    private let allowsDecimal: Bool
    @State private var entry: CountEntry

    init(allowsDecimal: Bool) {
        self.allowsDecimal = allowsDecimal
        var entry = CountEntry()
        entry.toggleSign()
        entry.appendDigit(1)
        if allowsDecimal {
            entry.appendDecimalPoint()
            entry.appendDigit(2)
            entry.appendDigit(5)
        } else {
            entry.appendDigit(2)
        }
        self._entry = State(initialValue: entry)
    }

    var body: some View {
        CountKeypad(entry: $entry, allowsDecimal: allowsDecimal) { _ in }
    }
}

private struct CountdownGalleryPage: View {
    var body: some View {
        GalleryItem("Full") { CountdownBar(fraction: 1) }
        GalleryItem("Half") { CountdownBar(fraction: 0.5) }
        GalleryItem("Nearly out") { CountdownBar(fraction: 0.1) }
        GalleryItem("Empty (timeout)") { CountdownBar(fraction: 0) }
    }
}

#Preview("Cards") { ComponentGalleryView(page: .cards) }
#Preview("Dock") { ComponentGalleryView(page: .dock) }
#Preview("Feedback") { ComponentGalleryView(page: .feedback) }
#Preview("Keypad") { ComponentGalleryView(page: .keypad) }
#endif

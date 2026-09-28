import SwiftUI
import BJSCore

/// The Hi-Lo values table and an endless one-card self-test (Step 4 spec §4). Nothing is saved.
struct CardValuesView: View {
    @Bindable var model: CardValuesViewModel
    let onBack: () -> Void

    @Environment(PreferencesStore.self) private var preferences
    @State private var showsToast = false

    private struct ValueRow: Identifiable {
        let value: Int
        let ranks: [Rank]
        var id: Int { value }
    }

    private static let answersID = "answers"

    private static let rows: [ValueRow] = [
        ValueRow(value: 1, ranks: [.two, .three, .four, .five, .six]),
        ValueRow(value: 0, ranks: [.seven, .eight, .nine]),
        ValueRow(value: -1, ranks: [.ten, .jack, .queen, .king, .ace]),
    ]

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                        CountingHeader(title: "Card values", onBack: onBack)
                        SettingsSection(title: "Hi-Lo values") {
                            ForEach(Self.rows) { row in
                                SettingsRow(label: TrainingText.signed(row.value)) {
                                    HStack(spacing: FeltSpacing.xs) {
                                        ForEach(row.ranks, id: \.self) { rank in
                                            PlayingCard(card: Card(rank: rank, suit: .spades), width: 28)
                                        }
                                    }
                                }
                                .id(row.value)
                            }
                        }
                        selfTest
                    }
                    .padding(FeltSpacing.l)
                }
                .onChange(of: model.mistake) { _, mistake in
                    // Keep the missed card in view above the FeedbackCard. On the SE it would be covered;
                    // where it already shows, the scroll clamps at the top and nothing moves.
                    guard mistake != nil else { return }
                    withAnimation(FeltMotion.ui) { proxy.scrollTo(Self.answersID, anchor: .bottom) }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if let mistake = model.mistake {
                        let text = CountingText.cardValueFeedback(rank: mistake.rank)
                        FeedbackCard(verdict: .incorrect, headline: text.headline, reason: text.reason,
                                     onWhy: {
                                         withAnimation(FeltMotion.ui) {
                                             proxy.scrollTo(mistake.rank.hiLoValue, anchor: .top)
                                         }
                                     },
                                     onNext: { model.next() })
                            .overlay(alignment: .bottom) {
                                FeltColor.cream
                                    .frame(height: geo.safeAreaInsets.bottom)
                                    .offset(y: geo.safeAreaInsets.bottom)
                                    .accessibilityHidden(true)
                            }
                    }
                }
            }
        }
        .onChange(of: model.toastCount) { flashToast() }
        .sensoryFeedback(trigger: model.answered) { _, _ in
            guard preferences.hapticsEnabled else { return nil }
            return model.mistake == nil ? .success : .error
        }
    }

    private var selfTest: some View {
        VStack(spacing: FeltSpacing.l) {
            Text("Quick test").feltText(.label).foregroundStyle(FeltColor.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            ZStack {
                if showsToast { FeltToast(text: "Correct").fixedSize().transition(.opacity) }
            }
            .frame(height: FeltTapTarget.minimum)
            PlayingCard(card: model.card, width: 96)
                // A fresh identity per card, so a repeat still reads as a new card.
                .id(model.answered)
            HStack(spacing: FeltSpacing.s) {
                ForEach([1, 0, -1], id: \.self) { value in
                    SecondaryButton(title: TrainingText.signed(value)) { model.answer(value) }
                        .accessibilityIdentifier("counting.value.\(value)")
                }
            }
            .disabled(model.mistake != nil)
            .id(Self.answersID)
            Text("Score \(model.correct) / \(model.answered) · Streak \(model.streak)")
                .feltText(.body).foregroundStyle(FeltColor.textSecondary)
        }
    }

    private func flashToast() {
        withAnimation(FeltMotion.ui) { showsToast = true }
        AccessibilityNotification.Announcement("Correct").post()
        Task {
            try? await Task.sleep(for: .seconds(FeltToast.displayDuration))
            withAnimation(FeltMotion.ui) { showsToast = false }
        }
    }
}

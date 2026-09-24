import BJSCore
import Foundation
import SwiftData

/// Writes a Strategy session as one `Session` plus one `DecisionRecord` per graded decision
/// (spec §6). Each record keeps its own `decidedAt`.
@MainActor
struct SwiftDataStrategySessionSaver: StrategySessionSaving {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ snapshot: StrategySessionSnapshot) throws {
        let summary = snapshot.summary
        let session = Session(id: snapshot.id, module: TrainingModule.strategy.rawValue,
                              mode: snapshot.config.mode.rawValue, startedAt: snapshot.startedAt,
                              endedAt: snapshot.endedAt, rulesJSON: RulesCoding.encode(snapshot.rules),
                              decisionCount: summary.decisionCount, correctDecisions: summary.correctDecisions,
                              countChecks: 0, correctCountChecks: 0, bestStreak: summary.bestStreak,
                              meanResponseMs: summary.meanResponseMs)
        context.insert(session)
        for decision in snapshot.decisions {
            session.decisions.append(StrategyRecordMapper.record(decision))
        }
        do {
            try context.save()
        } catch {
            // Leave nothing half-saved behind; the caller shows a non-blocking alert.
            context.rollback()
            let message = String(describing: error)
            AppLog.persistence.error("Saving a strategy session failed: \(message, privacy: .public)")
            throw error
        }
    }
}

/// `GradedDecision` → `DecisionRecord`, using the `TrainingCell` conventions (ace = 11).
enum StrategyRecordMapper {
    static func record(_ decision: GradedDecision) -> DecisionRecord {
        DecisionRecord(handNumber: decision.handNumber,
                       handType: decision.cell.handType.rawValue,
                       playerValue: decision.cell.playerValue,
                       dealerUpcard: decision.cell.dealerUpcard,
                       chosenAction: decision.choice.storageValue,
                       correctAction: decision.correctAction.rawValue,
                       isCorrect: decision.isCorrect,
                       responseMs: decision.responseMs,
                       decidedAt: decision.decidedAt)
    }
}

/// Reads decision history for Weak-spots mode.
enum DecisionHistory {
    /// The newest `WeakSpotWeights.historyWindow` decisions from every module, as samples.
    /// A fetch failure is logged and treated as no history (uniform hands).
    static func recentSamples(in context: ModelContext) -> [DecisionSample] {
        var descriptor = FetchDescriptor<DecisionRecord>(sortBy: [SortDescriptor(\.decidedAt, order: .reverse)])
        descriptor.fetchLimit = WeakSpotWeights.historyWindow
        do {
            return ProgressMapper.decisionSamples(try context.fetch(descriptor))
        } catch {
            let message = String(describing: error)
            AppLog.persistence.error("Reading decision history failed: \(message, privacy: .public)")
            return []
        }
    }
}

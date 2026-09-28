import BJSCore

extension SchemaV1.Session {
    /// nil when `module` is not a known `TrainingModule`.
    var sample: SessionSample? {
        guard let module = TrainingModule(rawValue: module) else { return nil }
        return SessionSample(id: id, module: module, startedAt: startedAt,
                             decisionCount: decisionCount, correctDecisions: correctDecisions,
                             countChecks: countCheckCount, correctCountChecks: correctCountChecks)
    }
}

extension SchemaV1.DecisionRecord {
    /// nil when `handType` is not a known `HandType`.
    var sample: DecisionSample? {
        guard let type = HandType(rawValue: handType) else { return nil }
        return DecisionSample(date: decidedAt,
                              cell: TrainingCell(handType: type, playerValue: playerValue,
                                                 dealerUpcard: dealerUpcard),
                              isCorrect: isCorrect, responseMs: responseMs)
    }

    /// nil when `handType`, `chosenAction` or `correctAction` is not a known raw value, or when the
    /// cell's `playerValue`/`dealerUpcard` fall outside the ranges `WhyContext(cell:)` assumes are
    /// valid (hard 4...20, soft 12...20, pair 2...11, dealer upcard 2...11) — a corrupt persisted
    /// cell outside these would otherwise be misinterpreted (or crash) when WHY is rebuilt from it.
    var detail: SessionDetail.Decision? {
        guard let type = HandType(rawValue: handType),
              let chosen = RecordedChoice(rawValue: chosenAction),
              let correct = Action(rawValue: correctAction),
              Self.isValidCell(handType: type, playerValue: playerValue, dealerUpcard: dealerUpcard)
        else { return nil }
        return SessionDetail.Decision(cell: TrainingCell(handType: type, playerValue: playerValue,
                                                         dealerUpcard: dealerUpcard),
                                      chosen: chosen, correctAction: correct, isCorrect: isCorrect,
                                      responseMs: responseMs)
    }

    private static func isValidCell(handType: HandType, playerValue: Int, dealerUpcard: Int) -> Bool {
        guard (2...11).contains(dealerUpcard) else { return false }
        switch handType {
        case .hard: return (4...20).contains(playerValue)
        case .soft: return (12...20).contains(playerValue)
        case .pair: return (2...11).contains(playerValue)
        }
    }
}

extension SchemaV1.CountCheckRecord {
    /// nil when `kind` is not a known `CountKind`.
    var sample: CountSample? {
        guard let kind = CountKind(rawValue: kind) else { return nil }
        return CountSample(date: checkedAt, kind: kind, expected: expected, answered: answered,
                           isCorrect: isCorrect, responseMs: responseMs)
    }
}

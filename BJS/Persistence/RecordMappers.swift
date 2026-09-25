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
}

extension SchemaV1.CountCheckRecord {
    /// nil when `kind` is not a known `CountKind`.
    var sample: CountSample? {
        guard let kind = CountKind(rawValue: kind) else { return nil }
        return CountSample(date: checkedAt, kind: kind, expected: expected, answered: answered,
                           isCorrect: isCorrect, responseMs: responseMs)
    }
}

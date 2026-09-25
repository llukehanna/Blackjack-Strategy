import Foundation
import BJSCore

/// A strategy decision's chosen play: an action, or running out of time in Speed mode.
enum RecordedChoice: Equatable {
    case action(Action)
    case timeout

    static let timeoutRawValue = "timeout"

    var rawValue: String {
        switch self {
        case .action(let action): return action.rawValue
        case .timeout: return Self.timeoutRawValue
        }
    }

    init?(rawValue: String) {
        if rawValue == Self.timeoutRawValue {
            self = .timeout
        } else if let action = Action(rawValue: rawValue) {
            self = .action(action)
        } else {
            return nil
        }
    }
}

struct DecisionDraft: Equatable {
    var handNumber: Int
    var cell: TrainingCell
    var chosen: RecordedChoice
    var correctAction: Action
    var isCorrect: Bool
    var responseMs: Int?
    var decidedAt: Date
}

struct CountCheckDraft: Equatable {
    var kind: CountKind
    var expected: Double
    var answered: Double
    var isCorrect: Bool
    var responseMs: Int?
    var cardsSeen: Int
    var checkedAt: Date
}

/// A finished (or saved-partial) session, as features hand it to `SessionStore`.
/// `decisions` and `countChecks` are in the order they happened.
struct SessionDraft: Equatable {
    var id = UUID()
    var module: TrainingModule
    var mode: String?
    var startedAt: Date
    var endedAt: Date
    var rules: BlackjackRules
    var decisions: [DecisionDraft] = []
    var countChecks: [CountCheckDraft] = []
}

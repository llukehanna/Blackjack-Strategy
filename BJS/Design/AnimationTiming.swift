import Foundation

enum AnimationTiming {
    /// Duration of feedback fade animation
    static let feedbackFade: Double = 0.15
    /// How long feedback banner is held before auto-advancing
    static let feedbackHold: Double = 1.0
    /// Pause before dealer plays out cards
    static let dealerPlayOut: Double = 0.3
    /// How long hand result is shown before advancing to next hand
    static let handResultHold: Double = 1.0
}

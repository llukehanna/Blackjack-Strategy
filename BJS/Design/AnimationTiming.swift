import SwiftUI

enum AnimationTiming {
    static let tap        = Animation.easeOut(duration: 0.120)
    static let overlayIn  = Animation.easeOut(duration: 0.280)
    static let overlayOut = Animation.easeIn(duration: 0.200)
    static let cardDeal   = Animation.easeOut(duration: 0.320)
    static let cardDealStagger: Double = 0.060
}

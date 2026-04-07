import SwiftUI

enum BJSColors {
    static let surfaceBase        = Color(red: 0x0A/255, green: 0x0A/255, blue: 0x0E/255)
    static let surfaceRaised      = Color(red: 0x16/255, green: 0x16/255, blue: 0x1B/255)
    static let actionDark         = Color(red: 0x1F/255, green: 0x1F/255, blue: 0x25/255)
    static let surfaceOverlay     = Color.white
    static let borderSubtle       = Color.white.opacity(0.08)
    static let borderOnOverlay    = Color(red: 0xD8/255, green: 0xD8/255, blue: 0xDC/255)
    static let accentGold         = Color(red: 0xE0/255, green: 0xA4/255, blue: 0x36/255)
    static let actionLabel        = Color(red: 0x6B/255, green: 0x84/255, blue: 0x99/255)
    static let watermarkInk       = Color(red: 0x3A/255, green: 0x58/255, blue: 0x68/255)
    static let textPrimary        = Color.white
    static let textSecondary      = Color.white.opacity(0.6)
    static let textOnOverlay      = Color(red: 0x0A/255, green: 0x0A/255, blue: 0x0E/255)
    static let textOnOverlayMuted = Color(red: 0x0A/255, green: 0x0A/255, blue: 0x0E/255).opacity(0.65)
    static let feedbackCorrect    = Color(red: 0x2B/255, green: 0xB6/255, blue: 0x73/255)
    static let feedbackIncorrect  = Color(red: 0xE5/255, green: 0x48/255, blue: 0x4D/255)
    static let cardBackRed        = Color(red: 0xB8/255, green: 0x28/255, blue: 0x28/255)
}

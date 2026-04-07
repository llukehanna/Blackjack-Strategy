import SwiftUI

// caption expects .tracking(1.5) applied at use site per UI-07-D spec
enum Typography {
    static let caption: Font = .system(size: 12, weight: .bold)
    static let body:    Font = .system(size: 16, weight: .regular)
    static let title:   Font = .system(size: 22, weight: .bold)
}

import SwiftUI

/// Central design tokens for the app. Dark, athletic, lime accent.
enum Theme {
    static let bg          = Color(hex: 0x0E0F13)
    static let surface     = Color(hex: 0x1A1C22)
    static let surfaceHi   = Color(hex: 0x23262E)
    static let stroke      = Color(hex: 0x2C3039)
    static let accent      = Color(hex: 0xC9F24D)
    static let accentDim   = Color(hex: 0x7E9A2E)
    static let textPrimary = Color.white
    static let textSecond  = Color(hex: 0x8A8D98)
    static let danger      = Color(hex: 0xFF5C5C)

    static let cardRadius: CGFloat = 18
    static let rowRadius: CGFloat  = 12
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

/// Reusable card container.
struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }
}

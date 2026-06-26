import SwiftUI

extension Color {
    // MARK: - Primary palette — Navy Blue
    static let primaryIndigo = Color(hex: "#1B3A6B")       // was #3D5A99, now navy
    static let primaryLight  = Color(hex: "#2E5799")
    static let primaryDark   = Color(hex: "#0F2244")

    // MARK: - Accent
    static let accentGold = Color(hex: "#E8A33D")

    // MARK: - Status
    static let successGreen = Color(hex: "#2E7D52")
    static let dangerRed    = Color(hex: "#C0392B")

    // MARK: - Backgrounds — adaptive (light/dark mode)
    static let backgroundLight    = Color(.secondarySystemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let surface            = Color(.secondarySystemBackground)
    static let cardWhite          = Color(.secondarySystemBackground)   // replaces hardcoded white

    // MARK: - Text — adaptive
    static let textDark      = Color(.label)               // auto dark/light
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary  = Color(.tertiaryLabel)
    static let textOnPrimary = Color.white                 // always white on coloured bg

    // MARK: - Hex initialiser
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}

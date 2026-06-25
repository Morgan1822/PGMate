import SwiftUI

extension Color {
    static let primaryIndigo = Color(hex: "#3D5A99")
    static let accentGold = Color(hex: "#E8A33D")
    static let successGreen = Color(hex: "#4A9B6E")
    static let backgroundLight = Color(hex: "#F5F7FA")
    static let textDark = Color(hex: "#1A1A2E")
    static let cardWhite = Color(hex: "#FFFFFF")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

import SwiftUI
import UIKit

// MARK: - Semantic Color System
// All adaptive colors use UIColor(dynamicProvider:) for explicit light/dark control.
// No pure black in dark mode — all dark backgrounds are deep navy.

extension Color {

    // MARK: Navy palette (static, same in light & dark)
    static let navyPrimary  = Color(hex: "#1B3A6B")
    static let navyDark     = Color(hex: "#0F2447")
    static let navyLight    = Color(hex: "#2E5799")

    // MARK: Gold palette (static)
    static let gold         = Color(hex: "#E8A33D")
    static let goldLight    = Color(hex: "#F5C168")

    // MARK: Adaptive backgrounds
    /// Main screen background — white in light, deep navy in dark
    static let bgPrimary = Color(
        UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#0F1E3C")
                : .white
        })
    )

    /// Secondary background (behind cards, grouped list) — light grey / mid navy
    static let bgSecondary = Color(
        UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#162444")
                : UIColor(hex: "#F2F4F8")
        })
    )

    /// Card / surface — white in light, elevated navy in dark
    static let surface = Color(
        UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#1E2F52")
                : .white
        })
    )

    /// Elevated card / chip — very light blue-white in light, higher navy in dark
    static let surfaceElevated = Color(
        UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#243460")
                : UIColor(hex: "#EEF2FA")
        })
    )

    // MARK: Text
    /// Primary text — near-black in light, near-white in dark
    static let textPrimary = Color(
        UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#F0F4FF")
                : UIColor(hex: "#0F1E3C")
        })
    )

    /// Secondary text — medium grey / light grey-blue
    static let textSecondary = Color(
        UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#8FA3CC")
                : UIColor(hex: "#5A6A88")
        })
    )

    /// Tertiary / placeholder text
    static let textTertiary = Color(
        UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#5B7099")
                : UIColor(hex: "#9EB0CC")
        })
    )

    /// Text on navy backgrounds — always white
    static let textOnNavy = Color.white

    /// Text on gold buttons — always dark navy
    static let textOnGold = Color(hex: "#0F2447")

    // MARK: Status / semantic
    static let positive = Color(hex: "#2E7D52")   // income, paid
    static let negative = Color(hex: "#C0392B")   // expense, overdue
    static let pending  = Color(hex: "#E8A33D")   // pending / warning (reuses gold)
    static let warning  = Color(hex: "#D97706")   // maintenance / caution

    // MARK: Legacy aliases (kept for backwards compat with any remaining usages)
    static let primaryIndigo        = navyPrimary
    static let primaryLight         = navyLight
    static let primaryDark          = navyDark
    static let accentGold           = gold
    static let successGreen         = positive
    static let dangerRed            = negative
    static let backgroundLight      = bgPrimary
    static let backgroundSecondary  = bgSecondary
    static let cardWhite            = surface
    static let textDark             = textPrimary
    static let textOnPrimary        = textOnNavy

    // MARK: Hex initialiser
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - UIColor hex initialiser (used by dynamicProvider blocks)
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

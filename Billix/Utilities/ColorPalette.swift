import SwiftUI

extension Color {
    // Billix Company Color Palette - Inspired by Logo
    static let billixPurple = Color(hex: "#9b7b9f")          // Piggy bank purple
    static let billixGoldenAmber = Color(hex: "#e8b54d")     // Golden amber background
    static let billixDarkTeal = Color(hex: "#2d5a5e")        // Dark teal base
    static let billixMoneyGreen = Color(hex: "#5b8a6b")      // Money green
    static let billixCreamBeige = Color(hex: "#dcc9a8")      // Cream beige background
    static let billixDarkGray = Color(hex: "#282525")        // Dark gray/black
    static let billixLightPurple = Color(hex: "#c4a8c8")     // Light purple accent
    static let billixNavyBlue = Color(hex: "#2d4a5a")        // Navy blue outline
    static let billixGold = Color(hex: "#d4a04e")            // Gold coins
    static let billixCopper = Color(hex: "#b87554")          // Copper coins

    // Legacy colors for backward compatibility
    static let billixMutedPurple = billixPurple
    static let billixYellowGold = billixGoldenAmber
    static let billixSoftGreen = billixMoneyGreen
    static let billixLightBeige = billixCreamBeige
    static let billixMutedTeal = billixDarkTeal
    static let billixOliveGreen = billixMoneyGreen
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

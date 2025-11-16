import SwiftUI

extension Color {
    // Billix Company Color Palette
    static let billixMutedPurple = Color(hex: "#5a567b")     // Muted purple/blue
    static let billixLightTan = Color(hex: "#cfae96")        // Light tan
    static let billixOliveGreen = Color(hex: "#5f915f")      // Olive green
    static let billixDarkGray = Color(hex: "#282525")        // Dark gray/black
    static let billixSoftGreen = Color(hex: "#93b989")       // Soft green
    static let billixLightBeige = Color(hex: "#e2d6b9")      // Light beige
    static let billixYellowGold = Color(hex: "#e0d35a")      // Yellow-gold
    static let billixPaleGreenGray = Color(hex: "#9db1a8")   // Pale green-gray
    static let billixDustyLavender = Color(hex: "#ad8aa4")   // Dusty lavender
    static let billixMutedTeal = Color(hex: "#597c8b")       // Muted teal
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

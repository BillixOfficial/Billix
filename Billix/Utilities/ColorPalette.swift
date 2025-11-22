import SwiftUI

extension Color {
    // MARK: - Dark Theme Colors (Design System v2)

    /// Pure black background (#0A0A0A) - Main app background
    static let dsBackgroundPrimary = Color(hex: "#0A0A0A")

    /// Dark gray background (#1C1C1E) - Secondary background, cards
    static let dsBackgroundSecondary = Color(hex: "#1C1C1E")

    /// Medium dark gray (#2C2C2E) - Card surfaces
    static let dsCardBackground = Color(hex: "#2C2C2E")

    /// Elevated surface (#3C3C3E) - Elevated cards and components
    static let dsElevatedBackground = Color(hex: "#3C3C3E")

    // MARK: - Semantic Accent Colors

    /// Primary accent - Teal (#00796b)
    static let dsPrimaryAccent = Color(hex: "#00796b")

    /// Success/Money - Money Green (#5b8a6b)
    static let dsSuccess = Color(hex: "#5b8a6b")

    /// Warning/Pending - Orange (#f19e38)
    static let dsWarning = Color(hex: "#f19e38")

    /// Error/Overdue - Red (#dc6b62)
    static let dsError = Color(hex: "#dc6b62")

    /// Info - Blue (#52b8df)
    static let dsInfo = Color(hex: "#52b8df")

    /// Rewards - Gold (#d4a04e)
    static let dsGold = Color(hex: "#d4a04e")

    // MARK: - Text Colors (with semantic opacity)

    /// Primary text - White 100%
    static let dsTextPrimary = Color.white

    /// Secondary text - White 87%
    static let dsTextSecondary = Color.white.opacity(0.87)

    /// Tertiary text - White 60%
    static let dsTextTertiary = Color.white.opacity(0.6)

    /// Disabled text - White 38%
    static let dsTextDisabled = Color.white.opacity(0.38)

    // MARK: - Billix Company Color Palette - Inspired by Logo

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

    // Custom Background
    static let billixCustomGreen = Color(hex: "#5fa052")     // User-selected green background

    // Home Screen Specific Colors (from Figma)
    static let billixLightGreen = Color(hex: "#f0f8ec")      // Main background
    static let billixPendingOrange = Color(hex: "#fcf3e8")   // Pending bills background
    static let billixPendingOrangeText = Color(hex: "#d88237") // Pending text
    static let billixCompletedGreen = Color(hex: "#f0f8ec")  // Completed bills background
    static let billixCompletedGreenText = Color(hex: "#5e7a5f") // Completed text
    static let billixActiveBlue = Color(hex: "#e8f4fc")      // Active bills background
    static let billixActiveBlueText = Color(hex: "#467aa0")  // Active text
    static let billixDarkGreen = Color(hex: "#234d34")       // Dark text
    static let billixMediumGreen = Color(hex: "#5e7a5f")     // Medium green text
    static let billixLightGreenText = Color(hex: "#95ad96")  // Light green text
    static let billixStarGold = Color(hex: "#f19e38")        // Star rating
    static let billixSavingsYellow = Color(hex: "#f7bc56")   // Savings progress
    static let billixSavingsOrange = Color(hex: "#f1a626")   // Savings amount
    static let billixBorderGreen = Color(hex: "#d8e3d8")     // Border color
    static let billixChartBlue = Color(hex: "#52b8df")       // Chart blue
    static let billixChartGreen = Color(hex: "#67bf6a")      // Chart green
    static let billixPurpleAccent = Color(hex: "#5d4db1")    // Purple accent
    static let billixPurpleLight = Color(hex: "#7c74a8")     // Light purple
    static let billixChatBlue = Color(hex: "#468ba5")        // Chat blue
    static let billixChatBlueBg = Color(hex: "#b2dfeb")      // Chat background
    static let billixVotePink = Color(hex: "#dc6b62")        // Vote pink
    static let billixVoteRed = Color(hex: "#f0a59f")         // Vote red
    static let billixFundingPurple = Color(hex: "#5d4db1")   // Funding purple
    static let billixFaqGreen = Color(hex: "#429459")        // FAQ green
    static let billixGraphGray = Color(hex: "#2a2c3e")       // Graph text

    // Login Screen Colors
    static let billixLoginGreen = Color(hex: "#e0f7e0")      // Login background
    static let billixLoginTeal = Color(hex: "#00796b")       // Login primary color

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

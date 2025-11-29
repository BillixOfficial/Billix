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

    // Rewards/Arcade Colors
    static let billixArcadeGold = Color(hex: "#FFD700")     // Bright gold for wins/points
    static let billixPrizeOrange = Color(hex: "#FF8C00")    // Prize/reward accent
    static let billixLeaderGold = Color(hex: "#FFD700")     // 1st place
    static let billixLeaderSilver = Color(hex: "#C0C0C0")   // 2nd place
    static let billixLeaderBronze = Color(hex: "#CD7F32")   // 3rd place
    static let billixGamePurple = Color(hex: "#8B5CF6")     // Game/arcade accent

    // Tier System Colors
    static let billixBronzeTier = Color(hex: "#CD7F32")     // Bronze tier
    static let billixSilverTier = Color(hex: "#C0C0C0")     // Silver tier
    static let billixGoldTier = Color(hex: "#FFD700")       // Gold tier
    static let billixPlatinumTier = Color(hex: "#E5E4E2")   // Platinum tier
    static let billixStreakOrange = Color(hex: "#FF6B35")   // Streak fire color
    static let billixFlashRed = Color(hex: "#FF4757")       // Flash deal accent

    // Login Screen Colors
    static let billixLoginGreen = Color(hex: "#b8e6b8")      // Login background - richer green
    static let billixLoginTeal = Color(hex: "#00796b")       // Login primary color

    // Profile Screen Colors (from Figma)
    static let billixProfileBlue = Color(hex: "#E2F4FF")     // Profile page light blue background
    static let billixProfileDarkBlue = Color(hex: "#1E3A5F") // Profile header text dark blue

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

// MARK: - Button Styles

/// A button style that scales down when pressed with spring animation
struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

import Foundation

// MARK: - Marketplace Settings Model

struct MarketplaceSettings: Codable, Equatable {
    var isMarketplaceEnabled: Bool
    var anonymityLevel: AnonymityLevel
    var showTenure: Bool
    var hideOutliers: Bool

    // Categories contributing to marketplace
    var contributingCategories: [String]

    var anonymityDescription: String {
        switch anonymityLevel {
        case .zipBand:
            return "ZIP band (070**)"
        case .cityOnly:
            return "City only (Newark, NJ)"
        case .full:
            return "Full anonymity"
        }
    }
}

// MARK: - Anonymity Level

enum AnonymityLevel: String, Codable, CaseIterable {
    case zipBand = "ZIP Band"
    case cityOnly = "City Only"
    case full = "Full Anonymity"
}

// MARK: - Security & Account

struct SecurityAccount: Codable, Equatable {
    var email: String
    var phoneNumber: String?
    var isTwoFactorEnabled: Bool
    var loggedInDevices: [LoggedInDevice]
}

// MARK: - Logged In Device

struct LoggedInDevice: Identifiable, Codable, Equatable {
    let id: UUID
    let deviceName: String
    let deviceType: String
    let lastActive: Date

    var lastActiveString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Last active \(formatter.string(from: lastActive))"
    }

    var icon: String {
        switch deviceType.lowercased() {
        case "iphone", "phone": return "iphone"
        case "ipad", "tablet": return "ipad"
        case "mac", "desktop": return "desktopcomputer"
        default: return "laptopcomputer"
        }
    }
}

// MARK: - Preview Data

extension MarketplaceSettings {
    static let preview = MarketplaceSettings(
        isMarketplaceEnabled: true,
        anonymityLevel: .zipBand,
        showTenure: true,
        hideOutliers: false,
        contributingCategories: ["Electricity", "Internet", "Streaming"]
    )

    static let previewOptedOut = MarketplaceSettings(
        isMarketplaceEnabled: false,
        anonymityLevel: .full,
        showTenure: false,
        hideOutliers: true,
        contributingCategories: []
    )
}

extension SecurityAccount {
    static let preview = SecurityAccount(
        email: "ronald.richards@example.com",
        phoneNumber: "+1 (555) 123-4567",
        isTwoFactorEnabled: true,
        loggedInDevices: [
            LoggedInDevice(
                id: UUID(),
                deviceName: "iPhone 14",
                deviceType: "iPhone",
                lastActive: Date()
            ),
            LoggedInDevice(
                id: UUID(),
                deviceName: "Chrome on Mac",
                deviceType: "Mac",
                lastActive: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            )
        ]
    )

    static let previewNoTwoFactor = SecurityAccount(
        email: "jane.cooper@example.com",
        phoneNumber: nil,
        isTwoFactorEnabled: false,
        loggedInDevices: [
            LoggedInDevice(
                id: UUID(),
                deviceName: "iPhone 15 Pro",
                deviceType: "iPhone",
                lastActive: Date()
            )
        ]
    )
}

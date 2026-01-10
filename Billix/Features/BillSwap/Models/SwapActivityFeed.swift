//
//  SwapActivityFeed.swift
//  Billix
//
//  Activity Feed Model for Social Proof in Bill Swap Marketplace
//

import Foundation

// MARK: - Activity Feed Item

/// Anonymized swap activity for social proof display
struct SwapActivityFeedItem: Identifiable, Codable {
    let id: UUID
    let swapId: UUID
    let timestamp: Date
    let category1: String
    let category2: String
    let amountRange: SwapAmountRange
    let tierBadge1: String
    let tierBadge2: String

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case timestamp
        case category1 = "category_1"
        case category2 = "category_2"
        case amountRange = "amount_range"
        case tierBadge1 = "tier_badge_1"
        case tierBadge2 = "tier_badge_2"
    }

    // MARK: - Computed Properties

    /// Display text for the activity (e.g., "Electric <-> Water swap completed")
    var displayText: String {
        let cat1 = categoryDisplayName(category1)
        let cat2 = categoryDisplayName(category2)
        return "\(cat1) <-> \(cat2) swap completed"
    }

    /// Short display text
    var shortDisplayText: String {
        "Swap completed"
    }

    /// Amount range display
    var amountRangeText: String {
        amountRange.displayText
    }

    /// Relative time string (e.g., "2 min ago")
    var relativeTimeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Category 1 icon
    var category1Icon: String {
        categoryIcon(category1)
    }

    /// Category 2 icon
    var category2Icon: String {
        categoryIcon(category2)
    }

    // MARK: - Helper Methods

    private func categoryDisplayName(_ category: String) -> String {
        switch category.lowercased() {
        case "electric", "electricity": return "Electric"
        case "gas", "natural_gas", "naturalgas": return "Gas"
        case "water": return "Water"
        case "internet": return "Internet"
        case "phone", "phone_plan", "phoneplan": return "Phone"
        case "cable": return "Cable"
        case "streaming": return "Streaming"
        default: return "Bill"
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "electric", "electricity": return "bolt.fill"
        case "gas", "natural_gas", "naturalgas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet": return "wifi"
        case "phone", "phone_plan", "phoneplan": return "phone.fill"
        case "cable": return "tv.fill"
        case "streaming": return "play.tv.fill"
        default: return "doc.text.fill"
        }
    }
}

// MARK: - Swap Amount Range

enum SwapAmountRange: String, Codable, CaseIterable {
    case small = "SMALL"      // $20-$50
    case medium = "MEDIUM"    // $50-$150
    case large = "LARGE"      // $150-$500
    case xlarge = "XLARGE"    // $500+

    var displayText: String {
        switch self {
        case .small: return "$20-$50"
        case .medium: return "$50-$150"
        case .large: return "$150-$500"
        case .xlarge: return "$500+"
        }
    }

    var shortText: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .xlarge: return "XL"
        }
    }

    var icon: String {
        switch self {
        case .small: return "dollarsign.circle"
        case .medium: return "dollarsign.circle.fill"
        case .large: return "banknote"
        case .xlarge: return "banknote.fill"
        }
    }

    /// Determine range from cents amount
    static func fromCents(_ cents: Int) -> SwapAmountRange {
        switch cents {
        case 0..<5000: return .small
        case 5000..<15000: return .medium
        case 15000..<50000: return .large
        default: return .xlarge
        }
    }
}

// MARK: - Activity Feed Stats

/// Statistics for the activity feed
struct ActivityFeedStats {
    let totalSwapsToday: Int
    let totalSwapsThisWeek: Int
    let averageMatchTime: TimeInterval?
    let mostActiveCategory: String?

    var formattedTodayCount: String {
        "\(totalSwapsToday) swaps today"
    }

    var formattedWeekCount: String {
        "\(totalSwapsThisWeek) this week"
    }

    var formattedMatchTime: String? {
        guard let time = averageMatchTime else { return nil }
        let minutes = Int(time / 60)
        if minutes < 60 {
            return "Avg \(minutes)m to match"
        } else {
            let hours = minutes / 60
            return "Avg \(hours)h to match"
        }
    }
}

// MARK: - Mock Data for Preview

extension SwapActivityFeedItem {
    static var mockItems: [SwapActivityFeedItem] {
        [
            SwapActivityFeedItem(
                id: UUID(),
                swapId: UUID(),
                timestamp: Date().addingTimeInterval(-120),
                category1: "electric",
                category2: "water",
                amountRange: .medium,
                tierBadge1: "T2_VERIFIED",
                tierBadge2: "T3_TRUSTED"
            ),
            SwapActivityFeedItem(
                id: UUID(),
                swapId: UUID(),
                timestamp: Date().addingTimeInterval(-300),
                category1: "internet",
                category2: "phone",
                amountRange: .small,
                tierBadge1: "T1_PROVISIONAL",
                tierBadge2: "T2_VERIFIED"
            ),
            SwapActivityFeedItem(
                id: UUID(),
                swapId: UUID(),
                timestamp: Date().addingTimeInterval(-600),
                category1: "gas",
                category2: "electric",
                amountRange: .large,
                tierBadge1: "T3_TRUSTED",
                tierBadge2: "T4_POWER"
            ),
            SwapActivityFeedItem(
                id: UUID(),
                swapId: UUID(),
                timestamp: Date().addingTimeInterval(-1800),
                category1: "streaming",
                category2: "streaming",
                amountRange: .small,
                tierBadge1: "T2_VERIFIED",
                tierBadge2: "T2_VERIFIED"
            ),
            SwapActivityFeedItem(
                id: UUID(),
                swapId: UUID(),
                timestamp: Date().addingTimeInterval(-3600),
                category1: "water",
                category2: "cable",
                amountRange: .medium,
                tierBadge1: "T4_POWER",
                tierBadge2: "T3_TRUSTED"
            )
        ]
    }
}

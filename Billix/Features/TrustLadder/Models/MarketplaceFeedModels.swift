//
//  MarketplaceFeedModels.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Models for Live Marketplace Feed feature
//

import Foundation
import SwiftUI

// MARK: - Feed Event Type

enum FeedEventType: String, Codable, CaseIterable {
    case swapMatched = "swap_matched"
    case swapCompleted = "swap_completed"
    case newListing = "new_listing"
    case priceAlert = "price_alert"
    case hotCategory = "hot_category"
    case milestone = "milestone"

    var displayName: String {
        switch self {
        case .swapMatched: return "Swap Matched"
        case .swapCompleted: return "Swap Completed"
        case .newListing: return "New Listing"
        case .priceAlert: return "Price Alert"
        case .hotCategory: return "Hot Category"
        case .milestone: return "Milestone"
        }
    }

    var icon: String {
        switch self {
        case .swapMatched: return "arrow.left.arrow.right.circle.fill"
        case .swapCompleted: return "checkmark.circle.fill"
        case .newListing: return "plus.circle.fill"
        case .priceAlert: return "bell.circle.fill"
        case .hotCategory: return "flame.fill"
        case .milestone: return "star.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .swapMatched: return .blue
        case .swapCompleted: return .green
        case .newListing: return .purple
        case .priceAlert: return .orange
        case .hotCategory: return .red
        case .milestone: return .yellow
        }
    }

    var verb: String {
        switch self {
        case .swapMatched: return "matched"
        case .swapCompleted: return "completed"
        case .newListing: return "listed"
        case .priceAlert: return "alert"
        case .hotCategory: return "trending"
        case .milestone: return "reached"
        }
    }
}

// MARK: - Amount Range

enum AmountRange: String, Codable, CaseIterable {
    case under50 = "under_50"
    case range50to100 = "50_100"
    case range100to200 = "100_200"
    case range200to500 = "200_500"
    case over500 = "over_500"

    var displayName: String {
        switch self {
        case .under50: return "Under $50"
        case .range50to100: return "$50-$100"
        case .range100to200: return "$100-$200"
        case .range200to500: return "$200-$500"
        case .over500: return "$500+"
        }
    }

    var shortName: String {
        switch self {
        case .under50: return "<$50"
        case .range50to100: return "$50-100"
        case .range100to200: return "$100-200"
        case .range200to500: return "$200-500"
        case .over500: return "$500+"
        }
    }

    static func range(for amount: Decimal) -> AmountRange {
        switch amount {
        case ..<50: return .under50
        case 50..<100: return .range50to100
        case 100..<200: return .range100to200
        case 200..<500: return .range200to500
        default: return .over500
        }
    }
}

// MARK: - Feed Event

struct MarketplaceFeedEvent: Codable, Identifiable {
    let id: UUID
    let eventType: String
    let category: String?
    let amountRange: String?
    let zipPrefix: String?
    let metadata: FeedEventMetadata?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case eventType = "event_type"
        case category
        case amountRange = "amount_range"
        case zipPrefix = "zip_prefix"
        case metadata
        case createdAt = "created_at"
    }

    var type: FeedEventType? {
        FeedEventType(rawValue: eventType)
    }

    var billCategory: ReceiptBillCategory? {
        guard let category = category else { return nil }
        return ReceiptBillCategory(rawValue: category)
    }

    var range: AmountRange? {
        guard let amountRange = amountRange else { return nil }
        return AmountRange(rawValue: amountRange)
    }

    /// Time ago string
    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    /// Anonymized description for display
    var description: String {
        let categoryName = billCategory?.displayName ?? "Bill"
        let rangeName = range?.shortName ?? ""

        switch type {
        case .swapMatched:
            return "\(categoryName) swap matched \(rangeName)"
        case .swapCompleted:
            return "\(categoryName) swap completed \(rangeName)"
        case .newListing:
            return "New \(categoryName) listing \(rangeName)"
        case .priceAlert:
            return "\(categoryName) prices are trending"
        case .hotCategory:
            return "\(categoryName) is hot right now"
        case .milestone:
            return metadata?.milestoneText ?? "Community milestone reached"
        case .none:
            return "Activity in your area"
        }
    }
}

// MARK: - Feed Event Metadata

struct FeedEventMetadata: Codable {
    var regionName: String?
    var milestoneText: String?
    var count: Int?
    var percentageChange: Double?

    var formattedChange: String? {
        guard let change = percentageChange else { return nil }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(Int(change))%"
    }
}

// MARK: - Feed Event Insert

struct FeedEventInsert: Codable {
    let eventType: String
    let category: String?
    let amountRange: String?
    let zipPrefix: String?
    let metadata: FeedEventMetadata?

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case category
        case amountRange = "amount_range"
        case zipPrefix = "zip_prefix"
        case metadata
    }
}

// MARK: - Marketplace Statistics

struct MarketplaceStatistics: Codable {
    var totalActiveListings: Int
    var swapsCompletedToday: Int
    var averageMatchTime: TimeInterval // In seconds
    var hotCategories: [HotCategory]
    var volumeByCategory: [String: Int]

    var formattedMatchTime: String {
        if averageMatchTime < 3600 {
            let minutes = Int(averageMatchTime / 60)
            return "\(minutes) min"
        } else {
            let hours = Int(averageMatchTime / 3600)
            return "\(hours) hr"
        }
    }

    static var empty: MarketplaceStatistics {
        MarketplaceStatistics(
            totalActiveListings: 0,
            swapsCompletedToday: 0,
            averageMatchTime: 0,
            hotCategories: [],
            volumeByCategory: [:]
        )
    }
}

// MARK: - Hot Category

struct HotCategory: Codable, Identifiable {
    let category: String
    let listingCount: Int
    let trend: Double // Percentage change

    var id: String { category }

    var billCategory: ReceiptBillCategory? {
        ReceiptBillCategory(rawValue: category)
    }

    var isIncreasing: Bool {
        trend > 0
    }

    var trendIcon: String {
        isIncreasing ? "arrow.up.right" : "arrow.down.right"
    }

    var trendColor: Color {
        isIncreasing ? .green : .red
    }
}

// MARK: - Feed Filter

struct FeedFilter {
    var eventTypes: Set<FeedEventType> = Set(FeedEventType.allCases)
    var categories: Set<ReceiptBillCategory> = Set(ReceiptBillCategory.allCases)
    var amountRanges: Set<AmountRange> = Set(AmountRange.allCases)
    var regionOnly: Bool = false

    var isDefault: Bool {
        eventTypes.count == FeedEventType.allCases.count &&
        categories.count == ReceiptBillCategory.allCases.count &&
        amountRanges.count == AmountRange.allCases.count &&
        !regionOnly
    }

    static var `default`: FeedFilter {
        FeedFilter()
    }
}

// MARK: - Activity Indicator

struct ActivityIndicator {
    let level: ActivityLevel
    let message: String

    enum ActivityLevel: String {
        case low
        case moderate
        case high
        case veryHigh = "very_high"

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .moderate: return "Moderate"
            case .high: return "High"
            case .veryHigh: return "Very High"
            }
        }

        var color: Color {
            switch self {
            case .low: return .gray
            case .moderate: return .yellow
            case .high: return .orange
            case .veryHigh: return .red
            }
        }

        var icon: String {
            switch self {
            case .low: return "circle"
            case .moderate: return "circle.lefthalf.filled"
            case .high: return "circle.fill"
            case .veryHigh: return "flame.fill"
            }
        }
    }

    static func fromCount(_ count: Int) -> ActivityIndicator {
        switch count {
        case 0..<5:
            return ActivityIndicator(level: .low, message: "Quiet right now")
        case 5..<15:
            return ActivityIndicator(level: .moderate, message: "Some activity")
        case 15..<30:
            return ActivityIndicator(level: .high, message: "Busy marketplace")
        default:
            return ActivityIndicator(level: .veryHigh, message: "Very active!")
        }
    }
}

// MARK: - Region Activity

struct RegionActivity: Identifiable {
    let zipPrefix: String
    let activityCount: Int
    let topCategory: ReceiptBillCategory?

    var id: String { zipPrefix }

    var regionName: String {
        // In production, would map zip prefix to region name
        "Area \(zipPrefix)xx"
    }
}

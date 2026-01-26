//
//  BillListing.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  Model for bill listings in Bill Explorer feed
//

import Foundation

// MARK: - Bill Type

enum BillType: String, CaseIterable, Identifiable {
    case electric = "Electric"
    case gas = "Gas"
    case water = "Water"
    case internet = "Internet"
    case phone = "Phone"
    case rent = "Rent"
    case insurance = "Insurance"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .electric: return "bolt.fill"
        case .gas: return "flame.fill"
        case .water: return "drop.fill"
        case .internet: return "wifi"
        case .phone: return "phone.fill"
        case .rent: return "house.fill"
        case .insurance: return "shield.fill"
        }
    }

    var color: String {
        switch self {
        case .electric: return "#F59E0B"  // Amber
        case .gas: return "#EF4444"       // Red
        case .water: return "#3B82F6"     // Blue
        case .internet: return "#8B5CF6"  // Purple
        case .phone: return "#10B981"     // Green
        case .rent: return "#6366F1"      // Indigo
        case .insurance: return "#EC4899" // Pink
        }
    }
}

// MARK: - Housing Type

enum HousingType: String {
    case apartment = "Apartment"
    case house = "House"
    case condo = "Condo"
    case townhouse = "Townhouse"
}

// MARK: - Occupant Range

enum OccupantRange: String {
    case one = "1 person"
    case oneToTwo = "1-2 people"
    case threeToFour = "3-4 people"
    case fivePlus = "5+ people"
}

// MARK: - Square Footage Range

enum SqftRange: String {
    case small = "< 800 sqft"
    case medium = "800-1200 sqft"
    case large = "1200-2000 sqft"
    case xlarge = "2000+ sqft"
}

// MARK: - Bill Trend

enum BillTrend: String {
    case increased = "Increased"
    case decreased = "Decreased"
    case stable = "Stable"

    var icon: String {
        switch self {
        case .increased: return "arrow.up"
        case .decreased: return "arrow.down"
        case .stable: return "arrow.right"
        }
    }

    var color: String {
        switch self {
        case .increased: return "#EF4444"  // Red
        case .decreased: return "#10B981"  // Green
        case .stable: return "#6B7280"     // Gray
        }
    }
}

// MARK: - Volatility

enum BillVolatility: String {
    case stable = "Stable"
    case moderate = "Moderate"
    case spiky = "Spiky"
}

// MARK: - Bill Reaction Type

enum BillReactionType: String, CaseIterable {
    case looksLow = "looksLow"
    case high = "high"
    case howDidYou = "howDidYou"
    case jumped = "jumped"

    var emoji: String {
        switch self {
        case .looksLow: return "👍"
        case .high: return "😬"
        case .howDidYou: return "❓"
        case .jumped: return "🔥"
        }
    }

    var label: String {
        switch self {
        case .looksLow: return "This looks low"
        case .high: return "This is high"
        case .howDidYou: return "How did you get this down?"
        case .jumped: return "This jumped a lot"
        }
    }
}

// MARK: - Explore Bill Listing Model

struct ExploreBillListing: Identifiable {
    let id: UUID
    let billType: BillType
    let provider: String
    let amount: Double
    let billingPeriod: String
    let city: String
    let state: String

    // Household context (optional)
    var housingType: HousingType?
    var occupants: OccupantRange?
    var squareFootage: SqftRange?

    // Comparison data
    let percentile: Int  // 0-100, lower percentile = lower bill (better)
    let historicalMin: Double
    let historicalMax: Double
    let trend: BillTrend
    let volatility: BillVolatility

    // User input
    var userNote: String?

    // Trust signals
    let isVerified: Bool
    let lastUpdated: Date
    let anonymizedId: String  // "User #4821"

    // Engagement
    var reactions: [BillReactionType: Int]
    var commentCount: Int

    // Computed properties
    var formattedAmount: String {
        return String(format: "$%.0f", amount)
    }

    var location: String {
        return "\(city), \(state)"
    }

    var percentileText: String {
        if percentile <= 30 {
            return "Lower than \(100 - percentile)% of similar households"
        } else if percentile >= 70 {
            return "Higher than \(percentile)% of similar households"
        } else {
            return "Around average for similar households"
        }
    }

    var historicalRangeText: String {
        return "$\(Int(historicalMin)) - $\(Int(historicalMax))"
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }

    var totalReactions: Int {
        reactions.values.reduce(0, +)
    }
}

// MARK: - Mock Data

extension ExploreBillListing {
    static let mockListings: [ExploreBillListing] = [
        ExploreBillListing(
            id: UUID(),
            billType: .electric,
            provider: "ConEd",
            amount: 185,
            billingPeriod: "Jan 2026",
            city: "Austin",
            state: "TX",
            housingType: .apartment,
            occupants: .oneToTwo,
            squareFootage: .medium,
            percentile: 32,
            historicalMin: 142,
            historicalMax: 210,
            trend: .increased,
            volatility: .moderate,
            userNote: "Cold month - heater running",
            isVerified: true,
            lastUpdated: Date().addingTimeInterval(-86400 * 2),
            anonymizedId: "User #4821",
            reactions: [.looksLow: 12, .high: 3, .howDidYou: 5, .jumped: 2],
            commentCount: 8
        ),
        ExploreBillListing(
            id: UUID(),
            billType: .internet,
            provider: "Xfinity",
            amount: 89,
            billingPeriod: "Jan 2026",
            city: "Chicago",
            state: "IL",
            housingType: .apartment,
            occupants: .oneToTwo,
            squareFootage: .small,
            percentile: 45,
            historicalMin: 79,
            historicalMax: 95,
            trend: .stable,
            volatility: .stable,
            userNote: nil,
            isVerified: true,
            lastUpdated: Date().addingTimeInterval(-86400 * 1),
            anonymizedId: "User #2910",
            reactions: [.looksLow: 8, .high: 15, .howDidYou: 3, .jumped: 0],
            commentCount: 4
        ),
        ExploreBillListing(
            id: UUID(),
            billType: .gas,
            provider: "National Grid",
            amount: 145,
            billingPeriod: "Jan 2026",
            city: "Boston",
            state: "MA",
            housingType: .house,
            occupants: .threeToFour,
            squareFootage: .large,
            percentile: 68,
            historicalMin: 85,
            historicalMax: 180,
            trend: .increased,
            volatility: .spiky,
            userNote: "Rate increase this month",
            isVerified: true,
            lastUpdated: Date().addingTimeInterval(-86400 * 3),
            anonymizedId: "User #7823",
            reactions: [.looksLow: 2, .high: 22, .howDidYou: 1, .jumped: 18],
            commentCount: 12
        ),
        ExploreBillListing(
            id: UUID(),
            billType: .water,
            provider: "City Water",
            amount: 42,
            billingPeriod: "Jan 2026",
            city: "Phoenix",
            state: "AZ",
            housingType: .apartment,
            occupants: .one,
            squareFootage: .small,
            percentile: 18,
            historicalMin: 35,
            historicalMax: 55,
            trend: .decreased,
            volatility: .stable,
            userNote: nil,
            isVerified: false,
            lastUpdated: Date().addingTimeInterval(-86400 * 5),
            anonymizedId: "User #1102",
            reactions: [.looksLow: 28, .high: 1, .howDidYou: 15, .jumped: 0],
            commentCount: 6
        ),
        ExploreBillListing(
            id: UUID(),
            billType: .phone,
            provider: "Verizon",
            amount: 95,
            billingPeriod: "Jan 2026",
            city: "Seattle",
            state: "WA",
            housingType: nil,
            occupants: .oneToTwo,
            squareFootage: nil,
            percentile: 55,
            historicalMin: 85,
            historicalMax: 105,
            trend: .stable,
            volatility: .stable,
            userNote: "Family plan",
            isVerified: true,
            lastUpdated: Date().addingTimeInterval(-3600 * 12),
            anonymizedId: "User #5543",
            reactions: [.looksLow: 5, .high: 8, .howDidYou: 2, .jumped: 1],
            commentCount: 3
        ),
        ExploreBillListing(
            id: UUID(),
            billType: .rent,
            provider: "Greystar",
            amount: 2150,
            billingPeriod: "Jan 2026",
            city: "Denver",
            state: "CO",
            housingType: .apartment,
            occupants: .oneToTwo,
            squareFootage: .medium,
            percentile: 42,
            historicalMin: 2000,
            historicalMax: 2200,
            trend: .increased,
            volatility: .stable,
            userNote: "Renewed lease - 3% increase",
            isVerified: true,
            lastUpdated: Date().addingTimeInterval(-86400 * 1),
            anonymizedId: "User #9921",
            reactions: [.looksLow: 18, .high: 5, .howDidYou: 8, .jumped: 3],
            commentCount: 15
        ),
        ExploreBillListing(
            id: UUID(),
            billType: .insurance,
            provider: "State Farm",
            amount: 125,
            billingPeriod: "Jan 2026",
            city: "Nashville",
            state: "TN",
            housingType: .house,
            occupants: .threeToFour,
            squareFootage: .large,
            percentile: 28,
            historicalMin: 115,
            historicalMax: 140,
            trend: .decreased,
            volatility: .stable,
            userNote: "Bundled with auto",
            isVerified: true,
            lastUpdated: Date().addingTimeInterval(-86400 * 4),
            anonymizedId: "User #3382",
            reactions: [.looksLow: 22, .high: 2, .howDidYou: 12, .jumped: 0],
            commentCount: 9
        ),
        ExploreBillListing(
            id: UUID(),
            billType: .electric,
            provider: "Duke Energy",
            amount: 245,
            billingPeriod: "Jan 2026",
            city: "Miami",
            state: "FL",
            housingType: .house,
            occupants: .fivePlus,
            squareFootage: .xlarge,
            percentile: 78,
            historicalMin: 180,
            historicalMax: 320,
            trend: .increased,
            volatility: .spiky,
            userNote: "AC running constantly",
            isVerified: true,
            lastUpdated: Date().addingTimeInterval(-86400 * 2),
            anonymizedId: "User #6677",
            reactions: [.looksLow: 1, .high: 35, .howDidYou: 0, .jumped: 28],
            commentCount: 22
        )
    ]
}

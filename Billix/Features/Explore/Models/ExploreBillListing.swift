//
//  BillListing.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  Model for bill listings in Bill Explorer feed
//

import Foundation

// MARK: - Bill Type

enum ExploreBillType: String, CaseIterable, Identifiable {
    case electric = "Electric"
    case gas = "Gas"
    case water = "Water"
    case internet = "Internet"
    case phone = "Phone"
    case rent = "Rent"
    case insurance = "Insurance"

    var id: String { rawValue }

    var displayName: String { rawValue }

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

    var displayText: String { rawValue }
}

// MARK: - Price Range (for historical data)

struct PriceRange {
    let min: Double
    let max: Double

    var displayText: String {
        "$\(Int(min)) - $\(Int(max))"
    }
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

    var displayText: String { rawValue }

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

// MARK: - Bill Reaction Type (Legacy - for backward compatibility)

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

// MARK: - Vote Type (Icon-based interactions)

enum VoteType: String, Codable {
    case up
    case down
}

// MARK: - Bill Interaction Model

struct BillInteraction: Codable, Identifiable {
    let id: UUID
    let listingId: UUID
    let userId: UUID
    var vote: VoteType?
    var isBookmarked: Bool
    let createdAt: Date

    init(listingId: UUID, userId: UUID, vote: VoteType? = nil, isBookmarked: Bool = false) {
        self.id = UUID()
        self.listingId = listingId
        self.userId = userId
        self.vote = vote
        self.isBookmarked = isBookmarked
        self.createdAt = Date()
    }
}

// MARK: - Anonymous Question Model

struct AnonymousQuestion: Identifiable, Codable {
    let id: UUID
    let listingId: UUID
    let askerAnonymousId: String
    let question: String
    var answer: String?
    var answeredAt: Date?
    let createdAt: Date

    var isAnswered: Bool {
        answer != nil
    }

    init(listingId: UUID, askerAnonymousId: String, question: String) {
        self.id = UUID()
        self.listingId = listingId
        self.askerAnonymousId = askerAnonymousId
        self.question = question
        self.answer = nil
        self.answeredAt = nil
        self.createdAt = Date()
    }
}

// MARK: - Explore Bill Listing Model

struct ExploreBillListing: Identifiable {
    let id: UUID
    let billType: ExploreBillType
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

    // Engagement (legacy)
    var reactions: [BillReactionType: Int]
    var commentCount: Int

    // Engagement metrics
    var voteScore: Int
    var tipCount: Int
    var viewCount: Int

    // Rotation algorithm
    var lastBoostedAt: Date?

    // Usage data (for bill-type specific details)
    var usageAmount: Double?       // e.g., 892 (kWh for electric)
    var usageUnit: String?         // e.g., "kWh", "therms", "gallons"
    var ratePerUnit: Double?       // e.g., 0.12 ($/kWh)
    var areaAverageUsage: Double?  // e.g., 1200 (for comparison)
    var areaMinUsage: Double?      // e.g., 400 (lowest in dataset)
    var areaMaxUsage: Double?      // e.g., 2500 (highest in dataset)

    // Bill-type specific details
    var planName: String?          // e.g., "Performance Plus"
    var additionalDetails: [String: String]?  // Flexible key-value pairs

    // Computed properties
    var formattedAmount: String {
        return String(format: "$%.0f", amount)
    }

    var location: String {
        return "\(city), \(state)"
    }

    // Alias for compatibility
    var anonymousId: String {
        anonymizedId
    }

    // Historical range struct for detail view
    var historicalRange: PriceRange? {
        PriceRange(min: historicalMin, max: historicalMax)
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

    // New computed properties for Bill Explorer feed
    var timeAgoDisplay: String {
        let seconds = Date().timeIntervalSince(lastUpdated)
        if seconds < 3600 {
            return "\(Int(seconds / 60))m ago"
        } else if seconds < 86400 {
            return "\(Int(seconds / 3600))h ago"
        } else {
            return "\(Int(seconds / 86400))d ago"
        }
    }

    var locationDisplay: String {
        "\(city), \(state)"
    }

    var percentileDescription: String? {
        if percentile <= 25 {
            return "Lower than \(100 - percentile)% of similar homes"
        } else if percentile >= 75 {
            return "Higher than \(percentile)% of similar homes"
        } else {
            return "Around average for similar homes"
        }
    }

    // Usage comparison computed properties
    var usageDisplayText: String? {
        guard let usage = usageAmount, let unit = usageUnit else { return nil }
        return "\(Int(usage)) \(unit)"
    }

    var rateDisplayText: String? {
        guard let rate = ratePerUnit, let unit = usageUnit else { return nil }
        return String(format: "$%.2f/\(unit)", rate)
    }

    var usagePercentageDiff: Double? {
        guard let usage = usageAmount, let avg = areaAverageUsage, avg > 0 else { return nil }
        return ((usage - avg) / avg) * 100
    }

    var usageComparisonText: String? {
        guard let diff = usagePercentageDiff else { return nil }
        let absDiff = abs(Int(diff))
        if diff < -5 {
            return "\(absDiff)% below area average"
        } else if diff > 5 {
            return "\(absDiff)% above area average"
        } else {
            return "Around area average"
        }
    }

    var hasUsageData: Bool {
        usageAmount != nil && usageUnit != nil
    }

    // Region computed from state
    var region: USRegion {
        USRegion.region(for: state)
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
            commentCount: 8,
            voteScore: 24,
            tipCount: 12,
            viewCount: 247,
            lastBoostedAt: nil,
            usageAmount: 892,
            usageUnit: "kWh",
            ratePerUnit: 0.21,
            areaAverageUsage: 1100,
            areaMinUsage: 450,
            areaMaxUsage: 2200,
            planName: nil,
            additionalDetails: ["peakUsage": "4-9 PM weekdays"]
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
            commentCount: 4,
            voteScore: 18,
            tipCount: 7,
            viewCount: 183,
            lastBoostedAt: nil,
            usageAmount: nil,
            usageUnit: nil,
            ratePerUnit: nil,
            areaAverageUsage: nil,
            areaMinUsage: nil,
            areaMaxUsage: nil,
            planName: "Performance Pro",
            additionalDetails: ["speed": "500 Mbps down / 50 Mbps up", "contract": "No contract"]
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
            commentCount: 12,
            voteScore: 8,
            tipCount: 3,
            viewCount: 92,
            lastBoostedAt: nil,
            usageAmount: 68,
            usageUnit: "therms",
            ratePerUnit: 2.13,
            areaAverageUsage: 52,
            areaMinUsage: 25,
            areaMaxUsage: 95,
            planName: nil,
            additionalDetails: nil
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
            commentCount: 6,
            voteScore: 42,
            tipCount: 19,
            viewCount: 521,
            lastBoostedAt: Date().addingTimeInterval(-3600),
            usageAmount: 2800,
            usageUnit: "gallons",
            ratePerUnit: 0.015,
            areaAverageUsage: 4200,
            areaMinUsage: 1500,
            areaMaxUsage: 8000,
            planName: nil,
            additionalDetails: ["tier": "Tier 1 (0-5000 gal)"]
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
            commentCount: 3,
            voteScore: 15,
            tipCount: 5,
            viewCount: 156,
            lastBoostedAt: nil,
            usageAmount: nil,
            usageUnit: nil,
            ratePerUnit: nil,
            areaAverageUsage: nil,
            areaMinUsage: nil,
            areaMaxUsage: nil,
            planName: "Family Plan",
            additionalDetails: ["lines": "2 lines", "data": "Unlimited"]
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
            commentCount: 15,
            voteScore: 31,
            tipCount: 8,
            viewCount: 312,
            lastBoostedAt: nil,
            usageAmount: nil,
            usageUnit: nil,
            ratePerUnit: nil,
            areaAverageUsage: nil,
            areaMinUsage: nil,
            areaMaxUsage: nil,
            planName: nil,
            additionalDetails: ["bedrooms": "2 BR / 1 BA", "amenities": "Gym, Pool, Parking", "lease": "12-month lease"]
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
            commentCount: 9,
            voteScore: 28,
            tipCount: 11,
            viewCount: 278,
            lastBoostedAt: nil,
            usageAmount: nil,
            usageUnit: nil,
            ratePerUnit: nil,
            areaAverageUsage: nil,
            areaMinUsage: nil,
            areaMaxUsage: nil,
            planName: nil,
            additionalDetails: ["coverage": "$300,000", "deductible": "$1,000", "policyType": "Homeowners"]
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
            commentCount: 22,
            voteScore: 5,
            tipCount: 2,
            viewCount: 145,
            lastBoostedAt: nil,
            usageAmount: 1850,
            usageUnit: "kWh",
            ratePerUnit: 0.13,
            areaAverageUsage: 1400,
            areaMinUsage: 600,
            areaMaxUsage: 2800,
            planName: nil,
            additionalDetails: ["peakUsage": "2-7 PM weekdays"]
        )
    ]
}

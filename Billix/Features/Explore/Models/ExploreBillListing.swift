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

    /// Bill types shown in Bill Explorer (excludes rent and insurance)
    static var explorerTypes: [ExploreBillType] {
        [.electric, .gas, .water, .internet, .phone]
    }

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
    var categoryBillCount: Int = 10  // Number of bills in same category for comparison
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
    var dailyAverage: Double?      // e.g., 4.9 (kWh/day)
    var areaAverageUsage: Double?  // e.g., 1200 (for comparison)
    var areaMinUsage: Double?      // e.g., 400 (lowest in dataset)
    var areaMaxUsage: Double?      // e.g., 2500 (highest in dataset)

    // Provider-level stats (for k-anonymity)
    var providerBillCount: Int = 0
    var providerMinUsage: Double?
    var providerMaxUsage: Double?
    var providerMinRate: Double?
    var providerMaxRate: Double?
    var providerMinDailyAvg: Double?
    var providerMaxDailyAvg: Double?

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
            return "Lower than \(100 - percentile)% of Billix bills"
        } else if percentile >= 70 {
            return "Higher than \(percentile)% of Billix bills"
        } else {
            return "Around average for Billix bills"
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
        let calendar = Calendar.current
        let year = calendar.component(.year, from: lastUpdated)
        return String(year)
    }

    var locationDisplay: String {
        if !city.isEmpty {
            return "\(city), \(state)"
        }
        return state
    }

    var percentileDescription: String? {
        // Require minimum 5 bills in category to show percentile
        guard categoryBillCount >= 5 else { return nil }

        // Cap at 99% to avoid showing "100%"
        let cappedPercentile = min(percentile, 99)

        if cappedPercentile <= 25 {
            return "Lower than \(100 - cappedPercentile)% of \(categoryBillCount) Billix bills"
        } else if cappedPercentile >= 75 {
            return "Higher than \(cappedPercentile)% of \(categoryBillCount) Billix bills"
        } else {
            return "Around average of \(categoryBillCount) Billix bills"
        }
    }

    // MARK: - K-Anonymity Privacy Protection

    /// K-anonymity threshold - minimum bills needed from same provider+category+state
    static let kAnonymityThreshold = 5

    /// Whether this listing has enough similar bills to show exact values
    var meetsKAnonymity: Bool {
        providerBillCount >= Self.kAnonymityThreshold
    }

    /// Create a fuzzy range around a value (±10%, rounded to nearest bucket)
    private func fuzzyRange(for value: Double, roundTo: Double = 10) -> (min: Int, max: Int) {
        let buffer = value * 0.10  // 10% buffer
        let minVal = ((value - buffer) / roundTo).rounded(.down) * roundTo
        let maxVal = ((value + buffer) / roundTo).rounded(.up) * roundTo
        return (Int(max(0, minVal)), Int(maxVal))
    }

    // MARK: - Usage Display (K-Anonymity Aware)

    /// Usage display - exact or fuzzy based on k-anonymity
    var usageDisplayText: String? {
        guard let usage = usageAmount, let unit = usageUnit else { return nil }
        if meetsKAnonymity {
            return "\(Int(usage)) \(unit)"  // Exact: "146 kWh"
        } else {
            let range = fuzzyRange(for: usage, roundTo: 10)
            return "~\(range.min)-\(range.max) \(unit)"  // Fuzzy: "~130-160 kWh"
        }
    }

    /// Rate display - exact or fuzzy based on k-anonymity
    var rateDisplayText: String? {
        guard let rate = ratePerUnit, let unit = usageUnit else { return nil }
        if meetsKAnonymity {
            return String(format: "$%.2f/\(unit)", rate)  // Exact: "$0.29/kWh"
        } else {
            let minRate = rate * 0.90
            let maxRate = rate * 1.10
            return String(format: "~$%.2f-$%.2f/\(unit)", minRate, maxRate)  // Fuzzy: "~$0.26-$0.32/kWh"
        }
    }

    /// Daily average display - exact or fuzzy based on k-anonymity
    var dailyAvgDisplayText: String? {
        guard let unit = usageUnit else { return nil }
        // Calculate daily average from usage if not provided
        let dailyAvg = dailyAverage ?? (usageAmount.map { $0 / 30 })
        guard let avg = dailyAvg else { return nil }

        if meetsKAnonymity {
            return String(format: "%.1f \(unit)/day", avg)  // Exact: "4.9 kWh/day"
        } else {
            let range = fuzzyRange(for: avg, roundTo: 1)
            return "~\(range.min)-\(range.max) \(unit)/day"  // Fuzzy: "~4-6 kWh/day"
        }
    }

    var usagePercentageDiff: Double? {
        guard let usage = usageAmount, let avg = areaAverageUsage, avg > 0 else { return nil }
        return ((usage - avg) / avg) * 100
    }

    var usageComparisonText: String? {
        guard let diff = usagePercentageDiff else { return nil }
        let absDiff = abs(Int(diff))
        if diff < -5 {
            return "\(absDiff)% below Billix average"
        } else if diff > 5 {
            return "\(absDiff)% above Billix average"
        } else {
            return "Around Billix average"
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

// MARK: - Database Response Model

/// Codable struct to decode from `bill_explorer_listings` Supabase view
struct BillExplorerRow: Codable {
    let id: UUID
    let provider: String
    let amount: Double
    let subcategory: String
    let state: String
    let zipPrefix: String
    let postedDate: String
    let createdAt: String
    let usageMetrics: UsageMetrics?
    let confidenceScore: Int?
    let percentile: Int?

    // Provider-level stats (for k-anonymity)
    let providerBillCount: Int?
    let providerMinUsage: Double?
    let providerMaxUsage: Double?
    let providerMinRate: Double?
    let providerMaxRate: Double?
    let providerMinDailyAvg: Double?
    let providerMaxDailyAvg: Double?

    // Category-level stats (fallback)
    let categoryBillCount: Int?

    // Area amount stats
    let areaMinAmount: Double?
    let areaMaxAmount: Double?
    let areaAvgAmount: Double?

    // Area usage stats
    let areaMinUsage: Double?
    let areaMaxUsage: Double?
    let areaAvgUsage: Double?

    // Area rate stats
    let areaMinRate: Double?
    let areaMaxRate: Double?
    let areaAvgRate: Double?

    // Area daily avg stats
    let areaMinDailyAvg: Double?
    let areaMaxDailyAvg: Double?
    let areaAvgDailyAvg: Double?

    // Engagement
    let voteScore: Int
    let upvotes: Int
    let downvotes: Int

    struct UsageMetrics: Codable {
        let type: String?
        let usage: Double?
        let rate: Double?
        let dailyAvg: Double?
        let monthlyCost: Double?
        let tierRange: String?  // For water bills
        let planName: String?   // For internet/phone
        let linesCount: Int?    // For phone
        let planType: String?   // For phone
        let speedMbps: Int?     // For internet (download speed)
        let unit: String?       // For internet (GB for data usage)
        let package: String?    // For cable TV

        enum CodingKeys: String, CodingKey {
            case type, usage, rate, dailyAvg, monthlyCost, tierRange
            case planName, linesCount, planType
            case speedMbps = "speed_mbps"
            case unit, package
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, provider, amount, subcategory, state
        case zipPrefix = "zip_prefix"
        case postedDate = "posted_date"
        case createdAt = "created_at"
        case usageMetrics = "usage_metrics"
        case confidenceScore = "confidence_score"
        case percentile
        case providerBillCount = "provider_bill_count"
        case providerMinUsage = "provider_min_usage"
        case providerMaxUsage = "provider_max_usage"
        case providerMinRate = "provider_min_rate"
        case providerMaxRate = "provider_max_rate"
        case providerMinDailyAvg = "provider_min_daily_avg"
        case providerMaxDailyAvg = "provider_max_daily_avg"
        case categoryBillCount = "category_bill_count"
        case areaMinAmount = "area_min_amount"
        case areaMaxAmount = "area_max_amount"
        case areaAvgAmount = "area_avg_amount"
        case areaMinUsage = "area_min_usage"
        case areaMaxUsage = "area_max_usage"
        case areaAvgUsage = "area_avg_usage"
        case areaMinRate = "area_min_rate"
        case areaMaxRate = "area_max_rate"
        case areaAvgRate = "area_avg_rate"
        case areaMinDailyAvg = "area_min_daily_avg"
        case areaMaxDailyAvg = "area_max_daily_avg"
        case areaAvgDailyAvg = "area_avg_daily_avg"
        case voteScore = "vote_score"
        case upvotes, downvotes
    }
}

// MARK: - ExploreBillType Mapping

extension ExploreBillType {
    /// Map database subcategory to ExploreBillType
    static func from(subcategory: String) -> ExploreBillType {
        switch subcategory.lowercased() {
        case "electricity", "electric":
            return .electric
        case "natural_gas", "gas":
            return .gas
        case "water":
            return .water
        case "internet":
            return .internet
        case "phone", "mobile":
            return .phone
        case "rent":
            return .rent
        case "insurance", "auto_insurance", "home_insurance":
            return .insurance
        default:
            return .electric  // Default fallback
        }
    }

    /// Get the unit string for usage display
    var usageUnit: String {
        switch self {
        case .electric: return "kWh"
        case .gas: return "therms"
        case .water: return "gal"
        default: return ""
        }
    }
}

// MARK: - Initialize from Database Row

extension ExploreBillListing {
    /// Create ExploreBillListing from database row
    init(from row: BillExplorerRow) {
        self.id = row.id
        self.billType = ExploreBillType.from(subcategory: row.subcategory)
        self.provider = row.provider
        self.amount = row.amount
        self.billingPeriod = Self.formatBillingPeriod(from: row.postedDate)
        self.city = ""  // Not available in DB yet
        self.state = row.state

        // Household context not available from DB
        self.housingType = nil
        self.occupants = nil
        self.squareFootage = nil

        // Comparison data from aggregations
        self.percentile = row.percentile ?? 50
        self.categoryBillCount = row.categoryBillCount ?? 0
        self.historicalMin = row.areaMinAmount ?? row.amount * 0.8
        self.historicalMax = row.areaMaxAmount ?? row.amount * 1.2
        // Calculate trend based on percentile:
        // - Lower percentile (≤30) = bill is cheaper than most = "Decreased" (green, good)
        // - Mid percentile (31-69) = around average = "Stable" (gray)
        // - Higher percentile (≥70) = bill is more expensive than most = "Increased" (red, concerning)
        let pct = row.percentile ?? 50
        if pct <= 30 {
            self.trend = .decreased
        } else if pct >= 70 {
            self.trend = .increased
        } else {
            self.trend = .stable
        }
        self.volatility = .stable

        // User note not available
        self.userNote = nil

        // Trust signals
        self.isVerified = (row.confidenceScore ?? 0) >= 90
        self.lastUpdated = Self.parseDate(from: row.createdAt) ?? Date()
        self.anonymizedId = "User #\(abs(row.id.hashValue) % 10000)"

        // Legacy engagement (empty)
        self.reactions = [:]
        self.commentCount = 0

        // New engagement from DB
        self.voteScore = row.voteScore
        self.tipCount = 0  // Tips table not implemented yet
        self.viewCount = 0
        self.lastBoostedAt = nil

        // Usage data from usage_metrics JSONB
        self.usageAmount = row.usageMetrics?.usage
        self.usageUnit = billType.usageUnit
        self.ratePerUnit = row.usageMetrics?.rate
        self.dailyAverage = row.usageMetrics?.dailyAvg

        // Area stats from aggregations
        self.areaAverageUsage = row.areaAvgUsage
        self.areaMinUsage = row.areaMinUsage
        self.areaMaxUsage = row.areaMaxUsage

        // Provider-level stats (for k-anonymity)
        self.providerBillCount = row.providerBillCount ?? 0
        self.providerMinUsage = row.providerMinUsage
        self.providerMaxUsage = row.providerMaxUsage
        self.providerMinRate = row.providerMinRate
        self.providerMaxRate = row.providerMaxRate
        self.providerMinDailyAvg = row.providerMinDailyAvg
        self.providerMaxDailyAvg = row.providerMaxDailyAvg

        // Additional area stats (store in additionalDetails for now)
        var details: [String: String] = [:]
        if let minRate = row.areaMinRate, let maxRate = row.areaMaxRate {
            details["areaRateRange"] = String(format: "$%.2f-$%.2f", minRate, maxRate)
        }
        if let minDaily = row.areaMinDailyAvg, let maxDaily = row.areaMaxDailyAvg {
            details["areaDailyAvgRange"] = String(format: "%.1f-%.1f", minDaily, maxDaily)
        }
        if let dailyAvg = row.usageMetrics?.dailyAvg {
            details["dailyAvg"] = String(format: "%.1f", dailyAvg)
        }
        if let tierRange = row.usageMetrics?.tierRange {
            details["tier"] = tierRange
        }

        // Internet-specific: map speed_mbps to display format
        if let speedMbps = row.usageMetrics?.speedMbps {
            details["speed"] = "\(speedMbps) Mbps"
        }

        // Internet-specific: data usage
        if let dataUsage = row.usageMetrics?.usage, let unit = row.usageMetrics?.unit {
            details["dataUsage"] = "\(Int(dataUsage)) \(unit)"
        }

        // Cable TV: package name
        if let package = row.usageMetrics?.package {
            details["package"] = package
        }

        self.planName = row.usageMetrics?.planName ?? row.usageMetrics?.package
        self.additionalDetails = details.isEmpty ? nil : details
    }

    /// Parse ISO date string to Date
    private static func parseDate(from string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    /// Format posted date to billing period string
    private static func formatBillingPeriod(from dateString: String) -> String {
        guard let date = parseDate(from: dateString) ?? parseDateOnly(from: dateString) else {
            return "Recent"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }

    /// Parse date-only string (YYYY-MM-DD)
    private static func parseDateOnly(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}

// MARK: - Additional Computed Properties for Ranges

extension ExploreBillListing {
    /// Bill types that have metered usage (kWh, therms, gallons)
    /// Used to determine whether to show usage ranges, rate ranges, and usage comparison bars
    var isMeteredUtility: Bool {
        switch billType {
        case .electric, .gas, .water:
            return true
        case .internet, .phone, .rent, .insurance:
            return false
        }
    }

    /// Usage range display - uses provider-level if k-anonymity met, otherwise fuzzy range
    /// Only shown for metered utilities (electric, gas, water)
    var usageRangeText: String? {
        // Only show for metered utilities, not for internet/phone/rent/insurance
        guard isMeteredUtility else { return nil }
        guard let unit = usageUnit, !unit.isEmpty else { return nil }

        if meetsKAnonymity, let pMin = providerMinUsage, let pMax = providerMaxUsage {
            // Provider-specific range (safe to show exact)
            return "\(Int(pMin))-\(Int(pMax)) \(unit)"
        } else if let usage = usageAmount {
            // K-anonymity NOT met - show fuzzy range (±10%) to protect privacy
            let fuzzy = fuzzyRange(for: usage, roundTo: max(10, usage * 0.05))
            return "~\(fuzzy.min)-\(fuzzy.max) \(unit)"
        }
        return nil
    }

    /// Rate range display - uses provider-level if k-anonymity met, otherwise fuzzy range
    /// Only shown for metered utilities (electric, gas, water)
    var rateRangeText: String? {
        guard isMeteredUtility else { return nil }
        guard let unit = usageUnit, !unit.isEmpty else { return nil }

        if meetsKAnonymity, let pMin = providerMinRate, let pMax = providerMaxRate {
            // Provider-specific range (safe to show exact)
            return String(format: "$%.2f-$%.2f/\(unit)", pMin, pMax)
        } else if let rate = ratePerUnit {
            // K-anonymity NOT met - show fuzzy range (±10%)
            let minRate = rate * 0.90
            let maxRate = rate * 1.10
            return String(format: "~$%.2f-$%.2f/\(unit)", minRate, maxRate)
        }
        return nil
    }

    /// Daily average range display - uses provider-level if k-anonymity met, otherwise fuzzy range
    /// Only shown for metered utilities (electric, gas, water)
    var dailyAvgRangeText: String? {
        guard isMeteredUtility else { return nil }
        guard let unit = usageUnit, !unit.isEmpty else { return nil }

        if meetsKAnonymity, let pMin = providerMinDailyAvg, let pMax = providerMaxDailyAvg {
            // Provider-specific range (safe to show exact)
            return String(format: "%.1f-%.1f \(unit)/day", pMin, pMax)
        } else if let usage = usageAmount {
            // K-anonymity NOT met - show fuzzy range
            let dailyAvg = usage / 30
            let minAvg = dailyAvg * 0.90
            let maxAvg = dailyAvg * 1.10
            return String(format: "~%.0f-%.0f \(unit)/day", minAvg, maxAvg)
        }
        return nil
    }

    /// User's daily average display (k-anonymity aware - use dailyAvgDisplayText instead)
    var dailyAvgText: String? {
        return dailyAvgDisplayText
    }

    /// Amount range display (e.g., "$40-$80/mo")
    var amountRangeText: String? {
        return "$\(Int(historicalMin))-$\(Int(historicalMax))/mo"
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

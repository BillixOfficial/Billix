//
//  ExploreModels.swift
//  Billix
//
//  Created by Claude Code on 11/27/25.
//

import Foundation
import SwiftUI

// MARK: - Recession Simulator Models

/// Preset economic scenarios for stress testing
enum EconomicScenario: String, CaseIterable, Identifiable {
    case inflationMild = "Inflation 3%"
    case inflationHigh = "Inflation 5%"
    case inflationSevere = "Inflation 8%"
    case winterSpike = "Winter Energy Spike"
    case recession = "Recession: Job Loss"
    case rentIncrease = "Rent Up 10%"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .inflationMild, .inflationHigh, .inflationSevere: return "🪙"
        case .winterSpike: return "❄️"
        case .recession: return "📉"
        case .rentIncrease: return "📈"
        case .custom: return "⚙️"
        }
    }

    var description: String {
        switch self {
        case .inflationMild: return "Mild inflation scenario"
        case .inflationHigh: return "Elevated inflation pressure"
        case .inflationSevere: return "Severe inflation shock"
        case .winterSpike: return "Seasonal energy cost surge"
        case .recession: return "Economic downturn impact"
        case .rentIncrease: return "Rental market pressure"
        case .custom: return "Set your own parameters"
        }
    }

    /// Category-specific multipliers for this scenario
    var categoryImpacts: [BillCategoryType: Double] {
        switch self {
        case .inflationMild:
            return [.energy: 0.05, .rent: 0.03, .internet: 0.02, .mobile: 0.02, .insurance: 0.04, .streaming: 0.01]
        case .inflationHigh:
            return [.energy: 0.12, .rent: 0.05, .internet: 0.04, .mobile: 0.03, .insurance: 0.08, .streaming: 0.02]
        case .inflationSevere:
            return [.energy: 0.20, .rent: 0.08, .internet: 0.06, .mobile: 0.05, .insurance: 0.12, .streaming: 0.03]
        case .winterSpike:
            return [.energy: 0.35, .rent: 0.0, .internet: 0.0, .mobile: 0.0, .insurance: 0.0, .streaming: 0.0]
        case .recession:
            return [.energy: 0.08, .rent: 0.02, .internet: 0.05, .mobile: 0.03, .insurance: 0.10, .streaming: 0.0]
        case .rentIncrease:
            return [.energy: 0.0, .rent: 0.10, .internet: 0.0, .mobile: 0.0, .insurance: 0.05, .streaming: 0.0]
        case .custom:
            return [:]
        }
    }
}

/// Bill category type for stress testing
enum BillCategoryType: String, CaseIterable, Identifiable {
    case energy = "Energy"
    case rent = "Rent"
    case internet = "Internet"
    case mobile = "Mobile"
    case insurance = "Insurance"
    case streaming = "Streaming"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .energy: return "bolt.fill"
        case .rent: return "house.fill"
        case .internet: return "wifi"
        case .mobile: return "iphone"
        case .insurance: return "shield.fill"
        case .streaming: return "play.tv.fill"
        }
    }

    var color: Color {
        switch self {
        case .energy: return Color(hex: "#F59E0B")
        case .rent: return Color(hex: "#8B5CF6")
        case .internet: return Color(hex: "#3B82F6")
        case .mobile: return Color(hex: "#10B981")
        case .insurance: return Color(hex: "#EC4899")
        case .streaming: return Color(hex: "#EF4444")
        }
    }

    /// Volatility factor (higher = more sensitive to shocks)
    var volatility: Double {
        switch self {
        case .energy: return 1.5
        case .rent: return 0.8
        case .internet: return 0.4
        case .mobile: return 0.3
        case .insurance: return 0.7
        case .streaming: return 0.2
        }
    }
}

/// Result of a stress test calculation
struct StressTestResult: Identifiable {
    let id = UUID()
    let scenario: EconomicScenario
    let totalImpactMonthly: Double
    let totalImpactYearly: Double
    let categoryBreakdown: [CategoryImpact]
    let recommendations: [StressTestRecommendation]
}

/// Impact on a specific category
struct CategoryImpact: Identifiable {
    let id = UUID()
    let category: BillCategoryType
    let currentAmount: Double
    let projectedAmount: Double
    let impactAmount: Double
    let impactPercent: Double
}

/// Recommended action from stress test
struct StressTestRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let actionType: RecommendationAction
    let urgency: RecommendationUrgency
    let potentialSavings: Double?

    enum RecommendationAction: String {
        case lockRate = "lock_rate"
        case viewPlans = "view_plans"
        case setStrikePrice = "set_strike"
        case joinCluster = "join_cluster"
        case switchProvider = "switch"
    }

    enum RecommendationUrgency: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var color: Color {
            switch self {
            case .high: return Color(hex: "#EF4444")
            case .medium: return Color(hex: "#F59E0B")
            case .low: return Color(hex: "#10B981")
            }
        }
    }
}

// MARK: - Bill Heatmap Models

/// Pricing tier for heatmap visualization
enum PricingTier: String, CaseIterable {
    case low = "Low Cost Zone"
    case normal = "Normal Zone"
    case high = "High Cost Zone"
    case gouging = "Price Gouging"

    var color: Color {
        switch self {
        case .low: return Color(hex: "#22C55E")
        case .normal: return Color(hex: "#EAB308")
        case .high: return Color(hex: "#F97316")
        case .gouging: return Color(hex: "#EF4444")
        }
    }

    var description: String {
        switch self {
        case .low: return "Below market average"
        case .normal: return "Near market average"
        case .high: return "Above market average"
        case .gouging: return "Significantly overpriced"
        }
    }
}

/// A geographic zone with pricing data
struct HeatmapZone: Identifiable {
    let id = UUID()
    let zipCode: String
    let latitude: Double
    let longitude: Double
    let category: BillCategoryType
    let averagePrice: Double
    let marketAverage: Double
    let tier: PricingTier
    let residentCount: Int
    let nearbyDealsCount: Int

    var overchargePercent: Double {
        guard marketAverage > 0 else { return 0 }
        return ((averagePrice - marketAverage) / marketAverage) * 100
    }
}

/// A deal visible on the heatmap
struct HeatmapDeal: Identifiable {
    let id = UUID()
    let providerName: String
    let price: Double
    let grade: String
    let distance: Double
    let zipCode: String
    let blueprintId: UUID?
}

// MARK: - Make Me Move Models

/// A strike price order set by the user
struct StrikePriceOrder: Identifiable, Codable {
    let id: UUID
    let category: String
    let providerName: String?
    let currentPrice: Double
    let strikePrice: Double
    let constraints: [StrikePriceConstraint]
    let createdDate: Date
    var isActive: Bool
    var matchCount: Int
    var lastMatchDate: Date?

    init(
        id: UUID = UUID(),
        category: String,
        providerName: String? = nil,
        currentPrice: Double,
        strikePrice: Double,
        constraints: [StrikePriceConstraint] = [],
        createdDate: Date = Date(),
        isActive: Bool = true,
        matchCount: Int = 0,
        lastMatchDate: Date? = nil
    ) {
        self.id = id
        self.category = category
        self.providerName = providerName
        self.currentPrice = currentPrice
        self.strikePrice = strikePrice
        self.constraints = constraints
        self.createdDate = createdDate
        self.isActive = isActive
        self.matchCount = matchCount
        self.lastMatchDate = lastMatchDate
    }

    var savingsTarget: Double {
        currentPrice - strikePrice
    }

    var savingsTargetPercent: Double {
        guard currentPrice > 0 else { return 0 }
        return (savingsTarget / currentPrice) * 100
    }
}

/// Constraint for a strike price order
struct StrikePriceConstraint: Identifiable, Codable {
    let id: UUID
    let type: ConstraintType
    let value: String

    enum ConstraintType: String, Codable {
        case minSpeed = "min_speed"
        case maxContract = "max_contract"
        case provider = "provider"
        case noDataCap = "no_data_cap"
    }

    init(id: UUID = UUID(), type: ConstraintType, value: String) {
        self.id = id
        self.type = type
        self.value = value
    }
}

/// A match for a strike price order
struct StrikePriceMatch: Identifiable {
    let id = UUID()
    let orderId: UUID
    let dealTitle: String
    let providerName: String
    let price: Double
    let matchScore: Int
    let listingId: UUID
    let matchedDate: Date
}

// MARK: - Gouge Index Models

/// Provider ranking in the Gouge Index
struct ProviderRanking: Identifiable {
    let id = UUID()
    let rank: Int
    let providerName: String
    let providerLogo: String
    let category: BillCategoryType
    let region: String
    let overchargePercent: Double
    let recentPriceChange: Double
    let complaintsCount: Int
    let rating: GougeRating
    let typicalBillRange: ClosedRange<Double>

    enum GougeRating: String {
        case mostHated = "Most Hated"
        case overpriced = "Overpriced"
        case average = "Average"
        case goodValue = "Good Value"
        case bestValue = "Best Value"

        var color: Color {
            switch self {
            case .mostHated: return Color(hex: "#EF4444")
            case .overpriced: return Color(hex: "#F97316")
            case .average: return Color(hex: "#EAB308")
            case .goodValue: return Color(hex: "#22C55E")
            case .bestValue: return Color(hex: "#10B981")
            }
        }

        var icon: String {
            switch self {
            case .mostHated: return "hand.thumbsdown.fill"
            case .overpriced: return "exclamationmark.triangle.fill"
            case .average: return "minus.circle.fill"
            case .goodValue: return "checkmark.circle.fill"
            case .bestValue: return "star.fill"
            }
        }
    }
}

/// Monthly villain/hero highlight
struct GougeHighlight: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let providerName: String
    let providerLogo: String
    let metric: String
    let highlightType: HighlightType

    enum HighlightType: String {
        case mostHated = "Most Hated"
        case biggestSurge = "Biggest Surge"
        case bestSurprise = "Best Surprise"

        var color: Color {
            switch self {
            case .mostHated: return Color(hex: "#EF4444")
            case .biggestSurge: return Color(hex: "#F97316")
            case .bestSurprise: return Color(hex: "#22C55E")
            }
        }

        var icon: String {
            switch self {
            case .mostHated: return "flame.fill"
            case .biggestSurge: return "arrow.up.right.circle.fill"
            case .bestSurprise: return "gift.fill"
            }
        }
    }
}

// MARK: - Outage Bot Models

/// A provider connection for outage monitoring
struct OutageConnection: Identifiable, Codable {
    let id: UUID
    let providerName: String
    let providerLogo: String
    let category: String
    let zipCode: String
    var isMonitoring: Bool
    var lastOutageDate: Date?
    var lastClaimAmount: Double?
    var totalClaimed: Double
    var claimsCount: Int

    init(
        id: UUID = UUID(),
        providerName: String,
        providerLogo: String,
        category: String,
        zipCode: String,
        isMonitoring: Bool = true,
        lastOutageDate: Date? = nil,
        lastClaimAmount: Double? = nil,
        totalClaimed: Double = 0,
        claimsCount: Int = 0
    ) {
        self.id = id
        self.providerName = providerName
        self.providerLogo = providerLogo
        self.category = category
        self.zipCode = zipCode
        self.isMonitoring = isMonitoring
        self.lastOutageDate = lastOutageDate
        self.lastClaimAmount = lastClaimAmount
        self.totalClaimed = totalClaimed
        self.claimsCount = claimsCount
    }
}

/// An outage event
struct OutageEvent: Identifiable {
    let id = UUID()
    let providerName: String
    let zipCode: String
    let startTime: Date
    let endTime: Date?
    let durationHours: Double
    let affectedUsers: Int
    let status: OutageStatus

    enum OutageStatus: String {
        case active = "Active"
        case resolved = "Resolved"
        case claimPending = "Claim Pending"
        case claimSubmitted = "Claim Submitted"
        case creditReceived = "Credit Received"
    }
}

/// A credit claim from Outage Bot
struct OutageClaim: Identifiable, Codable {
    let id: UUID
    let providerName: String
    let outageDate: Date
    let durationHours: Double
    let claimAmount: Double
    let status: ClaimStatus
    let submittedDate: Date
    var resolvedDate: Date?

    enum ClaimStatus: String, Codable {
        case pending = "Pending"
        case submitted = "Submitted"
        case approved = "Approved"
        case denied = "Denied"

        var color: Color {
            switch self {
            case .pending: return Color(hex: "#EAB308")
            case .submitted: return Color(hex: "#3B82F6")
            case .approved: return Color(hex: "#22C55E")
            case .denied: return Color(hex: "#EF4444")
            }
        }
    }

    init(
        id: UUID = UUID(),
        providerName: String,
        outageDate: Date,
        durationHours: Double,
        claimAmount: Double,
        status: ClaimStatus = .pending,
        submittedDate: Date = Date(),
        resolvedDate: Date? = nil
    ) {
        self.id = id
        self.providerName = providerName
        self.outageDate = outageDate
        self.durationHours = durationHours
        self.claimAmount = claimAmount
        self.status = status
        self.submittedDate = submittedDate
        self.resolvedDate = resolvedDate
    }
}

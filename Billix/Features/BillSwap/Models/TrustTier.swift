//
//  TrustTier.swift
//  Billix
//
//  Bill Swap Trust Tier System
//

import Foundation

// MARK: - Trust Tier Enum

enum SwapTrustTier: String, Codable, CaseIterable {
    case T0_NEW = "T0_NEW"
    case T1_BASIC = "T1_BASIC"
    case T2_TRUSTED = "T2_TRUSTED"
    case T3_VERIFIED = "T3_VERIFIED"

    // MARK: - Tier Caps

    /// Maximum bill amount in cents for this tier
    var maxBillCents: Int {
        switch self {
        case .T0_NEW: return 10000      // $100
        case .T1_BASIC: return 20000    // $200
        case .T2_TRUSTED: return 50000  // $500
        case .T3_VERIFIED: return 100000 // $1000
        }
    }

    /// Maximum bill amount in dollars
    var maxBillDollars: Double {
        Double(maxBillCents) / 100.0
    }

    /// Formatted max bill amount (e.g., "$100")
    var formattedMaxBill: String {
        String(format: "$%.0f", maxBillDollars)
    }

    /// Maximum active swaps allowed
    var maxActiveSwaps: Int {
        switch self {
        case .T0_NEW: return 2
        case .T1_BASIC: return 4
        case .T2_TRUSTED: return 6
        case .T3_VERIFIED: return 8
        }
    }

    // MARK: - Requirements

    /// Completed swaps required to reach this tier
    var completedSwapsRequired: Int {
        switch self {
        case .T0_NEW: return 0
        case .T1_BASIC: return 5
        case .T2_TRUSTED: return 15
        case .T3_VERIFIED: return 30
        }
    }

    /// Success rate required (percentage)
    var successRateRequired: Double {
        switch self {
        case .T0_NEW, .T1_BASIC: return 0
        case .T2_TRUSTED: return 90.0
        case .T3_VERIFIED: return 95.0
        }
    }

    /// Whether ID verification is required
    var requiresIdVerification: Bool {
        self == .T3_VERIFIED
    }

    /// Whether one-sided assist is allowed
    var canOneSidedAssist: Bool {
        switch self {
        case .T0_NEW, .T1_BASIC: return false
        case .T2_TRUSTED, .T3_VERIFIED: return true
        }
    }

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .T0_NEW: return "Newcomer"
        case .T1_BASIC: return "Basic"
        case .T2_TRUSTED: return "Trusted"
        case .T3_VERIFIED: return "Verified"
        }
    }

    var icon: String {
        switch self {
        case .T0_NEW: return "person.crop.circle"
        case .T1_BASIC: return "star"
        case .T2_TRUSTED: return "star.fill"
        case .T3_VERIFIED: return "checkmark.seal.fill"
        }
    }

    var color: String {
        switch self {
        case .T0_NEW: return "#8B9A94"      // Gray
        case .T1_BASIC: return "#5B8A6B"    // Green
        case .T2_TRUSTED: return "#D4A843"  // Gold
        case .T3_VERIFIED: return "#5BA4D4" // Blue
        }
    }

    var tierNumber: Int {
        switch self {
        case .T0_NEW: return 0
        case .T1_BASIC: return 1
        case .T2_TRUSTED: return 2
        case .T3_VERIFIED: return 3
        }
    }
}

// MARK: - Trust Profile Model

struct TrustProfile: Identifiable, Codable {
    var id: UUID { userId }
    let userId: UUID
    var trustScore: Double
    var tier: SwapTrustTier
    var completedSwapsCount: Int
    var failedSwapsCount: Int
    var disputedAtFaultCount: Int
    var noShowCount: Int
    var activeSwapsCount: Int
    var currentStreak: Int
    var lastSwapDate: Date?
    var isIdVerified: Bool
    var successRate: Double
    var billixPointsBalance: Int
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case trustScore = "trust_score"
        case tier
        case completedSwapsCount = "completed_swaps_count"
        case failedSwapsCount = "failed_swaps_count"
        case disputedAtFaultCount = "disputed_at_fault_count"
        case noShowCount = "no_show_count"
        case activeSwapsCount = "active_swaps_count"
        case currentStreak = "current_streak"
        case lastSwapDate = "last_swap_date"
        case isIdVerified = "is_id_verified"
        case successRate = "success_rate"
        case billixPointsBalance = "billix_points_balance"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Can create a new swap based on active swap limit
    var canCreateSwap: Bool {
        activeSwapsCount < tier.maxActiveSwaps
    }

    /// Remaining swaps allowed
    var remainingSwapSlots: Int {
        max(0, tier.maxActiveSwaps - activeSwapsCount)
    }

    /// Can waive fee with points (500 points required)
    var canWaiveFee: Bool {
        billixPointsBalance >= 500
    }

    /// Progress to next tier (0.0 - 1.0)
    var progressToNextTier: Double {
        guard tier != .T3_VERIFIED else { return 1.0 }

        let nextTier: SwapTrustTier = {
            switch tier {
            case .T0_NEW: return .T1_BASIC
            case .T1_BASIC: return .T2_TRUSTED
            case .T2_TRUSTED: return .T3_VERIFIED
            case .T3_VERIFIED: return .T3_VERIFIED
            }
        }()

        let currentRequired = tier.completedSwapsRequired
        let nextRequired = nextTier.completedSwapsRequired
        let range = nextRequired - currentRequired

        guard range > 0 else { return 1.0 }

        let progress = Double(completedSwapsCount - currentRequired) / Double(range)
        return min(1.0, max(0.0, progress))
    }

    // MARK: - Validation

    /// Check if user can create a swap for a given amount
    func canSwapAmount(_ amountCents: Int) -> Bool {
        amountCents <= tier.maxBillCents
    }

    /// Check eligibility for one-sided assist
    func canOfferOneSidedAssist() -> Bool {
        tier.canOneSidedAssist
    }
}

// MARK: - Trust Score Constants

enum TrustScoreConstants {
    // Base changes
    static let completedSwapBase: Int = 10
    static let failedAtFaultBase: Int = -15
    static let noShowBase: Int = -25
    static let disputedAtFaultBase: Int = -20

    // Modifiers
    static let oneSidedModifier: Double = 0.7
    static let atFaultMultiplier: Double = 1.25

    // Points
    static let pointsPerCompletedSwap: Int = 100
    static let firstSwapOfDayBonus: Int = 50
    static let pointsToWaiveFee: Int = 500
}

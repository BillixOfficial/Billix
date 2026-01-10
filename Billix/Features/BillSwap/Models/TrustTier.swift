//
//  TrustTier.swift
//  Billix
//
//  Bill Swap Trust Tier System - 5 Tier, 0-1000 Point Scale
//

import Foundation

// MARK: - Trust Tier Enum (5 Tiers)

enum SwapTrustTier: String, Codable, CaseIterable {
    case T1_PROVISIONAL = "T1_PROVISIONAL"
    case T2_VERIFIED = "T2_VERIFIED"
    case T3_TRUSTED = "T3_TRUSTED"
    case T4_POWER = "T4_POWER"
    case T5_ELITE = "T5_ELITE"

    // MARK: - Tier Caps

    /// Minimum bill amount in cents ($20 for all tiers)
    var minBillCents: Int { 2000 }

    /// Maximum bill amount in cents for this tier
    var maxBillCents: Int {
        switch self {
        case .T1_PROVISIONAL: return 5000      // $50
        case .T2_VERIFIED: return 15000        // $150
        case .T3_TRUSTED: return 50000         // $500
        case .T4_POWER: return 150000          // $1,500
        case .T5_ELITE: return 1000000         // $10,000 (effectively no limit)
        }
    }

    /// Maximum bill amount in dollars
    var maxBillDollars: Double {
        Double(maxBillCents) / 100.0
    }

    /// Minimum bill amount in dollars
    var minBillDollars: Double {
        Double(minBillCents) / 100.0
    }

    /// Formatted max bill amount (e.g., "$50")
    var formattedMaxBill: String {
        if self == .T5_ELITE {
            return "No Limit"
        }
        return String(format: "$%.0f", maxBillDollars)
    }

    /// Formatted bill range (e.g., "$20-$50")
    var formattedBillRange: String {
        if self == .T5_ELITE {
            return "$20+"
        }
        return "$\(Int(minBillDollars))-$\(Int(maxBillDollars))"
    }

    /// Maximum active swaps allowed
    var maxActiveSwaps: Int {
        switch self {
        case .T1_PROVISIONAL: return 2
        case .T2_VERIFIED: return 4
        case .T3_TRUSTED: return 6
        case .T4_POWER: return 8
        case .T5_ELITE: return 10
        }
    }

    // MARK: - Requirements

    /// Minimum trust points required to reach this tier (0-1000 scale)
    var pointsRequired: Int {
        switch self {
        case .T1_PROVISIONAL: return 150
        case .T2_VERIFIED: return 350
        case .T3_TRUSTED: return 600
        case .T4_POWER: return 850
        case .T5_ELITE: return 950
        }
    }

    /// Completed swaps required to reach this tier
    var completedSwapsRequired: Int {
        switch self {
        case .T1_PROVISIONAL: return 0
        case .T2_VERIFIED: return 3
        case .T3_TRUSTED: return 8
        case .T4_POWER: return 20
        case .T5_ELITE: return 50
        }
    }

    /// Success rate required (percentage)
    var successRateRequired: Double {
        switch self {
        case .T1_PROVISIONAL, .T2_VERIFIED: return 0
        case .T3_TRUSTED: return 85.0
        case .T4_POWER: return 90.0
        case .T5_ELITE: return 95.0
        }
    }

    /// Whether ID verification is required
    var requiresIdVerification: Bool {
        switch self {
        case .T1_PROVISIONAL, .T2_VERIFIED, .T3_TRUSTED: return false
        case .T4_POWER, .T5_ELITE: return true
        }
    }

    /// Whether one-sided assist is allowed
    var canOneSidedAssist: Bool {
        switch self {
        case .T1_PROVISIONAL, .T2_VERIFIED: return false
        case .T3_TRUSTED, .T4_POWER, .T5_ELITE: return true
        }
    }

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .T1_PROVISIONAL: return "Provisional"
        case .T2_VERIFIED: return "Verified"
        case .T3_TRUSTED: return "Trusted"
        case .T4_POWER: return "Power Swapper"
        case .T5_ELITE: return "Elite"
        }
    }

    var icon: String {
        switch self {
        case .T1_PROVISIONAL: return "person.crop.circle"
        case .T2_VERIFIED: return "checkmark.circle"
        case .T3_TRUSTED: return "star.fill"
        case .T4_POWER: return "bolt.fill"
        case .T5_ELITE: return "crown.fill"
        }
    }

    var color: String {
        switch self {
        case .T1_PROVISIONAL: return "#8B9A94"  // Gray
        case .T2_VERIFIED: return "#5B8A6B"     // Green
        case .T3_TRUSTED: return "#D4A843"      // Gold
        case .T4_POWER: return "#9B59B6"        // Purple
        case .T5_ELITE: return "#E74C3C"        // Red/Orange
        }
    }

    var tierNumber: Int {
        switch self {
        case .T1_PROVISIONAL: return 1
        case .T2_VERIFIED: return 2
        case .T3_TRUSTED: return 3
        case .T4_POWER: return 4
        case .T5_ELITE: return 5
        }
    }

    /// Next tier (nil if already at max)
    var nextTier: SwapTrustTier? {
        switch self {
        case .T1_PROVISIONAL: return .T2_VERIFIED
        case .T2_VERIFIED: return .T3_TRUSTED
        case .T3_TRUSTED: return .T4_POWER
        case .T4_POWER: return .T5_ELITE
        case .T5_ELITE: return nil
        }
    }

    /// Calculate tier from points and completed swaps
    static func tierFor(points: Int, completedSwaps: Int, successRate: Double, isIdVerified: Bool) -> SwapTrustTier {
        // Check tiers from highest to lowest
        if points >= T5_ELITE.pointsRequired &&
           completedSwaps >= T5_ELITE.completedSwapsRequired &&
           successRate >= T5_ELITE.successRateRequired &&
           isIdVerified {
            return .T5_ELITE
        }
        if points >= T4_POWER.pointsRequired &&
           completedSwaps >= T4_POWER.completedSwapsRequired &&
           successRate >= T4_POWER.successRateRequired &&
           isIdVerified {
            return .T4_POWER
        }
        if points >= T3_TRUSTED.pointsRequired &&
           completedSwaps >= T3_TRUSTED.completedSwapsRequired &&
           successRate >= T3_TRUSTED.successRateRequired {
            return .T3_TRUSTED
        }
        if points >= T2_VERIFIED.pointsRequired &&
           completedSwaps >= T2_VERIFIED.completedSwapsRequired {
            return .T2_VERIFIED
        }
        return .T1_PROVISIONAL
    }
}

// MARK: - Trust Profile Model

struct TrustProfile: Identifiable, Codable {
    var id: UUID { userId }
    let userId: UUID
    var trustScore: Int  // 0-1000 scale
    var tier: SwapTrustTier
    var completedSwapsCount: Int
    var failedSwapsCount: Int
    var disputedAtFaultCount: Int
    var noShowCount: Int
    var activeSwapsCount: Int
    var currentStreak: Int
    var consecutiveSuccessfulSwaps: Int
    var lastSwapDate: Date?
    var isIdVerified: Bool
    var hasGovIdVerification: Bool
    var hasBankLinkVerification: Bool
    var hasWorkEmailVerification: Bool
    var successRate: Double
    var billixPointsBalance: Int
    var displayName: String?
    var handle: String?
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
        case consecutiveSuccessfulSwaps = "consecutive_successful_swaps"
        case lastSwapDate = "last_swap_date"
        case isIdVerified = "is_id_verified"
        case hasGovIdVerification = "has_gov_id_verification"
        case hasBankLinkVerification = "has_bank_link_verification"
        case hasWorkEmailVerification = "has_work_email_verification"
        case successRate = "success_rate"
        case billixPointsBalance = "billix_points_balance"
        case displayName = "display_name"
        case handle
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

    /// Maximum one-sided swap amount (50% of trust score value)
    var maxOneSidedSwapCents: Int {
        guard tier.canOneSidedAssist else { return 0 }
        // Trust score maps roughly to dollars: 1000 points = $1000 max
        return trustScore * 50  // 50% of trust score in cents
    }

    /// Formatted max one-sided swap amount
    var formattedMaxOneSidedSwap: String {
        String(format: "$%.0f", Double(maxOneSidedSwapCents) / 100.0)
    }

    /// Progress to next tier (0.0 - 1.0) based on points
    var progressToNextTier: Double {
        guard let nextTier = tier.nextTier else { return 1.0 }

        let currentRequired = tier.pointsRequired
        let nextRequired = nextTier.pointsRequired
        let range = nextRequired - currentRequired

        guard range > 0 else { return 1.0 }

        let progress = Double(trustScore - currentRequired) / Double(range)
        return min(1.0, max(0.0, progress))
    }

    /// Points needed to reach next tier
    var pointsToNextTier: Int {
        guard let nextTier = tier.nextTier else { return 0 }
        return max(0, nextTier.pointsRequired - trustScore)
    }

    /// Swaps needed to reach next tier
    var swapsToNextTier: Int {
        guard let nextTier = tier.nextTier else { return 0 }
        return max(0, nextTier.completedSwapsRequired - completedSwapsCount)
    }

    /// Total verifications completed
    var verificationsCompleted: Int {
        var count = 0
        if hasGovIdVerification { count += 1 }
        if hasBankLinkVerification { count += 1 }
        if hasWorkEmailVerification { count += 1 }
        return count
    }

    // MARK: - Validation

    /// Check if user can create a swap for a given amount
    func canSwapAmount(_ amountCents: Int) -> Bool {
        amountCents >= tier.minBillCents && amountCents <= tier.maxBillCents
    }

    /// Check eligibility for one-sided assist
    func canOfferOneSidedAssist() -> Bool {
        tier.canOneSidedAssist
    }

    /// Check if one-sided swap amount is within limit
    func canRequestOneSidedSwap(amountCents: Int) -> Bool {
        guard tier.canOneSidedAssist else { return false }
        return amountCents <= maxOneSidedSwapCents
    }

    // MARK: - Default Profile

    static func defaultProfile(userId: UUID) -> TrustProfile {
        TrustProfile(
            userId: userId,
            trustScore: 150,
            tier: .T1_PROVISIONAL,
            completedSwapsCount: 0,
            failedSwapsCount: 0,
            disputedAtFaultCount: 0,
            noShowCount: 0,
            activeSwapsCount: 0,
            currentStreak: 0,
            consecutiveSuccessfulSwaps: 0,
            lastSwapDate: nil,
            isIdVerified: false,
            hasGovIdVerification: false,
            hasBankLinkVerification: false,
            hasWorkEmailVerification: false,
            successRate: 0,
            billixPointsBalance: 0,
            displayName: nil,
            handle: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Trust Score Constants (0-1000 Scale)

enum TrustScoreConstants {
    // Starting score after basic signup
    static let startingScore: Int = 150

    // Verification bonuses (one-time)
    static let govIdVerificationBonus: Int = 100
    static let bankLinkVerificationBonus: Int = 100
    static let workEmailVerificationBonus: Int = 50

    // Activity points
    static let pointsPerDollarSwapped: Double = 0.1  // Per $1 swapped
    static let onTimePaybackBonus: Int = 25
    static let earlyBirdBonus: Int = 10  // Payment within 1 hour
    static let streakBonus: Int = 50     // 5 swaps in a row

    // Trust score changes
    static let completedSwapBase: Int = 15
    static let failedAtFaultBase: Int = -25
    static let noShowBase: Int = -50
    static let disputedAtFaultBase: Int = -35

    // Modifiers
    static let oneSidedModifier: Double = 1.5  // Higher risk = higher reward
    static let atFaultMultiplier: Double = 1.25

    // Billix Points (separate from trust score)
    static let billixPointsPerCompletedSwap: Int = 100
    static let firstSwapOfDayBonus: Int = 50
    static let pointsToWaiveFee: Int = 500

    // Streak milestones
    static let streakMilestones: [Int] = [5, 10, 25, 50]

    // Time thresholds
    static let earlyBirdThresholdMinutes: Int = 60
}

// MARK: - Verification Type

enum VerificationType: String, Codable {
    case govId = "GOV_ID"
    case bankLink = "BANK_LINK"
    case workEmail = "WORK_EMAIL"

    var pointsAwarded: Int {
        switch self {
        case .govId: return TrustScoreConstants.govIdVerificationBonus
        case .bankLink: return TrustScoreConstants.bankLinkVerificationBonus
        case .workEmail: return TrustScoreConstants.workEmailVerificationBonus
        }
    }

    var displayName: String {
        switch self {
        case .govId: return "Government ID"
        case .bankLink: return "Bank Account"
        case .workEmail: return "Work Email"
        }
    }

    var icon: String {
        switch self {
        case .govId: return "person.text.rectangle"
        case .bankLink: return "building.columns"
        case .workEmail: return "envelope.badge.shield.half.filled"
        }
    }
}

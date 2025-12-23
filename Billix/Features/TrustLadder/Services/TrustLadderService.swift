//
//  TrustLadderService.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Service for managing Trust Ladder user status, tiers, and progression
//  Updated 12/23/24 to integrate Billix Score system
//

import Foundation
import Supabase
import SwiftUI

// MARK: - Codable Structs for Supabase

private struct TrustStatusInsert: Codable {
    let userId: String
    let currentTier: Int
    let trustPoints: Int
    let successfulSwapsCurrentTier: Int
    let totalSuccessfulSwaps: Int
    let totalFailedSwaps: Int
    let ghostCount: Int
    let isBanned: Bool
    let verificationStatus: VerificationStatusFlags
    let averageRating: Double
    let totalRatingsReceived: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case currentTier = "current_tier"
        case trustPoints = "trust_points"
        case successfulSwapsCurrentTier = "successful_swaps_current_tier"
        case totalSuccessfulSwaps = "total_successful_swaps"
        case totalFailedSwaps = "total_failed_swaps"
        case ghostCount = "ghost_count"
        case isBanned = "is_banned"
        case verificationStatus = "verification_status"
        case averageRating = "average_rating"
        case totalRatingsReceived = "total_ratings_received"
    }
}

private struct VerificationUpdate: Codable {
    let verificationStatus: VerificationStatusFlags
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case verificationStatus = "verification_status"
        case updatedAt = "updated_at"
    }
}

private struct TrustPointsUpdate: Codable {
    let trustPoints: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case trustPoints = "trust_points"
        case updatedAt = "updated_at"
    }
}

private struct SuccessfulSwapUpdate: Codable {
    let successfulSwapsCurrentTier: Int
    let totalSuccessfulSwaps: Int
    let trustPoints: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case successfulSwapsCurrentTier = "successful_swaps_current_tier"
        case totalSuccessfulSwaps = "total_successful_swaps"
        case trustPoints = "trust_points"
        case updatedAt = "updated_at"
    }
}

private struct FailedSwapUpdate: Codable {
    let totalFailedSwaps: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case totalFailedSwaps = "total_failed_swaps"
        case updatedAt = "updated_at"
    }
}

private struct GhostUpdateSimple: Codable {
    let ghostCount: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case ghostCount = "ghost_count"
        case updatedAt = "updated_at"
    }
}

private struct GhostBanUpdate: Codable {
    let ghostCount: Int
    let isBanned: Bool
    let banReason: String
    let bannedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case ghostCount = "ghost_count"
        case isBanned = "is_banned"
        case banReason = "ban_reason"
        case bannedAt = "banned_at"
        case updatedAt = "updated_at"
    }
}

private struct RatingUpdateData: Codable {
    let averageRating: Double
    let totalRatingsReceived: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case averageRating = "average_rating"
        case totalRatingsReceived = "total_ratings_received"
        case updatedAt = "updated_at"
    }
}

private struct TierGraduationUpdate: Codable {
    let currentTier: Int
    let successfulSwapsCurrentTier: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case currentTier = "current_tier"
        case successfulSwapsCurrentTier = "successful_swaps_current_tier"
        case updatedAt = "updated_at"
    }
}

private struct DeviceIdUpdate: Codable {
    let deviceIds: [String]
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case deviceIds = "device_ids"
        case updatedAt = "updated_at"
    }
}

// MARK: - Errors

enum TrustLadderError: LocalizedError {
    case notAuthenticated
    case statusNotFound
    case alreadyMaxTier
    case verificationRequired
    case insufficientSwaps
    case insufficientRating
    case userBanned
    case updateFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .statusNotFound:
            return "Trust status not found"
        case .alreadyMaxTier:
            return "You're already at the highest tier"
        case .verificationRequired:
            return "Additional verification required for this tier"
        case .insufficientSwaps:
            return "Complete more swaps to unlock this tier"
        case .insufficientRating:
            return "Your rating is too low to progress"
        case .userBanned:
            return "Your account has been suspended"
        case .updateFailed:
            return "Failed to update trust status"
        }
    }
}

// MARK: - Trust Ladder Service

@MainActor
class TrustLadderService: ObservableObject {

    // MARK: - Singleton
    static let shared = TrustLadderService()

    // MARK: - Published Properties
    @Published var userTrustStatus: UserTrustStatus?
    @Published var isLoading = false
    @Published var error: TrustLadderError?

    // MARK: - Billix Score Integration
    @Published var billixScore: Int = 0
    @Published var badgeLevel: BillixBadgeLevel = .newcomer

    /// Reference to Billix Score Service
    private var scoreService: BillixScoreService {
        BillixScoreService.shared
    }

    /// Reference to Subscription Service
    private var subscriptionService: SubscriptionService {
        SubscriptionService.shared
    }

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // MARK: - Initialization
    private init() {
        // Observe Billix Score changes
        Task {
            await syncBillixScore()
        }
    }

    // MARK: - Billix Score Sync

    /// Syncs Billix Score from BillixScoreService
    func syncBillixScore() async {
        await scoreService.loadScore()
        self.billixScore = scoreService.overallScore
        self.badgeLevel = scoreService.badgeLevel
    }

    /// Gets combined trust info (tier + score)
    var combinedTrustInfo: CombinedTrustInfo? {
        guard let status = userTrustStatus else { return nil }
        return CombinedTrustInfo(
            tier: status.tier,
            billixScore: billixScore,
            badgeLevel: badgeLevel,
            subscriptionTier: subscriptionService.currentTier,
            trustPoints: status.trustPoints,
            completedSwaps: status.totalSuccessfulSwaps
        )
    }

    // MARK: - Fetch Trust Status

    /// Fetches the current user's trust status from Supabase
    func fetchUserTrustStatus() async throws -> UserTrustStatus {
        guard let session = try? await supabase.auth.session else {
            throw TrustLadderError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let status: UserTrustStatus = try await supabase
                .from("user_trust_status")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .single()
                .execute()
                .value

            self.userTrustStatus = status

            if status.isBanned {
                throw TrustLadderError.userBanned
            }

            return status
        } catch let error as PostgrestError {
            // Check if user doesn't have a trust status yet
            if error.code == "PGRST116" { // No rows returned
                throw TrustLadderError.statusNotFound
            }
            throw error
        }
    }

    /// Fetches trust status or initializes it if not found
    func fetchOrInitializeTrustStatus() async throws -> UserTrustStatus {
        do {
            return try await fetchUserTrustStatus()
        } catch TrustLadderError.statusNotFound {
            try await initializeTrustStatus()
            return try await fetchUserTrustStatus()
        }
    }

    // MARK: - Initialize Trust Status

    /// Creates initial trust status for a new user
    func initializeTrustStatus() async throws {
        guard let session = try? await supabase.auth.session else {
            throw TrustLadderError.notAuthenticated
        }

        // Check if email is verified (from auth)
        let emailVerified = session.user.emailConfirmedAt != nil

        let verificationStatus = VerificationStatusFlags(
            email: emailVerified,
            phone: false,
            govIdVerified: false
        )

        let insertData = TrustStatusInsert(
            userId: session.user.id.uuidString,
            currentTier: 1,
            trustPoints: 0,
            successfulSwapsCurrentTier: 0,
            totalSuccessfulSwaps: 0,
            totalFailedSwaps: 0,
            ghostCount: 0,
            isBanned: false,
            verificationStatus: verificationStatus,
            averageRating: 5.0,
            totalRatingsReceived: 0
        )

        try await supabase
            .from("user_trust_status")
            .insert(insertData)
            .execute()
    }

    // MARK: - Update Verification Status

    /// Updates phone verification status
    func updatePhoneVerification(verified: Bool) async throws {
        guard let status = userTrustStatus else {
            throw TrustLadderError.statusNotFound
        }

        var newVerification = status.verificationStatus
        newVerification.phone = verified

        try await updateVerificationStatus(newVerification)
    }

    /// Updates government ID verification status
    func updateGovIdVerification(verified: Bool) async throws {
        guard let status = userTrustStatus else {
            throw TrustLadderError.statusNotFound
        }

        var newVerification = status.verificationStatus
        newVerification.govIdVerified = verified

        try await updateVerificationStatus(newVerification)
    }

    private func updateVerificationStatus(_ verification: VerificationStatusFlags) async throws {
        guard let status = userTrustStatus else {
            throw TrustLadderError.statusNotFound
        }

        let updateData = VerificationUpdate(
            verificationStatus: verification,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("user_trust_status")
            .update(updateData)
            .eq("user_id", value: status.userId.uuidString)
            .execute()

        // Refresh status
        _ = try await fetchUserTrustStatus()
    }

    // MARK: - Award Trust Points

    /// Awards trust points to the user
    func awardTrustPoints(_ points: Int, reason: String) async throws {
        guard let status = userTrustStatus else {
            throw TrustLadderError.statusNotFound
        }

        let updateData = TrustPointsUpdate(
            trustPoints: status.trustPoints + points,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("user_trust_status")
            .update(updateData)
            .eq("user_id", value: status.userId.uuidString)
            .execute()

        // Refresh status
        _ = try await fetchUserTrustStatus()
    }

    // MARK: - Record Successful Swap

    /// Records a successful swap completion
    func recordSuccessfulSwap(swapId: UUID, trustPointsEarned: Int = 50, wasOnTime: Bool = true) async throws {
        guard let status = userTrustStatus else {
            throw TrustLadderError.statusNotFound
        }

        let updateData = SuccessfulSwapUpdate(
            successfulSwapsCurrentTier: status.successfulSwapsCurrentTier + 1,
            totalSuccessfulSwaps: status.totalSuccessfulSwaps + 1,
            trustPoints: status.trustPoints + trustPointsEarned,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("user_trust_status")
            .update(updateData)
            .eq("user_id", value: status.userId.uuidString)
            .execute()

        // Update Billix Score
        await scoreService.recordSwapCompleted(swapId: swapId, wasOnTime: wasOnTime)
        await syncBillixScore()

        // Refresh and check for auto-graduation
        let updatedStatus = try await fetchUserTrustStatus()

        // Check if user can graduate
        if updatedStatus.canGraduate {
            _ = try? await graduateToNextTier()
        }

        // Check for consistency streak
        await scoreService.checkConsistencyStreak()
    }

    // MARK: - Record Failed Swap / Ghost

    /// Records a failed swap
    func recordFailedSwap(swapId: UUID, wasGhost: Bool = false) async throws {
        guard let status = userTrustStatus else {
            throw TrustLadderError.statusNotFound
        }

        let updateData = FailedSwapUpdate(
            totalFailedSwaps: status.totalFailedSwaps + 1,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("user_trust_status")
            .update(updateData)
            .eq("user_id", value: status.userId.uuidString)
            .execute()

        // Update Billix Score
        await scoreService.recordSwapFailed(swapId: swapId, wasGhost: wasGhost)
        await syncBillixScore()

        _ = try await fetchUserTrustStatus()
    }

    /// Records a ghost incident
    func recordGhost(swapId: UUID) async throws {
        guard let status = userTrustStatus else {
            throw TrustLadderError.statusNotFound
        }

        let newGhostCount = status.ghostCount + 1
        let timestamp = ISO8601DateFormatter().string(from: Date())

        // Ban user if they ghost 3 times
        let shouldBan = newGhostCount >= 3

        if shouldBan {
            let updateData = GhostBanUpdate(
                ghostCount: newGhostCount,
                isBanned: true,
                banReason: "Exceeded ghost limit (3)",
                bannedAt: timestamp,
                updatedAt: timestamp
            )
            try await supabase
                .from("user_trust_status")
                .update(updateData)
                .eq("user_id", value: status.userId.uuidString)
                .execute()
        } else {
            let updateData = GhostUpdateSimple(
                ghostCount: newGhostCount,
                updatedAt: timestamp
            )
            try await supabase
                .from("user_trust_status")
                .update(updateData)
                .eq("user_id", value: status.userId.uuidString)
                .execute()
        }

        // Update Billix Score with ghost incident
        await scoreService.recordSwapFailed(swapId: swapId, wasGhost: true)
        await syncBillixScore()

        _ = try await fetchUserTrustStatus()
    }

    // MARK: - Update Rating

    /// Updates the user's average rating after a swap
    func updateRating(swapId: UUID, newRating: Int) async throws {
        guard let status = userTrustStatus else {
            throw TrustLadderError.statusNotFound
        }

        let totalRatings = status.totalRatingsReceived + 1
        let currentSum = status.averageRating * Double(status.totalRatingsReceived)
        let newAverage = (currentSum + Double(newRating)) / Double(totalRatings)

        let updateData = RatingUpdateData(
            averageRating: newAverage,
            totalRatingsReceived: totalRatings,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("user_trust_status")
            .update(updateData)
            .eq("user_id", value: status.userId.uuidString)
            .execute()

        // Update Billix Score with rating
        await scoreService.recordRatingReceived(swapId: swapId, rating: newRating)
        await syncBillixScore()

        _ = try await fetchUserTrustStatus()
    }

    // MARK: - Screenshot Verification

    /// Records screenshot verification result for Billix Score
    func recordScreenshotVerification(swapId: UUID, wasVerified: Bool) async {
        await scoreService.recordScreenshotVerification(swapId: swapId, wasVerified: wasVerified)
        await syncBillixScore()
    }

    // MARK: - Tier Graduation

    /// Attempts to graduate the user to the next tier
    func graduateToNextTier() async throws -> TrustTier {
        guard let status = userTrustStatus else {
            throw TrustLadderError.statusNotFound
        }

        let currentTier = status.tier

        // Check if already at max tier
        guard let nextTier = currentTier.nextTier else {
            throw TrustLadderError.alreadyMaxTier
        }

        // Check swap requirements
        if let requiredSwaps = currentTier.requiredSwapsToGraduate {
            guard status.successfulSwapsCurrentTier >= requiredSwaps else {
                throw TrustLadderError.insufficientSwaps
            }
        }

        // Check rating requirements (for Tier 1 -> 2)
        if let requiredRating = currentTier.requiredRating {
            guard status.averageRating >= requiredRating else {
                throw TrustLadderError.insufficientRating
            }
        }

        // Check verification requirements
        guard status.verificationStatus.meetsRequirements(for: nextTier) else {
            throw TrustLadderError.verificationRequired
        }

        // Perform graduation
        let updateData = TierGraduationUpdate(
            currentTier: nextTier.rawValue,
            successfulSwapsCurrentTier: 0, // Reset for new tier
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("user_trust_status")
            .update(updateData)
            .eq("user_id", value: status.userId.uuidString)
            .execute()

        // Refresh status
        _ = try await fetchUserTrustStatus()

        return nextTier
    }

    // MARK: - Check Eligibility

    /// Checks if user is eligible to swap a bill of given amount
    func canSwapAmount(_ amount: Double) -> Bool {
        guard let status = userTrustStatus else { return false }
        return amount <= status.tier.maxAmount
    }

    /// Checks if user can swap a particular bill category
    func canSwapCategory(_ category: SwapBillCategory) -> Bool {
        guard let status = userTrustStatus else { return false }
        return category.tier.rawValue <= status.currentTier
    }

    /// Gets available categories for current user
    func availableCategories() -> [SwapBillCategory] {
        guard let status = userTrustStatus else { return [] }
        return SwapBillCategory.availableCategories(upToTier: status.tier)
    }

    /// Gets locked categories that require higher tier
    func lockedCategories() -> [(category: SwapBillCategory, requiredTier: TrustTier)] {
        guard let status = userTrustStatus else {
            return SwapBillCategory.allCases.map { ($0, $0.tier) }
        }

        return SwapBillCategory.allCases
            .filter { $0.tier.rawValue > status.currentTier }
            .map { ($0, $0.tier) }
    }

    // MARK: - Device Tracking

    /// Adds a device ID to the user's tracked devices
    func addDeviceId(_ deviceId: String) async throws {
        guard let status = userTrustStatus else {
            throw TrustLadderError.statusNotFound
        }

        var deviceIds = status.deviceIds
        if !deviceIds.contains(deviceId) {
            deviceIds.append(deviceId)
        }

        let updateData = DeviceIdUpdate(
            deviceIds: deviceIds,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("user_trust_status")
            .update(updateData)
            .eq("user_id", value: status.userId.uuidString)
            .execute()

        _ = try await fetchUserTrustStatus()
    }

    // MARK: - Fetch Tier Info

    /// Fetches all tier definitions from the database
    func fetchTierInfo() async throws -> [TrustTierInfo] {
        let tiers: [TrustTierInfo] = try await supabase
            .from("trust_tiers")
            .select()
            .order("tier_number")
            .execute()
            .value

        return tiers
    }

    // MARK: - Feature Access

    /// Checks if user has access to a premium feature
    func hasFeatureAccess(_ feature: PremiumFeature) -> Bool {
        subscriptionService.hasAccess(to: feature)
    }

    /// Gets the user's effective trust level (considering both tier and score)
    var effectiveTrustLevel: EffectiveTrustLevel {
        guard let status = userTrustStatus else {
            return EffectiveTrustLevel(
                displayName: "New User",
                color: .gray,
                canSwap: false,
                maxAmount: 0
            )
        }

        return EffectiveTrustLevel(
            displayName: "\(status.tier.displayName) • \(badgeLevel.displayName)",
            color: badgeLevel.color,
            canSwap: !status.isBanned,
            maxAmount: status.tier.maxAmount
        )
    }
}

// MARK: - Combined Trust Info

/// Combined trust information from multiple sources
struct CombinedTrustInfo {
    let tier: TrustTier
    let billixScore: Int
    let badgeLevel: BillixBadgeLevel
    let subscriptionTier: BillixSubscriptionTier
    let trustPoints: Int
    let completedSwaps: Int

    var displaySummary: String {
        "\(tier.displayName) • \(badgeLevel.displayName) • \(billixScore) pts"
    }

    var canAccessPremiumFeatures: Bool {
        subscriptionTier != .free
    }
}

// MARK: - Effective Trust Level

/// Effective trust level combining tier and badge
struct EffectiveTrustLevel {
    let displayName: String
    let color: Color
    let canSwap: Bool
    let maxAmount: Double
}

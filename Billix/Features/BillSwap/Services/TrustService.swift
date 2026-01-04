//
//  TrustService.swift
//  Billix
//
//  Bill Swap Trust Profile Service
//

import Foundation
import Supabase

// MARK: - Private Codable Payloads

private struct RecordNoShowPayload: Codable {
    let noShowCount: String
    let currentStreak: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case noShowCount = "no_show_count"
        case currentStreak = "current_streak"
        case updatedAt = "updated_at"
    }
}

private struct UpdateCompletedSwapStatsPayload: Codable {
    let completedSwapsCount: String
    let lastSwapDate: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case completedSwapsCount = "completed_swaps_count"
        case lastSwapDate = "last_swap_date"
        case updatedAt = "updated_at"
    }
}

private struct UpdateFailedSwapStatsPayload: Codable {
    let failedSwapsCount: String
    let currentStreak: Int
    let disputedAtFaultCount: String?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case failedSwapsCount = "failed_swaps_count"
        case currentStreak = "current_streak"
        case disputedAtFaultCount = "disputed_at_fault_count"
        case updatedAt = "updated_at"
    }
}

private struct ApplyTrustDeltaParams: Codable {
    let pUserId: String
    let pBaseChange: Int
    let pSwapAmountCents: Int
    let pIsOneSided: Bool
    let pIsSuccess: Bool
    let pIsAtFault: Bool

    enum CodingKeys: String, CodingKey {
        case pUserId = "p_user_id"
        case pBaseChange = "p_base_change"
        case pSwapAmountCents = "p_swap_amount_cents"
        case pIsOneSided = "p_is_one_sided"
        case pIsSuccess = "p_is_success"
        case pIsAtFault = "p_is_at_fault"
    }
}

@MainActor
class TrustService: ObservableObject {
    static let shared = TrustService()

    private let supabase = SupabaseService.shared.client

    @Published var currentProfile: TrustProfile?
    @Published var isLoading = false
    @Published var error: Error?

    private init() {}

    // MARK: - Fetch Profile

    /// Fetch trust profile for a user
    func fetchProfile(userId: UUID) async throws -> TrustProfile {
        let response: TrustProfile = try await supabase
            .from("trust_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return response
    }

    /// Fetch current user's trust profile
    func fetchCurrentUserProfile() async throws -> TrustProfile {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await fetchProfile(userId: userId)
            currentProfile = profile
            return profile
        } catch {
            // Profile might not exist yet, create it
            try await ensureProfileExists(userId: userId)
            let profile = try await fetchProfile(userId: userId)
            currentProfile = profile
            return profile
        }
    }

    // MARK: - Ensure Profile Exists

    /// Create trust profile if it doesn't exist
    func ensureProfileExists(userId: UUID) async throws {
        try await supabase.rpc(
            "ensure_trust_profile",
            params: ["user_id_param": userId.uuidString]
        ).execute()
    }

    // MARK: - Tier Validation

    /// Check if user can create a swap for given amount
    func canCreateSwap(
        profile: TrustProfile,
        amountCents: Int,
        swapType: BillSwapType
    ) -> Result<Void, BillSwapError> {
        // Check active swaps limit
        if profile.activeSwapsCount >= profile.tier.maxActiveSwaps {
            return .failure(.maxActiveSwapsReached(max: profile.tier.maxActiveSwaps))
        }

        // Check amount cap
        if amountCents > profile.tier.maxBillCents {
            return .failure(.tierCapExceeded(maxCents: profile.tier.maxBillCents))
        }

        // Check one-sided eligibility
        if swapType == .oneSidedAssist && !profile.tier.canOneSidedAssist {
            return .failure(.operationFailed("One-sided assist requires Trusted tier or higher"))
        }

        return .success(())
    }

    // MARK: - Active Swaps Management

    /// Increment active swaps count
    func incrementActiveSwaps(userId: UUID) async throws {
        try await supabase.rpc(
            "increment_active_swaps",
            params: ["user_id_param": userId.uuidString]
        ).execute()
    }

    /// Decrement active swaps count
    func decrementActiveSwaps(userId: UUID) async throws {
        try await supabase.rpc(
            "decrement_active_swaps",
            params: ["user_id_param": userId.uuidString]
        ).execute()
    }

    // MARK: - Trust Score Updates

    /// Apply trust score delta after swap completion/failure
    func applyTrustDelta(
        userId: UUID,
        baseChange: Int,
        swapAmountCents: Int,
        isOneSided: Bool,
        isSuccess: Bool,
        isAtFault: Bool = false
    ) async throws -> Double {
        struct DeltaResult: Codable {
            let delta: Double
        }

        let params = ApplyTrustDeltaParams(
            pUserId: userId.uuidString,
            pBaseChange: baseChange,
            pSwapAmountCents: swapAmountCents,
            pIsOneSided: isOneSided,
            pIsSuccess: isSuccess,
            pIsAtFault: isAtFault
        )

        let result: Double = try await supabase.rpc(
            "apply_trust_delta",
            params: params
        )
        .execute()
        .value

        return result
    }

    /// Update trust after successful swap
    func recordSuccessfulSwap(
        userId: UUID,
        swapAmountCents: Int,
        isOneSided: Bool
    ) async throws {
        // Apply positive trust delta
        _ = try await applyTrustDelta(
            userId: userId,
            baseChange: TrustScoreConstants.completedSwapBase,
            swapAmountCents: swapAmountCents,
            isOneSided: isOneSided,
            isSuccess: true
        )

        // Update swap counts and streak
        try await updateCompletedSwapStats(userId: userId)

        // Update tier if needed
        _ = try await updateUserTier(userId: userId)
    }

    /// Update trust after failed swap
    func recordFailedSwap(
        userId: UUID,
        swapAmountCents: Int,
        isOneSided: Bool,
        isAtFault: Bool
    ) async throws {
        // Apply negative trust delta
        _ = try await applyTrustDelta(
            userId: userId,
            baseChange: TrustScoreConstants.failedAtFaultBase,
            swapAmountCents: swapAmountCents,
            isOneSided: isOneSided,
            isSuccess: false,
            isAtFault: isAtFault
        )

        // Update failed count
        try await updateFailedSwapStats(userId: userId, isAtFault: isAtFault)

        // Update tier if needed
        _ = try await updateUserTier(userId: userId)
    }

    /// Record no-show
    func recordNoShow(userId: UUID, swapAmountCents: Int) async throws {
        _ = try await applyTrustDelta(
            userId: userId,
            baseChange: TrustScoreConstants.noShowBase,
            swapAmountCents: swapAmountCents,
            isOneSided: false,
            isSuccess: false,
            isAtFault: true
        )

        let payload = RecordNoShowPayload(
            noShowCount: "no_show_count + 1",
            currentStreak: 0,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("trust_profiles")
            .update(payload)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Private Helpers

    private func updateCompletedSwapStats(userId: UUID) async throws {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)

        let payload = UpdateCompletedSwapStatsPayload(
            completedSwapsCount: "completed_swaps_count + 1",
            lastSwapDate: String(today),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("trust_profiles")
            .update(payload)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    private func updateFailedSwapStats(userId: UUID, isAtFault: Bool) async throws {
        let payload = UpdateFailedSwapStatsPayload(
            failedSwapsCount: "failed_swaps_count + 1",
            currentStreak: 0,
            disputedAtFaultCount: isAtFault ? "disputed_at_fault_count + 1" : nil,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("trust_profiles")
            .update(payload)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    /// Update user tier based on current stats
    func updateUserTier(userId: UUID) async throws -> SwapTrustTier {
        let tierString: String = try await supabase.rpc(
            "update_user_tier",
            params: ["user_id_param": userId.uuidString]
        )
        .execute()
        .value

        return SwapTrustTier(rawValue: tierString) ?? .T0_NEW
    }
}

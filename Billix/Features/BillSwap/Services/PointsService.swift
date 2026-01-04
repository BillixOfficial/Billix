//
//  PointsService.swift
//  Billix
//
//  Bill Swap Points Service
//

import Foundation
import Supabase

// MARK: - Private Codable Payloads

private struct PointsLedgerPayload: Codable {
    let userId: String
    let deltaPoints: Int
    let reason: String
    var swapId: String?
    var description: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deltaPoints = "delta_points"
        case reason
        case swapId = "swap_id"
        case description
    }
}

private struct AddPointsRPCParams: Codable {
    let userIdParam: String
    let pointsToAdd: Int

    enum CodingKeys: String, CodingKey {
        case userIdParam = "user_id_param"
        case pointsToAdd = "points_to_add"
    }
}

@MainActor
class PointsService: ObservableObject {
    static let shared = PointsService()

    private let supabase = SupabaseService.shared.client

    @Published var currentBalance: Int = 0
    @Published var recentTransactions: [SwapPointsLedgerEntry] = []
    @Published var isLoading = false
    @Published var error: Error?

    private init() {}

    // MARK: - Fetch Points

    /// Fetch current user's points balance from trust profile
    func fetchCurrentBalance() async throws -> Int {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SwapPointsError.notAuthenticated
        }

        let profile: TrustProfile = try await supabase
            .from("trust_profiles")
            .select("billix_points_balance")
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        currentBalance = profile.billixPointsBalance
        return profile.billixPointsBalance
    }

    /// Fetch points ledger history
    func fetchLedgerHistory(limit: Int = 50) async throws -> [SwapPointsLedgerEntry] {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SwapPointsError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let entries: [SwapPointsLedgerEntry] = try await supabase
            .from("billix_points_ledger")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        recentTransactions = entries
        return entries
    }

    // MARK: - Add Points

    /// Add points to user's balance
    func addPoints(
        userId: UUID,
        points: Int,
        reason: SwapPointsReason,
        swapId: UUID? = nil,
        description: String? = nil
    ) async throws {
        // Create ledger entry
        var payload = PointsLedgerPayload(
            userId: userId.uuidString,
            deltaPoints: points,
            reason: reason.rawValue,
            swapId: swapId?.uuidString,
            description: description
        )

        try await supabase
            .from("billix_points_ledger")
            .insert(payload)
            .execute()

        // Update balance via RPC
        let rpcParams = AddPointsRPCParams(
            userIdParam: userId.uuidString,
            pointsToAdd: points
        )
        try await supabase.rpc(
            "add_billix_points",
            params: rpcParams
        ).execute()

        // Refresh current balance if this is the current user
        if userId == SupabaseService.shared.currentUserId {
            currentBalance += points
        }
    }

    // MARK: - Award Points for Swap Completion

    /// Award points for completing a swap
    func awardSwapCompletionPoints(
        userId: UUID,
        swapId: UUID,
        isFirstSwapOfDay: Bool
    ) async throws {
        // Base completion points
        try await addPoints(
            userId: userId,
            points: PointsConstants.perCompletedSwap,
            reason: .swapCompleted,
            swapId: swapId,
            description: "Swap completed successfully"
        )

        // First swap of day bonus
        if isFirstSwapOfDay {
            try await addPoints(
                userId: userId,
                points: PointsConstants.firstSwapOfDayBonus,
                reason: .firstSwapOfDay,
                swapId: swapId,
                description: "First swap of the day bonus"
            )
        }
    }

    // MARK: - Fee Waiver

    /// Check if user can waive fee with points
    func canWaiveFee(userId: UUID) async throws -> Bool {
        let profile: TrustProfile = try await supabase
            .from("trust_profiles")
            .select("billix_points_balance")
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return profile.billixPointsBalance >= PointsConstants.feeWaiverCost
    }

    /// Deduct points for fee waiver
    func deductPointsForFeeWaiver(
        userId: UUID,
        swapId: UUID
    ) async throws {
        // Verify sufficient balance
        let canWaive = try await canWaiveFee(userId: userId)
        guard canWaive else {
            throw SwapPointsError.insufficientBalance
        }

        // Deduct points (negative delta)
        try await addPoints(
            userId: userId,
            points: -PointsConstants.feeWaiverCost,
            reason: .feeWaiver,
            swapId: swapId,
            description: "Fee waived with points"
        )
    }

    // MARK: - First Swap of Day Check

    /// Check if this would be the user's first swap today
    func isFirstSwapOfDay(userId: UUID) async throws -> Bool {
        let profile: TrustProfile = try await supabase
            .from("trust_profiles")
            .select("last_swap_date")
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        guard let lastSwapDate = profile.lastSwapDate else {
            return true // Never swapped before
        }

        return !Calendar.current.isDateInToday(lastSwapDate)
    }

    // MARK: - Points Summary

    /// Get points summary for user
    func getPointsSummary(userId: UUID) async throws -> PointsSummary {
        let profile: TrustProfile = try await supabase
            .from("trust_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        // Get total credits
        struct PointsAgg: Codable {
            let totalEarned: Int?
            let totalSpent: Int?

            enum CodingKeys: String, CodingKey {
                case totalEarned = "total_earned"
                case totalSpent = "total_spent"
            }
        }

        // This is a simplified calculation - in production you'd aggregate from ledger
        let lifetimeEarned = profile.completedSwapsCount * PointsConstants.perCompletedSwap
        let lifetimeSpent = max(0, lifetimeEarned - profile.billixPointsBalance)

        return PointsSummary(
            currentBalance: profile.billixPointsBalance,
            lifetimeEarned: lifetimeEarned,
            lifetimeSpent: lifetimeSpent,
            swapsCompletedThisMonth: 0, // Would need additional query
            canWaiveFee: profile.billixPointsBalance >= PointsConstants.feeWaiverCost
        )
    }

    // MARK: - Dispute Refund

    /// Refund points for dispute resolution in user's favor
    func refundDisputePoints(
        userId: UUID,
        swapId: UUID,
        points: Int
    ) async throws {
        try await addPoints(
            userId: userId,
            points: points,
            reason: .disputeRefund,
            swapId: swapId,
            description: "Dispute resolved in your favor"
        )
    }
}

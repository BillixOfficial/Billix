//
//  RewardsService.swift
//  Billix
//
//  Handles all point-related operations with Supabase backend
//  Simplified to use user_profiles.points column directly
//

import Foundation
import Supabase

/// Service for managing rewards points with Supabase backend
class RewardsService {
    static let shared = RewardsService()

    private let client: SupabaseClient

    init() {
        self.client = SupabaseService.shared.client
    }

    // MARK: - User Points

    /// Fetch user's current point balance from user_profiles
    func getUserPoints(userId: UUID) async throws -> Int {
        struct ProfilePoints: Codable {
            let points: Int
        }

        let response: ProfilePoints = try await client
            .from("user_profiles")
            .select("points")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return response.points
    }

    /// Add points by updating user_profiles.points directly
    func addPoints(
        userId: UUID,
        amount: Int,
        type: String = "manual",
        description: String = ""
    ) async throws -> Int {
        // First get current points
        let currentPoints = try await getUserPoints(userId: userId)
        let newPoints = currentPoints + amount

        // Update the points
        try await client
            .from("user_profiles")
            .update(["points": newPoints])
            .eq("id", value: userId.uuidString)
            .execute()

        return newPoints
    }

    /// Deduct points (for redemptions)
    func deductPoints(userId: UUID, amount: Int) async throws -> Int {
        let currentPoints = try await getUserPoints(userId: userId)
        let newPoints = max(0, currentPoints - amount) // Don't go below 0

        try await client
            .from("user_profiles")
            .update(["points": newPoints])
            .eq("id", value: userId.uuidString)
            .execute()

        return newPoints
    }

    // MARK: - Transactions (Simplified - no history)

    /// Transaction history is no longer stored
    /// Returns empty array for backwards compatibility
    func getTransactions(
        userId: UUID,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [PointTransaction] {
        return []
    }
}

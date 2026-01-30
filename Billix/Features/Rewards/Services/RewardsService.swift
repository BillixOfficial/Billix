//
//  RewardsService.swift
//  Billix
//
//  Handles all point-related operations with Supabase backend
//  Simplified to use user_profiles.points column directly
//

import Foundation
import Supabase

/// Errors specific to rewards operations
enum RewardsServiceError: LocalizedError {
    case insufficientPoints
    case userNotFound
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .insufficientPoints:
            return "Insufficient points for this operation"
        case .userNotFound:
            return "User profile not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

/// Service for managing rewards points with Supabase backend
/// Uses atomic database operations to prevent race conditions
final class RewardsService: Sendable {
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

        do {
            let response: ProfilePoints = try await client
                .from("user_profiles")
                .select("points")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            return response.points
        } catch {
            throw RewardsServiceError.networkError(error)
        }
    }

    /// Add points atomically using RPC function
    /// Falls back to non-atomic update if RPC not available
    func addPoints(
        userId: UUID,
        amount: Int,
        type: String = "manual",
        description: String = ""
    ) async throws -> Int {
        // Try atomic RPC first
        do {
            struct AddPointsParams: Encodable {
                let p_user_id: String
                let p_amount: Int
            }

            struct PointsResult: Decodable {
                let new_balance: Int
            }

            let result: PointsResult = try await client
                .rpc("add_user_points", params: AddPointsParams(
                    p_user_id: userId.uuidString,
                    p_amount: amount
                ))
                .single()
                .execute()
                .value

            return result.new_balance
        } catch {
            // Fallback to read-then-write (less safe but works without RPC)
            print("⚠️ RPC not available, using fallback method")
            let currentPoints = try await getUserPoints(userId: userId)
            let newPoints = currentPoints + amount

            try await client
                .from("user_profiles")
                .update(["points": newPoints])
                .eq("id", value: userId.uuidString)
                .execute()

            return newPoints
        }
    }

    /// Deduct points atomically using RPC function
    /// Falls back to non-atomic update if RPC not available
    func deductPoints(userId: UUID, amount: Int) async throws -> Int {
        // Try atomic RPC first
        do {
            struct DeductPointsParams: Encodable {
                let p_user_id: String
                let p_amount: Int
            }

            struct PointsResult: Decodable {
                let new_balance: Int
            }

            let result: PointsResult = try await client
                .rpc("deduct_user_points", params: DeductPointsParams(
                    p_user_id: userId.uuidString,
                    p_amount: amount
                ))
                .single()
                .execute()
                .value

            return result.new_balance
        } catch {
            // Fallback to read-then-write (less safe but works without RPC)
            print("⚠️ RPC not available, using fallback method")
            let currentPoints = try await getUserPoints(userId: userId)

            // Verify sufficient points
            guard currentPoints >= amount else {
                throw RewardsServiceError.insufficientPoints
            }

            let newPoints = max(0, currentPoints - amount)

            try await client
                .from("user_profiles")
                .update(["points": newPoints])
                .eq("id", value: userId.uuidString)
                .execute()

            return newPoints
        }
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

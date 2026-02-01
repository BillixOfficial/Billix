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
                .from("profiles")
                .select("points")
                .eq("user_id", value: userId.uuidString)
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
            let currentLifetime = try await getLifetimePoints(userId: userId)
            let newPoints = currentPoints + amount
            let newLifetime = currentLifetime + amount

            try await client
                .from("profiles")
                .update([
                    "points": newPoints,
                    "lifetime_points": newLifetime
                ])
                .eq("user_id", value: userId.uuidString)
                .execute()

            return newPoints
        }
    }

    /// Fetch user's lifetime points from profiles
    func getLifetimePoints(userId: UUID) async throws -> Int {
        struct ProfileLifetime: Codable {
            let lifetime_points: Int?
        }

        do {
            let response: ProfileLifetime = try await client
                .from("profiles")
                .select("lifetime_points")
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            return response.lifetime_points ?? 0
        } catch {
            throw RewardsServiceError.networkError(error)
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
                .from("profiles")
                .update(["points": newPoints])
                .eq("user_id", value: userId.uuidString)
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

    // MARK: - Leaderboard

    /// Fetch leaderboard entries from profiles with show_on_leaderboard = true
    /// Returns top users sorted by lifetime points (all-time earnings)
    func fetchLeaderboard(currentUserId: UUID, limit: Int = 50) async throws -> (entries: [LeaderboardEntry], currentUserEntry: LeaderboardEntry?) {
        struct LeaderboardProfile: Codable {
            let user_id: String
            let handle: String?
            let lifetime_points: Int?
        }

        do {
            // Fetch all users who opted into leaderboard, sorted by lifetime points
            let profiles: [LeaderboardProfile] = try await client
                .from("profiles")
                .select("user_id, handle, lifetime_points")
                .eq("show_on_leaderboard", value: true)
                .gt("lifetime_points", value: 0)
                .order("lifetime_points", ascending: false)
                .limit(limit)
                .execute()
                .value

            var entries: [LeaderboardEntry] = []
            var currentUserEntry: LeaderboardEntry?

            for (index, profile) in profiles.enumerated() {
                let isCurrentUser = profile.user_id == currentUserId.uuidString
                let handle = profile.handle ?? "anonymous"
                let displayHandle = "@\(handle)"

                // Get initials from handle (first 2 chars uppercase)
                let initials = String(handle.prefix(2)).uppercased()

                let entry = LeaderboardEntry(
                    id: UUID(uuidString: profile.user_id) ?? UUID(),
                    rank: index + 1,
                    displayName: displayHandle,
                    avatarInitials: initials,
                    pointsThisWeek: profile.lifetime_points ?? 0, // All-time points
                    isCurrentUser: isCurrentUser
                )

                entries.append(entry)

                if isCurrentUser {
                    currentUserEntry = entry
                }
            }

            // If current user is not in the leaderboard (opted out or no points),
            // fetch their data separately
            if currentUserEntry == nil {
                let userProfile: LeaderboardProfile? = try? await client
                    .from("profiles")
                    .select("user_id, handle, lifetime_points")
                    .eq("user_id", value: currentUserId.uuidString)
                    .single()
                    .execute()
                    .value

                if let userProfile = userProfile {
                    let handle = userProfile.handle ?? "anonymous"
                    currentUserEntry = LeaderboardEntry(
                        id: currentUserId,
                        rank: entries.count + 1, // Position after all visible entries
                        displayName: "@\(handle)",
                        avatarInitials: String(handle.prefix(2)).uppercased(),
                        pointsThisWeek: userProfile.lifetime_points ?? 0,
                        isCurrentUser: true
                    )
                }
            }

            return (entries, currentUserEntry)
        } catch {
            throw RewardsServiceError.networkError(error)
        }
    }
}

//
//  RewardsService.swift
//  Billix
//
//  Handles all point-related operations with Supabase backend
//  Industry best practices: Event sourcing, real-time updates, atomic transactions
//

import Foundation
import Supabase

/// Service for managing rewards points with Supabase backend
class RewardsService {
    private let client: SupabaseClient

    init() {
        self.client = SupabaseService.shared.client
    }

    // MARK: - User Points

    /// Fetch user's current point balance
    func getUserPoints(userId: UUID) async throws -> UserPointsDTO {
        let response: UserPointsDTO = try await client
            .from("user_points")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return response
    }

    /// Add points using database function (atomic operation)
    func addPoints(
        userId: UUID,
        amount: Int,
        type: String,
        description: String,
        source: String = "manual",
        metadata: Data? = nil
    ) async throws -> PointTransactionDTO {
        struct AddPointsParams: Encodable {
            let p_user_id: String
            let p_amount: Int
            let p_type: String
            let p_description: String
            let p_source: String
            let p_metadata: Data?
        }

        let params = AddPointsParams(
            p_user_id: userId.uuidString,
            p_amount: amount,
            p_type: type,
            p_description: description,
            p_source: source,
            p_metadata: metadata
        )

        let response: PointTransactionDTO = try await client
            .rpc("add_points", params: params)
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Transactions

    /// Fetch user's transaction history
    func getTransactions(
        userId: UUID,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [PointTransactionDTO] {
        let response: [PointTransactionDTO] = try await client
            .from("point_transactions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("reversed", value: false)
            .order("created_at", ascending: false)
            .limit(limit)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return response
    }

    // MARK: - Daily Game Cap

    /// Check daily game cap status
    func checkDailyGameCap(userId: UUID) async throws -> DailyGameCapDTO {
        struct CheckCapParams: Encodable {
            let p_user_id: String
        }

        let params = CheckCapParams(p_user_id: userId.uuidString)

        let response: DailyGameCapDTO = try await client
            .rpc("check_daily_game_cap", params: params)
            .single()
            .execute()
            .value

        return response
    }

    /// Update daily game cap after earning points
    func updateDailyGameCap(
        userId: UUID,
        pointsEarned: Int
    ) async throws -> DailyGameCapRecordDTO {
        struct UpdateCapParams: Encodable {
            let p_user_id: String
            let p_points_earned: Int
        }

        let params = UpdateCapParams(
            p_user_id: userId.uuidString,
            p_points_earned: pointsEarned
        )

        let response: DailyGameCapRecordDTO = try await client
            .rpc("update_daily_game_cap", params: params)
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Real-time Subscriptions

    /// Subscribe to point balance changes (real-time updates)
    func subscribeToPointUpdates(userId: UUID, onChange: @escaping (UserPointsDTO) -> Void) async throws {
        // TODO: Implement real-time subscription when needed
        // Supabase Realtime is available for live updates
    }
}

// MARK: - Data Transfer Objects (DTOs)

/// Matches user_points table structure
struct UserPointsDTO: Codable {
    let id: UUID
    let userId: UUID
    var balance: Int
    var lifetimeEarned: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case balance
        case lifetimeEarned = "lifetime_earned"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Convert to app model
    func toRewardsPoints(transactions: [PointTransaction] = []) -> RewardsPoints {
        return RewardsPoints(
            balance: balance,
            lifetimeEarned: lifetimeEarned,
            transactions: transactions
        )
    }
}

/// Matches point_transactions table structure
struct PointTransactionDTO: Codable {
    let id: UUID
    let userId: UUID
    let type: String
    let amount: Int
    let description: String
    let metadata: Data?
    let createdAt: Date
    let source: String
    let reversed: Bool
    let reversalOf: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case amount
        case description
        case metadata
        case createdAt = "created_at"
        case source
        case reversed
        case reversalOf = "reversal_of"
    }

    /// Convert to app model
    func toPointTransaction() -> PointTransaction {
        let transactionType: PointTransactionType
        switch type {
        case "game_win": transactionType = .gameWin
        case "daily_bonus": transactionType = .dailyBonus
        case "redemption": transactionType = .redemption
        case "referral": transactionType = .referral
        case "achievement": transactionType = .achievement
        default: transactionType = .gameWin
        }

        return PointTransaction(
            id: id,
            type: transactionType,
            amount: amount,
            description: description,
            createdAt: createdAt
        )
    }
}

/// Response from check_daily_game_cap function
struct DailyGameCapDTO: Codable {
    let canEarnMore: Bool
    let pointsEarned: Int
    let remainingPoints: Int
    let sessionsPlayed: Int

    enum CodingKeys: String, CodingKey {
        case canEarnMore = "can_earn_more"
        case pointsEarned = "points_earned"
        case remainingPoints = "remaining_points"
        case sessionsPlayed = "sessions_played"
    }

    /// Convert to app model
    func toDailyGameCap() -> DailyGameCap {
        return DailyGameCap(
            date: Date(),
            pointsEarnedToday: pointsEarned,
            sessionsPlayedToday: sessionsPlayed
        )
    }
}

/// Full daily_game_caps record
struct DailyGameCapRecordDTO: Codable {
    let id: UUID
    let userId: UUID
    let date: Date
    let pointsEarned: Int
    let sessionsPlayed: Int
    let maxDailyPoints: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case pointsEarned = "points_earned"
        case sessionsPlayed = "sessions_played"
        case maxDailyPoints = "max_daily_points"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

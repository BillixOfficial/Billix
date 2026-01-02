//
//  TaskTrackingService.swift
//  Billix
//
//  Handles all task tracking operations with Supabase backend
//  Supports daily/weekly resets, progress tracking, and point claiming
//

import Foundation
import Supabase

/// Service for managing task tracking with Supabase backend
class TaskTrackingService {
    private let client: SupabaseClient

    init() {
        self.client = SupabaseService.shared.client
    }

    // MARK: - Get User Tasks

    /// Fetch all tasks with user completion status for current period
    func getUserTasks(userId: UUID) async throws -> [UserTaskDTO] {
        struct GetTasksParams: Encodable {
            let p_user_id: String
        }

        let params = GetTasksParams(p_user_id: userId.uuidString)

        let response: [UserTaskDTO] = try await client
            .rpc("get_user_tasks", params: params)
            .execute()
            .value

        return response
    }

    // MARK: - Increment Task Progress

    /// Update progress for multi-step tasks (called when bill uploaded, game played, etc.)
    func incrementTaskProgress(
        userId: UUID,
        taskKey: String,
        sourceId: UUID? = nil,
        metadata: [String: Any]? = nil
    ) async throws -> TaskProgressResult {
        struct IncrementProgressParams: Encodable {
            let p_user_id: String
            let p_task_key: String
            let p_source_id: String?
            let p_metadata: Data?
        }

        // Convert metadata to JSONB if provided
        var metadataData: Data? = nil
        if let metadata = metadata {
            metadataData = try? JSONSerialization.data(withJSONObject: metadata)
        }

        let params = IncrementProgressParams(
            p_user_id: userId.uuidString,
            p_task_key: taskKey,
            p_source_id: sourceId?.uuidString,
            p_metadata: metadataData
        )

        let response: TaskProgressResult = try await client
            .rpc("increment_task_progress", params: params)
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Claim Task Reward

    /// Claims points for completed task (atomic operation)
    func claimTaskReward(
        userId: UUID,
        taskKey: String
    ) async throws -> ClaimResult {
        struct ClaimRewardParams: Encodable {
            let p_user_id: String
            let p_task_key: String
        }

        let params = ClaimRewardParams(
            p_user_id: userId.uuidString,
            p_task_key: taskKey
        )

        let response: ClaimResult = try await client
            .rpc("claim_task_reward", params: params)
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Daily Check-in

    /// Handles daily check-in with streak tracking
    func checkInDaily(userId: UUID) async throws -> CheckInResult {
        struct CheckInParams: Encodable {
            let p_user_id: String
        }

        let params = CheckInParams(p_user_id: userId.uuidString)

        let response: CheckInResult = try await client
            .rpc("check_in_daily", params: params)
            .single()
            .execute()
            .value

        return response
    }
}

// MARK: - Data Transfer Objects (DTOs)

/// Matches get_user_tasks() return structure
struct UserTaskDTO: Codable {
    let taskKey: String
    let title: String
    let description: String
    let category: String
    let taskType: String
    let points: Int
    let iconName: String?
    let customImage: String?
    let iconColor: String?
    let ctaText: String
    let resetType: String
    let requiresCount: Int
    let currentCount: Int
    let isCompleted: Bool
    let isClaimed: Bool
    let canClaim: Bool
    let completedAt: Date?
    let claimedAt: Date?
    let periodStart: Date?
    let periodEnd: Date?

    enum CodingKeys: String, CodingKey {
        case taskKey = "task_key"
        case title
        case description
        case category
        case taskType = "task_type"
        case points
        case iconName = "icon_name"
        case customImage = "custom_image"
        case iconColor = "icon_color"
        case ctaText = "cta_text"
        case resetType = "reset_type"
        case requiresCount = "requires_count"
        case currentCount = "current_count"
        case isCompleted = "is_completed"
        case isClaimed = "is_claimed"
        case canClaim = "can_claim"
        case completedAt = "completed_at"
        case claimedAt = "claimed_at"
        case periodStart = "period_start"
        case periodEnd = "period_end"
    }
}

/// Response from increment_task_progress function
struct TaskProgressResult: Codable {
    let currentCount: Int
    let requiredCount: Int
    let isCompleted: Bool
    let justCompleted: Bool
    let periodStart: Date?
    let periodEnd: Date?

    enum CodingKeys: String, CodingKey {
        case currentCount = "current_count"
        case requiredCount = "required_count"
        case isCompleted = "is_completed"
        case justCompleted = "just_completed"
        case periodStart = "period_start"
        case periodEnd = "period_end"
    }
}

/// Response from claim_task_reward function
struct ClaimResult: Codable {
    let success: Bool
    let pointsAwarded: Int
    let message: String
    let taskTitle: String

    enum CodingKeys: String, CodingKey {
        case success
        case pointsAwarded = "points_awarded"
        case message
        case taskTitle = "task_title"
    }
}

/// Response from check_in_daily function
struct CheckInResult: Codable {
    let success: Bool
    let pointsAwarded: Int
    let currentStreak: Int
    let isNewRecord: Bool
    let milestoneReached: String?
    let message: String

    enum CodingKeys: String, CodingKey {
        case success
        case pointsAwarded = "points_awarded"
        case currentStreak = "current_streak"
        case isNewRecord = "is_new_record"
        case milestoneReached = "milestone_reached"
        case message
    }
}

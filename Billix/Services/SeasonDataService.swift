//
//  SeasonDataService.swift
//  Billix
//
//  Created by Claude Code
//  Service for managing season-based Price Guessr progression
//

import Foundation
import Supabase

/// Service handling all season-related database operations
@MainActor
class SeasonDataService {

    // MARK: - Singleton
    static let shared = SeasonDataService()

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Season Management

    /// Fetch all seasons (both released and locked)
    func fetchSeasons() async throws -> [Season] {
        let seasons: [Season] = try await supabase
            .from("seasons")
            .select()
            .order("season_number")
            .execute()
            .value

        return seasons
    }

    /// Fetch all parts for a specific season
    func fetchSeasonParts(seasonId: UUID) async throws -> [SeasonPart] {
        let parts: [SeasonPart] = try await supabase
            .from("season_parts")
            .select()
            .eq("season_id", value: seasonId.uuidString)
            .order("part_number")
            .execute()
            .value

        return parts
    }

    /// Fetch all locations for a specific part
    func fetchSeasonLocations(partId: UUID) async throws -> [SeasonLocation] {
        let locations: [SeasonLocation] = try await supabase
            .from("season_locations")
            .select()
            .eq("season_part_id", value: partId.uuidString)
            .order("location_number")
            .execute()
            .value

        return locations
    }

    // MARK: - Progress Tracking

    /// Fetch user's progress for all locations in a season
    func fetchUserProgress(userId: UUID, seasonId: UUID) async throws -> [UserSeasonProgress] {
        let progress: [UserSeasonProgress] = try await supabase
            .from("user_season_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("season_id", value: seasonId.uuidString)
            .execute()
            .value

        return progress
    }

    /// Fetch ALL user's progress across all seasons (for lightweight stats)
    func fetchAllUserProgress(userId: UUID) async throws -> [UserSeasonProgress] {
        let progress: [UserSeasonProgress] = try await supabase
            .from("user_season_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return progress
    }

    /// Fetch user's progress for a specific location
    func fetchLocationProgress(userId: UUID, locationId: UUID) async throws -> UserSeasonProgress? {
        do {
            let progress: UserSeasonProgress = try await supabase
                .from("user_season_progress")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("location_id", value: locationId.uuidString)
                .single()
                .execute()
                .value

            return progress
        } catch {
            // Return nil if no progress found (first time playing)
            return nil
        }
    }

    /// Save or update progress after completing a location
    func saveLocationProgress(
        userId: UUID,
        seasonId: UUID,
        partId: UUID,
        locationId: UUID,
        session: GameSession
    ) async throws {
        // Check if progress already exists
        let existingProgress = try await fetchLocationProgress(userId: userId, locationId: locationId)

        // Create new progress record from session
        let newProgress = UserSeasonProgress(
            userId: userId,
            seasonId: seasonId,
            partId: partId,
            locationId: locationId,
            session: session
        )

        if let existing = existingProgress {
            // Determine best values to keep
            let bestStars = max(newProgress.starsEarned, existing.starsEarned)
            let bestPoints = max(newProgress.pointsEarned, existing.pointsEarned)
            let bestCombo = max(newProgress.bestCombo, existing.bestCombo)
            let bestAccuracy = max(newProgress.accuracyPercent ?? 0, existing.accuracyPercent ?? 0)

            let shouldUpdate = bestStars > existing.starsEarned ||
                             bestPoints > existing.pointsEarned ||
                             bestCombo > existing.bestCombo ||
                             bestAccuracy > (existing.accuracyPercent ?? 0) ||
                             !existing.isCompleted

            if shouldUpdate {
                struct ProgressUpdate: Encodable {
                    let is_completed: Bool
                    let stars_earned: Int
                    let points_earned: Int
                    let best_combo: Int
                    let final_health: Int?
                    let accuracy_percent: Int?
                    let landmarks_correct: Int
                    let landmarks_attempted: Int
                    let prices_correct: Int
                    let prices_attempted: Int
                    let last_played_at: String
                    let completed_at: String?
                }

                let update = ProgressUpdate(
                    is_completed: newProgress.isCompleted,
                    stars_earned: bestStars,
                    points_earned: bestPoints,
                    best_combo: bestCombo,
                    final_health: newProgress.finalHealth,
                    accuracy_percent: bestAccuracy > 0 ? bestAccuracy : nil,
                    landmarks_correct: newProgress.landmarksCorrect,
                    landmarks_attempted: newProgress.landmarksAttempted,
                    prices_correct: newProgress.pricesCorrect,
                    prices_attempted: newProgress.pricesAttempted,
                    last_played_at: ISO8601DateFormatter().string(from: Date()),
                    completed_at: (newProgress.isCompleted && existing.completedAt == nil) ? ISO8601DateFormatter().string(from: Date()) : nil
                )

                try await supabase
                    .from("user_season_progress")
                    .update(update)
                    .eq("user_id", value: userId.uuidString)
                    .eq("location_id", value: locationId.uuidString)
                    .execute()
            }
        } else {
            // Insert new progress record
            struct ProgressInsert: Encodable {
                let user_id: UUID
                let season_id: UUID
                let part_id: UUID
                let location_id: UUID
                let is_completed: Bool
                let stars_earned: Int
                let points_earned: Int
                let best_combo: Int
                let final_health: Int?
                let accuracy_percent: Int?
                let landmarks_correct: Int
                let landmarks_attempted: Int
                let prices_correct: Int
                let prices_attempted: Int
            }

            let insert = ProgressInsert(
                user_id: userId,
                season_id: seasonId,
                part_id: partId,
                location_id: locationId,
                is_completed: newProgress.isCompleted,
                stars_earned: newProgress.starsEarned,
                points_earned: newProgress.pointsEarned,
                best_combo: newProgress.bestCombo,
                final_health: newProgress.finalHealth,
                accuracy_percent: newProgress.accuracyPercent,
                landmarks_correct: newProgress.landmarksCorrect,
                landmarks_attempted: newProgress.landmarksAttempted,
                prices_correct: newProgress.pricesCorrect,
                prices_attempted: newProgress.pricesAttempted
            )

            try await supabase
                .from("user_season_progress")
                .insert(insert)
                .execute()
        }

        // Award points to user profile
        try await awardPointsToProfile(userId: userId, points: newProgress.pointsEarned)
    }

    /// Check if a part is unlocked based on completion requirements
    func isPartUnlocked(userId: UUID, partId: UUID, unlockRequirement: Int) async throws -> Bool {
        // If unlock requirement is 0, part is unlocked by default
        guard unlockRequirement > 0 else { return true }

        // Count completed locations for this user in the PREVIOUS part
        // This is a simplified approach - in production, you'd query the part's dependencies
        let progress: [UserSeasonProgress] = try await supabase
            .from("user_season_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("part_id", value: partId.uuidString)
            .eq("is_completed", value: true)
            .execute()
            .value

        return progress.count >= unlockRequirement
    }

    /// Get completion count for a specific part
    func getPartCompletionCount(userId: UUID, partId: UUID) async throws -> Int {
        let progress: [UserSeasonProgress] = try await supabase
            .from("user_season_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("part_id", value: partId.uuidString)
            .eq("is_completed", value: true)
            .execute()
            .value

        return progress.count
    }

    // MARK: - Session-Based Gameplay

    /// Generate a random session of locations for gameplay
    /// - Parameters:
    ///   - partId: The part to generate locations from
    ///   - locationCount: Number of locations to include (default: 10)
    /// - Returns: Array of randomly selected locations
    func generateRandomSession(partId: UUID, locationCount: Int = 10) async throws -> [SeasonLocation] {
        let allLocations = try await fetchSeasonLocations(partId: partId)

        guard allLocations.count >= locationCount else {
            throw SeasonDataError.insufficientLocations(available: allLocations.count, required: locationCount)
        }

        // Shuffle and take the required number
        return Array(allLocations.shuffled().prefix(locationCount))
    }

    /// Check if user has passed a specific part (80% on any session)
    func hasPassedPart(userId: UUID, partId: UUID) async throws -> Bool {
        let sessions = try await fetchSessionProgress(userId: userId, partId: partId)
        return sessions.contains { $0.hasPassed }
    }

    /// Fetch all session progress for a user's part
    func fetchSessionProgress(userId: UUID, partId: UUID) async throws -> [UserSessionProgress] {
        // Query for session-based progress (where session_id is not null)
        struct RawSessionProgress: Decodable {
            let id: UUID
            let user_id: UUID
            let season_id: UUID
            let part_id: UUID
            let session_id: UUID?
            let total_questions_attempted: Int?
            let total_questions_correct: Int?
            let has_passed: Bool?
            let pass_threshold: Int?
            let attempt_number: Int?
            let points_earned: Int
            let landmarks_correct: Int
            let landmarks_attempted: Int
            let prices_correct: Int
            let prices_attempted: Int
            let completed_at: String?
        }

        let rawProgress: [RawSessionProgress] = try await supabase
            .from("user_season_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("part_id", value: partId.uuidString)
            .not("session_id", operator: .is, value: "null")
            .order("completed_at", ascending: false)
            .execute()
            .value

        // Convert to UserSessionProgress
        return rawProgress.compactMap { raw in
            guard let sessionId = raw.session_id,
                  let totalAttempted = raw.total_questions_attempted,
                  let totalCorrect = raw.total_questions_correct,
                  let hasPassed = raw.has_passed,
                  let passThreshold = raw.pass_threshold,
                  let attemptNumber = raw.attempt_number,
                  let completedAtString = raw.completed_at,
                  let completedAt = ISO8601DateFormatter().date(from: completedAtString) else {
                return nil
            }

            return UserSessionProgress(
                id: raw.id,
                userId: raw.user_id,
                seasonId: raw.season_id,
                partId: raw.part_id,
                sessionId: sessionId,
                totalQuestionsAttempted: totalAttempted,
                totalQuestionsCorrect: totalCorrect,
                hasPassed: hasPassed,
                passThreshold: passThreshold,
                attemptNumber: attemptNumber,
                pointsEarned: raw.points_earned,
                landmarksCorrect: raw.landmarks_correct,
                pricesCorrect: raw.prices_correct,
                completedAt: completedAt
            )
        }
    }

    /// Save session progress after completing a game session
    func saveSessionProgress(
        userId: UUID,
        seasonId: UUID,
        partId: UUID,
        session: GameSession
    ) async throws {
        // Get existing attempts to determine attempt number
        let existingSessions = try await fetchSessionProgress(userId: userId, partId: partId)
        let attemptNumber = existingSessions.count + 1

        // Create progress from session
        let progress = UserSessionProgress.from(
            session: session,
            userId: userId,
            seasonId: seasonId,
            partId: partId,
            attemptNumber: attemptNumber
        )

        // Insert session progress
        struct SessionProgressInsert: Encodable {
            let user_id: UUID
            let season_id: UUID
            let part_id: UUID
            let session_id: UUID
            let total_questions_attempted: Int
            let total_questions_correct: Int
            let has_passed: Bool
            let pass_threshold: Int
            let attempt_number: Int
            let points_earned: Int
            let landmarks_correct: Int
            let landmarks_attempted: Int
            let prices_correct: Int
            let prices_attempted: Int
            let final_health: Int  // NEW: Track ending health to distinguish quit vs game over
        }

        let insert = SessionProgressInsert(
            user_id: userId,
            season_id: seasonId,
            part_id: partId,
            session_id: session.id,
            total_questions_attempted: progress.totalQuestionsAttempted,
            total_questions_correct: progress.totalQuestionsCorrect,
            has_passed: progress.hasPassed,
            pass_threshold: progress.passThreshold,
            attempt_number: progress.attemptNumber,
            points_earned: progress.pointsEarned,
            landmarks_correct: progress.landmarksCorrect,
            landmarks_attempted: session.landmarksAttempted,
            prices_correct: progress.pricesCorrect,
            prices_attempted: session.pricesAttempted,
            final_health: session.health
        )

        try await supabase
            .from("user_season_progress")
            .insert(insert)
            .execute()

        // Award points to user profile
        try await awardPointsToProfile(userId: userId, points: progress.pointsEarned)
    }

    // MARK: - User Settings

    /// Fetch user's game settings (tutorial state, etc.)
    func fetchGameSettings(userId: UUID) async throws -> UserGameSettings? {
        do {
            let settings: UserGameSettings = try await supabase
                .from("user_game_settings")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            return settings
        } catch {
            // Return nil if settings don't exist yet
            return nil
        }
    }

    /// Update or create user's game settings
    func updateGameSettings(userId: UUID, settings: UserGameSettings) async throws {
        let existingSettings = try await fetchGameSettings(userId: userId)

        if existingSettings != nil {
            // Update existing settings
            struct SettingsUpdate: Encodable {
                let has_played_geogame: Bool
                let has_seen_tutorial: Bool
                let tutorial_skipped_count: Int
                let updated_at: String
            }

            let update = SettingsUpdate(
                has_played_geogame: settings.hasPlayedGeogame,
                has_seen_tutorial: settings.hasSeenTutorial,
                tutorial_skipped_count: settings.tutorialSkippedCount,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )

            try await supabase
                .from("user_game_settings")
                .update(update)
                .eq("user_id", value: userId.uuidString)
                .execute()
        } else {
            // Insert new settings
            struct SettingsInsert: Encodable {
                let user_id: UUID
                let has_played_geogame: Bool
                let has_seen_tutorial: Bool
                let tutorial_skipped_count: Int
            }

            let insert = SettingsInsert(
                user_id: userId,
                has_played_geogame: settings.hasPlayedGeogame,
                has_seen_tutorial: settings.hasSeenTutorial,
                tutorial_skipped_count: settings.tutorialSkippedCount
            )

            try await supabase
                .from("user_game_settings")
                .insert(insert)
                .execute()
        }
    }

    /// Mark tutorial as seen
    func markTutorialSeen(userId: UUID) async throws {
        var settings = try await fetchGameSettings(userId: userId) ?? UserGameSettings(userId: userId)
        settings.hasSeenTutorial = true
        settings.hasPlayedGeogame = true
        try await updateGameSettings(userId: userId, settings: settings)
    }

    /// Mark tutorial as skipped
    func markTutorialSkipped(userId: UUID) async throws {
        var settings = try await fetchGameSettings(userId: userId) ?? UserGameSettings(userId: userId)
        settings.tutorialSkippedCount += 1
        try await updateGameSettings(userId: userId, settings: settings)
    }

    /// Mark tutorial as completed (user clicked "LET'S PLAY!")
    func markTutorialCompleted(userId: UUID, pagesViewed: Int) async throws {
        var settings = try await fetchGameSettings(userId: userId) ?? UserGameSettings(userId: userId)
        settings.hasCompletedTutorial = true
        settings.hasSeenTutorial = true  // Also mark as seen
        settings.lastTutorialPageViewed = pagesViewed
        settings.lastTutorialShownAt = Date()
        settings.hasPlayedGeogame = true
        try await updateGameSettings(userId: userId, settings: settings)
    }

    /// Track tutorial page view (for analytics)
    func trackTutorialPageView(userId: UUID, pageNumber: Int) async throws {
        var settings = try await fetchGameSettings(userId: userId) ?? UserGameSettings(userId: userId)
        settings.lastTutorialPageViewed = max(settings.lastTutorialPageViewed, pageNumber)
        settings.lastTutorialShownAt = Date()
        try await updateGameSettings(userId: userId, settings: settings)
    }

    // MARK: - Points & Rewards

    /// Award points to user's profile after completing a game
    func awardPointsToProfile(userId: UUID, points: Int) async throws {
        guard points > 0 else { return }

        // Fetch current points
        struct ProfilePoints: Decodable {
            let points: Int
        }

        let current: ProfilePoints = try await supabase
            .from("user_profiles")
            .select("points")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        let newTotal = current.points + points

        // Update profile with new points total
        try await supabase
            .from("user_profiles")
            .update(["points": newTotal])
            .eq("id", value: userId.uuidString)
            .execute()
    }
}

// MARK: - Service Errors

enum SeasonDataError: LocalizedError {
    case notAuthenticated
    case seasonNotFound
    case partNotFound
    case locationNotFound
    case progressNotFound
    case updateFailed(String)
    case insufficientLocations(available: Int, required: Int)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to access season data"
        case .seasonNotFound:
            return "Season not found"
        case .partNotFound:
            return "Season part not found"
        case .locationNotFound:
            return "Location not found"
        case .progressNotFound:
            return "Progress data not found"
        case .updateFailed(let message):
            return "Failed to update data: \(message)"
        case .insufficientLocations(let available, let required):
            return "Not enough locations available. Need \(required), but only \(available) exist"
        }
    }
}

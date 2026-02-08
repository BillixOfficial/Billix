//
//  BillixScoreService.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Service for calculating and managing Billix Scores
//

import Foundation
import Supabase

// MARK: - Score Errors

enum ScoreError: LocalizedError {
    case notAuthenticated
    case scoreNotFound
    case updateFailed
    case calculationFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .scoreNotFound:
            return "Score record not found"
        case .updateFailed:
            return "Failed to update score"
        case .calculationFailed:
            return "Failed to calculate score"
        }
    }
}

// MARK: - Billix Score Service

@MainActor
class BillixScoreService: ObservableObject {

    // MARK: - Singleton
    static let shared = BillixScoreService()

    // MARK: - Published Properties
    @Published var currentScore: BillixScore?
    @Published var badgeLevel: BillixBadgeLevel = .newcomer
    @Published var overallScore: Int = 0
    @Published var recentHistory: [ScoreHistoryEntry] = []
    @Published var isLoading = false

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // MARK: - Initialization

    private init() {
        Task {
            await loadScore()
        }
    }

    // MARK: - Load Score

    /// Loads the current user's Billix Score
    func loadScore() async {
        guard let session = try? await supabase.auth.session else {
            currentScore = nil
            badgeLevel = .newcomer
            overallScore = 0
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch existing score
            let scores: [BillixScore] = try await supabase
                .from("billix_scores")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
                .value

            if let score = scores.first {
                currentScore = score
                badgeLevel = score.badgeLevel
                overallScore = score.overallScore
            } else {
                // Create initial score for new user
                await createInitialScore(userId: session.user.id)
            }

            // Load recent history
            await loadScoreHistory()

        } catch {
            print("Failed to load Billix Score: \(error)")
        }
    }

    /// Creates initial score for a new user
    private func createInitialScore(userId: UUID) async {
        let insert = BillixScoreInsert(
            userId: userId.uuidString,
            overallScore: 500,
            completionScore: 100,
            verificationScore: 100,
            communityScore: 100,
            reliabilityScore: 100,
            badgeLevel: BillixBadgeLevel.trusted.rawValue
        )

        do {
            try await supabase
                .from("billix_scores")
                .insert(insert)
                .execute()

            // Reload to get the created record
            await loadScore()
        } catch {
            print("Failed to create initial score: \(error)")
        }
    }

    /// Loads recent score history
    func loadScoreHistory(limit: Int = 20) async {
        guard let session = try? await supabase.auth.session else { return }

        do {
            let history: [ScoreHistoryEntry] = try await supabase
                .from("score_history")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            recentHistory = history
        } catch {
            print("Failed to load score history: \(error)")
        }
    }

    // MARK: - Record Events

    /// Records a score event and updates the score
    func recordEvent(_ eventType: ScoreEventType, referenceId: UUID? = nil, metadata: [String: Any]? = nil) async throws {
        guard let session = try? await supabase.auth.session else {
            throw ScoreError.notAuthenticated
        }

        guard var score = currentScore else {
            throw ScoreError.scoreNotFound
        }

        // Calculate point change
        var pointChange = eventType.basePointChange

        // Special handling for rating events
        if eventType == .ratingReceived, let rating = metadata?["rating"] as? Int {
            pointChange = calculateRatingPoints(rating: rating)
        }

        // Apply point change to appropriate component
        let component = eventType.affectedComponent
        let newComponentScore = applyPointChange(
            to: score.score(for: component),
            change: pointChange,
            maxValue: component.maxValue
        )

        // Update component score
        switch component {
        case .completion:
            score.completionScore = newComponentScore
        case .verification:
            score.verificationScore = newComponentScore
        case .community:
            score.communityScore = newComponentScore
        case .reliability:
            score.reliabilityScore = newComponentScore
        }

        // Recalculate overall score
        let newOverallScore = calculateOverallScore(
            completion: score.completionScore,
            verification: score.verificationScore,
            community: score.communityScore,
            reliability: score.reliabilityScore
        )

        // Determine new badge level
        let newBadgeLevel = BillixBadgeLevel.level(for: newOverallScore)

        // Update database
        try await updateScore(
            userId: session.user.id,
            overallScore: newOverallScore,
            completionScore: score.completionScore,
            verificationScore: score.verificationScore,
            communityScore: score.communityScore,
            reliabilityScore: score.reliabilityScore,
            badgeLevel: newBadgeLevel
        )

        // Record history
        let description = generateEventDescription(eventType, metadata: metadata)
        try await recordHistory(
            userId: session.user.id,
            eventType: eventType,
            component: component,
            pointChange: pointChange,
            newScore: newComponentScore,
            description: description,
            referenceId: referenceId
        )

        // Update local state
        self.overallScore = newOverallScore
        self.badgeLevel = newBadgeLevel

        // Reload to get fresh data
        await loadScore()
    }

    // MARK: - Score Calculation

    /// Calculates the weighted overall score
    private func calculateOverallScore(completion: Int, verification: Int, community: Int, reliability: Int) -> Int {
        let weighted = (Double(completion) * ScoreCalculationParams.completionWeight) +
                       (Double(verification) * ScoreCalculationParams.verificationWeight) +
                       (Double(community) * ScoreCalculationParams.communityWeight) +
                       (Double(reliability) * ScoreCalculationParams.reliabilityWeight)

        // Scale to 0-1000 range (components are 0-100, so multiply by 10)
        return Int(weighted * 10)
    }

    /// Applies a point change within bounds
    private func applyPointChange(to current: Int, change: Int, maxValue: Int) -> Int {
        return Swift.min(maxValue, Swift.max(0, current + change))
    }

    /// Calculates points from a rating (1-5 stars)
    private func calculateRatingPoints(rating: Int) -> Int {
        // Community score should reflect average rating
        // 5 stars = +5, 4 stars = +2, 3 stars = 0, 2 stars = -3, 1 star = -5
        switch rating {
        case 5: return 5
        case 4: return 2
        case 3: return 0
        case 2: return -3
        default: return -5
        }
    }

    /// Generates a description for the event
    private func generateEventDescription(_ eventType: ScoreEventType, metadata: [String: Any]?) -> String {
        switch eventType {
        case .swapCompleted:
            return "Successfully completed a swap"
        case .swapFailed:
            return "Swap was not completed"
        case .ghostIncident:
            return "Partner reported no response"
        case .screenshotVerified:
            return "Payment screenshot verified"
        case .screenshotRejected:
            return "Payment screenshot rejected"
        case .ratingReceived:
            if let rating = metadata?["rating"] as? Int {
                return "Received \(rating)-star rating"
            }
            return "Received rating from partner"
        case .onTimeCompletion:
            return "Completed swap on time"
        case .lateCompletion:
            return "Swap completed late"
        case .accountAgeMilestone:
            return "Account milestone reached"
        case .consistencyStreak:
            if let streak = metadata?["streak"] as? Int {
                return "\(streak)-swap consistency streak"
            }
            return "Consistency streak bonus"
        case .connectionCompleted:
            return "Successfully completed a Bill Connection"
        }
    }

    // MARK: - Database Operations

    /// Updates score in database
    private func updateScore(
        userId: UUID,
        overallScore: Int,
        completionScore: Int,
        verificationScore: Int,
        communityScore: Int,
        reliabilityScore: Int,
        badgeLevel: BillixBadgeLevel
    ) async throws {
        let update = BillixScoreUpdate(
            overallScore: overallScore,
            completionScore: completionScore,
            verificationScore: verificationScore,
            communityScore: communityScore,
            reliabilityScore: reliabilityScore,
            badgeLevel: badgeLevel.rawValue
        )
        try await supabase
            .from("billix_scores")
            .update(update)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    /// Records history entry
    private func recordHistory(
        userId: UUID,
        eventType: ScoreEventType,
        component: ScoreComponent,
        pointChange: Int,
        newScore: Int,
        description: String?,
        referenceId: UUID?
    ) async throws {
        let insert = ScoreHistoryInsert(
            userId: userId.uuidString,
            eventType: eventType.rawValue,
            component: component.rawValue,
            pointChange: pointChange,
            newScore: newScore,
            description: description,
            referenceId: referenceId?.uuidString
        )

        try await supabase
            .from("score_history")
            .insert(insert)
            .execute()
    }

    // MARK: - Convenience Methods

    /// Records a completed swap
    func recordSwapCompleted(swapId: UUID, wasOnTime: Bool) async {
        do {
            try await recordEvent(.swapCompleted, referenceId: swapId)
            if wasOnTime {
                try await recordEvent(.onTimeCompletion, referenceId: swapId)
            } else {
                try await recordEvent(.lateCompletion, referenceId: swapId)
            }
        } catch {
            print("Failed to record swap completion: \(error)")
        }
    }

    /// Records a completed Bill Connection (awards 5 points to completion score)
    /// Called when a connection is successfully completed in Phase 5
    func recordConnectionCompleted(connectionId: UUID) async {
        do {
            // Award 5 points for successful connection completion
            try await recordEvent(.connectionCompleted, referenceId: connectionId)
        } catch {
            print("Failed to record connection completion for Billix Score: \(error)")
        }
    }

    /// Records connection completion for a specific user (awards 5 points)
    /// Use this when you need to award points to a user who isn't the current user
    func recordConnectionCompletedForUser(userId: UUID, connectionId: UUID) async {
        guard let session = try? await supabase.auth.session,
              session.user.id == userId else {
            // For non-current users, we'd need a server function
            // For now, just record for current user
            return
        }
        await recordConnectionCompleted(connectionId: connectionId)
    }

    /// Records a failed swap
    func recordSwapFailed(swapId: UUID, wasGhost: Bool) async {
        do {
            try await recordEvent(.swapFailed, referenceId: swapId)
            if wasGhost {
                try await recordEvent(.ghostIncident, referenceId: swapId)
            }
        } catch {
            print("Failed to record swap failure: \(error)")
        }
    }

    /// Records a screenshot verification result
    func recordScreenshotVerification(swapId: UUID, wasVerified: Bool) async {
        do {
            if wasVerified {
                try await recordEvent(.screenshotVerified, referenceId: swapId)
            } else {
                try await recordEvent(.screenshotRejected, referenceId: swapId)
            }
        } catch {
            print("Failed to record verification: \(error)")
        }
    }

    /// Records a rating received from partner
    func recordRatingReceived(swapId: UUID, rating: Int) async {
        do {
            try await recordEvent(.ratingReceived, referenceId: swapId, metadata: ["rating": rating])
        } catch {
            print("Failed to record rating: \(error)")
        }
    }

    /// Checks and awards consistency streak
    func checkConsistencyStreak() async {
        guard let session = try? await supabase.auth.session else { return }

        do {
            // Count recent successful swaps
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let formatter = ISO8601DateFormatter()

            let history: [ScoreHistoryEntry] = try await supabase
                .from("score_history")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .eq("event_type", value: ScoreEventType.swapCompleted.rawValue)
                .gte("created_at", value: formatter.string(from: thirtyDaysAgo))
                .execute()
                .value

            // Award streak bonus at milestones
            let streakMilestones = [5, 10, 25, 50]
            let completedCount = history.count

            for milestone in streakMilestones {
                if completedCount == milestone {
                    try await recordEvent(.consistencyStreak, metadata: ["streak": milestone])
                    break
                }
            }
        } catch {
            print("Failed to check consistency streak: \(error)")
        }
    }

    // MARK: - Score Summary

    /// Returns a summary of the current score
    var scoreSummary: ScoreSummary? {
        guard let score = currentScore else { return nil }

        let components: [ScoreComponent: Int] = [
            .completion: score.completionScore,
            .verification: score.verificationScore,
            .community: score.communityScore,
            .reliability: score.reliabilityScore
        ]

        // Calculate recent change (last 7 days)
        let recentChange = recentHistory
            .filter { $0.createdAt > Calendar.current.date(byAdding: .day, value: -7, to: Date())! }
            .reduce(0) { $0 + $1.pointChange }

        return ScoreSummary(
            currentScore: score.overallScore,
            badgeLevel: score.badgeLevel,
            components: components,
            recentChange: recentChange,
            percentile: nil // Would need backend calculation
        )
    }

    // MARK: - Reset

    func reset() {
        currentScore = nil
        badgeLevel = .newcomer
        overallScore = 0
        recentHistory = []
    }
}

// MARK: - Preview Helpers

extension BillixScoreService {
    static func mockWithScore(_ score: Int, badge: BillixBadgeLevel) -> BillixScoreService {
        let service = BillixScoreService.shared
        service.overallScore = score
        service.badgeLevel = badge
        return service
    }
}

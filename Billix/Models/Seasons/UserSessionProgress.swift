//
//  UserSessionProgress.swift
//  Billix
//
//  Created by Claude Code
//  Model for tracking session-based progress in Season game mode
//

import Foundation

struct UserSessionProgress: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let seasonId: UUID
    let partId: UUID
    let sessionId: UUID  // Links to GameSession

    let totalQuestionsAttempted: Int  // Always 30 for full sessions
    let totalQuestionsCorrect: Int     // 0-30
    var hasPassed: Bool                // true if >= 24 (80%)
    let passThreshold: Int             // 24 for 80% requirement
    let attemptNumber: Int             // 1, 2, 3... (allows retries)

    var pointsEarned: Int
    var landmarksCorrect: Int          // 0-10
    var pricesCorrect: Int             // 0-20

    let completedAt: Date

    // MARK: - Computed Properties

    var accuracyPercent: Int {
        guard totalQuestionsAttempted > 0 else { return 0 }
        return Int((Double(totalQuestionsCorrect) / Double(totalQuestionsAttempted)) * 100)
    }

    var passFailStatus: String {
        hasPassed ? "PASSED" : "FAILED"
    }

    var questionsNeededToPass: Int {
        max(0, passThreshold - totalQuestionsCorrect)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        userId: UUID,
        seasonId: UUID,
        partId: UUID,
        sessionId: UUID,
        totalQuestionsAttempted: Int,
        totalQuestionsCorrect: Int,
        hasPassed: Bool,
        passThreshold: Int = 24,
        attemptNumber: Int,
        pointsEarned: Int,
        landmarksCorrect: Int,
        pricesCorrect: Int,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.seasonId = seasonId
        self.partId = partId
        self.sessionId = sessionId
        self.totalQuestionsAttempted = totalQuestionsAttempted
        self.totalQuestionsCorrect = totalQuestionsCorrect
        self.hasPassed = hasPassed
        self.passThreshold = passThreshold
        self.attemptNumber = attemptNumber
        self.pointsEarned = pointsEarned
        self.landmarksCorrect = landmarksCorrect
        self.pricesCorrect = pricesCorrect
        self.completedAt = completedAt
    }

    // MARK: - Factory Methods

    static func from(
        session: GameSession,
        userId: UUID,
        seasonId: UUID,
        partId: UUID,
        attemptNumber: Int
    ) -> UserSessionProgress {
        let totalCorrect = session.landmarksCorrect + session.pricesCorrect
        let totalAttempted = session.landmarksAttempted + session.pricesAttempted
        let hasPassed = totalCorrect >= 24 // 80% of 30

        return UserSessionProgress(
            userId: userId,
            seasonId: seasonId,
            partId: partId,
            sessionId: session.id,
            totalQuestionsAttempted: totalAttempted,
            totalQuestionsCorrect: totalCorrect,
            hasPassed: hasPassed,
            passThreshold: 24,
            attemptNumber: attemptNumber,
            pointsEarned: session.totalPoints,
            landmarksCorrect: session.landmarksCorrect,
            pricesCorrect: session.pricesCorrect,
            completedAt: Date()
        )
    }
}

// MARK: - Codable Keys

extension UserSessionProgress {
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case seasonId = "season_id"
        case partId = "part_id"
        case sessionId = "session_id"
        case totalQuestionsAttempted = "total_questions_attempted"
        case totalQuestionsCorrect = "total_questions_correct"
        case hasPassed = "has_passed"
        case passThreshold = "pass_threshold"
        case attemptNumber = "attempt_number"
        case pointsEarned = "points_earned"
        case landmarksCorrect = "landmarks_correct"
        case pricesCorrect = "prices_correct"
        case completedAt = "completed_at"
    }
}

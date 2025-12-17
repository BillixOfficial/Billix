//
//  UserSeasonProgress.swift
//  Billix
//
//  Created by Claude Code
//

import Foundation

struct UserSeasonProgress: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let seasonId: UUID
    let partId: UUID?       // Nullable for session-based progress
    let locationId: UUID?   // Nullable for session-based progress

    var isCompleted: Bool
    var starsEarned: Int
    var pointsEarned: Int
    var bestCombo: Int
    var finalHealth: Int?
    var accuracyPercent: Int?

    var landmarksCorrect: Int
    var landmarksAttempted: Int
    var pricesCorrect: Int
    var pricesAttempted: Int

    let firstPlayedAt: Date
    var completedAt: Date?
    var lastPlayedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case seasonId = "season_id"
        case partId = "part_id"
        case locationId = "location_id"
        case isCompleted = "is_completed"
        case starsEarned = "stars_earned"
        case pointsEarned = "points_earned"
        case bestCombo = "best_combo"
        case finalHealth = "final_health"
        case accuracyPercent = "accuracy_percent"
        case landmarksCorrect = "landmarks_correct"
        case landmarksAttempted = "landmarks_attempted"
        case pricesCorrect = "prices_correct"
        case pricesAttempted = "prices_attempted"
        case firstPlayedAt = "first_played_at"
        case completedAt = "completed_at"
        case lastPlayedAt = "last_played_at"
    }

    // Computed properties
    var totalCorrect: Int {
        landmarksCorrect + pricesCorrect
    }

    var totalAttempted: Int {
        landmarksAttempted + pricesAttempted
    }

    var accuracy: Double {
        guard totalAttempted > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAttempted)
    }
}

// MARK: - Creating from GameSession
extension UserSeasonProgress {
    init(
        userId: UUID,
        seasonId: UUID,
        partId: UUID?,
        locationId: UUID?,
        session: GameSession
    ) {
        self.id = UUID()
        self.userId = userId
        self.seasonId = seasonId
        self.partId = partId
        self.locationId = locationId

        self.isCompleted = session.hasWon
        self.starsEarned = Self.calculateStars(session: session)
        self.pointsEarned = session.totalPoints
        self.bestCombo = session.comboStreak
        self.finalHealth = session.health
        self.accuracyPercent = Self.calculateAccuracy(session: session)

        self.landmarksCorrect = session.landmarksCorrect
        self.landmarksAttempted = session.landmarksAttempted
        self.pricesCorrect = session.pricesCorrect
        self.pricesAttempted = session.pricesAttempted

        let now = Date()
        self.firstPlayedAt = now
        self.completedAt = session.hasWon ? now : nil
        self.lastPlayedAt = now
    }

    private static func calculateStars(session: GameSession) -> Int {
        // 0 stars: Lost (health <= 0)
        // 1 star: Won with < 50% accuracy
        // 2 stars: Won with 50-80% accuracy
        // 3 stars: Won with > 80% accuracy
        guard session.hasWon else { return 0 }

        let totalQuestions = session.landmarksAttempted + session.pricesAttempted
        guard totalQuestions > 0 else { return 1 }

        let totalCorrect = session.landmarksCorrect + session.pricesCorrect
        let accuracy = Double(totalCorrect) / Double(totalQuestions)

        if accuracy > 0.8 { return 3 }
        else if accuracy >= 0.5 { return 2 }
        else { return 1 }
    }

    private static func calculateAccuracy(session: GameSession) -> Int {
        let totalQuestions = session.landmarksAttempted + session.pricesAttempted
        guard totalQuestions > 0 else { return 0 }

        let totalCorrect = session.landmarksCorrect + session.pricesCorrect
        return Int((Double(totalCorrect) / Double(totalQuestions)) * 100)
    }
}

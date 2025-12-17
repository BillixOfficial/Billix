//
//  UserGameSettings.swift
//  Billix
//
//  Created by Claude Code
//

import Foundation

struct UserGameSettings: Codable, Hashable {
    let userId: UUID
    var hasPlayedGeogame: Bool
    var hasSeenTutorial: Bool
    var tutorialSkippedCount: Int
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case hasPlayedGeogame = "has_played_geogame"
        case hasSeenTutorial = "has_seen_tutorial"
        case tutorialSkippedCount = "tutorial_skipped_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Default initializer for new users
    init(userId: UUID) {
        self.userId = userId
        self.hasPlayedGeogame = false
        self.hasSeenTutorial = false
        self.tutorialSkippedCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

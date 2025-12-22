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
    var hasCompletedTutorial: Bool  // NEW: User viewed all 4 pages and clicked "LET'S PLAY!"
    var tutorialSkippedCount: Int
    var lastTutorialPageViewed: Int  // NEW: Highest page number reached (0-4)
    var lastTutorialShownAt: Date?  // NEW: Timestamp of last tutorial display
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case hasPlayedGeogame = "has_played_geogame"
        case hasSeenTutorial = "has_seen_tutorial"
        case hasCompletedTutorial = "has_completed_tutorial"  // NEW
        case tutorialSkippedCount = "tutorial_skipped_count"
        case lastTutorialPageViewed = "last_tutorial_page_viewed"  // NEW
        case lastTutorialShownAt = "last_tutorial_shown_at"  // NEW
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Default initializer for new users
    init(userId: UUID) {
        self.userId = userId
        self.hasPlayedGeogame = false
        self.hasSeenTutorial = false
        self.hasCompletedTutorial = false  // NEW
        self.tutorialSkippedCount = 0
        self.lastTutorialPageViewed = 0  // NEW
        self.lastTutorialShownAt = nil  // NEW
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

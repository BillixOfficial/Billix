//
//  Season.swift
//  Billix
//
//  Created by Claude Code
//

import Foundation

struct Season: Identifiable, Codable, Hashable {
    let id: UUID
    let seasonNumber: Int
    let title: String
    let description: String?
    let isReleased: Bool
    let releaseDate: Date?
    let totalParts: Int
    let iconName: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case seasonNumber = "season_number"
        case title
        case description
        case isReleased = "is_released"
        case releaseDate = "release_date"
        case totalParts = "total_parts"
        case iconName = "icon_name"
        case createdAt = "created_at"
    }

    // Computed property for display
    var isLocked: Bool {
        !isReleased
    }
}

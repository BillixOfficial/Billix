//
//  SeasonPart.swift
//  Billix
//
//  Created by Claude Code
//

import Foundation

struct SeasonPart: Identifiable, Codable, Hashable {
    let id: UUID
    let seasonId: UUID
    let partNumber: Int
    let title: String?
    let totalLocations: Int
    let unlockRequirement: Int
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case seasonId = "season_id"
        case partNumber = "part_number"
        case title
        case totalLocations = "total_locations"
        case unlockRequirement = "unlock_requirement"
        case createdAt = "created_at"
    }

    // Computed properties
    var displayTitle: String {
        title ?? "Part \(partNumber)"
    }

    var requiresCompletion: Bool {
        unlockRequirement > 0
    }
}

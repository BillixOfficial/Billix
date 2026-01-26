//
//  CommunityGroup.swift
//  Billix
//
//  Created by Claude Code on 1/25/26.
//  Model for community groups (similar to subreddits)
//

import Foundation

struct CommunityGroup: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let icon: String // SF Symbol
    let memberCount: Int
    let postCount: Int
    let color: String // Hex color
    var isJoined: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        icon: String,
        memberCount: Int,
        postCount: Int,
        color: String,
        isJoined: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.memberCount = memberCount
        self.postCount = postCount
        self.color = color
        self.isJoined = isJoined
    }

    var formattedMemberCount: String {
        if memberCount >= 1000 {
            return String(format: "%.1fK", Double(memberCount) / 1000)
        }
        return "\(memberCount)"
    }
}

// MARK: - Mock Data

extension CommunityGroup {
    static let mockGroups: [CommunityGroup] = [
        CommunityGroup(
            name: "Renters",
            description: "Advice and tips for navigating rentals",
            icon: "house.fill",
            memberCount: 15200,
            postCount: 4500,
            color: "#7BA8C1",
            isJoined: true
        ),
        CommunityGroup(
            name: "Bill Hacks",
            description: "Smart ways to reduce your monthly bills",
            icon: "bolt.fill",
            memberCount: 5600,
            postCount: 890,
            color: "#E8B54D",
            isJoined: false
        ),
        CommunityGroup(
            name: "Personal Finance",
            description: "Budgeting, saving, and building wealth together",
            icon: "chart.line.uptrend.xyaxis",
            memberCount: 8400,
            postCount: 2100,
            color: "#5b8a6b",
            isJoined: false
        )
    ]
}

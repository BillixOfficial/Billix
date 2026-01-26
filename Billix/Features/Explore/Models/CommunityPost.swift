//
//  CommunityPost.swift
//  Billix
//
//  Created by Claude Code on 1/24/26.
//  Model for community posts in Economy Feed tab
//

import Foundation

// MARK: - Community Comment Model

struct CommunityComment: Identifiable {
    let id: UUID
    let authorName: String
    let authorUsername: String
    let content: String
    let timestamp: Date
    var likeCount: Int

    init(
        id: UUID = UUID(),
        authorName: String,
        authorUsername: String,
        content: String,
        timestamp: Date,
        likeCount: Int = 0
    ) {
        self.id = id
        self.authorName = authorName
        self.authorUsername = authorUsername
        self.content = content
        self.timestamp = timestamp
        self.likeCount = likeCount
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Community Post Model

struct CommunityPost: Identifiable {
    let id: UUID
    let authorName: String
    let authorUsername: String  // e.g., "@sarahm", "@overtaked"
    let authorRole: String  // e.g., "Saver", "Budget Pro", "New Member"
    let authorAvatar: String?
    let content: String
    let topic: String?  // e.g., "Savings", "Tips", "Bills", "Question", "Milestone"
    let groupId: UUID?  // The group this post belongs to (nil = General Feed)
    let groupName: String?  // Display name of the group (e.g., "Renters", "Bill Hacks")
    let timestamp: Date
    var likeCount: Int
    var commentCount: Int
    var isLiked: Bool
    var isTrending: Bool
    var topComment: CommunityComment?  // Featured comment to show below post
    var isSaved: Bool  // Whether the current user has saved/bookmarked this post
    var userReaction: String?  // The current user's reaction type (e.g., "heart", "fire", "thumbsUp")
    var isOwnPost: Bool  // Whether the current user is the author of this post

    init(
        id: UUID = UUID(),
        authorName: String,
        authorUsername: String,
        authorRole: String,
        authorAvatar: String? = nil,
        content: String,
        topic: String? = nil,
        groupId: UUID? = nil,
        groupName: String? = nil,
        timestamp: Date,
        likeCount: Int = 0,
        commentCount: Int = 0,
        isLiked: Bool = false,
        isTrending: Bool = false,
        topComment: CommunityComment? = nil,
        isSaved: Bool = false,
        userReaction: String? = nil,
        isOwnPost: Bool = false
    ) {
        self.id = id
        self.authorName = authorName
        self.authorUsername = authorUsername
        self.authorRole = authorRole
        self.authorAvatar = authorAvatar
        self.content = content
        self.topic = topic
        self.groupId = groupId
        self.groupName = groupName
        self.timestamp = timestamp
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLiked = isLiked
        self.isTrending = isTrending
        self.topComment = topComment
        self.isSaved = isSaved
        self.userReaction = userReaction
        self.isOwnPost = isOwnPost
    }
}

// MARK: - Time Formatting Extension

extension CommunityPost {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Mock Data

extension CommunityPost {
    static let mockPosts: [CommunityPost] = [
        CommunityPost(
            authorName: "Sarah M.",
            authorUsername: "@sarahm_saves",
            authorRole: "Budget Pro",
            content: "Just saved $127 this month by switching to a different electricity provider! The comparison tool made it so easy. Has anyone else found good deals lately? I'd love to hear what's working for you.",
            topic: "Savings",
            timestamp: Date().addingTimeInterval(-3600),
            likeCount: 42,
            commentCount: 12,
            isLiked: false,
            isTrending: true,
            topComment: CommunityComment(
                authorName: "Mike R.",
                authorUsername: "@mike_r",
                content: "I switched last month too! Saved about $80. The key is checking every 6 months when contracts end.",
                timestamp: Date().addingTimeInterval(-1800),
                likeCount: 8
            )
        ),
        CommunityPost(
            authorName: "Marcus T.",
            authorUsername: "@marcus_tips",
            authorRole: "Saver",
            content: "Tip: I set up automatic payments for all my bills and combined it with a high-yield savings account. The interest covers my streaming subscriptions! Small wins add up over time.",
            topic: "Tips",
            timestamp: Date().addingTimeInterval(-7200),
            likeCount: 89,
            commentCount: 23,
            isLiked: true,
            isTrending: true,
            topComment: CommunityComment(
                authorName: "Lisa K.",
                authorUsername: "@lisa_k",
                content: "Which HYSA are you using? I'm getting 4.5% with mine but always looking for better rates.",
                timestamp: Date().addingTimeInterval(-3600),
                likeCount: 15
            )
        ),
        CommunityPost(
            authorName: "Emily R.",
            authorUsername: "@emily_newbie",
            authorRole: "New Member",
            content: "First month using Billix and I already found out I was overpaying for car insurance by $45/month. Wish I knew about this app sooner! Anyone have tips for a newbie?",
            topic: "Milestone",
            timestamp: Date().addingTimeInterval(-14400),
            likeCount: 156,
            commentCount: 31,
            isLiked: false,
            isTrending: false,
            topComment: CommunityComment(
                authorName: "David K.",
                authorUsername: "@davidk_pro",
                content: "Welcome! Pro tip: bundle your home and auto insurance. I saved an extra $300/year doing that.",
                timestamp: Date().addingTimeInterval(-10800),
                likeCount: 24
            )
        ),
        CommunityPost(
            authorName: "David K.",
            authorUsername: "@davidk_pro",
            authorRole: "Budget Pro",
            content: "Question: What's everyone doing about rising grocery prices? I've been meal planning more but still feels like everything costs more than last year. Looking for creative solutions!",
            topic: "Question",
            timestamp: Date().addingTimeInterval(-28800),
            likeCount: 67,
            commentCount: 45,
            isLiked: false,
            isTrending: false,
            topComment: CommunityComment(
                authorName: "Anna P.",
                authorUsername: "@anna_p",
                content: "Costco membership paid for itself in 2 months. Also, store brand everything - usually same quality for 30% less.",
                timestamp: Date().addingTimeInterval(-21600),
                likeCount: 31
            )
        ),
        CommunityPost(
            authorName: "Jennifer L.",
            authorUsername: "@jenn_saver",
            authorRole: "Saver",
            content: "Hit my first savings milestone today! Started tracking my bills 3 months ago and saved over $400. Small changes really add up over time. Keep going everyone!",
            topic: "Milestone",
            timestamp: Date().addingTimeInterval(-43200),
            likeCount: 234,
            commentCount: 56,
            isLiked: true,
            isTrending: true,
            topComment: CommunityComment(
                authorName: "Chris H.",
                authorUsername: "@chris_h",
                content: "Congrats! That's amazing progress. What was your biggest single savings?",
                timestamp: Date().addingTimeInterval(-36000),
                likeCount: 12
            )
        ),
        CommunityPost(
            authorName: "Alex W.",
            authorUsername: "@alex_wondering",
            authorRole: "New Member",
            content: "Anyone else notice their water bill jumped up this month? Not sure if it's a leak or just seasonal pricing. How do you guys track unusual spikes in your bills?",
            topic: "Question",
            timestamp: Date().addingTimeInterval(-86400),
            likeCount: 28,
            commentCount: 19,
            isLiked: false,
            isTrending: false,
            topComment: CommunityComment(
                authorName: "Tom B.",
                authorUsername: "@tom_b",
                content: "Check your toilets for silent leaks - put food coloring in the tank. If it shows up in the bowl without flushing, that's your culprit.",
                timestamp: Date().addingTimeInterval(-72000),
                likeCount: 19
            )
        ),
        CommunityPost(
            authorName: "Michelle P.",
            authorUsername: "@michelle_pro",
            authorRole: "Budget Pro",
            content: "Pro tip: Before renewing any insurance, always get at least 3 quotes. Just saved $200/year on home insurance by shopping around. Never accept the first renewal offer!",
            topic: "Tips",
            timestamp: Date().addingTimeInterval(-129600),
            likeCount: 178,
            commentCount: 34,
            isLiked: false,
            isTrending: false,
            topComment: CommunityComment(
                authorName: "Rachel S.",
                authorUsername: "@rachel_s",
                content: "This! I was auto-renewing for years until I realized I was paying 40% more than new customers. Loyalty doesn't pay.",
                timestamp: Date().addingTimeInterval(-100800),
                likeCount: 45
            )
        ),
        CommunityPost(
            authorName: "Chris H.",
            authorUsername: "@chris_organized",
            authorRole: "Saver",
            content: "Finally organized all my bills in one place. It's crazy how much I was spending on subscriptions I forgot about. Cancelled 4 services today and feeling great about it!",
            topic: "Bills",
            timestamp: Date().addingTimeInterval(-172800),
            likeCount: 112,
            commentCount: 28,
            isLiked: true,
            isTrending: false,
            topComment: CommunityComment(
                authorName: "Nina J.",
                authorUsername: "@nina_j",
                content: "Which ones did you cancel? I bet we all have subscriptions we forgot about lol",
                timestamp: Date().addingTimeInterval(-151200),
                likeCount: 8
            )
        )
    ]
}

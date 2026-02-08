//
//  CommunityService.swift
//  Billix
//
//  Created by Claude Code on 1/25/26.
//  Service for Community feature Supabase operations
//

import Foundation
import Supabase

// MARK: - Database Models (Codable)

struct CommunityPostDB: Codable, Identifiable {
    let id: UUID
    let authorId: UUID
    let groupId: UUID?
    let content: String
    let topic: String
    let likeCount: Int
    let commentCount: Int
    let isTrending: Bool
    let isPinned: Bool
    let isDeleted: Bool
    let isAnonymous: Bool
    let createdAt: Date
    let updatedAt: Date

    // Joined data from profiles table
    var author: AuthorProfile?
    // Joined data from groups table
    var group: PostGroupInfo?

    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case groupId = "group_id"
        case content
        case topic
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case isTrending = "is_trending"
        case isPinned = "is_pinned"
        case isDeleted = "is_deleted"
        case isAnonymous = "is_anonymous"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case author = "profiles"
        case group = "community_groups"
    }
}

struct PostGroupInfo: Codable {
    let id: UUID
    let name: String
}

struct AuthorProfile: Codable {
    let userId: UUID
    let displayName: String?
    let handle: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case handle
        case avatarUrl = "avatar_url"
    }
}

struct CommunityGroupDB: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let icon: String
    let color: String
    let memberCount: Int
    let postCount: Int
    let isOfficial: Bool
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case icon
        case color
        case memberCount = "member_count"
        case postCount = "post_count"
        case isOfficial = "is_official"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CommunityCommentDB: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let authorId: UUID
    let parentCommentId: UUID?
    let content: String
    let likeCount: Int
    let isDeleted: Bool
    let isAnonymous: Bool
    let createdAt: Date
    let updatedAt: Date

    var author: AuthorProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case authorId = "author_id"
        case parentCommentId = "parent_comment_id"
        case content
        case likeCount = "like_count"
        case isDeleted = "is_deleted"
        case isAnonymous = "is_anonymous"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case author = "profiles"
    }
}

struct CommunityReactionDB: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let reactableType: String // "post" or "comment"
    let reactableId: UUID
    let reaction: String // "like", "heart", "fire", etc.
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case reactableType = "reactable_type"
        case reactableId = "reactable_id"
        case reaction
        case createdAt = "created_at"
    }
}

struct CommunityGroupMemberDB: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let groupId: UUID
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case groupId = "group_id"
        case joinedAt = "joined_at"
    }
}

struct CommunitySavedPostDB: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let postId: UUID
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
        case savedAt = "saved_at"
    }
}

// MARK: - Topic Enum

enum CommunityTopicType: String, Codable, CaseIterable {
    case savings = "savings"
    case tips = "tips"
    case bills = "bills"
    case question = "question"
    case milestone = "milestone"
    case general = "general"

    var displayName: String {
        switch self {
        case .savings: return "Savings"
        case .tips: return "Tips"
        case .bills: return "Bills"
        case .question: return "Question"
        case .milestone: return "Milestone"
        case .general: return "General"
        }
    }
}

// MARK: - Conversion Extensions

extension CommunityPostDB {
    func toUIModel(isLiked: Bool = false, isSaved: Bool = false, userReaction: String? = nil, reactionCounts: [String: Int] = [:], currentUserId: UUID? = nil) -> CommunityPost {
        let isOwnPost = currentUserId != nil && authorId == currentUserId

        // For anonymous posts: hide author info from others, but show "(You)" to the author
        let displayAuthorName: String
        let displayAuthorUsername: String

        if isAnonymous {
            displayAuthorName = isOwnPost ? "Anonymous (You)" : "Anonymous"
            displayAuthorUsername = ""
        } else {
            displayAuthorName = author?.displayName ?? "Anonymous"
            displayAuthorUsername = "@\(author?.handle ?? "user")"
        }

        return CommunityPost(
            id: id,
            authorName: displayAuthorName,
            authorUsername: displayAuthorUsername,
            authorRole: isAnonymous ? "Member" : "Member", // Could be computed from user tier
            authorAvatar: isAnonymous ? nil : author?.avatarUrl,
            content: content,
            topic: CommunityTopicType(rawValue: topic)?.displayName ?? topic.capitalized,
            groupId: groupId,
            groupName: group?.name,
            timestamp: createdAt,
            likeCount: likeCount,
            commentCount: commentCount,
            isLiked: isLiked,
            isTrending: isTrending,
            topComment: nil, // Loaded separately if needed
            isSaved: isSaved,
            userReaction: userReaction,
            reactionCounts: reactionCounts,
            isOwnPost: isOwnPost,
            isAnonymous: isAnonymous
        )
    }
}

extension CommunityCommentDB {
    func toUIModel(isLiked: Bool = false, currentUserId: UUID? = nil) -> CommunityComment {
        let isOwnComment = currentUserId != nil && authorId == currentUserId

        // For anonymous comments: hide author info from others, but show "(You)" to the author
        let displayAuthorName: String
        let displayAuthorUsername: String

        if isAnonymous {
            displayAuthorName = isOwnComment ? "Anonymous (You)" : "Anonymous"
            displayAuthorUsername = ""
        } else {
            displayAuthorName = author?.displayName ?? "Anonymous"
            displayAuthorUsername = "@\(author?.handle ?? "user")"
        }

        return CommunityComment(
            id: id,
            authorId: authorId,
            authorName: displayAuthorName,
            authorUsername: displayAuthorUsername,
            content: content,
            timestamp: createdAt,
            likeCount: likeCount,
            parentCommentId: parentCommentId,
            replies: [],
            isLiked: isLiked,
            isOwnComment: isOwnComment,
            isAnonymous: isAnonymous
        )
    }
}

extension CommunityGroupDB {
    func toUIModel(isJoined: Bool = false) -> CommunityGroup {
        CommunityGroup(
            id: id,
            name: name,
            description: description ?? "",
            icon: icon,
            memberCount: memberCount,
            postCount: postCount,
            color: color,
            isJoined: isJoined
        )
    }
}

struct ReactionCountRow: Codable {
    let postId: UUID
    let reaction: String
    let count: Int

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case reaction
        case count
    }
}

// MARK: - Service Protocol

protocol CommunityServiceProtocol {
    // Posts
    func fetchFeed(filter: CommunityFeedFilter, page: Int, limit: Int) async throws -> [CommunityPost]
    func fetchGroupPosts(groupId: UUID) async throws -> [CommunityPost]
    func createPost(content: String, topic: CommunityTopicType, groupId: UUID?, isAnonymous: Bool) async throws -> CommunityPost
    func deletePost(id: UUID) async throws

    // Reactions
    func addReaction(to postId: UUID, reaction: String) async throws
    func removeReaction(from postId: UUID) async throws
    func getUserReaction(for postId: UUID) async throws -> String?

    // Groups
    func fetchGroups() async throws -> [CommunityGroup]
    func joinGroup(id: UUID) async throws
    func leaveGroup(id: UUID) async throws
    func getUserJoinedGroupIds() async throws -> Set<UUID>

    // Saved Posts
    func savePost(id: UUID) async throws
    func unsavePost(id: UUID) async throws
    func getUserSavedPostIds() async throws -> Set<UUID>

    // Reports
    func reportPost(id: UUID, reason: String, details: String?) async throws

    // Comments
    func fetchComments(for postId: UUID) async throws -> [CommunityCommentDB]
    func createComment(postId: UUID, content: String, parentCommentId: UUID?, isAnonymous: Bool) async throws -> CommunityCommentDB
    func deleteComment(id: UUID) async throws
    func likeComment(id: UUID) async throws
    func unlikeComment(id: UUID) async throws
}

// MARK: - Service Implementation

@MainActor
class CommunityService: CommunityServiceProtocol {

    // MARK: - Singleton
    static let shared = CommunityService()

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // Cache
    private var cachedGroups: [CommunityGroupDB]?
    private var cachedJoinedGroupIds: Set<UUID>?
    private var cachedSavedPostIds: Set<UUID>?
    private var cachedUserReactions: [UUID: String] = [:] // postId -> reaction

    // MARK: - Initialization
    private init() {}

    // MARK: - Posts

    func fetchFeed(filter: CommunityFeedFilter, page: Int = 0, limit: Int = 20) async throws -> [CommunityPost] {
        guard let session = try? await supabase.auth.session else {
            return []
        }

        let userId = session.user.id
        let offset = page * limit

        // Get user's reactions and saved posts for UI state
        let userReactions = try await fetchUserReactions()
        let savedPostIds = try await getUserSavedPostIds()

        var posts: [CommunityPostDB] = []

        // Select with author profile and group info
        let selectQuery = "*, profiles!community_posts_author_id_fkey(user_id, display_name, handle, avatar_url), community_groups(id, name)"

        switch filter {
        case .recent:
            posts = try await supabase
                .from("community_posts")
                .select(selectQuery)
                .eq("is_deleted", value: false)
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value

        case .myPosts:
            posts = try await supabase
                .from("community_posts")
                .select(selectQuery)
                .eq("author_id", value: userId.uuidString)
                .eq("is_deleted", value: false)
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value

        case .saved:
            // First get saved post IDs, then fetch those posts
            let savedPosts: [CommunitySavedPostDB] = try await supabase
                .from("community_saved_posts")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("saved_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value

            let postIds = savedPosts.map { $0.postId.uuidString }

            if !postIds.isEmpty {
                posts = try await supabase
                    .from("community_posts")
                    .select(selectQuery)
                    .in("id", values: postIds)
                    .eq("is_deleted", value: false)
                    .execute()
                    .value
            }
        }

        // Fetch reaction counts for all posts
        let reactionCountsMap = try await fetchReactionCounts(for: posts.map { $0.id })

        return posts.map { post in
            post.toUIModel(
                isLiked: userReactions[post.id] != nil,
                isSaved: savedPostIds.contains(post.id),
                userReaction: userReactions[post.id],
                reactionCounts: reactionCountsMap[post.id] ?? [:],
                currentUserId: userId
            )
        }
    }

    func createPost(content: String, topic: CommunityTopicType, groupId: UUID? = nil, isAnonymous: Bool = false) async throws -> CommunityPost {
        print("[CommunityService] createPost called - topic: \(topic), groupId: \(groupId?.uuidString ?? "nil"), isAnonymous: \(isAnonymous)")

        guard let session = try? await supabase.auth.session else {
            throw CommunityError.notAuthenticated
        }

        var insertData: [String: String] = [
            "author_id": session.user.id.uuidString,
            "content": content,
            "topic": topic.rawValue,
            "is_anonymous": isAnonymous ? "true" : "false"
        ]

        if let groupId = groupId {
            insertData["group_id"] = groupId.uuidString
        }

        do {
            let selectQuery = "*, profiles!community_posts_author_id_fkey(user_id, display_name, handle, avatar_url), community_groups(id, name)"

            let post: CommunityPostDB = try await supabase
                .from("community_posts")
                .insert(insertData)
                .select(selectQuery)
                .single()
                .execute()
                .value

            return post.toUIModel(isLiked: false, isSaved: false, currentUserId: session.user.id)
        } catch {
            throw error
        }
    }

    func deletePost(id: UUID) async throws {
        guard let session = try? await supabase.auth.session else {
            throw CommunityError.notAuthenticated
        }

        // Soft delete - set is_deleted to true (only if user is the author)
        try await supabase
            .from("community_posts")
            .update(["is_deleted": true])
            .eq("id", value: id.uuidString)
            .eq("author_id", value: session.user.id.uuidString)
            .execute()
    }

    /// Fetch posts for a specific group
    func fetchGroupPosts(groupId: UUID) async throws -> [CommunityPost] {
        guard let session = try? await supabase.auth.session else {
            return []
        }

        // Get user's reactions and saved posts for UI state
        let userReactions = try await fetchUserReactions()
        let savedPostIds = try await getUserSavedPostIds()

        let selectQuery = "*, profiles!community_posts_author_id_fkey(user_id, display_name, handle, avatar_url), community_groups(id, name)"

        let posts: [CommunityPostDB] = try await supabase
            .from("community_posts")
            .select(selectQuery)
            .eq("group_id", value: groupId.uuidString)
            .eq("is_deleted", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value

        let userId = session.user.id

        // Fetch reaction counts for group posts
        let reactionCountsMap = try await fetchReactionCounts(for: posts.map { $0.id })

        return posts.map { post in
            post.toUIModel(
                isLiked: userReactions[post.id] != nil,
                isSaved: savedPostIds.contains(post.id),
                userReaction: userReactions[post.id],
                reactionCounts: reactionCountsMap[post.id] ?? [:],
                currentUserId: userId
            )
        }
    }

    // MARK: - Reactions

    func addReaction(to postId: UUID, reaction: String = "heart") async throws {
        guard let session = try? await supabase.auth.session else {
            throw CommunityError.notAuthenticated
        }

        // Check if reaction already exists
        let existing: [CommunityReactionDB] = try await supabase
            .from("community_reactions")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("reactable_type", value: "post")
            .eq("reactable_id", value: postId.uuidString)
            .execute()
            .value

        if existing.isEmpty {
            try await supabase
                .from("community_reactions")
                .insert([
                    "user_id": session.user.id.uuidString,
                    "reactable_type": "post",
                    "reactable_id": postId.uuidString,
                    "reaction": reaction
                ])
                .execute()

            cachedUserReactions[postId] = reaction
        }
    }

    func removeReaction(from postId: UUID) async throws {
        guard let session = try? await supabase.auth.session else {
            throw CommunityError.notAuthenticated
        }

        try await supabase
            .from("community_reactions")
            .delete()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("reactable_type", value: "post")
            .eq("reactable_id", value: postId.uuidString)
            .execute()

        cachedUserReactions.removeValue(forKey: postId)
    }

    func getUserReaction(for postId: UUID) async throws -> String? {
        if let cached = cachedUserReactions[postId] {
            return cached
        }

        guard let session = try? await supabase.auth.session else {
            return nil
        }

        let reactions: [CommunityReactionDB] = try await supabase
            .from("community_reactions")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("reactable_type", value: "post")
            .eq("reactable_id", value: postId.uuidString)
            .limit(1)
            .execute()
            .value

        let reaction = reactions.first?.reaction
        if let reaction = reaction {
            cachedUserReactions[postId] = reaction
        }
        return reaction
    }

    private func fetchUserReactionPostIds() async throws -> Set<UUID> {
        let reactions = try await fetchUserReactions()
        return Set(reactions.keys)
    }

    /// Fetch aggregated reaction counts for a set of posts
    private func fetchReactionCounts(for postIds: [UUID]) async throws -> [UUID: [String: Int]] {
        guard !postIds.isEmpty else { return [:] }

        let postIdStrings = postIds.map { $0.uuidString }

        do {
            let rows: [ReactionCountRow] = try await supabase
                .rpc("get_reaction_counts", params: ["post_ids": postIdStrings])
                .execute()
                .value

            var result: [UUID: [String: Int]] = [:]
            for row in rows {
                result[row.postId, default: [:]][row.reaction] = row.count
            }
            return result
        } catch {
            print("[CommunityService] fetchReactionCounts - Error: \(error)")
            return [:]
        }
    }

    /// Fetch user reactions as a dictionary mapping postId -> reaction type
    private func fetchUserReactions() async throws -> [UUID: String] {
        guard let session = try? await supabase.auth.session else {
            return [:]
        }

        let reactions: [CommunityReactionDB] = try await supabase
            .from("community_reactions")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("reactable_type", value: "post")
            .execute()
            .value

        var reactionMap: [UUID: String] = [:]
        for reaction in reactions {
            reactionMap[reaction.reactableId] = reaction.reaction
            cachedUserReactions[reaction.reactableId] = reaction.reaction
        }
        return reactionMap
    }

    // MARK: - Groups

    func fetchGroups() async throws -> [CommunityGroup] {
        let joinedIds = try await getUserJoinedGroupIds()

        let groups: [CommunityGroupDB] = try await supabase
            .from("community_groups")
            .select()
            .order("member_count", ascending: false)
            .execute()
            .value

        print("[CommunityService] fetchGroups - Got \(groups.count) groups from DB")
        for group in groups {
            print("[CommunityService]   - \(group.name): \(group.memberCount) members, \(group.postCount) posts")
        }

        cachedGroups = groups

        return groups.map { group in
            group.toUIModel(isJoined: joinedIds.contains(group.id))
        }
    }

    func joinGroup(id: UUID) async throws {
        guard let session = try? await supabase.auth.session else {
            throw CommunityError.notAuthenticated
        }

        // Check if already a member
        let existing: [CommunityGroupMemberDB] = try await supabase
            .from("community_group_members")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("group_id", value: id.uuidString)
            .execute()
            .value

        if existing.isEmpty {
            try await supabase
                .from("community_group_members")
                .insert([
                    "user_id": session.user.id.uuidString,
                    "group_id": id.uuidString
                ])
                .execute()

            cachedJoinedGroupIds?.insert(id)
        }
    }

    func leaveGroup(id: UUID) async throws {
        guard let session = try? await supabase.auth.session else {
            throw CommunityError.notAuthenticated
        }

        try await supabase
            .from("community_group_members")
            .delete()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("group_id", value: id.uuidString)
            .execute()

        cachedJoinedGroupIds?.remove(id)
    }

    func getUserJoinedGroupIds() async throws -> Set<UUID> {
        if let cached = cachedJoinedGroupIds {
            return cached
        }

        guard let session = try? await supabase.auth.session else {
            return []
        }

        let memberships: [CommunityGroupMemberDB] = try await supabase
            .from("community_group_members")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .execute()
            .value

        let ids = Set(memberships.map { $0.groupId })
        cachedJoinedGroupIds = ids
        return ids
    }

    // MARK: - Saved Posts

    func savePost(id: UUID) async throws {
        guard let session = try? await supabase.auth.session else {
            throw CommunityError.notAuthenticated
        }

        // Check if already saved
        let existing: [CommunitySavedPostDB] = try await supabase
            .from("community_saved_posts")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("post_id", value: id.uuidString)
            .execute()
            .value

        if existing.isEmpty {
            try await supabase
                .from("community_saved_posts")
                .insert([
                    "user_id": session.user.id.uuidString,
                    "post_id": id.uuidString
                ])
                .execute()

            cachedSavedPostIds?.insert(id)
        }
    }

    func unsavePost(id: UUID) async throws {
        guard let session = try? await supabase.auth.session else {
            throw CommunityError.notAuthenticated
        }

        try await supabase
            .from("community_saved_posts")
            .delete()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("post_id", value: id.uuidString)
            .execute()

        cachedSavedPostIds?.remove(id)
    }

    func getUserSavedPostIds() async throws -> Set<UUID> {
        if let cached = cachedSavedPostIds {
            return cached
        }

        guard let session = try? await supabase.auth.session else {
            return []
        }

        let saved: [CommunitySavedPostDB] = try await supabase
            .from("community_saved_posts")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .execute()
            .value

        let ids = Set(saved.map { $0.postId })
        cachedSavedPostIds = ids
        return ids
    }

    // MARK: - Reports

    func reportPost(id: UUID, reason: String, details: String? = nil) async throws {
        guard let session = try? await supabase.auth.session else {
            throw CommunityError.notAuthenticated
        }

        var insertData: [String: String] = [
            "post_id": id.uuidString,
            "reporter_id": session.user.id.uuidString,
            "reason": reason
        ]

        if let details = details, !details.isEmpty {
            insertData["details"] = details
        }

        try await supabase
            .from("community_post_reports")
            .insert(insertData)
            .execute()
    }

    // MARK: - Comments

    func fetchComments(for postId: UUID) async throws -> [CommunityCommentDB] {
        print("[CommunityService] fetchComments - postId: \(postId)")

        let selectQuery = "*, profiles!community_comments_author_id_fkey(user_id, display_name, handle, avatar_url)"

        let comments: [CommunityCommentDB] = try await supabase
            .from("community_comments")
            .select(selectQuery)
            .eq("post_id", value: postId.uuidString)
            .eq("is_deleted", value: false)
            .order("created_at", ascending: true)
            .execute()
            .value

        print("[CommunityService] fetchComments - Got \(comments.count) comments")
        return comments
    }

    func createComment(postId: UUID, content: String, parentCommentId: UUID? = nil, isAnonymous: Bool = false) async throws -> CommunityCommentDB {
        print("[CommunityService] createComment - postId: \(postId), parentId: \(parentCommentId?.uuidString ?? "nil"), isAnonymous: \(isAnonymous)")

        guard let session = try? await supabase.auth.session else {
            print("[CommunityService] createComment - Not authenticated")
            throw CommunityError.notAuthenticated
        }

        var insertData: [String: String] = [
            "post_id": postId.uuidString,
            "author_id": session.user.id.uuidString,
            "content": content,
            "is_anonymous": isAnonymous ? "true" : "false"
        ]

        if let parentId = parentCommentId {
            insertData["parent_comment_id"] = parentId.uuidString
        }

        let selectQuery = "*, profiles!community_comments_author_id_fkey(user_id, display_name, handle, avatar_url)"

        let comment: CommunityCommentDB = try await supabase
            .from("community_comments")
            .insert(insertData)
            .select(selectQuery)
            .single()
            .execute()
            .value

        print("[CommunityService] createComment - SUCCESS, id: \(comment.id)")
        return comment
    }

    func deleteComment(id: UUID) async throws {
        print("[CommunityService] deleteComment - id: \(id)")

        guard let session = try? await supabase.auth.session else {
            print("[CommunityService] deleteComment - Not authenticated")
            throw CommunityError.notAuthenticated
        }

        // Hard delete - RLS policy ensures only author can delete
        try await supabase
            .from("community_comments")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        print("[CommunityService] deleteComment - SUCCESS")
    }

    func likeComment(id: UUID) async throws {
        print("[CommunityService] likeComment - id: \(id)")

        guard let session = try? await supabase.auth.session else {
            throw CommunityError.notAuthenticated
        }

        // Check if already liked
        let existing: [CommunityReactionDB] = try await supabase
            .from("community_reactions")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("reactable_type", value: "comment")
            .eq("reactable_id", value: id.uuidString)
            .execute()
            .value

        if existing.isEmpty {
            try await supabase
                .from("community_reactions")
                .insert([
                    "user_id": session.user.id.uuidString,
                    "reactable_type": "comment",
                    "reactable_id": id.uuidString,
                    "reaction": "thumbsup"  // Must match reaction_type enum: heart, thumbsup, lightbulb, fire, clap
                ])
                .execute()

            print("[CommunityService] likeComment - SUCCESS")
        }
    }

    func unlikeComment(id: UUID) async throws {
        print("[CommunityService] unlikeComment - id: \(id)")

        guard let session = try? await supabase.auth.session else {
            throw CommunityError.notAuthenticated
        }

        try await supabase
            .from("community_reactions")
            .delete()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("reactable_type", value: "comment")
            .eq("reactable_id", value: id.uuidString)
            .execute()

        print("[CommunityService] unlikeComment - SUCCESS")
    }

    // MARK: - Cache Management

    func clearCache() {
        cachedGroups = nil
        cachedJoinedGroupIds = nil
        cachedSavedPostIds = nil
        cachedUserReactions = [:]
    }
}

// MARK: - Errors

enum CommunityError: LocalizedError {
    case notAuthenticated
    case postNotFound
    case groupNotFound
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .postNotFound:
            return "Post not found"
        case .groupNotFound:
            return "Group not found"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}

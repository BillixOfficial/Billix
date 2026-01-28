//
//  CommentsViewModel.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  ViewModel for managing comments on community posts
//

import Foundation
import SwiftUI

@MainActor
class CommentsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var comments: [CommunityComment] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var error: String?
    @Published var newCommentText = ""
    @Published var replyingTo: CommunityComment?

    // MARK: - Private Properties

    private let service = CommunityService.shared
    private let postId: UUID
    private var currentUserId: UUID?

    // MARK: - Computed Properties

    /// Comments organized as a tree (top-level with nested replies)
    var organizedComments: [CommunityComment] {
        // Get top-level comments (no parent)
        var topLevel = comments.filter { $0.parentCommentId == nil }

        // Attach replies to their parents
        for i in topLevel.indices {
            topLevel[i].replies = comments.filter { $0.parentCommentId == topLevel[i].id }
        }

        return topLevel
    }

    var commentCount: Int {
        comments.count
    }

    var inputPlaceholder: String {
        if let replyingTo = replyingTo {
            return "Reply to \(replyingTo.authorUsername)..."
        }
        return "Add a comment..."
    }

    // MARK: - Initialization

    init(postId: UUID) {
        self.postId = postId
    }

    // MARK: - Public Methods

    func loadComments() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Get current user ID for ownership checks
            if let session = try? await SupabaseService.shared.client.auth.session {
                currentUserId = session.user.id
            }

            let dbComments = try await service.fetchComments(for: postId)

            // Get user's liked comment IDs
            let likedIds = await fetchUserLikedCommentIds()

            // Convert to UI models
            comments = dbComments.map { db in
                db.toUIModel(
                    isLiked: likedIds.contains(db.id),
                    currentUserId: currentUserId
                )
            }

            print("[CommentsViewModel] Loaded \(comments.count) comments")
        } catch {
            self.error = "Failed to load comments"
            print("[CommentsViewModel] Error loading comments: \(error)")
        }

        isLoading = false
    }

    func sendComment() async {
        let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        isSending = true

        // Optimistic update
        let tempId = UUID()
        let tempComment = CommunityComment(
            id: tempId,
            authorId: currentUserId,
            authorName: "You",
            authorUsername: "@you",
            content: text,
            timestamp: Date(),
            likeCount: 0,
            parentCommentId: replyingTo?.id,
            replies: [],
            isLiked: false,
            isOwnComment: true
        )

        // Add optimistically
        comments.append(tempComment)
        newCommentText = ""
        let parentId = replyingTo?.id
        replyingTo = nil

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        do {
            let dbComment = try await service.createComment(
                postId: postId,
                content: text,
                parentCommentId: parentId
            )

            // Replace temp comment with real one
            if let index = comments.firstIndex(where: { $0.id == tempId }) {
                comments[index] = dbComment.toUIModel(
                    isLiked: false,
                    currentUserId: currentUserId
                )
            }

            print("[CommentsViewModel] Comment created successfully")
        } catch {
            // Remove optimistic comment on failure
            comments.removeAll { $0.id == tempId }
            self.error = "Failed to post comment"
            print("[CommentsViewModel] Error creating comment: \(error)")
        }

        isSending = false
    }

    func deleteComment(_ comment: CommunityComment) async {
        guard comment.isOwnComment else { return }

        // Optimistic removal
        comments.removeAll { $0.id == comment.id }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        do {
            try await service.deleteComment(id: comment.id)
            print("[CommentsViewModel] Comment deleted successfully")
        } catch {
            // Restore on failure
            comments.append(comment)
            self.error = "Failed to delete comment"
            print("[CommentsViewModel] Error deleting comment: \(error)")
        }
    }

    func toggleLike(for comment: CommunityComment) async {
        guard let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }

        // Optimistic update
        let wasLiked = comments[index].isLiked
        comments[index].isLiked = !wasLiked
        comments[index].likeCount += wasLiked ? -1 : 1

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        do {
            if wasLiked {
                try await service.unlikeComment(id: comment.id)
            } else {
                try await service.likeComment(id: comment.id)
            }
        } catch {
            // Revert on failure
            comments[index].isLiked = wasLiked
            comments[index].likeCount += wasLiked ? 1 : -1
            print("[CommentsViewModel] Error toggling like: \(error)")
        }
    }

    func startReply(to comment: CommunityComment) {
        replyingTo = comment
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func cancelReply() {
        replyingTo = nil
    }

    // MARK: - Private Methods

    private func fetchUserLikedCommentIds() async -> Set<UUID> {
        guard let userId = currentUserId else { return [] }

        do {
            let reactions: [CommunityReactionDB] = try await SupabaseService.shared.client
                .from("community_reactions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("reactable_type", value: "comment")
                .execute()
                .value

            return Set(reactions.map { $0.reactableId })
        } catch {
            print("[CommentsViewModel] Error fetching liked comments: \(error)")
            return []
        }
    }
}

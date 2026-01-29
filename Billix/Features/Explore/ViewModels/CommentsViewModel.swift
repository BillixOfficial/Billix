//
//  CommentsViewModel.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  ViewModel for managing comments on community posts
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CommentsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var comments: [CommunityComment] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var error: String?
    @Published var newCommentText = ""
    @Published var replyingTo: CommunityComment?
    @Published var mentionText: String = ""  // Pre-filled @mention for nested replies
    @Published var replyParentId: UUID?  // The actual parent for the reply (top-level comment)
    @Published var commentCount: Int = 0  // Stored property for reliable SwiftUI updates
    @Published var isAnonymous: Bool = false  // Whether to post the comment anonymously

    // MARK: - Private Properties

    private let service = CommunityService.shared
    private let postId: UUID
    private var currentUserId: UUID?
    private var cancellables = Set<AnyCancellable>()

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

    var inputPlaceholder: String {
        if let replyingTo = replyingTo {
            return "Reply to \(replyingTo.authorUsername)..."
        }
        return "Add a comment..."
    }

    // MARK: - Initialization

    init(postId: UUID) {
        self.postId = postId

        // Keep commentCount in sync with comments array
        // Using Combine ensures SwiftUI always sees changes
        $comments
            .map { $0.count }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                guard let self = self else { return }
                print("[CommentsViewModel] Combine: comments.count changed to \(count)")
                self.commentCount = count
            }
            .store(in: &cancellables)
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

        // Use replyParentId (for nested replies goes to top-level parent)
        let parentId = replyParentId ?? replyingTo?.id
        let postAnonymously = isAnonymous
        print("[CommentsViewModel] sendComment:")
        print("  - Content: \(text)")
        print("  - replyParentId: \(replyParentId?.uuidString ?? "nil")")
        print("  - replyingTo?.id: \(replyingTo?.id.uuidString ?? "nil")")
        print("  - Final parentId: \(parentId?.uuidString ?? "nil (top-level comment)")")
        print("  - isAnonymous: \(postAnonymously)")

        // Optimistic update
        let tempId = UUID()
        let tempComment = CommunityComment(
            id: tempId,
            authorId: currentUserId,
            authorName: postAnonymously ? "Anonymous (You)" : "You",
            authorUsername: postAnonymously ? "" : "@you",
            content: text,
            timestamp: Date(),
            likeCount: 0,
            parentCommentId: parentId,
            replies: [],
            isLiked: false,
            isOwnComment: true,
            isAnonymous: postAnonymously
        )

        // Add optimistically
        comments.append(tempComment)
        newCommentText = ""
        mentionText = ""
        replyParentId = nil
        replyingTo = nil
        isAnonymous = false  // Reset after posting

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        do {
            let dbComment = try await service.createComment(
                postId: postId,
                content: text,
                parentCommentId: parentId,
                isAnonymous: postAnonymously
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

        // Store removed comments for potential rollback
        let removedComments = comments.filter { $0.id == comment.id || $0.parentCommentId == comment.id }
        let removedCount = removedComments.count

        // Optimistic removal - remove the comment AND its children (cascade)
        comments.removeAll { $0.id == comment.id || $0.parentCommentId == comment.id }
        print("[CommentsViewModel] deleteComment - Optimistically removed \(removedCount) comments (parent + children)")

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        do {
            try await service.deleteComment(id: comment.id)
            print("[CommentsViewModel] Comment deleted successfully")
        } catch {
            // Restore on failure
            comments.append(contentsOf: removedComments)
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

    /// Start a reply to a comment
    /// - Parameters:
    ///   - comment: The comment being replied to
    ///   - isNestedReply: Whether this is a reply to a nested comment (reply to a reply)
    ///   - topLevelParentId: For nested replies, the ID of the top-level parent comment
    func startReply(to comment: CommunityComment, isNestedReply: Bool = false, topLevelParentId: UUID? = nil) {
        replyingTo = comment

        print("[CommentsViewModel] startReply called:")
        print("  - Replying to: \(comment.authorUsername) (id: \(comment.id))")
        print("  - isNestedReply: \(isNestedReply)")
        print("  - topLevelParentId: \(topLevelParentId?.uuidString ?? "nil")")
        print("  - comment.parentCommentId: \(comment.parentCommentId?.uuidString ?? "nil")")

        if isNestedReply {
            // Reply goes to top-level parent, but @mention the nested user
            replyParentId = topLevelParentId ?? comment.parentCommentId
            mentionText = "\(comment.authorUsername) "
            newCommentText = mentionText
            print("  - NESTED REPLY: Auto-filled '\(mentionText)', replyParentId: \(replyParentId?.uuidString ?? "nil")")
        } else {
            // Direct reply to top-level comment
            replyParentId = comment.id
            mentionText = ""
            print("  - TOP-LEVEL REPLY: replyParentId set to comment.id: \(replyParentId?.uuidString ?? "nil")")
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func cancelReply() {
        replyingTo = nil
        replyParentId = nil
        mentionText = ""
        newCommentText = ""
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

//
//  CommunityFeedViewModel.swift
//  Billix
//
//  Created by Claude Code on 1/25/26.
//  ViewModel for Community Feed with Supabase backend
//

import Foundation
import Combine

@MainActor
class CommunityFeedViewModel: ObservableObject {

    // MARK: - Published Properties (Posts)
    @Published var posts: [CommunityPost] = []
    @Published var selectedFilter: CommunityFeedFilter = .recent
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: String?
    @Published var hasMorePages = true

    // MARK: - Published Properties (Groups) - Shared across tabs
    @Published var groups: [CommunityGroup] = []
    @Published var isLoadingGroups = false

    // MARK: - Published Properties (Group Posts) - For syncing across views
    @Published var groupPosts: [UUID: [CommunityPost]] = [:]
    @Published var isLoadingGroupPosts = false

    // MARK: - Computed Properties
    var joinedGroups: [CommunityGroup] {
        groups.filter { $0.isJoined }
    }

    // MARK: - Private Properties
    private let service: CommunityServiceProtocol
    private var currentPage = 0
    private let pageSize = 20

    // MARK: - Initialization

    init(service: CommunityServiceProtocol? = nil) {
        self.service = service ?? CommunityService.shared
    }

    // MARK: - Public Methods

    /// Load posts for the current filter
    func loadPosts() async {
        guard !isLoading else {
            print("[CommunityFeedViewModel] loadPosts - Already loading, skipping")
            return
        }

        print("[CommunityFeedViewModel] loadPosts - Starting for filter: \(selectedFilter)")
        isLoading = true
        error = nil
        currentPage = 0

        do {
            // Always reload groups to get fresh isJoined status (for CreatePostSheet)
            print("[CommunityFeedViewModel] loadPosts - Loading groups")
            let fetchedGroups = try await service.fetchGroups()
            print("[CommunityFeedViewModel] loadPosts - Got \(fetchedGroups.count) groups")
            for g in fetchedGroups {
                print("[CommunityFeedViewModel] loadPosts -   \(g.name): \(g.postCount) posts")
            }
            groups = fetchedGroups

            let fetchedPosts = try await service.fetchFeed(
                filter: selectedFilter,
                page: currentPage,
                limit: pageSize
            )
            print("[CommunityFeedViewModel] loadPosts - Got \(fetchedPosts.count) posts")
            posts = fetchedPosts
            hasMorePages = fetchedPosts.count >= pageSize
        } catch {
            print("[CommunityFeedViewModel] loadPosts - Error: \(error.localizedDescription)")
            self.error = error.localizedDescription
            // Keep existing posts on error rather than clearing or showing mock data
            // Only clear if there was no data before
            if posts.isEmpty {
                print("[CommunityFeedViewModel] loadPosts - No posts to show, keeping empty state")
            }
            // Keep existing groups on error
            if groups.isEmpty {
                print("[CommunityFeedViewModel] loadPosts - No groups loaded yet")
            }
        }

        isLoading = false
    }

    /// Refresh posts (pull-to-refresh)
    func refreshPosts() async {
        isRefreshing = true
        CommunityService.shared.clearCache()
        await loadPosts()
        isRefreshing = false
    }

    /// Load more posts (pagination)
    func loadMorePosts() async {
        guard !isLoading, hasMorePages else { return }

        currentPage += 1

        do {
            let morePosts = try await service.fetchFeed(
                filter: selectedFilter,
                page: currentPage,
                limit: pageSize
            )
            posts.append(contentsOf: morePosts)
            hasMorePages = morePosts.count >= pageSize
        } catch {
            currentPage -= 1 // Revert page on error
        }
    }

    /// Change filter and reload
    func setFilter(_ filter: CommunityFeedFilter) async {
        guard filter != selectedFilter else { return }
        selectedFilter = filter
        await loadPosts()
    }

    /// Load groups (called from Groups tab or when needed)
    func loadGroups() async {
        guard !isLoadingGroups else { return }

        isLoadingGroups = true

        do {
            groups = try await service.fetchGroups()
            print("[CommunityFeedViewModel] loadGroups - Got \(groups.count) groups, \(joinedGroups.count) joined")
        } catch {
            print("[CommunityFeedViewModel] loadGroups - Error: \(error)")
            self.error = error.localizedDescription
            // Keep existing groups on error - no mock data fallback
        }

        isLoadingGroups = false
    }

    /// Refresh groups (clears cache first)
    func refreshGroups() async {
        CommunityService.shared.clearCache()
        isLoadingGroups = false // Reset so loadGroups will run
        await loadGroups()
    }

    /// Load posts for a specific group (used by GroupDetailView)
    func loadGroupPosts(for groupId: UUID) async {
        guard !isLoadingGroupPosts else { return }

        isLoadingGroupPosts = true

        do {
            let fetchedPosts = try await service.fetchGroupPosts(groupId: groupId)
            groupPosts[groupId] = fetchedPosts
            print("[CommunityFeedViewModel] loadGroupPosts - Loaded \(fetchedPosts.count) posts for group: \(groupId)")
        } catch {
            print("[CommunityFeedViewModel] loadGroupPosts - Error: \(error)")
            groupPosts[groupId] = []
        }

        isLoadingGroupPosts = false
    }

    // MARK: - Group Actions

    /// Toggle join/leave for a group (optimistic update)
    func toggleJoin(for group: CommunityGroup) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }

        // Optimistic update
        let wasJoined = groups[index].isJoined
        let previousMemberCount = groups[index].memberCount
        groups[index].isJoined.toggle()
        groups[index].memberCount += wasJoined ? -1 : 1

        // Sync with backend
        Task {
            do {
                if wasJoined {
                    try await service.leaveGroup(id: group.id)
                } else {
                    try await service.joinGroup(id: group.id)
                }
                print("[CommunityFeedViewModel] toggleJoin - \(wasJoined ? "Left" : "Joined") \(group.name)")
            } catch {
                // Revert on failure
                if let idx = groups.firstIndex(where: { $0.id == group.id }) {
                    groups[idx].isJoined = wasJoined
                    groups[idx].memberCount = previousMemberCount
                }
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Post Actions

    /// Set a specific reaction on a post (optimistic update) - syncs across feed and group views
    func setReaction(for post: CommunityPost, reaction: String) {
        let wasLiked = post.isLiked
        let previousLikeCount = post.likeCount
        let previousReaction = post.userReaction

        print("[CommunityFeedViewModel] 🔥 setReaction START - Post: \(post.id), reaction: \(reaction)")
        print("[CommunityFeedViewModel] 🔥 setReaction - wasLiked: \(wasLiked), previousReaction: \(previousReaction ?? "none")")

        // Optimistic update in main posts array
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isLiked = true
            posts[index].userReaction = reaction
            if !wasLiked {
                posts[index].likeCount = previousLikeCount + 1
            }
        }

        // Also update in groupPosts to keep views in sync
        for (groupId, var groupPostList) in groupPosts {
            if let index = groupPostList.firstIndex(where: { $0.id == post.id }) {
                groupPostList[index].isLiked = true
                groupPostList[index].userReaction = reaction
                if !wasLiked {
                    groupPostList[index].likeCount = previousLikeCount + 1
                }
                groupPosts[groupId] = groupPostList
            }
        }

        // Sync with backend
        Task {
            do {
                // If already had a reaction, remove it first then add new one
                if wasLiked {
                    print("[CommunityFeedViewModel] 🔥 setReaction - removing old reaction first...")
                    try await service.removeReaction(from: post.id)
                }
                print("[CommunityFeedViewModel] 🔥 setReaction - adding new reaction: \(reaction)")
                try await service.addReaction(to: post.id, reaction: reaction)
                print("[CommunityFeedViewModel] 🔥 setReaction COMPLETE ✅ - no more state changes")
            } catch {
                print("[CommunityFeedViewModel] 🔥 setReaction - ERROR: \(error)")
                // Revert in main posts array
                if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[idx].isLiked = wasLiked
                    posts[idx].userReaction = previousReaction
                    posts[idx].likeCount = previousLikeCount
                }
                // Revert in groupPosts
                for (groupId, var groupPostList) in groupPosts {
                    if let idx = groupPostList.firstIndex(where: { $0.id == post.id }) {
                        groupPostList[idx].isLiked = wasLiked
                        groupPostList[idx].userReaction = previousReaction
                        groupPostList[idx].likeCount = previousLikeCount
                        groupPosts[groupId] = groupPostList
                    }
                }
            }
        }
    }

    /// Toggle like on a post (optimistic update) - syncs across feed and group views
    func toggleLike(for post: CommunityPost) {
        // Determine current state from the post passed in
        let wasLiked = post.isLiked
        let previousLikeCount = post.likeCount
        let previousReaction = post.userReaction
        let newIsLiked = !wasLiked
        let newLikeCount = wasLiked ? previousLikeCount - 1 : previousLikeCount + 1

        print("[CommunityFeedViewModel] ❤️ toggleLike START - Post: \(post.id)")
        print("[CommunityFeedViewModel] ❤️ toggleLike - wasLiked: \(wasLiked), now isLiked: \(newIsLiked)")
        print("[CommunityFeedViewModel] ❤️ toggleLike - likeCount: \(previousLikeCount) -> \(newLikeCount)")

        // Optimistic update in main posts array
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isLiked = newIsLiked
            posts[index].likeCount = newLikeCount
            posts[index].userReaction = newIsLiked ? "heart" : nil
        }

        // Also update in groupPosts to keep views in sync
        for (groupId, var groupPostList) in groupPosts {
            if let index = groupPostList.firstIndex(where: { $0.id == post.id }) {
                groupPostList[index].isLiked = newIsLiked
                groupPostList[index].likeCount = newLikeCount
                groupPostList[index].userReaction = newIsLiked ? "heart" : nil
                groupPosts[groupId] = groupPostList
            }
        }

        // Sync with backend
        Task {
            do {
                if wasLiked {
                    print("[CommunityFeedViewModel] ❤️ toggleLike - Calling removeReaction...")
                    try await service.removeReaction(from: post.id)
                    print("[CommunityFeedViewModel] ❤️ toggleLike - removeReaction SUCCESS ✅")
                } else {
                    print("[CommunityFeedViewModel] ❤️ toggleLike - Calling addReaction...")
                    try await service.addReaction(to: post.id, reaction: "heart")
                    print("[CommunityFeedViewModel] ❤️ toggleLike - addReaction SUCCESS ✅")
                }
                print("[CommunityFeedViewModel] ❤️ toggleLike COMPLETE - no more state changes")
            } catch {
                print("[CommunityFeedViewModel] ❤️ toggleLike - ERROR: \(error)")
                print("[CommunityFeedViewModel] ❤️ toggleLike - Reverting optimistic update")
                // Revert in main posts array
                if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[idx].isLiked = wasLiked
                    posts[idx].likeCount = previousLikeCount
                    posts[idx].userReaction = previousReaction
                }
                // Revert in groupPosts
                for (groupId, var groupPostList) in groupPosts {
                    if let idx = groupPostList.firstIndex(where: { $0.id == post.id }) {
                        groupPostList[idx].isLiked = wasLiked
                        groupPostList[idx].likeCount = previousLikeCount
                        groupPostList[idx].userReaction = previousReaction
                        groupPosts[groupId] = groupPostList
                    }
                }
            }
        }
    }

    /// Toggle save on a post (optimistic update) - syncs across feed and group views
    func toggleSave(for post: CommunityPost) {
        // Determine current state from the post passed in
        let wasSaved = post.isSaved
        let newIsSaved = !wasSaved

        print("[CommunityFeedViewModel] toggleSave - Post: \(post.id), wasSaved: \(wasSaved)")

        // Optimistic update in main posts array
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isSaved = newIsSaved
        }

        // Also update in groupPosts to keep views in sync
        for (groupId, var groupPostList) in groupPosts {
            if let index = groupPostList.firstIndex(where: { $0.id == post.id }) {
                groupPostList[index].isSaved = newIsSaved
                groupPosts[groupId] = groupPostList
            }
        }

        // Sync with backend
        Task {
            do {
                if wasSaved {
                    try await service.unsavePost(id: post.id)
                } else {
                    try await service.savePost(id: post.id)
                }
                print("[CommunityFeedViewModel] toggleSave - SUCCESS")
            } catch {
                print("[CommunityFeedViewModel] toggleSave - ERROR: \(error)")
                // Revert in main posts array
                if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[idx].isSaved = wasSaved
                }
                // Revert in groupPosts
                for (groupId, var groupPostList) in groupPosts {
                    if let idx = groupPostList.firstIndex(where: { $0.id == post.id }) {
                        groupPostList[idx].isSaved = wasSaved
                        groupPosts[groupId] = groupPostList
                    }
                }
            }
        }
    }

    /// Create a new post
    func createPost(content: String, topic: PostTopic, groupId: UUID? = nil, isAnonymous: Bool = false) async -> Bool {
        print("[CommunityFeedViewModel] createPost - content: \(content.prefix(50))..., topic: \(topic), isAnonymous: \(isAnonymous)")

        do {
            let topicType = CommunityTopicType(rawValue: topic.rawValue.lowercased()) ?? .general
            print("[CommunityFeedViewModel] createPost - topicType: \(topicType)")

            let newPost = try await service.createPost(
                content: content,
                topic: topicType,
                groupId: groupId,
                isAnonymous: isAnonymous
            )
            print("[CommunityFeedViewModel] createPost - Success! Post: \(newPost.id)")
            // Insert at top of feed
            posts.insert(newPost, at: 0)

            // Also add to groupPosts if this post belongs to a group
            if let groupId = groupId {
                if groupPosts[groupId] != nil {
                    groupPosts[groupId]?.insert(newPost, at: 0)
                } else {
                    groupPosts[groupId] = [newPost]
                }

                // Increment group post count
                if let index = groups.firstIndex(where: { $0.id == groupId }) {
                    groups[index].postCount += 1
                    print("[CommunityFeedViewModel] createPost - Incremented group postCount: \(groups[index].postCount)")
                }
            }

            return true
        } catch {
            print("[CommunityFeedViewModel] createPost - ERROR: \(error)")
            self.error = error.localizedDescription
            return false
        }
    }

    /// Delete a post (optimistic update for instant UI feedback)
    func deletePost(_ post: CommunityPost) async -> Bool {
        print("[CommunityFeedViewModel] deletePost called - postId: \(post.id)")

        // Store original state for potential rollback
        let originalPosts = posts
        let originalGroupPosts = groupPosts
        let originalGroups = groups
        let groupId = post.groupId

        // Optimistic update: Remove from UI immediately
        posts.removeAll { $0.id == post.id }
        print("[CommunityFeedViewModel] deletePost - Optimistically removed from posts")

        // Remove from groupPosts
        for (gId, var groupPostList) in groupPosts {
            let beforeCount = groupPostList.count
            groupPostList.removeAll { $0.id == post.id }
            if beforeCount != groupPostList.count {
                print("[CommunityFeedViewModel] deletePost - Optimistically removed from group \(gId)")
            }
            groupPosts[gId] = groupPostList
        }

        // Decrement group post count (optimistic update)
        if let groupId = groupId, let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].postCount = max(0, groups[index].postCount - 1)
            print("[CommunityFeedViewModel] deletePost - Decremented group postCount: \(groups[index].postCount)")
        }

        // Sync with backend
        do {
            try await service.deletePost(id: post.id)
            print("[CommunityFeedViewModel] deletePost - SUCCESS")
            return true
        } catch {
            print("[CommunityFeedViewModel] deletePost - ERROR: \(error), rolling back")
            // Rollback on failure
            posts = originalPosts
            groupPosts = originalGroupPosts
            groups = originalGroups
            self.error = error.localizedDescription
            return false
        }
    }

    /// Update comment count for a post (called from CommentsSheetView)
    func updateCommentCount(for postId: UUID, count: Int) {
        print("[CommunityFeedViewModel] updateCommentCount called - postId: \(postId), newCount: \(count)")

        // Explicitly notify SwiftUI that we're about to change
        objectWillChange.send()

        // Update in main posts array - create new copy to trigger SwiftUI update
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            let oldCount = posts[index].commentCount
            guard oldCount != count else {
                print("[CommunityFeedViewModel] updateCommentCount - No change needed, already \(count)")
                return
            }
            // Create a new copy and replace to ensure SwiftUI detects the change
            var updatedPost = posts[index]
            updatedPost.commentCount = count
            posts[index] = updatedPost
            print("[CommunityFeedViewModel] updateCommentCount - Updated posts[\(index)] from \(oldCount) to \(count) ✅")
        } else {
            print("[CommunityFeedViewModel] updateCommentCount - Post not found in posts array!")
        }

        // Also update in groupPosts to keep views in sync
        for (groupId, var groupPostList) in groupPosts {
            if let index = groupPostList.firstIndex(where: { $0.id == postId }) {
                var updatedPost = groupPostList[index]
                updatedPost.commentCount = count
                groupPostList[index] = updatedPost
                groupPosts[groupId] = groupPostList
                print("[CommunityFeedViewModel] updateCommentCount - Updated groupPosts[\(groupId)][\(index)] ✅")
            }
        }
    }

    /// Report a post
    func reportPost(_ post: CommunityPost, reason: String, details: String? = nil) async -> Bool {
        do {
            try await service.reportPost(id: post.id, reason: reason, details: details)
            print("[CommunityFeedViewModel] reportPost - SUCCESS for post \(post.id)")
            return true
        } catch {
            print("[CommunityFeedViewModel] reportPost - ERROR: \(error)")
            self.error = error.localizedDescription
            return false
        }
    }

    // MARK: - Filtering

    /// Filter posts by search text (client-side)
    func filteredPosts(searchText: String) -> [CommunityPost] {
        guard !searchText.isEmpty else { return posts }

        return posts.filter {
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.authorName.localizedCaseInsensitiveContains(searchText) ||
            ($0.topic ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Filter groups by search text (client-side)
    func filteredGroups(searchText: String) -> [CommunityGroup] {
        guard !searchText.isEmpty else { return groups }

        return groups.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
}

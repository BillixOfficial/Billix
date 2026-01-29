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
    private let maxPostsInMemory = 100  // Prevent unbounded memory growth

    // MARK: - Initialization

    init(service: CommunityServiceProtocol? = nil) {
        self.service = service ?? CommunityService.shared
    }

    // MARK: - Public Methods

    /// Load posts for the current filter
    func loadPosts() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        error = nil
        currentPage = 0

        do {
            // Always reload groups to get fresh isJoined status (for CreatePostSheet)
            groups = try await service.fetchGroups()

            let fetchedPosts = try await service.fetchFeed(
                filter: selectedFilter,
                page: currentPage,
                limit: pageSize
            )
            posts = fetchedPosts
            hasMorePages = fetchedPosts.count >= pageSize
        } catch {
            self.error = error.localizedDescription
            // Fall back to mock data if fetch fails
            if selectedFilter == .recent {
                posts = CommunityPost.mockPosts
            } else {
                posts = []
            }
            // Fall back to mock groups if needed
            if groups.isEmpty {
                groups = CommunityGroup.mockGroups
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

    /// Load more posts (pagination with memory cap)
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

            // Cap posts to prevent unbounded memory growth (windowed pagination)
            if posts.count > maxPostsInMemory {
                posts.removeFirst(posts.count - maxPostsInMemory)
            }

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
        } catch {
            // Fall back to mock data if fetch fails
            if groups.isEmpty {
                groups = CommunityGroup.mockGroups
            }
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
        } catch {
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
                    try await service.removeReaction(from: post.id)
                }
                try await service.addReaction(to: post.id, reaction: reaction)
            } catch {
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
                    try await service.removeReaction(from: post.id)
                } else {
                    try await service.addReaction(to: post.id, reaction: "heart")
                }
            } catch {
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
            } catch {
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
    func createPost(content: String, topic: PostTopic, groupId: UUID? = nil) async -> Bool {
        do {
            let topicType = CommunityTopicType(rawValue: topic.rawValue.lowercased()) ?? .general

            let newPost = try await service.createPost(
                content: content,
                topic: topicType,
                groupId: groupId
            )
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
                }
            }

            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    /// Delete a post (optimistic update for instant UI feedback)
    func deletePost(_ post: CommunityPost) async -> Bool {
        // Store original state for potential rollback
        let originalPosts = posts
        let originalGroupPosts = groupPosts
        let originalGroups = groups
        let groupId = post.groupId

        // Optimistic update: Remove from UI immediately
        posts.removeAll { $0.id == post.id }

        // Remove from groupPosts
        for (gId, var groupPostList) in groupPosts {
            groupPostList.removeAll { $0.id == post.id }
            groupPosts[gId] = groupPostList
        }

        // Decrement group post count (optimistic update)
        if let groupId = groupId, let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].postCount = max(0, groups[index].postCount - 1)
        }

        // Sync with backend
        do {
            try await service.deletePost(id: post.id)
            return true
        } catch {
            // Rollback on failure
            posts = originalPosts
            groupPosts = originalGroupPosts
            groups = originalGroups
            self.error = error.localizedDescription
            return false
        }
    }

    /// Report a post
    func reportPost(_ post: CommunityPost, reason: String, details: String? = nil) async -> Bool {
        do {
            try await service.reportPost(id: post.id, reason: reason, details: details)
            return true
        } catch {
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

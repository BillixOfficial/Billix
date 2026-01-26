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
            groups = try await service.fetchGroups()
            print("[CommunityFeedViewModel] loadPosts - Got \(groups.count) groups")

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
            // Fall back to mock data if fetch fails
            if selectedFilter == .recent {
                print("[CommunityFeedViewModel] loadPosts - Falling back to mock data")
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

    /// Toggle like on a post (optimistic update) - syncs across feed and group views
    func toggleLike(for post: CommunityPost) {
        // Determine current state from the post passed in
        let wasLiked = post.isLiked
        let previousLikeCount = post.likeCount
        let newIsLiked = !wasLiked
        let newLikeCount = wasLiked ? previousLikeCount - 1 : previousLikeCount + 1

        print("[CommunityFeedViewModel] toggleLike - Post: \(post.id)")
        print("[CommunityFeedViewModel] toggleLike - wasLiked: \(wasLiked), now isLiked: \(newIsLiked)")
        print("[CommunityFeedViewModel] toggleLike - likeCount: \(previousLikeCount) -> \(newLikeCount)")

        // Optimistic update in main posts array
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isLiked = newIsLiked
            posts[index].likeCount = newLikeCount
        }

        // Also update in groupPosts to keep views in sync
        for (groupId, var groupPostList) in groupPosts {
            if let index = groupPostList.firstIndex(where: { $0.id == post.id }) {
                groupPostList[index].isLiked = newIsLiked
                groupPostList[index].likeCount = newLikeCount
                groupPosts[groupId] = groupPostList
            }
        }

        // Sync with backend
        Task {
            do {
                if wasLiked {
                    print("[CommunityFeedViewModel] toggleLike - Calling removeReaction...")
                    try await service.removeReaction(from: post.id)
                    print("[CommunityFeedViewModel] toggleLike - removeReaction SUCCESS")
                } else {
                    print("[CommunityFeedViewModel] toggleLike - Calling addReaction...")
                    try await service.addReaction(to: post.id, reaction: "heart")
                    print("[CommunityFeedViewModel] toggleLike - addReaction SUCCESS")
                }
            } catch {
                print("[CommunityFeedViewModel] toggleLike - ERROR: \(error)")
                print("[CommunityFeedViewModel] toggleLike - Reverting optimistic update")
                // Revert in main posts array
                if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[idx].isLiked = wasLiked
                    posts[idx].likeCount = previousLikeCount
                }
                // Revert in groupPosts
                for (groupId, var groupPostList) in groupPosts {
                    if let idx = groupPostList.firstIndex(where: { $0.id == post.id }) {
                        groupPostList[idx].isLiked = wasLiked
                        groupPostList[idx].likeCount = previousLikeCount
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
    func createPost(content: String, topic: PostTopic, groupId: UUID? = nil) async -> Bool {
        print("[CommunityFeedViewModel] createPost - content: \(content.prefix(50))..., topic: \(topic)")

        do {
            let topicType = CommunityTopicType(rawValue: topic.rawValue.lowercased()) ?? .general
            print("[CommunityFeedViewModel] createPost - topicType: \(topicType)")

            let newPost = try await service.createPost(
                content: content,
                topic: topicType,
                groupId: groupId
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
            }

            return true
        } catch {
            print("[CommunityFeedViewModel] createPost - ERROR: \(error)")
            self.error = error.localizedDescription
            return false
        }
    }

    /// Delete a post
    func deletePost(_ post: CommunityPost) async -> Bool {
        do {
            try await service.deletePost(id: post.id)
            posts.removeAll { $0.id == post.id }

            // Also remove from groupPosts
            for (groupId, var groupPostList) in groupPosts {
                groupPostList.removeAll { $0.id == post.id }
                groupPosts[groupId] = groupPostList
            }

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

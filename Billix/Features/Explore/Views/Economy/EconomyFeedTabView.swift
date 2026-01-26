//
//  EconomyFeedTabView.swift
//  Billix
//
//  Created by Claude Code on 1/24/26.
//  Feed tab showing community posts in Economy section
//  Modern social feed inspired by Reddit, Glassdoor, and fintech apps
//

import SwiftUI

struct EconomyFeedTabView: View {
    @Binding var searchText: String
    @State private var posts: [CommunityPost] = CommunityPost.mockPosts
    @State private var selectedFilter: CommunityFeedFilter = .recent
    @State private var isRefreshing = false
    @State private var isButtonExpanded = true
    @State private var lastOffsetY: CGFloat = 0
    @State private var showCreatePostSheet = false

    private let backgroundColor = Color(hex: "#F5F5F7")

    var filteredPosts: [CommunityPost] {
        var result: [CommunityPost]
        switch selectedFilter {
        case .myPosts:
            // In future: filter by current user's posts
            result = [] // Empty for now since user hasn't posted yet
        case .recent:
            result = posts
        case .saved:
            // In future: filter by saved/bookmarked posts
            result = [] // Empty for now since user hasn't saved any posts yet
        }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.authorName.localizedCaseInsensitiveContains(searchText) ||
                ($0.topic ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    // Scroll tracker
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: geo.frame(in: .global).minY) { oldValue, newValue in
                                let delta = newValue - lastOffsetY

                                // Always expand when at or near the top
                                if newValue > 100 {
                                    if !isButtonExpanded {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isButtonExpanded = true
                                        }
                                    }
                                } else if abs(delta) > 5 {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        // Scrolling down (content moving up) = collapse
                                        // Scrolling up (content moving down) = expand
                                        isButtonExpanded = delta > 0
                                    }
                                }
                                lastOffsetY = newValue
                            }
                    }
                    .frame(height: 0)

                    // Filter Chips
                    filterChipsRow
                        .padding(.top, 12)
                        .padding(.bottom, 16)

                    // Posts Section Header
                    HStack {
                        Text(selectedFilter.rawValue)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#1A1A1A"))

                        Spacer()

                        if !filteredPosts.isEmpty {
                            Text("\(filteredPosts.count) posts")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#6B7280"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    // Posts
                    if filteredPosts.isEmpty {
                        emptyStateView
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPosts) { post in
                                CommunityPostCard(
                                    post: post,
                                    onLikeTapped: { toggleLike(for: post) },
                                    onCommentTapped: { /* Future: Show comments */ },
                                    onSaveTapped: { /* Future: Save post */ }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Bottom Spacing for FAB
                    Spacer()
                        .frame(height: 80)
                }
            }
            .background(backgroundColor)
            .refreshable {
                await refreshPosts()
            }

            // Floating Post Button
            floatingPostButton
        }
        .sheet(isPresented: $showCreatePostSheet) {
            CreatePostSheet(
                availableGroups: CommunityGroup.mockGroups,
                preselectedGroup: nil
            ) { content, topic, group in
                // Create new post and add to feed
                let newPost = CommunityPost(
                    authorName: "You",
                    authorUsername: "@you",
                    authorRole: "Member",
                    content: content,
                    topic: topic.rawValue,
                    timestamp: Date(),
                    likeCount: 0,
                    commentCount: 0,
                    isLiked: false,
                    isTrending: false
                )
                posts.insert(newPost, at: 0)
            }
        }
    }

    // MARK: - Floating Post Button

    private var floatingPostButton: some View {
        Button {
            showCreatePostSheet = true
        } label: {
            HStack(spacing: isButtonExpanded ? 8 : 0) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))

                if isButtonExpanded {
                    Text("Post")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, isButtonExpanded ? 24 : 16)
            .padding(.vertical, 14)
            .background(Color(hex: "#1A1A1A"))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 70)
    }

    // MARK: - Filter Chips Row

    private var filterChipsRow: some View {
        HStack(spacing: 10) {
            ForEach(CommunityFeedFilter.allCases, id: \.self) { filter in
                filterChip(filter)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }

    private func filterChip(_ filter: CommunityFeedFilter) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(selectedFilter == filter ? .white : Color(hex: "#4B5563"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Group {
                    if selectedFilter == filter {
                        LinearGradient(
                            colors: [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white
                    }
                }
            )
            .clipShape(Capsule())
            .shadow(color: selectedFilter == filter ? Color.billixDarkTeal.opacity(0.3) : .black.opacity(0.05),
                    radius: selectedFilter == filter ? 8 : 4,
                    x: 0,
                    y: selectedFilter == filter ? 4 : 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter.emptyIcon)
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#D1D5DB"))

            Text("No \(selectedFilter.rawValue.lowercased()) yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "#374151"))

            Text("Be the first to share something!")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Actions

    private func toggleLike(for post: CommunityPost) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isLiked.toggle()
            if posts[index].isLiked {
                posts[index].likeCount += 1
            } else {
                posts[index].likeCount -= 1
            }
        }
    }

    private func refreshPosts() async {
        isRefreshing = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // In future: Fetch from API
        posts = CommunityPost.mockPosts
        isRefreshing = false
    }
}

// MARK: - Feed Filter Enum

enum CommunityFeedFilter: String, CaseIterable {
    case myPosts = "My Posts"
    case recent = "Recent"
    case saved = "Saved"

    var icon: String {
        switch self {
        case .myPosts: return "person.fill"
        case .recent: return "clock"
        case .saved: return "bookmark.fill"
        }
    }

    var emptyIcon: String {
        switch self {
        case .myPosts: return "person.slash"
        case .recent: return "clock.badge.xmark"
        case .saved: return "bookmark.slash"
        }
    }
}

// MARK: - Preview

#Preview("Economy Feed Tab") {
    EconomyFeedTabView(searchText: .constant(""))
}

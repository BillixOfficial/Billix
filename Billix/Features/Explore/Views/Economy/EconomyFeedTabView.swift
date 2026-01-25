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
    @State private var posts: [CommunityPost] = CommunityPost.mockPosts
    @State private var selectedFilter: CommunityFeedFilter = .recentPosts
    @State private var isRefreshing = false

    private let backgroundColor = Color(hex: "#F5F5F7")

    var filteredPosts: [CommunityPost] {
        switch selectedFilter {
        case .yourPosts:
            // In future: filter by current user's posts
            return [] // Empty for now since user hasn't posted yet
        case .recentPosts:
            return posts
        case .questions:
            return posts.filter { $0.topic == "Question" }
        case .tips:
            return posts.filter { $0.topic == "Tips" }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
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
                                onShareTapped: { /* Future: Share sheet */ }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Bottom Spacing
                Spacer()
                    .frame(height: 100)
            }
        }
        .background(backgroundColor)
        .refreshable {
            await refreshPosts()
        }
    }

    // MARK: - Filter Chips Row

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CommunityFeedFilter.allCases, id: \.self) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, 16)
        }
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
    case yourPosts = "Your Posts"
    case recentPosts = "Recent Posts"
    case questions = "Questions"
    case tips = "Tips"

    var icon: String {
        switch self {
        case .yourPosts: return "person.fill"
        case .recentPosts: return "clock"
        case .questions: return "questionmark.circle"
        case .tips: return "lightbulb"
        }
    }

    var emptyIcon: String {
        switch self {
        case .yourPosts: return "person.slash"
        case .recentPosts: return "clock.badge.xmark"
        case .questions: return "questionmark.circle"
        case .tips: return "lightbulb.slash"
        }
    }
}

// MARK: - Preview

#Preview("Economy Feed Tab") {
    EconomyFeedTabView()
}

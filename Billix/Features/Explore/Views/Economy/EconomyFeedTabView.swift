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
    @ObservedObject var viewModel: CommunityFeedViewModel
    @Binding var searchText: String
    @ObservedObject var groupsRouter: GroupsNavigationRouter  // For navigating to groups from posts
    @State private var isButtonExpanded = true
    @State private var lastOffsetY: CGFloat = 0
    @State private var showCreatePostSheet = false
    @State private var showCommentsSheet = false
    @State private var selectedPostForComments: CommunityPost?

    private let backgroundColor = Color(hex: "#F5F5F7")

    var filteredPosts: [CommunityPost] {
        viewModel.filteredPosts(searchText: searchText)
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
                        Text(viewModel.selectedFilter.rawValue)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#1A1A1A"))

                        Spacer()

                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if !filteredPosts.isEmpty {
                            Text("\(filteredPosts.count) posts")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#6B7280"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    // Posts
                    if filteredPosts.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPosts) { post in
                                CommunityPostCard(
                                    post: post,
                                    onLikeTapped: { viewModel.toggleLike(for: post) },
                                    onCommentTapped: {
                                        selectedPostForComments = post
                                        showCommentsSheet = true
                                    },
                                    onSaveTapped: { viewModel.toggleSave(for: post) },
                                    onReactionSelected: { reaction in
                                        viewModel.setReaction(for: post, reaction: reaction.stringValue)
                                    },
                                    onGroupTapped: { groupId in
                                        // Find the group and navigate to it
                                        if let group = viewModel.groups.first(where: { $0.id == groupId }) {
                                            groupsRouter.navigateTo(group: group)
                                        }
                                    },
                                    onDeleteTapped: {
                                        Task {
                                            _ = await viewModel.deletePost(post)
                                        }
                                    },
                                    onReportSubmitted: { reason, details in
                                        Task {
                                            _ = await viewModel.reportPost(post, reason: reason, details: details)
                                        }
                                    }
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
                await viewModel.refreshPosts()
            }

            // Floating Post Button
            floatingPostButton
        }
        .sheet(isPresented: $showCreatePostSheet) {
            CreatePostSheet(
                availableGroups: viewModel.groups,
                preselectedGroup: nil
            ) { content, topic, group in
                Task {
                    _ = await viewModel.createPost(content: content, topic: topic, groupId: group?.id)
                }
            }
        }
        .sheet(isPresented: $showCommentsSheet) {
            if let post = selectedPostForComments {
                CommentsSheetView(post: post) { newCount in
                    viewModel.updateCommentCount(for: post.id, count: newCount)
                }
            }
        }
        .task {
            await viewModel.loadPosts()
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
        let isSelected = viewModel.selectedFilter == filter

        return Button {
            Task {
                await viewModel.setFilter(filter)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "#4B5563"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
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
            .shadow(color: isSelected ? Color.billixDarkTeal.opacity(0.3) : .black.opacity(0.05),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.selectedFilter.emptyIcon)
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#D1D5DB"))

            Text("No \(viewModel.selectedFilter.rawValue.lowercased()) yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "#374151"))

            Text("Be the first to share something!")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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
    EconomyFeedTabView(viewModel: CommunityFeedViewModel(), searchText: .constant(""), groupsRouter: GroupsNavigationRouter())
}

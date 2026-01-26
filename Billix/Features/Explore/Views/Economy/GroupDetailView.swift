//
//  GroupDetailView.swift
//  Billix
//
//  Created by Claude Code on 1/25/26.
//  Detail view for a community group showing posts
//

import SwiftUI

struct GroupDetailView: View {
    let group: CommunityGroup
    @Environment(\.dismiss) private var dismiss
    @State private var posts: [CommunityPost] = CommunityPost.mockPosts
    @State private var isButtonExpanded = true
    @State private var lastOffsetY: CGFloat = 0
    @State private var isJoined: Bool
    @State private var showCreatePostSheet = false

    private let backgroundColor = Color(hex: "#F5F5F7")

    init(group: CommunityGroup) {
        self.group = group
        self._isJoined = State(initialValue: group.isJoined)
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
                                        isButtonExpanded = delta > 0
                                    }
                                }
                                lastOffsetY = newValue
                            }
                    }
                    .frame(height: 0)

                    // Group Header
                    groupHeader
                        .padding(.top, 16)
                        .padding(.bottom, 20)

                    // Divider
                    Rectangle()
                        .fill(Color(hex: "#E5E7EB"))
                        .frame(height: 8)

                    // Posts Section
                    postsSection
                        .padding(.top, 16)

                    // Bottom Spacing for FAB
                    Spacer()
                        .frame(height: 100)
                }
            }
            .background(backgroundColor)

            // Floating Post Button
            floatingPostButton
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(group.name)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
            }
        }
        .sheet(isPresented: $showCreatePostSheet) {
            CreatePostSheet(
                availableGroups: [group],
                preselectedGroup: group
            ) { content, topic, _ in
                // Create new post and add to group feed
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

    // MARK: - Group Header

    private var groupHeader: some View {
        VStack(spacing: 16) {
            // Icon
            Circle()
                .fill(Color(hex: group.color).opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: group.icon)
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: group.color))
                )

            // Name and Description
            VStack(spacing: 8) {
                Text(group.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .multilineTextAlignment(.center)

                Text(group.description)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Member Count
            Text("\(group.formattedMemberCount) members")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#374151"))

            // Join/Joined Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isJoined.toggle()
                }
            } label: {
                Text(isJoined ? "Joined" : "Join Group")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isJoined ? Color(hex: "#6B7280") : .white)
                    .frame(width: 140)
                    .padding(.vertical, 12)
                    .background(isJoined ? Color(hex: "#F3F4F6") : Color.billixDarkTeal)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Posts Section

    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("Posts")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "#1A1A1A"))

                Spacer()

                Text("\(posts.count) posts")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            .padding(.horizontal, 16)

            // Posts List
            if posts.isEmpty {
                emptyPostsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(posts) { post in
                        CommunityPostCard(
                            post: post,
                            onLikeTapped: { toggleLike(for: post) },
                            onCommentTapped: { /* Future: Show comments */ },
                            onSaveTapped: { /* Future: Save post */ },
                            showTopComment: false
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Empty Posts View

    private var emptyPostsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#D1D5DB"))

            Text("No posts yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "#374151"))

            Text("Be the first to share something!")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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
}

// MARK: - Preview

#Preview("Group Detail View") {
    NavigationStack {
        GroupDetailView(group: CommunityGroup.mockGroups[0])
    }
}

//
//  EconomyGroupsTabView.swift
//  Billix
//
//  Created by Claude Code on 1/25/26.
//  Groups tab showing community groups to join (similar to subreddits)
//

import SwiftUI

struct EconomyGroupsTabView: View {
    @ObservedObject var viewModel: CommunityFeedViewModel
    @Binding var searchText: String
    @ObservedObject var router: GroupsNavigationRouter  // Router survives TabView recreation
    @State private var isButtonExpanded = true
    @State private var lastOffsetY: CGFloat = 0
    @State private var showCreatePostSheet = false

    private let backgroundColor = Color(hex: "#F5F5F7")

    var filteredGroups: [CommunityGroup] {
        viewModel.filteredGroups(searchText: searchText)
    }

    var joinedGroups: [CommunityGroup] {
        viewModel.joinedGroups
    }

    var body: some View {
        NavigationStack {
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

                        // Your Groups Section (if any joined)
                        if !joinedGroups.isEmpty && searchText.isEmpty {
                            yourGroupsSection
                                .padding(.top, 12)
                                .padding(.bottom, 20)
                        }

                        // Discover Section
                        discoverSection
                            .padding(.top, joinedGroups.isEmpty || !searchText.isEmpty ? 12 : 0)

                        // Bottom Spacing for FAB
                        Spacer()
                            .frame(height: 80)
                    }
                }
                .background(backgroundColor)

                // Floating Post Button
                floatingPostButton
            }
            .navigationBarHidden(true)
            // NOTE: fullScreenCover moved to parent EconomyTabView to prevent TabView recreation interference
            .sheet(isPresented: $showCreatePostSheet) {
                CreatePostSheet(
                    availableGroups: viewModel.groups,
                    preselectedGroup: nil
                ) { content, topic, group, isAnonymous in
                    // Create post via shared viewModel
                    Task {
                        _ = await viewModel.createPost(content: content, topic: topic, groupId: group?.id, isAnonymous: isAnonymous)
                    }
                }
            }
            .task {
                // Load groups if not already loaded (might be loaded by Feed tab)
                if viewModel.groups.isEmpty {
                    await viewModel.loadGroups()
                }
            }
        }
    }

    // MARK: - Your Groups Section

    private var yourGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Groups")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "#1A1A1A"))

                Spacer()

                Text("\(joinedGroups.count) joined")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(joinedGroups) { group in
                        Button {
                            router.navigateTo(group: group)
                        } label: {
                            joinedGroupCard(group)
                        }
                        .buttonStyle(.plain)
                        // Force re-render when counts change
                        .id("\(group.id)-\(group.postCount)-\(group.memberCount)")
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func joinedGroupCard(_ group: CommunityGroup) -> some View {
        VStack(spacing: 10) {
            // Icon
            Circle()
                .fill(Color(hex: group.color).opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: group.icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: group.color))
                )

            // Name
            Text(group.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#1A1A1A"))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // Member count
            Text("\(group.formattedMemberCount) members")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(width: 100)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Discover Section

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Discover Groups")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "#1A1A1A"))

                Spacer()

                Text("\(filteredGroups.count) groups")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            .padding(.horizontal, 16)

            if filteredGroups.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredGroups) { group in
                        GroupCard(
                            group: group,
                            onCardTapped: {
                                router.navigateTo(group: group)
                            },
                            onJoinTapped: {
                                toggleJoin(for: group)
                            }
                        )
                        // Force re-render when postCount or memberCount changes
                        .id("\(group.id)-\(group.postCount)-\(group.memberCount)")
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#D1D5DB"))

            Text("No groups found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "#374151"))

            Text("Try a different search")
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

    private func toggleJoin(for group: CommunityGroup) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            viewModel.toggleJoin(for: group)
        }
    }
}

// MARK: - Group Card Component

struct GroupCard: View {
    let group: CommunityGroup
    let onCardTapped: () -> Void
    let onJoinTapped: () -> Void

    var body: some View {
        let _ = print("[GroupCard] 📊 RENDER - \(group.name): \(group.postCount) posts, \(group.memberCount) members")
        Button(action: {
            onCardTapped()
        }) {
            HStack(spacing: 14) {
                // Icon
                Circle()
                    .fill(Color(hex: group.color).opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: group.icon)
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: group.color))
                    )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#1A1A1A"))

                    Text(group.description)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        Label("\(group.formattedMemberCount)", systemImage: "person.2.fill")
                        Label("\(group.postCount)", systemImage: "bubble.left.fill")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                }

                Spacer()

                // Join Button
                Button(action: onJoinTapped) {
                    Text(group.isJoined ? "Joined" : "Join")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(group.isJoined ? Color(hex: "#6B7280") : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            group.isJoined ? Color(hex: "#F3F4F6") : Color.billixDarkTeal
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct EconomyGroupsTabView_Economy_Groups_Tab_Previews: PreviewProvider {
    static var previews: some View {
        EconomyGroupsTabView(viewModel: CommunityFeedViewModel(), searchText: .constant(""), router: GroupsNavigationRouter())
    }
}

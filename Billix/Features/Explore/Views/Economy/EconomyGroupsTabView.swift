//
//  EconomyGroupsTabView.swift
//  Billix
//
//  Created by Claude Code on 1/25/26.
//  Groups tab showing community groups to join (similar to subreddits)
//

import SwiftUI

struct EconomyGroupsTabView: View {
    @Binding var searchText: String
    @State private var groups: [CommunityGroup] = CommunityGroup.mockGroups
    @State private var isButtonExpanded = true
    @State private var lastOffsetY: CGFloat = 0
    @State private var selectedGroup: CommunityGroup?
    @State private var showGroupDetail = false
    @State private var showCreatePostSheet = false

    private let backgroundColor = Color(hex: "#F5F5F7")

    var filteredGroups: [CommunityGroup] {
        if searchText.isEmpty {
            return groups
        }
        return groups.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var joinedGroups: [CommunityGroup] {
        groups.filter { $0.isJoined }
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
            .navigationDestination(item: $selectedGroup) { group in
                GroupDetailView(group: group)
            }
            .sheet(isPresented: $showCreatePostSheet) {
                CreatePostSheet(
                    availableGroups: groups,
                    preselectedGroup: nil
                ) { content, topic, group in
                    // Post created - would be added to feed
                    print("Posted to groups: \(content)")
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
                            selectedGroup = group
                        } label: {
                            joinedGroupCard(group)
                        }
                        .buttonStyle(.plain)
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
                                selectedGroup = group
                            },
                            onJoinTapped: {
                                toggleJoin(for: group)
                            }
                        )
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
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                groups[index].isJoined.toggle()
            }
        }
    }
}

// MARK: - Group Card Component

struct GroupCard: View {
    let group: CommunityGroup
    let onCardTapped: () -> Void
    let onJoinTapped: () -> Void

    var body: some View {
        Button(action: onCardTapped) {
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

#Preview("Economy Groups Tab") {
    EconomyGroupsTabView(searchText: .constant(""))
}

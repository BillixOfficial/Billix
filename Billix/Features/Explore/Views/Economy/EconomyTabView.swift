//
//  EconomyTabView.swift
//  Billix
//
//  Created by Claude Code on 1/24/26.
//  Main container view with Feed and News tabs for Economy section
//

import SwiftUI

enum EconomyTab: String, CaseIterable {
    case feed = "Feed"
    case groups = "Groups"
    case news = "News"
}

struct EconomyTabView: View {
    @StateObject private var newsViewModel = EconomyFeedViewModel()
    @StateObject private var communityViewModel = CommunityFeedViewModel()
    @State private var selectedTab: EconomyTab = .feed
    @State private var showProfileSheet = false
    @State private var isSearching = false
    @State private var searchText = ""
    @Namespace private var tabNamespace
    @FocusState private var isSearchFocused: Bool

    // Design colors
    private let accentBlue = Color(hex: "#3B6CFF")
    private let headlineBlack = Color(hex: "#1A1A1A")
    private let metadataGrey = Color(hex: "#8E8E93")
    private let buttonBackground = Color(hex: "#F3F4F6")
    private let tabUnderlineColor = Color.billixDarkTeal

    private var searchPlaceholder: String {
        switch selectedTab {
        case .feed: return "Search posts..."
        case .groups: return "Search groups..."
        case .news: return "Search news..."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Search Bar (shown when searching)
            if isSearching {
                searchBar
            }

            // Tab Bar
            tabBar

            // Tab Content
            TabView(selection: $selectedTab) {
                EconomyFeedTabView(viewModel: communityViewModel, searchText: $searchText)
                    .tag(EconomyTab.feed)

                EconomyGroupsTabView(viewModel: communityViewModel, searchText: $searchText)
                    .tag(EconomyTab.groups)

                EconomyNewsTabView(viewModel: newsViewModel, searchText: $searchText)
                    .tag(EconomyTab.news)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
        }
        .background(Color.white)
        .environmentObject(communityViewModel)
        .onChange(of: selectedTab) { _, _ in
            // Clear search when switching tabs
            searchText = ""
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            // Profile Section (Left) - Tappable to go to profile
            Button {
                showProfileSheet = true
            } label: {
                HStack(spacing: 12) {
                    // Profile Avatar
                    Circle()
                        .fill(accentBlue.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(newsViewModel.userName.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(accentBlue)
                        )

                    // Greeting Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(newsViewModel.greeting)
                            .font(.system(size: 14))
                            .foregroundColor(metadataGrey)

                        Text(newsViewModel.userName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Search Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSearching.toggle()
                    if isSearching {
                        isSearchFocused = true
                    } else {
                        searchText = ""
                        isSearchFocused = false
                    }
                }
            } label: {
                Circle()
                    .fill(isSearching ? Color.billixDarkTeal.opacity(0.15) : buttonBackground)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSearching ? Color.billixDarkTeal : .black.opacity(0.7))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, isSearching ? 8 : 16)
        .sheet(isPresented: $showProfileSheet) {
            ProfileView()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#9CA3AF"))

            TextField(searchPlaceholder, text: $searchText)
                .font(.system(size: 16))
                .focused($isSearchFocused)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: "#F5F5F7"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(EconomyTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 20)
    }

    private func tabButton(for tab: EconomyTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 8) {
                Text(tab.rawValue)
                    .font(.system(size: 16, weight: selectedTab == tab ? .bold : .regular))
                    .foregroundColor(selectedTab == tab ? headlineBlack : metadataGrey)
                    .frame(maxWidth: .infinity)

                // Underline Indicator
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 3)

                    if selectedTab == tab {
                        Rectangle()
                            .fill(tabUnderlineColor)
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Economy Tab View") {
    EconomyTabView()
}

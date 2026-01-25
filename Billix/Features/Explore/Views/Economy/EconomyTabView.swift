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
    case news = "News"
}

struct EconomyTabView: View {
    @StateObject private var viewModel = EconomyFeedViewModel()
    @State private var selectedTab: EconomyTab = .feed
    @State private var showProfileSheet = false
    @Namespace private var tabNamespace

    // Design colors
    private let accentBlue = Color(hex: "#3B6CFF")
    private let headlineBlack = Color(hex: "#1A1A1A")
    private let metadataGrey = Color(hex: "#8E8E93")
    private let buttonBackground = Color(hex: "#F3F4F6")
    private let tabUnderlineColor = Color.billixDarkTeal

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Tab Bar
            tabBar

            // Tab Content
            TabView(selection: $selectedTab) {
                EconomyFeedTabView()
                    .tag(EconomyTab.feed)

                EconomyNewsTabView(viewModel: viewModel)
                    .tag(EconomyTab.news)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
        }
        .background(Color.white)
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
                            Text(String(viewModel.userName.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(accentBlue)
                        )

                    // Greeting Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.greeting)
                            .font(.system(size: 14))
                            .foregroundColor(metadataGrey)

                        Text(viewModel.userName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Search Button
            Button {
                // Future: Implement search
            } label: {
                Circle()
                    .fill(buttonBackground)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .sheet(isPresented: $showProfileSheet) {
            ProfileView()
        }
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

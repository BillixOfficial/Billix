//
//  RewardsHubView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Main Rewards Hub - Tab-based interface (Marketplace + Earn Points)
//  Inspired by gamification best practices with bill management context
//

import SwiftUI

struct RewardsHubView: View {

    @StateObject private var viewModel = RewardsViewModel()
    @State private var selectedTab: RewardsTab = .earn
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.billixLightGreen
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Wallet Header (Sticky)
                    WalletHeaderView(
                        points: viewModel.displayedBalance,
                        cashEquivalent: viewModel.points.cashEquivalent,
                        onHistoryTapped: {
                            viewModel.showHistory = true
                        }
                    )
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

                    // Tab Selector
                    TabSelector(selectedTab: $selectedTab)
                        .padding(.top, 12)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)

                    // Tab Content
                    TabView(selection: $selectedTab) {
                        // Earn Points Tab
                        EarnPointsTabView(viewModel: viewModel)
                            .tag(RewardsTab.earn)

                        // Marketplace Tab
                        MarketplaceTabView(viewModel: viewModel)
                            .tag(RewardsTab.shop)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await viewModel.loadRewardsData()
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .sheet(isPresented: $viewModel.showHistory) {
            PointsHistoryView(transactions: viewModel.points.transactions)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $viewModel.selectedReward) { reward in
            RewardRedeemSheet(
                reward: reward,
                userPoints: viewModel.points.balance,
                onRedeem: {
                    viewModel.redeemReward(reward)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $viewModel.showGeoGame) {
            if let game = viewModel.activeGame {
                GeoGameContainerView(
                    initialGame: game,
                    onComplete: { result in
                        viewModel.handleGameResult(result)
                    },
                    onPlayAgain: {
                        viewModel.playAgain()
                    },
                    onDismiss: {
                        viewModel.closeGeoGame()
                    }
                )
                .id(game.id) // Force view recreation when game changes
            }
        }
    }
}

// MARK: - Rewards Tab Enum

enum RewardsTab: String, CaseIterable {
    case earn = "Earn Points"
    case shop = "Rewards Shop"

    var icon: String {
        switch self {
        case .earn: return "star.fill"
        case .shop: return "gift.fill"
        }
    }
}

// MARK: - Tab Selector

struct TabSelector: View {
    @Binding var selectedTab: RewardsTab

    var body: some View {
        HStack(spacing: 12) {
            ForEach(RewardsTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .semibold))

                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .billixMediumGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                selectedTab == tab ?
                                LinearGradient(
                                    colors: [.billixArcadeGold, .billixPrizeOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.billixMediumGreen.opacity(0.1), Color.billixMediumGreen.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                selectedTab == tab ? Color.clear : Color.billixBorderGreen,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Earn Points Tab View

struct EarnPointsTabView: View {
    @ObservedObject var viewModel: RewardsViewModel
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Daily Game Hero Card
                DailyGameHeroCard(
                    game: viewModel.dailyGame,
                    gamesPlayedToday: viewModel.gamesPlayedToday,
                    onPlay: {
                        viewModel.playDailyGame()
                    }
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)

                // Daily Tasks Section
                DailyTasksSection()
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appeared)

                // Weekly Tasks Section
                WeeklyTasksSection()
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)

                // Leaderboard Teaser
                LeaderboardTeaser(
                    topSavers: viewModel.topSavers,
                    currentUser: viewModel.currentUserRank
                )
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: appeared)

                Spacer(minLength: 100)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Marketplace Tab View

struct MarketplaceTabView: View {
    @ObservedObject var viewModel: RewardsViewModel
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Featured Reward Hero Card
                if let featured = viewModel.rewards.first {
                    FeaturedRewardCard(
                        reward: featured,
                        userPoints: viewModel.points.balance,
                        onTap: {
                            viewModel.selectedReward = featured
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
                }

                // Rewards Grid
                RewardGridSection(
                    rewards: Array(viewModel.rewards.dropFirst()),
                    userPoints: viewModel.points.balance,
                    onRewardTapped: { reward in
                        viewModel.selectedReward = reward
                    }
                )
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appeared)

                Spacer(minLength: 100)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Daily Game Hero Card

struct DailyGameHeroCard: View {
    let game: DailyGame?
    let gamesPlayedToday: Int
    let onPlay: () -> Void

    @State private var isAnimating = false
    @State private var shimmerOffset: CGFloat = -200
    @State private var badgePulse = false

    var body: some View {
        VStack(spacing: 0) {
            // "DAILY" badge with animation
            HStack {
                Spacer()
                Text("DAILY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.billixStreakOrange, Color.billixFlashRed],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .billixStreakOrange.opacity(0.5), radius: badgePulse ? 8 : 4)
                    )
                    .scaleEffect(badgePulse ? 1.05 : 1.0)
                    .offset(x: -12, y: 12)
            }
            .zIndex(1)

            ZStack {
                // Clean solid purple background
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#7C3AED"))  // Clean purple

                // Decorative pattern overlay
                GeometryReader { geometry in
                    // Top-right accent circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.billixArcadeGold.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .offset(x: geometry.size.width - 80, y: -60)

                    // Bottom-left accent circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.billixPrizeOrange.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 150, height: 150)
                        .offset(x: -40, y: geometry.size.height - 50)
                }

                // Subtle shimmer
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.1), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)

                HStack(spacing: 20) {
                    // Enhanced game visual
                    ZStack {
                        // Glow rings
                        ForEach(0..<2) { index in
                            Circle()
                                .stroke(Color.billixArcadeGold.opacity(0.3), lineWidth: 2)
                                .frame(width: 90 + CGFloat(index * 12), height: 90 + CGFloat(index * 12))
                                .opacity(isAnimating ? 0.0 : 0.5)
                                .scaleEffect(isAnimating ? 1.4 : 1.0)
                                .animation(
                                    .easeOut(duration: 1.8)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.4),
                                    value: isAnimating
                                )
                        }

                        // Main circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.billixArcadeGold, Color.billixPrizeOrange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90)
                            .shadow(color: .billixArcadeGold.opacity(0.5), radius: 15, x: 0, y: 8)
                            .overlay(
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [.white.opacity(0.4), .clear],
                                            center: .topLeading,
                                            startRadius: 0,
                                            endRadius: 45
                                        )
                                    )
                            )
                            .offset(y: isAnimating ? -4 : 4)

                        // Icon
                        Image(systemName: "questionmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 3)
                            .rotationEffect(.degrees(isAnimating ? 5 : -5))
                    }
                    .frame(width: 100)

                    // Content
                    VStack(alignment: .leading, spacing: 10) {
                        if let game = game {
                            VStack(alignment: .leading, spacing: 9) {
                                Text("Price Guessr")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.billixArcadeGold)

                                    Text("Win up to 100 pts")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.95))
                                }

                                HStack(spacing: 6) {
                                    Image(systemName: "target")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))

                                    Text("Guess: \(game.subject) price")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                }

                                // Show games played if any
                                if gamesPlayedToday > 0 {
                                    HStack(spacing: 6) {
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.7))

                                        Text("\(gamesPlayedToday) played today")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                }
                            }
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .frame(height: 150)

            // Enhanced CTA Button with shine effect
            Button(action: onPlay) {
                ZStack {
                    Text("Play Now")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            ZStack {
                                LinearGradient(
                                    colors: [Color.billixArcadeGold, Color.billixPrizeOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )

                                // Shine overlay
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.2),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .offset(x: shimmerOffset)
                            }
                        )

                    HStack {
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.trailing, 20)
                    }
                }
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.97))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .billixArcadeGold.opacity(0.3), radius: 12, y: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .offset(y: -10)
        }
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .onAppear {
            // Start animations
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }

            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                badgePulse = true
            }

            // Shimmer animation
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }
}

// MARK: - Daily Tasks Section

struct DailyTasksSection: View {
    @State private var tasks: [RewardTask] = [
        RewardTask(
            id: UUID(),
            title: "Check in today",
            points: 10,
            icon: "calendar.badge.checkmark",
            isCompleted: true,
            type: .daily
        ),
        RewardTask(
            id: UUID(),
            title: "Upload a bill",
            points: 50,
            icon: "doc.badge.plus",
            isCompleted: false,
            type: .daily
        ),
        RewardTask(
            id: UUID(),
            title: "Compare 3 providers",
            points: 30,
            icon: "chart.bar.fill",
            isCompleted: false,
            type: .daily
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Daily Tasks")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Text("Resets in 14h")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }

            // Tasks
            VStack(spacing: 12) {
                ForEach(tasks) { task in
                    TaskCard(task: task) {
                        // Claim action
                        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                            tasks[index].isCompleted = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Weekly Tasks Section

struct WeeklyTasksSection: View {
    @State private var tasks: [RewardTask] = [
        RewardTask(
            id: UUID(),
            title: "Refer a friend",
            points: 200,
            icon: "person.2.fill",
            isCompleted: false,
            type: .weekly
        ),
        RewardTask(
            id: UUID(),
            title: "Upload 5 bills",
            points: 150,
            icon: "doc.on.doc.fill",
            isCompleted: false,
            type: .weekly,
            progress: 2,
            progressTotal: 5
        ),
        RewardTask(
            id: UUID(),
            title: "Play Price Guessr 7 times",
            points: 300,
            icon: "gamecontroller.fill",
            isCompleted: false,
            type: .weekly,
            progress: 3,
            progressTotal: 7
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Weekly Tasks")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Text("Resets in 4 days")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }

            // Tasks
            VStack(spacing: 12) {
                ForEach(tasks) { task in
                    TaskCard(task: task) {
                        // Claim action
                        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                            tasks[index].isCompleted = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Task Card

struct TaskCard: View {
    let task: RewardTask
    let onClaim: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.billixMoneyGreen.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: task.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.billixMoneyGreen)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.billixArcadeGold)

                    Text("+\(task.points) pts")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }

                // Progress bar (if applicable)
                if let progress = task.progress, let total = task.progressTotal {
                    HStack(spacing: 6) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.billixBorderGreen)
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.billixMoneyGreen)
                                    .frame(
                                        width: geometry.size.width * CGFloat(progress) / CGFloat(total),
                                        height: 4
                                    )
                            }
                        }
                        .frame(height: 4)

                        Text("\(progress)/\(total)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                            .frame(width: 30)
                    }
                }
            }

            Spacer()

            // Claim Button
            if task.isCompleted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.billixMoneyGreen)

                    Text("Done")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.billixMoneyGreen)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.billixMoneyGreen.opacity(0.15))
                )
            } else {
                Button(action: onClaim) {
                    Text("Claim")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.billixArcadeGold, .billixPrizeOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.95))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Leaderboard Teaser

struct LeaderboardTeaser: View {
    let topSavers: [LeaderboardEntry]
    let currentUser: LeaderboardEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Leaderboard")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Button {
                    // Show full leaderboard
                } label: {
                    Text("See all")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixChartBlue)
                }
            }

            VStack(spacing: 8) {
                ForEach(Array(topSavers.prefix(3))) { entry in
                    LeaderboardMiniRow(entry: entry)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

struct LeaderboardMiniRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            Text("#\(entry.rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(entry.rankBadgeColor)
                .frame(width: 36)

            // Avatar
            Circle()
                .fill(entry.rankBadgeColor.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(entry.avatarInitials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(entry.rankBadgeColor)
                )

            // Name
            Text(entry.displayName)
                .font(.system(size: 14, weight: entry.isCurrentUser ? .bold : .medium))
                .foregroundColor(entry.isCurrentUser ? .billixDarkGreen : .billixMediumGreen)

            Spacer()

            // Points
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.billixArcadeGold)

                Text("\(entry.pointsThisWeek)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Featured Reward Card

struct FeaturedRewardCard: View {
    let reward: Reward
    let userPoints: Int
    let onTap: () -> Void

    private var canAfford: Bool {
        userPoints >= reward.pointsCost
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // "FEATURED" badge
                HStack {
                    Spacer()
                    Text("FEATURED")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.billixFlashRed)
                        )
                        .offset(x: -12, y: 12)
                }

                HStack(spacing: 20) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: reward.accentColor).opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: reward.iconName)
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: reward.accentColor))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(reward.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.billixDarkGreen)
                            .lineLimit(2)

                        if let value = reward.formattedValue {
                            Text(value)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.billixMoneyGreen)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.billixArcadeGold)

                            Text("\(reward.pointsCost) pts")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(canAfford ? .billixDarkGreen : .billixMediumGreen)
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: reward.accentColor).opacity(0.1),
                            Color.white
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Reward Grid Section

struct RewardGridSection: View {
    let rewards: [Reward]
    let userPoints: Int
    let onRewardTapped: (Reward) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Rewards")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.billixDarkGreen)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(rewards) { reward in
                    RewardGridCard(
                        reward: reward,
                        userPoints: userPoints,
                        onTap: { onRewardTapped(reward) }
                    )
                }
            }
        }
    }
}

struct RewardGridCard: View {
    let reward: Reward
    let userPoints: Int
    let onTap: () -> Void

    private var canAfford: Bool {
        userPoints >= reward.pointsCost
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: reward.accentColor).opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: reward.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: reward.accentColor))
                }

                // Title
                Text(reward.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 36)

                // Value
                if let value = reward.formattedValue {
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.billixMoneyGreen)
                }

                Spacer()

                // Cost
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.billixArcadeGold)

                    Text("\(reward.pointsCost)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(canAfford ? .billixDarkGreen : .billixMediumGreen)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.billixArcadeGold.opacity(0.15))
                )
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        canAfford ? Color.clear : Color.billixBorderGreen,
                        lineWidth: 1
                    )
            )
            .opacity(canAfford ? 1 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Reward Task Model

struct RewardTask: Identifiable {
    let id: UUID
    let title: String
    let points: Int
    let icon: String
    var isCompleted: Bool
    let type: TaskType
    var progress: Int?
    var progressTotal: Int?

    enum TaskType {
        case daily
        case weekly
    }
}

// MARK: - Reward Redeem Sheet

struct RewardRedeemSheet: View {
    let reward: Reward
    let userPoints: Int
    let onRedeem: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isRedeeming = false

    private var canAfford: Bool {
        userPoints >= reward.pointsCost
    }

    private var pointsNeeded: Int {
        max(reward.pointsCost - userPoints, 0)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Reward Icon
            ZStack {
                Circle()
                    .fill(Color(hex: reward.accentColor).opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: reward.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: reward.accentColor))
            }

            // Reward Info
            VStack(spacing: 8) {
                Text(reward.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Text(reward.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
                    .multilineTextAlignment(.center)

                if let value = reward.formattedValue {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.billixMoneyGreen)
                        .padding(.top, 4)
                }
            }

            // Cost
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.billixArcadeGold)

                Text("\(reward.pointsCost) pts")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.billixArcadeGold.opacity(0.15))
            )

            Spacer()

            // Action Button
            if canAfford {
                Button {
                    isRedeeming = true
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onRedeem()
                        dismiss()
                    }
                } label: {
                    HStack {
                        if isRedeeming {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Redeem Now")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.billixMoneyGreen, .billixMoneyGreen.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.97))
                .disabled(isRedeeming)
            } else {
                VStack(spacing: 8) {
                    Text("You need \(pointsNeeded) more pts")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Button {
                        dismiss()
                    } label: {
                        Text("Keep Earning")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.billixMoneyGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.billixMoneyGreen, lineWidth: 2)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.97))
                }
            }
        }
        .padding(24)
        .background(Color.white)
    }
}

// MARK: - Preview

#Preview {
    RewardsHubView()
}

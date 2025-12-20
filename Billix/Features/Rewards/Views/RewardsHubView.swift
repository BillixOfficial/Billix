//
//  RewardsHubView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Main Rewards Hub - Tab-based interface (Marketplace + Earn Points)
//  Inspired by gamification best practices with bill management context
//

import SwiftUI

// MARK: - Theme (Billix Color Scheme)

private enum Theme {
    // Core Billix Colors
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")          // Billix Money Green
    static let accentLight = Color(hex: "#5B8A6B").opacity(0.12)

    // Semantic colors
    static let success = Color(hex: "#4CAF7A")
    static let warning = Color(hex: "#E8A54B")
    static let danger = Color(hex: "#E07A6B")
    static let info = Color(hex: "#5BA4D4")            // Chart Blue
    static let purple = Color(hex: "#5D4DB1")          // Billix Purple Accent

    // Rewards/Points colors (using Billix palette)
    static let gold = Color(hex: "#D4A04E")            // Billix Gold (coins)
    static let highlight = Color(hex: "#5D4DB1")       // Purple for highlights
    static let streak = Color(hex: "#4CAF7A")          // Green for streaks

    // Spacing
    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let cardSpacing: CGFloat = 16
    static let cornerRadius: CGFloat = 16

    // Shadow
    static let shadowColor = Color.black.opacity(0.04)
    static let shadowRadius: CGFloat = 10
}

struct RewardsHubView: View {

    @StateObject private var viewModel = RewardsViewModel()
    @State private var selectedTab: RewardsTab = .earn
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.background
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
                    .foregroundColor(selectedTab == tab ? .white : Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                selectedTab == tab ?
                                LinearGradient(
                                    colors: [Theme.accent, Theme.accent.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Theme.secondaryText.opacity(0.08), Theme.secondaryText.opacity(0.08)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                selectedTab == tab ? Color.clear : Theme.secondaryText.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, Theme.horizontalPadding)
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

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Clean gradient background
                RoundedRectangle(cornerRadius: Theme.cornerRadius + 4)
                    .fill(
                        LinearGradient(
                            colors: [Theme.purple, Theme.purple.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Subtle pattern overlay
                RoundedRectangle(cornerRadius: Theme.cornerRadius + 4)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.08), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                HStack(spacing: 16) {
                    // Game icon
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Circle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 60, height: 60)

                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                            .offset(y: isAnimating ? -2 : 2)
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Price Guessr")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            // Daily badge
                            Text("DAILY")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.purple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(.white)
                                )
                        }

                        if let game = game {
                            Text("Guess the \(game.subject) price")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }

                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.gold)

                                Text("Up to 100 pts")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            if gamesPlayedToday > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))

                                    Text("\(gamesPlayedToday) played")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                }
                .padding(Theme.horizontalPadding)
            }
            .frame(height: 130)

            // Play button
            Button(action: onPlay) {
                HStack {
                    Text("Play Now")
                        .font(.system(size: 16, weight: .bold))

                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.accent)
                )
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.97))
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.top, -8)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius + 4)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
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
                    .foregroundColor(Theme.primaryText)

                Spacer()

                Text("Resets in 14h")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
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
                    .foregroundColor(Theme.primaryText)

                Spacer()

                Text("Resets in 4 days")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
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
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: task.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.accent)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.gold)

                    Text("+\(task.points) pts")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                }

                // Progress bar (if applicable)
                if let progress = task.progress, let total = task.progressTotal {
                    HStack(spacing: 6) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.secondaryText.opacity(0.2))
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.accent)
                                    .frame(
                                        width: geometry.size.width * CGFloat(progress) / CGFloat(total),
                                        height: 4
                                    )
                            }
                        }
                        .frame(height: 4)

                        Text("\(progress)/\(total)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
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
                        .foregroundColor(Theme.success)

                    Text("Done")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.success)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Theme.success.opacity(0.15))
                )
            } else {
                Button(action: onClaim) {
                    Text("Claim")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Theme.accent)
                        )
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.95))
            }
        }
        .padding(Theme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
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
                    .foregroundColor(Theme.primaryText)

                Spacer()

                Button {
                    // Show full leaderboard
                } label: {
                    Text("See all")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.info)
                }
            }

            VStack(spacing: 8) {
                ForEach(Array(topSavers.prefix(3))) { entry in
                    LeaderboardMiniRow(entry: entry)
                }
            }
        }
        .padding(Theme.horizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius + 4)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
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
                .foregroundColor(entry.isCurrentUser ? Theme.primaryText : Theme.secondaryText)

            Spacer()

            // Points
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.gold)

                Text("\(entry.pointsThisWeek)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
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
                                .fill(Theme.purple)
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
                            .foregroundColor(Theme.primaryText)
                            .lineLimit(2)

                        if let value = reward.formattedValue {
                            Text(value)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.success)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.gold)

                            Text("\(reward.pointsCost) pts")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(canAfford ? Theme.primaryText : Theme.secondaryText)
                        }
                    }

                    Spacer()
                }
                .padding(Theme.horizontalPadding)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius + 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: reward.accentColor).opacity(0.1),
                            Theme.cardBackground
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius + 4, x: 0, y: 4)
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
                .foregroundColor(Theme.primaryText)

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
                    .foregroundColor(Theme.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 36)

                // Value
                if let value = reward.formattedValue {
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.success)
                }

                Spacer()

                // Cost
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.gold)

                    Text("\(reward.pointsCost)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(canAfford ? Theme.primaryText : Theme.secondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Theme.gold.opacity(0.15))
                )
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius + 4)
                    .fill(Theme.cardBackground)
                    .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius + 4)
                    .stroke(
                        canAfford ? Color.clear : Theme.secondaryText.opacity(0.2),
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
                    .foregroundColor(Theme.primaryText)

                Text(reward.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)

                if let value = reward.formattedValue {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.success)
                        .padding(.top, 4)
                }
            }

            // Cost
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.gold)

                Text("\(reward.pointsCost) pts")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Theme.gold.opacity(0.15))
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
                            colors: [Theme.accent, Theme.accent.opacity(0.8)],
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
                        .foregroundColor(Theme.secondaryText)

                    Button {
                        dismiss()
                    } label: {
                        Text("Keep Earning")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.accent, lineWidth: 2)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.97))
                }
            }
        }
        .padding(24)
        .background(Theme.cardBackground)
    }
}

// MARK: - Preview

#Preview {
    RewardsHubView()
}

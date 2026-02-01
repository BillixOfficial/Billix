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

    @StateObject private var viewModel = RewardsViewModel(authService: AuthService.shared)
    @ObservedObject private var tasksViewModel = TasksViewModel.shared
    @State private var selectedTab: RewardsTab = .earn
    @State private var appeared = false
    @Environment(\.scenePhase) private var scenePhase

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
                        currentTier: viewModel.currentTier,
                        tierProgress: viewModel.tierProgress,
                        streakCount: tasksViewModel.currentStreak,
                        weeklyCheckIns: tasksViewModel.weeklyCheckIns
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
                        EarnPointsTabView(viewModel: viewModel, tasksViewModel: tasksViewModel)
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && appeared {
                Task {
                    await tasksViewModel.loadTasks()
                    await viewModel.loadRewardsData()
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadRewardsData()
                await tasksViewModel.loadTasks()
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToGame"))) { _ in
            // Open season selection screen when game task is tapped
            viewModel.showSeasonSelection = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissToRewards"))) { _ in
            // Dismiss season selection when returning from game
            viewModel.showSeasonSelection = false
        }
        .sheet(isPresented: $viewModel.showAmountSheet) {
            if let brandGroup = viewModel.selectedBrandGroup {
                let amounts = viewModel.getRewardsForBrand(brandGroup)
                let brandName = amounts.first?.brand ?? "Gift Card"

                GiftCardAmountSheet(
                    brandGroup: brandGroup,
                    brandName: brandName,
                    availableAmounts: amounts,
                    userPoints: viewModel.points.balance,
                    onSelectAmount: { reward in
                        viewModel.selectedReward = reward
                    }
                )
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color(hex: "#F5F7F6"))
        .presentationDragIndicator(.visible)
        .sheet(item: $viewModel.selectedReward) { reward in
            if reward.category == .giftCard {
                // Gift cards require email for delivery
                GiftCardEmailSheet(
                    reward: reward,
                    userPoints: viewModel.points.balance,
                    onRedeem: { email in
                        Task {
                            await viewModel.redeemGiftCard(reward, email: email)
                        }
                    }
                )
            } else {
                // Other rewards use direct redemption
                RewardRedeemSheet(
                    reward: reward,
                    userPoints: viewModel.points.balance,
                    onRedeem: {
                        viewModel.redeemReward(reward)
                    }
                )
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color(hex: "#F5F7F6"))
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $viewModel.showDonationRequestSheet) {
            CustomDonationRequestSheet(
                userPoints: viewModel.points.balance,
                userName: "John Doe", // TODO: Get from user profile
                userEmail: "john@example.com", // TODO: Get from user profile
                onSubmit: { org, location, amount, inName, donorName, donorEmail in
                    Task {
                        await viewModel.submitDonationRequest(
                            organizationName: org,
                            websiteOrLocation: location,
                            amount: amount
                        )
                    }
                }
            )
            .presentationDetents([.large])
            .presentationBackground(Color(hex: "#F5F7F6"))
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showFullLeaderboard) {
            FullLeaderboardSheet(
                entries: viewModel.topSavers,
                currentUser: viewModel.currentUserRank
            )
            .presentationDetents([.large])
            .presentationBackground(Color(hex: "#F5F7F6"))
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $viewModel.showGeoGame) {
            if let game = viewModel.activeGame {
                GeoGameFlowView(
                    game: game,
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
        .fullScreenCover(isPresented: $viewModel.showSeasonSelection) {
            SeasonSelectionView()
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
    @ObservedObject var tasksViewModel: TasksViewModel
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
                DailyTasksSection(tasksViewModel: tasksViewModel, rewardsViewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appeared)

                // Weekly Tasks Section
                WeeklyTasksSection(tasksViewModel: tasksViewModel)
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)

                // Leaderboard Teaser
                LeaderboardTeaser(
                    topSavers: viewModel.topSavers,
                    currentUser: viewModel.currentUserRank,
                    onSeeAll: { viewModel.showFullLeaderboard = true }
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

    var body: some View {
        RewardMarketplace(
            rewards: viewModel.rewards,
            userPoints: viewModel.points.balance,
            canAccessShop: viewModel.canAccessRewardShop,
            currentTier: viewModel.currentTier,
            onRewardTapped: { reward in
                // If gift card with brand group, show amount selection
                if reward.category == .giftCard, let brandGroup = reward.brandGroup {
                    viewModel.selectBrandForAmountSheet(brandGroup: brandGroup)
                } else {
                    // Direct redemption for other rewards
                    viewModel.selectedReward = reward
                }
            },
            onStartDonationRequest: {
                viewModel.startDonationRequest()
            },
            onViewAllGiftCards: {
                viewModel.showAllRewards = true
            },
            onViewAllGameBoosts: {
                viewModel.showAllRewards = true
            },
            onViewAllVirtualGoods: {
                viewModel.showAllRewards = true
            }
        )
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
    @State private var isPressed = false
    @State private var tickerOffset: CGFloat = 0
    @State private var viewIsVisible = false

    // Mock streak data (TODO: Connect to actual streak tracking)
    private let streakDays = 4
    private let maxPlaysPerDay = 3

    var playsRemaining: Int {
        max(0, maxPlaysPerDay - gamesPlayedToday)
    }

    var body: some View {
        VStack(spacing: 0) {
            // "DAILY" badge with enhanced animation
            HStack {
                Spacer()
                Text("DAILY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.billixStreakOrange, Color.billixFlashRed],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .billixStreakOrange.opacity(0.5), radius: badgePulse ? 8 : 4)

                            // Shimmer effect
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.4), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shimmerOffset * 0.3)
                        }
                    )
                    .scaleEffect(badgePulse ? 1.05 : 1.0)
                    .offset(x: -12, y: 12)
            }
            .zIndex(1)
            .accessibilityLabel("Daily challenge available")

            ZStack {
                // Solid background - Deep ocean blue for global travel theme
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#0C4A6E"))

                // Floating particles (subtle magical ambiance)
                FloatingParticlesBackground(
                    particleCount: 7,
                    colors: [.white, Color.billixArcadeGold.opacity(0.8)]
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))

                // Decorative pattern overlay (slightly enhanced)
                GeometryReader { geometry in
                    // Top-right accent circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.billixArcadeGold.opacity(0.35), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 110
                            )
                        )
                        .frame(width: 220, height: 220)
                        .offset(x: geometry.size.width - 90, y: -70)

                    // Bottom-left accent circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.billixPrizeOrange.opacity(0.25), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 85
                            )
                        )
                        .frame(width: 170, height: 170)
                        .offset(x: -50, y: geometry.size.height - 60)
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

                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        // Animated globe icon - shifted left
                        PriceGuessrIcon()
                            .frame(width: 168, height: 168)
                            .offset(x: -30)

                        // Simple content - title with price tag and reward
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .bottom, spacing: 3) {
                                Text("Price Guessr")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)

                                // Price tag next to title
                                PriceTag()
                                    .scaleEffect(0.95)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.billixArcadeGold)

                                Text("Test your price knowledge")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.95))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(x: -22)

                        Spacer(minLength: 0)
                    }

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 20)

                // Centered Play Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onPlay()
                        }) {
                            Text("PLAY NOW")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.billixArcadeGold, Color(hex: "#FFA500"), Color(hex: "#FF6B35")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )

                                        // Pulse glow effect
                                        Capsule()
                                            .stroke(Color.billixArcadeGold.opacity(0.5), lineWidth: 2)
                                            .blur(radius: 4)
                                            .scaleEffect(badgePulse ? 1.05 : 1.0)
                                    }
                                )
                                .shadow(color: .billixArcadeGold.opacity(0.4), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(FABButtonStyle())
                        .accessibilityLabel("Play today's Price Guessr challenge")
                        .accessibilityHint("Double tap to start guessing prices")

                        Spacer()
                    }
                }
                .padding(16)
            }
            .frame(height: 200)
        }
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily Price Guessr game. Guess prices around the world. Test your price knowledge.")
        .onAppear {
            viewIsVisible = true
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
        .onDisappear {
            viewIsVisible = false
            isAnimating = false
            badgePulse = false
            shimmerOffset = -200
        }
    }

    // Helper function to get flag emoji for location
    private func getFlagEmoji(for location: String) -> String {
        // Simple mapping for common locations
        let flagMap: [String: String] = [
            "Manhattan, NY": "🇺🇸",
            "Tokyo": "🇯🇵",
            "London": "🇬🇧",
            "Paris": "🇫🇷",
            "Sydney": "🇦🇺",
            "Toronto": "🇨🇦",
            "Berlin": "🇩🇪",
            "Mumbai": "🇮🇳"
        ]

        // Try to find exact match or partial match
        for (key, flag) in flagMap {
            if location.contains(key) || key.contains(location) {
                return flag
            }
        }

        return "🌎" // Default globe emoji
    }
}

// MARK: - FAB Button Style

struct FABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Daily Tasks Section

struct DailyTasksSection: View {
    @ObservedObject var tasksViewModel: TasksViewModel
    @ObservedObject var rewardsViewModel: RewardsViewModel
    @State private var showQuickTasks = false
    @State private var currentTime = Date()

    // Timer to update countdown
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    // Calculate time until midnight
    private var timeUntilReset: String {
        let calendar = Calendar.current
        let now = currentTime

        // Get EST timezone
        guard let estTimeZone = TimeZone(identifier: "America/New_York") else {
            return "24h"
        }

        // Create EST calendar
        var estCalendar = Calendar.current
        estCalendar.timeZone = estTimeZone

        // Get current time in EST
        let nowInEST = now

        // Get tomorrow at midnight EST
        guard let tomorrow = estCalendar.date(byAdding: .day, value: 1, to: nowInEST),
              let midnightEST = estCalendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
            return "24h"
        }

        let components = calendar.dateComponents([.hour, .minute], from: now, to: midnightEST)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Daily Tasks")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Text("Resets in \(timeUntilReset)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }

            // Tasks
            if tasksViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    // Show only daily tasks (check-in and bill upload)
                    ForEach(tasksViewModel.dailyTasks.filter { $0.taskType == .checkIn || $0.taskType == .billUpload }) { task in
                        DailyTaskCardView(task: task, viewModel: tasksViewModel, rewardsViewModel: rewardsViewModel)
                    }

                    // Quick Earnings portal card
                    TaskCard(task: RewardTask(
                        id: UUID(),
                        title: "Quick Earnings",
                        points: 0,
                        icon: "bolt.fill",
                        isCompleted: false,
                        type: .daily,
                        isPortal: true,
                        buttonText: nil,
                        canClaim: false
                    )) {
                        showQuickTasks = true
                    }
                }
            }
        }
        .task {
            await tasksViewModel.loadTasks()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .sheet(isPresented: $showQuickTasks) {
            QuickTasksScreen()
        }
    }
}

// MARK: - Daily Task Card View

struct DailyTaskCardView: View {
    let task: UserTask
    @ObservedObject var viewModel: TasksViewModel
    @ObservedObject var rewardsViewModel: RewardsViewModel

    // Use different icons based on task type and completion status
    private var taskIcon: String {
        switch task.taskType {
        case .checkIn:
            return task.isClaimed ? "calendar.badge.checkmark" : "calendar"
        case .billUpload:
            // Keep bill icon, don't change to checkmark
            return "doc.badge.plus"
        default:
            return task.iconName
        }
    }

    // Determine button text based on task state
    private var buttonText: String {
        if task.canClaim {
            return "Claim"
        } else {
            // Use task's CTA text from database (e.g., "Check In", "Upload Bill")
            return task.ctaText
        }
    }

    var body: some View {
        TaskCard(task: RewardTask(
            id: UUID(),
            title: task.title,
            points: task.points,
            icon: taskIcon,
            isCompleted: task.isClaimed,
            type: .daily,
            buttonText: buttonText,
            canClaim: task.canClaim
        )) {
            // Handle task action
            Task {
                if task.taskType == .checkIn {
                    await viewModel.performCheckIn()
                    await rewardsViewModel.loadRewardsData() // Refresh balance
                } else if task.canClaim {
                    await viewModel.claimTask(task)
                    await rewardsViewModel.loadRewardsData() // Refresh balance
                } else {
                    // Navigate to upload screen
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToUpload"), object: nil)
                }
            }
        }
    }
}

// MARK: - Weekly Tasks Section

struct WeeklyTasksSection: View {
    @ObservedObject var tasksViewModel: TasksViewModel
    @State private var currentTime = Date()

    // Timer to update countdown
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    // Calculate time until Sunday midnight EST
    private var timeUntilReset: String {
        let calendar = Calendar.current
        let now = currentTime

        // Get EST timezone
        guard let estTimeZone = TimeZone(identifier: "America/New_York") else {
            return "7 days"
        }

        // Create EST calendar
        var estCalendar = Calendar.current
        estCalendar.timeZone = estTimeZone

        // Get next Sunday at midnight EST
        var components = estCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 1 // Sunday
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let nextSunday = estCalendar.date(from: components) else {
            return "7 days"
        }

        // If nextSunday is in the past, add a week
        let sunday = nextSunday < now ? estCalendar.date(byAdding: .weekOfYear, value: 1, to: nextSunday)! : nextSunday

        let componentsUntil = calendar.dateComponents([.day, .hour], from: now, to: sunday)
        let days = componentsUntil.day ?? 0
        let hours = componentsUntil.hour ?? 0

        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "< 1h"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Weekly Tasks")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Text("Resets in \(timeUntilReset)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }

            // Tasks
            if tasksViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(tasksViewModel.weeklyTasks) { task in
                        WeeklyTaskCardView(task: task, viewModel: tasksViewModel)
                    }
                }
            }
        }
        .task {
            await tasksViewModel.loadTasks()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - Weekly Task Card View

struct WeeklyTaskCardView: View {
    let task: UserTask
    @ObservedObject var viewModel: TasksViewModel

    // Determine button text based on task state
    private var buttonText: String {
        if task.canClaim {
            return "Claim"
        } else {
            // Use task's CTA text from database (e.g., "Upload Bills", "Play Games")
            return task.ctaText
        }
    }

    var body: some View {
        TaskCard(task: RewardTask(
            id: UUID(),
            title: task.title,
            points: task.points,
            icon: task.iconName,
            isCompleted: task.isClaimed,
            type: .weekly,
            progress: task.currentCount,
            progressTotal: task.requiresCount > 1 ? task.requiresCount : nil,
            buttonText: buttonText,
            canClaim: task.canClaim
        )) {
            // Handle task action
            Task {
                if task.canClaim {
                    await viewModel.claimTask(task)
                } else {
                    // Navigate based on task type
                    switch task.taskType {
                    case .billUpload:
                        NotificationCenter.default.post(name: NSNotification.Name("NavigateToUpload"), object: nil)
                    case .game:
                        NotificationCenter.default.post(name: NSNotification.Name("NavigateToGame"), object: nil)
                    case .referral:
                        NotificationCenter.default.post(name: NSNotification.Name("ShowReferralSheet"), object: nil)
                    default:
                        break
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
            // Icon (gold for portal tasks, green for regular tasks)
            ZStack {
                Circle()
                    .fill((task.isPortal ? Color.billixArcadeGold : Color.billixMoneyGreen).opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: task.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(task.isPortal ? .billixArcadeGold : .billixMoneyGreen)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(2)

                if task.isPortal {
                    // Portal tasks show subtitle instead of points
                    Text("Complete mini-tasks for bonus points")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                } else {
                    // Regular tasks show points
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.billixArcadeGold)

                        Text("+\(task.points) pts")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                    }
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
                                        width: geometry.size.width * min(1.0, CGFloat(progress) / CGFloat(total)),
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

            // Action Button
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
            } else if task.isPortal {
                // Portal tasks show "View All" outline button
                Button(action: onClaim) {
                    Text("View All")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.billixMoneyGreen)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .stroke(Color.billixMoneyGreen, lineWidth: 2)
                        )
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.95))
            } else {
                // Regular tasks show button with context-appropriate text
                Button(action: onClaim) {
                    Text(task.buttonText ?? "Claim")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            // Use gold gradient for "Claim" button text, green for other actions
                            (task.buttonText == "Claim" || task.canClaim) ?
                            LinearGradient(
                                colors: [.billixArcadeGold, .billixPrizeOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [.billixMoneyGreen, .billixMediumGreen],
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
    var onSeeAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Leaderboard")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                if topSavers.count > 3 {
                    Button {
                        onSeeAll?()
                    } label: {
                        Text("See all")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.billixChartBlue)
                    }
                }
            }

            if topSavers.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.system(size: 32))
                        .foregroundColor(.billixMediumGreen.opacity(0.5))
                    Text("No leaderboard data yet")
                        .font(.system(size: 14))
                        .foregroundColor(.billixMediumGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(topSavers.prefix(3))) { entry in
                        LeaderboardMiniRow(entry: entry)
                    }
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

// MARK: - Full Leaderboard Sheet

struct FullLeaderboardSheet: View {
    let entries: [LeaderboardEntry]
    let currentUser: LeaderboardEntry?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header stats
                    if let currentUser = currentUser {
                        VStack(spacing: 8) {
                            Text("Your Rank")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.billixMediumGreen)

                            Text("#\(currentUser.rank)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.billixDarkGreen)

                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.billixArcadeGold)
                                Text("\(currentUser.pointsThisWeek) pts")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.billixDarkGreen)
                            }
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.billixMoneyGreen.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }

                    // Leaderboard list
                    LazyVStack(spacing: 0) {
                        ForEach(entries) { entry in
                            FullLeaderboardRow(entry: entry)
                            if entry.id != entries.last?.id {
                                Divider()
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#F5F7F6"))
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.billixDarkGreen)
                }
            }
        }
    }
}

struct FullLeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if entry.rank <= 3 {
                    Circle()
                        .fill(entry.rankBadgeColor)
                        .frame(width: 36, height: 36)

                    Text("\(entry.rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("#\(entry.rank)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)
                        .frame(width: 36)
                }
            }

            // Avatar
            Circle()
                .fill(entry.rankBadgeColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(entry.avatarInitials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(entry.rankBadgeColor)
                )

            // Handle
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 15, weight: entry.isCurrentUser ? .bold : .medium))
                    .foregroundColor(entry.isCurrentUser ? .billixMoneyGreen : .billixDarkGreen)

                if entry.isCurrentUser {
                    Text("That's you!")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixMoneyGreen)
                }
            }

            Spacer()

            // Points
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.billixArcadeGold)

                Text("\(entry.pointsThisWeek)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(entry.isCurrentUser ? Color.billixMoneyGreen.opacity(0.08) : Color.clear)
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
    var isPortal: Bool = false  // Special task that opens a new screen
    var buttonText: String?  // Custom button text (e.g., "Check In", "Upload", "Play Now")
    var canClaim: Bool = false  // Whether task is ready to be claimed

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

                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 500_000_000)
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

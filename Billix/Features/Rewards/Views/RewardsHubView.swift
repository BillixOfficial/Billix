//
//  RewardsHubView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Main Rewards Hub - Tab-based interface (Marketplace + Earn Points)
//  Inspired by gamification best practices with bill management context
//

import SwiftUI

// MARK: - Environment Key for Tab Active State
// This allows child views to know when the Rewards tab is active/inactive
// for pausing animations when the tab is hidden

struct RewardsTabActiveKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var isRewardsTabActive: Bool {
        get { self[RewardsTabActiveKey.self] }
        set { self[RewardsTabActiveKey.self] = newValue }
    }
}

struct RewardsHubView: View {

    // Tab active state - passed from MainTabView to control animations when tab is hidden
    var isTabActive: Bool = true

    @StateObject private var viewModel = RewardsViewModel(authService: AuthService.shared)
    @ObservedObject private var tasksViewModel = TasksViewModel.shared
    @State private var selectedTab: RewardsTab = .earn
    @State private var appeared = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                // Background - clean white matching home screen
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Wallet Header (streak carousel only — points shown in gauge card)
                    WalletHeaderView(
                        points: viewModel.displayedBalance,
                        cashEquivalent: viewModel.points.cashEquivalent,
                        currentTier: viewModel.currentTier,
                        tierProgress: viewModel.tierProgress,
                        streakCount: tasksViewModel.currentStreak,
                        weeklyCheckIns: tasksViewModel.weeklyCheckIns,
                        hidePointsHeader: true
                    )
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

                    // Tab Selector
                    TabSelector(selectedTab: $selectedTab)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)

                    // Tab Content (no swipe — use tab buttons only)
                    Group {
                        switch selectedTab {
                        case .earn:
                            EarnPointsTabView(viewModel: viewModel, tasksViewModel: tasksViewModel)
                        case .shop:
                            MarketplaceTabView(viewModel: viewModel)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
            }
            .navigationBarHidden(true)
        }
        .environment(\.isRewardsTabActive, isTabActive)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && appeared {
                Task {
                    await tasksViewModel.loadTasks()
                    await viewModel.loadRewardsData()
                }
            }
        }
        .onAppear {
            PerformanceMonitor.shared.viewAppeared("RewardsHubView")
            // Print status after a short delay to capture all child view registrations
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000)
                PerformanceMonitor.shared.printStatus()
            }
            Task {
                await viewModel.loadRewardsData()
                await tasksViewModel.loadTasks()
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .onChange(of: isTabActive) { _, isActive in
            if isActive {
                PerformanceMonitor.shared.viewAppeared("RewardsHubView (tab activated)")
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    PerformanceMonitor.shared.printStatus()
                }
            } else {
                PerformanceMonitor.shared.viewDisappeared("RewardsHubView (tab deactivated)")
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    PerformanceMonitor.shared.printStatus()
                }
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
                                    colors: [.billixMoneyGreen, .billixMediumGreen],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.billixMoneyGreen.opacity(0.08), Color.billixMoneyGreen.opacity(0.08)],
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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 1. Tier Progress Ring card
                ProgressRingHeroCard(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                // 2. Price Guessr card (separate)
                DailyGameHeroCard(
                    game: viewModel.dailyGame,
                    gamesPlayedToday: viewModel.gamesPlayedToday,
                    onPlay: { viewModel.playDailyGame() }
                )
                    .padding(.horizontal, 20)

                // 3. Daily Tasks Section (carousel)
                DailyTasksSection(tasksViewModel: tasksViewModel, rewardsViewModel: viewModel)
                    .padding(.top, 4)

                // 4. Weekly Tasks Section (unchanged)
                WeeklyTasksSection(tasksViewModel: tasksViewModel)
                    .padding(.horizontal, 20)

                // 5. Leaderboard Teaser (unchanged)
                LeaderboardTeaser(
                    topSavers: viewModel.topSavers,
                    currentUser: viewModel.currentUserRank,
                    onSeeAll: { viewModel.showFullLeaderboard = true }
                )
                .padding(.horizontal, 20)

                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Progress Ring Hero Card

struct ProgressRingHeroCard: View {
    @ObservedObject var viewModel: RewardsViewModel
    @State private var showHowItWorks = false

    private var nextTierThreshold: Int {
        if let next = viewModel.currentTier.nextTier {
            return next.pointsRange.lowerBound
        }
        return viewModel.currentTier.pointsRange.lowerBound
    }

    private var tierStartPoints: Int {
        viewModel.currentTier.pointsRange.lowerBound
    }

    private var milestones: [GaugeMilestone] {
        switch viewModel.currentTier {
        case .bronze: return SpeedometerGauge.bronzeMilestones()
        case .silver: return SpeedometerGauge.silverMilestones()
        case .gold: return SpeedometerGauge.goldMilestones()
        case .platinum: return SpeedometerGauge.platinumMilestones()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top: Speedometer Gauge (includes pig_loading inside)
            VStack(spacing: 6) {
                SpeedometerGauge(
                    progress: viewModel.tierProgress,
                    currentPoints: viewModel.points.lifetimeEarned,
                    maxPoints: nextTierThreshold,
                    tierColor: viewModel.currentTier.color,
                    milestones: milestones,
                    onPigTapped: { showHowItWorks = true }
                )
                .scaleEffect(1.18)
                .offset(y: 25)

                VStack(spacing: 4) {
                    Text("\(viewModel.points.lifetimeEarned.formatted()) / \(nextTierThreshold.formatted()) pts")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(viewModel.currentTier.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(viewModel.currentTier.color)
                }
                .offset(y: 13.3)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 292.4)
        .frame(maxWidth: .infinity)
        .scaleEffect(0.9)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.billixBorderGreen.opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showHowItWorks) {
            RewardsHowItWorksSheet()
                .presentationDetents([.large])
                .presentationBackground(Color(hex: "#F5F7F6"))
                .presentationDragIndicator(.visible)
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

// MARK: - Daily Game Hero Card (Compact Row)

struct DailyGameHeroCard: View {
    let game: DailyGame?
    let gamesPlayedToday: Int
    let onPlay: () -> Void

    // Debug tuning state — long-press card to open
    @State private var showDebug = false

    // Title debug controls
    @State private var titleSize: CGFloat = 24.4
    @State private var titleOffsetX: CGFloat = -50.0
    @State private var titleOffsetY: CGFloat = 0

    // Play Now button debug controls
    @State private var buttonFontSize: CGFloat = 13.0
    @State private var buttonOffsetX: CGFloat = -39.0
    @State private var buttonOffsetY: CGFloat = 0

    // 3D Dollar sign debug controls
    @State private var dollarSize: CGFloat = 165.0
    @State private var dollarOffsetX: CGFloat = -45.0
    @State private var dollarOffsetY: CGFloat = 0

    // Card debug controls
    @State private var cardHeight: CGFloat = 107.0

    // Shimmer debug controls
    @State private var shimmerStart: CGFloat = -40
    @State private var shimmerEnd: CGFloat = 40
    @State private var shimmerOpacity: CGFloat = 0.35
    @State private var shimmerWidth: CGFloat = 40
    @State private var shimmerOffset: CGFloat = -40

    // Background image opacity debug
    @State private var bgImageOpacity: CGFloat = 0.5

    var body: some View {
        ZStack {
            // Hero card background image as base
            Image("HeroCard_MONEY")
                .resizable()
                .scaledToFill()
                .scaleEffect(1.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(bgImageOpacity)

            // Soft mint gradient overlay for depth
            LinearGradient(
                colors: [
                    Color(hex: "#F0F9F4").opacity(0.6),
                    Color(hex: "#E8F5EC").opacity(0.4),
                    Color(hex: "#F5FBF7").opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 12) {
                // 3D Dollar Sign — the hero focal point
                Animated3DDollarSign(offsetX: -0.01, offsetY: 0.00, scale: 1.01)
                    .frame(width: dollarSize, height: dollarSize)
                    .offset(x: dollarOffsetX, y: dollarOffsetY)
                    .shadow(color: Color.billixMoneyGreen.opacity(0.3), radius: 12, x: 0, y: 6)

                // Title + Play button stacked
                VStack(alignment: .leading, spacing: 6) {
                    // Gamified typography — layered shadow + outline
                    ZStack {
                        // Offset shadow layer
                        Text("Price Guessr")
                            .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                            .foregroundColor(Color.billixDarkGreen.opacity(0.15))
                            .offset(x: 1.5, y: 1.5)

                        // Main title
                        Text("Price Guessr")
                            .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                            .foregroundColor(.billixDarkGreen)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .offset(x: titleOffsetX, y: titleOffsetY)

                    // 3D button with bottom border + shimmer
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onPlay()
                    }) {
                        Text("Play Now")
                            .font(.system(size: buttonFontSize, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 9)
                            .background(
                                ZStack {
                                    // Darker bottom border for 3D pressed look
                                    Capsule()
                                        .fill(Color(hex: "#C47A10"))
                                        .offset(y: 3)

                                    // Main gradient fill
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#F5B638"), Color(hex: "#F0A830"), Color(hex: "#E89520")],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )

                                    // Shimmer sweep
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0),
                                                    .white.opacity(shimmerOpacity),
                                                    .white.opacity(0)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: shimmerWidth)
                                        .offset(x: shimmerOffset)
                                }
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color(hex: "#F0A830").opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(FABButtonStyle())
                    .offset(x: buttonOffsetX, y: buttonOffsetY)
                    .accessibilityLabel("Play today's Price Guessr challenge")
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.billixMoneyGreen.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.billixMoneyGreen.opacity(0.12), radius: 12, x: 0, y: 6)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .onAppear { startShimmer() }
        .onChange(of: shimmerStart) { _ in startShimmer() }
        .onChange(of: shimmerEnd) { _ in startShimmer() }
        .onLongPressGesture(minimumDuration: 0.5) { showDebug = true }
        .sheet(isPresented: $showDebug) {
            priceGuessrDebugSheet
                .presentationDetents([.fraction(0.35), .fraction(0.55), .large])
                .interactiveDismissDisabled(false)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily Price Guessr game")
    }



    // MARK: - Shimmer Animation

    private func startShimmer() {
        shimmerOffset = shimmerStart
        withAnimation(.easeInOut(duration: 1.2).delay(1.8).repeatForever(autoreverses: false)) {
            shimmerOffset = shimmerEnd
        }
    }

    // MARK: - Debug Sheet

    private var priceGuessrDebugSheet: some View {
        NavigationView {
            Form {
                Section("Title — \"Price Guessr\"") {
                    HStack {
                        Text("Size")
                        Slider(value: $titleSize, in: 10...40, step: 0.5)
                        Text("\(titleSize, specifier: "%.1f")")
                            .monospacedDigit().frame(width: 40)
                    }
                    HStack {
                        Text("X")
                        Slider(value: $titleOffsetX, in: -50...50, step: 0.5)
                        Text("\(titleOffsetX, specifier: "%.1f")")
                            .monospacedDigit().frame(width: 40)
                    }
                    HStack {
                        Text("Y")
                        Slider(value: $titleOffsetY, in: -50...50, step: 0.5)
                        Text("\(titleOffsetY, specifier: "%.1f")")
                            .monospacedDigit().frame(width: 40)
                    }
                }

                Section("Play Now Button") {
                    HStack {
                        Text("Font Size")
                        Slider(value: $buttonFontSize, in: 8...24, step: 0.5)
                        Text("\(buttonFontSize, specifier: "%.1f")")
                            .monospacedDigit().frame(width: 40)
                    }
                    HStack {
                        Text("X")
                        Slider(value: $buttonOffsetX, in: -50...50, step: 0.5)
                        Text("\(buttonOffsetX, specifier: "%.1f")")
                            .monospacedDigit().frame(width: 40)
                    }
                    HStack {
                        Text("Y")
                        Slider(value: $buttonOffsetY, in: -50...50, step: 0.5)
                        Text("\(buttonOffsetY, specifier: "%.1f")")
                            .monospacedDigit().frame(width: 40)
                    }
                }

                Section("3D Dollar Sign") {
                    HStack {
                        Text("Size")
                        Slider(value: $dollarSize, in: 20...300, step: 1)
                        Text("\(dollarSize, specifier: "%.0f")")
                            .monospacedDigit().frame(width: 40)
                    }
                    HStack {
                        Text("X")
                        Slider(value: $dollarOffsetX, in: -60...60, step: 0.5)
                        Text("\(dollarOffsetX, specifier: "%.1f")")
                            .monospacedDigit().frame(width: 40)
                    }
                    HStack {
                        Text("Y")
                        Slider(value: $dollarOffsetY, in: -60...60, step: 0.5)
                        Text("\(dollarOffsetY, specifier: "%.1f")")
                            .monospacedDigit().frame(width: 40)
                    }
                }

                Section("Shimmer") {
                    HStack {
                        Text("Start X")
                        Slider(value: $shimmerStart, in: -150...0, step: 1)
                        Text("\(shimmerStart, specifier: "%.0f")")
                            .monospacedDigit().frame(width: 44)
                    }
                    HStack {
                        Text("End X")
                        Slider(value: $shimmerEnd, in: 0...150, step: 1)
                        Text("\(shimmerEnd, specifier: "%.0f")")
                            .monospacedDigit().frame(width: 44)
                    }
                    HStack {
                        Text("Width")
                        Slider(value: $shimmerWidth, in: 10...120, step: 1)
                        Text("\(shimmerWidth, specifier: "%.0f")")
                            .monospacedDigit().frame(width: 44)
                    }
                    HStack {
                        Text("Opacity")
                        Slider(value: $shimmerOpacity, in: 0...1, step: 0.05)
                        Text("\(shimmerOpacity, specifier: "%.2f")")
                            .monospacedDigit().frame(width: 44)
                    }
                }

                Section("Card") {
                    HStack {
                        Text("Height")
                        Slider(value: $cardHeight, in: 50...200, step: 1)
                        Text("\(cardHeight, specifier: "%.0f")")
                            .monospacedDigit().frame(width: 40)
                    }
                    HStack {
                        Text("BG Image")
                        Slider(value: $bgImageOpacity, in: 0...1, step: 0.05)
                        Text("\(bgImageOpacity, specifier: "%.2f")")
                            .monospacedDigit().frame(width: 44)
                    }
                }

                Section {
                    Button("Copy Values") {
                        let values = """
                        // Title: size=\(titleSize), x=\(titleOffsetX), y=\(titleOffsetY)
                        // Button: fontSize=\(buttonFontSize), x=\(buttonOffsetX), y=\(buttonOffsetY)
                        // Dollar: size=\(dollarSize), x=\(dollarOffsetX), y=\(dollarOffsetY)
                        // Card: height=\(cardHeight), bgOpacity=\(bgImageOpacity)
                        // Shimmer: start=\(shimmerStart), end=\(shimmerEnd), width=\(shimmerWidth), opacity=\(shimmerOpacity)
                        """
                        UIPasteboard.general.string = values
                    }

                    Button("Reset All") {
                        titleSize = 24.4; titleOffsetX = -50.0; titleOffsetY = 0
                        buttonFontSize = 13.0; buttonOffsetX = -39.0; buttonOffsetY = 0
                        dollarSize = 165.0; dollarOffsetX = -45.0; dollarOffsetY = 0
                        cardHeight = 107.0; bgImageOpacity = 0.5
                        shimmerStart = -40; shimmerEnd = 40; shimmerWidth = 40; shimmerOpacity = 0.35
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Price Guessr Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDebug = false }
                }
            }
        }
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
    @State private var currentCardID: Int? = 1  // Start at index 1 (Check In)

    // Read tab active state from environment to pause timer when tab is hidden
    @Environment(\.isRewardsTabActive) private var isTabActive

    // Debug tuning state — long-press "Daily Tasks" header to open
    @State private var showDebug = false
    @State private var cardHeight: CGFloat = 153
    @State private var cardWidthPercent: CGFloat = 0.4
    @State private var cardPadding: CGFloat = 24
    @State private var iconSize: CGFloat = 42.1
    @State private var elevation: CGFloat = 0
    @State private var frameExtra: CGFloat = 0
    @State private var titleSize: CGFloat = 14.9
    @State private var pointsSize: CGFloat = 12.5
    @State private var claimSize: CGFloat = 13.7
    @State private var vSpacing: CGFloat = 5.7
    @State private var claimPadH: CGFloat = 18
    @State private var claimPadV: CGFloat = 8.8

    // Card dimensions for peek-on-both-sides carousel
    private let screenWidth = UIScreen.main.bounds.width
    private var dailyCardWidthPercent: CGFloat { cardWidthPercent }
    private var dailyCardWidth: CGFloat { screenWidth * cardWidthPercent }
    private var dailyCardHeight: CGFloat { cardHeight }
    private var dailyCardSpacing: CGFloat { screenWidth * 0.03 }


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

    // Build the carousel card data
    private var carouselCards: [DailyCarouselCard] {
        var cards: [DailyCarouselCard] = []

        // Card 0: Quick Earnings (left)
        cards.append(DailyCarouselCard(
            index: 0,
            icon: "bolt.fill",
            title: "Quick Earnings",
            points: 0,
            isCompleted: false,
            canClaim: false,
            ctaText: "View All",
            cardType: .quickEarnings
        ))

        // Card 1: Check In Today (center, default)
        let checkInTask = tasksViewModel.dailyTasks.first { $0.taskType == .checkIn }
        cards.append(DailyCarouselCard(
            index: 1,
            icon: checkInTask?.isClaimed == true ? "calendar.badge.checkmark" : "calendar",
            title: "Check In Today",
            points: checkInTask?.points ?? 10,
            isCompleted: checkInTask?.isClaimed ?? false,
            canClaim: checkInTask?.canClaim ?? false,
            ctaText: checkInTask?.ctaText ?? "Check In",
            cardType: .checkIn
        ))

        // Card 2: Upload a Bill (right)
        let uploadTask = tasksViewModel.dailyTasks.first { $0.taskType == .billUpload }
        cards.append(DailyCarouselCard(
            index: 2,
            icon: "doc.badge.plus",
            title: "Upload a Bill",
            points: uploadTask?.points ?? 25,
            isCompleted: uploadTask?.isClaimed ?? false,
            canClaim: uploadTask?.canClaim ?? false,
            ctaText: uploadTask?.ctaText ?? "Upload",
            cardType: .upload
        ))

        return cards
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header — long-press to open debug controls
            HStack {
                Text("Daily Tasks")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Text("Resets in \(timeUntilReset)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }
            .padding(.horizontal, 20)
            .onLongPressGesture(minimumDuration: 0.5) {
                let g = UIImpactFeedbackGenerator(style: .heavy)
                g.impactOccurred()
                showDebug = true
            }

            // Carousel - ScrollView + GeometryReader for peek-on-both-sides
            if tasksViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: dailyCardSpacing) {
                        ForEach(Array(carouselCards.enumerated()), id: \.offset) { index, card in
                            DailyTaskCarouselCardView(
                                card: card,
                                onAction: { handleCardAction(card) },
                                cardPadding: cardPadding,
                                iconSize: iconSize,
                                titleSize: titleSize,
                                pointsSize: pointsSize,
                                claimSize: claimSize,
                                vSpacing: vSpacing,
                                claimPadH: claimPadH,
                                claimPadV: claimPadV
                            )
                            .containerRelativeFrame(.horizontal)
                            .id(index)
                            .visualEffect { content, proxy in
                                content
                                    .offset(y: dailyCardElevation(for: proxy))
                                    .opacity(dailyCardOpacity(for: proxy))
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentCardID)
                .safeAreaPadding(.horizontal, (screenWidth - 40 - dailyCardWidth) / 2)
                .scrollClipDisabled()
                .padding(.horizontal, 20)
                .frame(height: dailyCardHeight + frameExtra + 24)
            }
        }
        .onAppear {
            PerformanceMonitor.shared.viewAppeared("DailyTasksSection")
        }
        .onDisappear {
            PerformanceMonitor.shared.timerStopped("countdownTimer", in: "DailyTasksSection")
            PerformanceMonitor.shared.viewDisappeared("DailyTasksSection")
        }
        .task {
            await tasksViewModel.loadTasks()
        }
        .task(id: isTabActive) {
            // Only run timer when tab is active
            guard isTabActive else {
                PerformanceMonitor.shared.timerStopped("countdownTimer", in: "DailyTasksSection (tab inactive)")
                return
            }
            // Task-based timer that auto-cancels when view disappears or tab changes
            PerformanceMonitor.shared.timerStarted("countdownTimer", in: "DailyTasksSection", interval: 60)
            while !Task.isCancelled && isTabActive {
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
                if Task.isCancelled || !isTabActive { break }
                currentTime = Date()
            }
            PerformanceMonitor.shared.timerStopped("countdownTimer", in: "DailyTasksSection")
        }
        .sheet(isPresented: $showQuickTasks) {
            QuickTasksScreen()
        }
        .safeAreaInset(edge: .bottom) {
            if showDebug {
                DailyTasksInlineDebugPanel(
                    showDebug: $showDebug,
                    cardHeight: $cardHeight,
                    cardWidthPercent: $cardWidthPercent,
                    cardPadding: $cardPadding,
                    iconSize: $iconSize,
                    elevation: $elevation,
                    frameExtra: $frameExtra,
                    titleSize: $titleSize,
                    pointsSize: $pointsSize,
                    claimSize: $claimSize,
                    vSpacing: $vSpacing,
                    claimPadH: $claimPadH,
                    claimPadV: $claimPadV
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showDebug)
    }

    private func dailyCardElevation(for proxy: GeometryProxy) -> CGFloat {
        let cardCenterX = proxy.frame(in: .scrollView).midX
        let viewportCenterX = proxy.bounds(of: .scrollView)?.midX ?? 0
        let distance = abs(cardCenterX - viewportCenterX)
        let normalized = min(distance / dailyCardWidth, 1.0)
        let eased = 1 - pow(1 - normalized, 2)
        return -elevation * (1 - eased)
    }

    private func dailyCardOpacity(for proxy: GeometryProxy) -> CGFloat {
        let cardCenterX = proxy.frame(in: .scrollView).midX
        let viewportCenterX = proxy.bounds(of: .scrollView)?.midX ?? 0
        let distance = abs(cardCenterX - viewportCenterX)
        let normalized = min(distance / dailyCardWidth, 1.0)
        return 1.0 - (normalized * 0.4)  // 1.0 center → 0.6 edges
    }

    private func handleCardAction(_ card: DailyCarouselCard) {
        switch card.cardType {
        case .checkIn:
            Task {
                await tasksViewModel.performCheckIn()
                await rewardsViewModel.loadRewardsData()
            }
        case .upload:
            if card.canClaim {
                let uploadTask = tasksViewModel.dailyTasks.first { $0.taskType == .billUpload }
                if let task = uploadTask {
                    Task {
                        await tasksViewModel.claimTask(task)
                        await rewardsViewModel.loadRewardsData()
                    }
                }
            } else {
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToUpload"), object: nil)
            }
        case .quickEarnings:
            showQuickTasks = true
        }
    }
}

// MARK: - Daily Tasks Inline Debug Panel

private struct DailyTasksInlineDebugPanel: View {
    @Binding var showDebug: Bool
    @Binding var cardHeight: CGFloat
    @Binding var cardWidthPercent: CGFloat
    @Binding var cardPadding: CGFloat
    @Binding var iconSize: CGFloat
    @Binding var elevation: CGFloat
    @Binding var frameExtra: CGFloat
    @Binding var titleSize: CGFloat
    @Binding var pointsSize: CGFloat
    @Binding var claimSize: CGFloat
    @Binding var vSpacing: CGFloat
    @Binding var claimPadH: CGFloat
    @Binding var claimPadV: CGFloat
    @State private var copied = false

    private var valuesString: String {
        "cardHeight: \(fmt(cardHeight)), widthPct: \(fmt(cardWidthPercent)), padding: \(fmt(cardPadding)), iconSize: \(fmt(iconSize)), elevation: \(fmt(elevation)), frameExtra: \(fmt(frameExtra)), titleSize: \(fmt(titleSize)), pointsSize: \(fmt(pointsSize)), claimSize: \(fmt(claimSize)), vSpacing: \(fmt(vSpacing)), claimPadH: \(fmt(claimPadH)), claimPadV: \(fmt(claimPadV))"
    }

    private func fmt(_ v: CGFloat) -> String { String(format: "%.1f", v) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Debug Controls")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Button("Done") {
                    showDebug = false
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Sliders
            VStack(spacing: 8) {
                sliderRow("Height", color: .blue, value: $cardHeight, range: 80...250, step: 5)
                sliderRow("Width %", color: .purple, value: $cardWidthPercent, range: 0.4...0.9, step: 0.02)
                sliderRow("Padding", color: .cyan, value: $cardPadding, range: 4...24, step: 1)
                sliderRow("Icon", color: .green, value: $iconSize, range: 20...60, step: 2)
                sliderRow("Title", color: .mint, value: $titleSize, range: 8...24, step: 0.5)
                sliderRow("Points", color: .teal, value: $pointsSize, range: 8...20, step: 0.5)
                sliderRow("Claim", color: .indigo, value: $claimSize, range: 8...20, step: 0.5)
                sliderRow("Spacing", color: .pink, value: $vSpacing, range: 0...20, step: 1)
                sliderRow("ClmPdH", color: .brown, value: $claimPadH, range: 4...40, step: 1)
                sliderRow("ClmPdV", color: .yellow, value: $claimPadV, range: 2...20, step: 1)
                sliderRow("Elevtn", color: .orange, value: $elevation, range: 0...40, step: 2)
                sliderRow("Frame+", color: .red, value: $frameExtra, range: 0...60, step: 2)
            }
            .padding(.horizontal, 20)

            // Actions
            HStack(spacing: 12) {
                Button {
                    cardHeight = 153; cardWidthPercent = 0.4; cardPadding = 24
                    iconSize = 42.1; elevation = 0; frameExtra = 0
                    titleSize = 14.9; pointsSize = 12.5; claimSize = 13.7
                    vSpacing = 5.7; claimPadH = 18; claimPadV = 8.8
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }

                Button {
                    UIPasteboard.general.string = valuesString
                    copied = true
                    let g = UINotificationFeedbackGenerator()
                    g.notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(copied ? Color.green : Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .frame(maxHeight: 460)
        .background(.ultraThinMaterial)
    }

    private func sliderRow(_ label: String, color: Color, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, step: CGFloat) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 52, alignment: .leading)
            Slider(value: value, in: range, step: step)
                .tint(color)
            Text(fmt(value.wrappedValue))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)
        }
        .frame(height: 28)
    }
}

// MARK: - Daily Carousel Card Model

struct DailyCarouselCard: Identifiable {
    let index: Int
    let icon: String
    let title: String
    let points: Int
    let isCompleted: Bool
    let canClaim: Bool
    let ctaText: String
    let cardType: DailyCardType

    var id: Int { index }

    enum DailyCardType {
        case upload
        case checkIn
        case quickEarnings
    }
}

// MARK: - Daily Task Carousel Card View

struct DailyTaskCarouselCardView: View {
    let card: DailyCarouselCard
    let onAction: () -> Void
    var cardPadding: CGFloat = 14
    var iconSize: CGFloat = 40
    var titleSize: CGFloat = 14
    var pointsSize: CGFloat = 12
    var claimSize: CGFloat = 13
    var vSpacing: CGFloat = 8
    var claimPadH: CGFloat = 18
    var claimPadV: CGFloat = 8

    var body: some View {
        VStack(spacing: vSpacing) {
            // Title
            Text(card.title)
                .font(.system(size: titleSize, weight: .bold))
                .foregroundColor(.billixDarkGreen)
                .multilineTextAlignment(.center)
                .lineLimit(1)

            // Points or subtitle
            if card.cardType == .quickEarnings {
                Text("Bonus mini-tasks")
                    .font(.system(size: pointsSize, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: pointsSize - 2))
                        .foregroundColor(.billixArcadeGold)
                    Text("+\(card.points) pts")
                        .font(.system(size: pointsSize, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            // Icon
            ZStack {
                Circle()
                    .fill(
                        (card.cardType == .quickEarnings ? Color.billixArcadeGold : Color.billixMoneyGreen)
                            .opacity(0.15)
                    )
                    .frame(width: iconSize, height: iconSize)

                Image(systemName: card.icon)
                    .font(.system(size: iconSize * 0.45, weight: .semibold))
                    .foregroundColor(card.cardType == .quickEarnings ? .billixArcadeGold : .billixMoneyGreen)
            }

            Spacer(minLength: 0)

            // Action button
            if card.isCompleted {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: claimSize - 1))
                    Text("Done")
                        .font(.system(size: claimSize - 1, weight: .semibold))
                }
                .foregroundColor(.billixMoneyGreen)
                .padding(.horizontal, claimPadH)
                .padding(.vertical, claimPadV)
                .background(
                    Capsule()
                        .fill(Color.billixMoneyGreen.opacity(0.15))
                )
            } else {
                Button(action: onAction) {
                    Text(card.canClaim ? "Claim" : card.ctaText)
                        .font(.system(size: claimSize, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, claimPadH)
                        .padding(.vertical, claimPadV)
                        .background(
                            Capsule()
                                .fill(
                                    card.canClaim ?
                                    LinearGradient(
                                        colors: [.billixGoldenAmber, .billixPrizeOrange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [.billixMoneyGreen, .billixMediumGreen],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.95))
            }
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
        )
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

    // Read tab active state from environment to pause timer when tab is hidden
    @Environment(\.isRewardsTabActive) private var isTabActive

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
        .onAppear {
            PerformanceMonitor.shared.viewAppeared("WeeklyTasksSection")
        }
        .onDisappear {
            PerformanceMonitor.shared.timerStopped("countdownTimer", in: "WeeklyTasksSection")
            PerformanceMonitor.shared.viewDisappeared("WeeklyTasksSection")
        }
        .task {
            await tasksViewModel.loadTasks()
        }
        .task(id: isTabActive) {
            // Only run timer when tab is active
            guard isTabActive else {
                PerformanceMonitor.shared.timerStopped("countdownTimer", in: "WeeklyTasksSection (tab inactive)")
                return
            }
            // Task-based timer that auto-cancels when view disappears or tab changes
            PerformanceMonitor.shared.timerStarted("countdownTimer", in: "WeeklyTasksSection", interval: 60)
            while !Task.isCancelled && isTabActive {
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
                if Task.isCancelled || !isTabActive { break }
                currentTime = Date()
            }
            PerformanceMonitor.shared.timerStopped("countdownTimer", in: "WeeklyTasksSection")
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
                            // Amber for Claim, sage green for other actions
                            (task.buttonText == "Claim" || task.canClaim) ?
                            LinearGradient(
                                colors: [.billixGoldenAmber, .billixPrizeOrange],
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

                Text("\(entry.totalPoints)")
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
                                Text("\(currentUser.totalPoints) pts")
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

                Text("\(entry.totalPoints)")
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

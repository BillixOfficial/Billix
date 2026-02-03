//
//  WalletHeaderView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Zone A: Sticky wallet header with point balance and slot-machine animation
//

import SwiftUI

struct WalletHeaderView: View {
    let points: Int
    let cashEquivalent: Double
    let currentTier: RewardsTier
    let tierProgress: Double  // 0.0 to 1.0 progress to next tier
    let streakCount: Int  // Real check-in streak from TasksViewModel
    let weeklyCheckIns: [Bool]  // Actual check-in days (Mon-Sun)

    @State private var animatedPoints: Int = 0
    @State private var showShimmer = false
    @State private var currentStatIndex: Int = 0
    @State private var showHowItWorks = false

    // Computed property for points to next tier
    private var pointsToNextTier: Int {
        guard let nextTier = currentTier.nextTier else { return 0 }
        return nextTier.pointsRange.lowerBound - points
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Points Icon with Tier Ring (Tappable)
                Button(action: {
                    showHowItWorks = true
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.billixArcadeGold, .billixPrizeOrange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .shadow(color: .billixArcadeGold.opacity(0.4), radius: 8, x: 0, y: 4)

                        // Billix logo (same as modal)
                        Image("billix_logo_new")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)

                        // Tier Progress Ring
                        TierProgressRing(
                            currentTier: currentTier,
                            progress: tierProgress,
                            showSparkles: false
                        )
                        .frame(width: 60, height: 60)
                    }
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.95))

                // Points Balance with Tier Info
                VStack(alignment: .leading, spacing: 4) {
                    // Big rolling number
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(points)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.billixDarkGreen)
                            .contentTransition(.numericText(value: Double(points)))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: points)

                        Text("pts")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.billixMediumGreen)
                    }

                    // Tier progress
                    if let nextTier = currentTier.nextTier {
                        Text("\(pointsToNextTier) pts to \(nextTier.rawValue)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(currentTier.color)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)

            // Streak & Stats Carousel
            StreakStatsCarousel(
                streakDays: streakCount,
                weeklyCheckIns: weeklyCheckIns,
                thisWeek: 240,
                toNextTier: pointsToNextTier,
                currentTier: currentTier
            )
            .padding(.bottom, 12)
            .background(
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            Color.billixArcadeGold.opacity(0.15),
                            Color.billixPrizeOrange.opacity(0.08),
                            Color.billixLightGreen
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Decorative elements
                    GeometryReader { geometry in
                        Circle()
                            .fill(Color.billixArcadeGold.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .offset(x: geometry.size.width - 60, y: -30)

                        Circle()
                            .fill(Color.billixPrizeOrange.opacity(0.08))
                            .frame(width: 60, height: 60)
                            .offset(x: geometry.size.width - 40, y: 50)
                    }

                    // Bottom border
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.billixArcadeGold.opacity(0.3), .billixPrizeOrange.opacity(0.2), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 2)
                    }
                }
            )
        }
        .sheet(isPresented: $showHowItWorks) {
            RewardsHowItWorksSheet()
                .presentationDetents([.large])
                .presentationBackground(Color(hex: "#F5F7F6"))
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Tier Progress Ring

struct TierProgressRing: View {
    let currentTier: RewardsTier
    let progress: Double
    let showSparkles: Bool

    // Read tab active state from environment to pause animations when tab is hidden
    @Environment(\.isRewardsTabActive) private var isTabActive

    @State private var animatedProgress: Double = 0.0
    @State private var sparkleOffset: CGFloat = 0
    @State private var isVisible: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: tierGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animatedProgress)

            if showSparkles && isVisible {
                Circle()
                    .fill(tierColor)
                    .frame(width: 8, height: 8)
                    .offset(x: 26)
                    .rotationEffect(.degrees(360 * animatedProgress - 90))
                    .shadow(color: tierColor, radius: 4)
                    .opacity(sparkleOffset == 0 ? 1 : 0.7)
                    .scaleEffect(sparkleOffset == 0 ? 1.2 : 1.0)
                    .animation(isVisible ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: sparkleOffset)
            }
        }
        .task(id: isTabActive) {
            // Only run animations when tab is active
            guard isTabActive else {
                if showSparkles {
                    PerformanceMonitor.shared.animationStopped("sparkle", in: "TierProgressRing (tab inactive)")
                }
                PerformanceMonitor.shared.viewDisappeared("TierProgressRing (tab inactive)")
                isVisible = false
                sparkleOffset = 0
                return
            }

            PerformanceMonitor.shared.viewAppeared("TierProgressRing")
            isVisible = true
            if showSparkles {
                PerformanceMonitor.shared.animationStarted("sparkle", in: "TierProgressRing")
            }
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3)) {
                animatedProgress = progress
            }
            if showSparkles {
                withAnimation {
                    sparkleOffset = 1
                }
            }
        }
        .onDisappear {
            if showSparkles {
                PerformanceMonitor.shared.animationStopped("sparkle", in: "TierProgressRing")
            }
            PerformanceMonitor.shared.viewDisappeared("TierProgressRing")
            isVisible = false
            sparkleOffset = 0
        }
    }

    private var tierColor: Color {
        switch currentTier {
        case .bronze: return .billixBronzeTier
        case .silver: return .billixSilverTier
        case .gold: return .billixGoldTier
        case .platinum: return .billixPlatinumTier
        }
    }

    private var tierGradientColors: [Color] {
        switch currentTier {
        case .bronze: return [Color.billixBronzeTier, Color.billixBronzeTier.opacity(0.7)]
        case .silver: return [Color.billixSilverTier, Color.billixSilverTier.opacity(0.7)]
        case .gold: return [Color.billixGoldTier, Color.billixPrizeOrange]
        case .platinum: return [Color.billixPlatinumTier, Color.billixSilverTier]
        }
    }
}

// MARK: - Streak & Stats Carousel

struct StreakStatsCarousel: View {
    let streakDays: Int
    let weeklyCheckIns: [Bool]  // Actual check-in days from database (Mon-Sun)
    let thisWeek: Int
    let toNextTier: Int
    let currentTier: RewardsTier

    // Read tab active state from environment to pause auto-scroll when tab is hidden
    @Environment(\.isRewardsTabActive) private var isTabActive

    @State private var currentIndex: Int = 0

    // Week days (Monday to Sunday)
    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // Tier badges - dynamically calculated based on currentTier
    private var tierBadges: [(tier: String, isEarned: Bool)] {
        let allTiers: [RewardsTier] = [.bronze, .silver, .gold, .platinum]
        return allTiers.map { tier in
            (tier: tier.rawValue, isEarned: tier.pointsRange.lowerBound <= currentTier.pointsRange.lowerBound)
        }
    }

    // Use TimelineView for automatic carousel - no Timer memory leak risk
    private let autoScrollInterval: TimeInterval = 4.5

    var body: some View {
        HStack(spacing: 8) {
            // Left Arrow
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentIndex = currentIndex == 0 ? 1 : 0
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixMoneyGreen)
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.9))

            // Content
            TabView(selection: $currentIndex) {
                // Slide 1: Weekly Progress
                WeeklyProgressSlide(days: weekDays, progress: weeklyCheckIns, actualStreak: streakDays)
                    .tag(0)

                // Slide 2: My Tier Badges
                MyBadgesSlide(tierBadges: tierBadges)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.4), value: currentIndex)
            .frame(height: 70)

            // Right Arrow
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentIndex = currentIndex == 0 ? 1 : 0
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixMoneyGreen)
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.9))
        }
        .padding(.horizontal, 4)
        .onAppear {
            PerformanceMonitor.shared.viewAppeared("StreakStatsCarousel")
        }
        .task(id: isTabActive) {
            // Only run auto-scroll when tab is active
            guard isTabActive else {
                PerformanceMonitor.shared.taskCancelled("autoScroll", in: "StreakStatsCarousel (tab inactive)")
                return
            }
            // Use structured concurrency for auto-scroll - automatically cancelled when view disappears or tab changes
            PerformanceMonitor.shared.taskStarted("autoScroll", in: "StreakStatsCarousel")
            defer {
                PerformanceMonitor.shared.taskCancelled("autoScroll", in: "StreakStatsCarousel")
                PerformanceMonitor.shared.viewDisappeared("StreakStatsCarousel")
            }
            await autoScrollLoop()
        }
    }

    @MainActor
    private func autoScrollLoop() async {
        while !Task.isCancelled && isTabActive {
            try? await Task.sleep(nanoseconds: UInt64(autoScrollInterval * 1_000_000_000))

            if Task.isCancelled || !isTabActive { break }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentIndex = currentIndex == 0 ? 1 : 0
            }
        }
    }
}

// MARK: - Weekly Progress Slide

struct WeeklyProgressSlide: View {
    let days: [String]
    let progress: [Bool]
    let actualStreak: Int  // Real streak count from database

    @State private var animatedChecks: [Bool] = Array(repeating: false, count: 7)

    private var streakCount: Int {
        actualStreak  // Use the real streak count instead of calculating
    }

    private var streakColor: Color {
        switch streakCount {
        case 4...Int.max: return Color(hex: "#FF6B35") // Hot streak - Orange/Red
        case 2...3: return Color(hex: "#4A90E2") // Cooling - Blue
        default: return Color.gray // No streak - Gray
        }
    }

    private var streakIcon: String {
        switch streakCount {
        case 4...Int.max: return "flame.fill" // Hot streak
        case 2...3: return "snowflake" // Cooling streak
        default: return "flame.fill" // No streak
        }
    }

    /// Today's weekday index (Mon=0, Tue=1, ..., Sun=6)
    private var todayWeekdayIndex: Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Convert: Sunday=1, Monday=2...Saturday=7 → Monday=0...Sunday=6
        return weekday == 1 ? 6 : weekday - 2
    }

    /// Pre-computed checkmark states for all 7 days - computed once per render
    private var checkmarkStates: [Bool] {
        guard actualStreak > 0 else {
            return Array(repeating: false, count: 7)
        }

        // Find the last check-in day (streak end) - don't assume it's today
        var streakEndIndex = todayWeekdayIndex

        // If today hasn't been checked in yet, find the last checked day
        if !progress[todayWeekdayIndex] {
            // Search backwards from today to find the last check-in
            for i in stride(from: todayWeekdayIndex - 1, through: 0, by: -1) {
                if progress[i] {
                    streakEndIndex = i
                    break
                }
            }
            // Also check if streak ended last week (wrap around)
            if streakEndIndex == todayWeekdayIndex && !progress[todayWeekdayIndex] {
                for i in stride(from: 6, through: todayWeekdayIndex + 1, by: -1) {
                    if progress[i] {
                        streakEndIndex = i
                        break
                    }
                }
            }
        }

        // Calculate streak start based on the actual streak end
        let streakStartIndex = streakEndIndex - actualStreak + 1

        // Pre-compute all 7 checkmark states
        var states = [Bool](repeating: false, count: 7)
        for index in 0..<7 {
            if streakStartIndex < 0 {
                // Streak spans from previous week
                states[index] = (index >= (7 + streakStartIndex) || index <= streakEndIndex) && progress[index]
            } else {
                states[index] = index >= streakStartIndex && index <= streakEndIndex && progress[index]
            }
        }
        return states
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left side: Streak Count
            VStack(spacing: 2) {
                Text("\(streakCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(streakColor)

                Text("Day Streak!")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(streakColor)
            }

            // Right side: Weekly Progress
            VStack(spacing: 4) {
                // Title
                Text("Weekly Progress")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)

                // Days row - uses pre-computed checkmarkStates for performance
                HStack(spacing: 4) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        VStack(spacing: 2) {
                            Text(day)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.billixMediumGreen)
                                .frame(width: 24)

                            ZStack {
                                Circle()
                                    .fill(checkmarkStates[index] ? Color.billixArcadeGold : Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 20)
                                    .scaleEffect(animatedChecks[index] ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.08), value: animatedChecks[index])

                                if checkmarkStates[index] {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .scaleEffect(animatedChecks[index] ? 1.0 : 0.3)
                                        .opacity(animatedChecks[index] ? 1.0 : 0.0)
                                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double(index) * 0.08), value: animatedChecks[index])
                                }
                            }
                        }
                    }
                }
            }

            // Streak icon (dynamic based on streak) - static to avoid continuous animation
            Image(systemName: streakIcon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(streakColor)
        }
        .onAppear {
            // Trigger animation on appear for days that are part of the current streak
            // Uses pre-computed checkmarkStates for consistency
            let states = checkmarkStates
            for i in 0..<states.count {
                if states[i] {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        animatedChecks[i] = true
                    }
                }
            }
        }
    }
}

// MARK: - My Badges Slide

struct MyBadgesSlide: View {
    let tierBadges: [(tier: String, isEarned: Bool)]

    var body: some View {
        VStack(spacing: 8) {
            // Title
            Text("My Tier Badges")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.billixMediumGreen)

            // Badges row
            HStack(spacing: 28) {
                ForEach(Array(tierBadges.enumerated()), id: \.offset) { index, badge in
                    TierBadgeHexagon(tier: badge.tier, isEarned: badge.isEarned)
                }
            }
        }
    }
}

// MARK: - Tier Badge Hexagon

struct TierBadgeHexagon: View {
    let tier: String
    let isEarned: Bool

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Hexagon shape (using SF Symbol)
                Image(systemName: "hexagon.fill")
                    .font(.system(size: 32))
                    .foregroundColor(isEarned ? badgeColor : Color.gray.opacity(0.3))

                // Medal icon
                Image(systemName: medalIcon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            // Tier label
            Text(tier)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(isEarned ? badgeColor : Color.gray.opacity(0.6))
        }
    }

    private var medalIcon: String {
        switch tier {
        case "Bronze": return "medal.fill"
        case "Silver": return "medal.fill"
        case "Gold": return "medal.fill"
        case "Platinum": return "crown.fill"
        default: return "medal.fill"
        }
    }

    private var badgeColor: Color {
        switch tier {
        case "Bronze": return .billixBronzeTier
        case "Silver": return .billixSilverTier
        case "Gold": return .billixGoldTier
        case "Platinum": return .billixPlatinumTier
        default: return .gray
        }
    }
}

// MARK: - Animated Points Text (Alternative to contentTransition)

struct RollingNumberView: View {
    let value: Int
    let font: Font
    let color: Color

    @State private var displayedValue: Int = 0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        Text("\(displayedValue)")
            .font(font)
            .foregroundColor(color)
            .onChange(of: value) { oldValue, newValue in
                animateValueChange(from: oldValue, to: newValue)
            }
            .onAppear {
                displayedValue = value
            }
            .onDisappear {
                // Cancel animation when view disappears
                animationTask?.cancel()
            }
    }

    private func animateValueChange(from oldValue: Int, to newValue: Int) {
        // Cancel any existing animation
        animationTask?.cancel()

        let difference = newValue - oldValue
        let steps = min(abs(difference), 30)
        let stepDurationNs: UInt64 = UInt64(500_000_000 / max(steps, 1)) // 0.5s total

        animationTask = Task { @MainActor in
            for i in 0...steps {
                if Task.isCancelled { break }

                let progress = Double(i) / Double(max(steps, 1))
                let easedProgress = 1 - pow(1 - progress, 3) // Ease out cubic
                displayedValue = oldValue + Int(Double(difference) * easedProgress)

                if i < steps {
                    try? await Task.sleep(nanoseconds: stepDurationNs)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Bronze Tier - 1,450 pts") {
    VStack {
        WalletHeaderView(
            points: 1450,
            cashEquivalent: 0.73,
            currentTier: .bronze,
            tierProgress: 0.18,  // 1,450 / 8,000 = ~18%
            streakCount: 3,
            weeklyCheckIns: [false, false, false, false, true, true, true]  // Thu-Fri-Sat checked
        )

        Spacer()
    }
    .background(Color.billixLightGreen)
}

#Preview("Silver Tier - 12,000 pts") {
    VStack {
        WalletHeaderView(
            points: 12000,
            cashEquivalent: 6.00,
            currentTier: .silver,
            tierProgress: 0.18,  // 4,000 / 22,000 = ~18%
            streakCount: 5,
            weeklyCheckIns: [false, false, true, true, true, true, true]  // Wed-Sun checked
        )

        Spacer()
    }
    .background(Color.billixLightGreen)
}

#Preview("Gold Tier - 45,000 pts") {
    VStack {
        WalletHeaderView(
            points: 45000,
            cashEquivalent: 22.50,
            currentTier: .gold,
            tierProgress: 0.21,  // 15,000 / 70,000 = ~21%
            streakCount: 7,
            weeklyCheckIns: [true, true, true, true, true, true, true]  // Full week checked
        )

        Spacer()
    }
    .background(Color.billixLightGreen)
}

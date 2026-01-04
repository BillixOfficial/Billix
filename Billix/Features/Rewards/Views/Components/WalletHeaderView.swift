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
    let onHistoryTapped: () -> Void

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

                    // Cash equivalent
                    Text("≈ \(String(format: "$%.2f", cashEquivalent)) value")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    // Tier progress
                    if let nextTier = currentTier.nextTier {
                        Text("\(pointsToNextTier) pts to \(nextTier.rawValue)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(currentTier.color)
                    }
                }

                Spacer()

                // History Button
                Button(action: onHistoryTapped) {
                    ZStack {
                        Circle()
                            .fill(Color.billixDarkGreen.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.billixDarkGreen)
                    }
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.9))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)

            // Streak & Stats Carousel
            StreakStatsCarousel(
                streakDays: streakCount,
                weeklyCheckIns: weeklyCheckIns,
                thisWeek: 240,
                toNextTier: pointsToNextTier
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

    @State private var animatedProgress: Double = 0.0
    @State private var sparkleOffset: CGFloat = 0

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

            if showSparkles {
                Circle()
                    .fill(tierColor)
                    .frame(width: 8, height: 8)
                    .offset(x: 26)
                    .rotationEffect(.degrees(360 * animatedProgress - 90))
                    .shadow(color: tierColor, radius: 4)
                    .opacity(sparkleOffset == 0 ? 1 : 0.7)
                    .scaleEffect(sparkleOffset == 0 ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: sparkleOffset)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3)) {
                animatedProgress = progress
            }
            if showSparkles {
                withAnimation {
                    sparkleOffset = 1
                }
            }
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

    @State private var currentIndex: Int = 0
    @State private var timer: Timer?

    // Week days (Monday to Sunday)
    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // Tier badges (Bronze, Silver, Gold, Platinum, Diamond)
    private let tierBadges: [(tier: String, isEarned: Bool)] = [
        ("Bronze", true),
        ("Silver", false),
        ("Gold", false),
        ("Platinum", false)
    ]

    var body: some View {
        HStack(spacing: 8) {
            // Left Arrow
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentIndex = currentIndex == 0 ? 1 : 0
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                resetTimer()
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
            .frame(height: 70)

            // Right Arrow
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentIndex = currentIndex == 0 ? 1 : 0
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                resetTimer()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixMoneyGreen)
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.9))
        }
        .padding(.horizontal, 4)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: true) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentIndex = currentIndex == 0 ? 1 : 0
            }
        }
    }

    private func resetTimer() {
        startTimer()
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

    var body: some View {
        let _ = print("🎯 [CAROUSEL] WeeklyProgressSlide rendering - streakCount: \(streakCount), actualStreak: \(actualStreak)")
        HStack(spacing: 12) {
            // Left side: Streak Count
            VStack(spacing: 2) {
                Text("\(streakCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(streakColor)
                    .onAppear {
                        print("🎯 [CAROUSEL] Streak text appeared with value: \(streakCount)")
                    }

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

                // Days row
                HStack(spacing: 4) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        VStack(spacing: 2) {
                            Text(day)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.billixMediumGreen)
                                .frame(width: 24)

                            ZStack {
                                Circle()
                                    .fill(progress[index] ? Color.billixArcadeGold : Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 20)
                                    .scaleEffect(animatedChecks[index] ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.08), value: animatedChecks[index])

                                if progress[index] {
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

            // Streak icon (dynamic based on streak)
            Image(systemName: streakIcon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(streakColor)
                .symbolEffect(.pulse, options: streakCount >= 4 ? .repeating : .default)
        }
        .onAppear {
            // Trigger animation on appear
            for i in 0..<progress.count {
                if progress[i] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
    }

    private func animateValueChange(from oldValue: Int, to newValue: Int) {
        let difference = newValue - oldValue
        let steps = min(abs(difference), 30)
        let stepDuration: TimeInterval = 0.5 / Double(max(steps, 1))

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let progress = Double(i) / Double(max(steps, 1))
                let easedProgress = 1 - pow(1 - progress, 3) // Ease out cubic
                displayedValue = oldValue + Int(Double(difference) * easedProgress)
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
            weeklyCheckIns: [false, false, false, false, true, true, true],  // Thu-Fri-Sat checked
            onHistoryTapped: {}
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
            weeklyCheckIns: [false, false, true, true, true, true, true],  // Wed-Sun checked
            onHistoryTapped: {}
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
            weeklyCheckIns: [true, true, true, true, true, true, true],  // Full week checked
            onHistoryTapped: {}
        )

        Spacer()
    }
    .background(Color.billixLightGreen)
}

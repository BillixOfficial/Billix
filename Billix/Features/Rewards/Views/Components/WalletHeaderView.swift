//
//  WalletHeaderView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Zone A: Sticky wallet header with point balance and slot-machine animation
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
    static let info = Color(hex: "#5BA4D4")
    static let purple = Color(hex: "#5D4DB1")

    // Rewards colors (using Billix palette)
    static let gold = Color(hex: "#D4A04E")            // Billix Gold
    static let streak = Color(hex: "#4CAF7A")          // Green for streaks

    // Spacing
    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 16

    // Shadow
    static let shadowColor = Color.black.opacity(0.04)
    static let shadowRadius: CGFloat = 10
}

struct WalletHeaderView: View {
    let points: Int
    let cashEquivalent: Double
    let onHistoryTapped: () -> Void

    // Mock data for visual design
    let currentTier: RewardsTier = .bronze
    let tierProgress: Double = 0.45  // 45% to next tier
    let streakCount: Int = 7
    let streakAtRisk: Bool = false

    @State private var animatedPoints: Int = 0
    @State private var showShimmer = false
    @State private var currentStatIndex: Int = 0

    // Computed property for points to next tier
    private var pointsToNextTier: Int {
        guard let nextTier = currentTier.nextTier else { return 0 }
        return nextTier.pointsRange.lowerBound - points
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Points Icon with Tier Ring
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.purple, Theme.purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: Theme.purple.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "star.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)

                    // Tier Progress Ring
                    TierProgressRing(
                        currentTier: currentTier,
                        progress: tierProgress,
                        showSparkles: false
                    )
                    .frame(width: 60, height: 60)
                }

                // Points Balance with Tier Info
                VStack(alignment: .leading, spacing: 4) {
                    // Big rolling number
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(points)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText)
                            .contentTransition(.numericText(value: Double(points)))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: points)

                        Text("pts")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.secondaryText)
                    }

                    // Cash equivalent
                    Text("≈ \(String(format: "$%.2f", cashEquivalent)) value")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.secondaryText)

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
                            .fill(Theme.primaryText.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.primaryText)
                    }
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.9))
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 12)

            // Streak & Stats Carousel
            StreakStatsCarousel(
                streakDays: 7,
                thisWeek: 240,
                toNextTier: pointsToNextTier
            )
            .padding(.bottom, 12)
            .background(
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            Theme.purple.opacity(0.08),
                            Theme.accent.opacity(0.05),
                            Theme.background
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Decorative elements
                    GeometryReader { geometry in
                        Circle()
                            .fill(Theme.purple.opacity(0.08))
                            .frame(width: 100, height: 100)
                            .offset(x: geometry.size.width - 60, y: -30)

                        Circle()
                            .fill(Theme.accent.opacity(0.06))
                            .frame(width: 60, height: 60)
                            .offset(x: geometry.size.width - 40, y: 50)
                    }

                    // Bottom border
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.purple.opacity(0.2), Theme.accent.opacity(0.15), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                    }
                }
            )
        }
    }
}

// MARK: - Streak & Stats Carousel

struct StreakStatsCarousel: View {
    let streakDays: Int
    let thisWeek: Int
    let toNextTier: Int

    @State private var currentIndex: Int = 0

    // Mock weekly progress (last 7 days, ordered Monday to Sunday, most recent = end)
    private let weekDays = ["M", "T", "W", "T", "F", "S", "S"]
    private let weekProgress = [false, false, false, true, true, true, true] // 4-day streak (Thu-Sun)

    // Mock badges
    private let badges = [3, 7, 14, 30, 60]

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
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.9))

            // Content
            TabView(selection: $currentIndex) {
                // Slide 1: Weekly Progress
                WeeklyProgressSlide(days: weekDays, progress: weekProgress)
                    .tag(0)

                // Slide 2: My Badges
                MyBadgesSlide(badges: badges)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 60)

            // Right Arrow
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentIndex = currentIndex == 0 ? 1 : 0
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.9))
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Weekly Progress Slide

struct WeeklyProgressSlide: View {
    let days: [String]
    let progress: [Bool]

    @State private var animatedChecks: [Bool] = Array(repeating: false, count: 7)

    private var streakCount: Int {
        // Count consecutive true values from the end
        var count = 0
        for i in stride(from: progress.count - 1, through: 0, by: -1) {
            if progress[i] {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    private var streakColor: Color {
        switch streakCount {
        case 4...Int.max: return Theme.streak   // Hot streak - Green
        case 2...3: return Theme.info           // Building - Blue
        default: return Theme.secondaryText     // No streak - Gray
        }
    }

    private var streakIcon: String {
        switch streakCount {
        case 4...Int.max: return "flame.fill"
        case 2...3: return "bolt.fill"
        default: return "circle.dotted"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left side: Streak Count
            VStack(spacing: 2) {
                Text("\(streakCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(streakColor)

                Text("Day Streak")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(streakColor)
            }

            // Right side: Weekly Progress
            VStack(spacing: 4) {
                // Title
                Text("Weekly Progress")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.secondaryText)

                // Days row
                HStack(spacing: 4) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        VStack(spacing: 2) {
                            Text(day)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Theme.secondaryText)
                                .frame(width: 12)

                            ZStack {
                                Circle()
                                    .fill(progress[index] ? Theme.accent : Theme.secondaryText.opacity(0.2))
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
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(streakColor)
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
    let badges: [Int]

    var body: some View {
        VStack(spacing: 8) {
            // Title
            Text("My Badges")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.secondaryText)

            // Badges row
            HStack(spacing: 8) {
                ForEach(Array(badges.enumerated()), id: \.offset) { index, count in
                    BadgeHexagon(count: count, isEarned: index < 2)
                }
            }
        }
    }
}

// MARK: - Badge Hexagon

struct BadgeHexagon: View {
    let count: Int
    let isEarned: Bool

    var body: some View {
        ZStack {
            // Hexagon shape (using SF Symbol)
            Image(systemName: "hexagon.fill")
                .font(.system(size: 32))
                .foregroundColor(isEarned ? badgeColor : Color.gray.opacity(0.3))

            // Count
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var badgeColor: Color {
        switch count {
        case 3: return Color(hex: "#E57373") // Light red
        case 7: return Color(hex: "#F06292") // Pink
        case 14: return Color(hex: "#BA68C8") // Purple
        case 30: return Color(hex: "#64B5F6") // Blue
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

#Preview {
    VStack {
        WalletHeaderView(
            points: 1450,
            cashEquivalent: 14.50,
            onHistoryTapped: {}
        )

        Spacer()
    }
    .background(Theme.background)
}

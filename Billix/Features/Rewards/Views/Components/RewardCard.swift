//
//  RewardCard.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Individual reward/gift card with realistic brand card appearance
//

import SwiftUI

enum RewardCardStyle {
    case carousel  // Horizontal scroll style (compact)
    case grid      // Grid view style (larger)
}

struct RewardCard: View {
    let reward: Reward
    let userPoints: Int
    var style: RewardCardStyle = .carousel
    let onTap: () -> Void

    private var progress: Double {
        min(Double(userPoints) / Double(reward.pointsCost), 1.0)
    }

    private var pointsToGo: Int {
        max(reward.pointsCost - userPoints, 0)
    }

    private var canAfford: Bool {
        userPoints >= reward.pointsCost
    }

    private var accentColor: Color {
        Color(hex: reward.accentColor)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Gift Card Visual (top portion - looks like actual card)
                giftCardVisual
                    .frame(height: style == .carousel ? 100 : 120)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 14,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 14
                        )
                    )

                // Info section (bottom portion - white)
                VStack(alignment: .leading, spacing: 6) {
                    // Brand name
                    Text(reward.brand ?? reward.type.rawValue)
                        .font(.system(size: style == .carousel ? 13 : 14, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)
                        .lineLimit(1)

                    // Progress bar
                    GoalProgressBar(
                        progress: progress,
                        accentColor: accentColor
                    )

                    // Points info
                    HStack {
                        if canAfford {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.billixMoneyGreen)
                        }

                        Text(canAfford ? "Ready" : "\(pointsToGo) pts to go")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(canAfford ? .billixMoneyGreen : .billixMediumGreen)

                        Spacer()

                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.billixArcadeGold)

                            Text("\(reward.pointsCost)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.billixDarkGreen)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
            }
            .frame(width: style == .carousel ? 160 : nil)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(canAfford ? accentColor.opacity(0.4) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
    }

    // MARK: - Gift Card Visual (Brand-specific design)

    @ViewBuilder
    private var giftCardVisual: some View {
        switch reward.brand?.lowercased() {
        case "amazon":
            AmazonGiftCardVisual(value: reward.formattedValue)
        case "starbucks":
            StarbucksGiftCardVisual(value: reward.formattedValue)
        case "target":
            TargetGiftCardVisual(value: reward.formattedValue)
        case "billix":
            BillixGiftCardVisual(value: reward.formattedValue)
        case "doordash":
            DoorDashGiftCardVisual(value: reward.formattedValue)
        case "uber":
            UberGiftCardVisual(value: reward.formattedValue)
        case "netflix":
            NetflixGiftCardVisual(value: reward.formattedValue)
        case "spotify":
            SpotifyGiftCardVisual(value: reward.formattedValue)
        default:
            GenericGiftCardVisual(
                value: reward.formattedValue,
                color: accentColor,
                type: reward.type
            )
        }
    }
}

// MARK: - Goal Progress Bar

struct GoalProgressBar: View {
    let progress: Double
    let accentColor: Color

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.15))

                // Progress fill with gradient
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.6),
                                accentColor
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedProgress)
            }
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Brand Icon Components

struct AmazonBrandIcon: View {
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            // Arrow/smile shape
            Circle()
                .fill(color.opacity(0.15))

            VStack(spacing: 2) {
                // "a" letterform suggestion
                Text("a")
                    .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                    .foregroundColor(color)

                // Smile/arrow underneath
                AmazonSmileShape()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: size * 0.5, height: size * 0.15)
            }
        }
    }
}

struct AmazonSmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

struct StarbucksBrandIcon: View {
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            // Circular background
            Circle()
                .fill(color)

            // Inner circle
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: size * 0.75, height: size * 0.75)

            // Star in center
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.35))
                .foregroundColor(.white)
        }
    }
}

struct TargetBrandIcon: View {
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .fill(color)

            // White ring
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.7, height: size * 0.7)

            // Inner red circle
            Circle()
                .fill(color)
                .frame(width: size * 0.4, height: size * 0.4)
        }
    }
}

struct BillixBrandIcon: View {
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            // Coin shape
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Inner circle detail
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: size * 0.7, height: size * 0.7)

            // Dollar sign
            Text("$")
                .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

struct GenericRewardIcon: View {
    let size: CGFloat
    let color: Color
    let type: RewardType

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))

            Image(systemName: iconName)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundColor(color)
        }
    }

    private var iconName: String {
        switch type {
        case .billCredit:
            return "creditcard.fill"
        case .giftCard:
            return "gift.fill"
        case .digitalGood:
            return "sparkles"
        }
    }
}

// MARK: - Preview

#Preview("Carousel Style") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        HStack(spacing: 14) {
            RewardCard(
                reward: Reward.previewRewards[0],
                userPoints: 250,
                style: .carousel,
                onTap: {}
            )

            RewardCard(
                reward: Reward.previewRewards[1],
                userPoints: 600,
                style: .carousel,
                onTap: {}
            )
        }
        .padding()
    }
}

#Preview("Grid Style") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(Reward.previewRewards.prefix(4)) { reward in
                RewardCard(
                    reward: reward,
                    userPoints: 450,
                    style: .grid,
                    onTap: {}
                )
            }
        }
        .padding()
    }
}

//
//  TierProgressRing.swift
//  Billix
//
//  Circular progress ring showing tier advancement
//  Displays around the star icon in wallet header
//

import SwiftUI

struct TierProgressRing: View {
    let currentTier: RewardsTier
    let progress: Double  // 0.0 to 1.0
    let showSparkles: Bool

    @State private var animatedProgress: Double = 0.0
    @State private var sparkleOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Background ring (gray)
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)

            // Progress ring
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

            // Sparkles at progress point (when showSparkles is true)
            if showSparkles {
                Circle()
                    .fill(tierColor)
                    .frame(width: 8, height: 8)
                    .offset(x: 26)  // radius of the circle
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
        case .bronze:
            return .billixBronzeTier
        case .silver:
            return .billixSilverTier
        case .gold:
            return .billixGoldTier
        case .platinum:
            return .billixPlatinumTier
        }
    }

    private var tierGradientColors: [Color] {
        switch currentTier {
        case .bronze:
            return [Color.billixBronzeTier, Color.billixBronzeTier.opacity(0.7)]
        case .silver:
            return [Color.billixSilverTier, Color.billixSilverTier.opacity(0.7)]
        case .gold:
            return [Color.billixGoldTier, Color.billixPrizeOrange]
        case .platinum:
            return [Color.billixPlatinumTier, Color.billixSilverTier]
        }
    }
}

// MARK: - Preview

#Preview("Bronze - 45% Progress") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack(spacing: 30) {
            ZStack {
                // Star icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.billixArcadeGold, Color.billixPrizeOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: "star.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                TierProgressRing(currentTier: .bronze, progress: 0.45, showSparkles: false)
                    .frame(width: 60, height: 60)
            }

            Text("Bronze: 450/1000 pts to Silver")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.billixMediumGreen)
        }
    }
}

#Preview("Gold - With Sparkles") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.billixArcadeGold, Color.billixPrizeOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: "star.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                TierProgressRing(currentTier: .gold, progress: 0.75, showSparkles: true)
                    .frame(width: 60, height: 60)
            }

            Text("Gold: 7,500/10,000 pts to Platinum")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.billixMediumGreen)
        }
    }
}

//
//  TierUpCelebrationView.swift
//  Billix
//
//  Created by Claude Code
//  Full-screen celebration modal when user unlocks a new tier
//

import SwiftUI

struct TierUpCelebrationView: View {
    @Binding var isPresented: Bool
    let newTier: RewardsTier
    let bonusPoints: Int
    let onExploreShop: () -> Void

    @State private var showConfetti = false
    @State private var badgeScale: CGFloat = 0.3
    @State private var badgeRotation: Double = -180
    @State private var showContent = false
    @State private var benefitsOpacity: Double = 0

    var tierEmoji: String {
        switch newTier {
        case .bronze: return "🥉"
        case .silver: return "🥈"
        case .gold: return "🥇"
        case .platinum: return "💎"
        }
    }

    var tierBenefits: [String] {
        switch newTier {
        case .bronze:
            return ["Earn points from games", "Daily rewards", "Leaderboard access"]
        case .silver:
            return ["Access Rewards Shop", "+10% bonus earnings", "Silver badge", "Weekly giveaway entry"]
        case .gold:
            return ["Exclusive gold rewards", "+15% bonus earnings", "2x giveaway entries", "Priority support"]
        case .platinum:
            return ["Premium rewards", "+20% bonus earnings", "3x giveaway entries", "VIP support", "Early access"]
        }
    }

    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissView()
                }

            // Confetti
            if showConfetti {
                ConfettiView(isActive: true, type: .celebration)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Main content
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    // Badge animation
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        newTier.color.opacity(0.3),
                                        newTier.color.opacity(0.1),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .blur(radius: 10)

                        // Badge circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [newTier.color, newTier.color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: newTier.color.opacity(0.5), radius: 20)

                        // Tier emoji
                        Text(tierEmoji)
                            .font(.system(size: 60))
                    }
                    .scaleEffect(badgeScale)
                    .rotationEffect(.degrees(badgeRotation))

                    if showContent {
                        VStack(spacing: 16) {
                            // Title
                            VStack(spacing: 8) {
                                Text("TIER UP!")
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundColor(.white)
                                    .tracking(1)

                                Text("You reached \(newTier.rawValue) Tier!")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            // Bonus points
                            if bonusPoints > 0 {
                                HStack(spacing: 8) {
                                    Image(systemName: "gift.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.billixArcadeGold)

                                    Text("+\(bonusPoints) Bonus Points!")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.billixArcadeGold)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.billixArcadeGold.opacity(0.2))
                                )
                            }

                            // Benefits
                            VStack(alignment: .leading, spacing: 12) {
                                Text("What you unlocked:")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))

                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(Array(tierBenefits.enumerated()), id: \.offset) { index, benefit in
                                        HStack(spacing: 10) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(newTier.color)

                                            Text(benefit)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        .opacity(benefitsOpacity)
                                        .animation(
                                            .easeOut(duration: 0.3).delay(Double(index) * 0.1),
                                            value: benefitsOpacity
                                        )
                                    }
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.15))
                            )

                            // CTAs
                            VStack(spacing: 12) {
                                // Primary CTA
                                Button(action: {
                                    onExploreShop()
                                    dismissView()
                                }) {
                                    Text("Explore Rewards Shop")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.billixDarkGreen)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                        )
                                }

                                // Secondary CTA
                                Button(action: {
                                    dismissView()
                                }) {
                                    Text("Maybe Later")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .transition(.opacity)
                    }
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            newTier.color.opacity(0.95),
                            newTier.color.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32))
                .shadow(color: .black.opacity(0.3), radius: 30)

                Spacer()
                    .frame(height: 0)
            }
        }
        .onAppear {
            performAnimations()
        }
    }

    func performAnimations() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Start confetti
        withAnimation {
            showConfetti = true
        }

        // Badge animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            badgeScale = 1.0
            badgeRotation = 0
        }

        // Show content after badge animation
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }

            // Stagger benefits
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                benefitsOpacity = 1.0
            }
        }
    }

    func dismissView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

// MARK: - Preview

#Preview("Silver Tier Unlock") {
    TierUpCelebrationView(
        isPresented: .constant(true),
        newTier: .silver,
        bonusPoints: 500,
        onExploreShop: {
        }
    )
}

#Preview("Gold Tier Unlock") {
    TierUpCelebrationView(
        isPresented: .constant(true),
        newTier: .gold,
        bonusPoints: 1000,
        onExploreShop: {
        }
    )
}

#Preview("Platinum Tier Unlock") {
    TierUpCelebrationView(
        isPresented: .constant(true),
        newTier: .platinum,
        bonusPoints: 2000,
        onExploreShop: {
        }
    )
}

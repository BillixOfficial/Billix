//
//  TierProgressView.swift
//  Billix
//
//  Created by Claude Code
//  Full-screen tier journey visualization showing all tiers and benefits
//

import SwiftUI

struct TierProgressView: View {
    @Environment(\.dismiss) private var dismiss
    let currentPoints: Int // Hardcoded for now, will come from viewModel later
    let currentTier: RewardsTier // Hardcoded for now

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Your Tier Journey")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.billixDarkGreen)

                        Text("Unlock exclusive benefits as you progress")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.billixMediumGreen)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Current points display
                    VStack(spacing: 4) {
                        Text("Your Points")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        Text("\(currentPoints)")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.billixMoneyGreen)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.04), radius: 8)
                    )
                    .padding(.horizontal, 20)

                    // Tier cards
                    VStack(spacing: 20) {
                        TierCard(
                            tier: .bronze,
                            currentTier: currentTier,
                            currentPoints: currentPoints
                        )

                        TierCard(
                            tier: .silver,
                            currentTier: currentTier,
                            currentPoints: currentPoints
                        )

                        TierCard(
                            tier: .gold,
                            currentTier: currentTier,
                            currentPoints: currentPoints
                        )

                        TierCard(
                            tier: .platinum,
                            currentTier: currentTier,
                            currentPoints: currentPoints
                        )
                    }
                    .padding(.horizontal, 20)

                    // CTA
                    VStack(spacing: 16) {
                        Text("Keep earning to unlock more rewards!")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Earn More Points")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.billixMoneyGreen)
                                )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(Color.billixLightGreen.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.billixMediumGreen)
                    }
                }
            }
        }
    }
}

// MARK: - Tier Card Component

struct TierCard: View {
    let tier: RewardsTier
    let currentTier: RewardsTier
    let currentPoints: Int

    var isUnlocked: Bool {
        currentPoints >= tier.pointsRange.lowerBound
    }

    var isCurrent: Bool {
        tier == currentTier
    }

    var progress: Double {
        guard isCurrent, let nextTier = tier.nextTier else { return 1.0 }

        let currentMin = Double(tier.pointsRange.lowerBound)
        let nextMin = Double(nextTier.pointsRange.lowerBound)
        let current = Double(currentPoints)

        return (current - currentMin) / (nextMin - currentMin)
    }

    var pointsToUnlock: Int {
        max(tier.pointsRange.lowerBound - currentPoints, 0)
    }

    var tierBenefits: [String] {
        switch tier {
        case .bronze:
            return [
                "Earn points from games",
                "Daily check-in rewards",
                "Access to leaderboard"
            ]
        case .silver:
            return [
                "🔓 Access Rewards Shop",
                "+10% bonus on all earnings",
                "Silver tier badge",
                "Weekly giveaway entry"
            ]
        case .gold:
            return [
                "🔓 Exclusive gold rewards",
                "+15% bonus on all earnings",
                "Gold tier badge",
                "2x weekly giveaway entries"
            ]
        case .platinum:
            return [
                "🔓 Premium rewards",
                "+20% bonus on all earnings",
                "Platinum tier badge",
                "3x weekly giveaway entries",
                "VIP support"
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                // Tier icon/badge
                ZStack {
                    Circle()
                        .fill(isUnlocked ? tier.color : Color.billixMediumGreen.opacity(0.2))
                        .frame(width: 48, height: 48)

                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.billixMediumGreen)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tier.rawValue)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isUnlocked ? .billixDarkGreen : .billixMediumGreen)

                        if isCurrent {
                            Text("CURRENT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(tier.color)
                                )
                        }
                    }

                    Text("\(tier.pointsRange.lowerBound)+ points")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }

                Spacer()
            }

            // Progress bar (only for current tier)
            if isCurrent, tier != .platinum {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Progress")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.billixMediumGreen.opacity(0.15))
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [tier.color, tier.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.85 * progress, height: 10)
                    }

                    if let nextTier = tier.nextTier {
                        Text("\(currentPoints) / \(nextTier.pointsRange.lowerBound) pts to \(nextTier.rawValue)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                    }
                }
            }

            // Locked state message
            if !isUnlocked && pointsToUnlock > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.billixMoneyGreen)

                    Text("Earn \(pointsToUnlock) more points to unlock")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.billixMoneyGreen.opacity(0.1))
                )
            }

            // Benefits list
            VStack(alignment: .leading, spacing: 10) {
                ForEach(tierBenefits, id: \.self) { benefit in
                    HStack(spacing: 10) {
                        Image(systemName: isUnlocked ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isUnlocked ? tier.color : .billixMediumGreen.opacity(0.4))

                        Text(benefit)
                            .font(.system(size: 14, weight: isUnlocked ? .medium : .regular))
                            .foregroundColor(isUnlocked ? .billixDarkGreen : .billixMediumGreen.opacity(0.7))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(isCurrent ? 0.12 : 0.04), radius: isCurrent ? 12 : 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCurrent ? tier.color : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isCurrent ? 1.02 : 1.0)
    }
}

// MARK: - Preview

#Preview("Bronze Tier (1,450 pts)") {
    TierProgressView(currentPoints: 1450, currentTier: .bronze)
}

#Preview("Silver Tier (12,000 pts)") {
    TierProgressView(currentPoints: 12000, currentTier: .silver)
}

#Preview("Gold Tier (45,000 pts)") {
    TierProgressView(currentPoints: 45000, currentTier: .gold)
}

#Preview("Platinum Tier (150,000 pts)") {
    TierProgressView(currentPoints: 150000, currentTier: .platinum)
}

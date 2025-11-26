//
//  RewardMarketplace.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Zone C: Rewards marketplace with horizontal carousel and View All
//

import SwiftUI

struct RewardMarketplace: View {
    let rewards: [Reward]
    let userPoints: Int
    let onRewardTapped: (Reward) -> Void
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            HStack {
                Text("Redeem Your Points")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                // Decorative dot (consistent with app pattern)
                Circle()
                    .fill(Color.billixArcadeGold)
                    .frame(width: 8, height: 8)

                Spacer()

                // View All button
                Button(action: onViewAll) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.billixChartBlue)
                }
            }
            .padding(.horizontal, 20)

            // Horizontal scroll carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(rewards) { reward in
                        RewardCard(
                            reward: reward,
                            userPoints: userPoints,
                            style: .carousel,
                            onTap: { onRewardTapped(reward) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

// MARK: - Empty Marketplace State

struct EmptyMarketplaceCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gift")
                .font(.system(size: 32))
                .foregroundColor(.billixMediumGreen)

            Text("Rewards coming soon")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.billixMediumGreen)
        }
        .frame(width: 160, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack {
            RewardMarketplace(
                rewards: Reward.previewRewards,
                userPoints: 450,
                onRewardTapped: { _ in },
                onViewAll: {}
            )

            Spacer()
        }
        .padding(.top, 20)
    }
}

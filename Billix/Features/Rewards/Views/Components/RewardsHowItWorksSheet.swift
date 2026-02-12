//
//  RewardsHowItWorksSheet.swift
//  Billix
//
//  Created by Claude Code
//  Explains how the Rewards Hub works
//

import SwiftUI

struct RewardsHowItWorksSheet: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image("billix_logo_new")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)

                        Text("How Rewards Hub Works")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.billixDarkGreen)

                        Text("Earn points, climb tiers, and get rewarded for managing your bills")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Divider()
                        .padding(.horizontal)

                    // Earn Points Section
                    FeatureSection(
                        icon: "star.circle.fill",
                        iconColor: .billixArcadeGold,
                        title: "Earn Points",
                        description: "Get rewarded for every bill you upload and manage in Billix",
                        items: [
                            "Upload a bill: Earn points instantly",
                            "Complete daily challenges: Build streaks",
                            "Play Price Guessr: Test your knowledge and win big"
                        ]
                    )

                    Divider()
                        .padding(.horizontal)

                    // Tier System Section
                    FeatureSection(
                        icon: "medal.fill",
                        iconColor: .billixMoneyGreen,
                        title: "Climb Tiers",
                        description: "As you earn more points, you unlock higher tiers with better rewards",
                        items: [
                            "Bronze → Silver → Gold → Platinum",
                            "Higher tiers = better rewards",
                            "Track your progress in the wallet header"
                        ]
                    )

                    Divider()
                        .padding(.horizontal)

                    // Redeem Rewards Section
                    FeatureSection(
                        icon: "gift.fill",
                        iconColor: .billixPrizeOrange,
                        title: "Redeem Rewards",
                        description: "Use your points to unlock exclusive rewards in the Marketplace",
                        items: [
                            "Gift cards from top brands",
                            "Premium Billix features",
                            "Special badges and achievements"
                        ]
                    )

                    Divider()
                        .padding(.horizontal)

                    // Price Guessr Section
                    FeatureSection(
                        icon: "map.fill",
                        iconColor: .blue,
                        title: "Price Guessr Challenge",
                        description: "Test your knowledge of prices around the world",
                        items: [
                            "Guess locations based on landmarks",
                            "Estimate prices for common items",
                            "Health bar - answer carefully to survive!"
                        ]
                    )

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

// MARK: - Feature Section Component

struct FeatureSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(iconColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Items list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.billixMoneyGreen)
                            .offset(y: 2)

                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 44)
        }
        .padding(.horizontal)
    }
}

struct RewardsHowItWorksSheet_Previews: PreviewProvider {
    static var previews: some View {
        RewardsHowItWorksSheet()
    }
}

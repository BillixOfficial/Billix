//
//  RewardMarketplace.swift
//  Billix
//
//  Created by Claude Code
//  4-zone rewards marketplace following industry UI/UX best practices
//  Zone 1: Featured Gift Card Hero (highest visual priority)
//  Zone 2: Game Boosts Grid (2-column IAP style)
//  Zone 3: Virtual Goods Carousel (customization items)
//  Zone 4: Weekly Giveaway Card (standalone call-to-action)
//

import SwiftUI

struct RewardMarketplace: View {
    let rewards: [Reward]
    let userPoints: Int
    let canAccessShop: Bool
    let currentTier: RewardsTier
    let onRewardTapped: (Reward) -> Void
    let onStartDonationRequest: () -> Void
    let onViewAllGiftCards: () -> Void
    let onViewAllGameBoosts: () -> Void
    let onViewAllVirtualGoods: () -> Void

    // Filter rewards by type for different zones
    var giftCardRewards: [Reward] {
        rewards.filter { $0.category == .giftCard }
    }

    var gameBoosts: [Reward] {
        rewards.filter { $0.type == .digitalGood && $0.category == .virtualGoods }
    }

    var virtualGoods: [Reward] {
        rewards.filter { $0.type == .customization && $0.category == .virtualGoods }
    }

    var giveawayEntries: [Reward] {
        rewards.filter { $0.category == .giveaway }
    }

    // Featured card (highest value gift card)
    var featuredGiftCard: Reward? {
        giftCardRewards.max(by: { ($0.dollarValue ?? 0) < ($1.dollarValue ?? 0) })
    }

    var body: some View {
        // Shop is always accessible to all users (canAccessShop always true)
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                        // ZONE 1: Weekly Giveaway Card (highest priority)
                        WeeklyGiveawayCard(
                            userEntries: 5,  // TODO: Get from user data
                            totalEntries: 1247,  // TODO: Get from backend
                            currentTier: currentTier,
                            onBuyEntries: {
                                // Buy entry with points
                                if let entry = giveawayEntries.first {
                                    onRewardTapped(entry)
                                }
                            },
                            onHowToEarn: {
                                // Show info modal
                            }
                        )
                        .padding(.top, 12)

                        // Gift Cards Carousel
                        if !giftCardRewards.isEmpty {
                            GiftCardsCarousel(
                                giftCards: giftCardRewards,
                                userPoints: userPoints,
                                onViewAll: onViewAllGiftCards,
                                onCardTapped: onRewardTapped
                            )
                        }

                        // GIVE BACK SECTION: Custom Charity Donation
                        VStack(alignment: .leading, spacing: 20) {
                            // Section header
                            VStack(alignment: .leading, spacing: 6) {
                                Text("GIVE BACK")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "#0D9488")) // Teal
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                Text("Turn your points into real-world impact")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.billixDarkGreen)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                            // Single "Golden Ticket" card
                            CustomDonationCard(
                                onStartRequest: onStartDonationRequest
                            )
                            .padding(.horizontal, 20)
                        }

                        // Empty state if no rewards at all
                        if giftCardRewards.isEmpty {
                            EmptyMarketplaceState()
                                .padding(.vertical, 40)
                        }

                        // Bottom spacer for better scroll behavior
                        Spacer(minLength: 100)
                    }
                    .padding(.bottom, 20)
                }
    }
}

// MARK: - Empty Marketplace State

struct EmptyMarketplaceState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift.fill")
                .font(.system(size: 48))
                .foregroundColor(.billixMediumGreen.opacity(0.5))

            VStack(spacing: 4) {
                Text("Rewards Coming Soon")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Text("Check back later for new rewards")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.billixMediumGreen)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#Preview("Unlocked Shop - All Zones") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        RewardMarketplace(
            rewards: Reward.previewRewardsWithCategories,
            userPoints: 12000,
            canAccessShop: true,
            currentTier: .silver,
            onRewardTapped: { _ in },
            onStartDonationRequest: {},
            onViewAllGiftCards: {},
            onViewAllGameBoosts: {},
            onViewAllVirtualGoods: {}
        )
    }
}

#Preview("Locked Shop - Bronze Tier") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        RewardMarketplace(
            rewards: Reward.previewRewardsWithCategories,
            userPoints: 3500,
            canAccessShop: false,
            currentTier: .bronze,
            onRewardTapped: { _ in },
            onStartDonationRequest: {},
            onViewAllGiftCards: {},
            onViewAllGameBoosts: {},
            onViewAllVirtualGoods: {}
        )
    }
}

#Preview("Empty Marketplace") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        RewardMarketplace(
            rewards: [],
            userPoints: 12000,
            canAccessShop: true,
            currentTier: .silver,
            onRewardTapped: { _ in },
            onStartDonationRequest: {},
            onViewAllGiftCards: {},
            onViewAllGameBoosts: {},
            onViewAllVirtualGoods: {}
        )
    }
}

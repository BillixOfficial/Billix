//
//  GiftCardsCarousel.swift
//  Billix
//
//  Created by Claude Code on 12/2/25.
//  Horizontal carousel for browsing gift card rewards
//

import SwiftUI

struct GiftCardsCarousel: View {
    let giftCards: [Reward]
    let userPoints: Int
    let onViewAll: () -> Void
    let onCardTapped: (Reward) -> Void

    // Group rewards by brand and show one card per brand
    private var displayCards: [Reward] {
        // Featured brands first: target, kroger, walmart
        let featuredBrands = ["target", "kroger", "walmart"]

        // Group by brandGroup (or brand if no brandGroup)
        let groupedByBrand = Dictionary(grouping: giftCards) { card in
            card.brandGroup ?? card.brand ?? ""
        }

        var result: [Reward] = []

        // Add featured brands first
        for brand in featuredBrands {
            if let rewards = groupedByBrand[brand], let first = rewards.first {
                result.append(first)
            }
        }

        // Add other brands (up to 6 total)
        for (brand, rewards) in groupedByBrand where !featuredBrands.contains(brand) {
            if let first = rewards.first, result.count < 6 {
                result.append(first)
            }
        }

        return Array(result.prefix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            VStack(alignment: .leading, spacing: 4) {
                Text("FEATURED REWARDS")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text("Gift Cards")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.billixDarkGreen)
            }
            .padding(.horizontal, 20)

            // Horizontal Scroll - LazyHStack for deferred rendering
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(displayCards) { card in
                        RewardCard(
                            reward: card,
                            userPoints: userPoints,
                            style: .carousel,
                            onTap: { onCardTapped(card) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        ScrollView {
            GiftCardsCarousel(
                giftCards: [
                    Reward(
                        id: UUID(),
                        type: .giftCard,
                        category: .giftCard,
                        title: "$5 Target",
                        description: "Target Gift Card",
                        pointsCost: 10000,
                        brand: "Target",
                        brandGroup: "target",
                        dollarValue: 5.0,
                        iconName: "target",
                        accentColor: "#CC0000"
                    ),
                    Reward(
                        id: UUID(),
                        type: .giftCard,
                        category: .giftCard,
                        title: "$5 Kroger",
                        description: "Kroger Gift Card",
                        pointsCost: 10000,
                        brand: "Kroger",
                        brandGroup: "kroger",
                        dollarValue: 5.0,
                        iconName: "cart.fill",
                        accentColor: "#0033A0"
                    ),
                    Reward(
                        id: UUID(),
                        type: .giftCard,
                        category: .giftCard,
                        title: "$5 Walmart",
                        description: "Walmart Gift Card",
                        pointsCost: 10000,
                        brand: "Walmart",
                        brandGroup: "walmart",
                        dollarValue: 5.0,
                        iconName: "bag.fill",
                        accentColor: "#0071CE"
                    )
                ],
                userPoints: 750,
                onViewAll: {},
                onCardTapped: { _ in }
            )
            .padding(.top, 20)
        }
    }
}

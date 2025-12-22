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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
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

                Spacer()

                // View All button
                Button(action: onViewAll) {
                    HStack(spacing: 6) {
                        Text("View All")
                            .font(.system(size: 15, weight: .semibold))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.billixMoneyGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.billixMoneyGreen.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 20)

            // Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(giftCards.prefix(6)) { card in
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
                        title: "$5 Amazon",
                        description: "Amazon Gift Card",
                        pointsCost: 500,
                        brand: "Amazon",
                        dollarValue: 5.0,
                        iconName: "gift.fill",
                        accentColor: "#FF9900"
                    ),
                    Reward(
                        id: UUID(),
                        type: .giftCard,
                        category: .giftCard,
                        title: "$10 Starbucks",
                        description: "Starbucks Gift Card",
                        pointsCost: 1000,
                        brand: "Starbucks",
                        dollarValue: 10.0,
                        iconName: "cup.and.saucer.fill",
                        accentColor: "#00704A"
                    ),
                    Reward(
                        id: UUID(),
                        type: .giftCard,
                        category: .giftCard,
                        title: "$25 Target",
                        description: "Target Gift Card",
                        pointsCost: 2500,
                        brand: "Target",
                        dollarValue: 25.0,
                        iconName: "target",
                        accentColor: "#CC0000"
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

//
//  GameBoostsCarousel.swift
//  Billix
//
//  Created by Claude Code
//  Horizontal carousel showing 3 game boosts with "View All" CTA
//  Similar to Upload Hub's recent uploads presentation
//

import SwiftUI

struct GameBoostsCarousel: View {
    let boosts: [Reward]
    let userPoints: Int
    let onBoostTapped: (Reward) -> Void
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with "View All"
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Power-Ups")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text("Game Boosts")
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

            // Horizontal scroll of boosts - LazyHStack for deferred rendering
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(boosts.prefix(6)) { boost in
                        GameBoostCard(
                            boost: boost,
                            userPoints: userPoints,
                            onTap: { onBoostTapped(boost) }
                        )
                        .frame(width: 180)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.trailing, 20) // Extra padding to prevent cutoff
            }
        }
    }
}

// MARK: - Preview

struct GameBoostsCarousel_Game_Boosts_Carousel_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        Color.billixLightGreen.ignoresSafeArea()
        
        VStack {
        GameBoostsCarousel(
        boosts: Reward.previewRewardsWithCategories.filter { $0.type == .digitalGood },
        userPoints: 5000,
        onBoostTapped: { _ in },
        onViewAll: {}
        )
        
        Spacer()
        }
        }
    }
}

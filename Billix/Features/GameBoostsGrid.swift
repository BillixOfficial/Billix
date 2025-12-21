//
//  GameBoostsGrid.swift
//  Billix
//
//  Created by Claude Code
//  In-app purchase style grid for game power-ups - 2 column layout
//

import SwiftUI

struct GameBoostsGrid: View {
    let boosts: [Reward]
    let userPoints: Int
    let onBoostTapped: (Reward) -> Void

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.billixArcadeGold.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.billixArcadeGold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Game Boosts")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.billixDarkGreen)

                    Text("Power-ups for Price Guessr")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.billixMediumGreen)
                }

                Spacer()
            }
            .padding(.horizontal, 20)

            // Grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(boosts) { boost in
                    GameBoostCard(
                        boost: boost,
                        userPoints: userPoints,
                        onTap: { onBoostTapped(boost) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Game Boost Card

struct GameBoostCard: View {
    let boost: Reward
    let userPoints: Int
    let onTap: () -> Void

    var canAfford: Bool {
        userPoints >= boost.pointsCost
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 14) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: boost.accentColor).opacity(0.2),
                                    Color(hex: boost.accentColor).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: boost.iconName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color(hex: boost.accentColor))
                }

                // Title
                Text(boost.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.billixDarkGreen)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Description
                Text(boost.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.billixMediumGreen)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Price button
                HStack(spacing: 6) {
                    Image(systemName: canAfford ? "checkmark.circle.fill" : "star.fill")
                        .font(.system(size: 13, weight: .semibold))

                    Text("\(boost.pointsCost)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(canAfford ? .white : Color(hex: boost.accentColor))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            canAfford ?
                            Color(hex: boost.accentColor) :
                            Color(hex: boost.accentColor).opacity(0.1)
                        )
                )
            }
            .padding(16)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        canAfford ? Color(hex: boost.accentColor).opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
    }
}

// MARK: - Preview

#Preview("Game Boosts Grid") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        ScrollView {
            GameBoostsGrid(
                boosts: [
                    Reward(
                        id: UUID(),
                        type: .digitalGood,
                        category: .virtualGoods,
                        title: "Extra Life",
                        description: "One more chance if you lose",
                        pointsCost: 500,
                        brand: nil,
                        dollarValue: nil,
                        iconName: "heart.fill",
                        accentColor: "#FF6B6B"
                    ),
                    Reward(
                        id: UUID(),
                        type: .digitalGood,
                        category: .virtualGoods,
                        title: "2x Multiplier",
                        description: "Double points earned",
                        pointsCost: 800,
                        brand: nil,
                        dollarValue: nil,
                        iconName: "arrow.up.circle.fill",
                        accentColor: "#4ECDC4"
                    ),
                    Reward(
                        id: UUID(),
                        type: .digitalGood,
                        category: .virtualGoods,
                        title: "Skip Question",
                        description: "Pass a difficult question",
                        pointsCost: 300,
                        brand: nil,
                        dollarValue: nil,
                        iconName: "forward.fill",
                        accentColor: "#95E1D3"
                    ),
                    Reward(
                        id: UUID(),
                        type: .digitalGood,
                        category: .virtualGoods,
                        title: "Time Freeze",
                        description: "+30 seconds on timer",
                        pointsCost: 400,
                        brand: nil,
                        dollarValue: nil,
                        iconName: "clock.fill",
                        accentColor: "#F38181"
                    ),
                    Reward(
                        id: UUID(),
                        type: .digitalGood,
                        category: .virtualGoods,
                        title: "Hint Token",
                        description: "Reveal one wrong answer",
                        pointsCost: 250,
                        brand: nil,
                        dollarValue: nil,
                        iconName: "lightbulb.fill",
                        accentColor: "#FFD93D"
                    ),
                    Reward(
                        id: UUID(),
                        type: .digitalGood,
                        category: .virtualGoods,
                        title: "Lucky Spin",
                        description: "Bonus points wheel",
                        pointsCost: 600,
                        brand: nil,
                        dollarValue: nil,
                        iconName: "star.circle.fill",
                        accentColor: "#6BCB77"
                    )
                ],
                userPoints: 550,
                onBoostTapped: { _ in }
            )
            .padding(.top, 20)
        }
    }
}

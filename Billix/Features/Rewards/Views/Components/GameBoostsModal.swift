//
//  GameBoostsModal.swift
//  Billix
//
//  Created by Claude Code
//  Full-screen modal showing all game boosts in a clean grid layout
//  Follows e-commerce best practices with filtering, sorting, and clear CTAs
//

import SwiftUI

struct GameBoostsModal: View {
    @Environment(\.dismiss) var dismiss

    let gameBoosts: [Reward]
    let userPoints: Int
    let onBoostTapped: (Reward) -> Void

    @State private var sortBy: SortOption = .pointsLowToHigh
    @State private var filterAffordable: Bool = false

    enum SortOption: String, CaseIterable {
        case pointsLowToHigh = "Points: Low to High"
        case pointsHighToLow = "Points: High to Low"
    }

    var sortedAndFilteredBoosts: [Reward] {
        var boosts = gameBoosts

        // Filter affordable only
        if filterAffordable {
            boosts = boosts.filter { userPoints >= $0.pointsCost }
        }

        // Sort
        switch sortBy {
        case .pointsLowToHigh:
            boosts.sort { $0.pointsCost < $1.pointsCost }
        case .pointsHighToLow:
            boosts.sort { $0.pointsCost > $1.pointsCost }
        }

        return boosts
    }

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.billixLightGreen.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with user points
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.billixArcadeGold)

                            Text("\(userPoints) points")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.billixDarkGreen)

                            Spacer()

                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.billixMediumGreen.opacity(0.5))
                            }
                        }

                        // Filter and sort controls
                        HStack(spacing: 12) {
                            // Affordable toggle
                            Button(action: { filterAffordable.toggle() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: filterAffordable ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 14, weight: .semibold))

                                    Text("Affordable Only")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(filterAffordable ? .billixMoneyGreen : .billixMediumGreen)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(filterAffordable ? Color.billixMoneyGreen.opacity(0.1) : Color.white)
                                )
                            }

                            Spacer()

                            // Sort menu
                            Menu {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(action: { sortBy = option }) {
                                        HStack {
                                            Text(option.rawValue)
                                            if sortBy == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.system(size: 13, weight: .semibold))

                                    Text("Sort")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.billixDarkGreen)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.billixLightGreen)

                    // Game boosts grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(sortedAndFilteredBoosts) { boost in
                                GameBoostCard(
                                    boost: boost,
                                    userPoints: userPoints,
                                    onTap: { onBoostTapped(boost) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    }

                    // Empty state
                    if sortedAndFilteredBoosts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.billixMediumGreen.opacity(0.5))

                            VStack(spacing: 4) {
                                Text(filterAffordable ? "No Affordable Boosts Yet" : "No Game Boosts Available")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.billixDarkGreen)

                                Text(filterAffordable ? "Keep earning points!" : "Check back soon")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.billixMediumGreen)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 60)
                    }
                }
            }
            .navigationTitle("Game Boosts")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

#Preview("Game Boosts Modal - Can Afford Some") {
    GameBoostsModal(
        gameBoosts: [
            Reward(
                id: UUID(),
                type: .digitalGood,
                category: .virtualGoods,
                title: "Extra Life",
                description: "One more chance",
                pointsCost: 250,
                brand: nil,
                        brandGroup: nil,                dollarValue: nil,
                iconName: "heart.fill",
                accentColor: "#FF6B6B"
            ),
            Reward(
                id: UUID(),
                type: .digitalGood,
                category: .virtualGoods,
                title: "Skip Question",
                description: "Pass any question",
                pointsCost: 300,
                brand: nil,
                        brandGroup: nil,                dollarValue: nil,
                iconName: "forward.fill",
                accentColor: "#4ECDC4"
            ),
            Reward(
                id: UUID(),
                type: .digitalGood,
                category: .virtualGoods,
                title: "Time Freeze",
                description: "Pause the timer",
                pointsCost: 350,
                brand: nil,
                        brandGroup: nil,                dollarValue: nil,
                iconName: "clock.fill",
                accentColor: "#45B7D1"
            ),
            Reward(
                id: UUID(),
                type: .digitalGood,
                category: .virtualGoods,
                title: "Hint Token",
                description: "Get a helpful hint",
                pointsCost: 200,
                brand: nil,
                        brandGroup: nil,                dollarValue: nil,
                iconName: "lightbulb.fill",
                accentColor: "#FFD93D"
            ),
            Reward(
                id: UUID(),
                type: .digitalGood,
                category: .virtualGoods,
                title: "Double Points",
                description: "2x points next game",
                pointsCost: 500,
                brand: nil,
                        brandGroup: nil,                dollarValue: nil,
                iconName: "star.fill",
                accentColor: "#FFD700"
            )
        ],
        userPoints: 400,
        onBoostTapped: { _ in }
    )
}

#Preview("Game Boosts Modal - Empty (Filtered)") {
    GameBoostsModal(
        gameBoosts: [
            Reward(
                id: UUID(),
                type: .digitalGood,
                category: .virtualGoods,
                title: "Double Points",
                description: "2x points next game",
                pointsCost: 10000,
                brand: nil,
                        brandGroup: nil,                dollarValue: nil,
                iconName: "star.fill",
                accentColor: "#FFD700"
            )
        ],
        userPoints: 500,
        onBoostTapped: { _ in }
    )
}

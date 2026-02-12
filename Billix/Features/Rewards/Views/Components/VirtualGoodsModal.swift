//
//  VirtualGoodsModal.swift
//  Billix
//
//  Created by Claude Code
//  Full-screen modal showing all virtual goods in a clean grid layout
//  Follows e-commerce best practices with filtering, sorting, and clear CTAs
//

import SwiftUI

struct VirtualGoodsModal: View {
    @Environment(\.dismiss) var dismiss

    let virtualGoods: [Reward]
    let userPoints: Int
    let onItemTapped: (Reward) -> Void

    @State private var sortBy: SortOption = .pointsLowToHigh
    @State private var filterAffordable: Bool = false

    enum SortOption: String, CaseIterable {
        case pointsLowToHigh = "Points: Low to High"
        case pointsHighToLow = "Points: High to Low"
    }

    var sortedAndFilteredGoods: [Reward] {
        var goods = virtualGoods

        // Filter affordable only
        if filterAffordable {
            goods = goods.filter { userPoints >= $0.pointsCost }
        }

        // Sort
        switch sortBy {
        case .pointsLowToHigh:
            goods.sort { $0.pointsCost < $1.pointsCost }
        case .pointsHighToLow:
            goods.sort { $0.pointsCost > $1.pointsCost }
        }

        return goods
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

                    // Virtual goods grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(sortedAndFilteredGoods) { item in
                                VirtualGoodCard(
                                    item: item,
                                    userPoints: userPoints,
                                    onTap: { onItemTapped(item) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    }

                    // Empty state
                    if sortedAndFilteredGoods.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.billixMediumGreen.opacity(0.5))

                            VStack(spacing: 4) {
                                Text(filterAffordable ? "No Affordable Items Yet" : "No Virtual Goods Available")
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
            .navigationTitle("Virtual Goods")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

#Preview("Virtual Goods Modal - Can Afford Some") {
    VirtualGoodsModal(
        virtualGoods: [
            Reward(
                id: UUID(),
                type: .customization,
                category: .virtualGoods,
                title: "Dark Mode Theme",
                description: "Unlock sleek dark interface",
                pointsCost: 200,
                brand: nil,
                dollarValue: nil,
                iconName: "moon.fill",
                accentColor: "#2C2C2E"
            ),
            Reward(
                id: UUID(),
                type: .customization,
                category: .virtualGoods,
                title: "Premium Dashboard",
                description: "Advanced analytics view",
                pointsCost: 500,
                brand: nil,
                dollarValue: nil,
                iconName: "chart.bar.fill",
                accentColor: "#52b8df"
            ),
            Reward(
                id: UUID(),
                type: .customization,
                category: .virtualGoods,
                title: "Custom Bill Colors",
                description: "Personalize categories",
                pointsCost: 300,
                brand: nil,
                dollarValue: nil,
                iconName: "paintpalette.fill",
                accentColor: "#E8A54B"
            ),
            Reward(
                id: UUID(),
                type: .customization,
                category: .virtualGoods,
                title: "Pro Icons Pack",
                description: "Premium icon collection",
                pointsCost: 400,
                brand: nil,
                dollarValue: nil,
                iconName: "star.fill",
                accentColor: "#e8b54d"
            )
        ],
        userPoints: 350,
        onItemTapped: { _ in }
    )
}

#Preview("Virtual Goods Modal - Empty (Filtered)") {
    VirtualGoodsModal(
        virtualGoods: [
            Reward(
                id: UUID(),
                type: .customization,
                category: .virtualGoods,
                title: "Premium Dashboard",
                description: "Advanced analytics view",
                pointsCost: 10000,
                brand: nil,
                dollarValue: nil,
                iconName: "chart.bar.fill",
                accentColor: "#52b8df"
            )
        ],
        userPoints: 500,
        onItemTapped: { _ in }
    )
}

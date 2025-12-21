//
//  VirtualGoodsCarousel.swift
//  Billix
//
//  Created by Claude Code
//  Horizontal carousel for unlockable themes and customization
//

import SwiftUI

struct VirtualGoodsCarousel: View {
    let virtualGoods: [Reward]
    let userPoints: Int
    let onItemTapped: (Reward) -> Void
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CUSTOMIZATION")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text("Virtual Goods")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.billixDarkGreen)
                }

                Spacer()

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

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(virtualGoods.prefix(6)) { item in
                        VirtualGoodCard(
                            item: item,
                            userPoints: userPoints,
                            onTap: { onItemTapped(item) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Virtual Good Card

struct VirtualGoodCard: View {
    let item: Reward
    let userPoints: Int
    let onTap: () -> Void

    var canAfford: Bool {
        userPoints >= item.pointsCost
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Preview area
                ZStack {
                    // Background based on item type
                    previewBackground

                    // Icon overlay
                    VStack {
                        Spacer()

                        Image(systemName: item.iconName)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 4)

                        Spacer()
                    }
                }
                .frame(height: 140)

                // Info section
                VStack(alignment: .leading, spacing: 10) {
                    // Title
                    Text(item.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.billixDarkGreen)
                        .lineLimit(1)

                    // Description
                    Text(item.description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.billixMediumGreen)
                        .lineLimit(2)
                        .frame(height: 32)

                    // Price
                    HStack(spacing: 6) {
                        Image(systemName: canAfford ? "checkmark.circle.fill" : "star.fill")
                            .font(.system(size: 12, weight: .semibold))

                        Text("\(item.pointsCost) pts")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(canAfford ? .billixMoneyGreen : .billixMediumGreen)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
            }
            .frame(width: 160)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        canAfford ? Color.billixMoneyGreen.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.96))
    }

    @ViewBuilder
    var previewBackground: some View {
        switch item.title {
        case let title where title.contains("Dark Mode"):
            LinearGradient(
                colors: [Color(hex: "#1C1C1E"), Color(hex: "#2C2C2E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case let title where title.contains("Premium"):
            LinearGradient(
                colors: [Color(hex: "#52b8df"), Color(hex: "#3A9EC9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case let title where title.contains("Color"):
            LinearGradient(
                colors: [
                    Color(hex: "#FF6B6B"),
                    Color(hex: "#4ECDC4"),
                    Color(hex: "#45B7D1"),
                    Color(hex: "#96CEB4")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        default:
            LinearGradient(
                colors: [Color.billixChartBlue, Color.billixChartBlue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Preview

#Preview("Virtual Goods Carousel") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 30) {
                VirtualGoodsCarousel(
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
                            accentColor: "#FF6B35"
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
                            accentColor: "#FFD700"
                        )
                    ],
                    userPoints: 350,
                    onItemTapped: { _ in },
                    onViewAll: {}
                )

                Spacer()
            }
            .padding(.top, 20)
        }
    }
}

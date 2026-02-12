//
//  GiftCardsModal.swift
//  Billix
//
//  Created by Claude Code
//  Full-screen modal showing all gift cards in a clean grid layout
//  Follows e-commerce best practices with filtering, sorting, and clear CTAs
//

import SwiftUI

struct GiftCardsModal: View {
    @Environment(\.dismiss) var dismiss

    let giftCards: [Reward]
    let userPoints: Int
    let onCardTapped: (Reward) -> Void

    @State private var sortBy: SortOption = .pointsLowToHigh
    @State private var filterAffordable: Bool = false

    enum SortOption: String, CaseIterable {
        case pointsLowToHigh = "Points: Low to High"
        case pointsHighToLow = "Points: High to Low"
        case valueLowToHigh = "Value: Low to High"
        case valueHighToLow = "Value: High to Low"
    }

    var sortedAndFilteredCards: [Reward] {
        var cards = giftCards

        // Filter affordable only
        if filterAffordable {
            cards = cards.filter { userPoints >= $0.pointsCost }
        }

        // Sort
        switch sortBy {
        case .pointsLowToHigh:
            cards.sort { $0.pointsCost < $1.pointsCost }
        case .pointsHighToLow:
            cards.sort { $0.pointsCost > $1.pointsCost }
        case .valueLowToHigh:
            cards.sort { ($0.dollarValue ?? 0) < ($1.dollarValue ?? 0) }
        case .valueHighToLow:
            cards.sort { ($0.dollarValue ?? 0) > ($1.dollarValue ?? 0) }
        }

        return cards
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

                    // Gift cards grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(sortedAndFilteredCards) { card in
                                GiftCardGridItem(
                                    card: card,
                                    userPoints: userPoints,
                                    onTap: { onCardTapped(card) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    }

                    // Empty state
                    if sortedAndFilteredCards.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "giftcard")
                                .font(.system(size: 48))
                                .foregroundColor(.billixMediumGreen.opacity(0.5))

                            VStack(spacing: 4) {
                                Text(filterAffordable ? "No Affordable Cards Yet" : "No Gift Cards Available")
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
            .navigationTitle("Gift Cards")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Gift Card Grid Item

struct GiftCardGridItem: View {
    let card: Reward
    let userPoints: Int
    let onTap: () -> Void

    var canAfford: Bool {
        userPoints >= card.pointsCost
    }

    var progressToCard: Double {
        min(Double(userPoints) / Double(card.pointsCost), 1.0)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Card visual with brand color
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: card.accentColor),
                            Color(hex: card.accentColor).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Decorative circle
                    GeometryReader { geo in
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 60, height: 60)
                            .offset(x: geo.size.width - 30, y: -15)
                    }

                    VStack(spacing: 12) {
                        Spacer()

                        // Icon
                        Image(systemName: card.iconName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)

                        // Value
                        if let value = card.formattedValue {
                            Text(value)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }

                        // Brand
                        if let brand = card.brand {
                            Text(brand)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
                .frame(height: 160)

                // Info section
                VStack(spacing: 10) {
                    // Points cost
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .semibold))

                        Text("\(card.pointsCost)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))

                        if canAfford {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.billixMoneyGreen)
                        }
                    }
                    .foregroundColor(canAfford ? .billixMoneyGreen : .billixMediumGreen)

                    // Progress bar (only if not affordable yet)
                    if !canAfford {
                        VStack(alignment: .leading, spacing: 4) {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.billixMediumGreen.opacity(0.15))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.billixMoneyGreen)
                                    .frame(width: 140 * progressToCard, height: 6)
                            }

                            Text("\(card.pointsCost - userPoints) more points")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.billixMediumGreen)
                        }
                    } else {
                        Text("Ready to redeem!")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.billixMoneyGreen)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        canAfford ? Color(hex: card.accentColor).opacity(0.4) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.96))
    }
}

// MARK: - Preview

struct GiftCardsModal_Gift_Cards_Modal___Can_Afford_Some_Previews: PreviewProvider {
    static var previews: some View {
        GiftCardsModal(
        giftCards: [
        Reward(
        id: UUID(),
        type: .giftCard,
        category: .giftCard,
        title: "$0.50 Starbucks Card",
        description: "Micro reward",
        pointsCost: 1000,
        brand: "Starbucks",
        brandGroup: nil,                dollarValue: 0.5,
        iconName: "cup.and.saucer.fill",
        accentColor: "#00704A"
        ),
        Reward(
        id: UUID(),
        type: .billCredit,
        category: .giftCard,
        title: "$1.00 Bill Credit",
        description: "$1 off payment",
        pointsCost: 2000,
        brand: "Billix",
        brandGroup: nil,                dollarValue: 1,
        iconName: "dollarsign.circle.fill",
        accentColor: "#5b8a6b"
        ),
        Reward(
        id: UUID(),
        type: .giftCard,
        category: .giftCard,
        title: "$2.00 Amazon Card",
        description: "Amazon.com",
        pointsCost: 4000,
        brand: "Amazon",
        brandGroup: nil,                dollarValue: 2,
        iconName: "gift.fill",
        accentColor: "#FF9900"
        ),
        Reward(
        id: UUID(),
        type: .giftCard,
        category: .giftCard,
        title: "$5.00 Target Card",
        description: "Shop at Target",
        pointsCost: 10000,
        brand: "Target",
        brandGroup: nil,                dollarValue: 5,
        iconName: "target",
        accentColor: "#CC0000"
        ),
        Reward(
        id: UUID(),
        type: .giftCard,
        category: .giftCard,
        title: "$10 Uber Eats",
        description: "Food delivery",
        pointsCost: 20000,
        brand: "Uber Eats",
        brandGroup: nil,                dollarValue: 10,
        iconName: "fork.knife",
        accentColor: "#06C167"
        ),
        Reward(
        id: UUID(),
        type: .giftCard,
        category: .giftCard,
        title: "$10 DoorDash",
        description: "Food delivery",
        pointsCost: 20000,
        brand: "DoorDash",
        brandGroup: nil,                dollarValue: 10,
        iconName: "bicycle",
        accentColor: "#FF3008"
        )
        ],
        userPoints: 5000,
        onCardTapped: { _ in }
        )
    }
}

struct GiftCardsModal_Gift_Cards_Modal___Empty__Filtered__Previews: PreviewProvider {
    static var previews: some View {
        GiftCardsModal(
        giftCards: [
        Reward(
        id: UUID(),
        type: .giftCard,
        category: .giftCard,
        title: "$10 Target Card",
        description: "Shop at Target",
        pointsCost: 20000,
        brand: "Target",
        brandGroup: nil,                dollarValue: 10,
        iconName: "target",
        accentColor: "#CC0000"
        )
        ],
        userPoints: 500,
        onCardTapped: { _ in }
        )
    }
}

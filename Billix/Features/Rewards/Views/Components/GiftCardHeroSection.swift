//
//  GiftCardHeroSection.swift
//  Billix
//
//  Created by Claude Code
//  Featured gift card hero with "View All" CTA - follows e-commerce best practices
//

import SwiftUI

struct GiftCardHeroSection: View {
    let featuredCard: Reward
    let userPoints: Int
    let onViewAll: () -> Void
    let onCardTapped: () -> Void

    @State private var shimmerOffset: CGFloat = -300

    var canAfford: Bool {
        userPoints >= featuredCard.pointsCost
    }

    var progressToCard: Double {
        min(Double(userPoints) / Double(featuredCard.pointsCost), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Featured Reward")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text("Redeem Your Points")
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

            // Hero Card
            Button(action: onCardTapped) {
                ZStack {
                    // Background gradient based on brand
                    LinearGradient(
                        colors: [
                            Color(hex: featuredCard.accentColor),
                            Color(hex: featuredCard.accentColor).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Decorative circles
                    GeometryReader { geo in
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .offset(x: geo.size.width - 60, y: -30)

                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 80, height: 80)
                            .offset(x: -20, y: geo.size.height - 40)
                    }

                    // Shimmer effect for affordable items
                    if canAfford {
                        GeometryReader { geo in
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 100)
                            .offset(x: shimmerOffset)
                            .onAppear {
                                withAnimation(
                                    .linear(duration: 2.0)
                                    .repeatForever(autoreverses: false)
                                ) {
                                    shimmerOffset = geo.size.width + 100
                                }
                            }
                        }
                        .allowsHitTesting(false)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        // Top section: Icon + Brand
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.25))
                                    .frame(width: 56, height: 56)

                                Image(systemName: featuredCard.iconName)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            // "Popular" badge
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Popular")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.billixArcadeGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                        }

                        Spacer()

                        // Bottom section: Details
                        VStack(alignment: .leading, spacing: 12) {
                            // Brand name
                            if let brand = featuredCard.brand {
                                Text(brand)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            // Value + Title
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                if let value = featuredCard.formattedValue {
                                    Text(value)
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }

                                Text("Gift Card")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            // Points cost + progress
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14, weight: .semibold))

                                    Text("\(featuredCard.pointsCost) points")
                                        .font(.system(size: 15, weight: .bold))

                                    if canAfford {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.billixArcadeGold)
                                    }
                                }
                                .foregroundColor(.white)

                                // Progress bar (only if not affordable yet)
                                if !canAfford {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white.opacity(0.3))
                                                .frame(height: 6)

                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white)
                                                .frame(width: UIScreen.main.bounds.width * 0.85 * progressToCard, height: 6)
                                        }

                                        Text("\(featuredCard.pointsCost - userPoints) more points needed")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                        }
                    }
                    .padding(24)
                }
                .frame(height: 240)
                .cornerRadius(20)
                .shadow(color: Color(hex: featuredCard.accentColor).opacity(0.3), radius: 20, x: 0, y: 8)
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

struct GiftCardHeroSection_Can_Afford_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        Color.billixLightGreen.ignoresSafeArea()
        
        VStack {
        GiftCardHeroSection(
        featuredCard: Reward(
        id: UUID(),
        type: .giftCard,
        category: .giftCard,
        title: "$5 Amazon Gift Card",
        description: "Redeemable on Amazon.com",
        pointsCost: 10000,
        brand: "Amazon",
        brandGroup: nil,
        dollarValue: 5,
        iconName: "gift.fill",
        accentColor: "#FF9900"
        ),
        userPoints: 12000,
        onViewAll: {},
        onCardTapped: {}
        )
        
        Spacer()
        }
        .padding(.top, 20)
        }
    }
}

struct GiftCardHeroSection_Cannot_Afford_Yet_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        Color.billixLightGreen.ignoresSafeArea()
        
        VStack {
        GiftCardHeroSection(
        featuredCard: Reward(
        id: UUID(),
        type: .giftCard,
        category: .giftCard,
        title: "$10 Target Gift Card",
        description: "Shop at Target",
        pointsCost: 20000,
        brand: "Target",
        brandGroup: nil,
        dollarValue: 10,
        iconName: "giftcard.fill",
        accentColor: "#CC0000"
        ),
        userPoints: 12000,
        onViewAll: {},
        onCardTapped: {}
        )
        
        Spacer()
        }
        .padding(.top, 20)
        }
    }
}

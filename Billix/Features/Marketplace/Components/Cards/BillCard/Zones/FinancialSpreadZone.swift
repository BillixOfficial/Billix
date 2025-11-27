//
//  FinancialSpreadZone.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Zone 2: Financial Spread - The Scoreboard
/// Shows the deal at a glance - "How much? How good?"
struct FinancialSpreadZone: View {
    let listing: BillListing
    let isVsMe: Bool
    let userCurrentPrice: Double? // User's current bill for comparison

    @State private var animatedSavings: Double = 0

    private var displayedSavings: Double {
        if isVsMe, let userPrice = userCurrentPrice {
            return userPrice - listing.askPrice
        }
        return listing.savingsVsMarket
    }

    private var savingsLabel: String {
        isVsMe ? "You'd save" : "Save"
    }

    private var comparisonLabel: String {
        isVsMe ? "vs Your Bill" : "vs Market Avg"
    }

    private var comparisonPrice: Double {
        if isVsMe, let userPrice = userCurrentPrice {
            return userPrice
        }
        return listing.marketAvgPrice
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Main price row
            HStack(alignment: .top) {
                // Ask price (large)
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxxs) {
                    Text(formatPrice(listing.askPrice))
                        .font(.system(size: MarketplaceTheme.Typography.hero, weight: .bold, design: .rounded))
                        .foregroundStyle(MarketplaceTheme.Colors.success)
                        .contentTransition(.numericText())

                    // Market comparison
                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        Text("vs")
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                        Text(formatPrice(comparisonPrice))
                            .strikethrough()
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                        Text(comparisonLabel)
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                }

                Spacer()

                // Grade pill + Savings
                VStack(alignment: .trailing, spacing: MarketplaceTheme.Spacing.xs) {
                    GradePill(grade: listing.grade)

                    // Savings pill (animated)
                    savingsPill
                }
            }

            Divider()
                .background(MarketplaceTheme.Colors.textTertiary.opacity(0.2))

            // True cost breakdown
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxs) {
                // True cost line
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Text("Advertised")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    Text(formatPrice(listing.askPrice))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    Text("+")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    Text(formatPrice(listing.fees))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    Text("fees =")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    Text(formatPrice(listing.trueCost))
                        .fontWeight(.semibold)
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    Text("total")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }
                .font(.system(size: MarketplaceTheme.Typography.micro))

                // Promo cliff indicator
                if let months = listing.promoDuration {
                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(MarketplaceTheme.Colors.warning)
                        Text("Locked \(months) months")
                            .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                            .foregroundStyle(MarketplaceTheme.Colors.warning)
                    }
                }
            }
        }
        .onChange(of: isVsMe) { _, _ in
            withAnimation(MarketplaceTheme.Animation.bouncy) {
                animatedSavings = displayedSavings
            }
        }
        .onAppear {
            animatedSavings = displayedSavings
        }
    }

    private var savingsPill: some View {
        HStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Text(savingsLabel)
                .font(.system(size: MarketplaceTheme.Typography.micro))
            Text(formatPrice(abs(animatedSavings)) + "/mo")
                .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                .contentTransition(.numericText())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, MarketplaceTheme.Spacing.sm)
        .padding(.vertical, MarketplaceTheme.Spacing.xxs)
        .background(
            Capsule()
                .fill(MarketplaceTheme.Colors.success)
        )
    }

    private func formatPrice(_ price: Double) -> String {
        if price < 1 {
            // For rates like $0.11/kWh
            return String(format: "$%.2f", price)
        } else if price == floor(price) {
            return String(format: "$%.0f", price)
        } else {
            return String(format: "$%.2f", price)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FinancialSpreadZone(
            listing: MockMarketplaceData.billListings[0],
            isVsMe: false,
            userCurrentPrice: 95.00
        )

        FinancialSpreadZone(
            listing: MockMarketplaceData.billListings[0],
            isVsMe: true,
            userCurrentPrice: 95.00
        )
    }
    .padding()
    .background(Color.white)
}

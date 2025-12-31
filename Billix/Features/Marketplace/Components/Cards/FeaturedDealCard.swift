//
//  FeaturedDealCard.swift
//  Billix
//
//  Featured deal card component for the Marketplace
//

import SwiftUI

struct FeaturedDealCard: View {
    let deal: FeaturedDeal
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header with provider and badge
            HStack {
                // Provider logo placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.sm)
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                        .frame(width: 40, height: 40)

                    Image(systemName: deal.categoryIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(MarketplaceTheme.Colors.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(deal.providerName)
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    Text(deal.category)
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                Spacer()

                // Featured badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text("Featured")
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [MarketplaceTheme.Colors.accent, MarketplaceTheme.Colors.accent.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }

            // Deal title
            Text(deal.title)
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                .lineLimit(2)

            // Price and savings
            HStack(alignment: .bottom, spacing: MarketplaceTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Starting at")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("$\(deal.price, specifier: "%.0f")")
                            .font(.system(size: MarketplaceTheme.Typography.title2, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        Text("/mo")
                            .font(.system(size: MarketplaceTheme.Typography.caption))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    }
                }

                Spacer()

                // Savings badge
                if let savings = deal.savingsDisplay {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12))
                        Text(savings)
                            .font(.system(size: MarketplaceTheme.Typography.caption, weight: .bold))
                    }
                    .foregroundStyle(MarketplaceTheme.Colors.success)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(MarketplaceTheme.Colors.success.opacity(0.15))
                    )
                }
            }

            // Specs row
            if !deal.specs.isEmpty {
                HStack(spacing: MarketplaceTheme.Spacing.md) {
                    ForEach(deal.specs.prefix(3), id: \.self) { spec in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(MarketplaceTheme.Colors.success)
                            Text(spec)
                                .font(.system(size: MarketplaceTheme.Typography.micro))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                        }
                    }
                }
            }

            // Unlock button
            Button(action: onUnlock) {
                HStack {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 12))
                    Text("Unlock Details")
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("\(deal.unlockCost)")
                            .font(.system(size: MarketplaceTheme.Typography.caption, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.vertical, MarketplaceTheme.Spacing.sm)
                .padding(.horizontal, MarketplaceTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(MarketplaceTheme.Colors.primary)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [MarketplaceTheme.Colors.accent.opacity(0.3), MarketplaceTheme.Colors.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: MarketplaceTheme.Shadows.medium.color,
                    radius: MarketplaceTheme.Shadows.medium.radius,
                    x: 0,
                    y: MarketplaceTheme.Shadows.medium.y
                )
        )
    }
}

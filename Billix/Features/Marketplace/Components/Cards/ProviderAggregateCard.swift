//
//  ProviderAggregateCard.swift
//  Billix
//
//  Provider aggregate and share deal CTA cards for Marketplace
//

import SwiftUI

// MARK: - Provider Aggregate Card

struct ProviderAggregateCard: View {
    let aggregate: MarketplaceAggregate
    let onCompare: () -> Void
    let onDetails: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header
            HStack {
                // Provider icon
                ZStack {
                    Circle()
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: aggregate.categoryIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(MarketplaceTheme.Colors.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(aggregate.providerName)
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    Text(aggregate.category)
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                Spacer()

                // Sample size badge
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                    Text("\(aggregate.sampleSize)")
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                }
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                )
            }

            // Price stats
            HStack(spacing: MarketplaceTheme.Spacing.lg) {
                // Average
                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("$\(aggregate.averagePrice, specifier: "%.0f")")
                        .font(.system(size: MarketplaceTheme.Typography.title3, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                }

                // Range
                VStack(alignment: .leading, spacing: 2) {
                    Text("Range")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("$\(aggregate.lowPrice, specifier: "%.0f") - $\(aggregate.highPrice, specifier: "%.0f")")
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                Spacer()

                // Trend
                if let trend = aggregate.trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12))
                        Text("\(abs(trend), specifier: "%.1f")%")
                            .font(.system(size: MarketplaceTheme.Typography.caption, weight: .bold))
                    }
                    .foregroundStyle(trend > 0 ? MarketplaceTheme.Colors.danger : MarketplaceTheme.Colors.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((trend > 0 ? MarketplaceTheme.Colors.danger : MarketplaceTheme.Colors.success).opacity(0.15))
                    )
                }
            }

            // Compare button
            Button(action: onCompare) {
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 14))
                    Text("Compare My Bill")
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                }
                .foregroundStyle(MarketplaceTheme.Colors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(MarketplaceTheme.Colors.primary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                .stroke(MarketplaceTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .shadow(
                    color: MarketplaceTheme.Shadows.low.color,
                    radius: MarketplaceTheme.Shadows.low.radius,
                    x: 0,
                    y: 2
                )
        )
    }
}

// MARK: - Share Deal CTA Card

struct ShareDealCTACard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MarketplaceTheme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [MarketplaceTheme.Colors.accent, MarketplaceTheme.Colors.accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "gift.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Share Your Deal")
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    Text("Help others & earn rewards")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
            .padding(MarketplaceTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                    .fill(MarketplaceTheme.Colors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [MarketplaceTheme.Colors.accent.opacity(0.5), MarketplaceTheme.Colors.accent.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: MarketplaceTheme.Colors.accent.opacity(0.15),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

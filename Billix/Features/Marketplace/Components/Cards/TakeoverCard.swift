//
//  TakeoverCard.swift
//  Billix
//
//  Created by Claude Code on 11/27/25.
//

import SwiftUI

/// Card for Contract Takeover listings
struct TakeoverCard: View {
    let takeover: ContractTakeover
    let onInquire: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header
            header

            // Specs row
            specsRow

            Divider()
                .background(MarketplaceTheme.Colors.textTertiary.opacity(0.2))

            // Value proposition
            valueSection

            // Action
            Button(action: onInquire) {
                HStack {
                    Spacer()
                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14))
                        Text("Inquire")
                        if takeover.inquiryCount > 0 {
                            Text("(\(takeover.inquiryCount) interested)")
                                .font(.system(size: MarketplaceTheme.Typography.micro))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(MarketplaceTheme.Colors.primary)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(MarketplaceTheme.Spacing.md)
        .marketplaceCard(elevation: .medium)
    }

    private var header: some View {
        HStack {
            // Provider icon
            ZStack {
                Circle()
                    .fill(MarketplaceTheme.Colors.primary.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: takeover.providerLogoName)
                    .font(.system(size: 18))
                    .foregroundStyle(MarketplaceTheme.Colors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Text("TAKEOVER")
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.accent)
                        .tracking(1)

                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(MarketplaceTheme.Colors.accent)
                }

                Text(takeover.title)
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    .lineLimit(2)
            }

            Spacer()

            // Monthly rate
            VStack(alignment: .trailing, spacing: 0) {
                Text(String(format: "$%.0f", takeover.monthlyRate))
                    .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.success)
                Text("/mo")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
        }
    }

    private var specsRow: some View {
        HStack(spacing: MarketplaceTheme.Spacing.lg) {
            specItem(icon: "clock", label: "Time left", value: "\(takeover.monthsRemaining) months")
            specItem(icon: "building.2", label: "Provider", value: takeover.providerName)

            if let speed = takeover.specs.speed {
                specItem(icon: "bolt.fill", label: "Speed", value: speed)
            }
        }
    }

    private func specItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                Text(value)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
    }

    private var valueSection: some View {
        HStack(spacing: MarketplaceTheme.Spacing.md) {
            // ETF avoided
            valuePill(
                icon: "xmark.shield.fill",
                label: "ETF avoided",
                value: String(format: "$%.0f", takeover.etfAvoided),
                color: MarketplaceTheme.Colors.danger
            )

            // Seller incentive
            if takeover.sellerIncentive > 0 {
                valuePill(
                    icon: "gift.fill",
                    label: "Seller bonus",
                    value: String(format: "$%.0f", takeover.sellerIncentive),
                    color: MarketplaceTheme.Colors.success
                )
            }

            Spacer()

            // Total value
            VStack(alignment: .trailing, spacing: 0) {
                Text(takeover.totalValue)
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.accent)

                Text("@\(takeover.sellerHandle)")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
        }
    }

    private func valuePill(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 8))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                Text(value)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .bold))
                    .foregroundStyle(color)
            }
        }
        .padding(.horizontal, MarketplaceTheme.Spacing.xs)
        .padding(.vertical, MarketplaceTheme.Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.sm)
                .fill(color.opacity(0.1))
        )
    }
}

struct TakeoverCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
        TakeoverCard(
        takeover: MockMarketplaceData.takeovers[0],
        onInquire: {}
        )
        }
        .padding()
        .background(MarketplaceTheme.Colors.backgroundPrimary)
    }
}

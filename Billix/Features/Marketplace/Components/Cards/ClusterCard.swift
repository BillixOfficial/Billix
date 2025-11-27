//
//  ClusterCard.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Card for group buys, syndicates, and rallies
struct ClusterCard: View {
    let cluster: Cluster
    let onPlaceBid: () -> Void
    let onClaimOffer: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header
            header

            // Description
            Text(cluster.description)
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

            // Progress bar
            progressSection

            // Stats row
            statsRow

            // ZIP codes
            if !cluster.coveredZipCodes.isEmpty {
                zipCodesRow
            }

            Divider()
                .background(MarketplaceTheme.Colors.textTertiary.opacity(0.2))

            // Action
            if let offer = cluster.flashDropOffer {
                flashDropSection(offer: offer)
            } else {
                Button(action: onPlaceBid) {
                    HStack {
                        Spacer()
                        Text("Place Bid to Join")
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
        }
        .padding(MarketplaceTheme.Spacing.md)
        .marketplaceCard(elevation: .medium)
    }

    private var header: some View {
        HStack {
            // Type icon
            Image(systemName: cluster.type.icon)
                .font(.system(size: 16))
                .foregroundStyle(MarketplaceTheme.Colors.secondary)

            // Title
            VStack(alignment: .leading, spacing: 0) {
                Text("CLUSTER")
                    .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    .tracking(1)

                Text(cluster.title)
                    .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
            }

            Spacer()

            // Status pill
            statusPill
        }
    }

    private var statusPill: some View {
        Text(cluster.status.rawValue)
            .font(.system(size: MarketplaceTheme.Typography.micro, weight: .semibold))
            .foregroundStyle(statusColor.opacity(0.8))
            .padding(.horizontal, MarketplaceTheme.Spacing.xs)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.15))
            )
    }

    private var statusColor: Color {
        switch cluster.status {
        case .forming: return MarketplaceTheme.Colors.info
        case .active: return MarketplaceTheme.Colors.success
        case .goalReached, .flashDrop: return MarketplaceTheme.Colors.accent
        case .completed: return MarketplaceTheme.Colors.textTertiary
        case .expired: return MarketplaceTheme.Colors.danger
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxs) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            cluster.isGoalReached
                                ? MarketplaceTheme.Colors.success
                                : MarketplaceTheme.Colors.primary
                        )
                        .frame(width: geo.size.width * cluster.progressPercent, height: 12)
                }
            }
            .frame(height: 12)

            // Count
            HStack {
                Text("\(cluster.currentCount) / \(cluster.goalCount) bids")
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                Spacer()

                if let remaining = cluster.timeRemaining {
                    Text(remaining)
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.warning)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: MarketplaceTheme.Spacing.lg) {
            if let median = cluster.medianContractEnd {
                statItem(
                    icon: "calendar",
                    label: "Median ends",
                    value: formatDate(median)
                )
            }

            if let price = cluster.medianWillingToPay {
                statItem(
                    icon: "dollarsign.circle",
                    label: "Median bid",
                    value: String(format: "$%.0f/mo", price)
                )
            }
        }
    }

    private func statItem(icon: String, label: String, value: String) -> some View {
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
            }
        }
    }

    private var zipCodesRow: some View {
        HStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Image(systemName: "mappin.circle")
                .font(.system(size: 12))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            Text("ZIPs:")
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            Text(cluster.coveredZipCodes.joined(separator: ", "))
                .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
        }
    }

    private func flashDropSection(offer: FlashDropOffer) -> some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Flash drop header
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(MarketplaceTheme.Colors.accent)
                Text("FLASH DROP")
                    .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.accent)
                    .tracking(1)
                Spacer()
                Text(offer.timeRemaining)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.danger)
            }

            // Offer details
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(offer.providerName)
                        .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        Text(String(format: "$%.0f", offer.offerPrice))
                            .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.success)

                        Text(String(format: "$%.0f", offer.originalPrice))
                            .font(.system(size: MarketplaceTheme.Typography.caption))
                            .strikethrough()
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }
                }

                Spacer()

                Button(action: { onClaimOffer?() }) {
                    Text("Claim Offer")
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)
                        .padding(.vertical, MarketplaceTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(MarketplaceTheme.Colors.accent)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Claims progress
            HStack {
                Text("\(offer.claimCount)/\(offer.maxClaims) claimed")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                Spacer()
            }
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(MarketplaceTheme.Colors.accent.opacity(0.1))
                .stroke(MarketplaceTheme.Colors.accent.opacity(0.3), lineWidth: 1)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        ClusterCard(
            cluster: MockMarketplaceData.clusters[0],
            onPlaceBid: {},
            onClaimOffer: nil
        )

        ClusterCard(
            cluster: MockMarketplaceData.clusters[2],
            onPlaceBid: {},
            onClaimOffer: {}
        )
    }
    .padding()
    .background(MarketplaceTheme.Colors.backgroundPrimary)
}

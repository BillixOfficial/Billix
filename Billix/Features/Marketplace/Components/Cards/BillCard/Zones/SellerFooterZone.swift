//
//  SellerFooterZone.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Zone 5: Seller Footer
/// FB Marketplace vibe - "Who's behind this?"
struct SellerFooterZone: View {
    let listing: BillListing
    let onWatchlist: () -> Void
    let onAskOwner: () -> Void
    let onReport: () -> Void

    var body: some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Avatar
            sellerAvatar

            // Seller info
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxxs) {
                // Handle + Sherpa badge
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Text(listing.sellerHandle)
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    if listing.isSherpa {
                        sherpaBadge
                    }
                }

                // Stats
                Text("Saved others \(formatCurrency(listing.sellerTotalSaved))")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.success)

                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Text("\(listing.sellerTotalUses) used")
                    Text("•")
                    Text("\(Int(listing.sellerSuccessRate * 100))% success")
                }
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }

            Spacer()

            // Action icons
            actionButtons
        }
    }

    private var sellerAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            MarketplaceTheme.Colors.secondary.opacity(0.3),
                            MarketplaceTheme.Colors.secondary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)

            Image(systemName: "person.fill")
                .font(.system(size: 20))
                .foregroundStyle(MarketplaceTheme.Colors.secondary)
        }
    }

    private var sherpaBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 8))
            Text("Sherpa")
                .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
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

    private var actionButtons: some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Watchlist
            Button(action: onWatchlist) {
                Image(systemName: "heart")
                    .font(.system(size: 18))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }

            // Ask Owner
            Button(action: onAskOwner) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 18))
                    .foregroundStyle(MarketplaceTheme.Colors.info)
            }

            // Report
            Button(action: onReport) {
                Image(systemName: "flag")
                    .font(.system(size: 16))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "$%.1fK", amount / 1000)
        }
        return String(format: "$%.0f", amount)
    }
}

#Preview {
    VStack(spacing: 20) {
        SellerFooterZone(
            listing: MockMarketplaceData.billListings[0],
            onWatchlist: {},
            onAskOwner: {},
            onReport: {}
        )

        SellerFooterZone(
            listing: MockMarketplaceData.billListings[1],
            onWatchlist: {},
            onAskOwner: {},
            onReport: {}
        )
    }
    .padding()
    .background(Color.white)
}

//
//  TickerHeaderZone.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Zone 1: Ticker Header - Identity & Trust
/// Answers "What is this?" and "Can I trust it?"
struct TickerHeaderZone: View {
    let listing: BillListing

    var body: some View {
        HStack(alignment: .top, spacing: MarketplaceTheme.Spacing.sm) {
            // Provider logo
            providerLogo

            // Provider info
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxxs) {
                Text(listing.providerName)
                    .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                // Trust indicators row
                trustIndicators

                // Reliability score
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Text("Reliability")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    Text(String(format: "%.1f/5", listing.reliabilityScore))
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(listing.reliabilityScore) ? "star.fill" : "star")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.billixStarGold)
                    }
                }
            }

            Spacer()

            // Right side: Eligibility + Match Score
            VStack(alignment: .trailing, spacing: MarketplaceTheme.Spacing.xs) {
                EligibilityPill(type: listing.eligibility)

                MatchScoreRing(score: listing.matchScore, size: 44)
            }
        }
    }

    private var providerLogo: some View {
        ZStack {
            Circle()
                .fill(MarketplaceTheme.Colors.primary.opacity(0.1))
                .frame(width: 48, height: 48)

            Image(systemName: listing.providerLogoName)
                .font(.system(size: 22))
                .foregroundStyle(MarketplaceTheme.Colors.primary)
        }
    }

    private var trustIndicators: some View {
        HStack(spacing: MarketplaceTheme.Spacing.xs) {
            if listing.isVerified {
                VerifiedBadge()
            }

            Text("•")
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            Text(listing.timeAgo)
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            Text("•")
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            Text(listing.zipCode)
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
    }
}

struct TickerHeaderZone_Previews: PreviewProvider {
    static var previews: some View {
        TickerHeaderZone(listing: MockMarketplaceData.billListings[0])
        .padding()
        .background(Color.white)
    }
}

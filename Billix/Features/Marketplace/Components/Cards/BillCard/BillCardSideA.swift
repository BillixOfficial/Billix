//
//  BillCardSideA.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Side A: Asset View - The main deal card face
/// Shows all 5 zones in the default view
struct BillCardSideA: View {
    let listing: BillListing
    @Binding var isVsMe: Bool
    let userCurrentPrice: Double?
    let onUnlock: () -> Void
    let onAskQuestion: () -> Void
    let onWatchlist: () -> Void
    let onAskOwner: () -> Void
    let onReport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top bar with VS ME toggle and Live Pulse
            topBar
                .padding(.horizontal, MarketplaceTheme.Spacing.md)
                .padding(.top, MarketplaceTheme.Spacing.md)
                .padding(.bottom, MarketplaceTheme.Spacing.sm)

            Divider()
                .background(MarketplaceTheme.Colors.textTertiary.opacity(0.1))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.md) {
                    // Zone 1: Ticker Header
                    TickerHeaderZone(listing: listing)

                    Divider()
                        .background(MarketplaceTheme.Colors.textTertiary.opacity(0.1))

                    // Zone 2: Financial Spread
                    FinancialSpreadZone(
                        listing: listing,
                        isVsMe: isVsMe,
                        userCurrentPrice: userCurrentPrice
                    )

                    Divider()
                        .background(MarketplaceTheme.Colors.textTertiary.opacity(0.1))

                    // Zone 3: Dynamic Specs
                    DynamicSpecsZone(listing: listing)

                    Divider()
                        .background(MarketplaceTheme.Colors.textTertiary.opacity(0.1))

                    // Zone 4: Blueprint Tease
                    BlueprintTeaseZone(
                        listing: listing,
                        onUnlock: onUnlock,
                        onAskQuestion: onAskQuestion
                    )

                    Divider()
                        .background(MarketplaceTheme.Colors.textTertiary.opacity(0.1))

                    // Zone 5: Seller Footer
                    SellerFooterZone(
                        listing: listing,
                        onWatchlist: onWatchlist,
                        onAskOwner: onAskOwner,
                        onReport: onReport
                    )
                }
                .padding(.horizontal, MarketplaceTheme.Spacing.md)
                .padding(.vertical, MarketplaceTheme.Spacing.sm)
            }

            // Swipe hint
            swipeHint
        }
    }

    private var topBar: some View {
        HStack {
            VSMeToggle(isVsMe: $isVsMe)

            Spacer()

            LivePulse(
                viewingCount: listing.viewingCount,
                unlocksPerHour: listing.unlocksPerHour
            )
        }
    }

    private var swipeHint: some View {
        HStack {
            Spacer()
            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Text("Swipe for analytics")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                Image(systemName: "chevron.left")
                    .font(.system(size: 10))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
            .padding(.vertical, MarketplaceTheme.Spacing.xs)
            .padding(.horizontal, MarketplaceTheme.Spacing.md)
        }
        .background(MarketplaceTheme.Colors.backgroundSecondary.opacity(0.5))
    }
}

struct BillCardSideA_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
        @State private var isVsMe = false
        
        var body: some View {
        BillCardSideA(
        listing: MockMarketplaceData.billListings[0],
        isVsMe: $isVsMe,
        userCurrentPrice: 95.00,
        onUnlock: {},
        onAskQuestion: {},
        onWatchlist: {},
        onAskOwner: {},
        onReport: {}
        )
        .frame(width: 360, height: 520)
        .marketplaceCard(elevation: .high)
        }
        }
        
        return PreviewWrapper()
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

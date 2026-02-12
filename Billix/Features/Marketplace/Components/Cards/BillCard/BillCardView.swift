//
//  BillCardView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Main Bill Card component with Side A (Asset) and Side B (Analyst) views
/// Swipe left to reveal analytics, swipe right to go back to deal view
struct BillCardView: View {
    let listing: BillListing
    let userCurrentPrice: Double?
    let onUnlock: () -> Void
    let onAskQuestion: () -> Void
    let onWatchlist: () -> Void
    let onAskOwner: () -> Void
    let onReport: () -> Void

    @State private var isVsMe: Bool = false
    @State private var showingSideB: Bool = false
    @State private var dragOffset: CGFloat = 0

    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 32

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Side B (Analyst) - Behind
                BillCardSideB(
                    listing: listing,
                    isVsMe: $isVsMe
                )
                .frame(width: cardWidth)
                .offset(x: showingSideB ? 0 : cardWidth)

                // Side A (Asset) - Front
                BillCardSideA(
                    listing: listing,
                    isVsMe: $isVsMe,
                    userCurrentPrice: userCurrentPrice,
                    onUnlock: onUnlock,
                    onAskQuestion: onAskQuestion,
                    onWatchlist: onWatchlist,
                    onAskOwner: onAskOwner,
                    onReport: onReport
                )
                .frame(width: cardWidth)
                .offset(x: showingSideB ? -cardWidth : 0)
                .offset(x: dragOffset)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.width
                        if showingSideB {
                            // On Side B, allow dragging right
                            dragOffset = max(0, translation)
                        } else {
                            // On Side A, allow dragging left
                            dragOffset = min(0, translation)
                        }
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 100
                        withAnimation(MarketplaceTheme.Animation.smooth) {
                            if showingSideB {
                                // Swipe right to go back to Side A
                                if value.translation.width > threshold {
                                    showingSideB = false
                                }
                            } else {
                                // Swipe left to show Side B
                                if value.translation.width < -threshold {
                                    showingSideB = true
                                }
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .frame(width: cardWidth, height: MarketplaceTheme.CardSize.billCardHeight)
        .marketplaceCard(elevation: .high)
        .clipped()
    }
}

/// Compact version of Bill Card for list views
struct BillCardCompact: View {
    let listing: BillListing
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                // Provider icon
                ZStack {
                    Circle()
                        .fill(MarketplaceTheme.Colors.primary.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: listing.providerLogoName)
                        .font(.system(size: 18))
                        .foregroundStyle(MarketplaceTheme.Colors.primary)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(listing.providerName)
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        if listing.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(MarketplaceTheme.Colors.info)
                        }
                    }

                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        Text(listing.category.rawValue)
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                        Text("•")
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                        Text(listing.zipCode)
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }
                }

                Spacer()

                // Price + Grade
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatPrice(listing.askPrice))
                        .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.success)

                    GradePill(grade: listing.grade)
                }

                // Match score
                MatchScoreRing(score: listing.matchScore, size: 36)
            }
            .padding(MarketplaceTheme.Spacing.sm)
            .background(MarketplaceTheme.Colors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg))
            .shadow(
                color: MarketplaceTheme.Shadows.low.color,
                radius: MarketplaceTheme.Shadows.low.radius,
                x: MarketplaceTheme.Shadows.low.x,
                y: MarketplaceTheme.Shadows.low.y
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func formatPrice(_ price: Double) -> String {
        if price < 1 {
            return String(format: "$%.2f", price)
        } else if price == floor(price) {
            return String(format: "$%.0f", price)
        } else {
            return String(format: "$%.2f", price)
        }
    }
}

struct BillCardView_Full_Card_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
        BillCardView(
        listing: MockMarketplaceData.billListings[0],
        userCurrentPrice: 95.00,
        onUnlock: {},
        onAskQuestion: {},
        onWatchlist: {},
        onAskOwner: {},
        onReport: {}
        )
        .padding()
        }
        .background(MarketplaceTheme.Colors.backgroundPrimary)
    }
}

struct BillCardView_Compact_Cards_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
        ForEach(MockMarketplaceData.billListings) { listing in
        BillCardCompact(listing: listing, onTap: {})
        }
        }
        .padding()
        .background(MarketplaceTheme.Colors.backgroundPrimary)
    }
}

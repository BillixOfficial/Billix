//
//  ExploreBillListingCard.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  Card component for displaying bill listings in Bill Explorer
//

import SwiftUI

struct ExploreBillListingCard: View {
    let listing: ExploreBillListing
    let onReactionTapped: (BillReactionType) -> Void
    let onCommentTapped: () -> Void

    private let cardBackground = Color.white
    private let headlineBlack = Color(hex: "#1A1A1A")
    private let metadataGrey = Color(hex: "#6B7280")
    private let dividerGrey = Color(hex: "#F3F4F6")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Bill type + Location + Time
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            // Amount & Comparison
            amountSection
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Percentile Bar
            percentileSection
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Context Tags (if available)
            if listing.housingType != nil || listing.occupants != nil || listing.userNote != nil {
                contextSection
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            // Divider
            Rectangle()
                .fill(dividerGrey)
                .frame(height: 1)

            // Reactions Bar
            BillReactionsBar(
                reactions: listing.reactions,
                commentCount: listing.commentCount,
                onReactionTapped: onReactionTapped,
                onCommentTapped: onCommentTapped
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            // Bill type icon & name
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: listing.billType.color).opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: listing.billType.icon)
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: listing.billType.color))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(listing.billType.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(headlineBlack)

                    Text(listing.provider)
                        .font(.system(size: 13))
                        .foregroundColor(metadataGrey)
                }
            }

            Spacer()

            // Location & time
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 10))
                    Text(listing.location)
                        .font(.system(size: 12))
                }
                .foregroundColor(metadataGrey)

                HStack(spacing: 4) {
                    if listing.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.billixDarkTeal)
                    }
                    Text(listing.timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(metadataGrey)
                }
            }
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        HStack(alignment: .firstTextBaseline) {
            // Main amount
            Text(listing.formattedAmount)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(headlineBlack)

            // Period & housing type
            VStack(alignment: .leading, spacing: 2) {
                Text(listing.billingPeriod)
                    .font(.system(size: 13))
                    .foregroundColor(metadataGrey)

                if let housingType = listing.housingType {
                    Text(housingType.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(metadataGrey)
                }
            }
            .padding(.leading, 8)

            Spacer()

            // Trend indicator
            trendBadge
        }
    }

    private var trendBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: listing.trend.icon)
                .font(.system(size: 11, weight: .bold))
            Text(listing.trend.rawValue)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(Color(hex: listing.trend.color))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(hex: listing.trend.color).opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Percentile Section

    private var percentileSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            PercentileBar(percentile: listing.percentile)

            HStack {
                Text(listing.percentileText)
                    .font(.system(size: 13))
                    .foregroundColor(metadataGrey)

                Spacer()

                Text("Range: \(listing.historicalRangeText)")
                    .font(.system(size: 12))
                    .foregroundColor(metadataGrey.opacity(0.8))
            }
        }
    }

    // MARK: - Context Section

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tags row
            HStack(spacing: 8) {
                if let occupants = listing.occupants {
                    contextTag(icon: "person.2.fill", text: occupants.rawValue)
                }
                if let sqft = listing.squareFootage {
                    contextTag(icon: "square.dashed", text: sqft.rawValue)
                }
            }

            // User note
            if let note = listing.userNote {
                HStack(spacing: 6) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 11))
                        .foregroundColor(metadataGrey)

                    Text("\"\(note)\"")
                        .font(.system(size: 13))
                        .foregroundColor(metadataGrey)
                        .italic()
                }
                .padding(.top, 2)
            }
        }
    }

    private func contextTag(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 12))
        }
        .foregroundColor(metadataGrey)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: "#F3F4F6"))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Bill Listing Card") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(ExploreBillListing.mockListings.prefix(3)) { listing in
                ExploreBillListingCard(
                    listing: listing,
                    onReactionTapped: { _ in },
                    onCommentTapped: { }
                )
            }
        }
        .padding(16)
    }
    .background(Color(hex: "#F5F5F7"))
}

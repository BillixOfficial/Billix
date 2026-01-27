//
//  BillListingCard.swift
//  Billix
//
//  Individual bill listing card for the Bill Explorer marketplace
//

import SwiftUI

struct BillListingCard: View {
    let listing: ExploreBillListing
    let userVote: VoteType?
    let isBookmarked: Bool

    let onTap: () -> Void
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onBookmark: () -> Void
    let onMessage: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            // Amount & Percentile
            amountSection
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Context tags
            if hasContextInfo {
                contextSection
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            // User note (if exists)
            if let note = listing.userNote, !note.isEmpty {
                noteSection(note)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            // Divider
            Divider()
                .padding(.horizontal, 16)

            // Interaction bar
            CompactInteractionBar(
                voteScore: listing.voteScore,
                tipCount: listing.tipCount,
                userVote: userVote,
                isBookmarked: isBookmarked,
                onUpvote: onUpvote,
                onDownvote: onDownvote,
                onBookmark: onBookmark,
                onMessage: onMessage
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(isPressed ? 0.10 : 0.06), radius: isPressed ? 6 : 12, x: 0, y: isPressed ? 2 : 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 10) {
            // Bill type icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: listing.billType.color).opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: listing.billType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: listing.billType.color))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(listing.billType.displayName.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))
                        .tracking(0.5)

                    if listing.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#4CAF7A"))
                    }
                }

                HStack(spacing: 4) {
                    Text(listing.provider)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8B9A94"))

                    Text("*")
                        .foregroundColor(Color(hex: "#8B9A94"))

                    Text(listing.locationDisplay)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }
            }

            Spacer()

            Text(listing.timeAgoDisplay)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "#8B9A94"))
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$\(Int(listing.amount))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("/mo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Spacer()

                // Trend badge
                trendBadge(listing.trend)
            }

            // Percentile bar
            percentileBar(listing.percentile)
        }
    }

    // MARK: - Trend Badge

    private func trendBadge(_ trend: BillTrend) -> some View {
        HStack(spacing: 3) {
            Image(systemName: trend.icon)
                .font(.system(size: 10, weight: .semibold))

            Text(trend.displayText)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(Color(hex: trend.color))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: trend.color).opacity(0.12))
        .cornerRadius(6)
    }

    // MARK: - Percentile Bar

    private func percentileBar(_ percentile: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#E5E9E7"))
                        .frame(height: 6)

                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(percentileColor(percentile))
                        .frame(width: geometry.size.width * CGFloat(100 - percentile) / 100, height: 6)
                }
            }
            .frame(height: 6)

            // Label
            if let description = listing.percentileDescription {
                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(percentileColor(percentile))
            }
        }
    }

    private func percentileColor(_ percentile: Int) -> Color {
        if percentile <= 30 {
            return Color(hex: "#4CAF7A")
        } else if percentile >= 70 {
            return Color(hex: "#E07A6B")
        } else {
            return Color(hex: "#F5A623")
        }
    }

    // MARK: - Context Section

    private var hasContextInfo: Bool {
        listing.housingType != nil || listing.occupants != nil || listing.squareFootage != nil
    }

    private var contextSection: some View {
        HStack(spacing: 8) {
            if let housing = listing.housingType {
                contextTag(housing.rawValue)
            }

            if let occupants = listing.occupants {
                contextTag(occupants.rawValue)
            }

            if let sqft = listing.squareFootage {
                contextTag(sqft.rawValue)
            }
        }
    }

    private func contextTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color(hex: "#5B8A6B"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: "#5B8A6B").opacity(0.1))
            .cornerRadius(6)
    }

    // MARK: - Note Section

    private func noteSection(_ note: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "quote.opening")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#8B9A94"))

            Text(note)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#5A6B64"))
                .italic()
                .lineLimit(2)

            Spacer()
        }
        .padding(10)
        .background(Color(hex: "#F7F9F8"))
        .cornerRadius(8)
    }
}

// MARK: - Legacy Card (backward compatibility)

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
            // Header
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            // Amount
            amountSection
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Percentile
            percentileSection
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Context
            if listing.housingType != nil || listing.occupants != nil || listing.userNote != nil {
                contextSection
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            Rectangle()
                .fill(dividerGrey)
                .frame(height: 1)

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
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
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

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 10))
                    Text(listing.location)
                        .font(.system(size: 12))
                }
                .foregroundColor(metadataGrey)

                Text(listing.timeAgo)
                    .font(.system(size: 11))
                    .foregroundColor(metadataGrey.opacity(0.8))
            }
        }
    }

    private var amountSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(listing.formattedAmount)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(headlineBlack)

            Text("/\(listing.billingPeriod)")
                .font(.system(size: 14))
                .foregroundColor(metadataGrey)

            Spacer()

            if listing.isVerified {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                    Text("Verified")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(hex: "#10B981"))
            }
        }
    }

    private var percentileSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            PercentileBar(percentile: listing.percentile)

            Text(listing.percentileText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(metadataGrey)
        }
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let housing = listing.housingType {
                    contextTag(text: housing.rawValue, icon: "house.fill")
                }
                if let occupants = listing.occupants {
                    contextTag(text: occupants.rawValue, icon: "person.2.fill")
                }
            }

            if let note = listing.userNote {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 10))
                        .foregroundColor(metadataGrey)
                    Text(note)
                        .font(.system(size: 13))
                        .foregroundColor(metadataGrey)
                        .italic()
                }
                .padding(10)
                .background(Color(hex: "#F9FAFB"))
                .cornerRadius(8)
            }
        }
    }

    private func contextTag(text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(Color(hex: "#6B7280"))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "#F3F4F6"))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(ExploreBillListing.mockListings) { listing in
                BillListingCard(
                    listing: listing,
                    userVote: listing.voteScore > 20 ? .up : nil,
                    isBookmarked: listing.tipCount > 10,
                    onTap: { print("Tapped \(listing.provider)") },
                    onUpvote: { print("Upvote") },
                    onDownvote: { print("Downvote") },
                    onBookmark: { print("Bookmark") },
                    onMessage: { print("Message") }
                )
            }
        }
        .padding()
    }
    .background(Color(hex: "#F7F9F8"))
}

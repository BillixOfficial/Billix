//
//  BillExplorerDetailSheet.swift
//  Billix
//
//  Detail sheet for bill listings
//

import SwiftUI

struct BillExplorerDetailSheet: View {
    let listing: ExploreBillListing
    let userVote: VoteType?
    let isBookmarked: Bool

    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onBookmark: () -> Void
    let onGetSimilarRates: () -> Void
    let onNegotiationScript: () -> Void
    let onFindSwapMatch: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            // Show details content directly (Actions tab hidden for now)
            detailsTab
            .background(Color(hex: "#F7F9F8"))
            .navigationTitle("\(listing.billType.displayName) Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#5B8A6B"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: onBookmark) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(isBookmarked ? Color(hex: "#5B8A6B") : Color(hex: "#8B9A94"))
                        }

                        Text(listing.locationDisplay)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#8B9A94"))
                    }
                }
            }
        }
    }

    // MARK: - Details Tab

    private var detailsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Context Banner - explains what user is viewing
                contextBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Bill Amount Card
                billAmountCard
                    .padding(.horizontal, 20)

                // Provider & Trend Card
                providerCard
                    .padding(.horizontal, 20)

                // Bill-Type Specific Details Card
                BillTypeDetailsCard(listing: listing)
                    .padding(.horizontal, 20)

                // Usage Comparison Bar (only for metered utilities: electric, gas, water)
                // Don't show for internet/phone since they're flat-rate services
                if listing.isMeteredUtility,
                   listing.meetsKAnonymity,
                   listing.hasUsageData,
                   let usage = listing.usageAmount,
                   let avg = listing.areaAverageUsage,
                   let min = listing.areaMinUsage,
                   let max = listing.areaMaxUsage,
                   let unit = listing.usageUnit {
                    UsageComparisonBar(
                        userValue: usage,
                        areaAverage: avg,
                        areaMin: min,
                        areaMax: max,
                        unit: unit,
                        valuePrefix: "",
                        stateCode: listing.state
                    )
                    .padding(.horizontal, 20)
                }

                // User Note Card
                if let note = listing.userNote, !note.isEmpty {
                    userNoteCard(note)
                        .padding(.horizontal, 20)
                }

                // Bottom padding
                Color.clear.frame(height: 20)
            }
        }
    }

    // MARK: - Context Banner

    private var contextBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#5B8A6B"))

                Text("Viewing \(listing.anonymousId)'s Bill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))
            }

            // Data source explanation
            HStack(spacing: 6) {
                Image(systemName: listing.meetsKAnonymity ? "checkmark.shield.fill" : "eye.slash.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8B9A94"))

                if listing.meetsKAnonymity {
                    Text("Based on \(listing.providerBillCount) Billix \(listing.provider) bills")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8B9A94"))
                } else {
                    Text("Based on Billix community data (limited)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#5B8A6B").opacity(0.08))
        .cornerRadius(12)
    }

    private var billAmountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Amount
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$\(Int(listing.amount))")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("/mo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            // Percentile comparison
            VStack(alignment: .leading, spacing: 8) {
                // Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#E5E9E7"))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(percentileColor(listing.percentile))
                            .frame(width: geometry.size.width * CGFloat(100 - listing.percentile) / 100, height: 8)
                    }
                }
                .frame(height: 8)

                if let description = listing.percentileDescription {
                    Text(description)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(percentileColor(listing.percentile))
                }
            }

        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var providerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: listing.billType.color).opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: listing.billType.icon)
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: listing.billType.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(listing.provider)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        if listing.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#4CAF7A"))
                        }
                    }

                    Text(listing.billType.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: listing.trend.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: listing.trend.color))

                    Text(listing.trend.displayText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: listing.trend.color))
                }
            }

            Divider()

            HStack {
                Label(listing.locationDisplay, systemImage: "mappin.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Spacer()

                Text("Posted \(listing.timeAgoDisplay)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private func userNoteCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#5B8A6B"))

                Text("From \(listing.anonymousId)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            Text(note)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#2D3B35"))
                .italic()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    // MARK: - Actions Tab

    private var actionsTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Get similar rates
                actionButton(
                    icon: "tag.fill",
                    title: "Get Similar Rates",
                    subtitle: "View providers in your area with comparable prices",
                    color: "#5B8A6B",
                    action: onGetSimilarRates
                )

                // Negotiation script
                actionButton(
                    icon: "text.bubble.fill",
                    title: "Negotiation Script",
                    subtitle: "Get a call script for \(listing.provider)",
                    color: "#5BA4D4",
                    action: onNegotiationScript
                )

                // Find BillSwap match
                actionButton(
                    icon: "arrow.left.arrow.right.circle.fill",
                    title: "Find BillSwap Match",
                    subtitle: "Split costs with others in your area",
                    color: "#9B7EB8",
                    action: onFindSwapMatch
                )

                // Report option
                actionButton(
                    icon: "flag.fill",
                    title: "Report Listing",
                    subtitle: "Report inaccurate or inappropriate content",
                    color: "#8B9A94",
                    action: {}
                )
            }
            .padding(20)
        }
    }

    private func actionButton(icon: String, title: String, subtitle: String, color: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: color).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: color))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers

    private func percentileColor(_ percentile: Int) -> Color {
        if percentile <= 30 {
            return Color(hex: "#4CAF7A")
        } else if percentile >= 70 {
            return Color(hex: "#E07A6B")
        } else {
            return Color(hex: "#F5A623")
        }
    }
}

// MARK: - Preview

#Preview {
    BillExplorerDetailSheet(
        listing: ExploreBillListing.mockListings[0],
        userVote: .up,
        isBookmarked: true,
        onUpvote: {},
        onDownvote: {},
        onBookmark: {},
        onGetSimilarRates: {},
        onNegotiationScript: {},
        onFindSwapMatch: {}
    )
}

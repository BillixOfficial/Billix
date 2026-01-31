//
//  BillTypeDetailsCard.swift
//  Billix
//
//  Renders bill-type specific details based on the bill category
//

import SwiftUI

struct BillTypeDetailsCard: View {
    let listing: ExploreBillListing

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: listing.billType.icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: listing.billType.color))

                Text("\(listing.billType.displayName.uppercased()) DETAILS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .tracking(0.5)
            }

            // Bill-type specific content
            detailsContent
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private var detailsContent: some View {
        switch listing.billType {
        case .electric:
            electricDetails
        case .gas:
            gasDetails
        case .water:
            waterDetails
        case .internet:
            internetDetails
        case .phone:
            phoneDetails
        case .rent:
            rentDetails
        case .insurance:
            insuranceDetails
        }
    }

    // MARK: - Electric Details

    private var electricDetails: some View {
        VStack(spacing: 12) {
            // Usage (k-anonymity aware - shows fuzzy range if < 5 bills from provider)
            if let usageText = listing.usageDisplayText {
                detailRow(
                    icon: "bolt.fill",
                    label: "Usage",
                    value: usageText,
                    color: "#F59E0B"
                )
            }

            // Rate (k-anonymity aware)
            if let rate = listing.rateDisplayText {
                detailRow(
                    icon: "dollarsign.circle.fill",
                    label: "Rate",
                    value: rate,
                    color: "#5B8A6B"
                )
            }

            // Daily Average (k-anonymity aware)
            if let dailyAvgText = listing.dailyAvgDisplayText {
                detailRow(
                    icon: "calendar",
                    label: "Daily Avg",
                    value: dailyAvgText,
                    color: "#8B9A94"
                )
            }

            if let details = listing.additionalDetails {
                if let peak = details["peakUsage"] {
                    detailRow(
                        icon: "sun.max.fill",
                        label: "Peak Hours",
                        value: peak,
                        color: "#E07A6B"
                    )
                }
            }
        }
    }

    // MARK: - Gas Details

    private var gasDetails: some View {
        VStack(spacing: 12) {
            // Usage (k-anonymity aware)
            if let usageText = listing.usageDisplayText {
                detailRow(
                    icon: "flame.fill",
                    label: "Usage",
                    value: usageText,
                    color: "#EF4444"
                )
            }

            // Rate (k-anonymity aware)
            if let rate = listing.rateDisplayText {
                detailRow(
                    icon: "dollarsign.circle.fill",
                    label: "Rate",
                    value: rate,
                    color: "#5B8A6B"
                )
            }

            // Daily Average (k-anonymity aware)
            if let dailyAvgText = listing.dailyAvgDisplayText {
                detailRow(
                    icon: "calendar",
                    label: "Daily Avg",
                    value: dailyAvgText,
                    color: "#8B9A94"
                )
            }
        }
    }

    // MARK: - Water Details

    private var waterDetails: some View {
        VStack(spacing: 12) {
            // Usage (k-anonymity aware)
            if let usageText = listing.usageDisplayText {
                detailRow(
                    icon: "drop.fill",
                    label: "Usage",
                    value: usageText,
                    color: "#3B82F6"
                )
            }

            // Rate (k-anonymity aware)
            if let rate = listing.rateDisplayText {
                detailRow(
                    icon: "dollarsign.circle.fill",
                    label: "Rate",
                    value: rate,
                    color: "#5B8A6B"
                )
            }

            if let details = listing.additionalDetails {
                if let tier = details["tier"] {
                    detailRow(
                        icon: "chart.bar.fill",
                        label: "Tier",
                        value: tier,
                        color: "#8B5CF6"
                    )
                }
            }
        }
    }

    // MARK: - Internet Details

    private var internetDetails: some View {
        VStack(spacing: 12) {
            // Speed (from usage_metrics.speed_mbps)
            if let details = listing.additionalDetails, let speed = details["speed"] {
                detailRow(
                    icon: "arrow.down.circle.fill",
                    label: "Speed",
                    value: speed,
                    color: "#8B5CF6"
                )
            }

            // Plan name
            if let plan = listing.planName {
                detailRow(
                    icon: "checkmark.seal.fill",
                    label: "Plan",
                    value: plan,
                    color: "#5B8A6B"
                )
            }

            // Data usage (if available)
            if let details = listing.additionalDetails, let dataUsage = details["dataUsage"] {
                detailRow(
                    icon: "arrow.up.arrow.down.circle.fill",
                    label: "Data Used",
                    value: dataUsage,
                    color: "#3B82F6"
                )
            }

            // Show empty state if no data at all
            if listing.planName == nil &&
               (listing.additionalDetails?["speed"] == nil) &&
               (listing.additionalDetails?["dataUsage"] == nil) {
                noDataAvailable
            }
        }
    }

    // MARK: - Phone Details

    private var phoneDetails: some View {
        VStack(spacing: 12) {
            if let details = listing.additionalDetails {
                if let lines = details["lines"] {
                    detailRow(
                        icon: "phone.fill",
                        label: "Lines",
                        value: lines,
                        color: "#10B981"
                    )
                }

                if let data = details["data"] {
                    detailRow(
                        icon: "antenna.radiowaves.left.and.right",
                        label: "Data",
                        value: data,
                        color: "#8B5CF6"
                    )
                }

                if let plan = listing.planName {
                    detailRow(
                        icon: "rectangle.stack.fill",
                        label: "Plan Type",
                        value: plan,
                        color: "#5B8A6B"
                    )
                }
            } else {
                if let plan = listing.planName {
                    detailRow(
                        icon: "rectangle.stack.fill",
                        label: "Plan Type",
                        value: plan,
                        color: "#5B8A6B"
                    )
                } else {
                    noDataAvailable
                }
            }
        }
    }

    // MARK: - Rent Details

    private var rentDetails: some View {
        VStack(spacing: 12) {
            if let details = listing.additionalDetails {
                if let bedrooms = details["bedrooms"] {
                    detailRow(
                        icon: "bed.double.fill",
                        label: "Bedrooms",
                        value: bedrooms,
                        color: "#6366F1"
                    )
                }

                if let amenities = details["amenities"] {
                    detailRow(
                        icon: "star.fill",
                        label: "Amenities",
                        value: amenities,
                        color: "#F59E0B"
                    )
                }

                if let lease = details["lease"] {
                    detailRow(
                        icon: "calendar",
                        label: "Lease",
                        value: lease,
                        color: "#8B9A94"
                    )
                }
            } else {
                // Fall back to household context if no additional details
                if let housing = listing.housingType {
                    detailRow(
                        icon: "house.fill",
                        label: "Type",
                        value: housing.displayText,
                        color: "#6366F1"
                    )
                }
                if let sqft = listing.squareFootage {
                    detailRow(
                        icon: "square.dashed",
                        label: "Size",
                        value: sqft.rawValue,
                        color: "#8B9A94"
                    )
                }
            }
        }
    }

    // MARK: - Insurance Details

    private var insuranceDetails: some View {
        VStack(spacing: 12) {
            if let details = listing.additionalDetails {
                if let coverage = details["coverage"] {
                    detailRow(
                        icon: "shield.fill",
                        label: "Coverage",
                        value: coverage,
                        color: "#EC4899"
                    )
                }

                if let deductible = details["deductible"] {
                    detailRow(
                        icon: "dollarsign.circle.fill",
                        label: "Deductible",
                        value: deductible,
                        color: "#5B8A6B"
                    )
                }

                if let policyType = details["policyType"] {
                    detailRow(
                        icon: "doc.text.fill",
                        label: "Policy Type",
                        value: policyType,
                        color: "#8B9A94"
                    )
                }
            } else {
                noDataAvailable
            }
        }
    }

    // MARK: - Helper Views

    private func detailRow(icon: String, label: String, value: String, color: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: color).opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: color))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))
            }

            Spacer()
        }
    }

    private var noDataAvailable: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#8B9A94"))

            Text("Detailed information not provided")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#8B9A94"))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Electric with usage data
            BillTypeDetailsCard(listing: ExploreBillListing.mockListings[0])

            // Internet
            BillTypeDetailsCard(listing: ExploreBillListing.mockListings[1])

            // Gas
            BillTypeDetailsCard(listing: ExploreBillListing.mockListings[2])
        }
        .padding(20)
    }
    .background(Color(hex: "#F7F9F8"))
}

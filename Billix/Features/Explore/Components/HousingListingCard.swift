//
//  HousingListingCard.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Rent listing card with fair value indicator and market position
//

import SwiftUI

/// Fair value status for rental listings
enum FairValueStatus {
    case great      // > 15% below market
    case fair       // Within 10% of market
    case premium    // > 15% above market

    var label: String {
        switch self {
        case .great: return "Great Deal"
        case .fair: return "Fair Price"
        case .premium: return "Premium"
        }
    }

    var icon: String {
        switch self {
        case .great: return "checkmark.circle.fill"
        case .fair: return "equal.circle.fill"
        case .premium: return "arrow.up.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .great: return .billixMoneyGreen
        case .fair: return .billixGoldenAmber
        case .premium: return .billixFlashRed
        }
    }
}

/// Housing listing data model
struct HousingListing: Identifiable {
    let id: String
    let address: String
    let neighborhood: String
    let monthlyRent: Double
    let bedrooms: Int
    let bathrooms: Double
    let sqft: Int?
    let amenities: [String]
    let fairValue: FairValueStatus
    let marketPosition: Double  // 0.0 to 1.0 (position in market range)
    let marketMin: Double
    let marketMax: Double
    let isPriceDrop: Bool
}

/// Rent listing card component
struct HousingListingCard: View {

    // MARK: - Properties

    let listing: HousingListing
    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Price + Fair Value Badge
            header

            // Property details
            propertyDetails

            // Amenities
            if !listing.amenities.isEmpty {
                amenitiesSection
            }

            // Market position spread bar
            marketSpreadBar
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(
                    color: .black.opacity(isPressed ? 0.1 : 0.05),
                    radius: isPressed ? 4 : 10,
                    x: 0,
                    y: isPressed ? 2 : 4
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("$\(Int(listing.monthlyRent))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    Text("/mo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .offset(y: 4)

                    if listing.isPriceDrop {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.billixMoneyGreen)
                    }
                }

                Text(listing.neighborhood)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Fair value badge
            HStack(spacing: 5) {
                Image(systemName: listing.fairValue.icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(listing.fairValue.label)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(listing.fairValue.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(listing.fairValue.color.opacity(0.12))
            )
        }
    }

    // MARK: - Property Details

    private var propertyDetails: some View {
        HStack(spacing: 16) {
            DetailPill(icon: "bed.double.fill", value: "\(listing.bedrooms) Bed")

            DetailPill(icon: "shower.fill", value: "\(String(format: "%.1f", listing.bathrooms)) Bath")

            if let sqft = listing.sqft {
                DetailPill(icon: "square.fill", value: "\(sqft) sqft")
            }
        }
    }

    // MARK: - Amenities

    private var amenitiesSection: some View {
        HStack(spacing: 8) {
            ForEach(Array(listing.amenities.prefix(3)), id: \.self) { amenity in
                AmenityChip(text: amenity)
            }

            if listing.amenities.count > 3 {
                Text("+\(listing.amenities.count - 3)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Market Spread Bar

    private var marketSpreadBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Market Position")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)

                    // Position marker
                    Circle()
                        .fill(listing.fairValue.color)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .offset(x: geometry.size.width * listing.marketPosition - 8)
                }
            }
            .frame(height: 16)

            HStack {
                Text("$\(Int(listing.marketMin))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()

                Spacer()

                Text("$\(Int(listing.marketMax))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Detail Pill

struct DetailPill: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))

            Text(value)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(.billixDarkTeal)
    }
}

// MARK: - Amenity Chip

struct AmenityChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.billixDarkTeal)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.billixDarkTeal.opacity(0.08))
            )
    }
}

// MARK: - Previews

struct HousingListingCard_Housing_Listing_Cards_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
        VStack(spacing: 16) {
        HousingListingCard(
        listing: HousingListing(
        id: "1",
        address: "1234 Main St",
        neighborhood: "Downtown Detroit",
        monthlyRent: 1500,
        bedrooms: 2,
        bathrooms: 1.5,
        sqft: 950,
        amenities: ["Parking", "Pet Friendly", "A/C"],
        fairValue: .great,
        marketPosition: 0.3,
        marketMin: 1400,
        marketMax: 2200,
        isPriceDrop: true
        )
        )
        
        HousingListingCard(
        listing: HousingListing(
        id: "2",
        address: "567 Oak Ave",
        neighborhood: "Midtown",
        monthlyRent: 1850,
        bedrooms: 1,
        bathrooms: 1,
        sqft: 750,
        amenities: ["Gym", "Pool", "Parking", "Laundry"],
        fairValue: .fair,
        marketPosition: 0.5,
        marketMin: 1400,
        marketMax: 2200,
        isPriceDrop: false
        )
        )
        
        HousingListingCard(
        listing: HousingListing(
        id: "3",
        address: "890 Elm St",
        neighborhood: "Corktown",
        monthlyRent: 2100,
        bedrooms: 3,
        bathrooms: 2,
        sqft: nil,
        amenities: ["Dishwasher", "Balcony"],
        fairValue: .premium,
        marketPosition: 0.75,
        marketMin: 1400,
        marketMax: 2200,
        isPriceDrop: false
        )
        )
        }
        .padding()
        }
        .background(Color.billixCreamBeige)
    }
}

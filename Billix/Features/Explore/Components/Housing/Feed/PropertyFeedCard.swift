//
//  PropertyFeedCard.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Vertical property card with image, price badge, and stats
//

import SwiftUI

struct PropertyFeedCard: View {
    let property: RentalComparable
    let fairValue: FairValue

    // MARK: - Property Type Gradient

    private var propertyTypeGradient: LinearGradient {
        switch property.propertyType {
        case .apartment:
            // Cool blue gradient
            return LinearGradient(
                colors: [Color(hex: "4A90E2"), Color(hex: "357ABD")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .singleFamily:
            // Warm green gradient
            return LinearGradient(
                colors: [Color(hex: "50C878"), Color(hex: "3FA561")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .condo:
            // Purple gradient
            return LinearGradient(
                colors: [Color(hex: "9B59B6"), Color(hex: "8E44AD")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .townhouse:
            // Orange gradient
            return LinearGradient(
                colors: [Color(hex: "E67E22"), Color(hex: "D35400")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .manufactured:
            // Brown gradient
            return LinearGradient(
                colors: [Color(hex: "A0826D"), Color(hex: "8B6F47")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .multiFamily:
            // Red gradient
            return LinearGradient(
                colors: [Color(hex: "E74C3C"), Color(hex: "C0392B")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .all:
            // Neutral teal gradient (fallback)
            return LinearGradient(
                colors: [Color(hex: "00A8E8"), Color(hex: "0077B6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var propertyTypeIcon: String {
        switch property.propertyType {
        case .apartment: return "building.2.fill"
        case .singleFamily: return "house.fill"
        case .condo: return "building.fill"
        case .townhouse: return "house.lodge.fill"
        case .manufactured: return "house.and.flag.fill"
        case .multiFamily: return "building.2.crop.circle.fill"
        case .all: return "house.fill"
        }
    }

    private var propertyTypeLabel: String {
        switch property.propertyType {
        case .apartment: return "Apartment"
        case .singleFamily: return "Single Family"
        case .condo: return "Condo"
        case .townhouse: return "Townhouse"
        case .manufactured: return "Manufactured"
        case .multiFamily: return "Multi-Family"
        case .all: return "Property"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Colored header with property type gradient
            ZStack {
                // Background gradient
                propertyTypeGradient

                // Content overlay
                VStack(spacing: 8) {
                    HStack {
                        // Property type icon
                        Image(systemName: propertyTypeIcon)
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.9))

                        Spacer()
                    }

                    Spacer()

                    // Price and stats row
                    VStack(alignment: .leading, spacing: 6) {
                        // Fair value badge
                        FairValueBadge(fairValue: fairValue, rent: property.rent ?? 2000)

                        // Stats
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "bed.double.fill")
                                    .font(.system(size: 14))
                                Text("\(property.bedrooms)")
                                    .font(.system(size: 14, weight: .medium))
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "bath.fill")
                                    .font(.system(size: 14))
                                Text(String(format: "%.1f", property.bathrooms))
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding(16)
            }
            .frame(height: 90)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 16
                )
            )

            // Property info section (white background)
            VStack(alignment: .leading, spacing: 8) {
                // Address
                Text(property.address)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Location + distance
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(property.distanceFormatted)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                // Property type and sqft
                HStack(spacing: 8) {
                    Text(propertyTypeLabel)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    if let sqft = property.sqft {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(sqft) ft²")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 90)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .accessibilityLabel("\(property.address), $\(Int(property.rent ?? 0)) per month")
    }
}

#Preview("Property Feed Card") {
    PropertyFeedCard(
        property: RentalComparable(
            id: "comp1",
            address: "418 N Center St, Royal Oak, MI",
            rent: 2450,
            lastSeen: Date(),
            similarity: 99.5,
            distance: 0.4,
            bedrooms: 2,
            bathrooms: 1.5,
            sqft: 950,
            propertyType: .apartment,
            coordinate: .init(latitude: 42.3314, longitude: -83.0458),
            yearBuilt: nil,
            lotSize: nil,
            status: "Active"
        ),
        fairValue: .greatDeal
    )
    .padding()
    .background(Color.billixCreamBeige)
}

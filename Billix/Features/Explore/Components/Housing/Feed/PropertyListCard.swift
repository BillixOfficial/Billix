//
//  PropertyListCard.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Mobile-friendly vertical property card (replaces horizontal scrolling table)
//

import SwiftUI

struct PropertyListCard: View {
    let property: RentalComparable
    let isSelected: Bool
    let index: Int?  // 1, 2, 3... for numbered badge (like RentCast)
    let onTap: () -> Void

    init(property: RentalComparable, isSelected: Bool, index: Int? = nil, onTap: @escaping () -> Void) {
        self.property = property
        self.isSelected = isSelected
        self.index = index
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Index badge, Address and Rent
                HStack(alignment: .top, spacing: 12) {
                    // Numbered badge (like RentCast)
                    if let index = index {
                        ZStack {
                            Circle()
                                .fill(Color.billixDarkTeal)
                                .frame(width: 28, height: 28)
                            Text("\(index)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.address)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text(property.lastSeenFormatted)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(property.rentFormatted)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.billixDarkTeal)
                        .monospacedDigit()
                }

                Divider()

                // Property Details Grid
                HStack(spacing: 16) {
                    // Beds & Baths
                    HStack(spacing: 12) {
                        DetailBadge(
                            icon: "bed.double.fill",
                            value: "\(property.bedrooms)"
                        )

                        DetailBadge(
                            icon: "shower.fill",
                            value: property.bathroomsFormatted
                        )
                    }

                    Spacer()
                }

                // Secondary Details
                HStack(spacing: 16) {
                    if let sqft = property.sqft {
                        SecondaryDetail(label: "Sq.Ft.", value: "\(sqft)")
                    }

                    if let distance = property.distance {
                        SecondaryDetail(
                            label: "Distance",
                            value: String(format: "%.2f mi", distance)
                        )
                    }

                    SecondaryDetail(label: "Type", value: property.propertyType.rawValue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.blue : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? .blue.opacity(0.2) : .black.opacity(0.04),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Views

struct DetailBadge: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

struct SecondaryDetail: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

struct PropertyListCard_Property_List_Cards_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
        VStack(spacing: 12) {
        PropertyListCard(
        property: RentalComparable(
        id: "1",
        address: "234 Lincoln Ave, Royal Oak, MI 48067",
        rent: 1605,
        lastSeen: Date(),
        similarity: 99.2,
        distance: 0.3,
        bedrooms: 2,
        bathrooms: 1.5,
        sqft: 950,
        propertyType: .apartment,
        coordinate: .init(latitude: 42.3314, longitude: -83.0458),
        yearBuilt: nil,
        lotSize: nil,
        status: "Active"
        ),
        isSelected: true,
        onTap: {}
        )
        
        PropertyListCard(
        property: RentalComparable(
        id: "2",
        address: "435 N Washington Ave, Royal Oak, MI 48067",
        rent: 1532,
        lastSeen: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
        similarity: 95.8,
        distance: 0.5,
        bedrooms: 2,
        bathrooms: 1.0,
        sqft: 850,
        propertyType: .apartment,
        coordinate: .init(latitude: 42.3314, longitude: -83.0458),
        yearBuilt: nil,
        lotSize: nil,
        status: "Inactive"
        ),
        isSelected: false,
        onTap: {}
        )
        }
        .padding()
        }
        .background(Color.billixCreamBeige)
    }
}

//
//  ComparableRow.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Data row with 9 columns for comparable properties table
//

import SwiftUI

struct ComparableRow: View {
    let comparable: RentalComparable
    let rowNumber: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Column 1: Row Number
            Text("\(rowNumber)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .center)
                .padding(.vertical, 12)

            // Column 2: Address
            Text(comparable.address)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(width: 180, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)

            // Column 3: Listed Rent
            Text(comparable.rentFormatted)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .monospacedDigit()
                .frame(width: 100, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)

            // Column 4: Last Seen
            Text(comparable.lastSeenFormatted)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)

            // Column 5: Similarity %
            Text(comparable.similarityFormatted)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.billixMoneyGreen)
                .monospacedDigit()
                .frame(width: 80, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)

            // Column 6: Distance
            Text(comparable.distanceFormatted)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .monospacedDigit()
                .frame(width: 80, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)

            // Column 7: Beds
            Text("\(comparable.bedrooms)")
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .frame(width: 50, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)

            // Column 8: Baths
            Text(comparable.bathroomsFormatted)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)

            // Column 9: Sq.Ft.
            Text(comparable.sqftFormatted)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .monospacedDigit()
                .frame(width: 70, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)

            // Column 10: Type
            Text(comparable.propertyType.rawValue)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
        }
        .background(rowBackground)
        .overlay(
            Rectangle()
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private var rowBackground: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        }
        return rowNumber % 2 == 0 ? Color.gray.opacity(0.03) : Color.clear
    }
}

// MARK: - Preview

#Preview("Comparable Rows") {
    ScrollView(.horizontal) {
        VStack(spacing: 0) {
            ForEach(1...5, id: \.self) { index in
                ComparableRow(
                    comparable: RentalComparable(
                        id: "comp\(index)",
                        address: "418 N Center St, Royal Oak, MI",
                        rent: 2000 + Double(index * 100),
                        lastSeen: Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date(),
                        similarity: 99.9 - Double(index) * 0.2,
                        distance: Double(index) * 0.3,
                        bedrooms: 2,
                        bathrooms: 1.5,
                        sqft: 950,
                        propertyType: .apartment,
                        coordinate: .init(latitude: 42.3314, longitude: -83.0458),
                        yearBuilt: 2010,
                        lotSize: 5000,
                        status: index % 2 == 0 ? "Active" : "Inactive"
                    ),
                    rowNumber: index,
                    isSelected: index == 1  // First row selected
                )
                Divider()
            }
        }
    }
    .background(Color.white)
}

//
//  PropertyStatsRow.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Stats row component with bed/bath/sqft icons
//

import SwiftUI

struct PropertyStatsRow: View {
    let bedrooms: Int
    let bathrooms: Double
    let sqft: Int?

    var body: some View {
        HStack(spacing: 16) {
            // Bedrooms
            HStack(spacing: 4) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.billixDarkTeal)

                Text("\(bedrooms) bed\(bedrooms == 1 ? "" : "s")")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }

            // Bathrooms
            HStack(spacing: 4) {
                Image(systemName: "shower.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.billixDarkTeal)

                Text(bathroomsFormatted)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }

            // Square feet (if available)
            if let sqft = sqft {
                HStack(spacing: 4) {
                    Image(systemName: "square.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.billixDarkTeal)

                    Text("\(sqft) ft²")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
            }
        }
    }

    private var bathroomsFormatted: String {
        if bathrooms.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(bathrooms)) bath"
        } else {
            return String(format: "%.1f bath", bathrooms)
        }
    }
}

struct PropertyStatsRow_Property_Stats_Row_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
        PropertyStatsRow(bedrooms: 2, bathrooms: 1.5, sqft: 950)
        PropertyStatsRow(bedrooms: 3, bathrooms: 2.0, sqft: nil)
        PropertyStatsRow(bedrooms: 1, bathrooms: 1.0, sqft: 650)
        }
        .padding()
        .background(Color.white)
    }
}

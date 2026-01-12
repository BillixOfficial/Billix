//
//  BedroomStatCard.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  Individual bedroom stat card for Market Trends grid
//

import SwiftUI

struct BedroomStatCard: View {
    let stat: BedroomStats

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Bedroom label (cleaner, no uppercase)
            Text(stat.bedroomLabel + " Rentals")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            // Price
            Text(stat.formattedRent)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .monospacedDigit()

            // Change percentage
            HStack(spacing: 3) {
                Image(systemName: stat.rentChange >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 9, weight: .bold))

                Text(stat.formattedChange)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(stat.changeColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview("Bedroom Stat Cards") {
    VStack(spacing: 12) {
        BedroomStatCard(
            stat: BedroomStats(
                bedroomCount: 0,
                averageRent: 826,
                rentChange: -2.9,
                sampleSize: 45
            )
        )

        BedroomStatCard(
            stat: BedroomStats(
                bedroomCount: 1,
                averageRent: 792,
                rentChange: 21.6,
                sampleSize: 67
            )
        )

        BedroomStatCard(
            stat: BedroomStats(
                bedroomCount: 2,
                averageRent: 1258,
                rentChange: 8.9,
                sampleSize: 89
            )
        )
    }
    .padding()
    .background(Color.billixCreamBeige)
}

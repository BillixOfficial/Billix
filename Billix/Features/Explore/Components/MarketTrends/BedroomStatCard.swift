//
//  BedroomStatCard.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  Individual bedroom stat card for Market Trends grid
//

import SwiftUI
import UIKit

struct BedroomStatCard: View {
    let stat: BedroomStats
    let bedroomType: BedroomType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Bedroom label with color dot indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(bedroomType.chartColor)
                    .frame(width: 8, height: 8)

                Text(stat.bedroomLabel + " Rentals")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

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
                .fill(isSelected ? bedroomType.chartColor.opacity(0.1) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? bedroomType.chartColor : Color.gray.opacity(0.15),
                                lineWidth: isSelected ? 2 : 1)
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .onTapGesture {
            onTap()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
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
            ),
            bedroomType: .studio,
            isSelected: false,
            onTap: { print("Studio tapped") }
        )

        BedroomStatCard(
            stat: BedroomStats(
                bedroomCount: 1,
                averageRent: 792,
                rentChange: 21.6,
                sampleSize: 67
            ),
            bedroomType: .oneBed,
            isSelected: true,
            onTap: { print("1 BD tapped") }
        )

        BedroomStatCard(
            stat: BedroomStats(
                bedroomCount: 2,
                averageRent: 1258,
                rentChange: 8.9,
                sampleSize: 89
            ),
            bedroomType: .twoBed,
            isSelected: false,
            onTap: { print("2 BD tapped") }
        )
    }
    .padding()
    .background(Color.billixCreamBeige)
}

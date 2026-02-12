//
//  PriceRangeStatsCard.swift
//  Billix
//
//  Created by Claude Code on 1/12/26.
//  Three-column price range stats (Low | Average | High)
//

import SwiftUI

struct PriceRangeStatsCard: View {
    let lowRent: Double
    let averageRent: Double
    let highRent: Double

    var body: some View {
        HStack(spacing: 0) {
            // Low
            StatColumn(
                label: "Low Rent",
                value: "$\(Int(lowRent))",
                color: Color.billixMoneyGreen
            )

            Divider()
                .frame(height: 60)

            // Average
            StatColumn(
                label: "Average",
                value: "$\(Int(averageRent))",
                color: Color.billixDarkTeal
            )

            Divider()
                .frame(height: 60)

            // High
            StatColumn(
                label: "High Rent",
                value: "$\(Int(highRent))",
                color: Color.billixStreakOrange
            )
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

struct StatColumn: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

struct PriceRangeStatsCard_Price_Range_Stats_Card_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        PriceRangeStatsCard(
        lowRent: 560,
        averageRent: 1407,
        highRent: 3400
        )
        
        PriceRangeStatsCard(
        lowRent: 1200,
        averageRent: 2180,
        highRent: 4800
        )
        }
        .padding(20)
        .background(Color(hex: "F8F9FA"))
    }
}

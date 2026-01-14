//
//  TickerHeaderView.swift
//  Billix
//
//  Created by Claude Code on 1/12/26.
//  Trading-style ticker header for Market Trends
//

import SwiftUI

struct TickerHeaderView: View {
    let averageRent: Double
    let changePercent: Double
    let lowRent: Double
    let highRent: Double

    var body: some View {
        VStack(spacing: 16) {
            // Restructured layout: price on top, metadata below
            VStack(alignment: .leading, spacing: 8) {
                // Row 1: Price only (prevent wrapping with dynamic scaling)
                Text("$\(Int(averageRent))")
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundColor(.primary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)  // Allow shrinking to 60% if needed
                    .lineLimit(1)  // Force single line

                // Row 2: /mo + Trend + Range
                HStack(spacing: 12) {
                    Text("/mo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)

                    // Percentage badge (Robinhood-style)
                    HStack(spacing: 4) {
                        Image(systemName: changePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .bold))

                        Text("\(abs(changePercent), specifier: "%.1f")%")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(changePercent >= 0 ? Color.billixMoneyGreen : Color.billixStreakOrange)
                    )

                    Text("Range: $\(Int(lowRent)) - $\(Int(highRent / 1000))k")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // Price range bar
            PriceRangeBar(
                low: lowRent,
                high: highRent,
                average: averageRent
            )
        }
    }
}

// MARK: - Preview

#Preview("Ticker Header - Positive Change") {
    TickerHeaderView(
        averageRent: 1407,
        changePercent: 3.1,
        lowRent: 560,
        highRent: 3400
    )
    .padding(20)
    .background(Color(hex: "F8F9FA"))
}

#Preview("Ticker Header - Negative Change") {
    TickerHeaderView(
        averageRent: 2180,
        changePercent: -2.4,
        lowRent: 850,
        highRent: 4200
    )
    .padding(20)
    .background(Color(hex: "F8F9FA"))
}

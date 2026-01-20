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
    var location: String = ""  // ZIP code or location name

    var body: some View {
        // Restructured layout: price + /mo on top, trend + range below
        VStack(alignment: .leading, spacing: 8) {
            // Location context (if provided)
            if !location.isEmpty {
                Text("Market Average in \(location)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Row 1: Price + /mo side-by-side
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("$\(Int(averageRent))")
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundColor(.primary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("/mo")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Row 2: Trend pill (far left) + Range text
            HStack(spacing: 12) {
                // Percentage badge (Robinhood-style) - far left
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

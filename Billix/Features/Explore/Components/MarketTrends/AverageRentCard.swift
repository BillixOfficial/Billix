//
//  AverageRentCard.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  Average monthly rent card with range visualization
//

import SwiftUI

struct AverageRentCard: View {
    let averageRent: Double
    let changePercent: Double
    let lowRent: Double
    let highRent: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("AVERAGE MONTHLY RENT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            // Large price with change badge
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("$\(Int(averageRent))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.billixDarkTeal)
                    .monospacedDigit()

                // Change badge
                HStack(spacing: 4) {
                    Text("\(changePercent >= 0 ? "+" : "")\(String(format: "%.1f", changePercent))%")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(changePercent >= 0 ? .billixMoneyGreen : .billixStreakOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill((changePercent >= 0 ? Color.billixMoneyGreen : Color.billixStreakOrange).opacity(0.12))
                )
            }

            // Subtitle
            Text("last 12 months")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Spacer().frame(height: 8)

            // Rent range bar
            VStack(alignment: .leading, spacing: 8) {
                // Range labels
                HStack {
                    Text("Low Rent")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("High Rent")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Gradient bar with marker
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background gradient
                        LinearGradient(
                            colors: [
                                Color.billixMoneyGreen.opacity(0.3),
                                Color.billixGoldenAmber.opacity(0.5),
                                Color.billixStreakOrange.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 8)
                        .clipShape(Capsule())

                        // Average marker
                        Circle()
                            .fill(Color.billixDarkTeal)
                            .frame(width: 16, height: 16)
                            .offset(x: markerPosition(in: geometry.size.width) - 8)  // Center the circle
                    }
                    .frame(height: 16)
                }
                .frame(height: 16)

                // Price labels
                HStack {
                    Text("$\(Int(lowRent))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.billixDarkTeal)
                        .monospacedDigit()

                    Spacer()

                    Text("$\(Int(highRent))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.billixDarkTeal)
                        .monospacedDigit()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    private func markerPosition(in width: CGFloat) -> CGFloat {
        // Calculate position based on average relative to low/high
        guard highRent > lowRent else { return 0 }

        let range = highRent - lowRent
        let position = (averageRent - lowRent) / range

        return CGFloat(position) * width
    }
}

// MARK: - Preview

#Preview("Average Rent Card") {
    VStack(spacing: 20) {
        AverageRentCard(
            averageRent: 1407,
            changePercent: 0.5,
            lowRent: 560,
            highRent: 3400
        )

        AverageRentCard(
            averageRent: 2200,
            changePercent: -3.2,
            lowRent: 1100,
            highRent: 4500
        )
    }
    .padding()
    .background(Color.billixCreamBeige)
}

//
//  PriceRangeBar.swift
//  Billix
//
//  Created by Claude Code on 1/12/26.
//  Simplified price range visualization for fintech aesthetic
//

import SwiftUI

struct PriceRangeBar: View {
    let low: Double
    let high: Double
    let average: Double

    private var averagePosition: CGFloat {
        guard high > low else { return 0.5 }
        return CGFloat((average - low) / (high - low))
    }

    var body: some View {
        VStack(spacing: 8) {
            // Labels above bar
            HStack {
                Text("Low Rent")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text("High Rent")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Gradient bar with average marker
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background gradient bar
                    LinearGradient(
                        colors: [
                            Color.billixMoneyGreen.opacity(0.3),
                            Color.billixGoldenAmber.opacity(0.4),
                            Color.billixStreakOrange.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .cornerRadius(4)

                    // Average marker dot
                    Circle()
                        .fill(Color.billixDarkTeal)
                        .frame(width: 16, height: 16)
                        .offset(x: geometry.size.width * averagePosition - 8)
                }
            }
            .frame(height: 16)

            // Price labels below bar
            HStack {
                Text("$\(Int(low))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .monospacedDigit()

                Spacer()

                Text("$\(Int(high))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Preview

struct PriceRangeBar_Price_Range_Bar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
        PriceRangeBar(
        low: 560,
        high: 3400,
        average: 1407
        )
        
        PriceRangeBar(
        low: 1200,
        high: 4800,
        average: 3200
        )
        
        PriceRangeBar(
        low: 800,
        high: 2500,
        average: 950
        )
        }
        .padding(20)
        .background(Color.white)
    }
}

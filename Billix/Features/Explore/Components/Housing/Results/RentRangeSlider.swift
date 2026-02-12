//
//  RentRangeSlider.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Visual low/estimate/high range slider with gradient bar
//

import SwiftUI

struct RentRangeSlider: View {
    let estimate: RentEstimateResult
    @State private var animatedPosition: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimate Range")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            // Range visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background gradient bar
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.billixMoneyGreen.opacity(0.3),
                                    Color.billixGoldenAmber.opacity(0.3),
                                    Color.billixStreakOrange.opacity(0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 12)

                    // Estimate position marker
                    Circle()
                        .fill(Color.billixDarkTeal)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .offset(x: geometry.size.width * animatedPosition - 10)
                }
            }
            .frame(height: 20)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animatedPosition = estimate.estimatePosition
                }
            }

            // Labels
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Low Est.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(Int(estimate.lowEstimate))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.billixMoneyGreen)
                        .monospacedDigit()
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("Estimate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(Int(estimate.estimatedRent))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.billixDarkTeal)
                        .monospacedDigit()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("High Est.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(Int(estimate.highEstimate))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.billixStreakOrange)
                        .monospacedDigit()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}

struct RentRangeSlider_Rent_Range_Slider_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        RentRangeSlider(
        estimate: RentEstimateResult(
        estimatedRent: 2450,
        lowEstimate: 2083,
        highEstimate: 2818,
        perSqft: 2.58,
        perBedroom: 1225,
        confidence: "High",
        comparablesCount: 15
        )
        )
        
        RentRangeSlider(
        estimate: RentEstimateResult(
        estimatedRent: 1650,
        lowEstimate: 1403,
        highEstimate: 1898,
        perSqft: 1.74,
        perBedroom: 825,
        confidence: "Medium",
        comparablesCount: 10
        )
        )
        
        RentRangeSlider(
        estimate: RentEstimateResult(
        estimatedRent: 3200,
        lowEstimate: 2720,
        highEstimate: 3680,
        perSqft: 3.37,
        perBedroom: 1600,
        confidence: "High",
        comparablesCount: 12
        )
        )
        }
        .padding()
        .background(Color.billixCreamBeige)
    }
}

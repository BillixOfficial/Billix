//
//  RentEstimatePanel.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Rent estimate panel with stat pills and breakdowns
//

import SwiftUI

struct RentEstimatePanel: View {
    let estimate: RentEstimateResult

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Average Rent")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.secondary)

            // Main estimate
            Text("$\(Int(estimate.estimatedRent))/mo")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.billixDarkTeal)
                .monospacedDigit()

            // Stat pills row
            HStack(spacing: 16) {
                StatPillSmall(
                    label: "per sq.ft.",
                    value: "$\(String(format: "%.2f", estimate.perSqft))"
                )

                StatPillSmall(
                    label: "per bedroom",
                    value: "$\(Int(estimate.perBedroom))"
                )
            }

            // Confidence badge
            HStack(spacing: 6) {
                Image(systemName: confidenceIcon)
                    .font(.system(size: 12, weight: .semibold))

                Text("\(estimate.confidence) Confidence")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(confidenceColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(confidenceColor.opacity(0.12))
            )
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
    }

    private var confidenceIcon: String {
        switch estimate.confidence {
        case "High": return "checkmark.seal.fill"
        case "Medium": return "exclamationmark.triangle.fill"
        default: return "questionmark.circle.fill"
        }
    }

    private var confidenceColor: Color {
        switch estimate.confidence {
        case "High": return .billixMoneyGreen
        case "Medium": return .billixGoldenAmber
        default: return .billixStreakOrange
        }
    }
}

// MARK: - Stat Pill Small

struct StatPillSmall: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.billixDarkTeal)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.billixDarkTeal.opacity(0.08))
        )
    }
}

// MARK: - Preview

struct RentEstimatePanel_Rent_Estimate_Panel_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        RentEstimatePanel(
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
        
        RentEstimatePanel(
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
        }
        .padding()
        .background(Color.billixCreamBeige)
    }
}

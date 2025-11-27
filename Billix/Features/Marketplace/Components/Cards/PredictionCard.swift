//
//  PredictionCard.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Card for prediction markets on bill rates and provider actions
struct PredictionCard: View {
    let prediction: PredictionMarket
    let onStakeYes: () -> Void
    let onStakeNo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(MarketplaceTheme.Colors.info)

                Text("PREDICTION")
                    .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.info)
                    .tracking(1)

                Spacer()

                // Time to resolution
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(prediction.timeToResolution)
                }
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }

            // Question
            Text(prediction.question)
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            // Current value context
            if let current = prediction.currentValue {
                Text("Current: \(formatValue(current))")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
            }

            // Odds visualization
            oddsBar

            // Stake buttons
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                // YES button
                Button(action: onStakeYes) {
                    VStack(spacing: 2) {
                        Text("YES")
                            .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                        Text(prediction.yesOdds)
                            .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MarketplaceTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                            .fill(MarketplaceTheme.Colors.success)
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                // NO button
                Button(action: onStakeNo) {
                    VStack(spacing: 2) {
                        Text("NO")
                            .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                        Text(prediction.noOdds)
                            .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MarketplaceTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                            .fill(MarketplaceTheme.Colors.danger)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Total staked
            HStack {
                Text("Total staked:")
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                Text("\(formatNumber(prediction.totalStaked)) pts")
                    .fontWeight(.semibold)
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                Spacer()

                Text("Your position: No stake")
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
            .font(.system(size: MarketplaceTheme.Typography.micro))
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.xl)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .stroke(MarketplaceTheme.Colors.info.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: MarketplaceTheme.Shadows.low.color,
            radius: MarketplaceTheme.Shadows.low.radius,
            x: MarketplaceTheme.Shadows.low.x,
            y: MarketplaceTheme.Shadows.low.y
        )
    }

    private var oddsBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // YES portion
                RoundedRectangle(cornerRadius: 4)
                    .fill(MarketplaceTheme.Colors.success)
                    .frame(width: geo.size.width * (prediction.yesPercent / 100))

                // NO portion
                RoundedRectangle(cornerRadius: 4)
                    .fill(MarketplaceTheme.Colors.danger)
                    .frame(width: geo.size.width * (prediction.noPercent / 100))
            }
        }
        .frame(height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func formatValue(_ value: Double) -> String {
        if value < 1 {
            return String(format: "$%.2f/kWh", value)
        }
        return String(format: "$%.0f", value)
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(MockMarketplaceData.predictions) { prediction in
            PredictionCard(
                prediction: prediction,
                onStakeYes: {},
                onStakeNo: {}
            )
        }
    }
    .padding()
    .background(MarketplaceTheme.Colors.backgroundPrimary)
}

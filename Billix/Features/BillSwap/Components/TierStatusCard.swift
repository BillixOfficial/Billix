//
//  TierStatusCard.swift
//  Billix
//
//  Displays user's current tier status with progress to next tier
//

import SwiftUI

struct TierStatusCard: View {
    let currentTier: Int
    let completedSwaps: Int
    var onLearnMore: (() -> Void)?

    private var tierColor: Color {
        SwapTheme.Tiers.tierColor(currentTier)
    }

    private var tierIcon: String {
        SwapTheme.Tiers.tierIcon(currentTier)
    }

    private var tierName: String {
        SwapTheme.Tiers.tierName(currentTier)
    }

    private var tierLimit: Decimal {
        SwapTheme.Tiers.maxAmount(for: currentTier)
    }

    private var formattedLimit: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: tierLimit as NSDecimalNumber) ?? "$\(tierLimit)"
    }

    private var swapsToNext: Int {
        SwapTheme.Tiers.swapsToNextTier(currentTier: currentTier, completedSwaps: completedSwaps)
    }

    private var nextTierRequirement: Int {
        SwapTheme.Tiers.requiredSwaps(for: currentTier + 1)
    }

    private var progress: Double {
        guard currentTier < 4 else { return 1.0 }
        let currentRequirement = SwapTheme.Tiers.requiredSwaps(for: currentTier)
        let nextRequirement = SwapTheme.Tiers.requiredSwaps(for: currentTier + 1)
        let progressRange = nextRequirement - currentRequirement
        let progressMade = completedSwaps - currentRequirement
        return Double(progressMade) / Double(progressRange)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top row: Tier badge + limit
            HStack(spacing: SwapTheme.Spacing.md) {
                // Tier icon
                ZStack {
                    Circle()
                        .fill(tierColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: tierIcon)
                        .font(.system(size: 20))
                        .foregroundColor(tierColor)
                }

                // Tier info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Tier \(currentTier)")
                            .font(SwapTheme.Typography.headline)
                            .foregroundColor(SwapTheme.Colors.primaryText)

                        Text("•")
                            .foregroundColor(SwapTheme.Colors.tertiaryText)

                        Text(tierName)
                            .font(SwapTheme.Typography.subheadline)
                            .foregroundColor(tierColor)
                    }

                    Text("Bills up to \(formattedLimit)")
                        .font(SwapTheme.Typography.caption)
                        .foregroundColor(SwapTheme.Colors.secondaryText)
                }

                Spacer()

                // Learn more button
                if let onLearnMore = onLearnMore {
                    Button(action: onLearnMore) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 20))
                            .foregroundColor(SwapTheme.Colors.primary)
                    }
                }
            }

            // Progress section (if not max tier)
            if currentTier < 4 {
                VStack(spacing: SwapTheme.Spacing.sm) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [tierColor.opacity(0.8), tierColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * max(0, min(1, progress)), height: 8)
                        }
                    }
                    .frame(height: 8)

                    // Progress text
                    HStack {
                        Text("\(completedSwaps) swaps completed")
                            .font(SwapTheme.Typography.caption)
                            .foregroundColor(SwapTheme.Colors.tertiaryText)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("\(swapsToNext)")
                                .font(SwapTheme.Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(tierColor)

                            Text("more to Tier \(currentTier + 1)")
                                .font(SwapTheme.Typography.caption)
                                .foregroundColor(SwapTheme.Colors.secondaryText)
                        }
                    }
                }
                .padding(.top, SwapTheme.Spacing.md)
            } else {
                // Max tier badge
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                        Text("Maximum Tier")
                            .font(SwapTheme.Typography.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(SwapTheme.Colors.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(SwapTheme.Colors.gold.opacity(0.12))
                    .cornerRadius(12)
                }
                .padding(.top, SwapTheme.Spacing.sm)
            }
        }
        .padding(SwapTheme.Spacing.lg)
        .background(
            ZStack {
                SwapTheme.Colors.background
                // Subtle tier-colored gradient overlay
                LinearGradient(
                    colors: [tierColor.opacity(0.04), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(SwapTheme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: SwapTheme.CornerRadius.large)
                .stroke(
                    LinearGradient(
                        colors: [tierColor.opacity(0.25), tierColor.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: SwapTheme.Shadows.medium.color,
            radius: SwapTheme.Shadows.medium.radius,
            x: SwapTheme.Shadows.medium.x,
            y: SwapTheme.Shadows.medium.y
        )
    }
}

// MARK: - Preview

#Preview("Tier 1 - New") {
    TierStatusCard(
        currentTier: 1,
        completedSwaps: 2,
        onLearnMore: {}
    )
    .padding()
}

#Preview("Tier 2 - Established") {
    TierStatusCard(
        currentTier: 2,
        completedSwaps: 8,
        onLearnMore: {}
    )
    .padding()
}

#Preview("Tier 3 - Trusted") {
    TierStatusCard(
        currentTier: 3,
        completedSwaps: 25,
        onLearnMore: {}
    )
    .padding()
}

#Preview("Tier 4 - Veteran (Max)") {
    TierStatusCard(
        currentTier: 4,
        completedSwaps: 50,
        onLearnMore: {}
    )
    .padding()
}

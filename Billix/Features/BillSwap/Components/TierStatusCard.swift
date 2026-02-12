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
        switch currentTier {
        case 1: return Color.billixBronzeTier
        case 2: return Color.billixSilverTier
        case 3: return Color.billixGoldTier
        case 4: return Color.billixGoldenAmber
        default: return Color.billixDarkTeal
        }
    }

    private var tierIcon: String {
        switch currentTier {
        case 1: return "leaf.fill"
        case 2: return "star.fill"
        case 3: return "star.circle.fill"
        case 4: return "crown.fill"
        default: return "circle.fill"
        }
    }

    private var tierName: String {
        switch currentTier {
        case 1: return "Neighbor"
        case 2: return "Contributor"
        case 3: return "Pillar"
        case 4: return "Guardian"
        default: return "Unknown"
        }
    }

    private var tierLimit: Decimal {
        switch currentTier {
        case 1: return 50
        case 2: return 150
        case 3: return 500
        case 4: return 1000
        default: return 50
        }
    }

    private var formattedLimit: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: tierLimit as NSDecimalNumber) ?? "$\(tierLimit)"
    }

    private func requiredSwaps(for tier: Int) -> Int {
        switch tier {
        case 1: return 0
        case 2: return 3
        case 3: return 10
        case 4: return 25
        default: return 0
        }
    }

    private var swapsToNext: Int {
        guard currentTier < 4 else { return 0 }
        let nextRequirement = requiredSwaps(for: currentTier + 1)
        return max(0, nextRequirement - completedSwaps)
    }

    private var progress: Double {
        guard currentTier < 4 else { return 1.0 }
        let currentRequirement = requiredSwaps(for: currentTier)
        let nextRequirement = requiredSwaps(for: currentTier + 1)
        let progressRange = nextRequirement - currentRequirement
        let progressMade = completedSwaps - currentRequirement
        return Double(progressMade) / Double(progressRange)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top row: Tier badge + limit
            HStack(spacing: 12) {
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
                            .font(.headline)
                            .foregroundColor(Color.billixDarkTeal)

                        Text("•")
                            .foregroundColor(.secondary.opacity(0.5))

                        Text(tierName)
                            .font(.subheadline)
                            .foregroundColor(tierColor)
                    }

                    Text("Bills up to \(formattedLimit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Learn more button
                if let onLearnMore = onLearnMore {
                    Button(action: onLearnMore) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color.billixDarkTeal)
                    }
                }
            }

            // Progress section (if not max tier)
            if currentTier < 4 {
                VStack(spacing: 8) {
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
                        Text("\(completedSwaps) connections completed")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))

                        Spacer()

                        HStack(spacing: 4) {
                            Text("\(swapsToNext)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(tierColor)

                            Text("more to Tier \(currentTier + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 12)
            } else {
                // Max tier badge
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                        Text("Maximum Tier")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color.billixGoldenAmber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.billixGoldenAmber.opacity(0.12))
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            ZStack {
                Color.billixCreamBeige
                // Subtle tier-colored gradient overlay
                LinearGradient(
                    colors: [tierColor.opacity(0.04), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [tierColor.opacity(0.25), tierColor.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

struct TierStatusCard_Tier_1___Neighbor_Previews: PreviewProvider {
    static var previews: some View {
        TierStatusCard(
        currentTier: 1,
        completedSwaps: 2,
        onLearnMore: {}
        )
        .padding()
    }
}

struct TierStatusCard_Tier_2___Contributor_Previews: PreviewProvider {
    static var previews: some View {
        TierStatusCard(
        currentTier: 2,
        completedSwaps: 8,
        onLearnMore: {}
        )
        .padding()
    }
}

struct TierStatusCard_Tier_3___Pillar_Previews: PreviewProvider {
    static var previews: some View {
        TierStatusCard(
        currentTier: 3,
        completedSwaps: 20,
        onLearnMore: {}
        )
        .padding()
    }
}

struct TierStatusCard_Tier_4___Guardian__Max__Previews: PreviewProvider {
    static var previews: some View {
        TierStatusCard(
        currentTier: 4,
        completedSwaps: 50,
        onLearnMore: {}
        )
        .padding()
    }
}

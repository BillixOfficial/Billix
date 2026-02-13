//
//  ConnectionStatsSheet.swift
//  Billix
//

import SwiftUI

struct ConnectionStatsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let requesterPoints: Int
    let supporterPoints: Int

    // Tier thresholds
    private let neighborMax = 99
    private let contributorMax = 499

    // Helper to get tier name from points
    private func tierName(for points: Int) -> String {
        switch points {
        case 0..<100: return "Neighbor"
        case 100..<500: return "Contributor"
        default: return "Pillar"
        }
    }

    // Helper to get tier color from points
    private func tierColor(for points: Int) -> Color {
        switch points {
        case 0..<100: return Color(hex: "#5B8A6B")      // Green - Neighbor
        case 100..<500: return Color(hex: "#9B7B9F")    // Purple - Contributor
        default: return Color(hex: "#E8B54D")           // Gold - Pillar
        }
    }

    // Progress to next tier (0.0 - 1.0)
    private func tierProgress(for points: Int) -> Double {
        switch points {
        case 0..<100:
            return Double(points) / 100.0
        case 100..<500:
            return Double(points - 100) / 400.0
        default:
            return 1.0 // At max tier
        }
    }

    // Points needed for next tier
    private func pointsToNextTier(for points: Int) -> Int? {
        switch points {
        case 0..<100:
            return 100 - points
        case 100..<500:
            return 500 - points
        default:
            return nil // Already at max
        }
    }

    // Next tier name
    private func nextTierName(for points: Int) -> String? {
        switch points {
        case 0..<100: return "Contributor"
        case 100..<500: return "Pillar"
        default: return nil
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Points Cards
                    HStack(spacing: 16) {
                        // Requester Card
                        PointsCard(
                            title: "Requester",
                            icon: "person.fill",
                            points: requesterPoints,
                            tierName: tierName(for: requesterPoints),
                            tierColor: tierColor(for: requesterPoints),
                            progress: tierProgress(for: requesterPoints),
                            pointsToNext: pointsToNextTier(for: requesterPoints),
                            nextTierName: nextTierName(for: requesterPoints)
                        )

                        // Supporter Card
                        PointsCard(
                            title: "Supporter",
                            icon: "heart.fill",
                            points: supporterPoints,
                            tierName: tierName(for: supporterPoints),
                            tierColor: tierColor(for: supporterPoints),
                            progress: tierProgress(for: supporterPoints),
                            pointsToNext: pointsToNextTier(for: supporterPoints),
                            nextTierName: nextTierName(for: supporterPoints)
                        )
                    }
                    .padding(.horizontal)

                    // Tier Benefits Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tier Benefits")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(HomeTheme.primaryText)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            TierBenefitRow(
                                tierName: "Neighbor",
                                tierColor: Color(hex: "#5B8A6B"),
                                pointRange: "0 - 99 pts",
                                benefits: [
                                    "Bills up to $25",
                                    "1 connection per month"
                                ],
                                isCurrentTier: requesterPoints < 100 || supporterPoints < 100
                            )

                            TierBenefitRow(
                                tierName: "Contributor",
                                tierColor: Color(hex: "#9B7B9F"),
                                pointRange: "100 - 499 pts",
                                benefits: [
                                    "Bills up to $150",
                                    "Unlimited connections"
                                ],
                                isCurrentTier: (requesterPoints >= 100 && requesterPoints < 500) || (supporterPoints >= 100 && supporterPoints < 500)
                            )

                            TierBenefitRow(
                                tierName: "Pillar",
                                tierColor: Color(hex: "#E8B54D"),
                                pointRange: "500+ pts",
                                benefits: [
                                    "Bills up to $500",
                                    "Community leader status"
                                ],
                                isCurrentTier: requesterPoints >= 500 || supporterPoints >= 500
                            )
                        }
                        .padding(.horizontal)
                    }

                    // How to Earn Points
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Earn Points")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(HomeTheme.primaryText)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            EarnPointRow(icon: "person.fill", color: Color(hex: "#5B8A6B"), text: "Requester: Complete bill payments as the requester")
                            EarnPointRow(icon: "heart.fill", color: Color(hex: "#E8B54D"), text: "Supporter: Help others by supporting their bills")
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(HomeTheme.background)
            .navigationTitle("Connection Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Points Card

private struct PointsCard: View {
    let title: String
    let icon: String
    let points: Int
    let tierName: String
    let tierColor: Color
    let progress: Double
    let pointsToNext: Int?
    let nextTierName: String?

    var body: some View {
        VStack(spacing: 12) {
            // Icon and Title
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tierColor)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HomeTheme.secondaryText)
            }

            // Points
            Text("\(points)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(HomeTheme.primaryText)

            // Tier Badge
            Text(tierName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(tierColor)
                .cornerRadius(12)

            // Progress Bar
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(tierColor)
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)

                if let pointsToNext = pointsToNext, let nextTier = nextTierName {
                    Text("\(pointsToNext) pts to \(nextTier)")
                        .font(.system(size: 10))
                        .foregroundColor(HomeTheme.secondaryText)
                } else {
                    Text("Max tier reached!")
                        .font(.system(size: 10))
                        .foregroundColor(tierColor)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8)
    }
}

// MARK: - Tier Benefit Row

private struct TierBenefitRow: View {
    let tierName: String
    let tierColor: Color
    let pointRange: String
    let benefits: [String]
    let isCurrentTier: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Tier Badge
            VStack(spacing: 4) {
                Circle()
                    .fill(tierColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: tierIcon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )

                Text(pointRange)
                    .font(.system(size: 9))
                    .foregroundColor(HomeTheme.secondaryText)
            }
            .frame(width: 60)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(tierName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(HomeTheme.primaryText)

                    if isCurrentTier {
                        Text("CURRENT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(tierColor)
                            .cornerRadius(4)
                    }
                }

                ForEach(benefits, id: \.self) { benefit in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(tierColor)
                        Text(benefit)
                            .font(.system(size: 13))
                            .foregroundColor(HomeTheme.secondaryText)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(isCurrentTier ? tierColor.opacity(0.08) : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentTier ? tierColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var tierIcon: String {
        switch tierName {
        case "Neighbor": return "house.fill"
        case "Contributor": return "star.fill"
        case "Pillar": return "crown.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - Earn Point Row

private struct EarnPointRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(HomeTheme.secondaryText)

            Spacer()
        }
    }
}

struct ConnectionStatsSheet_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionStatsSheet(requesterPoints: 75, supporterPoints: 150)
    }
}

//
//  DonationImpactCard.swift
//  Billix
//
//  Horizontal impact card for charitable donations
//  Features photography, impact-focused messaging, and outline button style
//

import SwiftUI

struct DonationImpactCard: View {
    let donation: Donation
    let userPoints: Int
    let onDonate: () -> Void

    private var canAfford: Bool {
        userPoints >= donation.pointsCost
    }

    private var accentColor: Color {
        Color(hex: donation.accentColor)
    }

    var body: some View {
        Button(action: onDonate) {
            HStack(spacing: 16) {
                // LEFT: Photo + Logo Badge
                ZStack(alignment: .bottomTrailing) {
                    // Circular photo placeholder (will use SF Symbols as placeholder for photography)
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.3),
                                        accentColor.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        // Placeholder icon (represents the photo subject)
                        Image(systemName: impactIcon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(accentColor)
                    }

                    // Charity logo badge
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.1), radius: 4)

                        Image(systemName: donation.logoName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                    .offset(x: 4, y: 4)
                }

                // MIDDLE: Charity Info & Impact
                VStack(alignment: .leading, spacing: 6) {
                    // Charity name
                    Text(donation.charityName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.billixDarkGreen)
                        .lineLimit(1)

                    // Impact title (the hook)
                    Text(donation.impactTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(accentColor)
                        .lineLimit(1)

                    // Impact description
                    Text(donation.impactDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                // RIGHT: Donate Button + Points
                VStack(spacing: 8) {
                    // Donate button (outline style)
                    Text("Donate")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(canAfford ? accentColor : .billixMediumGreen.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(
                                    canAfford ? accentColor : Color.billixMediumGreen.opacity(0.3),
                                    lineWidth: 2
                                )
                        )

                    // Points cost
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.billixArcadeGold)

                        Text("\(donation.pointsCost)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.billixMediumGreen)
                    }
                }
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    canAfford ? accentColor.opacity(0.2) : Color.billixBorderGreen,
                    lineWidth: 1
                )
        )
        .opacity(canAfford ? 1.0 : 0.7)
    }

    // Map category to representative icon
    private var impactIcon: String {
        switch donation.category {
        case .hunger:
            return "fork.knife.circle.fill"
        case .environment:
            return "leaf.circle.fill"
        case .animals:
            return "pawprint.circle.fill"
        case .education:
            return "book.circle.fill"
        case .health:
            return "heart.circle.fill"
        case .community:
            return "building.2.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack(spacing: 16) {
            DonationImpactCard(
                donation: Donation.previewDonations[0],
                userPoints: 2000,
                onDonate: {
                    print("Donate tapped")
                }
            )

            DonationImpactCard(
                donation: Donation.previewDonations[2],
                userPoints: 1500,
                onDonate: {
                    print("Donate tapped")
                }
            )

            DonationImpactCard(
                donation: Donation.previewDonations[4],
                userPoints: 3000,
                onDonate: {
                    print("Donate tapped")
                }
            )
        }
        .padding(20)
    }
}

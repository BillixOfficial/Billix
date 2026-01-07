//
//  EmptyStateView.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Gamified empty state for marketplace with no data
//

import SwiftUI

/// Empty state view when no marketplace data is available
struct MarketplaceEmptyState: View {

    // MARK: - Properties

    let location: Location
    let onUploadTapped: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Lock icon with map
            ZStack {
                Circle()
                    .fill(Color.billixPurple.opacity(0.1))
                    .frame(width: 140, height: 140)

                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.billixPurple)

                    Image(systemName: "map.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.billixDarkTeal.opacity(0.6))
                }
            }

            // Title and description
            VStack(spacing: 12) {
                Text("Be the First Explorer!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                Text("No marketplace data yet for \(location.displayName)")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("Upload a bill to unlock the marketplace and help your neighbors discover fair pricing.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }

            // Benefits cards
            HStack(spacing: 16) {
                BenefitCard(
                    icon: "star.fill",
                    title: "Earn Points",
                    subtitle: "Get rewarded"
                )

                BenefitCard(
                    icon: "chart.bar.fill",
                    title: "See Insights",
                    subtitle: "View trends"
                )

                BenefitCard(
                    icon: "person.2.fill",
                    title: "Help Others",
                    subtitle: "Build community"
                )
            }
            .padding(.horizontal)

            // Upload button
            Button(action: onUploadTapped) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Upload First Bill")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.billixGoldenAmber,
                                    Color.billixGoldenAmber.opacity(0.9)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.billixGoldenAmber.opacity(0.4), radius: 12, x: 0, y: 6)
                )
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.billixCreamBeige)
    }
}

// MARK: - Benefit Card

struct BenefitCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.billixGoldenAmber)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Previews

#Preview("Marketplace Empty State") {
    MarketplaceEmptyState(
        location: Location.defaultLocation,
        onUploadTapped: {
            print("Upload tapped")
        }
    )
}

#Preview("Empty State - SF") {
    MarketplaceEmptyState(
        location: Location.mockLocations[1],
        onUploadTapped: {}
    )
}

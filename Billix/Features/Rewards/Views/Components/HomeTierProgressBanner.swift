//
//  HomeTierProgressBanner.swift
//  Billix
//
//  Created by Claude Code
//  Home screen banner showing progress to Silver tier unlock
//  Only displays when user has < 8,000 points
//

import SwiftUI

struct HomeTierProgressBanner: View {
    let currentPoints: Int
    let targetPoints: Int = 8000
    @Binding var isDismissed: Bool
    let onEarnMoreTapped: () -> Void

    var progress: Double {
        min(Double(currentPoints) / Double(targetPoints), 1.0)
    }

    var pointsRemaining: Int {
        max(targetPoints - currentPoints, 0)
    }

    var shouldShow: Bool {
        currentPoints < targetPoints && !isDismissed
    }

    var body: some View {
        if shouldShow {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "target")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.billixMoneyGreen)

                            Text("Reach Silver Tier")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.billixDarkGreen)
                        }

                        Text("\(pointsRemaining) more points to Silver")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.billixMediumGreen)
                    }

                    Spacer()

                    // Dismiss button
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isDismissed = true
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.billixMediumGreen)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.billixMediumGreen.opacity(0.1))
                            )
                    }
                }

                // Progress bar
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.billixMediumGreen.opacity(0.15))
                        .frame(height: 12)

                    // Progress fill with gradient
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .billixMoneyGreen,
                                    .billixSilverTier
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: UIScreen.main.bounds.width * 0.85 * progress, height: 12)

                    // Points label on progress bar
                    HStack {
                        Spacer()
                        Text("\(currentPoints) / \(targetPoints)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(progress > 0.3 ? .white : .billixDarkGreen)
                            .padding(.horizontal, 12)
                    }
                }
                .frame(height: 12)

                // CTA button
                Button(action: onEarnMoreTapped) {
                    HStack(spacing: 6) {
                        Text("Earn more points")
                            .font(.system(size: 14, weight: .semibold))

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.billixMoneyGreen)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#Preview("Close to unlock (75%)") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack(spacing: 20) {
            HomeTierProgressBanner(
                currentPoints: 6000,
                isDismissed: .constant(false),
                onEarnMoreTapped: {}
            )

            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview("Just started (20%)") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack(spacing: 20) {
            HomeTierProgressBanner(
                currentPoints: 1600,
                isDismissed: .constant(false),
                onEarnMoreTapped: {}
            )

            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview("Almost there (95%)") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack(spacing: 20) {
            HomeTierProgressBanner(
                currentPoints: 7600,
                isDismissed: .constant(false),
                onEarnMoreTapped: {}
            )

            Spacer()
        }
        .padding(.top, 20)
    }
}

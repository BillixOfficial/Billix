//
//  SwapHubEntryCard.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Entry card for SwapHub displayed on HomeView
//

import SwiftUI

struct SwapHubEntryCard: View {
    @State private var showSwapHub = false
    @StateObject private var trustService = TrustLadderService.shared

    // Theme colors matching HomeView
    private let cardBackground = Color.white
    private let primaryText = Color(hex: "#2D3B35")
    private let secondaryText = Color(hex: "#8B9A94")
    private let accent = Color(hex: "#5B8A6B")

    var body: some View {
        Button {
            haptic()
            showSwapHub = true
        } label: {
            VStack(spacing: 0) {
                // Header with gradient
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.system(size: 18))
                            Text("Bill Swap")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(.white)

                        Text("Swap bills with trusted partners")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()

                    // Tier badge
                    tierBadge
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: tierColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                // Stats row
                HStack(spacing: 0) {
                    statItem(
                        icon: "checkmark.seal.fill",
                        value: "\(trustService.userTrustStatus?.totalSuccessfulSwaps ?? 0)",
                        label: "Swaps"
                    )

                    Divider()
                        .frame(height: 32)

                    statItem(
                        icon: "star.fill",
                        value: trustService.userTrustStatus?.formattedRating ?? "5.0",
                        label: "Rating"
                    )

                    Divider()
                        .frame(height: 32)

                    statItem(
                        icon: "shield.fill",
                        value: "\(trustService.userTrustStatus?.trustPoints ?? 0)",
                        label: "Points"
                    )
                }
                .padding(.vertical, 12)
                .background(cardBackground)

                // CTA
                HStack {
                    Text(ctaText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accent)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(accent.opacity(0.08))
            }
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showSwapHub) {
            SwapHubView()
        }
        .task {
            // Load trust status when card appears
            try? await trustService.fetchOrInitializeTrustStatus()
        }
    }

    private var tier: TrustTier {
        trustService.userTrustStatus?.tier ?? .streamer
    }

    private var tierColors: [Color] {
        tier.gradientColors
    }

    private var tierBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: tier.icon)
                .font(.system(size: 12))
            Text(tier.shortName)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.2))
        .cornerRadius(12)
    }

    private var ctaText: String {
        if trustService.userTrustStatus == nil {
            return "Get started with swapping"
        } else if (trustService.userTrustStatus?.totalSuccessfulSwaps ?? 0) == 0 {
            return "Start your first swap"
        } else {
            return "Find a swap partner"
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(accent)
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(primaryText)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func haptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "#F7F9F8").ignoresSafeArea()

        SwapHubEntryCard()
            .padding()
    }
}

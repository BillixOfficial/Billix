//
//  SeasonThemeBackground.swift
//  Billix
//
//  Created by Claude Code
//  Animated background system with season-specific themes
//

import SwiftUI

struct SeasonThemeBackground: View {
    let season: Season?
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            // Base background color
            Color(hex: "#F3F4F6")
                .ignoresSafeArea()

            // Subtle themed gradient overlay
            if let season = season {
                LinearGradient(
                    colors: gradientForSeason.map { $0.opacity(0.08) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Optional: Very subtle animated gradient shift
                if !reduceMotion {
                    LinearGradient(
                        colors: gradientForSeason.map { $0.opacity(0.05) },
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                    .ignoresSafeArea()
                    .opacity(0.5)
                }
            }
        }
    }

    // MARK: - Season-Specific Gradients

    private var gradientForSeason: [Color] {
        guard let season = season else {
            return defaultGradient
        }

        switch season.seasonNumber {
        case 1:
            // USA Roadtrip: Warm reds and oranges
            return [
                Color(hex: "#FF6B6B"),
                Color(hex: "#FF8E53")
            ]
        case 2:
            // Global: Cool teals and blues
            return [
                Color(hex: "#4ECDC4"),
                Color(hex: "#44A08D")
            ]
        default:
            return defaultGradient
        }
    }

    private var defaultGradient: [Color] {
        [
            Color.billixLightGreen,
            Color.billixMoneyGreen.opacity(0.3)
        ]
    }

    // MARK: - Season-Specific Particle Colors

    private var particleColorsForSeason: [Color] {
        guard let season = season else {
            return defaultParticleColors
        }

        switch season.seasonNumber {
        case 1:
            // USA: Warm whites and golds
            return [
                .white.opacity(0.8),
                Color(hex: "#FFD700").opacity(0.6)
            ]
        case 2:
            // Global: Cool whites and teals
            return [
                .white.opacity(0.8),
                Color(hex: "#4ECDC4").opacity(0.6)
            ]
        default:
            return defaultParticleColors
        }
    }

    private var defaultParticleColors: [Color] {
        [
            .white.opacity(0.8),
            Color.billixArcadeGold.opacity(0.6)
        ]
    }
}

// MARK: - Preview

#Preview("Season 1 Background") {
    SeasonThemeBackground(
        season: Season(
            id: UUID(),
            seasonNumber: 1,
            title: "USA Roadtrip",
            description: "Explore prices across America",
            isReleased: true,
            releaseDate: Date(),
            totalParts: 3,
            iconName: "flag.fill",
            createdAt: Date()
        )
    )
}

#Preview("Season 2 Background") {
    SeasonThemeBackground(
        season: Season(
            id: UUID(),
            seasonNumber: 2,
            title: "Global",
            description: "Price adventure around the world",
            isReleased: false,
            releaseDate: Date(),
            totalParts: 5,
            iconName: "globe.americas.fill",
            createdAt: Date()
        )
    )
}

#Preview("Default Background") {
    SeasonThemeBackground(season: nil)
}

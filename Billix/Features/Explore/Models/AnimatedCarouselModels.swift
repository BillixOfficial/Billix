//
//  AnimatedCarouselModels.swift
//  Billix
//
//  Created by Claude Code on 1/10/26.
//  Data models for animated explore carousel (3-card carousel)
//

import SwiftUI

/// Destination enum for carousel card navigation
enum ExploreDestination: Hashable {
    case economyByAI
    case housingTrends
    case bills
}

/// Card model for animated explore carousel
struct AnimatedExploreCardModel: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String // SF Symbol
    let imageName: String? // Optional PNG asset
    let accentColor: Color
    let backdropGradient: [Color]
    let destination: ExploreDestination
}

// MARK: - Mock Data

extension AnimatedExploreCardModel {
    static let mockCards: [AnimatedExploreCardModel] = [
        AnimatedExploreCardModel(
            title: "Housing Trends",
            description: "Explore market data, rent estimates, and comparables",
            icon: "house.fill",
            imageName: "MarketTrendsIcon",
            accentColor: .billixDarkTeal,
            backdropGradient: [
                Color(hex: "#5B8A6B").opacity(0.8),
                Color(hex: "#3D6B52").opacity(0.6)
            ],
            destination: .housingTrends
        )
    ]
}

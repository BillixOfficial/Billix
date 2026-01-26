//
//  AnimatedCarouselModels.swift
//  Billix
//
//  Created by Claude Code on 1/10/26.
//  Data models for animated explore carousel
//

import SwiftUI

/// Destination enum for carousel card navigation
enum ExploreDestination: Hashable {
    case economyByAI
    case housingTrends
    case bills
}

/// Filter pill model for active filters display
struct FilterPill: Identifiable {
    let id: String
    let label: String
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
    let categories: [String] // Category pills
    let buttonText: String // CTA button text
}

// MARK: - Mock Data

extension AnimatedExploreCardModel {
    static let mockCards: [AnimatedExploreCardModel] = [
        // Card 1: Community (FIRST)
        AnimatedExploreCardModel(
            title: "Community",
            description: "Join discussions, share tips, and connect with savers",
            icon: "person.3.fill",
            imageName: nil,
            accentColor: .billixPurple,
            backdropGradient: [
                Color(hex: "#9B7EBD").opacity(0.8),
                Color(hex: "#6B4E9B").opacity(0.6)
            ],
            destination: .economyByAI,
            categories: ["Posts", "Tips", "Discussion"],
            buttonText: "Join Community"
        ),

        // Card 2: Housing Trends (SECOND)
        AnimatedExploreCardModel(
            title: "Rent & Property\nCost",
            description: "Explore market data, rent estimates, and comparables",
            icon: "house.fill",
            imageName: "HouseExplore_OFFICIAL",
            accentColor: .billixDarkTeal,
            backdropGradient: [
                Color(hex: "#A8C7D8").opacity(0.8),
                Color(hex: "#7BA8C1").opacity(0.6)
            ],
            destination: .housingTrends,
            categories: ["Rent", "Property", "Trends"],
            buttonText: "Explore Housing"
        ),

        // Card 3: Bills Explorer (THIRD)
        AnimatedExploreCardModel(
            title: "Bills Explorer",
            description: "Analyze your bills and find savings opportunities",
            icon: "doc.text.fill",
            imageName: nil,
            accentColor: .billixMoneyGreen,
            backdropGradient: [
                Color(hex: "#7FB069").opacity(0.8),
                Color(hex: "#5A8C47").opacity(0.6)
            ],
            destination: .bills,
            categories: ["Bills", "Savings", "Insights"],
            buttonText: "Explore Bills"
        )
    ]
}

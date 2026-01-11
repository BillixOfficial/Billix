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
        // Card 1: Housing Trends (MOVED TO FIRST)
        AnimatedExploreCardModel(
            title: "Housing Trends",
            description: "Explore market data, rent estimates, and comparables",
            icon: "house.fill",
            imageName: "HouseExplore_OFFICIAL",
            accentColor: .billixDarkTeal,
            backdropGradient: [
                Color(hex: "#5B8A6B").opacity(0.8),
                Color(hex: "#3D6B52").opacity(0.6)
            ],
            destination: .housingTrends,
            categories: ["Housing", "Market", "Data"],
            buttonText: "View Trends"
        ),

        // Card 2: Bills Explorer (MOVED TO SECOND)
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
        ),

        // Card 3: Economy by AI (MOVED TO THIRD)
        AnimatedExploreCardModel(
            title: "Economy by AI",
            description: "AI-powered economic insights and forecasts",
            icon: "chart.line.uptrend.xyaxis",
            imageName: nil,
            accentColor: .billixPurple,
            backdropGradient: [
                Color(hex: "#9B7EBD").opacity(0.8),
                Color(hex: "#6B4E9B").opacity(0.6)
            ],
            destination: .economyByAI,
            categories: ["AI", "Economy", "Insights"],
            buttonText: "Explore AI"
        )
    ]
}

//
//  ExploreCarouselModels.swift
//  Billix
//
//  Models for the Explore page carousel design
//

import SwiftUI

// MARK: - Explore Theme

enum ExploreTheme {
    // Colors - Matching HomePage clean design
    static let background = Color(hex: "#F5F7F6")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#1A1D1C")
    static let secondaryText = Color(hex: "#6B7280")
    static let accent = Color(hex: "#10B981")

    // Category colors
    static let simulatorColor = Color(hex: "#F59E0B")  // Amber
    static let marketColor = Color(hex: "#10B981")     // Emerald
    static let toolsColor = Color(hex: "#6366F1")      // Indigo
    static let insightsColor = Color(hex: "#EC4899")   // Pink

    // Spacing
    static let horizontalPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 16
    static let cornerRadius: CGFloat = 20

    // Shadow
    static let shadowColor = Color.black.opacity(0.06)
}

// MARK: - Carousel Destination

enum CarouselDestination: Identifiable, Hashable {
    case recessionSimulator
    case makeMeMove
    case outageBot
    case billHeatmap
    case gougeIndex
    case marketplace
    case clusters
    case expertScripts
    case billAnalysis
    case savingsTracker

    var id: String {
        switch self {
        case .recessionSimulator: return "recession"
        case .makeMeMove: return "move"
        case .outageBot: return "outage"
        case .billHeatmap: return "heatmap"
        case .gougeIndex: return "gouge"
        case .marketplace: return "marketplace"
        case .clusters: return "clusters"
        case .expertScripts: return "scripts"
        case .billAnalysis: return "analysis"
        case .savingsTracker: return "savings"
        }
    }
}

// MARK: - Explore Sub-Feature

struct ExploreSubFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    let destination: CarouselDestination
}

// MARK: - Explore Feature Card

struct ExploreFeatureCard: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let description: String
    let icon: String
    let accentColor: Color
    let gradientColors: [Color]
    let subFeatures: [ExploreSubFeature]

    // MARK: - All Features

    static let allFeatures: [ExploreFeatureCard] = [
        // Simulators
        ExploreFeatureCard(
            title: "What-If Simulators",
            category: "Plan Ahead",
            description: "Model financial scenarios and prepare for the unexpected",
            icon: "gauge.with.dots.needle.33percent",
            accentColor: ExploreTheme.simulatorColor,
            gradientColors: [Color(hex: "#F59E0B"), Color(hex: "#D97706")],
            subFeatures: [
                ExploreSubFeature(
                    title: "Recession Simulator",
                    description: "See how your bills would change in an economic downturn",
                    icon: "chart.line.downtrend.xyaxis",
                    iconColor: Color(hex: "#EF4444"),
                    destination: .recessionSimulator
                ),
                ExploreSubFeature(
                    title: "Make Me Move",
                    description: "Calculate the true cost of relocating to a new area",
                    icon: "house.and.flag.fill",
                    iconColor: Color(hex: "#8B5CF6"),
                    destination: .makeMeMove
                ),
                ExploreSubFeature(
                    title: "Outage Bot",
                    description: "Get credits automatically when your services go down",
                    icon: "bolt.trianglebadge.exclamationmark.fill",
                    iconColor: Color(hex: "#F59E0B"),
                    destination: .outageBot
                )
            ]
        ),

        // Market Intelligence
        ExploreFeatureCard(
            title: "Market Intelligence",
            category: "Know Your Market",
            description: "See how your bills compare to others in your area",
            icon: "map.fill",
            accentColor: ExploreTheme.marketColor,
            gradientColors: [Color(hex: "#10B981"), Color(hex: "#059669")],
            subFeatures: [
                ExploreSubFeature(
                    title: "Bill Heatmap",
                    description: "Interactive map showing price zones across your region",
                    icon: "map.fill",
                    iconColor: Color(hex: "#10B981"),
                    destination: .billHeatmap
                ),
                ExploreSubFeature(
                    title: "Gouge Index",
                    description: "Find out which providers are overcharging in your area",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: Color(hex: "#EF4444"),
                    destination: .gougeIndex
                )
            ]
        ),

        // Marketplace
        ExploreFeatureCard(
            title: "Bill Marketplace",
            category: "Save Money",
            description: "Find deals, join clusters, and get expert help",
            icon: "storefront.fill",
            accentColor: ExploreTheme.toolsColor,
            gradientColors: [Color(hex: "#6366F1"), Color(hex: "#4F46E5")],
            subFeatures: [
                ExploreSubFeature(
                    title: "Browse Marketplace",
                    description: "Explore deals and offers from providers",
                    icon: "storefront.fill",
                    iconColor: Color(hex: "#6366F1"),
                    destination: .marketplace
                ),
                ExploreSubFeature(
                    title: "Join Clusters",
                    description: "Team up with neighbors for group discounts",
                    icon: "person.3.fill",
                    iconColor: Color(hex: "#8B5CF6"),
                    destination: .clusters
                ),
                ExploreSubFeature(
                    title: "Expert Scripts",
                    description: "Get proven negotiation scripts that work",
                    icon: "text.bubble.fill",
                    iconColor: Color(hex: "#EC4899"),
                    destination: .expertScripts
                )
            ]
        ),

        // Insights
        ExploreFeatureCard(
            title: "Bill Insights",
            category: "Understand",
            description: "Deep analysis of your spending patterns",
            icon: "chart.pie.fill",
            accentColor: ExploreTheme.insightsColor,
            gradientColors: [Color(hex: "#EC4899"), Color(hex: "#DB2777")],
            subFeatures: [
                ExploreSubFeature(
                    title: "Bill Analysis",
                    description: "AI-powered breakdown of your bills",
                    icon: "doc.text.magnifyingglass",
                    iconColor: Color(hex: "#EC4899"),
                    destination: .billAnalysis
                ),
                ExploreSubFeature(
                    title: "Savings Tracker",
                    description: "See how much you've saved over time",
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: Color(hex: "#10B981"),
                    destination: .savingsTracker
                )
            ]
        )
    ]
}

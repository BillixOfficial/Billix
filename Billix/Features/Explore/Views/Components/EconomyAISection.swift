//
//  EconomyAISection.swift
//  Billix
//
//  Created by Claude Code on 1/7/26.
//  Economy by AI section with 3 horizontal scrolling cards
//

import SwiftUI

struct EconomyAISection: View {
    let iconSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: -5) {
            // Section header
            Text("Economy by AI")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "#2D3B35"))
                .padding(.horizontal, 20)

            // 3-column static layout
            HStack(spacing: 12) {
                // Market Trends Card
                EconomyFeatureCard(
                    imageName: "MarketTrendsIcon",
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Market Trends",
                    accentColor: .billixDarkTeal,
                    iconSize: iconSize,
                    action: {
                        // Phase 2: Navigate to Market Trends view
                    }
                )

                // Global Finance Card
                EconomyFeatureCard(
                    imageName: "GlobalMoney",
                    icon: "globe.americas.fill",
                    title: "Global Finance",
                    accentColor: .billixPurple,
                    iconSize: iconSize,
                    action: {
                        // Phase 2: Navigate to Global Finance view
                    }
                )

                // Policy & Rates Card
                EconomyFeatureCard(
                    imageName: "PolicyIcon",
                    icon: "newspaper.fill",
                    title: "Policy & Rates",
                    accentColor: .billixMoneyGreen,
                    iconSize: iconSize,
                    action: {
                        // Phase 2: Navigate to Policy & Rates view
                    }
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview("Economy AI Section") {
    EconomyAISection(iconSize: 50)
        .background(Color.billixCreamBeige.opacity(0.3))
}

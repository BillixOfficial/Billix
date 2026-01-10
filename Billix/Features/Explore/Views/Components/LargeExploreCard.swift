//
//  LargeExploreCard.swift
//  Billix
//
//  Created by Claude Code on 1/7/26.
//  Large card component for See What Your Neighbors Pay section
//

import SwiftUI

struct LargeExploreCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let isActive: Bool
    let cardWidth: CGFloat
    let cardHeight: CGFloat

    var body: some View {
        // Just the PNG image, no overlays or text - adjustable width and height
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: cardWidth, height: cardHeight)
    }
}

#Preview("Large Cards") {
    VStack(spacing: 16) {
        LargeExploreCard(
            imageName: "HousingIcon",
            title: "Housing Trends",
            subtitle: "Rising Market",
            gradientColors: [Color.clear, Color.orange.opacity(0.8)],
            isActive: true,
            cardWidth: 150,
            cardHeight: 150
        )

        LargeExploreCard(
            imageName: "UtilityBillsIcon",
            title: "Bills & Cost",
            subtitle: "Monthly Overview",
            gradientColors: [Color.clear, Color.purple.opacity(0.8)],
            isActive: true,
            cardWidth: 150,
            cardHeight: 150
        )
    }
    .padding()
    .background(Color.billixCreamBeige.opacity(0.3))
}

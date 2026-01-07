//
//  ExploreFeatureCard.swift
//  Billix
//
//  Created by Claude Code on 1/7/26.
//  Small card component for Economy by AI section
//

import SwiftUI

struct EconomyFeatureCard: View {
    let imageName: String? // Optional PNG asset name
    let icon: String // SF Symbol fallback
    let title: String
    let accentColor: Color
    let iconSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: -20) {
                // Large icon at top - adjustable size
                if let imageName = imageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: iconSize)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: iconSize * 0.8))
                        .foregroundColor(accentColor)
                        .frame(height: iconSize)
                }

                // Small text at bottom, centered - very close to icon
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview("Economy Card") {
    HStack(spacing: 12) {
        EconomyFeatureCard(
            imageName: nil, // Will use SF Symbol fallback
            icon: "chart.line.uptrend.xyaxis",
            title: "Market Trends",
            accentColor: .billixDarkTeal,
            iconSize: 50,
            action: {}
        )

        EconomyFeatureCard(
            imageName: nil,
            icon: "globe.americas.fill",
            title: "Global Finance",
            accentColor: .billixPurple,
            iconSize: 50,
            action: {}
        )
    }
    .padding(.horizontal, 20)
    .background(Color.billixCreamBeige.opacity(0.3))
}

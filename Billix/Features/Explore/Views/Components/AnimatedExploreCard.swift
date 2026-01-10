//
//  AnimatedExploreCard.swift
//  Billix
//
//  Created by Claude Code on 1/10/26.
//  Individual card component for animated carousel
//

import SwiftUI

struct AnimatedExploreCard: View {
    let card: AnimatedExploreCardModel
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    var translateY: CGFloat = 0

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 35,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 35
        )
        .fill(.white)
        .frame(width: cardWidth, height: cardHeight)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        .overlay(
            cardContent
                .padding(24)
        )
        .offset(y: translateY)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            // Icon
            Image(systemName: card.icon)
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(card.accentColor)

            // Title
            Text(card.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)

            // Description
            Text(card.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .lineLimit(2)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Animated Explore Card") {
    AnimatedExploreCard(
        card: AnimatedExploreCardModel.mockCards[0],
        cardWidth: UIScreen.main.bounds.width * 0.72,
        cardHeight: UIScreen.main.bounds.height * 0.65
    )
    .padding()
    .background(Color.billixCreamBeige.opacity(0.3))
}

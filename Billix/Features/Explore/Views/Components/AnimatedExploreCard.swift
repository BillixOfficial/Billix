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
        // Blank card
        UnevenRoundedRectangle(
            topLeadingRadius: 35,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 35
        )
        .fill(.white)
        .frame(width: cardWidth, height: cardHeight)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        .offset(y: translateY)
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

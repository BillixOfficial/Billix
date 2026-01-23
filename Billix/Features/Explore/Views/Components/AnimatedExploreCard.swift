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
    var buttonBottomPadding: CGFloat = 138
    var placeholderHeightPercent: CGFloat = 0.46
    let namespace: Namespace.ID

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
        VStack(spacing: 0) {
            // Image container with rounded corners
            GeometryReader { geometry in
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(card.accentColor.opacity(0.1))

                    // Image or icon
                    Group {
                        if let imageName = card.imageName {
                            // Use actual image if provided - expand to fill and hide edges
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width * 1.3, height: geometry.size.height * 1.3)
                        } else {
                            // Fallback to SF Symbol
                            Image(systemName: card.icon)
                                .font(.system(size: 60, weight: .medium))
                                .foregroundColor(card.accentColor.opacity(0.3))
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .frame(height: cardHeight * placeholderHeightPercent)
            .padding(.top, 12)
            .padding(.horizontal, 12)

            // Content section
            VStack(spacing: 6) {
                // Title
                Text(card.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)

                // Category pills
                HStack(spacing: 8) {
                    ForEach(card.categories, id: \.self) { category in
                        Text(category)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.top, 6)
            }

            Spacer(minLength: 12)

            // CTA Button
            Text(card.buttonText.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.black)
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .padding(.bottom, buttonBottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AnimatedExploreCard_Preview: View {
    @Namespace private var namespace

    var body: some View {
        AnimatedExploreCard(
            card: AnimatedExploreCardModel.mockCards[0],
            cardWidth: UIScreen.main.bounds.width * 0.72,
            cardHeight: UIScreen.main.bounds.height * 0.65,
            namespace: namespace
        )
        .padding()
        .background(Color.billixCreamBeige.opacity(0.3))
    }
}

#Preview("Animated Explore Card") {
    AnimatedExploreCard_Preview()
}

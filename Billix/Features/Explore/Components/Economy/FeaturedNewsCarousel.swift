//
//  FeaturedNewsCarousel.swift
//  Billix
//
//  Created by Claude Code on 1/19/26.
//  Horizontal carousel for featured news articles with pagination
//

import SwiftUI

struct FeaturedNewsCarousel: View {
    let articles: [EconomyArticle]
    let onArticleTap: (EconomyArticle) -> Void

    @State private var currentIndex = 0

    // Design spec colors
    private let accentBlue = Color(hex: "#3B6CFF")

    // Card dimensions - sized to show next card peeking
    private let cardWidth: CGFloat = 310
    private let cardSpacing: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Text("Featured News")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)

            // Parallax Carousel with GeometryReader
            GeometryReader { outerGeo in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cardSpacing) {
                        ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                            GeometryReader { cardGeo in
                                let cardCenter = cardGeo.frame(in: .global).midX
                                let screenCenter = outerGeo.size.width / 2
                                let distance = abs(cardCenter - screenCenter)
                                let maxDistance: CGFloat = 200
                                let normalizedDistance = min(distance / maxDistance, 1.0)
                                let scale = 1.0 - (normalizedDistance * 0.20) // 100% to 80%

                                FeaturedNewsCard(article: article) {
                                    onArticleTap(article)
                                }
                                .scaleEffect(scale)
                                .animation(.easeOut(duration: 0.15), value: scale)
                                .onChange(of: scale) { _, newScale in
                                    // Update current index when card is closest to center
                                    if newScale > 0.95 {
                                        currentIndex = index
                                    }
                                }
                            }
                            .frame(width: cardWidth, height: 190)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12) // Extra padding for scale effect
                }
            }
            .frame(height: 214) // Card height + vertical padding

            // Pagination Dots - wider active indicator (4x width)
            HStack(spacing: 6) {
                ForEach(0..<min(articles.count, 5), id: \.self) { index in
                    if index == currentIndex {
                        // Active indicator - stadium/pill shape (4x wider)
                        Capsule()
                            .fill(accentBlue)
                            .frame(width: 24, height: 6)
                    } else {
                        // Inactive indicator - circle
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.2), value: currentIndex)
        }
    }
}


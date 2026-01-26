//
//
//  FeaturedNewsCard.swift
//  Billix
//
//  Created by Claude Code on 1/19/26.
//  Card component for featured news carousel - matches design spec
//

import SwiftUI

struct FeaturedNewsCard: View {
    let article: EconomyArticle
    let onTap: () -> Void



    // Design spec colors
    private let accentBlue = Color(hex: "#3B6CFF")

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Background Image with gradient overlay
                ZStack(alignment: .bottomLeading) {
                    // Real image or gradient fallback
                    if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 310, height: 190)
                                    .clipped()
                            case .failure, .empty:
                                gradientFallback
                            @unknown default:
                                gradientFallback
                            }
                        }
                        .frame(width: 310, height: 190)
                    } else {
                        gradientFallback
                    }

                    // Gradient overlay for text readability
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Content at bottom
                    VStack(alignment: .leading, spacing: 8) {
                        Spacer()

                        // Headline
                        Text(article.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        // Metadata row
                        HStack(spacing: 6) {
                            Text(article.source)
                                .font(.system(size: 13, weight: .medium))

                            Text("•")

                            Text(article.timeAgo)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(16)
                }

                // Floating Category Tag (top-right)
                Text(article.category.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentBlue)
                    )
                    .padding(12)
            }
            .frame(width: 310, height: 190) // Sized to show next card peeking
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
    }

    private func gradientColors(for category: EconomyCategory) -> [Color] {
        switch category {
        case .all:
            return [Color(hex: "#4158D0"), Color(hex: "#C850C0")]
        case .home:
            return [Color(hex: "#DA4453"), Color(hex: "#89216B")]
        case .prices:
            return [Color(hex: "#11998e"), Color(hex: "#38ef7d")]
        case .insurance:
            return [Color(hex: "#667eea"), Color(hex: "#764ba2")]
        }
    }

    private var gradientFallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradientColors(for: article.category),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: article.category.icon)
                .font(.system(size: 100))
                .foregroundColor(.white.opacity(0.15))
                .offset(x: 120, y: -40)
        }
    }
}


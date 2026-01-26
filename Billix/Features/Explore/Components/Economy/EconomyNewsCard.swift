//
//  EconomyNewsCard.swift
//  Billix
//
//  Created by Claude Code on 1/19/26.
//  Feed card for news articles - matches design spec
//

import SwiftUI

struct EconomyNewsCard: View {
    let article: EconomyArticle
    let onTap: () -> Void

    // Design spec colors
    private let metadataGrey = Color(hex: "#8E8E93")
    private let headlineBlack = Color(hex: "#1A1A1A")

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Thumbnail (Left) - Real image or gradient fallback
                if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            thumbnailFallback
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    thumbnailFallback
                }

                // Content (Right)
                VStack(alignment: .leading, spacing: 6) {
                    // Category Tag
                    Text(article.category.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(metadataGrey)

                    // Headline
                    Text(article.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(headlineBlack)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    // Author Row
                    HStack(spacing: 8) {
                        // Tiny Avatar
                        Circle()
                            .fill(Color(hex: "#3B6CFF").opacity(0.2))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text(String(article.author.prefix(1)))
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(Color(hex: "#3B6CFF"))
                            )

                        Text(article.author)
                            .font(.system(size: 12))
                            .foregroundColor(metadataGrey)

                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(metadataGrey)

                        Text(article.timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(metadataGrey)
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(height: 100)
        }
        .buttonStyle(.plain)
    }

    private func thumbnailGradient(for category: EconomyCategory) -> LinearGradient {
        let colors: [Color]
        switch category {
        case .all:
            colors = [Color(hex: "#4158D0"), Color(hex: "#C850C0")]
        case .home:
            colors = [Color(hex: "#DA4453"), Color(hex: "#89216B")]
        case .prices:
            colors = [Color(hex: "#11998e"), Color(hex: "#38ef7d")]
        case .insurance:
            colors = [Color(hex: "#667eea"), Color(hex: "#764ba2")]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var thumbnailFallback: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(thumbnailGradient(for: article.category))
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: article.category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.9))
            )
    }
}


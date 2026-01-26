//
//  EconomyArticleDetailView.swift
//  Billix
//
//  Created by Claude Code on 1/19/26.
//  Full article detail view - matches design spec
//

import SwiftUI

struct EconomyArticleDetailView: View {
    let article: EconomyArticle
    @Environment(\.dismiss) private var dismiss

    // Design spec colors
    private let accentBlue = Color(hex: "#3B6CFF")
    private let headlineBlack = Color(hex: "#1A1A1A")
    private let metadataGrey = Color(hex: "#8E8E93")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header Image
                    headerImage

                    // Content
                    VStack(alignment: .leading, spacing: 20) {
                        // Category Badge
                        Text(article.category.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(accentBlue)
                            )

                        // Title
                        Text(article.title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(headlineBlack)
                            .lineSpacing(4)

                        // Author Info Bar
                        authorInfoBar

                        Divider()
                            .padding(.vertical, 8)

                        // Article Body
                        Text(article.content)
                            .font(.system(size: 17))
                            .foregroundColor(headlineBlack.opacity(0.9))
                            .lineSpacing(8)

                        // Source Link & AI Disclaimer
                        sourceAndDisclaimerSection

                        // Tags/Related
                        relatedTagsSection

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(accentBlue)
                    }
                }
            }
        }
    }

    // MARK: - Header Image

    private var headerImage: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Real image or gradient fallback
                if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: 260)
                                .clipped()
                        default:
                            headerGradientFallback
                        }
                    }
                    .frame(width: geometry.size.width, height: 260)
                } else {
                    headerGradientFallback
                }

                // Dark gradient overlay for text readability
                LinearGradient(
                    colors: [.clear, .black.opacity(0.3)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Source badge
                Text(article.source)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.4))
                    )
                    .padding(20)
            }
        }
        .frame(height: 260)
        .clipped()
    }

    private var headerGradientFallback: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors(for: article.category),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 260)

            Image(systemName: article.category.icon)
                .font(.system(size: 100))
                .foregroundColor(.white.opacity(0.15))
                .offset(x: 180, y: -40)
        }
    }

    // MARK: - Author Info Bar

    private var authorInfoBar: some View {
        HStack(spacing: 12) {
            // Author Avatar
            Circle()
                .fill(accentBlue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(article.author.prefix(1)))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(accentBlue)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(article.author)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(headlineBlack)

                Text(article.formattedDate)
                    .font(.system(size: 13))
                    .foregroundColor(metadataGrey)
            }

            Spacer()

            // Reading time estimate
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 12))

                Text("\(readingTime) min read")
                    .font(.system(size: 13))
            }
            .foregroundColor(metadataGrey)
        }
    }

    // MARK: - Source and Disclaimer Section

    private var sourceAndDisclaimerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            // Source Link
            if let sourceURL = article.sourceURL {
                Link(destination: sourceURL) {
                    HStack(spacing: 10) {
                        Image(systemName: "newspaper")
                            .font(.system(size: 16))
                            .foregroundColor(accentBlue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Read Original Article")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(accentBlue)

                            Text("Source: \(article.source)")
                                .font(.system(size: 13))
                                .foregroundColor(metadataGrey)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                            .foregroundColor(accentBlue)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accentBlue.opacity(0.08))
                    )
                }
            }

            // AI Disclaimer
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(metadataGrey)

                Text("Analysis generated by Billix AI")
                    .font(.system(size: 13))
                    .foregroundColor(metadataGrey)
            }
            .padding(.top, 4)
        }
        .padding(.top, 20)
    }

    // MARK: - Related Tags Section

    private var relatedTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Topics")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(headlineBlack)

            FlowLayout(spacing: 8) {
                ForEach(relatedTags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 13))
                        .foregroundColor(accentBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(accentBlue.opacity(0.1))
                        )
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Helpers

    private var readingTime: Int {
        let wordCount = article.content.split(separator: " ").count
        return max(1, wordCount / 200)
    }

    private var relatedTags: [String] {
        switch article.category {
        case .all:
            return ["Economy", "News", "Finance"]
        case .home:
            return ["Rent Prices", "Utilities", "Mortgage Rates"]
        case .prices:
            return ["Food Prices", "Gas Prices", "Cost of Living"]
        case .insurance:
            return ["Health Insurance", "Auto Insurance", "Premiums"]
        }
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
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}


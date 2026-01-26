//
//  AllArticlesModalView.swift
//  Billix
//
//  Created by Claude Code on 1/24/26.
//  Modal view showing all articles for a category
//

import SwiftUI

struct AllArticlesModalView: View {
    let articles: [EconomyArticle]
    let category: EconomyCategory
    let onArticleTap: (EconomyArticle) -> Void

    @Environment(\.dismiss) private var dismiss

    // Design spec colors
    private let accentBlue = Color(hex: "#3B6CFF")
    private let headlineBlack = Color(hex: "#1A1A1A")

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(articles) { article in
                        EconomyNewsCard(article: article) {
                            onArticleTap(article)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.white)
            .navigationTitle(category == .all ? "All Articles" : "\(category.displayName) News")
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
}

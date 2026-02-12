//
//  EconomyNewsTabView.swift
//  Billix
//
//  Created by Claude Code on 1/24/26.
//  News tab content for Economy section (refactored from EconomyFeedView)
//

import SwiftUI

struct EconomyNewsTabView: View {
    @ObservedObject var viewModel: EconomyFeedViewModel
    @Binding var searchText: String
    @State private var showAllArticlesModal = false

    // Design spec colors
    private let accentBlue = Color(hex: "#3B6CFF")
    private let headlineBlack = Color(hex: "#1A1A1A")

    var searchFilteredArticles: [EconomyArticle] {
        if searchText.isEmpty {
            return viewModel.displayedArticles
        }
        return viewModel.displayedArticles.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.source.localizedCaseInsensitiveContains(searchText) ||
            $0.summary.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            // Background - clean white per design spec
            Color.white
                .ignoresSafeArea()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Featured News Carousel
                    if !viewModel.featuredNews.isEmpty {
                        FeaturedNewsCarousel(
                            articles: viewModel.featuredNews,
                            onArticleTap: { article in
                                viewModel.selectArticle(article)
                            }
                        )
                    }

                    // Category Filter Pills
                    EconomyFilterBar(
                        selected: $viewModel.selectedCategory
                    )

                    // Latest News Feed Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Latest News")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(headlineBlack)

                            Spacer()

                            // Show "See All" if there are more articles
                            if viewModel.hasMoreArticles {
                                Button {
                                    showAllArticlesModal = true
                                } label: {
                                    Text("See All")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(accentBlue)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Article Cards
                        if viewModel.isLoading {
                            loadingView
                        } else if searchFilteredArticles.isEmpty {
                            emptyStateView
                        } else {
                            LazyVStack(spacing: 20) {
                                ForEach(searchFilteredArticles) { article in
                                    EconomyNewsCard(article: article) {
                                        viewModel.selectArticle(article)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Bottom spacing
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.top, 16)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .sheet(item: $viewModel.selectedArticle) { article in
            EconomyArticleDetailView(article: article)
        }
        .sheet(isPresented: $showAllArticlesModal) {
            AllArticlesModalView(
                articles: viewModel.filteredArticles,
                category: viewModel.selectedCategory,
                onArticleTap: { article in
                    showAllArticlesModal = false
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        viewModel.selectArticle(article)
                    }
                }
            )
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { _ in
                loadingCard
            }
        }
        .padding(.horizontal, 20)
    }

    private var loadingCard: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 100, height: 100)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 10)
                    .frame(maxWidth: 60)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 14)
                    .frame(maxWidth: 180)

                Spacer()

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 20, height: 20)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 80, height: 10)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(height: 100)
        .shimmerEffect()
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.4))

            Text("No articles found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(headlineBlack)

            Text("Try adjusting your search\nor pull to refresh")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct EconomyNewsTabView_Economy_News_Tab_Previews: PreviewProvider {
    static var previews: some View {
        EconomyNewsTabView(viewModel: EconomyFeedViewModel(), searchText: .constant(""))
    }
}

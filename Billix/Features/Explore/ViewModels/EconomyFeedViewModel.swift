//
//  EconomyFeedViewModel.swift
//  Billix
//
//  Created by Claude Code on 1/19/26.
//  ViewModel for Economy by AI news feed
//

import Foundation
import SwiftUI

/// ViewModel for the Economy by AI news feed
/// Manages article data, filtering, and selection state
@MainActor
class EconomyFeedViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var featuredNews: [EconomyArticle] = []
    @Published var feedArticles: [EconomyArticle] = []
    @Published var selectedCategory: EconomyCategory = .all
    @Published var selectedArticle: EconomyArticle?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let newsService = EconomyNewsService.shared

    // MARK: - Computed Properties

    var filteredArticles: [EconomyArticle] {
        var articles = feedArticles

        // Filter by category
        if selectedCategory != .all {
            articles = articles.filter { $0.category == selectedCategory }
        }

        // Filter by search text
        if !searchText.isEmpty {
            articles = articles.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.summary.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }

        return articles
    }

    /// Articles to display on main feed (limited to 5)
    var displayedArticles: [EconomyArticle] {
        return Array(filteredArticles.prefix(5))
    }

    /// Whether there are more articles to show
    var hasMoreArticles: Bool {
        filteredArticles.count > 5
    }

    var userName: String {
        // Get user's display name from AuthService
        let displayName = AuthService.shared.currentUser?.displayName ?? "User"
        if !displayName.isEmpty && displayName != "User" {
            return displayName.components(separatedBy: " ").first ?? displayName
        }
        return "User"
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }

    // MARK: - Initialization

    init() {
        Task {
            await loadArticles()
        }
    }

    // MARK: - Data Loading

    /// Load articles from Supabase (or mock data for testing)
    func loadArticles() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch from Supabase in parallel
            async let featuredTask = newsService.fetchFeaturedNews(limit: 5)
            async let feedTask = newsService.fetchArticles(limit: 30)

            let (featured, feed) = try await (featuredTask, feedTask)

            featuredNews = featured
            feedArticles = feed
        } catch {
            errorMessage = "Unable to load articles. Please try again later."
        }

        isLoading = false
    }

    /// Refresh data (pull-to-refresh)
    func refresh() async {
        await loadArticles()
    }

    // MARK: - Article Selection

    func selectArticle(_ article: EconomyArticle) {
        selectedArticle = article
    }

    func dismissArticle() {
        selectedArticle = nil
    }
}

// MARK: - Time Formatting Extension

extension EconomyArticle {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: publishedAt)
    }
}

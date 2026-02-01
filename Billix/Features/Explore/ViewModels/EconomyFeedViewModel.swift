//
//  EconomyFeedViewModel.swift
//  Billix
//
//  Created by Claude Code on 1/19/26.
//  ViewModel for Economy by AI news feed
//

import Foundation
import SwiftUI
import Combine

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
    @Published private(set) var userName: String = "User"

    // MARK: - Private Properties

    private let newsService = EconomyNewsService.shared
    private var cancellables = Set<AnyCancellable>()

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
        // Subscribe to user changes for reactive name updates
        AuthService.shared.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.updateUserName(from: user)
            }
            .store(in: &cancellables)

        // Set initial user name
        updateUserName(from: AuthService.shared.currentUser)

        Task {
            await loadArticles()
        }
    }

    // MARK: - Private Methods

    private func updateUserName(from user: CombinedUser?) {
        let displayName = user?.displayName ?? "User"
        if !displayName.isEmpty && displayName != "User" {
            userName = displayName.components(separatedBy: " ").first ?? displayName
        } else {
            userName = "User"
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

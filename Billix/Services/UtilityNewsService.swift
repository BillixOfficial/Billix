//
//  UtilityNewsService.swift
//  Billix
//
//  Fetches daily utility/bill news from Supabase Edge Function
//  News is sourced from web search and summarized by OpenAI
//

import Foundation

// MARK: - Utility News Model

struct UtilityNews: Codable, Identifiable {
    let id: UUID
    let newsDate: String
    let headline: String
    let summary: String
    let sourceUrl: String?
    let sourceName: String?
    let category: String
    let region: String?
    let impactType: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case newsDate = "news_date"
        case headline, summary
        case sourceUrl = "source_url"
        case sourceName = "source_name"
        case category, region
        case impactType = "impact_type"
        case createdAt = "created_at"
    }

    // Category display info
    var categoryIcon: String {
        switch category.lowercased() {
        case "rates": return "chart.line.uptrend.xyaxis"
        case "policy": return "building.columns.fill"
        case "industry": return "bolt.fill"
        default: return "newspaper.fill"
        }
    }

    var categoryDisplayName: String {
        category.capitalized
    }

    var impactIcon: String? {
        switch impactType?.lowercased() {
        case "increase": return "arrow.up.circle.fill"
        case "decrease": return "arrow.down.circle.fill"
        default: return nil
        }
    }
}

// MARK: - Utility News Service

@MainActor
class UtilityNewsService: ObservableObject {

    // MARK: - Singleton
    static let shared = UtilityNewsService()

    // MARK: - Published Properties
    @Published var todaysNews: UtilityNews?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastFetchDate: Date?

    // MARK: - Private Properties
    private let supabase = SupabaseService.shared.client

    private init() {}

    // MARK: - Public Methods

    /// Fetch today's utility news (cycles daily through available news)
    func fetchTodaysNews() async {
        // Avoid duplicate fetches
        guard !isLoading else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Call the RPC function that returns today's rotating news
            let results: [UtilityNews] = try await supabase
                .rpc("get_todays_news")
                .execute()
                .value

            if let news = results.first {
                self.todaysNews = news
                self.lastFetchDate = Date()
                cacheNews(news)
            } else {
                // Fallback: try direct table query
                let fallbackResults: [UtilityNews] = try await supabase
                    .from("utility_news_cache")
                    .select()
                    .order("news_date", ascending: false)
                    .limit(1)
                    .execute()
                    .value

                if let recentNews = fallbackResults.first {
                    self.todaysNews = recentNews
                    self.lastFetchDate = Date()
                } else {
                    loadCachedNews()
                }
            }

        } catch {
            self.error = error
            print("❌ Failed to fetch utility news: \(error)")
            loadCachedNews()
        }
    }

    /// Force refresh news (bypasses local cache check)
    func refreshNews() async {
        await fetchTodaysNews()
    }

    // MARK: - Private Methods

    /// Load cached news from UserDefaults as fallback
    private func loadCachedNews() {
        guard let data = UserDefaults.standard.data(forKey: "cached_utility_news"),
              let news = try? JSONDecoder().decode(UtilityNews.self, from: data) else {
            return
        }

        // Only use cached news if it's less than 48 hours old
        if let created = news.createdAt,
           Date().timeIntervalSince(created) < 48 * 3600 {
            self.todaysNews = news
        }
    }

    /// Save news to local cache
    private func cacheNews(_ news: UtilityNews) {
        if let data = try? JSONEncoder().encode(news) {
            UserDefaults.standard.set(data, forKey: "cached_utility_news")
        }
    }
}

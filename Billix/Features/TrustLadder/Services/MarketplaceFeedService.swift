//
//  MarketplaceFeedService.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Service for managing the live marketplace activity feed
//

import Foundation
import Supabase
import Combine

// MARK: - Marketplace Feed Service

@MainActor
class MarketplaceFeedService: ObservableObject {

    // MARK: - Singleton
    static let shared = MarketplaceFeedService()

    // MARK: - Published Properties
    @Published var feedEvents: [MarketplaceFeedEvent] = []
    @Published var statistics: MarketplaceStatistics = .empty
    @Published var activityIndicator: ActivityIndicator = .fromCount(0)
    @Published var isLoading = false
    @Published var isLive = false

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var refreshTimer: Timer?
    private var filter: FeedFilter = .default

    // MARK: - Initialization

    private init() {
        Task {
            await loadFeed()
            await loadStatistics()
        }
    }

    // MARK: - Load Feed

    /// Loads recent feed events
    func loadFeed(limit: Int = 50) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let events: [MarketplaceFeedEvent] = try await supabase
                .from("marketplace_feed_events")
                .select()
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            feedEvents = events
            updateActivityIndicator()

        } catch {
            print("Failed to load feed: \(error)")
        }
    }

    /// Loads feed with filter
    func loadFeed(with filter: FeedFilter, limit: Int = 50) async {
        self.filter = filter
        isLoading = true
        defer { isLoading = false }

        do {
            var query = supabase
                .from("marketplace_feed_events")
                .select()

            // Apply filters
            if !filter.eventTypes.isEmpty && filter.eventTypes.count < FeedEventType.allCases.count {
                let types = filter.eventTypes.map { $0.rawValue }
                query = query.in("event_type", values: types)
            }

            if !filter.categories.isEmpty && filter.categories.count < ReceiptBillCategory.allCases.count {
                let cats = filter.categories.map { $0.rawValue }
                query = query.in("category", values: cats)
            }

            let events: [MarketplaceFeedEvent] = try await query
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            feedEvents = applyLocalFilters(events, filter: filter)
            updateActivityIndicator()

        } catch {
            print("Failed to load filtered feed: \(error)")
        }
    }

    /// Applies filters that can't be done in the query
    private func applyLocalFilters(_ events: [MarketplaceFeedEvent], filter: FeedFilter) -> [MarketplaceFeedEvent] {
        events.filter { event in
            // Amount range filter
            if !filter.amountRanges.isEmpty,
               let range = event.range,
               !filter.amountRanges.contains(range) {
                return false
            }
            return true
        }
    }

    // MARK: - Load Statistics

    /// Loads marketplace statistics
    func loadStatistics() async {
        do {
            // Get today's events
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let formatter = ISO8601DateFormatter()

            let todayEvents: [MarketplaceFeedEvent] = try await supabase
                .from("marketplace_feed_events")
                .select()
                .gte("created_at", value: formatter.string(from: startOfDay))
                .execute()
                .value

            // Calculate stats
            let completedSwaps = todayEvents.filter { $0.type == .swapCompleted }.count

            // Calculate volume by category
            var volumeByCategory: [String: Int] = [:]
            for event in todayEvents {
                if let category = event.category {
                    volumeByCategory[category, default: 0] += 1
                }
            }

            // Determine hot categories
            let hotCategories = volumeByCategory
                .sorted { $0.value > $1.value }
                .prefix(3)
                .map { HotCategory(category: $0.key, listingCount: $0.value, trend: Double.random(in: -20...50)) }

            statistics = MarketplaceStatistics(
                totalActiveListings: todayEvents.filter { $0.type == .newListing }.count,
                swapsCompletedToday: completedSwaps,
                averageMatchTime: Double.random(in: 1800...7200), // Mock: 30min - 2hr
                hotCategories: Array(hotCategories),
                volumeByCategory: volumeByCategory
            )

        } catch {
            print("Failed to load statistics: \(error)")
        }
    }

    // MARK: - Live Updates

    /// Starts live feed updates
    func startLiveUpdates(interval: TimeInterval = 30) {
        isLive = true
        refreshTimer?.invalidate()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                await self?.loadFeed()
            }
        }
    }

    /// Stops live feed updates
    func stopLiveUpdates() {
        isLive = false
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Record Event

    /// Records a new marketplace event (called internally when swaps occur)
    func recordEvent(
        type: FeedEventType,
        category: ReceiptBillCategory? = nil,
        amount: Decimal? = nil,
        zipPrefix: String? = nil,
        metadata: FeedEventMetadata? = nil
    ) async {
        let amountRange = amount.map { AmountRange.range(for: $0).rawValue }

        let insert = FeedEventInsert(
            eventType: type.rawValue,
            category: category?.rawValue,
            amountRange: amountRange,
            zipPrefix: zipPrefix,
            metadata: metadata
        )

        do {
            try await supabase
                .from("marketplace_feed_events")
                .insert(insert)
                .execute()

            // Reload feed
            await loadFeed()

        } catch {
            print("Failed to record event: \(error)")
        }
    }

    // MARK: - Activity Indicator

    /// Updates the activity indicator based on recent events
    private func updateActivityIndicator() {
        let recentCount = feedEvents.filter { event in
            event.createdAt > Date().addingTimeInterval(-3600) // Last hour
        }.count

        activityIndicator = ActivityIndicator.fromCount(recentCount)
    }

    // MARK: - Filtered Accessors

    /// Gets events by type
    func events(ofType type: FeedEventType) -> [MarketplaceFeedEvent] {
        feedEvents.filter { $0.type == type }
    }

    /// Gets events by category
    func events(for category: ReceiptBillCategory) -> [MarketplaceFeedEvent] {
        feedEvents.filter { $0.billCategory == category }
    }

    /// Gets recent events (last N)
    func recentEvents(_ count: Int) -> [MarketplaceFeedEvent] {
        Array(feedEvents.prefix(count))
    }

    // MARK: - Category Insights

    /// Gets activity level for a category
    func activityLevel(for category: ReceiptBillCategory) -> ActivityIndicator.ActivityLevel {
        let count = statistics.volumeByCategory[category.rawValue] ?? 0
        return ActivityIndicator.fromCount(count).level
    }

    /// Gets if a category is hot
    func isHot(_ category: ReceiptBillCategory) -> Bool {
        statistics.hotCategories.contains { $0.category == category.rawValue }
    }

    // MARK: - Cleanup

    /// Cleans up old events (would be called by backend job)
    func cleanupOldEvents(olderThan days: Int = 7) async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let formatter = ISO8601DateFormatter()

        do {
            try await supabase
                .from("marketplace_feed_events")
                .delete()
                .lt("created_at", value: formatter.string(from: cutoffDate))
                .execute()
        } catch {
            print("Failed to cleanup old events: \(error)")
        }
    }

    // MARK: - Reset

    func reset() {
        feedEvents = []
        statistics = .empty
        stopLiveUpdates()
    }

    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - Preview Helpers

extension MarketplaceFeedService {
    static func mockWithEvents() -> MarketplaceFeedService {
        let service = MarketplaceFeedService.shared
        // Would add mock events for previews
        return service
    }
}

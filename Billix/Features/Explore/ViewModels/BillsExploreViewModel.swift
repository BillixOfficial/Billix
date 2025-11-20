import Foundation
import SwiftUI

/// ViewModel for the Bills Explore page
/// Manages marketplace data fetching, filtering, and pagination
@MainActor
class BillsExploreViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var marketplaceData: [MarketplaceData] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: NetworkError?

    // Filters
    @Published var selectedCategory: String?
    @Published var selectedZipPrefix: String?
    @Published var selectedSort: SortOption = .priceAsc

    // Stats
    @Published var totalProviders: Int = 0
    @Published var averageSavings: Double = 0
    @Published var totalSamples: Int = 0

    // MARK: - Private Properties

    private let service = MarketplaceService.shared
    private var allCategories: [String] = []

    // MARK: - Computed Properties

    var filteredData: [MarketplaceData] {
        marketplaceData
    }

    var hasData: Bool {
        !marketplaceData.isEmpty
    }

    var errorMessage: String? {
        error?.userFriendlyMessage
    }

    // MARK: - Initialization

    init() {
        // Load categories immediately (hardcoded list, no API call, synchronous)
        self.allCategories = ["Electric", "Internet", "Water", "Gas", "Phone", "Cable"].sorted()

        // Don't load data on init - wait for user to enter ZIP code
        // User must use filter bar to enter ZIP code first
    }

    // MARK: - Data Loading

    /// Load initial marketplace data
    func loadInitialData() async {
        isLoading = true
        error = nil

        do {
            // Fetch data with current filters
            let data = try await service.fetchMarketplaceData(
                zipPrefix: selectedZipPrefix,
                category: selectedCategory,
                sort: selectedSort.apiValue
            )

            marketplaceData = data
            calculateStats(from: data)

        } catch let networkError as NetworkError {
            error = networkError
            print("❌ Error loading marketplace data: \(networkError.localizedDescription)")
        } catch {
            self.error = .networkError(error)
            print("❌ Unexpected error: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Refresh data (pull-to-refresh)
    func refresh() async {
        isRefreshing = true
        error = nil

        // Don't refresh if no ZIP code entered
        guard selectedZipPrefix != nil else {
            isRefreshing = false
            return
        }

        do {
            // Force refresh from network
            let data = try await service.fetchMarketplaceData(
                zipPrefix: selectedZipPrefix,
                category: selectedCategory,
                sort: selectedSort.apiValue,
                forceRefresh: true
            )

            marketplaceData = data
            calculateStats(from: data)

        } catch let networkError as NetworkError {
            error = networkError
            print("❌ Refresh error (NetworkError): \(networkError.localizedDescription)")
        } catch {
            // Check if the error is a cancellation (normal when pulling to refresh quickly)
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                print("ℹ️ Refresh request was cancelled (normal behavior)")
                // Don't set error for cancelled requests
            } else {
                self.error = .networkError(error)
                print("❌ Refresh error (Other): \(error.localizedDescription)")
            }
        }

        isRefreshing = false
    }

    // MARK: - Filtering

    /// Apply category filter
    func applyCategory(_ category: String?) async {
        selectedCategory = category
        await loadInitialData()
    }

    /// Apply ZIP code filter
    func applyZipPrefix(_ zipPrefix: String?) async {
        selectedZipPrefix = zipPrefix
        await loadInitialData()
    }

    /// Apply sort option
    func applySort(_ sort: SortOption) async {
        selectedSort = sort
        await loadInitialData()
    }

    /// Clear all filters
    func clearFilters() async {
        selectedCategory = nil
        selectedZipPrefix = nil
        selectedSort = .priceAsc

        // Clear data instead of reloading (since no ZIP = can't load)
        marketplaceData = []
        totalProviders = 0
        averageSavings = 0
        totalSamples = 0
        error = nil
    }

    var activeFilterCount: Int {
        var count = 0
        if selectedCategory != nil { count += 1 }
        if selectedZipPrefix != nil { count += 1 }
        if selectedSort != .priceAsc { count += 1 }
        return count
    }

    // MARK: - Stats Calculation

    private func calculateStats(from data: [MarketplaceData]) {
        totalProviders = data.count
        totalSamples = data.reduce(0) { $0 + $1.sampleSize }

        // Calculate average savings (difference between max and min)
        let savings = data.map { $0.maxAmount - $0.minAmount }
        averageSavings = savings.isEmpty ? 0 : savings.reduce(0, +) / Double(savings.count)
    }

    // MARK: - Helper Methods

    func getCategories() -> [String] {
        allCategories
    }
}

// MARK: - Sort Option

enum SortOption: String, CaseIterable {
    case priceAsc = "Price: Low to High"
    case priceDesc = "Price: High to Low"
    case samples = "Most Samples"

    var apiValue: String {
        switch self {
        case .priceAsc:
            return "price_asc"
        case .priceDesc:
            return "price_desc"
        case .samples:
            return "samples_desc"
        }
    }

    var icon: String {
        switch self {
        case .priceAsc:
            return "arrow.up"
        case .priceDesc:
            return "arrow.down"
        case .samples:
            return "chart.bar.fill"
        }
    }
}

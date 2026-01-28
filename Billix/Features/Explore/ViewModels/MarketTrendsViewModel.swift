//
//  MarketTrendsViewModel.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  State management for Market Trends tab
//

import Foundation
import Combine

// MARK: - Market Content Tab

enum MarketContentTab: String, CaseIterable, Identifiable {
    case breakdown = "Breakdown"
    case summary = "Summary"

    var id: String { rawValue }
}

@MainActor
class MarketTrendsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var marketData: MarketTrendsData?
    @Published var historyData: [RentHistoryPoint] = []
    @Published var selectedTimeRange: TimeRange = .oneYear
    @Published var isLoading: Bool = false
    @Published var currentLocation: String = ""
    @Published var selectedContentTab: MarketContentTab = .breakdown

    // Chart interaction state
    @Published var selectedDataPoint: RentHistoryPoint?
    @Published var isScrubbingChart: Bool = false

    // Bedroom type filtering
    @Published var selectedBedroomTypes: Set<BedroomType> = []

    // MARK: - Shared State

    weak var housingViewModel: HousingSearchViewModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var filteredHistoryData: [RentHistoryPoint] {
        let cutoffDate = Calendar.current.date(
            byAdding: .month,
            value: -selectedTimeRange.monthsBack,
            to: Date()
        ) ?? Date()

        return historyData.filter { $0.date >= cutoffDate }
    }

    var averageOnlyHistoryData: [RentHistoryPoint] {
        filteredHistoryData.filter { $0.bedroomType == .average }
    }

    var chartHistoryData: [RentHistoryPoint] {
        if selectedBedroomTypes.isEmpty {
            // NEW: Show average line when nothing selected (cleaner default)
            return filteredHistoryData.filter { $0.bedroomType == .average }
        } else {
            // Show only selected types
            return filteredHistoryData.filter { selectedBedroomTypes.contains($0.bedroomType) }
        }
    }

    // MARK: - Initialization

    init(housingViewModel: HousingSearchViewModel? = nil) {
        self.housingViewModel = housingViewModel
        // Location sync is handled by the View's .task modifier to avoid duplicate API calls
    }

    // MARK: - RentCast Service

    private let rentCastService = RentCastEdgeFunctionService.shared

    // MARK: - Data Loading

    func loadMarketTrends(for location: String) async {
        guard !location.isEmpty else { return }

        isLoading = true
        currentLocation = location

        do {
            // Step 1: Get zip code (from string or via geocoding)
            var zipCode: String? = extractZipCode(from: location)

            if zipCode == nil {
                // Use Apple geocoding to find zip code (free)
                zipCode = await GeocodingService.shared.getZipCode(from: location)
            }

            guard let resolvedZipCode = zipCode else {
                isLoading = false
                return
            }

            // Step 2: Check shared cache first (same cache as Housing tab)
            let cacheKey = CacheKey.rentCastMarketStats(zipCode: resolvedZipCode)
            if let cachedResponse: RentCastMarketResponse = await CacheManager.shared.get(cacheKey) {
                marketData = cachedResponse.toMarketTrendsData(location: location)
                historyData = cachedResponse.toHistoryData()
                isLoading = false
                return
            }

            // Step 3: Fetch from RentCast via Edge Function
            let response = try await rentCastService.fetchMarketStatistics(
                zipCode: resolvedZipCode,
                historyRange: 60
            )

            // Step 4: Store in shared cache
            await CacheManager.shared.set(cacheKey, value: response)

            // Convert to Billix models
            marketData = response.toMarketTrendsData(location: location)
            historyData = response.toHistoryData()

        } catch {
            // Show error - NO FALLBACK to mock data
            marketData = nil
            historyData = []
        }

        isLoading = false
    }

    private func extractZipCode(from location: String) -> String? {
        // Try to find a 5-digit zip code in the string
        let pattern = "\\d{5}"
        if let range = location.range(of: pattern, options: .regularExpression) {
            return String(location[range])
        }
        return nil
    }

    func updateLocation(_ location: String) {
        guard location != currentLocation && !location.isEmpty else { return }

        Task {
            await loadMarketTrends(for: location)
        }
    }

    func changeTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
    }

    func toggleBedroomType(_ type: BedroomType) {
        if selectedBedroomTypes.contains(type) {
            selectedBedroomTypes.remove(type)
        } else {
            selectedBedroomTypes.insert(type)
        }
    }
}

//
//  MarketTrendsViewModel.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  State management for Market Trends tab
//

import Foundation
import Combine

@MainActor
class MarketTrendsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var marketData: MarketTrendsData?
    @Published var historyData: [RentHistoryPoint] = []
    @Published var selectedTimeRange: TimeRange = .oneYear
    @Published var isLoading: Bool = false
    @Published var currentLocation: String = ""

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

    // MARK: - Initialization

    init(housingViewModel: HousingSearchViewModel? = nil) {
        self.housingViewModel = housingViewModel

        // Subscribe to location changes from Housing tab
        if let housingVM = housingViewModel {
            housingVM.$activeLocation
                .sink { [weak self] newLocation in
                    guard let self = self else { return }
                    if !newLocation.isEmpty {
                        self.updateLocation(newLocation)
                    }
                }
                .store(in: &cancellables)

            housingVM.$searchQuery
                .sink { [weak self] query in
                    guard let self = self else { return }
                    if !query.isEmpty && query != self.currentLocation {
                        self.updateLocation(query)
                    }
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Data Loading

    func loadMarketTrends(for location: String) async {
        guard !location.isEmpty else { return }

        isLoading = true
        currentLocation = location

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

        // Generate mock data
        marketData = MarketTrendsMockData.generateMarketData(location: location)
        historyData = MarketTrendsMockData.generateHistoryData(
            location: location,
            monthsBack: 24
        )

        isLoading = false
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
}

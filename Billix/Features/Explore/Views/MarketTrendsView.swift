//
//  MarketTrendsView.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  Main view for Market Trends tab with rental market analytics
//

import SwiftUI

struct MarketTrendsView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var housingViewModel: HousingSearchViewModel
    @StateObject private var viewModel: MarketTrendsViewModel
    let onSwitchToHousing: () -> Void

    init(
        locationManager: LocationManager,
        housingViewModel: HousingSearchViewModel,
        onSwitchToHousing: @escaping () -> Void
    ) {
        self.locationManager = locationManager
        self.housingViewModel = housingViewModel
        self.onSwitchToHousing = onSwitchToHousing
        _viewModel = StateObject(wrappedValue: MarketTrendsViewModel(housingViewModel: housingViewModel))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    loadingView
                } else if let data = viewModel.marketData {
                    // Ticker Header (replaces AverageRentCard)
                    TickerHeaderView(
                        averageRent: data.averageRent,
                        changePercent: data.yearOverYearChange,
                        lowRent: data.lowRent,
                        highRent: data.highRent
                    )
                    .padding(.horizontal, 20)

                    // Time range selector
                    TimeRangeSelector(selectedRange: $viewModel.selectedTimeRange)
                        .padding(.horizontal, 20)

                    // Chart (shown for both tabs)
                    RentHistoryChart(
                        historyData: viewModel.selectedContentTab == .summary
                            ? viewModel.averageOnlyHistoryData
                            : viewModel.chartHistoryData,
                        timeRange: viewModel.selectedTimeRange,
                        chartMode: viewModel.selectedContentTab == .summary
                            ? .averageOnly
                            : .allTypes,
                        selectedBedroomTypes: viewModel.selectedBedroomTypes,
                        selectedDataPoint: $viewModel.selectedDataPoint,
                        isScrubbing: $viewModel.isScrubbingChart
                    )

                    // Tab Picker (Summary | Breakdown) - BELOW chart
                    MarketContentTabPicker(selectedTab: $viewModel.selectedContentTab)

                    // Conditional Content based on selected tab
                    if viewModel.selectedContentTab == .breakdown {
                        // BREAKDOWN TAB - Bedroom Breakdown Grid
                        BedroomBreakdownGrid(
                            stats: data.bedroomStats,
                            selectedBedroomTypes: viewModel.selectedBedroomTypes,
                            onBedroomTap: { type in
                                viewModel.toggleBedroomType(type)
                            }
                        )
                        .padding(.horizontal, 20)
                    } else {
                        // SUMMARY TAB - Market Overview
                        MarketSummaryView(
                            marketData: data,
                            marketHealth: calculateMarketHealth(changePercent: data.yearOverYearChange)
                        )
                        .padding(.horizontal, 20)
                    }
                } else {
                    emptyStateView
                }
            }
            .padding(.bottom, 100)  // Extra padding for bottom nav bar
        }
        .background(Color(hex: "F8F9FA").ignoresSafeArea())
        .task {
            // Auto-load NYC on first appear
            if viewModel.marketData == nil {
                await viewModel.loadMarketTrends(for: "New York, NY 10001")
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.billixDarkTeal)

            Text("Loading market trends...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.billixDarkTeal.opacity(0.3))

            Text("No Market Data Available")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)

            Text("Select a location to view market trends")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Helpers

    private func calculateMarketHealth(changePercent: Double) -> MarketHealth {
        if changePercent > 5.0 {
            return .hot
        } else if changePercent < -5.0 {
            return .cool
        } else {
            return .moderate
        }
    }

    private func navigateToHousingTab(with data: MarketTrendsData) {
        // Set filters on Housing tab
        housingViewModel.activeLocation = data.location
        housingViewModel.activePriceRange = data.lowRent...data.highRent

        // Trigger tab switch
        onSwitchToHousing()
    }
}

// MARK: - Preview

#Preview("Market Trends View") {
    MarketTrendsView(
        locationManager: LocationManager.preview(),
        housingViewModel: HousingSearchViewModel(),
        onSwitchToHousing: {
            print("Navigate to Housing tab")
        }
    )
}

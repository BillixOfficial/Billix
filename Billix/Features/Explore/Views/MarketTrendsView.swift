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
            VStack(spacing: 12) {  // Compact spacing to fit everything on one screen
                if viewModel.isLoading {
                    loadingView
                } else if let data = viewModel.marketData {
                    // Ticker Header (now more compact)
                    TickerHeaderView(
                        averageRent: data.averageRent,
                        changePercent: data.yearOverYearChange,
                        lowRent: data.lowRent,
                        highRent: data.highRent
                    )
                    .padding(.horizontal, 20)

                    // Chart with inline time selector in header
                    RentHistoryChart(
                        historyData: viewModel.chartHistoryData,
                        timeRange: $viewModel.selectedTimeRange,
                        chartMode: .allTypes,
                        selectedBedroomTypes: viewModel.selectedBedroomTypes,
                        selectedDataPoint: $viewModel.selectedDataPoint,
                        isScrubbing: $viewModel.isScrubbingChart,
                        lineOnlyMode: false  // Enable gradient shadow fill under lines
                    )
                    .padding(.horizontal, 20)

                    // Bedroom Breakdown List (always visible - no toggle)
                    BedroomListView(
                        stats: data.bedroomStats,
                        selectedBedroomTypes: viewModel.selectedBedroomTypes,
                        onBedroomTap: { type in
                            viewModel.toggleBedroomType(type)
                        }
                    )
                    .padding(.horizontal, 20)
                } else {
                    emptyStateView
                }
            }
            .padding(.bottom, 80)  // Padding for bottom nav bar
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

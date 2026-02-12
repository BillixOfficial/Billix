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
                        highRent: data.highRent,
                        location: viewModel.currentLocation
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
            // Only load market trends if user has searched in Housing tab
            // No default location - user must search first
            if viewModel.marketData == nil && housingViewModel.hasSearched {
                let location = housingViewModel.activeLocation.isEmpty
                    ? housingViewModel.searchAddress
                    : housingViewModel.activeLocation
                if !location.isEmpty {
                    await viewModel.loadMarketTrends(for: location)
                }
            }
        }
        .onChange(of: housingViewModel.activeLocation) { newLocation in
            // Sync when user searches a new location in Housing tab
            if !newLocation.isEmpty && newLocation != viewModel.currentLocation {
                Task {
                    await viewModel.loadMarketTrends(for: newLocation)
                }
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
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.billixDarkTeal.opacity(0.6))
                .padding(.bottom, 8)

            // Title
            Text("Explore Market Trends")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            // Description
            Text("Search for an address to view rental market\nstatistics, historical prices, and trends.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Action button to switch to Housing tab
            Button {
                onSwitchToHousing()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Search in Housing tab")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.billixDarkTeal)
                )
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
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

struct MarketTrendsView_Market_Trends_View_Previews: PreviewProvider {
    static var previews: some View {
        MarketTrendsView(
        locationManager: LocationManager.preview(),
        housingViewModel: HousingSearchViewModel(),
        onSwitchToHousing: {
        }
        )
    }
}

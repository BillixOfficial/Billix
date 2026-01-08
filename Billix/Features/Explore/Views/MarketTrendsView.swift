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

    init(locationManager: LocationManager, housingViewModel: HousingSearchViewModel) {
        self.locationManager = locationManager
        self.housingViewModel = housingViewModel
        _viewModel = StateObject(wrappedValue: MarketTrendsViewModel(housingViewModel: housingViewModel))
    }

    var body: some View {
        GeometryReader { geometry in
            let isWideScreen = geometry.size.width > 600

            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let data = viewModel.marketData {
                        // Top section: Average Rent + Bedroom Breakdown
                        if isWideScreen {
                            // Desktop/iPad: Side by side
                            HStack(alignment: .top, spacing: 16) {
                                AverageRentCard(
                                    averageRent: data.averageRent,
                                    changePercent: data.rentChange12Month,
                                    lowRent: data.lowRent,
                                    highRent: data.highRent
                                )
                                .frame(maxWidth: .infinity)

                                BedroomBreakdownGrid(stats: data.bedroomStats)
                                    .frame(maxWidth: .infinity)
                            }
                        } else {
                            // Mobile: Stacked
                            VStack(spacing: 16) {
                                AverageRentCard(
                                    averageRent: data.averageRent,
                                    changePercent: data.rentChange12Month,
                                    lowRent: data.lowRent,
                                    highRent: data.highRent
                                )

                                BedroomBreakdownGrid(stats: data.bedroomStats)
                            }
                        }

                        // Bottom section: Time selector + Chart
                        VStack(spacing: 16) {
                            // Time range selector
                            TimeRangeSelector(selectedRange: $viewModel.selectedTimeRange)

                            // Historical chart
                            RentHistoryChart(
                                historyData: viewModel.filteredHistoryData,
                                timeRange: viewModel.selectedTimeRange
                            )
                        }
                    } else {
                        emptyStateView
                    }
                }
                .padding(20)
                .padding(.bottom, 100)  // Extra padding for bottom nav bar
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "F8F9FA"),
                        Color(hex: "E9ECEF")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
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
}

// MARK: - Preview

#Preview("Market Trends View") {
    MarketTrendsView(
        locationManager: LocationManager.preview(),
        housingViewModel: HousingSearchViewModel()
    )
}

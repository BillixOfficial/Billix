//
//  HousingExploreView.swift
//  Billix
//
//  Redesigned by Claude Code on 1/5/26.
//  Map-first interactive property explorer with responsive layout
//

import SwiftUI

/// Map-first property explorer: Filters → Estimate Panel + Map → Comparable Listings
struct HousingExploreView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var viewModel: HousingSearchViewModel

    var body: some View {
        GeometryReader { geometry in
            let isWideScreen = geometry.size.width > 600

            VStack(spacing: 0) {
                // Search bar (sticky)
                if viewModel.hasSearched && !viewModel.isLoading {
                    VStack(spacing: 12) {
                        // Address/Zip Search
                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))

                                TextField("Enter address or zip code", text: $viewModel.searchQuery)
                                    .textFieldStyle(.plain)
                                    .submitLabel(.search)
                                    .onSubmit {
                                        Task {
                                            await viewModel.performAddressSearch()
                                        }
                                    }

                                if !viewModel.searchQuery.isEmpty {
                                    Button {
                                        viewModel.searchQuery = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Search button
                            Button {
                                Task {
                                    await viewModel.performAddressSearch()
                                }
                            } label: {
                                Text("Search")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.billixDarkTeal)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // Filter chips
                        FeedFiltersBar(viewModel: viewModel)
                    }
                    .background(Color.white.opacity(0.95))
                    .zIndex(1)
                }

                if viewModel.isLoading {
                    // Loading state
                    loadingState
                } else if viewModel.hasSearched {
                    // Map-first interactive state (default)
                    ScrollView {
                        VStack(spacing: 24) {
                            if isWideScreen {
                                // Desktop/iPad: 2-column layout (Estimate + Map)
                                HStack(alignment: .top, spacing: 20) {
                                    // Left: Estimate Panel
                                    RentEstimatePanel(
                                        estimate: viewModel.selectedPropertyId == nil
                                            ? viewModel.aggregateEstimate()
                                            : viewModel.rentEstimate ?? viewModel.aggregateEstimate()
                                    )
                                    .frame(width: 300)

                                    // Right: Interactive Map
                                    PropertyMapView(
                                        searchedProperty: nil,
                                        comparables: viewModel.propertyMarkers,
                                        region: $viewModel.mapRegion,
                                        selectedPropertyId: $viewModel.selectedPropertyId,
                                        onPinTap: { id in
                                            viewModel.selectPropertyFromMap(id: id)
                                        }
                                    )
                                    .frame(height: 350)
                                }
                                .padding(.horizontal, 20)
                            } else {
                                // Mobile: Stack vertically (Map → Estimate)
                                VStack(spacing: 20) {
                                    // Map first (priority on mobile)
                                    PropertyMapView(
                                        searchedProperty: nil,
                                        comparables: viewModel.propertyMarkers,
                                        region: $viewModel.mapRegion,
                                        selectedPropertyId: $viewModel.selectedPropertyId,
                                        onPinTap: { id in
                                            viewModel.selectPropertyFromMap(id: id)
                                        }
                                    )
                                    .frame(height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                                    // Estimate panel below (clear separation)
                                    RentEstimatePanel(
                                        estimate: viewModel.selectedPropertyId == nil
                                            ? viewModel.aggregateEstimate()
                                            : viewModel.rentEstimate ?? viewModel.aggregateEstimate()
                                    )
                                }
                                .padding(.horizontal, 20)
                            }

                            // Comparable listings (vertical cards - no horizontal scroll)
                            if !viewModel.comparables.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    // Header
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Comparable Listings")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)

                                        if let estimate = viewModel.rentEstimate {
                                            Text("Based on \(estimate.comparablesCount) rental\(estimate.comparablesCount == 1 ? "" : "s") within \(viewModel.activeRadius, specifier: "%.1f") mile radius")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 20)

                                    // Property Cards
                                    VStack(spacing: 12) {
                                        ForEach(Array(viewModel.sortedComparables.enumerated()), id: \.element.id) { index, property in
                                            PropertyListCard(
                                                property: property,
                                                isSelected: property.id == viewModel.selectedPropertyId,
                                                onTap: {
                                                    viewModel.selectPropertyFromMap(id: property.id)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
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
        .task {
            // Auto-load NYC map with properties on first appear
            if viewModel.isInitialLoad {
                await viewModel.loadPopulatedArea(address: "New York, NY 10001")
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.billixDarkTeal)

            Text("Loading properties...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Housing Explore - Empty State") {
    HousingExploreView(
        locationManager: LocationManager.preview(),
        viewModel: HousingSearchViewModel()
    )
}

#Preview("Housing Explore - Loading State") {
    HousingExploreView(
        locationManager: LocationManager.preview(),
        viewModel: HousingSearchViewModel()
    )
}

#Preview("Housing Explore - Results State") {
    HousingExploreView(
        locationManager: LocationManager.preview(),
        viewModel: HousingSearchViewModel()
    )
}

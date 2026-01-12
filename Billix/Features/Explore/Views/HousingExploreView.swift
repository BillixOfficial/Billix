//
//  HousingExploreView.swift
//  Billix
//
//  Redesigned by Claude Code on 1/5/26.
//  Map-first interactive property explorer with responsive layout
//

import SwiftUI
import MapKit

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
                                // Mobile: Combined map + estimate card
                                VStack(spacing: 0) {
                                    // Map only (no legend)
                                    CompactMapView(
                                        comparables: viewModel.propertyMarkers,
                                        region: $viewModel.mapRegion,
                                        selectedPropertyId: $viewModel.selectedPropertyId,
                                        onPinTap: { id in
                                            viewModel.selectPropertyFromMap(id: id)
                                        }
                                    )
                                    .frame(height: 280)

                                    // Rent estimate inside same card
                                    CompactRentEstimate(
                                        estimate: viewModel.selectedPropertyId == nil
                                            ? viewModel.aggregateEstimate()
                                            : viewModel.rentEstimate ?? viewModel.aggregateEstimate()
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                    .padding(.bottom, 20)
                                }
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
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

// MARK: - Compact Map View (No Legend)

struct CompactMapView: View {
    let comparables: [PropertyMarker]
    @Binding var region: MKCoordinateRegion
    @Binding var selectedPropertyId: String?
    var onPinTap: (String) -> Void

    @State private var position: MapCameraPosition

    init(
        comparables: [PropertyMarker],
        region: Binding<MKCoordinateRegion>,
        selectedPropertyId: Binding<String?>,
        onPinTap: @escaping (String) -> Void
    ) {
        self.comparables = comparables
        self._region = region
        self._selectedPropertyId = selectedPropertyId
        self.onPinTap = onPinTap
        self._position = State(initialValue: .region(region.wrappedValue))
    }

    var body: some View {
        Map(position: $position) {
            // Comparable properties (green pins) - tappable
            ForEach(comparables) { comp in
                Annotation("", coordinate: comp.coordinate) {
                    PropertyPin(
                        isSelected: comp.id == selectedPropertyId,
                        isMain: false
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            onPinTap(comp.id)
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }
}

// MARK: - Compact Rent Estimate

struct CompactRentEstimate: View {
    let estimate: RentEstimateResult

    var body: some View {
        VStack(spacing: 10) {
            // Divider line at top
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.bottom, 4)

            // Title
            Text("Estimated Monthly Rent")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            // Main estimate
            Text("$\(Int(estimate.estimatedRent))/mo")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.billixDarkTeal)
                .monospacedDigit()

            // Stat pills row
            HStack(spacing: 10) {
                CompactStatPill(
                    label: "per sq.ft.",
                    value: "$\(String(format: "%.2f", estimate.perSqft))"
                )

                CompactStatPill(
                    label: "per bedroom",
                    value: "$\(Int(estimate.perBedroom))"
                )
            }

            // Confidence badge
            HStack(spacing: 4) {
                Image(systemName: confidenceIcon)
                    .font(.system(size: 10, weight: .semibold))

                Text("\(estimate.confidence) Confidence")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(confidenceColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(confidenceColor.opacity(0.12))
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var confidenceIcon: String {
        switch estimate.confidence {
        case "High": return "checkmark.seal.fill"
        case "Medium": return "exclamationmark.triangle.fill"
        default: return "questionmark.circle.fill"
        }
    }

    private var confidenceColor: Color {
        switch estimate.confidence {
        case "High": return .billixMoneyGreen
        case "Medium": return .billixGoldenAmber
        default: return .billixStreakOrange
        }
    }
}

// MARK: - Compact Stat Pill

struct CompactStatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.billixDarkTeal)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.billixDarkTeal.opacity(0.08))
        )
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

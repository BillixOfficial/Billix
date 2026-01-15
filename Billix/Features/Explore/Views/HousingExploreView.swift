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
    @State private var showMoreFilters = false
    @State private var sheetDetent: PresentationDetent = .fraction(0.12)
    @State private var isKeyboardVisible = false

    private var isCollapsed: Bool {
        sheetDetent != .medium && sheetDetent != .large
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Full-screen map as background
            if viewModel.hasSearched && !viewModel.isLoading {
                CompactMapView(
                    comparables: viewModel.propertyMarkers,
                    region: $viewModel.mapRegion,
                    selectedPropertyId: $viewModel.selectedPropertyId,
                    onPinTap: { id in
                        viewModel.selectPropertyFromMap(id: id)
                        // Expand sheet to medium (half-expanded) to show property details
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            sheetDetent = .medium
                        }
                    }
                )
                .ignoresSafeArea()
            } else if viewModel.isLoading {
                loadingState
            }

            // Search bar at top (overlaid on map)
            VStack(spacing: 0) {
                if !viewModel.isLoading {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            // Address/Zip Search Field
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
                            .background(Color.white.opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                            // More Filters Button with badge
                            Button {
                                showMoreFilters = true
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "slider.horizontal.3")
                                            .font(.system(size: 14))

                                        Text("More")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.95))
                                    .foregroundColor(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                                    // Filter count badge
                                    if viewModel.activeFilterCount > 0 {
                                        Text("\(viewModel.activeFilterCount)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(minWidth: 18, minHeight: 18)
                                            .background(
                                                Circle()
                                                    .fill(Color.blue)
                                            )
                                            .offset(x: 8, y: -6)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Filter Pills (Horizontal Scrollable)
                        if !viewModel.activeFilterPills.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.activeFilterPills) { pill in
                                        FilterPillView(
                                            label: pill.label,
                                            onRemove: {
                                                viewModel.removeFilter(id: pill.id)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .background(
                        // Translucent background so map shows through slightly
                        Color.white.opacity(0.85)
                            .background(.ultraThinMaterial)
                    )
                }

                Spacer()
            }

            // Bottom sheet overlay (doesn't cover tab bar) - hide when keyboard is visible
            if viewModel.showResultsSheet, let rentEstimate = viewModel.rentEstimate, !isKeyboardVisible {
                VStack {
                    Spacer()

                    DraggableResultsSheet(
                        rentEstimate: rentEstimate,
                        comparables: viewModel.comparables,  // Use raw comparables (selected property is first)
                        selectedPropertyId: viewModel.selectedPropertyId,
                        onPropertyTap: { id in
                            // Card tap: only update selection (blue border), don't reorder
                            viewModel.selectedPropertyId = id
                        },
                        sheetDetent: $sheetDetent,
                        topPadding: 5,
                        bottomPadding: 55,
                        sheetFraction: 0.12
                    )
                    .padding(.bottom, 8) // Small gap above tab bar
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
            // Auto-load Detroit map with properties on first appear (matches mock data location)
            if viewModel.isInitialLoad {
                await viewModel.loadPopulatedArea(address: "Detroit, MI 48226")
            }
        }
        .onAppear {
            // Listen for keyboard show/hide notifications
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    isKeyboardVisible = true
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    isKeyboardVisible = false
                }
            }
        }
        .onDisappear {
            // Remove keyboard observers when view disappears
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
        .sheet(isPresented: $showMoreFilters) {
            MoreFiltersSheet(viewModel: viewModel)
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

// MARK: - Draggable Results Sheet

struct DraggableResultsSheet: View {
    let rentEstimate: RentEstimateResult
    let comparables: [RentalComparable]
    let selectedPropertyId: String?
    let onPropertyTap: (String) -> Void
    @Binding var sheetDetent: PresentationDetent

    // Padding parameters
    var topPadding: CGFloat = 5
    var bottomPadding: CGFloat = 55
    var sheetFraction: Double = 0.12

    @State private var dragOffset: CGFloat = 0

    private let midHeight: CGFloat = 480
    private let expandedHeight: CGFloat = 600

    private var collapsedHeight: CGFloat {
        // Calculate based on padding
        return topPadding + 18 + 16 + bottomPadding // top + text height + vertical padding + bottom
    }

    private var isCollapsed: Bool {
        sheetDetent != .medium && sheetDetent != .large
    }

    private var currentHeight: CGFloat {
        if isCollapsed {
            return collapsedHeight
        } else if sheetDetent == .medium {
            return midHeight
        } else if sheetDetent == .large {
            return expandedHeight
        } else {
            return collapsedHeight
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 6)

            if isCollapsed {
                // Collapsed state: Just count
                Text("\(comparables.count) rental\(comparables.count == 1 ? "" : "s") available")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, topPadding)
                    .padding(.bottom, bottomPadding)
            } else {
                // Expanded states: Show content
                if sheetDetent == .medium {
                    // Medium state: Non-scrollable, compact view
                    VStack(spacing: 12) {
                        // Compact Rent Estimate
                        VStack(spacing: 8) {
                            Text("Estimated Monthly Rent")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)

                            Text("$\(Int(rentEstimate.estimatedRent))/mo")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.billixDarkTeal)
                                .monospacedDigit()

                            HStack(spacing: 8) {
                                CompactStatPill(
                                    label: "per sq.ft.",
                                    value: "$\(String(format: "%.2f", rentEstimate.perSqft))"
                                )
                                CompactStatPill(
                                    label: "per bedroom",
                                    value: "$\(Int(rentEstimate.perBedroom))"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        Divider()
                            .padding(.horizontal, 20)

                        // Compact Comparable Listings
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Comparable Listings")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)

                            if let firstProperty = comparables.first {
                                PropertyListCard(
                                    property: firstProperty,
                                    isSelected: firstProperty.id == selectedPropertyId,
                                    onTap: {
                                        onPropertyTap(firstProperty.id)
                                    }
                                )
                                .padding(.horizontal, 20)
                            }

                            // Show "Swipe up for more" hint
                            if comparables.count > 1 {
                                HStack {
                                    Spacer()
                                    Text("Swipe up to see \(comparables.count - 1) more")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                } else {
                    // Large state: Fixed rent estimate + scrollable listings
                    VStack(spacing: 0) {
                        // Fixed Rent Estimate (stays at top)
                        VStack(spacing: 12) {
                            CompactRentEstimate(estimate: rentEstimate)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            Divider()
                                .padding(.horizontal, 20)
                        }
                        .background(Color.white)

                        // Scrollable Comparable Listings
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Comparable Listings")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)

                                    Text("Based on \(rentEstimate.comparablesCount) rental\(rentEstimate.comparablesCount == 1 ? "" : "s") in this area")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                                VStack(spacing: 12) {
                                    ForEach(comparables) { property in
                                        PropertyListCard(
                                            property: property,
                                            isSelected: property.id == selectedPropertyId,
                                            onTap: {
                                                onPropertyTap(property.id)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: currentHeight)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
        .offset(y: max(0, dragOffset))
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow downward drags when not collapsed, or upward drags when collapsed
                    let translation = value.translation.height
                    if translation < 0 && !isCollapsed && sheetDetent != .large {
                        // Swipe up - allow
                        dragOffset = translation
                    } else if translation < 0 && isCollapsed {
                        // Swipe up from collapsed - allow
                        dragOffset = translation
                    } else if translation > 0 && !isCollapsed {
                        // Swipe down - allow with resistance
                        dragOffset = translation * 0.3
                    }
                }
                .onEnded { value in
                    let translation = value.translation.height
                    let velocity = value.predictedEndTranslation.height - value.translation.height

                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                        // Determine next state based on translation distance and velocity
                        if translation < -50 || velocity < -200 {
                            // Swipe up
                            if isCollapsed {
                                // Check if it's a full swipe (large distance or high velocity)
                                if translation < -150 || velocity < -500 {
                                    sheetDetent = .large // Skip to fully expanded
                                } else {
                                    sheetDetent = .medium
                                }
                            } else if sheetDetent == .medium {
                                sheetDetent = .large
                            }
                        } else if translation > 50 || velocity > 200 {
                            // Swipe down
                            if sheetDetent == .large {
                                // Check if it's a full swipe down
                                if translation > 150 || velocity > 500 {
                                    sheetDetent = .fraction(sheetFraction) // Skip to collapsed
                                } else {
                                    sheetDetent = .medium
                                }
                            } else if sheetDetent == .medium {
                                sheetDetent = .fraction(sheetFraction)
                            }
                        }
                        dragOffset = 0
                    }
                }
        )
        .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: sheetDetent)
    }
}

// MARK: - Filter Pill View

struct FilterPillView: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
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

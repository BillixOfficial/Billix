//
//  HousingSearchViewModel.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  State management for Rentometer-style property search
//

import Foundation
import MapKit
import Combine

@MainActor
class HousingSearchViewModel: ObservableObject {

    // MARK: - Search Inputs

    @Published var searchAddress: String = ""
    @Published var selectedPropertyType: PropertyType = .all
    @Published var selectedBedrooms: Int? = nil
    @Published var selectedBathrooms: Double? = nil
    @Published var squareFeet: String = ""
    @Published var searchRadius: Double = 1.0  // miles
    @Published var lookbackDays: Int = 30

    // MARK: - Results State

    @Published var hasSearched: Bool = false
    @Published var isLoading: Bool = false
    @Published var rentEstimate: RentEstimateResult? = nil
    @Published var comparables: [RentalComparable] = []
    @Published var showResultsSheet: Bool = false

    // MARK: - Table Sorting

    @Published var sortColumn: ComparableColumn = .similarity
    @Published var sortAscending: Bool = false  // similarity default descending

    // MARK: - Map State

    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var propertyMarkers: [PropertyMarker] = []

    // MARK: - Feed State

    @Published var featuredListings: [RentalComparable] = []
    @Published var isLoadingFeed: Bool = false
    @Published var showSearchSheet: Bool = false

    // Active filters
    @Published var activeSearchMode: SearchMode = .rent
    @Published var activePropertyType: PropertyType = .all
    @Published var activeBedrooms: Int? = nil
    @Published var activeBathrooms: Double? = nil
    @Published var activePriceRange: ClosedRange<Double>? = nil
    @Published var activeRadius: Double = 3.0  // Default 3 miles for feed
    @Published var activeLocation: String = ""  // City or state filter

    // Additional filters for MoreFiltersSheet
    @Published var activeSqftRange: ClosedRange<Double>? = nil
    @Published var activeYearBuiltRange: ClosedRange<Int>? = nil
    @Published var activeAmenities: Set<PropertyAmenity> = []
    @Published var activeKeywords: String = ""

    // NEW: Rentcast-supported filters
    @Published var activeLotSizeRange: ClosedRange<Double>? = nil  // sq ft
    @Published var activeDaysOldRange: ClosedRange<Int>? = nil    // days since listed
    @Published var activeListingStatus: ListingStatus = .active   // Active/Inactive
    @Published var activePropertyTypes: Set<PropertyType> = []    // Multiple types

    // Search input
    @Published var searchQuery: String = ""

    // Store original unfiltered data
    private var allComparables: [RentalComparable] = []

    // MARK: - Map-First Interactive State

    @Published var selectedPropertyId: String? = nil
    @Published var isInitialLoad: Bool = true

    // MARK: - Computed Properties

    var canSearch: Bool {
        !searchAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var sortedComparables: [RentalComparable] {
        comparables.sorted { c1, c2 in
            let result: Bool

            switch sortColumn {
            case .address:
                result = c1.address < c2.address
            case .rent:
                result = (c1.rent ?? 0) < (c2.rent ?? 0)
            case .lastSeen:
                result = c1.lastSeen < c2.lastSeen
            case .similarity:
                result = c1.similarity < c2.similarity
            case .distance:
                result = (c1.distance ?? 0) < (c2.distance ?? 0)
            case .beds:
                result = c1.bedrooms < c2.bedrooms
            case .baths:
                result = c1.bathrooms < c2.bathrooms
            case .sqft:
                result = (c1.sqft ?? 0) < (c2.sqft ?? 0)
            case .type:
                result = c1.propertyType.rawValue < c2.propertyType.rawValue
            }

            return sortAscending ? result : !result
        }
    }

    var searchedPropertyMarker: PropertyMarker? {
        propertyMarkers.first { $0.isSearchedProperty }
    }

    var comparableMarkers: [PropertyMarker] {
        propertyMarkers.filter { !$0.isSearchedProperty }
    }

    // MARK: - Active Filters

    var activeFilterCount: Int {
        var count = 0

        if activePropertyType != .all { count += 1 }
        if activeBedrooms != nil { count += 1 }
        if activeBathrooms != nil { count += 1 }
        if activePriceRange != nil { count += 1 }
        if activeSqftRange != nil { count += 1 }
        if activeYearBuiltRange != nil { count += 1 }
        if activeLotSizeRange != nil { count += 1 }
        if activeDaysOldRange != nil { count += 1 }
        if !activeAmenities.isEmpty { count += 1 }
        if !activeKeywords.isEmpty { count += 1 }

        return count
    }

    var activeFilterPills: [FilterPill] {
        var pills: [FilterPill] = []

        if activePropertyType != .all {
            pills.append(FilterPill(id: "type", label: activePropertyType.rawValue))
        }

        if let beds = activeBedrooms {
            pills.append(FilterPill(id: "beds", label: "\(beds)+ bed\(beds == 1 ? "" : "s")"))
        }

        if let baths = activeBathrooms {
            pills.append(FilterPill(id: "baths", label: "\(Int(baths))+ bathroom\(baths == 1.0 ? "" : "s")"))
        }

        if let priceRange = activePriceRange {
            pills.append(FilterPill(id: "price", label: "$\(Int(priceRange.lowerBound))-\(Int(priceRange.upperBound))/mo"))
        }

        if let sqftRange = activeSqftRange {
            pills.append(FilterPill(id: "sqft", label: "\(Int(sqftRange.lowerBound))-\(Int(sqftRange.upperBound)) sq.ft."))
        }

        if let yearRange = activeYearBuiltRange {
            pills.append(FilterPill(id: "year", label: "Built \(yearRange.lowerBound)-\(yearRange.upperBound)"))
        }

        if let lotRange = activeLotSizeRange {
            pills.append(FilterPill(id: "lot", label: "\(Int(lotRange.lowerBound))-\(Int(lotRange.upperBound)) lot sq.ft."))
        }

        if let daysRange = activeDaysOldRange {
            pills.append(FilterPill(id: "days", label: "Listed \(daysRange.lowerBound)-\(daysRange.upperBound) days ago"))
        }

        if !activeAmenities.isEmpty {
            pills.append(FilterPill(id: "amenities", label: "\(activeAmenities.count) amenity filter\(activeAmenities.count == 1 ? "" : "s")"))
        }

        if !activeKeywords.isEmpty {
            pills.append(FilterPill(id: "keywords", label: "Keywords: \(activeKeywords)"))
        }

        return pills
    }

    func removeFilter(id: String) {
        switch id {
        case "type": activePropertyType = .all
        case "beds": activeBedrooms = nil
        case "baths": activeBathrooms = nil
        case "price": activePriceRange = nil
        case "sqft": activeSqftRange = nil
        case "year": activeYearBuiltRange = nil
        case "lot": activeLotSizeRange = nil
        case "days": activeDaysOldRange = nil
        case "amenities": activeAmenities = []
        case "keywords": activeKeywords = ""
        default: break
        }

        Task {
            await applyFilters()
        }
    }

    // MARK: - Rentcast API Integration

    struct RentcastQueryParams {
        // Location
        var city: String?
        var state: String?
        var zipCode: String?
        var address: String?
        var latitude: Double?
        var longitude: Double?
        var radius: Double?

        // Property characteristics
        var propertyType: String?        // "Condo|Townhouse"
        var bedrooms: String?            // "2:4" or "2|3|4"
        var bathrooms: String?           // "2:*" or "1.5|2|2.5"
        var squareFootage: String?       // "1000:2500"
        var lotSize: String?             // "5000:*"
        var yearBuilt: String?           // "2000:*"

        // Listing filters
        var status: String?              // "Active"
        var price: String?               // "1500:3000"
        var daysOld: String?             // "*:30"

        // Pagination
        var limit: Int = 50
        var offset: Int = 0
    }

    func buildRentcastQuery() -> RentcastQueryParams {
        var params = RentcastQueryParams()

        // Parse location
        params.address = activeLocation.isEmpty ? nil : activeLocation
        params.radius = activeRadius

        // Property types (multiple with |)
        if !activePropertyTypes.isEmpty {
            let types = activePropertyTypes
                .filter { $0 != .all }
                .map { $0.rentcastValue }
                .joined(separator: "|")
            params.propertyType = types.isEmpty ? nil : types
        }

        // Bedrooms (range or single)
        if let beds = activeBedrooms {
            params.bedrooms = "\(beds):*"  // Min bedrooms
        }

        // Bathrooms (range or single)
        if let baths = activeBathrooms {
            params.bathrooms = "\(baths):*"  // Min bathrooms
        }

        // Price range
        if let priceRange = activePriceRange {
            params.price = "\(Int(priceRange.lowerBound)):\(Int(priceRange.upperBound))"
        }

        // Square footage range
        if let sqftRange = activeSqftRange {
            params.squareFootage = "\(Int(sqftRange.lowerBound)):\(Int(sqftRange.upperBound))"
        }

        // Year built range
        if let yearRange = activeYearBuiltRange {
            params.yearBuilt = "\(yearRange.lowerBound):\(yearRange.upperBound)"
        }

        // Lot size range
        if let lotRange = activeLotSizeRange {
            params.lotSize = "\(Int(lotRange.lowerBound)):\(Int(lotRange.upperBound))"
        }

        // Days old range
        if let daysRange = activeDaysOldRange {
            params.daysOld = "\(daysRange.lowerBound):\(daysRange.upperBound)"
        }

        // Status
        if activeListingStatus != .all {
            params.status = activeListingStatus.rawValue
        }

        return params
    }

    // MARK: - Methods

    func performSearch() async {
        guard canSearch else { return }

        isLoading = true

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 800_000_000)  // 0.8 seconds

        // Build search params
        let sqftValue = Int(squareFeet.trimmingCharacters(in: .whitespacesAndNewlines))
        let params = PropertySearchParams(
            address: searchAddress,
            propertyType: selectedPropertyType,
            bedrooms: selectedBedrooms,
            bathrooms: selectedBathrooms,
            squareFeet: sqftValue,
            searchRadius: searchRadius,
            lookbackDays: lookbackDays
        )

        // Generate mock data
        let estimate = HousingMockData.generateRentEstimate(params: params)
        let comps = HousingMockData.generateComparables(params: params, estimate: estimate)

        // Generate map markers
        let searchedMarker = HousingMockData.generateSearchedPropertyMarker(params: params)
        let compMarkers = HousingMockData.generateComparableMarkers(comparables: comps)

        // Update map region to center on searched property
        let region = MKCoordinateRegion(
            center: searchedMarker.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: searchRadius * 0.03,  // Adjust zoom based on radius
                longitudeDelta: searchRadius * 0.03
            )
        )

        // Update state
        rentEstimate = estimate
        comparables = comps
        propertyMarkers = [searchedMarker] + compMarkers
        mapRegion = region
        hasSearched = true
        showResultsSheet = true
        isLoading = false
    }

    func clearSearch() {
        searchAddress = ""
        selectedPropertyType = .all
        selectedBedrooms = nil
        selectedBathrooms = nil
        squareFeet = ""
        searchRadius = 1.0
        lookbackDays = 30

        hasSearched = false
        showResultsSheet = false
        isLoading = false
        rentEstimate = nil
        comparables = []
        propertyMarkers = []

        sortColumn = .similarity
        sortAscending = false

        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    func sortComparables(by column: ComparableColumn) {
        if sortColumn == column {
            // Toggle direction if same column
            sortAscending.toggle()
        } else {
            // New column: default direction
            sortColumn = column
            // Similarity defaults to descending, others to ascending
            sortAscending = (column == .similarity) ? false : true
        }
    }

    // MARK: - Feed Methods

    func loadFeaturedFeed() async {
        isLoadingFeed = true

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

        // Generate default featured feed (2BR apartments within 3 miles)
        let params = PropertySearchParams(
            address: "Royal Oak, MI 48067",
            propertyType: activePropertyType,
            bedrooms: activeBedrooms,
            bathrooms: activeBathrooms,
            squareFeet: nil,
            searchRadius: activeRadius,
            lookbackDays: 30
        )

        let estimate = HousingMockData.generateRentEstimate(params: params)
        let listings = HousingMockData.generateComparables(params: params, estimate: estimate)

        featuredListings = listings
        isLoadingFeed = false
    }

    func applyFilters() async {
        // Filter the existing properties
        let filteredComps = filterComparables(allComparables)

        // Update markers
        let markers = filteredComps.map { comp in
            PropertyMarker(
                id: comp.id,
                coordinate: comp.coordinate,
                isSearchedProperty: false
            )
        }

        // Clear selection since filtered property might not be in results
        selectedPropertyId = nil

        comparables = filteredComps
        propertyMarkers = markers

        // Update estimate
        rentEstimate = aggregateEstimate()
    }

    func resetFilters() {
        activePropertyType = .all
        activePropertyTypes = []
        activeBedrooms = nil
        activeBathrooms = nil
        activePriceRange = nil
        activeRadius = 3.0
        activeLocation = ""
        activeSqftRange = nil
        activeYearBuiltRange = nil
        activeLotSizeRange = nil
        activeDaysOldRange = nil
        activeListingStatus = .active
        activeAmenities = []
        activeKeywords = ""
        searchQuery = ""

        Task {
            await applyFilters()
        }
    }

    func performAddressSearch() async {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Load properties for the searched address
        await loadPopulatedArea(address: searchQuery)
    }

    /// Filter comparables based on active filters
    private func filterComparables(_ comps: [RentalComparable]) -> [RentalComparable] {
        var filtered = comps

        // Filter by property type
        if activePropertyType != .all {
            filtered = filtered.filter { $0.propertyType == activePropertyType }
        }

        // Filter by bedrooms (minimum)
        if let minBeds = activeBedrooms {
            filtered = filtered.filter { $0.bedrooms >= minBeds }
        }

        // Filter by bathrooms (minimum)
        if let minBaths = activeBathrooms {
            filtered = filtered.filter { $0.bathrooms >= minBaths }
        }

        // Filter by price range
        if let priceRange = activePriceRange {
            filtered = filtered.filter {
                guard let rent = $0.rent else { return false }
                return priceRange.contains(rent)
            }
        }

        // Filter by radius (approximate - would need real distance calc in production)
        // For mock data, we'll keep all since they're already within radius

        return filtered
    }

    func fairValueIndicator(for rent: Double) -> FairValue {
        let median = medianRent()
        let difference = (rent - median) / median

        if difference < -0.10 {
            return .greatDeal
        } else if difference > 0.10 {
            return .aboveAverage
        } else {
            return .fairPrice
        }
    }

    private func medianRent() -> Double {
        let rents = featuredListings.compactMap { $0.rent }.sorted()
        guard !rents.isEmpty else { return 2000 }
        return rents[rents.count / 2]
    }

    // MARK: - Map-First Methods

    /// Load populated area (NYC by default) with properties for map-first view
    func loadPopulatedArea(address: String) async {
        isLoading = true
        searchAddress = address

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

        let params = PropertySearchParams(
            address: address,
            propertyType: .all,  // Load all initially, filter later
            bedrooms: nil,
            bathrooms: nil,
            squareFeet: nil,
            searchRadius: 2.0,  // 2 miles for dense clustering
            lookbackDays: 30
        )

        // Center map on Detroit coordinates (matches mock data location)
        let baseCoordinate = CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458)

        let estimate = HousingMockData.generateRentEstimate(params: params)
        let comps = HousingMockData.generateComparables(params: params, estimate: estimate)

        // Store original unfiltered data
        allComparables = comps

        // Apply current filters
        let filteredComps = filterComparables(comps)

        // Generate map markers for filtered properties
        let markers = filteredComps.map { comp in
            PropertyMarker(
                id: comp.id,
                coordinate: comp.coordinate,
                isSearchedProperty: false
            )
        }

        mapRegion = MKCoordinateRegion(
            center: baseCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )

        rentEstimate = estimate
        comparables = filteredComps
        propertyMarkers = markers
        hasSearched = true
        showResultsSheet = true
        isLoading = false
        isInitialLoad = false
    }

    /// Handle pin selection from map
    func selectPropertyFromMap(id: String) {
        selectedPropertyId = id

        // Find clicked property
        guard let selected = comparables.first(where: { $0.id == id }) else { return }

        // Get 5 nearest comparables
        let nearbyComparables = comparables
            .filter { $0.id != id }
            .sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
            .prefix(5)

        // Update table to show selected + nearby
        comparables = [selected] + Array(nearbyComparables)

        // Update estimate for selected property
        updateEstimateForProperty(id: id)
    }

    /// Update estimate panel for selected property
    func updateEstimateForProperty(id: String) {
        guard let property = comparables.first(where: { $0.id == id }) else { return }

        // Generate estimate for this specific property
        let params = PropertySearchParams(
            address: property.address,
            propertyType: property.propertyType,
            bedrooms: property.bedrooms,
            bathrooms: property.bathrooms,
            squareFeet: property.sqft,
            searchRadius: 0.5,
            lookbackDays: 30
        )

        rentEstimate = HousingMockData.generateRentEstimate(params: params)
    }

    /// Compute aggregate median rent for initial state (before pin selected)
    func aggregateEstimate() -> RentEstimateResult {
        let rents = comparables.compactMap { $0.rent }.sorted()
        let median = rents.isEmpty ? 2000 : rents[rents.count / 2]
        let low = rents.isEmpty ? 1500 : rents.first!
        let high = rents.isEmpty ? 3000 : rents.last!

        return RentEstimateResult(
            estimatedRent: median,
            lowEstimate: low,
            highEstimate: high,
            perSqft: median / 1000,
            perBedroom: median / 2,
            confidence: "Medium",
            comparablesCount: comparables.count
        )
    }
}

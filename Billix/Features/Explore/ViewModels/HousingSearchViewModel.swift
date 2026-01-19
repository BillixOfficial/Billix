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
    @Published var comparables: [RentalComparable] = []  // Filtered list for display
    @Published var showResultsSheet: Bool = false

    // MARK: - Rate Limiting

    @Published var showRateLimitExceeded: Bool = false
    @Published var rateLimitErrorMessage: String? = nil

    /// Dismiss the rate limit exceeded view
    func dismissRateLimitExceeded() {
        showRateLimitExceeded = false
        rateLimitErrorMessage = nil
    }

    /// Refresh rate limit status from server
    func refreshRateLimitStatus() async {
        await RateLimitService.shared.refreshUsage()
    }

    // Full list of all comparables (not filtered by pin selection)
    private var allComparables: [RentalComparable] = []

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

    // Rentcast-supported filters (simplified - removed sqft, yearBuilt, lotSize, daysOld)
    @Published var activeListingStatus: ListingStatus = .all   // Show all by default (Active + Inactive)
    @Published var activePropertyTypes: Set<PropertyType> = []    // Multiple types

    // Search input
    @Published var searchQuery: String = ""

    // MARK: - Map-First Interactive State

    @Published var selectedPropertyId: String? = nil
    @Published var isInitialLoad: Bool = true

    // MARK: - Market Statistics (for header average)

    @Published var marketResponse: RentCastMarketResponse?
    private var currentZipCode: String?
    private var searchCenterCoordinate: CLLocationCoordinate2D?

    // MARK: - RentCast Service

    private let rentCastService = RentCastEdgeFunctionService.shared

    // MARK: - Address Autocomplete

    let autocompleteService = AddressAutocompleteService()
    @Published var showAutocompleteSuggestions: Bool = false

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
        if !activePropertyTypes.isEmpty { count += 1 }
        if activeBedrooms != nil { count += 1 }
        if activeBathrooms != nil { count += 1 }
        if activePriceRange != nil { count += 1 }
        if activeListingStatus != .all { count += 1 }

        return count
    }

    var activeFilterPills: [FilterPill] {
        var pills: [FilterPill] = []

        if activePropertyType != .all {
            pills.append(FilterPill(id: "type", label: activePropertyType.rawValue))
        }

        // Show multi-select property types
        if !activePropertyTypes.isEmpty {
            let typeNames = activePropertyTypes.map { $0.rawValue }.joined(separator: ", ")
            pills.append(FilterPill(id: "types", label: typeNames))
        }

        if let beds = activeBedrooms {
            pills.append(FilterPill(id: "beds", label: "\(beds) bed\(beds == 1 ? "" : "s")"))
        }

        if let baths = activeBathrooms {
            let bathLabel = baths.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(baths))" : "\(baths)"
            pills.append(FilterPill(id: "baths", label: "\(bathLabel) bath\(baths == 1.0 ? "" : "s")"))
        }

        if let priceRange = activePriceRange {
            pills.append(FilterPill(id: "price", label: "$\(Int(priceRange.lowerBound))-\(Int(priceRange.upperBound))/mo"))
        }

        if activeListingStatus != .all {
            pills.append(FilterPill(id: "status", label: activeListingStatus.rawValue))
        }

        return pills
    }

    func removeFilter(id: String) {
        switch id {
        case "type": activePropertyType = .all
        case "types": activePropertyTypes = []
        case "beds": activeBedrooms = nil
        case "baths": activeBathrooms = nil
        case "price": activePriceRange = nil
        case "status": activeListingStatus = .all
        default: break
        }

        print("🔍 [FILTER] Removed filter: \(id)")

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

        // Bedrooms (exact value)
        if let beds = activeBedrooms {
            params.bedrooms = "\(beds)"  // Exact bedroom count
        }

        // Bathrooms (exact value)
        if let baths = activeBathrooms {
            let bathStr = baths.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(baths))" : "\(baths)"
            params.bathrooms = bathStr  // Exact bathroom count
        }

        // Price range
        if let priceRange = activePriceRange {
            params.price = "\(Int(priceRange.lowerBound)):\(Int(priceRange.upperBound))"
        }

        // Status
        if activeListingStatus != .all {
            params.status = activeListingStatus.rawValue
        }

        print("🔍 [API QUERY] Building query with:")
        print("   📍 Location: \(params.address ?? "nil")")
        print("   🛏️ Bedrooms: \(params.bedrooms ?? "any")")
        print("   🛁 Bathrooms: \(params.bathrooms ?? "any")")
        print("   💵 Price: \(params.price ?? "any")")
        print("   📊 Status: \(params.status ?? "any")")

        return params
    }

    // MARK: - Methods

    func performSearch() async {
        guard canSearch else { return }

        isLoading = true

        do {
            let sqftValue = Int(squareFeet.trimmingCharacters(in: .whitespacesAndNewlines))

            // Fetch from RentCast via Edge Function
            let response = try await rentCastService.fetchRentEstimate(
                address: searchAddress,
                propertyType: selectedPropertyType == .all ? nil : selectedPropertyType.rentcastValue,
                bedrooms: selectedBedrooms,
                bathrooms: selectedBathrooms,
                squareFootage: sqftValue,
                maxRadius: searchRadius,
                daysOld: lookbackDays,
                compCount: 15
            )

            // Convert to Billix models
            let estimate = response.toRentEstimateResult()
            let comps = response.comparables.map { $0.toRentalComparable() }

            // Generate map markers
            let searchedMarker = PropertyMarker(
                id: "searched",
                coordinate: CLLocationCoordinate2D(
                    latitude: response.latitude,
                    longitude: response.longitude
                ),
                isSearchedProperty: true,
                isActive: true
            )

            let compMarkers = comps.map { comp in
                PropertyMarker(
                    id: comp.id,
                    coordinate: comp.coordinate,
                    isSearchedProperty: false,
                    isActive: comp.isActive
                )
            }

            // Update map region to center on searched property
            let region = MKCoordinateRegion(
                center: searchedMarker.coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: searchRadius * 0.03,
                    longitudeDelta: searchRadius * 0.03
                )
            )

            // Update state
            rentEstimate = estimate
            allComparables = comps
            comparables = comps
            propertyMarkers = [searchedMarker] + compMarkers
            mapRegion = region
            hasSearched = true
            showResultsSheet = true

        } catch let error as RentCastError {
            // Handle rate limit exceeded specifically
            if case .rateLimitExceeded(let remaining, let limit) = error {
                print("")
                print("🛑 [HOUSING VM] ═══════════════════════════════════════════")
                print("🛑 [HOUSING VM] RATE LIMIT EXCEEDED IN performSearch()")
                print("🛑 [HOUSING VM] Limit: \(limit)/week, Remaining: \(remaining)")
                print("🛑 [HOUSING VM] Showing RateLimitExceededView...")
                print("🛑 [HOUSING VM] ═══════════════════════════════════════════")
                print("")
                showRateLimitExceeded = true
                rateLimitErrorMessage = error.localizedDescription
            } else {
                print("❌ [HOUSING VM] RentCast error: \(error)")
            }
            rentEstimate = nil
            allComparables = []
            comparables = []
            propertyMarkers = []
        } catch {
            // Show error - NO FALLBACK to mock data
            print("❌ [HOUSING VM] Error performing search: \(error)")
            rentEstimate = nil
            allComparables = []
            comparables = []
            propertyMarkers = []
        }

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
        allComparables = []
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

        do {
            // Build filters for RentCast API
            let bedroomsStr = activeBedrooms.map { "\($0):*" }  // Min bedrooms
            let bathroomsStr = activeBathrooms.map { "\($0):*" }  // Min bathrooms
            var priceStr: String? = nil
            if let priceRange = activePriceRange {
                priceStr = "\(Int(priceRange.lowerBound)):\(Int(priceRange.upperBound))"
            }

            // Fetch listings from RentCast via Edge Function
            let listings = try await rentCastService.fetchRentalListings(
                city: activeLocation.isEmpty ? "Royal Oak" : nil,
                state: activeLocation.isEmpty ? "MI" : nil,
                zipCode: activeLocation.isEmpty ? nil : extractZipCode(from: activeLocation),
                radius: activeRadius,
                propertyType: activePropertyType == .all ? nil : activePropertyType.rentcastValue,
                bedrooms: bedroomsStr,
                bathrooms: bathroomsStr,
                price: priceStr,
                status: "Active",
                limit: 50
            )

            // Convert to Billix models
            featuredListings = listings.map { $0.toRentalComparable() }

        } catch let error as RentCastError {
            // Handle rate limit exceeded specifically
            if case .rateLimitExceeded(let remaining, let limit) = error {
                print("")
                print("🛑 [HOUSING VM] ═══════════════════════════════════════════")
                print("🛑 [HOUSING VM] RATE LIMIT EXCEEDED IN loadFeaturedFeed()")
                print("🛑 [HOUSING VM] Limit: \(limit)/week, Remaining: \(remaining)")
                print("🛑 [HOUSING VM] Showing RateLimitExceededView...")
                print("🛑 [HOUSING VM] ═══════════════════════════════════════════")
                print("")
                showRateLimitExceeded = true
                rateLimitErrorMessage = error.localizedDescription
            } else {
                print("❌ [HOUSING VM] RentCast error: \(error)")
            }
            featuredListings = []
        } catch {
            // Show error - NO FALLBACK to mock data
            print("❌ [HOUSING VM] Error loading featured feed: \(error)")
            featuredListings = []
        }

        isLoadingFeed = false
    }

    private func extractZipCode(from location: String) -> String? {
        let pattern = "\\d{5}"
        if let range = location.range(of: pattern, options: .regularExpression) {
            return String(location[range])
        }
        return nil
    }

    func applyFilters() async {
        print("")
        print("🔄 [APPLY FILTERS] Called")
        print("   • searchAddress: '\(searchAddress)'")
        print("   • activeBedrooms: \(activeBedrooms != nil ? "\(activeBedrooms!)" : "nil")")
        print("   • activeBathrooms: \(activeBathrooms != nil ? "\(activeBathrooms!)" : "nil")")

        // If we have a search address, reload from API with new filters
        // This ensures filters are applied server-side for better results
        if !searchAddress.isEmpty {
            print("   → Making NEW API call with filters (API-level filtering)")
            await loadPopulatedArea(address: searchAddress)
            return
        } else {
            print("   → No search address, applying client-side filters only")
        }

        // Fallback: Filter existing properties if no search has been done
        let filteredComps = filterComparables(allComparables)

        // Update markers
        let markers = filteredComps.map { comp in
            PropertyMarker(
                id: comp.id,
                coordinate: comp.coordinate,
                isSearchedProperty: false,
                isActive: comp.isActive
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
        activeListingStatus = .all
        searchQuery = ""

        print("🔍 [FILTERS] All filters reset")

        Task {
            await applyFilters()
        }
    }

    func performAddressSearch() async {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Hide suggestions when searching
        showAutocompleteSuggestions = false
        autocompleteService.clear()

        // Load properties for the searched address
        await loadPopulatedArea(address: searchQuery)
    }

    /// Update autocomplete suggestions as user types
    func updateAutocompleteSuggestions() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.count >= 3 {
            showAutocompleteSuggestions = true
            autocompleteService.search(query: query)
        } else {
            showAutocompleteSuggestions = false
            autocompleteService.clear()
        }
    }

    /// Handle selection of an autocomplete suggestion
    func selectAddressSuggestion(_ suggestion: AddressSuggestion) async {
        // Get full formatted address
        if let fullAddress = await autocompleteService.getFullAddress(for: suggestion) {
            searchQuery = fullAddress
        } else {
            // Fallback to display text
            searchQuery = suggestion.displayText
        }

        // Hide suggestions and search
        showAutocompleteSuggestions = false
        autocompleteService.clear()

        // Perform the search
        await loadPopulatedArea(address: searchQuery)
    }

    /// Hide autocomplete suggestions
    func hideAutocompleteSuggestions() {
        showAutocompleteSuggestions = false
    }

    /// Filter comparables based on active filters
    /// NOTE: Bedroom/bathroom filtering is done at API level, not client-side
    private func filterComparables(_ comps: [RentalComparable]) -> [RentalComparable] {
        var filtered = comps

        print("🔍 [FILTER] Starting with \(comps.count) properties (API-filtered)")
        print("🔍 [FILTER] Refinement filters:")
        print("   - activePropertyType: \(activePropertyType)")
        print("   - activePropertyTypes: \(activePropertyTypes)")
        print("   - activePriceRange: \(activePriceRange?.description ?? "nil")")
        print("   - activeListingStatus: \(activeListingStatus)")
        print("   - activeRadius: \(activeRadius) mi")
        print("   (beds/baths handled by API, not filtered here)")

        // Filter by property types (multi-select takes priority)
        if !activePropertyTypes.isEmpty {
            filtered = filtered.filter { activePropertyTypes.contains($0.propertyType) }
            print("🔍 [FILTER] After property types (multi): \(filtered.count)")
        } else if activePropertyType != .all {
            // Fallback to single selection if multi-select is empty
            filtered = filtered.filter { $0.propertyType == activePropertyType }
            print("🔍 [FILTER] After property type (single): \(filtered.count)")
        }

        // NOTE: Bedroom/bathroom filtering removed - API handles this
        // When user selects "2 bedrooms", we re-fetch from API with bedrooms=2
        // API returns ~15-20 two-bedroom properties directly

        // Filter by price range (client-side refinement)
        if let priceRange = activePriceRange {
            filtered = filtered.filter {
                guard let rent = $0.rent else { return false }
                return priceRange.contains(rent)
            }
            print("🔍 [FILTER] After price range: \(filtered.count)")
        }

        // Filter by listing status (client-side refinement)
        if activeListingStatus != .all {
            let statusStr = activeListingStatus.rawValue
            filtered = filtered.filter { $0.status == statusStr }
            print("🔍 [FILTER] After status == \(statusStr): \(filtered.count)")
        }

        // Filter by radius (distance from search center)
        let beforeRadiusCount = filtered.count
        filtered = filtered.filter { comp in
            guard let distance = comp.distance else { return true }  // Keep if no distance data
            return distance <= activeRadius
        }
        if beforeRadiusCount != filtered.count {
            print("🔍 [FILTER] After radius <= \(activeRadius) mi: \(filtered.count) (removed \(beforeRadiusCount - filtered.count))")
        }

        print("🔍 [FILTER] Final result: \(filtered.count) properties")
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

    /// Load rent estimate and comparables for an address (RentCast-style)
    func loadPopulatedArea(address: String) async {
        print("═══════════════════════════════════════════════════════════")
        print("🏠 [SEARCH] Starting search for: \(address)")
        print("═══════════════════════════════════════════════════════════")
        print("📋 [FILTERS] Active filters:")
        print("   • Bedrooms: \(activeBedrooms != nil ? "\(activeBedrooms!)" : "Any")")
        print("   • Bathrooms: \(activeBathrooms != nil ? "\(activeBathrooms!)" : "Any")")
        print("   • Property Type: \(activePropertyType.rawValue)")
        print("   • Price Range: \(activePriceRange?.description ?? "Any")")
        print("   • Status: \(activeListingStatus.rawValue)")
        print("   • Radius: \(activeRadius) mi")
        print("───────────────────────────────────────────────────────────")

        isLoading = true
        searchAddress = address
        activeLocation = address  // Sync with Market Trends tab

        do {
            // Step 1: Check cache first (by address + filters)
            let cacheKey = CacheKey.rentEstimate(address: address, latitude: nil, longitude: nil, bedrooms: activeBedrooms, bathrooms: activeBathrooms)
            print("🔑 [CACHE KEY] \(cacheKey)")

            let cachedResponse: RentCastEstimateResponse? = await CacheManager.shared.get(cacheKey)

            var response: RentCastEstimateResponse

            if let cached = cachedResponse {
                print("💾 [CACHE HIT] Using cached data (no API call)")
                response = cached
            } else {
                // Step 2: Fetch from Rent Estimate API (provides similarity scores!)
                print("📡 [API CALL] Making NEW API request with:")
                print("   • address: \(address)")
                print("   • bedrooms: \(activeBedrooms != nil ? "\(activeBedrooms!)" : "nil (any)")")
                print("   • bathrooms: \(activeBathrooms != nil ? "\(activeBathrooms!)" : "nil (any)")")
                print("   • maxRadius: 1.5 mi")
                print("   • daysOld: 365")
                print("   • compCount: 20")

                response = try await rentCastService.fetchRentEstimate(
                    address: address,
                    propertyType: activePropertyType == .all ? nil : activePropertyType.rentcastValue,
                    bedrooms: activeBedrooms,
                    bathrooms: activeBathrooms != nil ? activeBathrooms : nil,
                    squareFootage: nil,
                    maxRadius: 1.5,   // 1.5 mile radius for more results
                    daysOld: 180,     // Last 6 months of data
                    compCount: 20     // Get 20 comparables
                )

                // Step 3: Store in cache
                await CacheManager.shared.set(cacheKey, value: response)
                print("💾 [CACHE STORED] Saved to cache with key: \(cacheKey)")
            }

            // Store search center from API response
            searchCenterCoordinate = CLLocationCoordinate2D(
                latitude: response.latitude,
                longitude: response.longitude
            )

            // Convert comparables to Billix models (already sorted by similarity from API)
            let comps = response.comparables.map { $0.toRentalComparable() }
            print("───────────────────────────────────────────────────────────")
            print("📊 [API RESPONSE] Received \(comps.count) comparables from API")

            // Show bedroom breakdown of API results
            let bedroomCounts = Dictionary(grouping: comps, by: { $0.bedrooms }).mapValues { $0.count }
            print("   Bedroom breakdown: \(bedroomCounts.sorted(by: { $0.key < $1.key }).map { "\($0.key)bd: \($0.value)" }.joined(separator: ", "))")

            // Store all comparables
            allComparables = comps

            // Sort by similarity (highest first) - API usually does this but let's ensure
            let sortedComps = comps.sorted { $0.similarity > $1.similarity }

            // Apply client-side filters (beds, baths, price, status, etc.)
            let filteredComps = filterComparables(sortedComps)

            // Create numbered markers (1, 2, 3...) for filtered comparables only
            let searchedMarker = PropertyMarker(
                id: "searched",
                coordinate: CLLocationCoordinate2D(latitude: response.latitude, longitude: response.longitude),
                isSearchedProperty: true,
                isActive: true,
                index: nil  // No number for searched property
            )

            let compMarkers = filteredComps.enumerated().map { (index, comp) in
                PropertyMarker(
                    id: comp.id,
                    coordinate: comp.coordinate,
                    isSearchedProperty: false,
                    isActive: comp.isActive,
                    index: index + 1  // 1, 2, 3, ... (based on filtered results)
                )
            }

            // Calculate map region to fit all pins
            let allCoords = [searchedMarker.coordinate] + compMarkers.map { $0.coordinate }
            let mapSpan = calculateSpanToFit(coordinates: allCoords)

            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: response.latitude, longitude: response.longitude),
                span: mapSpan
            )

            // Create rent estimate result from API response
            rentEstimate = response.toRentEstimateResult()
            comparables = filteredComps
            propertyMarkers = [searchedMarker] + compMarkers
            hasSearched = true
            showResultsSheet = true

            print("───────────────────────────────────────────────────────────")
            print("✅ [SEARCH COMPLETE]")
            print("   • API returned: \(sortedComps.count) comparables")
            print("   • After client filters: \(filteredComps.count) shown")
            print("   • Rent estimate: $\(Int(response.rent))/mo")
            print("   • Map pins: 1 (searched) + \(compMarkers.count) (comparables)")
            print("═══════════════════════════════════════════════════════════")

        } catch let error as RentCastError {
            // Handle rate limit exceeded specifically
            if case .rateLimitExceeded(let remaining, let limit) = error {
                print("")
                print("🛑 [HOUSING VM] ═══════════════════════════════════════════")
                print("🛑 [HOUSING VM] RATE LIMIT EXCEEDED IN loadPopulatedArea()")
                print("🛑 [HOUSING VM] Limit: \(limit)/week, Remaining: \(remaining)")
                print("🛑 [HOUSING VM] Showing RateLimitExceededView...")
                print("🛑 [HOUSING VM] ═══════════════════════════════════════════")
                print("")
                showRateLimitExceeded = true
                rateLimitErrorMessage = error.localizedDescription
            } else {
                print("❌ [HOUSING VM] RentCast error: \(error)")
            }
            allComparables = []
            comparables = []
            propertyMarkers = []
            rentEstimate = nil
        } catch {
            print("❌ [HOUSING VM] Error loading rent estimate: \(error)")
            allComparables = []
            comparables = []
            propertyMarkers = []
            rentEstimate = nil
        }

        isLoading = false
        isInitialLoad = false
    }

    /// Calculate map span to fit all coordinates with padding
    private func calculateSpanToFit(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateSpan {
        guard !coordinates.isEmpty else {
            return MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }

        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }

        let latDelta = (lats.max()! - lats.min()!) * 1.4  // 40% padding
        let lonDelta = (lons.max()! - lons.min()!) * 1.4

        // Minimum span to ensure pins are visible
        return MKCoordinateSpan(
            latitudeDelta: max(latDelta, 0.01),
            longitudeDelta: max(lonDelta, 0.01)
        )
    }

    /// Select property and center map on it (called from card tap)
    func selectAndCenterOnProperty(id: String) {
        selectedPropertyId = id

        // Find the property's coordinate and center map on it
        if let marker = propertyMarkers.first(where: { $0.id == id }) {
            mapRegion = MKCoordinateRegion(
                center: marker.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }

    /// Handle pin selection from map
    func selectPropertyFromMap(id: String) {
        print("📌 [PIN TAP] Selected property ID: \(id)")
        selectedPropertyId = id

        // Find clicked property from FULL list
        guard let selected = allComparables.first(where: { $0.id == id }) else {
            print("📌 [PIN TAP] ❌ Property not found in allComparables!")
            return
        }

        print("📌 [PIN TAP] Selected: \(selected.address) - \(selected.bedrooms) beds")
        print("📌 [PIN TAP] allComparables count: \(allComparables.count)")
        print("📌 [PIN TAP] propertyMarkers count: \(propertyMarkers.count)")

        // Apply current filters to get valid nearby comparables
        let filteredList = filterComparables(allComparables)
        print("📌 [PIN TAP] filteredList count: \(filteredList.count)")

        // Check if selected property passes the filter
        let selectedPassesFilter = filteredList.contains { $0.id == id }
        print("📌 [PIN TAP] Selected property passes filter: \(selectedPassesFilter)")

        // Get ALL filtered comparables (sorted by distance) - removed prefix(5) limit
        let otherComparables = filteredList
            .filter { $0.id != id }
            .sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }

        print("📌 [PIN TAP] Other comparables: \(otherComparables.count)")

        // Update display list (selected first, then all others sorted by distance)
        comparables = [selected] + otherComparables
        print("📌 [PIN TAP] Final comparables count: \(comparables.count)")

        // Update estimate for selected property
        updateEstimateForProperty(id: id)
    }

    /// Update estimate panel for selected property - shows market estimate from all comparables
    func updateEstimateForProperty(id: String) {
        guard comparables.first(where: { $0.id == id }) != nil else { return }

        // Show market estimate based on all comparables, not just selected property's price
        // The selected property's actual price is visible in the listings below
        rentEstimate = aggregateEstimate()
    }

    /// Compute aggregate rent estimate - uses market stats if available (historical average)
    func aggregateEstimate() -> RentEstimateResult {
        // Use market statistics if available (historical market average from RentCast)
        if let response = marketResponse, let rentalData = response.rentalData {
            let avgRent = rentalData.averageRent
            let perSqft = rentalData.averageRentPerSquareFoot ?? (avgRent / (rentalData.averageSquareFootage ?? 1000))

            // Calculate per-bedroom from market stats
            let avgBeds: Double
            if let firstBedroom = rentalData.dataByBedrooms.first(where: { $0.bedrooms == 2 }) {
                avgBeds = avgRent / firstBedroom.averageRent * 2  // Estimate based on 2BR
            } else if !rentalData.dataByBedrooms.isEmpty {
                avgBeds = Double(rentalData.dataByBedrooms.map { $0.bedrooms }.reduce(0, +)) / Double(rentalData.dataByBedrooms.count)
            } else {
                avgBeds = 2.0
            }

            return RentEstimateResult(
                estimatedRent: avgRent,
                lowEstimate: rentalData.minRent,
                highEstimate: rentalData.maxRent,
                perSqft: perSqft,
                perBedroom: avgRent / max(avgBeds, 1),
                confidence: "High",
                comparablesCount: comparables.count
            )
        }

        // Fallback: Calculate from listings if no market stats available
        let sourceData = allComparables.isEmpty ? comparables : allComparables

        let rents = sourceData.compactMap { $0.rent }.sorted()
        let median = rents.isEmpty ? 2000 : rents[rents.count / 2]
        let low = rents.isEmpty ? 1500 : rents.first!
        let high = rents.isEmpty ? 3000 : rents.last!

        // Calculate averages from actual data
        let sqftValues = sourceData.compactMap { $0.sqft }
        let avgSqft = sqftValues.isEmpty ? 1000 : sqftValues.reduce(0, +) / sqftValues.count
        let bedsValues = sourceData.map { $0.bedrooms }
        let avgBeds = bedsValues.isEmpty ? 2 : max(bedsValues.reduce(0, +) / bedsValues.count, 1)

        return RentEstimateResult(
            estimatedRent: median,
            lowEstimate: low,
            highEstimate: high,
            perSqft: median / Double(avgSqft),
            perBedroom: median / Double(avgBeds),
            confidence: sourceData.count >= 10 ? "High" : "Medium",
            comparablesCount: sourceData.count
        )
    }

    // MARK: - Distance Calculation

    /// Calculate distance between two coordinates in miles
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distanceMeters = fromLocation.distance(from: toLocation)
        let distanceMiles = distanceMeters / 1609.34  // Convert meters to miles
        return distanceMiles
    }
}

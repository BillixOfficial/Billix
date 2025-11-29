//
//  MarketplaceViewModel.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import Foundation
import SwiftUI

/// Tab types for the Marketplace
enum MarketplaceTab: String, CaseIterable {
    case deals = "Deals"
    case clusters = "Clusters & Rallies"
    case experts = "Experts & Gigs"
    case signals = "Signals & Bets"

    var icon: String {
        switch self {
        case .deals: return "tag.fill"
        case .clusters: return "person.3.fill"
        case .experts: return "person.badge.shield.checkmark.fill"
        case .signals: return "chart.line.uptrend.xyaxis"
        }
    }

    var shortName: String {
        switch self {
        case .deals: return "Deals"
        case .clusters: return "Clusters"
        case .experts: return "Experts"
        case .signals: return "Signals"
        }
    }
}

/// Main ViewModel for Marketplace
@MainActor
class MarketplaceViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedTab: MarketplaceTab = .deals
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var showFilterSheet: Bool = false

    // Data
    @Published var billListings: [BillListing] = []
    @Published var clusters: [Cluster] = []
    @Published var bounties: [Bounty] = []
    @Published var scripts: [NegotiationScript] = []
    @Published var services: [ServiceListing] = []
    @Published var predictions: [PredictionMarket] = []
    @Published var takeovers: [ContractTakeover] = []

    // Selected items for detail views
    @Published var selectedListing: BillListing?
    @Published var selectedCluster: Cluster?

    // Sheets
    @Published var showUnlockSheet: Bool = false
    @Published var showAskOwnerSheet: Bool = false
    @Published var showPlaceBidSheet: Bool = false

    // Filters
    @Published var selectedCategories: Set<MarketplaceBillType> = []
    @Published var priceRange: ClosedRange<Double> = 0...200
    @Published var minMatchScore: Double = 0
    @Published var showVerifiedOnly: Bool = false
    @Published var filterZipCode: String = ""

    // User context (for VS ME comparisons)
    var userCurrentBills: [String: Double] = [
        "Internet": 95.00,
        "Mobile": 85.00,
        "Energy": 0.15
    ]

    // MARK: - Initialization

    init() {
        loadMockData()
    }

    // MARK: - Data Loading

    func loadMockData() {
        isLoading = true

        // Simulate network delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s

            await MainActor.run {
                self.billListings = MockMarketplaceData.billListings
                self.clusters = MockMarketplaceData.clusters
                self.bounties = MockMarketplaceData.bounties
                self.scripts = MockMarketplaceData.scripts
                self.services = MockMarketplaceData.services
                self.predictions = MockMarketplaceData.predictions
                self.takeovers = MockMarketplaceData.takeovers
                self.isLoading = false
            }
        }
    }

    func refresh() async {
        isLoading = true
        // In real app, fetch from API
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        loadMockData()
    }

    // MARK: - Filtering

    var filteredListings: [BillListing] {
        billListings.filter { listing in
            // Search text filter
            let matchesSearch = searchText.isEmpty ||
                listing.providerName.localizedCaseInsensitiveContains(searchText) ||
                listing.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                listing.zipCode.contains(searchText)

            // Category filter
            let matchesCategory = selectedCategories.isEmpty || selectedCategories.contains(listing.category)

            // Price range filter
            let matchesPrice = listing.askPrice >= priceRange.lowerBound && listing.askPrice <= priceRange.upperBound

            // Match score filter
            let matchesScore = Double(listing.matchScore) >= minMatchScore

            // Verified filter
            let matchesVerified = !showVerifiedOnly || listing.isVerified

            // ZIP code filter
            let matchesZip = filterZipCode.isEmpty || listing.zipCode.contains(filterZipCode)

            return matchesSearch && matchesCategory && matchesPrice && matchesScore && matchesVerified && matchesZip
        }
    }

    var filteredClusters: [Cluster] {
        clusters.filter { cluster in
            // Search text filter
            let matchesSearch = searchText.isEmpty ||
                cluster.title.localizedCaseInsensitiveContains(searchText) ||
                cluster.category.rawValue.localizedCaseInsensitiveContains(searchText)

            // Category filter
            let matchesCategory = selectedCategories.isEmpty || selectedCategories.contains(cluster.category)

            return matchesSearch && matchesCategory
        }
    }

    func resetFilters() {
        selectedCategories = []
        priceRange = 0...200
        minMatchScore = 0
        showVerifiedOnly = false
        filterZipCode = ""
    }

    // MARK: - User Context

    func userPriceForCategory(_ category: MarketplaceBillType) -> Double? {
        return userCurrentBills[category.rawValue]
    }

    // MARK: - Actions

    func unlockBlueprint(for listing: BillListing) {
        selectedListing = listing
        showUnlockSheet = true
    }

    func askOwner(for listing: BillListing) {
        selectedListing = listing
        showAskOwnerSheet = true
    }

    func placeBid(for cluster: Cluster) {
        selectedCluster = cluster
        showPlaceBidSheet = true
    }

    func addToWatchlist(_ listing: BillListing) {
        // TODO: Implement watchlist
        print("Added \(listing.providerName) to watchlist")
    }

    func reportListing(_ listing: BillListing) {
        // TODO: Implement reporting
        print("Reported \(listing.providerName)")
    }
}

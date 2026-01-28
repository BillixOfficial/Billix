//
//  BillExplorerViewModel.swift
//  Billix
//
//  ViewModel for the Bill Explorer feed with time-based rotation algorithm
//

import Foundation
import SwiftUI

@MainActor
class BillExplorerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var listings: [ExploreBillListing] = []
    @Published var filteredListings: [ExploreBillListing] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: String?

    // Filters
    @Published var selectedBillType: ExploreBillType?
    @Published var showBookmarkedOnly = false
    @Published var selectedRegion: USRegion = .all
    @Published var selectedState: String? = nil

    // Interactions (local state before Supabase sync)
    @Published var interactions: [UUID: BillInteraction] = [:]

    // Selected listing for detail sheet
    @Published var selectedListing: ExploreBillListing?

    // MARK: - Private Properties

    private var allListings: [ExploreBillListing] = []

    // MARK: - Computed Properties

    var billTypeFilters: [ExploreBillType] {
        ExploreBillType.allCases
    }

    var hasListings: Bool {
        !filteredListings.isEmpty
    }

    var bookmarkedCount: Int {
        interactions.values.filter { $0.isBookmarked }.count
    }

    // Backward compatibility aliases
    var selectedExploreBillType: ExploreBillType? {
        get { selectedBillType }
        set { selectedBillType = newValue }
    }

    var billTypes: [ExploreBillType] {
        billTypeFilters
    }

    // Region filtering
    var availableStates: [String] {
        guard selectedRegion != .all else { return [] }
        return selectedRegion.states.sorted()
    }

    var hasRegionFilter: Bool {
        selectedRegion != .all
    }

    var hasStateFilter: Bool {
        selectedState != nil
    }

    // MARK: - Initialization

    init() {
        // Load mock data for now
        loadMockData()
    }

    // MARK: - Data Loading

    func loadMockData() {
        isLoading = true

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            self.allListings = ExploreBillListing.mockListings
            self.applyRotationAlgorithm()
            self.applyFilters()
            self.isLoading = false
        }
    }

    func refresh() async {
        isRefreshing = true

        // Simulate network refresh
        try? await Task.sleep(nanoseconds: 500_000_000)

        // In production, fetch from Supabase here
        applyRotationAlgorithm()
        applyFilters()

        isRefreshing = false
    }

    // MARK: - Time-Based Rotation Algorithm

    /// Calculates feed order based on freshness score with periodic boosts for older listings
    private func applyRotationAlgorithm() {
        let now = Date()

        listings = allListings.sorted { a, b in
            let aScore = freshnessScore(for: a, now: now)
            let bScore = freshnessScore(for: b, now: now)
            return aScore > bScore
        }
    }

    /// Calculates freshness score for a listing
    /// - Higher score = appears earlier in feed
    /// - Score decays over time but gets engagement bonus
    private func freshnessScore(for listing: ExploreBillListing, now: Date) -> Double {
        // Use lastBoostedAt if available, otherwise lastUpdated
        let effectiveDate = listing.lastBoostedAt ?? listing.lastUpdated
        let hoursSinceActive = now.timeIntervalSince(effectiveDate) / 3600

        // Base decay: halves every 24 hours
        let decayFactor = pow(0.5, hoursSinceActive / 24)

        // Engagement bonus (votes + tips)
        let engagementBonus = Double(listing.voteScore + listing.tipCount) * 0.05

        // Verified bonus
        let verifiedBonus = listing.isVerified ? 0.1 : 0

        // Random jitter to prevent identical scores (0-5%)
        let jitter = Double.random(in: 0...0.05)

        return decayFactor + engagementBonus + verifiedBonus + jitter
    }

    // MARK: - Filtering

    func applyFilters() {
        var result = listings

        // Filter by region
        if selectedRegion != .all {
            result = result.filter { selectedRegion.contains(state: $0.state) }
        }

        // Filter by state (within region)
        if let state = selectedState {
            result = result.filter { $0.state.uppercased() == state.uppercased() }
        }

        // Filter by bill type
        if let billType = selectedBillType {
            result = result.filter { $0.billType == billType }
        }

        // Filter by bookmarked
        if showBookmarkedOnly {
            result = result.filter { listing in
                interactions[listing.id]?.isBookmarked == true
            }
        }

        filteredListings = result
    }

    // MARK: - Region/State Selection

    func selectRegion(_ region: USRegion) {
        if selectedRegion == region {
            // Tapping same region clears it
            selectedRegion = .all
            selectedState = nil
        } else {
            selectedRegion = region
            selectedState = nil  // Reset state when changing region
        }
        applyFilters()
    }

    func selectState(_ state: String?) {
        if selectedState == state {
            selectedState = nil
        } else {
            selectedState = state
        }
        applyFilters()
    }

    func selectBillType(_ type: ExploreBillType?) {
        if selectedBillType == type {
            selectedBillType = nil
        } else {
            selectedBillType = type
        }
        applyFilters()
    }

    func toggleBookmarkedOnly() {
        showBookmarkedOnly.toggle()
        applyFilters()
    }

    func clearFilters() {
        selectedRegion = .all
        selectedState = nil
        selectedBillType = nil
        showBookmarkedOnly = false
        applyFilters()
    }

    // Backward compatibility method
    func selectExploreBillType(_ type: ExploreBillType?) {
        selectBillType(type)
    }

    // Legacy reaction toggle (for old BillsExploreView)
    func toggleReaction(for listingId: UUID, reaction: BillReactionType) {
        guard let index = listings.firstIndex(where: { $0.id == listingId }) else { return }

        var updatedReactions = listings[index].reactions
        let currentCount = updatedReactions[reaction] ?? 0
        updatedReactions[reaction] = currentCount + 1

        listings[index].reactions = updatedReactions
        applyFilters()
    }

    // MARK: - Interactions

    func getInteraction(for listingId: UUID) -> BillInteraction? {
        interactions[listingId]
    }

    func getUserVote(for listingId: UUID) -> VoteType? {
        interactions[listingId]?.vote
    }

    func isBookmarked(_ listingId: UUID) -> Bool {
        interactions[listingId]?.isBookmarked ?? false
    }

    func upvote(_ listing: ExploreBillListing) {
        hapticFeedback()

        var interaction = interactions[listing.id] ?? BillInteraction(
            listingId: listing.id,
            userId: UUID() // In production, use actual user ID
        )

        if interaction.vote == .up {
            // Remove upvote
            interaction.vote = nil
        } else {
            // Add upvote (or change from downvote)
            interaction.vote = .up
        }

        interactions[listing.id] = interaction

        // Update listing's vote score (local only, sync to Supabase in production)
        updateVoteScore(for: listing.id)
    }

    func downvote(_ listing: ExploreBillListing) {
        hapticFeedback()

        var interaction = interactions[listing.id] ?? BillInteraction(
            listingId: listing.id,
            userId: UUID()
        )

        if interaction.vote == .down {
            // Remove downvote
            interaction.vote = nil
        } else {
            // Add downvote (or change from upvote)
            interaction.vote = .down
        }

        interactions[listing.id] = interaction
        updateVoteScore(for: listing.id)
    }

    func toggleBookmark(_ listing: ExploreBillListing) {
        hapticFeedback()

        var interaction = interactions[listing.id] ?? BillInteraction(
            listingId: listing.id,
            userId: UUID()
        )

        interaction.isBookmarked.toggle()
        interactions[listing.id] = interaction

        // Re-apply filters if bookmarked filter is active
        if showBookmarkedOnly {
            applyFilters()
        }
    }

    private func updateVoteScore(for listingId: UUID) {
        // In a real implementation, this would sync to Supabase
        // For now, we just trigger a UI refresh
        objectWillChange.send()
    }

    // MARK: - Detail Sheet

    func showDetail(for listing: ExploreBillListing) {
        // Increment view count
        incrementViewCount(for: listing)
        selectedListing = listing
    }

    // MARK: - View Count

    private func incrementViewCount(for listing: ExploreBillListing) {
        // Find and update the listing in our arrays
        if let index = listings.firstIndex(where: { $0.id == listing.id }) {
            listings[index].viewCount += 1
        }
        if let index = allListings.firstIndex(where: { $0.id == listing.id }) {
            allListings[index].viewCount += 1
        }
        if let index = filteredListings.firstIndex(where: { $0.id == listing.id }) {
            filteredListings[index].viewCount += 1
        }

        // TODO: Sync to Supabase in production
        // try await supabase.rpc("increment_view_count", params: ["listing_id": listing.id])
    }

    func hideDetail() {
        selectedListing = nil
    }

    // MARK: - Helpers

    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Supabase Integration (Placeholder)

extension BillExplorerViewModel {
    /// Load listings from Supabase with rotation algorithm
    func loadFromSupabase() async {
        isLoading = true
        error = nil

        // TODO: Implement Supabase fetch
        // let listings = try await supabase
        //     .from("explore_bill_listings")
        //     .select()
        //     .order("created_at", ascending: false)
        //     .execute()
        //     .value

        // For now, use mock data
        loadMockData()
    }

    /// Boost old listings (would be called by backend cron job)
    func boostOldListings() {
        let now = Date()
        let sevenDaysAgo = now.addingTimeInterval(-7 * 24 * 3600)

        // Find listings that haven't been boosted in 7+ days
        let toBoost = allListings.filter { listing in
            let lastBoost = listing.lastBoostedAt ?? listing.lastUpdated
            return lastBoost < sevenDaysAgo
        }
        .sorted { $0.lastUpdated < $1.lastUpdated }
        .prefix(50) // Boost up to 50 oldest per day

        // In production, update lastBoostedAt in Supabase
    }
}

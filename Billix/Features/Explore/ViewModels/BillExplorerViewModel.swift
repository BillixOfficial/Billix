//
//  BillExplorerViewModel.swift
//  Billix
//
//  ViewModel for the Bill Explorer feed with time-based rotation algorithm
//

import Foundation
import SwiftUI

// MARK: - Database Response Models

/// Codable struct to decode saved votes from Supabase
private struct SavedVoteRow: Codable {
    let billId: UUID
    let voteType: String

    enum CodingKeys: String, CodingKey {
        case billId = "bill_id"
        case voteType = "vote_type"
    }
}

/// Codable struct to decode saved bookmarks from Supabase
private struct SavedBookmarkRow: Codable {
    let billId: UUID

    enum CodingKeys: String, CodingKey {
        case billId = "bill_id"
    }
}

@MainActor
class BillExplorerViewModel: ObservableObject {
    // MARK: - Shared Instance

    /// Shared instance to persist interactions across navigation
    static let shared = BillExplorerViewModel()

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

    // Interactions (local state before Supabase sync) - capped to prevent unbounded growth
    @Published var interactions: [UUID: BillInteraction] = [:]
    private var interactionAccessOrder: [UUID] = []  // Track access order for LRU eviction
    private let maxInteractionsInMemory = 500

    // Selected listing for detail sheet
    @Published var selectedListing: ExploreBillListing?

    // MARK: - Private Properties

    private var allListings: [ExploreBillListing] = []
    private var refreshTask: Task<Void, Never>?  // Track current refresh to prevent duplicates

    // MARK: - Computed Properties

    var billTypeFilters: [ExploreBillType] {
        ExploreBillType.explorerTypes  // Excludes rent and insurance
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

    private init() {
        // Load real data from Supabase
        Task {
            await loadRealBills()
            await loadUserVotes()  // Load saved votes so they persist across app restarts
            await loadUserBookmarks()  // Load saved bookmarks so they persist across app restarts
        }
    }

    /// Load user's saved votes from database
    private func loadUserVotes() async {
        guard let userId = AuthService.shared.currentUser?.id else {
            print("[BillExplorer] No user logged in, skipping vote load")
            return
        }

        do {
            let votes: [SavedVoteRow] = try await SupabaseService.shared.client
                .from("bill_explorer_votes")
                .select("bill_id, vote_type")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            print("[BillExplorer] Loaded \(votes.count) saved votes")

            // Restore votes to interactions dictionary
            for vote in votes {
                if let voteType = VoteType(rawValue: vote.voteType) {
                    var interaction = interactions[vote.billId] ?? BillInteraction(
                        listingId: vote.billId,
                        userId: userId
                    )
                    interaction.vote = voteType
                    interactions[vote.billId] = interaction
                }
            }

            // Trigger UI update
            objectWillChange.send()
        } catch {
            print("[BillExplorer] Error loading votes: \(error)")
        }
    }

    /// Load user's saved bookmarks from database
    private func loadUserBookmarks() async {
        guard let userId = AuthService.shared.currentUser?.id else {
            print("[BillExplorer] No user logged in, skipping bookmark load")
            return
        }

        do {
            let bookmarks: [SavedBookmarkRow] = try await SupabaseService.shared.client
                .from("bill_explorer_bookmarks")
                .select("bill_id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            print("[BillExplorer] Loaded \(bookmarks.count) saved bookmarks")

            // Restore bookmarks to interactions dictionary
            for bookmark in bookmarks {
                var interaction = interactions[bookmark.billId] ?? BillInteraction(
                    listingId: bookmark.billId,
                    userId: userId
                )
                interaction.isBookmarked = true
                interactions[bookmark.billId] = interaction
            }

            // Trigger UI update
            objectWillChange.send()
        } catch {
            print("[BillExplorer] Error loading bookmarks: \(error)")
        }
    }

    // MARK: - Data Loading

    /// Load real bills from Supabase bill_explorer_listings view
    func loadRealBills() async {
        isLoading = true
        error = nil

        do {
            let response: [BillExplorerRow] = try await SupabaseService.shared.client
                .from("bill_explorer_listings")
                .select()
                .order("created_at", ascending: false)
                .limit(200)
                .execute()
                .value

            print("[BillExplorer] Loaded \(response.count) bills from database")

            // Filter out rent, insurance, and unknown categories (e.g., medical)
            // compactMap filters out nil values from failable init
            let validTypes = Set(ExploreBillType.explorerTypes)
            allListings = response
                .compactMap { ExploreBillListing(from: $0) }  // Filters out unknown categories
                .filter { validTypes.contains($0.billType) }  // Further filter to explorer types only

            print("[BillExplorer] After filtering: \(allListings.count) utility bills")
            applyRotationAlgorithm()
            applyFilters()
        } catch {
            print("[BillExplorer] Error loading bills: \(error)")

            // Check if this is a cancellation error (e.g., user pulled to refresh then released quickly)
            // Don't clear existing data on cancellation - keep showing what we have
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                print("[BillExplorer] Request was cancelled, keeping existing data")
                // Don't clear data, just end loading state
            } else {
                // Real error - show error state but preserve data if we have it
                self.error = error.localizedDescription
                if allListings.isEmpty {
                    // Only clear if we had no data to begin with
                    listings = []
                    filteredListings = []
                }
            }
        }

        isLoading = false
    }

    func refresh() async {
        // Cancel any existing refresh to prevent multiple concurrent requests
        refreshTask?.cancel()

        // Guard against refresh spam - if already refreshing, skip
        guard !isRefreshing else {
            print("[BillExplorer] Already refreshing, skipping duplicate request")
            return
        }

        isRefreshing = true

        refreshTask = Task {
            await loadRealBills()
        }

        await refreshTask?.value

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

    /// Calculates ranking score for a listing (Reddit-style hot algorithm)
    /// - Higher score = appears earlier in feed
    /// - Combines vote popularity with time decay
    private func freshnessScore(for listing: ExploreBillListing, now: Date) -> Double {
        // Get effective vote score including user's local vote
        let effectiveVotes = getEffectiveVoteScore(for: listing)

        // Vote score on log scale (like Reddit) - every 10x votes adds ~1 point
        // This prevents a single bill from dominating just by having slightly more votes
        let voteScore: Double
        if effectiveVotes > 0 {
            voteScore = log10(Double(effectiveVotes) + 1) * 2  // Scale up for impact
        } else if effectiveVotes < 0 {
            voteScore = -log10(Double(abs(effectiveVotes)) + 1)
        } else {
            voteScore = 0
        }

        // Time decay: newer posts get a boost
        let effectiveDate = listing.lastBoostedAt ?? listing.lastUpdated
        let hoursSinceActive = now.timeIntervalSince(effectiveDate) / 3600
        let timeScore = max(0, 24 - hoursSinceActive) / 24  // 0-1 based on how recent (within 24h)

        // Verified bonus
        let verifiedBonus = listing.isVerified ? 0.3 : 0

        // Combine: votes are primary, time is secondary
        // A bill with 10 votes beats a new bill with 0 votes
        // But a new bill with 5 votes beats an old bill with 5 votes
        return voteScore + (timeScore * 0.5) + verifiedBonus
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

    /// Get the effective vote score for display
    /// Note: The database view (bill_explorer_listings) calculates vote_score in real-time
    /// from the bill_explorer_votes table, so we just return the base score directly.
    /// After voting, we refresh the bill to get the updated score.
    func getEffectiveVoteScore(for listing: ExploreBillListing) -> Int {
        return listing.voteScore
    }

    func upvote(_ listing: ExploreBillListing) {
        hapticFeedback()

        let previousVote = interactions[listing.id]?.vote

        var interaction = interactions[listing.id] ?? BillInteraction(
            listingId: listing.id,
            userId: AuthService.shared.currentUser?.id ?? UUID()
        )

        if interaction.vote == .up {
            // Remove upvote
            interaction.vote = nil
        } else {
            // Add upvote (or change from downvote)
            interaction.vote = .up
        }

        storeInteraction(interaction, for: listing.id)
        updateVoteScore(for: listing.id)

        // Sync to Supabase in background
        Task {
            await syncVoteToDatabase(listing: listing, newVote: interaction.vote, previousVote: previousVote)
        }
    }

    func downvote(_ listing: ExploreBillListing) {
        hapticFeedback()

        let previousVote = interactions[listing.id]?.vote

        var interaction = interactions[listing.id] ?? BillInteraction(
            listingId: listing.id,
            userId: AuthService.shared.currentUser?.id ?? UUID()
        )

        if interaction.vote == .down {
            // Remove downvote
            interaction.vote = nil
        } else {
            // Add downvote (or change from upvote)
            interaction.vote = .down
        }

        storeInteraction(interaction, for: listing.id)
        updateVoteScore(for: listing.id)

        // Sync to Supabase in background
        Task {
            await syncVoteToDatabase(listing: listing, newVote: interaction.vote, previousVote: previousVote)
        }
    }

    /// Sync vote to Supabase database
    private func syncVoteToDatabase(listing: ExploreBillListing, newVote: VoteType?, previousVote: VoteType?) async {
        guard let userId = AuthService.shared.currentUser?.id else {
            print("[BillExplorer] No user logged in, vote saved locally only")
            return
        }

        do {
            if let vote = newVote {
                // Upsert vote - use onConflict to handle existing votes
                try await SupabaseService.shared.client
                    .from("bill_explorer_votes")
                    .upsert(
                        [
                            "bill_id": listing.id.uuidString,
                            "user_id": userId.uuidString,
                            "vote_type": vote.rawValue
                        ],
                        onConflict: "bill_id,user_id"  // Specify the unique constraint columns
                    )
                    .execute()
                print("[BillExplorer] Vote synced: \(vote.rawValue)")
            } else {
                // Remove vote
                try await SupabaseService.shared.client
                    .from("bill_explorer_votes")
                    .delete()
                    .eq("bill_id", value: listing.id.uuidString)
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                print("[BillExplorer] Vote removed")
            }

            // Refresh this specific bill to get updated vote_score from the view
            await refreshSingleBill(id: listing.id)

        } catch {
            print("[BillExplorer] Vote sync error: \(error)")
        }
    }

    /// Refresh a single bill's data from the database
    private func refreshSingleBill(id: UUID) async {
        do {
            let response: [BillExplorerRow] = try await SupabaseService.shared.client
                .from("bill_explorer_listings")
                .select()
                .eq("id", value: id.uuidString)
                .limit(1)
                .execute()
                .value

            guard let row = response.first,
                  let updatedListing = ExploreBillListing(from: row) else { return }

            // Update in all arrays
            if let index = allListings.firstIndex(where: { $0.id == id }) {
                allListings[index] = updatedListing
            }
            if let index = listings.firstIndex(where: { $0.id == id }) {
                listings[index] = updatedListing
            }
            if let index = filteredListings.firstIndex(where: { $0.id == id }) {
                filteredListings[index] = updatedListing
            }
            if selectedListing?.id == id {
                selectedListing = updatedListing
            }

            print("[BillExplorer] Refreshed bill \(id), new vote_score: \(updatedListing.voteScore)")
        } catch {
            print("[BillExplorer] Refresh single bill error: \(error)")
        }
    }

    func toggleBookmark(_ listing: ExploreBillListing) {
        hapticFeedback()

        var interaction = interactions[listing.id] ?? BillInteraction(
            listingId: listing.id,
            userId: AuthService.shared.currentUser?.id ?? UUID()
        )

        let wasBookmarked = interaction.isBookmarked
        interaction.isBookmarked.toggle()
        storeInteraction(interaction, for: listing.id)

        // Re-apply filters if bookmarked filter is active
        if showBookmarkedOnly {
            applyFilters()
        }

        // Sync to Supabase in background
        Task {
            await syncBookmarkToDatabase(listing: listing, isBookmarked: interaction.isBookmarked)
        }
    }

    /// Sync bookmark to Supabase database
    private func syncBookmarkToDatabase(listing: ExploreBillListing, isBookmarked: Bool) async {
        guard let userId = AuthService.shared.currentUser?.id else {
            print("[BillExplorer] No user logged in, bookmark saved locally only")
            return
        }

        do {
            if isBookmarked {
                // Insert bookmark - use upsert to handle existing entries
                try await SupabaseService.shared.client
                    .from("bill_explorer_bookmarks")
                    .upsert(
                        [
                            "bill_id": listing.id.uuidString,
                            "user_id": userId.uuidString
                        ],
                        onConflict: "bill_id,user_id"
                    )
                    .execute()
                print("[BillExplorer] Bookmark synced: added")
            } else {
                // Remove bookmark
                try await SupabaseService.shared.client
                    .from("bill_explorer_bookmarks")
                    .delete()
                    .eq("bill_id", value: listing.id.uuidString)
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                print("[BillExplorer] Bookmark synced: removed")
            }
        } catch {
            print("[BillExplorer] Bookmark sync error: \(error)")
        }
    }

    private func updateVoteScore(for listingId: UUID) {
        // Don't re-sort immediately - this prevents the card from jumping away
        // when user votes in the middle of the feed. Re-sort will happen on:
        // - Pull to refresh
        // - Return to screen
        // - Next loadRealBills() call
        //
        // The score updates visually via getEffectiveVoteScore() which includes
        // the user's local vote adjustment for optimistic updates.
        objectWillChange.send()

        // TODO: In production, also sync to Supabase
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

    /// Store interaction with LRU eviction to prevent unbounded memory growth
    private func storeInteraction(_ interaction: BillInteraction, for listingId: UUID) {
        // Update access order (move to end if exists, or add to end)
        interactionAccessOrder.removeAll { $0 == listingId }
        interactionAccessOrder.append(listingId)

        // Store the interaction
        interactions[listingId] = interaction

        // Evict oldest interactions if over limit (preserve bookmarked items)
        while interactions.count > maxInteractionsInMemory {
            guard let oldestId = interactionAccessOrder.first else { break }

            // Don't evict bookmarked items
            if interactions[oldestId]?.isBookmarked == true {
                // Move to end of access order (keep it longer)
                interactionAccessOrder.removeFirst()
                interactionAccessOrder.append(oldestId)
                continue
            }

            // Evict the oldest non-bookmarked interaction
            interactionAccessOrder.removeFirst()
            interactions.removeValue(forKey: oldestId)
        }
    }
}

// MARK: - Supabase Integration

extension BillExplorerViewModel {
    /// Vote on a bill (syncs to Supabase)
    func voteOnBill(_ listing: ExploreBillListing, voteType: VoteType) async {
        guard let userId = AuthService.shared.currentUser?.id else {
            print("[BillExplorer] No user logged in, cannot vote")
            return
        }

        // Optimistic update
        if voteType == .up {
            upvote(listing)
        } else {
            downvote(listing)
        }

        // Sync to Supabase
        do {
            try await SupabaseService.shared.client
                .from("bill_explorer_votes")
                .upsert([
                    "bill_id": listing.id.uuidString,
                    "user_id": userId.uuidString,
                    "vote_type": voteType.rawValue
                ])
                .execute()

            print("[BillExplorer] Vote synced to database")

            // Refresh to get updated vote count
            await refreshBill(id: listing.id)
        } catch {
            print("[BillExplorer] Vote sync error: \(error)")
        }
    }

    /// Remove vote from a bill
    func removeVote(from listing: ExploreBillListing) async {
        guard let userId = AuthService.shared.currentUser?.id else { return }

        do {
            try await SupabaseService.shared.client
                .from("bill_explorer_votes")
                .delete()
                .eq("bill_id", value: listing.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()

            // Refresh to get updated vote count
            await refreshBill(id: listing.id)
        } catch {
            print("[BillExplorer] Remove vote error: \(error)")
        }
    }

    /// Refresh a single bill's data
    private func refreshBill(id: UUID) async {
        do {
            let response: [BillExplorerRow] = try await SupabaseService.shared.client
                .from("bill_explorer_listings")
                .select()
                .eq("id", value: id.uuidString)
                .limit(1)
                .execute()
                .value

            guard let row = response.first,
                  let updatedListing = ExploreBillListing(from: row) else { return }

            // Update in all arrays
            if let index = allListings.firstIndex(where: { $0.id == id }) {
                allListings[index] = updatedListing
            }
            if let index = listings.firstIndex(where: { $0.id == id }) {
                listings[index] = updatedListing
            }
            if let index = filteredListings.firstIndex(where: { $0.id == id }) {
                filteredListings[index] = updatedListing
            }
            if selectedListing?.id == id {
                selectedListing = updatedListing
            }
        } catch {
            print("[BillExplorer] Refresh bill error: \(error)")
        }
    }

    /// Boost old listings (would be called by backend cron job)
    func boostOldListings() {
        let now = Date()
        let sevenDaysAgo = now.addingTimeInterval(-7 * 24 * 3600)

        // Find listings that haven't been boosted in 7+ days
        _ = allListings.filter { listing in
            let lastBoost = listing.lastBoostedAt ?? listing.lastUpdated
            return lastBoost < sevenDaysAgo
        }
        .sorted { $0.lastUpdated < $1.lastUpdated }
        .prefix(50) // Boost up to 50 oldest per day

        // In production, update lastBoostedAt in Supabase
    }
}

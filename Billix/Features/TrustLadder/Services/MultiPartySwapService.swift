//
//  MultiPartySwapService.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Service for managing fractional, multi-party, and flexible swaps
//

import Foundation
import Supabase
import Combine

// MARK: - Multi-Party Swap Service

@MainActor
class MultiPartySwapService: ObservableObject {

    // MARK: - Singleton
    static let shared = MultiPartySwapService()

    // MARK: - Published Properties
    @Published var activeSwaps: [MultiPartySwap] = []
    @Published var myOrganizedSwaps: [MultiPartySwap] = []
    @Published var myParticipations: [SwapParticipant] = []
    @Published var availableSwaps: [MultiPartySwap] = []
    @Published var priorityListings: [PriorityListing] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var subscriptionService: SubscriptionService {
        SubscriptionService.shared
    }

    private var creditsService: UnlockCreditsService {
        UnlockCreditsService.shared
    }

    private var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    // MARK: - Initialization

    private init() {
        Task {
            await loadMySwaps()
        }
    }

    // MARK: - Load Swaps

    /// Loads all swaps organized by the current user
    func loadMySwaps() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // Load organized swaps
            let organized: [MultiPartySwap] = try await supabase
                .from("multi_party_swaps")
                .select()
                .eq("organizer_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            myOrganizedSwaps = organized

            // Load participations
            let participations: [SwapParticipant] = try await supabase
                .from("swap_participants")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            myParticipations = participations

            // Combine active swaps
            activeSwaps = organized.filter { $0.swapStatus?.isActive ?? false }

        } catch {
            self.error = "Failed to load swaps: \(error.localizedDescription)"
            print("Failed to load swaps: \(error)")
        }
    }

    /// Loads available swaps to join
    func loadAvailableSwaps(category: ReceiptBillCategory? = nil, limit: Int = 20) async {
        guard let userId = currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let query = supabase
                .from("multi_party_swaps")
                .select()
                .eq("status", value: MultiPartySwapStatus.recruiting.rawValue)
                .neq("organizer_id", value: userId.uuidString)

            let swaps: [MultiPartySwap] = try await query
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            // Filter by tier access
            availableSwaps = swaps.filter { swap in
                guard let swapType = swap.type else { return true }
                return subscriptionService.hasAccess(to: swapType.requiredFeature)
            }

            // Sort by priority listings first
            await sortByPriority()

        } catch {
            self.error = "Failed to load available swaps: \(error.localizedDescription)"
            print("Failed to load available swaps: \(error)")
        }
    }

    // MARK: - Create Swaps

    /// Creates a new fractional swap
    func createFractionalSwap(request: FractionalSwapRequest) async throws -> MultiPartySwap {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        // Check feature access
        guard subscriptionService.hasAccess(to: .fractionalSwaps) else {
            throw SwapError.featureNotAvailable
        }

        // Validate request
        guard request.isValid else {
            throw SwapError.invalidRequest
        }

        let tierRequired = subscriptionService.currentTier.rawTierValue

        let insert = MultiPartySwapInsert(
            swapType: SwapType.fractional.rawValue,
            status: MultiPartySwapStatus.recruiting.rawValue,
            organizerId: userId.uuidString,
            targetBillId: request.targetBillId?.uuidString,
            targetAmount: request.targetAmount,
            filledAmount: 0,
            minContribution: request.minContribution,
            maxParticipants: request.maxParticipants,
            groupId: nil,
            executionDeadline: request.executionDeadline.map { ISO8601DateFormatter().string(from: $0) },
            tierRequired: tierRequired
        )

        let swap: MultiPartySwap = try await supabase
            .from("multi_party_swaps")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        // Add organizer as first participant
        try await addParticipant(
            to: swap.id,
            contribution: request.targetAmount, // Organizer's target
            billId: request.targetBillId
        )

        await loadMySwaps()

        // Record feed event
        await MarketplaceFeedService.shared.recordEvent(
            type: .newListing,
            category: request.category,
            amount: request.targetAmount
        )

        return swap
    }

    /// Creates a multi-party swap (multiple contributors to one bill)
    func createMultiPartySwap(
        targetAmount: Decimal,
        minContribution: Decimal,
        maxParticipants: Int,
        category: ReceiptBillCategory,
        deadline: Date?
    ) async throws -> MultiPartySwap {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        guard subscriptionService.hasAccess(to: .multiPartySwaps) else {
            throw SwapError.featureNotAvailable
        }

        let tierRequired = subscriptionService.currentTier.rawTierValue

        let insert = MultiPartySwapInsert(
            swapType: SwapType.multiParty.rawValue,
            status: MultiPartySwapStatus.recruiting.rawValue,
            organizerId: userId.uuidString,
            targetBillId: nil,
            targetAmount: targetAmount,
            filledAmount: 0,
            minContribution: minContribution,
            maxParticipants: maxParticipants,
            groupId: nil,
            executionDeadline: deadline.map { ISO8601DateFormatter().string(from: $0) },
            tierRequired: tierRequired
        )

        let swap: MultiPartySwap = try await supabase
            .from("multi_party_swaps")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        await loadMySwaps()

        await MarketplaceFeedService.shared.recordEvent(
            type: .newListing,
            category: category,
            amount: targetAmount
        )

        return swap
    }

    // MARK: - Participate in Swaps

    /// Join a swap with a contribution
    func joinSwap(_ swapId: UUID, contribution: Decimal, billId: UUID? = nil) async throws {
        guard currentUserId != nil else {
            throw SwapError.notAuthenticated
        }

        // Load swap details
        let swap: MultiPartySwap = try await supabase
            .from("multi_party_swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .single()
            .execute()
            .value

        // Validate
        guard swap.swapStatus == .recruiting else {
            throw SwapError.swapNotRecruiting
        }

        if let minContribution = swap.minContribution, contribution < minContribution {
            throw SwapError.contributionTooLow
        }

        if contribution > swap.remainingAmount {
            throw SwapError.contributionTooHigh
        }

        // Check tier requirement
        guard let swapType = swap.type,
              subscriptionService.hasAccess(to: swapType.requiredFeature) else {
            throw SwapError.featureNotAvailable
        }

        // Add participant
        try await addParticipant(to: swapId, contribution: contribution, billId: billId)

        // Update filled amount
        let newFilledAmount = swap.filledAmount + contribution
        var newStatus = swap.status

        if newFilledAmount >= swap.targetAmount {
            newStatus = MultiPartySwapStatus.filled.rawValue
        }

        let update = MultiPartySwapUpdate(
            filledAmount: newFilledAmount,
            status: newStatus,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("multi_party_swaps")
            .update(update)
            .eq("id", value: swapId.uuidString)
            .execute()

        await loadMySwaps()

        // Record feed event
        await MarketplaceFeedService.shared.recordEvent(
            type: .swapMatched,
            amount: contribution
        )
    }

    /// Adds a participant to a swap
    private func addParticipant(to swapId: UUID, contribution: Decimal, billId: UUID?) async throws {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        let insert = SwapParticipantInsert(
            swapId: swapId.uuidString,
            userId: userId.uuidString,
            billId: billId?.uuidString,
            contributionAmount: contribution,
            status: ParticipantStatus.pending.rawValue,
            feePaid: false
        )

        try await supabase
            .from("swap_participants")
            .insert(insert)
            .execute()
    }

    // MARK: - Participant Actions

    /// Confirms participation (after reviewing details)
    func confirmParticipation(_ participantId: UUID) async throws {
        try await updateParticipantStatus(participantId, status: .confirmed)
    }

    /// Marks payment as completed
    func markPaymentCompleted(_ participantId: UUID) async throws {
        try await updateParticipantStatus(participantId, status: .paid)
    }

    /// Uploads screenshot for verification
    func uploadScreenshot(_ participantId: UUID, imageUrl: String) async throws {
        try await supabase
            .from("swap_participants")
            .update([
                "screenshot_url": imageUrl,
                "status": ParticipantStatus.paid.rawValue
            ])
            .eq("id", value: participantId.uuidString)
            .execute()

        await loadMySwaps()
    }

    /// Verifies a participant's screenshot
    func verifyScreenshot(_ participantId: UUID, verified: Bool) async throws {
        let newStatus = verified ? ParticipantStatus.verified : ParticipantStatus.pending

        let update = ParticipantVerificationUpdate(
            screenshotVerified: verified,
            status: newStatus.rawValue,
            completedAt: verified ? ISO8601DateFormatter().string(from: Date()) : nil
        )
        try await supabase
            .from("swap_participants")
            .update(update)
            .eq("id", value: participantId.uuidString)
            .execute()

        await loadMySwaps()

        // Check if swap is complete
        if verified {
            await checkSwapCompletion(participantId: participantId)
        }
    }

    /// Updates participant status
    private func updateParticipantStatus(_ participantId: UUID, status: ParticipantStatus) async throws {
        try await supabase
            .from("swap_participants")
            .update(["status": status.rawValue])
            .eq("id", value: participantId.uuidString)
            .execute()

        await loadMySwaps()
    }

    // MARK: - Swap Status Management

    /// Starts a swap (moves from filled to in_progress)
    func startSwap(_ swapId: UUID) async throws {
        try await updateSwapStatus(swapId, status: .inProgress)
    }

    /// Completes a swap
    func completeSwap(_ swapId: UUID) async throws {
        try await updateSwapStatus(swapId, status: .completed)

        // Award credits to participants
        let participants = try await loadParticipants(for: swapId)
        for participant in participants where participant.participantStatus == .verified {
            try? await creditsService.earnCredits(
                UnlockCreditsService.swapCompletionCredits,
                type: UnlockCreditType.swapCompletion,
                description: "Multi-party swap completed"
            )
        }

        // Record feed event
        await MarketplaceFeedService.shared.recordEvent(type: .swapCompleted)
    }

    /// Cancels a swap
    func cancelSwap(_ swapId: UUID) async throws {
        try await updateSwapStatus(swapId, status: .cancelled)
        await loadMySwaps()
    }

    /// Updates swap status
    private func updateSwapStatus(_ swapId: UUID, status: MultiPartySwapStatus) async throws {
        try await supabase
            .from("multi_party_swaps")
            .update([
                "status": status.rawValue,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: swapId.uuidString)
            .execute()

        await loadMySwaps()
    }

    /// Checks if all participants verified and completes swap
    private func checkSwapCompletion(participantId: UUID) async {
        do {
            // Get participant to find swap
            let participant: SwapParticipant = try await supabase
                .from("swap_participants")
                .select()
                .eq("id", value: participantId.uuidString)
                .single()
                .execute()
                .value

            // Get all participants for this swap
            let allParticipants = try await loadParticipants(for: participant.swapId)

            // Check if all are verified
            let allVerified = allParticipants.allSatisfy { $0.participantStatus == .verified }

            if allVerified {
                try await completeSwap(participant.swapId)
            }
        } catch {
            print("Error checking swap completion: \(error)")
        }
    }

    // MARK: - Load Participants

    /// Loads participants for a swap
    func loadParticipants(for swapId: UUID) async throws -> [SwapParticipant] {
        try await supabase
            .from("swap_participants")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    /// Gets swap summary with participants
    func getSwapSummary(_ swapId: UUID) async throws -> MultiPartySwapSummary {
        let swap: MultiPartySwap = try await supabase
            .from("multi_party_swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .single()
            .execute()
            .value

        let participants = try await loadParticipants(for: swapId)

        // In production, would fetch organizer name
        return MultiPartySwapSummary(
            swap: swap,
            participants: participants,
            organizerName: nil
        )
    }

    // MARK: - Priority Listings

    /// Creates a priority listing for a swap
    func createPriorityListing(
        swapId: UUID,
        boostMultiplier: Double = 1.5,
        durationHours: Int = 24
    ) async throws {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        guard subscriptionService.hasAccess(to: .priorityListings) else {
            throw SwapError.featureNotAvailable
        }

        let expiresAt = Date().addingTimeInterval(TimeInterval(durationHours * 3600))

        let listing = PriorityListing(
            swapId: swapId,
            userId: userId,
            isActive: true,
            boostMultiplier: boostMultiplier,
            expiresAt: expiresAt,
            createdAt: Date()
        )

        // Store priority listing
        let insert = PriorityListingInsert(
            swapId: swapId.uuidString,
            userId: userId.uuidString,
            isActive: true,
            boostMultiplier: boostMultiplier,
            expiresAt: ISO8601DateFormatter().string(from: expiresAt)
        )
        try await supabase
            .from("priority_listings")
            .insert(insert)
            .execute()

        priorityListings.append(listing)
    }

    /// Sorts available swaps by priority
    private func sortByPriority() async {
        // Load active priority listings
        do {
            let listings: [PriorityListingDB] = try await supabase
                .from("priority_listings")
                .select()
                .eq("is_active", value: true)
                .gte("expires_at", value: ISO8601DateFormatter().string(from: Date()))
                .execute()
                .value

            let prioritySwapIds = Set(listings.map { $0.swapId })

            // Sort: priority first, then by date
            availableSwaps.sort { swap1, swap2 in
                let isPriority1 = prioritySwapIds.contains(swap1.id.uuidString)
                let isPriority2 = prioritySwapIds.contains(swap2.id.uuidString)

                if isPriority1 != isPriority2 {
                    return isPriority1
                }
                return swap1.createdAt > swap2.createdAt
            }
        } catch {
            print("Error loading priority listings: \(error)")
        }
    }

    // MARK: - Contribution Options

    /// Gets contribution options for a swap
    func contributionOptions(for swap: MultiPartySwap) -> [ContributionOption] {
        let remaining = swap.remainingAmount
        return ContributionOption.options(for: remaining)
    }

    // MARK: - Ratings

    /// Rate a participant
    func rateParticipant(_ participantId: UUID, rating: Int) async throws {
        guard rating >= 1 && rating <= 5 else {
            throw SwapError.invalidRating
        }

        try await supabase
            .from("swap_participants")
            .update(["rating_given": rating])
            .eq("id", value: participantId.uuidString)
            .execute()
    }

    // MARK: - Cleanup

    /// Expires old recruiting swaps
    func expireOldSwaps() async {
        let cutoff = Date().addingTimeInterval(-7 * 24 * 3600) // 7 days
        let formatter = ISO8601DateFormatter()

        do {
            try await supabase
                .from("multi_party_swaps")
                .update(["status": MultiPartySwapStatus.expired.rawValue])
                .eq("status", value: MultiPartySwapStatus.recruiting.rawValue)
                .lt("created_at", value: formatter.string(from: cutoff))
                .execute()
        } catch {
            print("Error expiring old swaps: \(error)")
        }
    }

    func reset() {
        activeSwaps = []
        myOrganizedSwaps = []
        myParticipations = []
        availableSwaps = []
        priorityListings = []
    }
}

// MARK: - Helper Structs

private struct PriorityListingDB: Codable {
    let id: UUID
    let swapId: String
    let userId: String
    let isActive: Bool
    let boostMultiplier: Double
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case userId = "user_id"
        case isActive = "is_active"
        case boostMultiplier = "boost_multiplier"
        case expiresAt = "expires_at"
    }
}

// MARK: - Swap Errors

enum SwapError: LocalizedError {
    case notAuthenticated
    case featureNotAvailable
    case invalidRequest
    case swapNotFound
    case swapNotRecruiting
    case contributionTooLow
    case contributionTooHigh
    case alreadyParticipating
    case invalidRating

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .featureNotAvailable:
            return "Upgrade your subscription to access this feature"
        case .invalidRequest:
            return "Invalid swap request"
        case .swapNotFound:
            return "Swap not found"
        case .swapNotRecruiting:
            return "This swap is no longer accepting participants"
        case .contributionTooLow:
            return "Contribution below minimum amount"
        case .contributionTooHigh:
            return "Contribution exceeds remaining amount"
        case .alreadyParticipating:
            return "You're already participating in this swap"
        case .invalidRating:
            return "Rating must be between 1 and 5"
        }
    }
}

// MARK: - Extension for BillixSubscriptionTier

extension BillixSubscriptionTier {
    var rawTierValue: Int {
        switch self {
        case .free: return 0
        case .basic: return 1
        case .pro: return 2
        case .premium: return 3
        }
    }
}

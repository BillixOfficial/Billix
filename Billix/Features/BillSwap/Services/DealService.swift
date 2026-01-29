//
//  DealService.swift
//  Billix
//
//  Service for managing deal/terms negotiations in BillSwap
//

import Foundation
import Supabase

/// Service for deal CRUD operations and negotiation flow
@MainActor
class DealService: ObservableObject {

    // MARK: - Singleton

    static let shared = DealService()

    // MARK: - Published Properties

    @Published var currentDeal: SwapDeal?
    @Published var dealHistory: [SwapDeal] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    private init() {}

    // MARK: - Fetch Deals

    /// Get the current active deal for a swap
    func getCurrentDeal(for swapId: UUID) async throws -> SwapDeal? {
        let deals: [SwapDeal] = try await supabase
            .from("swap_deals")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .order("version", ascending: false)
            .limit(1)
            .execute()
            .value

        currentDeal = deals.first
        return deals.first
    }

    /// Get all deals for a swap (history)
    func getDealHistory(for swapId: UUID) async throws -> [SwapDeal] {
        let deals: [SwapDeal] = try await supabase
            .from("swap_deals")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .order("version", ascending: true)
            .execute()
            .value

        dealHistory = deals
        return deals
    }

    // MARK: - Create Deal

    /// Propose new deal terms
    func proposeDeal(swapId: UUID, terms: DealTermsInput) async throws -> SwapDeal {
        guard let userId = currentUserId else {
            throw DealError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Check if there's already an active deal
        if let existing = try await getCurrentDeal(for: swapId),
           existing.status == .proposed || existing.status == .countered {
            throw DealError.dealAlreadyPending
        }

        // Get current version (for counter-offers)
        let currentVersion = dealHistory.last?.version ?? 0

        let insert = SwapDealInsert(
            swapId: swapId,
            proposerId: userId,
            terms: terms,
            version: currentVersion + 1
        )

        let deal: SwapDeal = try await supabase
            .from("swap_deals")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        // Log event
        try await SwapEventService.shared.logEvent(
            swapId: swapId,
            type: currentVersion == 0 ? .dealProposed : .dealCountered,
            payload: .dealProposed(deal: deal)
        )

        currentDeal = deal
        return deal
    }

    // MARK: - Counter Deal

    /// Send a counter-offer with modified terms
    func counterDeal(dealId: UUID, newTerms: DealTermsInput) async throws -> SwapDeal {
        guard let userId = currentUserId else {
            throw DealError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Get the current deal
        let deals: [SwapDeal] = try await supabase
            .from("swap_deals")
            .select()
            .eq("id", value: dealId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let currentDeal = deals.first else {
            throw DealError.dealNotFound
        }

        // Verify user can counter (not the proposer)
        guard currentDeal.proposerId != userId else {
            throw DealError.cannotCounterOwnDeal
        }

        // Check version limit
        guard currentDeal.version < 3 else {
            throw DealError.maxCountersReached
        }

        // Check expiration
        guard !currentDeal.isExpired else {
            throw DealError.dealExpired
        }

        // Update old deal status to countered
        try await supabase
            .from("swap_deals")
            .update(["status": DealStatus.countered.rawValue, "responded_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: dealId.uuidString)
            .execute()

        // Create new deal with incremented version
        let insert = SwapDealInsert(
            swapId: currentDeal.swapId,
            proposerId: userId,
            terms: newTerms,
            version: currentDeal.version + 1
        )

        let newDeal: SwapDeal = try await supabase
            .from("swap_deals")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        // Log event
        try await SwapEventService.shared.logEvent(
            swapId: currentDeal.swapId,
            type: .dealCountered,
            payload: .dealProposed(deal: newDeal)
        )

        self.currentDeal = newDeal
        return newDeal
    }

    // MARK: - Accept Deal

    /// Accept the proposed deal terms
    func acceptDeal(dealId: UUID) async throws {
        guard let userId = currentUserId else {
            throw DealError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Get the deal
        let deals: [SwapDeal] = try await supabase
            .from("swap_deals")
            .select()
            .eq("id", value: dealId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let deal = deals.first else {
            throw DealError.dealNotFound
        }

        // Verify user can accept (not the proposer)
        guard deal.proposerId != userId else {
            throw DealError.cannotAcceptOwnDeal
        }

        // Check deal is still pending
        guard deal.status == .proposed || deal.status == .countered else {
            throw DealError.dealNotPending
        }

        // Check expiration
        guard !deal.isExpired else {
            throw DealError.dealExpired
        }

        // Update deal status
        try await supabase
            .from("swap_deals")
            .update(["status": DealStatus.accepted.rawValue, "responded_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: dealId.uuidString)
            .execute()

        // Log event
        try await SwapEventService.shared.logEvent(
            swapId: deal.swapId,
            type: .dealAccepted,
            payload: SwapEventPayload(dealId: deal.id, dealVersion: deal.version)
        )

        // Activate the swap
        try await supabase
            .from("swaps")
            .update(["status": BillSwapStatus.active.rawValue])
            .eq("id", value: deal.swapId.uuidString)
            .execute()

        // Log swap activation event
        try await SwapEventService.shared.logEvent(
            swapId: deal.swapId,
            type: .swapActivated,
            payload: nil
        )

        // Lock collateral for both users
        try await CollateralService.shared.lockCollateralForSwap(swapId: deal.swapId, fallbackType: deal.fallbackIfLate)

        // Create chat conversation between parties
        try await createSwapConversation(for: deal.swapId)

        // Refresh current deal
        _ = try await getCurrentDeal(for: deal.swapId)
    }

    // MARK: - Reject Deal

    /// Reject the proposed deal terms
    func rejectDeal(dealId: UUID, reason: String? = nil) async throws {
        guard let userId = currentUserId else {
            throw DealError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Get the deal
        let deals: [SwapDeal] = try await supabase
            .from("swap_deals")
            .select()
            .eq("id", value: dealId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let deal = deals.first else {
            throw DealError.dealNotFound
        }

        // Verify user can reject (not the proposer)
        guard deal.proposerId != userId else {
            throw DealError.cannotRejectOwnDeal
        }

        // Update deal status
        try await supabase
            .from("swap_deals")
            .update(["status": DealStatus.rejected.rawValue, "responded_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: dealId.uuidString)
            .execute()

        // Log event
        try await SwapEventService.shared.logEvent(
            swapId: deal.swapId,
            type: .dealRejected,
            payload: reason != nil ? .withNote(reason!) : nil
        )

        // Refresh
        _ = try await getCurrentDeal(for: deal.swapId)
    }

    // MARK: - Helper Methods

    /// Create a conversation linked to the swap
    private func createSwapConversation(for swapId: UUID) async throws {
        // Get the swap to find both users
        let swaps: [BillSwapTransaction] = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let swap = swaps.first else { return }

        // Check if conversation already exists
        let existing: [Conversation] = try await supabase
            .from("conversations")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .limit(1)
            .execute()
            .value

        guard existing.isEmpty else { return }

        // Create new swap-linked conversation
        struct ConversationInsert: Encodable {
            let participant1Id: UUID
            let participant2Id: UUID
            let swapId: UUID
            let isSwapChat: Bool

            enum CodingKeys: String, CodingKey {
                case participant1Id = "participant_1_id"
                case participant2Id = "participant_2_id"
                case swapId = "swap_id"
                case isSwapChat = "is_swap_chat"
            }
        }

        let insert = ConversationInsert(
            participant1Id: swap.userAId,
            participant2Id: swap.userBId,
            swapId: swapId,
            isSwapChat: true
        )

        try await supabase
            .from("conversations")
            .insert(insert)
            .execute()

        // Log chat unlocked event
        try await SwapEventService.shared.logEvent(
            swapId: swapId,
            type: .chatUnlocked,
            payload: nil
        )
    }

    /// Check if user can propose terms for a swap
    func canPropose(for swapId: UUID) async throws -> Bool {
        guard currentUserId != nil else { return false }

        if let deal = try await getCurrentDeal(for: swapId) {
            // Can only propose if no pending deal or if it's expired
            return deal.status == .rejected || deal.status == .expired || deal.isExpired
        }

        // No deal exists, can propose
        return true
    }
}

// MARK: - Deal Errors

enum DealError: LocalizedError {
    case notAuthenticated
    case dealNotFound
    case dealAlreadyPending
    case cannotCounterOwnDeal
    case cannotAcceptOwnDeal
    case cannotRejectOwnDeal
    case dealNotPending
    case dealExpired
    case maxCountersReached

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .dealNotFound:
            return "Terms not found"
        case .dealAlreadyPending:
            return "There's already a pending offer"
        case .cannotCounterOwnDeal:
            return "You can't counter your own offer"
        case .cannotAcceptOwnDeal:
            return "You can't accept your own offer"
        case .cannotRejectOwnDeal:
            return "You can't reject your own offer"
        case .dealNotPending:
            return "This offer is no longer pending"
        case .dealExpired:
            return "This offer has expired"
        case .maxCountersReached:
            return "Maximum counter-offers reached (3)"
        }
    }
}

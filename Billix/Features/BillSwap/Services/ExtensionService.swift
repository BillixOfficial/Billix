//
//  ExtensionService.swift
//  Billix
//
//  Service for managing deadline extension/renegotiation requests
//

import Foundation
import Supabase

/// Service for extension request CRUD and workflow management
@MainActor
class ExtensionService: ObservableObject {

    // MARK: - Singleton

    static let shared = ExtensionService()

    // MARK: - Constants

    /// Maximum extensions allowed per swap
    static let maxExtensionsPerSwap = 2

    /// Maximum days that can be extended at once
    static let maxExtensionDays = 7

    /// Hours given to respond to extension request
    static let responseWindowHours = 24

    // MARK: - Published Properties

    @Published var currentRequest: ExtensionRequest?
    @Published var requestHistory: [ExtensionRequest] = []
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

    // MARK: - Fetch Extensions

    /// Get the current pending extension for a swap
    func getPendingRequest(for swapId: UUID) async throws -> ExtensionRequest? {
        let requests: [ExtensionRequest] = try await supabase
            .from("extension_requests")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .eq("status", value: ExtensionStatus.pending.rawValue)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        // Check if request has expired
        if let request = requests.first, request.isExpired {
            try await expireRequest(requestId: request.id)
            currentRequest = nil
            return nil
        }

        currentRequest = requests.first
        return requests.first
    }

    /// Get all extension requests for a swap
    func getRequestHistory(for swapId: UUID) async throws -> [ExtensionRequest] {
        let requests: [ExtensionRequest] = try await supabase
            .from("extension_requests")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        requestHistory = requests
        return requests
    }

    /// Get extension request count for a swap
    func getExtensionCount(for swapId: UUID) async throws -> Int {
        let requests: [ExtensionRequest] = try await supabase
            .from("extension_requests")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .in("status", values: [ExtensionStatus.approved.rawValue, ExtensionStatus.pending.rawValue])
            .execute()
            .value

        return requests.count
    }

    // MARK: - Create Extension Request

    /// Request a deadline extension
    func requestExtension(
        swapId: UUID,
        input: ExtensionRequestInput
    ) async throws -> ExtensionRequest {
        guard let userId = currentUserId else {
            throw ExtensionError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Check extension count limit
        let existingCount = try await getExtensionCount(for: swapId)
        guard existingCount < Self.maxExtensionsPerSwap else {
            throw ExtensionError.maxExtensionsReached
        }

        // Check if there's already a pending request
        if let pending = try await getPendingRequest(for: swapId) {
            throw ExtensionError.requestAlreadyPending
        }

        // Get the current deadline from the swap/deal
        let deadline = try await getCurrentDeadline(for: swapId, userId: userId)

        // Validate extension duration
        let daysRequested = Calendar.current.dateComponents(
            [.day],
            from: deadline,
            to: input.requestedDeadline
        ).day ?? 0

        guard daysRequested > 0 && daysRequested <= Self.maxExtensionDays else {
            throw ExtensionError.invalidDuration
        }

        // Create the request
        let insert = ExtensionRequestInsert(
            swapId: swapId,
            requesterId: userId,
            originalDeadline: deadline,
            input: input
        )

        let request: ExtensionRequest = try await supabase
            .from("extension_requests")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        // Log event
        try await SwapEventService.shared.logEvent(
            swapId: swapId,
            type: .extensionRequested,
            payload: .extensionRequested(
                extensionId: request.id,
                reason: input.reason.displayName,
                requestedDeadline: input.requestedDeadline,
                partialPaymentAmount: input.partialPaymentAmount
            )
        )

        currentRequest = request
        return request
    }

    // MARK: - Respond to Extension

    /// Approve an extension request
    func approveExtension(requestId: UUID) async throws {
        guard let userId = currentUserId else {
            throw ExtensionError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Get the request
        let requests: [ExtensionRequest] = try await supabase
            .from("extension_requests")
            .select()
            .eq("id", value: requestId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let request = requests.first else {
            throw ExtensionError.requestNotFound
        }

        // Verify user can respond
        guard request.canRespond(userId: userId) else {
            throw ExtensionError.cannotRespond
        }

        // Update request status
        try await supabase
            .from("extension_requests")
            .update([
                "status": ExtensionStatus.approved.rawValue,
                "responded_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: requestId.uuidString)
            .execute()

        // Update the swap/deal deadline
        try await updateDeadline(
            swapId: request.swapId,
            userId: request.requesterId,
            newDeadline: request.requestedDeadline
        )

        // Log event
        try await SwapEventService.shared.logEvent(
            swapId: request.swapId,
            type: .extensionApproved,
            payload: .extensionRequested(
                extensionId: request.id,
                reason: request.reason.displayName,
                requestedDeadline: request.requestedDeadline,
                partialPaymentAmount: request.partialPaymentAmount
            )
        )

        // Process partial payment if offered
        if let partialAmount = request.partialPaymentAmount, partialAmount > 0 {
            // TODO: Record partial payment evidence
            try await SwapEventService.shared.logEvent(
                swapId: request.swapId,
                type: .paymentProofSubmitted,
                payload: .withNote("Partial payment of \(partialAmount) with extension")
            )
        }

        // Clear current request
        currentRequest = nil
    }

    /// Deny an extension request
    func denyExtension(requestId: UUID, reason: String? = nil) async throws {
        guard let userId = currentUserId else {
            throw ExtensionError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Get the request
        let requests: [ExtensionRequest] = try await supabase
            .from("extension_requests")
            .select()
            .eq("id", value: requestId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let request = requests.first else {
            throw ExtensionError.requestNotFound
        }

        // Verify user can respond
        guard request.canRespond(userId: userId) else {
            throw ExtensionError.cannotRespond
        }

        // Update request status
        try await supabase
            .from("extension_requests")
            .update([
                "status": ExtensionStatus.denied.rawValue,
                "responded_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: requestId.uuidString)
            .execute()

        // Log event
        try await SwapEventService.shared.logEvent(
            swapId: request.swapId,
            type: .extensionDenied,
            payload: reason != nil ? .withNote(reason!) : nil
        )

        // Clear current request
        currentRequest = nil
    }

    // MARK: - Expire Extension

    /// Mark an extension request as expired
    private func expireRequest(requestId: UUID) async throws {
        try await supabase
            .from("extension_requests")
            .update(["status": ExtensionStatus.expired.rawValue])
            .eq("id", value: requestId.uuidString)
            .execute()
    }

    /// Check and expire any pending requests that have timed out
    func checkExpiredRequests(for swapId: UUID) async throws {
        let requests: [ExtensionRequest] = try await supabase
            .from("extension_requests")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .eq("status", value: ExtensionStatus.pending.rawValue)
            .execute()
            .value

        for request in requests where request.isExpired {
            try await expireRequest(requestId: request.id)

            // Log event
            try await SwapEventService.shared.logSystemEvent(
                swapId: swapId,
                type: .extensionDenied,
                payload: .withNote("Extension request expired - no response within 24 hours")
            )
        }
    }

    // MARK: - Helper Methods

    /// Get the current deadline for a user in a swap
    private func getCurrentDeadline(for swapId: UUID, userId: UUID) async throws -> Date {
        // Get the active deal
        guard let deal = try await DealService.shared.getCurrentDeal(for: swapId),
              deal.status == .accepted else {
            throw ExtensionError.noActiveDeal
        }

        // Get the swap to determine if user is A or B
        let swaps: [BillSwapTransaction] = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let swap = swaps.first else {
            throw ExtensionError.swapNotFound
        }

        // Return the appropriate deadline based on user role
        if swap.isUserA(userId: userId) {
            return deal.deadlineA
        } else {
            return deal.deadlineB
        }
    }

    /// Update the deadline in the deal
    private func updateDeadline(swapId: UUID, userId: UUID, newDeadline: Date) async throws {
        // Get the swap to determine which deadline to update
        let swaps: [BillSwapTransaction] = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let swap = swaps.first else {
            throw ExtensionError.swapNotFound
        }

        // Get the current deal
        guard let deal = try await DealService.shared.getCurrentDeal(for: swapId) else {
            throw ExtensionError.noActiveDeal
        }

        // Determine which deadline field to update
        let deadlineField = swap.isUserA(userId: userId) ? "deadline_a" : "deadline_b"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        try await supabase
            .from("swap_deals")
            .update([deadlineField: formatter.string(from: newDeadline)])
            .eq("id", value: deal.id.uuidString)
            .execute()
    }

    /// Check if user can request extension
    func canRequestExtension(for swapId: UUID) async throws -> (canRequest: Bool, reason: String?) {
        guard let userId = currentUserId else {
            return (false, "Not authenticated")
        }

        // Check if there's an active deal
        guard let deal = try await DealService.shared.getCurrentDeal(for: swapId),
              deal.status == .accepted else {
            return (false, "No active swap terms")
        }

        // Check extension count
        let count = try await getExtensionCount(for: swapId)
        if count >= Self.maxExtensionsPerSwap {
            return (false, "Maximum extensions reached (\(Self.maxExtensionsPerSwap))")
        }

        // Check for pending request
        if let pending = try await getPendingRequest(for: swapId) {
            if pending.isRequester(userId: userId) {
                return (false, "You have a pending extension request")
            } else {
                return (false, "Your partner has a pending extension request")
            }
        }

        // Check if deadline has passed (can't extend after deadline)
        let deadline = try await getCurrentDeadline(for: swapId, userId: userId)
        if Date() > deadline {
            return (false, "Your deadline has already passed")
        }

        return (true, nil)
    }

    /// Get suggested new deadlines based on presets
    func getSuggestedDeadlines(currentDeadline: Date) -> [(name: String, date: Date)] {
        ExtensionRequestInput.presetDurations.compactMap { preset in
            guard let newDate = Calendar.current.date(
                byAdding: .hour,
                value: preset.hours,
                to: currentDeadline
            ) else { return nil }

            // Don't suggest if it exceeds max extension
            let days = Calendar.current.dateComponents([.day], from: currentDeadline, to: newDate).day ?? 0
            guard days <= Self.maxExtensionDays else { return nil }

            return (name: preset.name, date: newDate)
        }
    }
}

// MARK: - Errors

enum ExtensionError: LocalizedError {
    case notAuthenticated
    case swapNotFound
    case noActiveDeal
    case requestNotFound
    case requestAlreadyPending
    case maxExtensionsReached
    case invalidDuration
    case cannotRespond
    case deadlinePassed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .swapNotFound:
            return "Swap not found"
        case .noActiveDeal:
            return "No active swap terms found"
        case .requestNotFound:
            return "Extension request not found"
        case .requestAlreadyPending:
            return "There's already a pending extension request"
        case .maxExtensionsReached:
            return "Maximum extensions reached for this swap"
        case .invalidDuration:
            return "Extension must be between 1 and 7 days"
        case .cannotRespond:
            return "You cannot respond to this request"
        case .deadlinePassed:
            return "Cannot request extension after deadline has passed"
        }
    }
}

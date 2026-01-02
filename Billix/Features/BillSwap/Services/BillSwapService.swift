//
//  BillSwapService.swift
//  Billix
//
//  Bill Swap Core Service
//

import Foundation
import Supabase

// MARK: - Private Codable Payloads

private struct CreateBillPayload: Codable {
    let ownerUserId: String
    let title: String
    let category: String
    let providerName: String?
    let amountCents: Int
    let dueDate: String
    let status: String
    let paymentUrl: String?
    let accountNumberLast4: String?
    let billImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case ownerUserId = "owner_user_id"
        case title
        case category
        case providerName = "provider_name"
        case amountCents = "amount_cents"
        case dueDate = "due_date"
        case status
        case paymentUrl = "payment_url"
        case accountNumberLast4 = "account_number_last4"
        case billImageUrl = "bill_image_url"
    }
}

private struct CreateSwapPayload: Codable {
    let swapType: String
    let status: String
    let initiatorUserId: String
    let billAId: String
    let billBId: String?
    let counterpartyUserId: String?
    let feeAmountCentsInitiator: Int
    let feeAmountCentsCounterparty: Int
    let acceptDeadline: String

    enum CodingKeys: String, CodingKey {
        case swapType = "swap_type"
        case status
        case initiatorUserId = "initiator_user_id"
        case billAId = "bill_a_id"
        case billBId = "bill_b_id"
        case counterpartyUserId = "counterparty_user_id"
        case feeAmountCentsInitiator = "fee_amount_cents_initiator"
        case feeAmountCentsCounterparty = "fee_amount_cents_counterparty"
        case acceptDeadline = "accept_deadline"
    }
}

private struct AcceptSwapPayload: Codable {
    let status: String
    let counterpartyUserId: String
    let billBId: String?
    let acceptedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case counterpartyUserId = "counterparty_user_id"
        case billBId = "bill_b_id"
        case acceptedAt = "accepted_at"
        case updatedAt = "updated_at"
    }
}

private struct MarkInitiatorFeePaidPayload: Codable {
    let feePaidInitiator: Bool
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case feePaidInitiator = "fee_paid_initiator"
        case updatedAt = "updated_at"
    }
}

private struct MarkCounterpartyFeePaidPayload: Codable {
    let feePaidCounterparty: Bool
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case feePaidCounterparty = "fee_paid_counterparty"
        case updatedAt = "updated_at"
    }
}

private struct LockSwapPayload: Codable {
    let status: String
    let lockedAt: String
    let proofDueDeadline: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case lockedAt = "locked_at"
        case proofDueDeadline = "proof_due_deadline"
        case updatedAt = "updated_at"
    }
}

private struct CompleteSwapPayload: Codable {
    let status: String
    let completedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case completedAt = "completed_at"
        case updatedAt = "updated_at"
    }
}

private struct UpdateStatusPayload: Codable {
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case updatedAt = "updated_at"
    }
}

@MainActor
class BillSwapService: ObservableObject {
    static let shared = BillSwapService()

    private let supabase = SupabaseService.shared.client
    private let trustService = TrustService.shared
    private let pointsService = PointsService.shared

    @Published var availableBills: [SwapBill] = []
    @Published var myBills: [SwapBill] = []
    @Published var activeSwaps: [BillSwap] = []
    @Published var swapHistory: [BillSwap] = []
    @Published var isLoading = false
    @Published var error: Error?

    private init() {}

    // MARK: - Bills

    /// Fetch available bills for swapping (excluding user's own)
    func fetchAvailableBills() async throws -> [SwapBill] {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let bills: [SwapBill] = try await supabase
            .from("swap_bills")
            .select()
            .eq("status", value: SwapBillStatus.active.rawValue)
            .neq("owner_user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        availableBills = bills
        return bills
    }

    /// Fetch user's own bills
    func fetchMyBills() async throws -> [SwapBill] {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        let bills: [SwapBill] = try await supabase
            .from("swap_bills")
            .select()
            .eq("owner_user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        myBills = bills
        return bills
    }

    /// Create a new bill
    func createBill(_ request: CreateBillRequest) async throws -> SwapBill {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        // Validate amount
        guard SwapBill.isValidAmount(request.amountCents) else {
            throw BillSwapError.operationFailed("Amount must be between $1 and $200")
        }

        // Check tier limit
        let profile = try await trustService.fetchCurrentUserProfile()
        if request.amountCents > profile.tier.maxBillCents {
            throw BillSwapError.tierCapExceeded(maxCents: profile.tier.maxBillCents)
        }

        let billPayload = CreateBillPayload(
            ownerUserId: userId.uuidString,
            title: request.title,
            category: request.category.rawValue,
            providerName: request.providerName,
            amountCents: request.amountCents,
            dueDate: ISO8601DateFormatter().string(from: request.dueDate),
            status: SwapBillStatus.active.rawValue,
            paymentUrl: request.paymentUrl,
            accountNumberLast4: request.accountNumberLast4,
            billImageUrl: request.billImageUrl
        )

        let response: [SwapBill] = try await supabase
            .from("swap_bills")
            .insert(billPayload)
            .select()
            .execute()
            .value

        guard let bill = response.first else {
            throw BillSwapError.operationFailed("Failed to create bill")
        }

        // Refresh my bills
        myBills.insert(bill, at: 0)

        return bill
    }

    /// Update bill status
    func updateBillStatus(_ billId: UUID, status: SwapBillStatus) async throws {
        let payload = UpdateStatusPayload(
            status: status.rawValue,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("swap_bills")
            .update(payload)
            .eq("id", value: billId.uuidString)
            .execute()
    }

    /// Delete a bill (only drafts)
    func deleteBill(_ billId: UUID) async throws {
        try await supabase
            .from("swap_bills")
            .delete()
            .eq("id", value: billId.uuidString)
            .eq("status", value: SwapBillStatus.draft.rawValue)
            .execute()

        myBills.removeAll { $0.id == billId }
    }

    // MARK: - Image Upload

    /// Upload a bill image to Supabase Storage
    func uploadBillImage(_ imageData: Data) async throws -> String {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        let fileName = "\(userId.uuidString)/\(UUID().uuidString).jpg"

        try await supabase.storage
            .from("bill-images")
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        let publicURL = try supabase.storage
            .from("bill-images")
            .getPublicURL(path: fileName)

        return publicURL.absoluteString
    }

    // MARK: - Swaps

    /// Fetch active swaps for current user
    func fetchActiveSwaps() async throws -> [BillSwap] {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let activeStatuses = BillSwapStatus.allCases
            .filter { $0.isActive }
            .map { $0.rawValue }

        let swaps: [BillSwap] = try await supabase
            .from("bill_swaps")
            .select()
            .or("initiator_user_id.eq.\(userId.uuidString),counterparty_user_id.eq.\(userId.uuidString)")
            .in("status", values: activeStatuses)
            .order("created_at", ascending: false)
            .execute()
            .value

        activeSwaps = swaps
        return swaps
    }

    /// Fetch swap history (completed, failed, cancelled)
    func fetchSwapHistory() async throws -> [BillSwap] {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        let terminalStatuses = BillSwapStatus.allCases
            .filter { $0.isTerminal }
            .map { $0.rawValue }

        let swaps: [BillSwap] = try await supabase
            .from("bill_swaps")
            .select()
            .or("initiator_user_id.eq.\(userId.uuidString),counterparty_user_id.eq.\(userId.uuidString)")
            .in("status", values: terminalStatuses)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value

        swapHistory = swaps
        return swaps
    }

    /// Fetch a single swap by ID
    func fetchSwap(_ swapId: UUID) async throws -> BillSwap {
        let swap: BillSwap = try await supabase
            .from("bill_swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .single()
            .execute()
            .value

        return swap
    }

    /// Create a new swap offer
    func createSwap(_ request: CreateSwapRequest) async throws -> BillSwap {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        // Validate user can create swap
        let profile = try await trustService.fetchCurrentUserProfile()
        if profile.activeSwapsCount >= profile.tier.maxActiveSwaps {
            throw BillSwapError.maxActiveSwapsReached(max: profile.tier.maxActiveSwaps)
        }

        // Get bill A details for amount validation
        let billA: SwapBill = try await supabase
            .from("swap_bills")
            .select()
            .eq("id", value: request.billAId.uuidString)
            .single()
            .execute()
            .value

        // Validate amount against tier
        let tierCheck = trustService.canCreateSwap(
            profile: profile,
            amountCents: billA.amountCents,
            swapType: request.swapType
        )

        if case .failure(let error) = tierCheck {
            throw error
        }

        // Set fees based on swap type
        let initiatorFee = request.swapType.initiatorFeeCents
        let counterpartyFee = request.swapType.counterpartyFeeCents

        // Calculate accept deadline (24 hours)
        let acceptDeadline = Calendar.current.date(byAdding: .hour, value: 24, to: Date())!

        let swapPayload = CreateSwapPayload(
            swapType: request.swapType.rawValue,
            status: BillSwapStatus.offered.rawValue,
            initiatorUserId: userId.uuidString,
            billAId: request.billAId.uuidString,
            billBId: request.billBId?.uuidString,
            counterpartyUserId: request.counterpartyUserId?.uuidString,
            feeAmountCentsInitiator: initiatorFee,
            feeAmountCentsCounterparty: counterpartyFee,
            acceptDeadline: ISO8601DateFormatter().string(from: acceptDeadline)
        )

        let response: [BillSwap] = try await supabase
            .from("bill_swaps")
            .insert(swapPayload)
            .select()
            .execute()
            .value

        guard let swap = response.first else {
            throw BillSwapError.operationFailed("Failed to create swap")
        }

        // Lock the initiator's bill
        try await updateBillStatus(request.billAId, status: .lockedInSwap)

        // Increment active swaps
        try await trustService.incrementActiveSwaps(userId: userId)

        activeSwaps.insert(swap, at: 0)
        return swap
    }

    /// Accept a swap offer
    func acceptSwap(_ swapId: UUID, billBId: UUID? = nil) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        // Lock counterparty's bill if provided
        if let billBId = billBId {
            try await updateBillStatus(billBId, status: .lockedInSwap)
        }

        let acceptPayload = AcceptSwapPayload(
            status: BillSwapStatus.acceptedPendingFee.rawValue,
            counterpartyUserId: userId.uuidString,
            billBId: billBId?.uuidString,
            acceptedAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("bill_swaps")
            .update(acceptPayload)
            .eq("id", value: swapId.uuidString)
            .execute()

        // Increment active swaps for counterparty
        try await trustService.incrementActiveSwaps(userId: userId)
    }

    /// Cancel a swap
    func cancelSwap(_ swapId: UUID) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        // Fetch swap details
        let swap = try await fetchSwap(swapId)

        guard swap.initiatorUserId == userId || swap.counterpartyUserId == userId else {
            throw BillSwapError.operationFailed("Not authorized to cancel this swap")
        }

        guard swap.status.isActive else {
            throw BillSwapError.invalidTransition(from: swap.status, to: .cancelled)
        }

        // Update status
        let cancelPayload = UpdateStatusPayload(
            status: BillSwapStatus.cancelled.rawValue,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("bill_swaps")
            .update(cancelPayload)
            .eq("id", value: swapId.uuidString)
            .execute()

        // Unlock bills
        try await updateBillStatus(swap.billAId, status: .active)
        if let billBId = swap.billBId {
            try await updateBillStatus(billBId, status: .active)
        }

        // Decrement active swaps
        try await trustService.decrementActiveSwaps(userId: swap.initiatorUserId)
        if let counterpartyId = swap.counterpartyUserId {
            try await trustService.decrementActiveSwaps(userId: counterpartyId)
        }

        // Update local state
        activeSwaps.removeAll { $0.id == swapId }
    }

    /// Mark fee as paid
    func markFeePaid(_ swapId: UUID, forInitiator: Bool) async throws {
        let now = ISO8601DateFormatter().string(from: Date())

        if forInitiator {
            let payload = MarkInitiatorFeePaidPayload(feePaidInitiator: true, updatedAt: now)
            try await supabase
                .from("bill_swaps")
                .update(payload)
                .eq("id", value: swapId.uuidString)
                .execute()
        } else {
            let payload = MarkCounterpartyFeePaidPayload(feePaidCounterparty: true, updatedAt: now)
            try await supabase
                .from("bill_swaps")
                .update(payload)
                .eq("id", value: swapId.uuidString)
                .execute()
        }

        // Check if both fees paid, then lock
        let swap = try await fetchSwap(swapId)
        if swap.bothFeesPaid {
            try await lockSwap(swapId)
        }
    }

    /// Lock swap and move to awaiting proof
    private func lockSwap(_ swapId: UUID) async throws {
        // Set proof deadline (72 hours from now)
        let now = Date()
        let proofDeadline = Calendar.current.date(byAdding: .hour, value: 72, to: now)!
        let formatter = ISO8601DateFormatter()

        let payload = LockSwapPayload(
            status: BillSwapStatus.awaitingProof.rawValue,
            lockedAt: formatter.string(from: now),
            proofDueDeadline: formatter.string(from: proofDeadline),
            updatedAt: formatter.string(from: now)
        )

        try await supabase
            .from("bill_swaps")
            .update(payload)
            .eq("id", value: swapId.uuidString)
            .execute()
    }

    /// Complete a swap (called when both proofs are accepted)
    func completeSwap(_ swapId: UUID) async throws {
        let swap = try await fetchSwap(swapId)

        guard swap.status == .awaitingProof else {
            throw BillSwapError.invalidTransition(from: swap.status, to: .completed)
        }

        // Update swap status
        let now = ISO8601DateFormatter().string(from: Date())
        let completePayload = CompleteSwapPayload(
            status: BillSwapStatus.completed.rawValue,
            completedAt: now,
            updatedAt: now
        )
        try await supabase
            .from("bill_swaps")
            .update(completePayload)
            .eq("id", value: swapId.uuidString)
            .execute()

        // Mark bills as paid
        try await updateBillStatus(swap.billAId, status: .paidConfirmed)
        if let billBId = swap.billBId {
            try await updateBillStatus(billBId, status: .paidConfirmed)
        }

        // Get bill amount for trust calculation
        let billA: SwapBill = try await supabase
            .from("swap_bills")
            .select()
            .eq("id", value: swap.billAId.uuidString)
            .single()
            .execute()
            .value

        let isOneSided = swap.swapType == .oneSidedAssist

        // Update trust for both users
        try await trustService.recordSuccessfulSwap(
            userId: swap.initiatorUserId,
            swapAmountCents: billA.amountCents,
            isOneSided: isOneSided
        )

        if let counterpartyId = swap.counterpartyUserId {
            try await trustService.recordSuccessfulSwap(
                userId: counterpartyId,
                swapAmountCents: billA.amountCents,
                isOneSided: isOneSided
            )

            // Award points
            let isFirstInitiator = try await pointsService.isFirstSwapOfDay(userId: swap.initiatorUserId)
            let isFirstCounterparty = try await pointsService.isFirstSwapOfDay(userId: counterpartyId)

            try await pointsService.awardSwapCompletionPoints(
                userId: swap.initiatorUserId,
                swapId: swapId,
                isFirstSwapOfDay: isFirstInitiator
            )

            try await pointsService.awardSwapCompletionPoints(
                userId: counterpartyId,
                swapId: swapId,
                isFirstSwapOfDay: isFirstCounterparty
            )
        }

        // Decrement active swaps
        try await trustService.decrementActiveSwaps(userId: swap.initiatorUserId)
        if let counterpartyId = swap.counterpartyUserId {
            try await trustService.decrementActiveSwaps(userId: counterpartyId)
        }

        // Update local state
        activeSwaps.removeAll { $0.id == swapId }
    }
}

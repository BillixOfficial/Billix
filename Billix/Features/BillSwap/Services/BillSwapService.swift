//
//  BillSwapService.swift
//  Billix
//
//  Bill Swap Core Service with Import, Activity Feed, and Proof Handling
//

import Foundation
import Supabase

// MARK: - Private Codable Payloads

private struct CreateBillPayload: Codable {
    // Note: owner_user_id is NOT included - database uses auth.uid() default
    // This ensures RLS policy always passes
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
    let spreadFeeCents: Int
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
        case spreadFeeCents = "spread_fee_cents"
        case acceptDeadline = "accept_deadline"
    }
}

private struct CreateProofPayload: Codable {
    let swapId: String
    let submittedByUserId: String
    let proofType: String
    let imageUrl: String
    let notes: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case submittedByUserId = "submitted_by_user_id"
        case proofType = "proof_type"
        case imageUrl = "image_url"
        case notes
        case status
    }
}

private struct ActivityFeedPayload: Codable {
    let swapId: String
    let category1: String
    let category2: String
    let amountRange: String
    let tierBadge1: String
    let tierBadge2: String

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case category1 = "category_1"
        case category2 = "category_2"
        case amountRange = "amount_range"
        case tierBadge1 = "tier_badge_1"
        case tierBadge2 = "tier_badge_2"
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
    @Published var activityFeed: [SwapActivityFeedItem] = []
    @Published var activityStats: ActivityFeedStats?
    @Published var isLoading = false
    @Published var error: Error?

    private init() {}

    // MARK: - Import Bill from Upload

    /// Import a bill from the Upload feature's BillAnalysis
    func importBillFromAnalysis(_ analysis: BillAnalysis) async throws -> SwapBill {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        // Validate amount is within swap range ($20-$200)
        let amountCents = Int(analysis.amount * 100)
        guard amountCents >= 2000 && amountCents <= 20000 else {
            throw BillSwapError.operationFailed("Bill amount must be between $20 and $200 for swapping")
        }

        // Check tier limit
        let profile = try await trustService.fetchCurrentUserProfile()
        if amountCents > profile.tier.maxBillCents {
            throw BillSwapError.tierCapExceeded(maxCents: profile.tier.maxBillCents)
        }

        // Map analysis category to swap category
        let swapCategory = mapAnalysisCategoryToSwapCategory(analysis.category)

        // Parse due date from string or default to 2 weeks from now
        let dueDate: Date
        if let dueDateStr = analysis.dueDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            dueDate = formatter.date(from: dueDateStr) ?? Date().addingTimeInterval(86400 * 14)
        } else {
            dueDate = Date().addingTimeInterval(86400 * 14)
        }

        // Create bill request
        let request = CreateBillRequest(
            title: "\(analysis.provider) Bill",
            category: swapCategory,
            providerName: analysis.provider,
            amountCents: amountCents,
            dueDate: dueDate,
            paymentUrl: nil,
            accountNumberLast4: extractLast4FromAccountNumber(analysis.accountNumber),
            billImageUrl: nil
        )

        return try await createBill(request)
    }

    /// Map BillAnalysis category to SwapBillCategory
    private func mapAnalysisCategoryToSwapCategory(_ category: String) -> SwapBillCategory {
        switch category.lowercased() {
        case "electric", "electricity", "power":
            return .electric
        case "gas", "natural gas":
            return .naturalGas
        case "water", "sewer":
            return .water
        case "internet", "broadband":
            return .internet
        case "phone", "mobile", "cell":
            return .phonePlan
        case "cable", "tv":
            return .cable
        case "streaming", "netflix", "hulu", "disney", "hbo":
            return .netflix
        default:
            return .electric
        }
    }

    /// Extract last 4 digits from account number
    private func extractLast4FromAccountNumber(_ accountNumber: String?) -> String? {
        guard let account = accountNumber, account.count >= 4 else { return nil }
        return String(account.suffix(4))
    }

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

        // Format date as YYYY-MM-DD for PostgreSQL date column
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Note: owner_user_id is set by database default (auth.uid())
        // This guarantees RLS policy passes
        let billPayload = CreateBillPayload(
            title: request.title,
            category: request.category.rawValue,
            providerName: request.providerName,
            amountCents: request.amountCents,
            dueDate: dateFormatter.string(from: request.dueDate),
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

        // Use lowercased UUIDs to match PostgreSQL's auth.uid()::text format
        // PostgreSQL returns lowercase UUIDs, but Swift's uuidString is uppercase
        let fileName = "\(userId.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"

        try await supabase.storage
            .from("bills")
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        let publicURL = try supabase.storage
            .from("bills")
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

        // Get bill B amount if available (for spread fee calculation)
        var billBAmountCents: Int? = nil
        if let billBId = request.billBId {
            let billB: SwapBill = try await supabase
                .from("swap_bills")
                .select()
                .eq("id", value: billBId.uuidString)
                .single()
                .execute()
                .value
            billBAmountCents = billB.amountCents
        }

        // Calculate fees with spread fee for unequal bills
        let fees = SwapFeeCalculator.calculateTotalFees(
            billACents: billA.amountCents,
            billBCents: billBAmountCents,
            swapType: request.swapType
        )

        // Calculate accept deadline (24 hours)
        let acceptDeadline = Calendar.current.date(byAdding: .hour, value: 24, to: Date())!

        let swapPayload = CreateSwapPayload(
            swapType: request.swapType.rawValue,
            status: BillSwapStatus.offered.rawValue,
            initiatorUserId: userId.uuidString,
            billAId: request.billAId.uuidString,
            billBId: request.billBId?.uuidString,
            counterpartyUserId: request.counterpartyUserId?.uuidString,
            feeAmountCentsInitiator: fees.totalInitiator,
            feeAmountCentsCounterparty: fees.totalCounterparty,
            spreadFeeCents: fees.spreadFee,
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

        // Add to activity feed
        try await logSwapToActivityFeed(swap)
    }

    // MARK: - Proof Handling

    /// Submit payment proof for a swap
    func submitPaymentProof(
        swapId: UUID,
        imageData: Data,
        proofType: ProofType = .screenshot,
        notes: String? = nil
    ) async throws -> SwapProof {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        // Upload proof image
        let imageUrl = try await uploadProofImage(imageData, swapId: swapId)

        let proofPayload = CreateProofPayload(
            swapId: swapId.uuidString,
            submittedByUserId: userId.uuidString,
            proofType: proofType.rawValue,
            imageUrl: imageUrl,
            notes: notes,
            status: ProofStatus.pending.rawValue
        )

        let response: [SwapProof] = try await supabase
            .from("swap_proofs")
            .insert(proofPayload)
            .select()
            .execute()
            .value

        guard let proof = response.first else {
            throw BillSwapError.operationFailed("Failed to submit proof")
        }

        return proof
    }

    /// Upload proof image to storage
    private func uploadProofImage(_ imageData: Data, swapId: UUID) async throws -> String {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        let fileName = "proofs/\(swapId.uuidString.lowercased())/\(userId.uuidString.lowercased())_\(UUID().uuidString.lowercased()).jpg"

        try await supabase.storage
            .from("bills")
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        let publicURL = try supabase.storage
            .from("bills")
            .getPublicURL(path: fileName)

        return publicURL.absoluteString
    }

    /// Fetch proofs for a swap
    func fetchProofs(for swapId: UUID) async throws -> [SwapProof] {
        let proofs: [SwapProof] = try await supabase
            .from("swap_proofs")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return proofs
    }

    /// Approve a proof (marks it as accepted)
    func approveProof(_ proofId: UUID) async throws {
        try await supabase
            .from("swap_proofs")
            .update(["status": ProofStatus.accepted.rawValue, "updated_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: proofId.uuidString)
            .execute()
    }

    /// Reject a proof
    func rejectProof(_ proofId: UUID, reason: String) async throws {
        try await supabase
            .from("swap_proofs")
            .update([
                "status": ProofStatus.rejected.rawValue,
                "rejection_reason": reason,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: proofId.uuidString)
            .execute()
    }

    // MARK: - Activity Feed

    /// Fetch recent activity feed for social proof
    func fetchActivityFeed(limit: Int = 20) async throws -> [SwapActivityFeedItem] {
        let feed: [SwapActivityFeedItem] = try await supabase
            .from("swap_activity_feed")
            .select()
            .order("timestamp", ascending: false)
            .limit(limit)
            .execute()
            .value

        activityFeed = feed
        return feed
    }

    /// Fetch activity feed statistics
    func fetchActivityStats() async throws -> ActivityFeedStats {
        // Get today's swaps
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: Date())!

        let todayFormatter = ISO8601DateFormatter()

        // Count swaps today
        let todayCountResponse: [CountResponse] = try await supabase
            .from("swap_activity_feed")
            .select("id", head: false, count: .exact)
            .gte("timestamp", value: todayFormatter.string(from: startOfToday))
            .execute()
            .value

        // Count swaps this week
        let weekCountResponse: [CountResponse] = try await supabase
            .from("swap_activity_feed")
            .select("id", head: false, count: .exact)
            .gte("timestamp", value: todayFormatter.string(from: startOfWeek))
            .execute()
            .value

        let stats = ActivityFeedStats(
            totalSwapsToday: todayCountResponse.count,
            totalSwapsThisWeek: weekCountResponse.count,
            averageMatchTime: nil, // Would need additional tracking
            mostActiveCategory: nil
        )

        activityStats = stats
        return stats
    }

    /// Log completed swap to activity feed (called internally on completion)
    private func logSwapToActivityFeed(_ swap: BillSwap) async throws {
        guard let billA = swap.billA,
              let billB = swap.billB,
              let initiatorProfile = swap.initiatorProfile,
              let counterpartyProfile = swap.counterpartyProfile else {
            // Fetch bills if not attached
            return
        }

        let amountRange = SwapAmountRange.fromCents(max(billA.amountCents, billB.amountCents))

        let feedPayload = ActivityFeedPayload(
            swapId: swap.id.uuidString,
            category1: billA.category.rawValue,
            category2: billB.category.rawValue,
            amountRange: amountRange.rawValue,
            tierBadge1: initiatorProfile.tier.rawValue,
            tierBadge2: counterpartyProfile.tier.rawValue
        )

        try await supabase
            .from("swap_activity_feed")
            .insert(feedPayload)
            .execute()
    }

    // MARK: - Create Swap from Match

    /// Create a swap directly from a match
    func createSwapFromMatch(_ match: SwapMatch) async throws -> BillSwap {
        let request = CreateSwapRequest(
            billAId: match.yourBill.id,
            billBId: match.theirBill.id,
            counterpartyUserId: match.partnerProfile.userId,
            swapType: .twoSided
        )

        return try await createSwap(request)
    }
}

// MARK: - Helper Types

private struct CountResponse: Codable {
    let id: UUID
}

// Note: ProofType, ProofStatus, and SwapProof are defined in SwapProof.swift

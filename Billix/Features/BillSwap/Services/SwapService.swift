//
//  SwapService.swift
//  Billix
//
//  Service for managing swap transactions and matching logic
//

import Foundation
import Supabase

/// Service for swap matching, creation, and management
@MainActor
class SwapService: ObservableObject {

    // MARK: - Singleton
    static let shared = SwapService()

    // MARK: - Published Properties
    @Published var potentialMatches: [SwapBill] = []
    @Published var activeSwaps: [BillSwapTransaction] = []
    @Published var completedSwaps: [BillSwapTransaction] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentUserId: UUID? {
        AuthService.shared.currentUser?.id
    }

    private init() {}

    // MARK: - Matching Logic

    /// Find potential matches for a bill (within 10% of amount)
    func findMatches(for bill: SwapBill) async throws -> [SwapBill] {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        let lowerBound = NSDecimalNumber(decimal: bill.amount * Decimal(0.9)).doubleValue
        let upperBound = NSDecimalNumber(decimal: bill.amount * Decimal(1.1)).doubleValue

        let matches: [SwapBill] = try await supabase
            .from("swap_bills")
            .select()
            .neq("user_id", value: userId.uuidString)
            .eq("status", value: "unmatched")
            .gte("amount", value: lowerBound)
            .lte("amount", value: upperBound)
            .execute()
            .value

        self.potentialMatches = matches
        return matches
    }

    /// Find all potential matches for user's unmatched bills
    func findAllMatches() async throws {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Get user's unmatched bills
        let myBills: [SwapBill] = try await supabase
            .from("swap_bills")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "unmatched")
            .execute()
            .value

        guard !myBills.isEmpty else {
            potentialMatches = []
            return
        }

        // Find matches for each bill
        var allMatches: Set<UUID> = []
        var matchedBills: [SwapBill] = []

        for bill in myBills {
            let lowerBound = NSDecimalNumber(decimal: bill.amount * Decimal(0.9)).doubleValue
            let upperBound = NSDecimalNumber(decimal: bill.amount * Decimal(1.1)).doubleValue

            let matches: [SwapBill] = try await supabase
                .from("swap_bills")
                .select()
                .neq("user_id", value: userId.uuidString)
                .eq("status", value: "unmatched")
                .gte("amount", value: lowerBound)
                .lte("amount", value: upperBound)
                .execute()
                .value

            for match in matches where !allMatches.contains(match.id) {
                allMatches.insert(match.id)
                matchedBills.append(match)
            }
        }

        self.potentialMatches = matchedBills
    }

    // MARK: - Swap CRUD Operations

    /// Fetch all swaps for current user
    func fetchMySwaps() async throws {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let swaps: [BillSwapTransaction] = try await supabase
            .from("swaps")
            .select()
            .or("user_a_id.eq.\(userId.uuidString),user_b_id.eq.\(userId.uuidString)")
            .order("created_at", ascending: false)
            .execute()
            .value

        self.activeSwaps = swaps.filter { $0.status == .pending || $0.status == .active }
        self.completedSwaps = swaps.filter { $0.status == .completed }
    }

    /// Create a new swap between two bills
    func createSwap(myBillId: UUID, partnerBillId: UUID, partnerUserId: UUID) async throws -> BillSwapTransaction {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        let newSwap = SwapInsert(
            billAId: myBillId,
            billBId: partnerBillId,
            userAId: userId,
            userBId: partnerUserId
        )

        let swap: BillSwapTransaction = try await supabase
            .from("swaps")
            .insert(newSwap)
            .select()
            .single()
            .execute()
            .value

        // Update bill statuses
        try await SwapBillService.shared.updateBillStatus(billId: myBillId, status: .matched)

        // Get the bill amount for the notification
        let myBill = try await SwapBillService.shared.getBill(id: myBillId)
        let billAmount = NSDecimalNumber(decimal: myBill.amount).doubleValue
        await NotificationService.shared.notifyMatchFound(swapId: swap.id, billAmount: billAmount)

        // Refresh swaps
        try await fetchMySwaps()

        return swap
    }

    /// Accept a swap (after paying handshake fee)
    func acceptSwap(swapId: UUID) async throws {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        // Get current swap
        let swap: BillSwapTransaction = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .single()
            .execute()
            .value

        // Determine which field to update
        let isUserA = swap.isUserA(userId: userId)
        let updateField = isUserA ? "user_a_paid_fee" : "user_b_paid_fee"

        // Update the fee payment status
        try await supabase
            .from("swaps")
            .update([updateField: true])
            .eq("id", value: swapId.uuidString)
            .execute()

        // Check if both users have paid - if so, activate the swap
        let updatedSwap: BillSwapTransaction = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .single()
            .execute()
            .value

        if updatedSwap.bothPaidFees && updatedSwap.status == .pending {
            try await supabase
                .from("swaps")
                .update(["status": BillSwapStatus.active.rawValue])
                .eq("id", value: swapId.uuidString)
                .execute()

            // Both committed - notify both users that chat is unlocked
            await NotificationService.shared.notifyBothCommitted(swap: updatedSwap)
        } else {
            // Only one committed - notify partner
            await NotificationService.shared.notifyPartnerCommitted(swap: updatedSwap, currentUserId: userId)
        }

        // Refresh swaps
        try await fetchMySwaps()
    }

    /// Mark that user has paid their partner's bill
    func markPartnerPaid(swapId: UUID, proofUrl: String) async throws {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        // Get current swap
        let swap: BillSwapTransaction = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .single()
            .execute()
            .value

        // Determine which fields to update based on which user
        let isUserA = swap.isUserA(userId: userId)

        // Update payment status and proof - need separate updates for different types
        if isUserA {
            try await supabase
                .from("swaps")
                .update(["user_a_paid_partner": true])
                .eq("id", value: swapId.uuidString)
                .execute()

            try await supabase
                .from("swaps")
                .update(["proof_a_url": proofUrl])
                .eq("id", value: swapId.uuidString)
                .execute()
        } else {
            try await supabase
                .from("swaps")
                .update(["user_b_paid_partner": true])
                .eq("id", value: swapId.uuidString)
                .execute()

            try await supabase
                .from("swaps")
                .update(["proof_b_url": proofUrl])
                .eq("id", value: swapId.uuidString)
                .execute()
        }

        // Check if swap is complete
        let updatedSwap: BillSwapTransaction = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .single()
            .execute()
            .value

        // Get the partner's bill amount for the notification
        let partnerBillId = updatedSwap.partnerBillId(for: userId)
        let partnerBill = try await SwapBillService.shared.getBill(id: partnerBillId)
        let amount = NSDecimalNumber(decimal: partnerBill.amount).doubleValue
        await NotificationService.shared.notifyBillPaid(swap: updatedSwap, paidByUserId: userId, amount: amount)

        if updatedSwap.canComplete {
            try await completeSwap(swapId: swapId)
        }

        // Refresh swaps
        try await fetchMySwaps()
    }

    /// Complete a swap
    func completeSwap(swapId: UUID) async throws {
        try await supabase
            .from("swaps")
            .update([
                "status": BillSwapStatus.completed.rawValue,
                "completed_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: swapId.uuidString)
            .execute()

        // Get the swap to update bill statuses
        let swap: BillSwapTransaction = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .single()
            .execute()
            .value

        // Update both bills to paid status
        try await SwapBillService.shared.updateBillStatus(billId: swap.billAId, status: .paid)
        try await SwapBillService.shared.updateBillStatus(billId: swap.billBId, status: .paid)

        // Notify both users that swap is complete
        await NotificationService.shared.notifySwapComplete(swap: swap)

        // Refresh swaps
        try await fetchMySwaps()
    }

    /// Raise a dispute on a swap
    func raiseDispute(swapId: UUID, reason: String) async throws {
        try await supabase
            .from("swaps")
            .update(["status": BillSwapStatus.dispute.rawValue])
            .eq("id", value: swapId.uuidString)
            .execute()

        // Refresh swaps
        try await fetchMySwaps()
    }

    // MARK: - Helper Methods

    /// Get a specific swap by ID
    func getSwap(id: UUID) async throws -> BillSwapTransaction {
        let swap: BillSwapTransaction = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return swap
    }

    /// Get partner's bill for a swap
    func getPartnerBill(for swap: BillSwapTransaction) async throws -> SwapBill {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        let partnerBillId = swap.partnerBillId(for: userId)

        let bill: SwapBill = try await supabase
            .from("swap_bills")
            .select()
            .eq("id", value: partnerBillId.uuidString)
            .single()
            .execute()
            .value

        return bill
    }

    // MARK: - Free Swap Usage Tracking

    /// Maximum free swaps per month for non-Prime users
    private let maxFreeSwapsPerMonth = 2

    /// Get remaining free swaps for current user
    func getRemainingFreeSwaps() async throws -> Int {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        // First, reset monthly swaps if needed
        try await resetMonthlySwapsIfNeeded()

        // Fetch current count from profiles
        struct ProfileSwapCount: Decodable {
            let monthlySwapCount: Int?

            enum CodingKeys: String, CodingKey {
                case monthlySwapCount = "monthly_swap_count"
            }
        }

        let profiles: [ProfileSwapCount] = try await supabase
            .from("profiles")
            .select("monthly_swap_count")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        let usedSwaps = profiles.first?.monthlySwapCount ?? 0
        return max(0, maxFreeSwapsPerMonth - usedSwaps)
    }

    /// Use one free swap (increments the monthly count)
    func useFreeSwap() async throws {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        // Get current count
        struct ProfileSwapCount: Decodable {
            let monthlySwapCount: Int?

            enum CodingKeys: String, CodingKey {
                case monthlySwapCount = "monthly_swap_count"
            }
        }

        let profiles: [ProfileSwapCount] = try await supabase
            .from("profiles")
            .select("monthly_swap_count")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        let currentCount = profiles.first?.monthlySwapCount ?? 0

        // Check if user has remaining free swaps
        guard currentCount < maxFreeSwapsPerMonth else {
            throw SwapError.noFreeSwapsRemaining
        }

        // Increment the count
        try await supabase
            .from("profiles")
            .update(["monthly_swap_count": currentCount + 1])
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    /// Reset monthly swap count if we're in a new month
    private func resetMonthlySwapsIfNeeded() async throws {
        guard let userId = currentUserId else { return }

        struct ProfileResetDate: Decodable {
            let swapCountResetDate: Date?

            enum CodingKeys: String, CodingKey {
                case swapCountResetDate = "swap_count_reset_date"
            }
        }

        let profiles: [ProfileResetDate] = try await supabase
            .from("profiles")
            .select("swap_count_reset_date")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        let lastReset = profiles.first?.swapCountResetDate

        // Check if we need to reset (first of the month or never reset)
        let calendar = Calendar.current
        let now = Date()

        var needsReset = false

        if let lastReset = lastReset {
            // Reset if we're in a different month
            let lastMonth = calendar.component(.month, from: lastReset)
            let lastYear = calendar.component(.year, from: lastReset)
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)

            needsReset = (lastMonth != currentMonth || lastYear != currentYear)
        } else {
            // Never reset before
            needsReset = true
        }

        if needsReset {
            // Reset count to 0
            try await supabase
                .from("profiles")
                .update(["monthly_swap_count": 0])
                .eq("user_id", value: userId.uuidString)
                .execute()

            // Update reset date
            try await supabase
                .from("profiles")
                .update(["swap_count_reset_date": ISO8601DateFormatter().string(from: now)])
                .eq("user_id", value: userId.uuidString)
                .execute()
        }
    }
}

// MARK: - Supporting Types

/// Insert model for creating new swaps
private struct SwapInsert: Encodable {
    let billAId: UUID
    let billBId: UUID
    let userAId: UUID
    let userBId: UUID

    enum CodingKeys: String, CodingKey {
        case billAId = "bill_a_id"
        case billBId = "bill_b_id"
        case userAId = "user_a_id"
        case userBId = "user_b_id"
    }
}

/// Errors for SwapService
enum SwapError: LocalizedError {
    case notAuthenticated
    case swapNotFound
    case alreadyMatched
    case invalidSwapState
    case noFreeSwapsRemaining

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .swapNotFound:
            return "Swap not found"
        case .alreadyMatched:
            return "This bill has already been matched"
        case .invalidSwapState:
            return "Invalid swap state for this action"
        case .noFreeSwapsRemaining:
            return "You've used all your free swaps this month. Upgrade to Prime or pay per swap."
        }
    }
}

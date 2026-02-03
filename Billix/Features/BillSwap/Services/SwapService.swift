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

    // MARK: - Trust Tier Management

    /// User trust data for tier-based limits
    struct SwapTrustInfo: Decodable {
        let userId: UUID
        let tier: Int
        let totalSwaps: Int
        let successfulSwaps: Int
        let disputedSwaps: Int
        let missedDeadlines: Int
        let trustPoints: Int
        let eligibilityLockedUntil: Date?

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case tier
            case totalSwaps = "total_swaps"
            case successfulSwaps = "successful_swaps"
            case disputedSwaps = "disputed_swaps"
            case missedDeadlines = "missed_deadlines"
            case trustPoints = "trust_points"
            case eligibilityLockedUntil = "eligibility_locked_until"
        }
    }

    /// Get current user's trust tier info
    func getUserTrustInfo() async throws -> SwapTrustInfo {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        // Try to get existing trust record
        let records: [SwapTrustInfo] = try await supabase
            .from("swap_trust")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        if let info = records.first {
            return info
        }

        // Create default tier 1 record if none exists
        let defaultTrust = SwapTrustInsert(userId: userId)
        try await supabase
            .from("swap_trust")
            .insert(defaultTrust)
            .execute()

        // Return default tier 1 info
        return SwapTrustInfo(
            userId: userId,
            tier: 1,
            totalSwaps: 0,
            successfulSwaps: 0,
            disputedSwaps: 0,
            missedDeadlines: 0,
            trustPoints: 0,
            eligibilityLockedUntil: nil
        )
    }

    /// Check if user can swap (not locked)
    func canUserSwap() async throws -> Bool {
        let trustInfo = try await getUserTrustInfo()

        if let lockedUntil = trustInfo.eligibilityLockedUntil {
            return lockedUntil < Date()
        }

        return true
    }

    /// Validate bill amount against user's tier limit
    func validateBillAmountForTier(amount: Decimal) async throws -> Bool {
        let trustInfo = try await getUserTrustInfo()
        let maxAmount = SwapTheme.Tiers.maxAmount(for: trustInfo.tier)
        return amount <= maxAmount
    }

    /// Get user's tier limit
    func getUserTierLimit() async throws -> Decimal {
        let trustInfo = try await getUserTrustInfo()
        return SwapTheme.Tiers.maxAmount(for: trustInfo.tier)
    }

    // MARK: - Matching Logic

    /// Progressive tolerance levels for matching
    private let toleranceLevels: [Double] = [0.05, 0.10, 0.15]  // 5%, 10%, 15%

    /// Timeline compatibility window (days)
    private let timelineWindowDays = 14

    /// Find potential matches for a bill using progressive tolerance
    /// Starts tight (±5%), expands to ±10%, then ±15% if no matches found
    func findMatches(for bill: SwapBill) async throws -> [SwapBill] {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        // Try each tolerance level until we find matches
        for tolerance in toleranceLevels {
            let matches = try await findMatchesWithTolerance(
                for: bill,
                userId: userId,
                tolerance: tolerance
            )

            if !matches.isEmpty {
                self.potentialMatches = matches
                return matches
            }
        }

        // No matches at any tolerance level
        self.potentialMatches = []
        return []
    }

    /// Find matches with a specific tolerance level
    private func findMatchesWithTolerance(
        for bill: SwapBill,
        userId: UUID,
        tolerance: Double
    ) async throws -> [SwapBill] {
        let amount = NSDecimalNumber(decimal: bill.amount).doubleValue
        let lowerBound = amount * (1.0 - tolerance)
        let upperBound = amount * (1.0 + tolerance)

        // Query bills within amount tolerance
        var matches: [SwapBill] = try await supabase
            .from("swap_bills")
            .select()
            .neq("user_id", value: userId.uuidString)
            .eq("status", value: "unmatched")
            .gte("amount", value: lowerBound)
            .lte("amount", value: upperBound)
            .order("created_at", ascending: false)
            .execute()
            .value

        // Filter by timeline compatibility if bill has a due date
        if let billDueDate = bill.dueDate {
            let calendar = Calendar.current
            let windowStart = calendar.date(byAdding: .day, value: -timelineWindowDays, to: billDueDate)!
            let windowEnd = calendar.date(byAdding: .day, value: timelineWindowDays, to: billDueDate)!

            matches = matches.filter { match in
                guard let matchDueDate = match.dueDate else {
                    // Bills without due dates are still matchable
                    return true
                }
                return matchDueDate >= windowStart && matchDueDate <= windowEnd
            }
        }

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
    /// Validates tier limits before creating
    func createSwap(myBillId: UUID, partnerBillId: UUID, partnerUserId: UUID) async throws -> BillSwapTransaction {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        // Check if user is eligible to swap (not locked)
        guard try await canUserSwap() else {
            throw SwapError.eligibilityLocked
        }

        // Get my bill to validate amount
        let myBill = try await SwapBillService.shared.getBill(id: myBillId)

        // Validate bill amount against tier limit
        guard try await validateBillAmountForTier(amount: myBill.amount) else {
            let tierLimit = try await getUserTierLimit()
            throw SwapError.amountExceedsTierLimit(
                amount: myBill.amount,
                limit: tierLimit
            )
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

        // Get the bill amount for the notification (reuse myBill from validation above)
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
    /// - Returns: TierAdvancementResult if the swap completed and user advanced to a new tier
    func markPartnerPaid(swapId: UUID, proofUrl: String) async throws -> TierAdvancementResult? {
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

        var tierAdvancementResult: TierAdvancementResult? = nil
        if updatedSwap.canComplete {
            tierAdvancementResult = try await completeSwap(swapId: swapId)
        }

        // Refresh swaps
        try await fetchMySwaps()

        return tierAdvancementResult
    }

    /// Complete a swap and check for tier advancement
    /// - Returns: TierAdvancementResult if user advanced to a new tier, nil otherwise
    func completeSwap(swapId: UUID) async throws -> TierAdvancementResult? {
        // Get tier BEFORE completing (database trigger will update it)
        let previousTrustInfo = try await getUserTrustInfo()
        let previousTier = previousTrustInfo.tier

        // Complete the swap - database trigger handles tier updates
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

        // Check for tier advancement AFTER database trigger ran
        let newTrustInfo = try await getUserTrustInfo()
        let newTier = newTrustInfo.tier
        let billixScore = try await getBillixScore()

        // Refresh swaps
        try await fetchMySwaps()

        // Return tier advancement result if tier changed
        if newTier > previousTier {
            return TierAdvancementResult(
                previousTier: previousTier,
                newTier: newTier,
                swapsCompleted: newTrustInfo.successfulSwaps,
                newBillixScore: billixScore
            )
        }

        return nil
    }

    /// Get user's Billix Score from profiles table
    func getBillixScore() async throws -> Int {
        guard let userId = currentUserId else {
            throw SwapError.notAuthenticated
        }

        struct ProfileScore: Decodable {
            let trustScore: Int?

            enum CodingKeys: String, CodingKey {
                case trustScore = "trust_score"
            }
        }

        let result: ProfileScore = try await supabase
            .from("profiles")
            .select("trust_score")
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return result.trustScore ?? 0
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

/// Insert model for creating default trust records
private struct SwapTrustInsert: Encodable {
    let userId: UUID
    let tier: Int
    let totalSwaps: Int
    let successfulSwaps: Int
    let disputedSwaps: Int
    let missedDeadlines: Int
    let trustPoints: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case tier
        case totalSwaps = "total_swaps"
        case successfulSwaps = "successful_swaps"
        case disputedSwaps = "disputed_swaps"
        case missedDeadlines = "missed_deadlines"
        case trustPoints = "trust_points"
    }

    init(userId: UUID) {
        self.userId = userId
        self.tier = 1
        self.totalSwaps = 0
        self.successfulSwaps = 0
        self.disputedSwaps = 0
        self.missedDeadlines = 0
        self.trustPoints = 0
    }
}

/// Errors for SwapService
enum SwapError: LocalizedError {
    case notAuthenticated
    case swapNotFound
    case alreadyMatched
    case invalidSwapState
    case noFreeSwapsRemaining
    case eligibilityLocked
    case amountExceedsTierLimit(amount: Decimal, limit: Decimal)

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
        case .eligibilityLocked:
            return "Your swap eligibility is temporarily locked due to a recent dispute. Please wait until the lock expires."
        case .amountExceedsTierLimit(let amount, let limit):
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            let amountStr = formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
            let limitStr = formatter.string(from: limit as NSDecimalNumber) ?? "$\(limit)"
            return "Bill amount \(amountStr) exceeds your tier limit of \(limitStr). Complete more successful swaps to increase your limit."
        }
    }
}

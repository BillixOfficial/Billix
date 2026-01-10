//
//  BillSwapViewModel.swift
//  Billix
//
//  Bill Swap Hub ViewModel - with Matching, Activity Feed, and Import
//

import Foundation
import Combine

@MainActor
class BillSwapViewModel: ObservableObject {
    // MARK: - Services
    private let billSwapService = BillSwapService.shared
    private let trustService = TrustService.shared
    private let pointsService = PointsService.shared
    private let paymentService = SwapPaymentService.shared
    private let matchingService = MatchingService.shared

    // MARK: - Published Properties

    // User state
    @Published var trustProfile: TrustProfile?
    @Published var pointsBalance: Int = 0

    // Bills
    @Published var myBills: [SwapBill] = []
    @Published var availableBills: [SwapBill] = []

    // Swaps
    @Published var activeSwaps: [BillSwap] = []
    @Published var swapHistory: [BillSwap] = []

    // Matching
    @Published var proposedMatches: [SwapMatch] = []
    @Published var isMatching = false
    @Published var selectedBillForMatching: SwapBill?

    // Activity Feed
    @Published var activityFeed: [SwapActivityFeedItem] = []
    @Published var activityStats: ActivityFeedStats?

    // UI State
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var showCreateBillSheet = false
    @Published var showImportSheet = false
    @Published var selectedTab: SwapHubTab = .marketplace

    // Filters
    @Published var categoryFilter: SwapBillCategory?
    @Published var maxAmountFilter: Int?

    // MARK: - Computed Properties

    var filteredAvailableBills: [SwapBill] {
        var bills = availableBills

        if let category = categoryFilter {
            bills = bills.filter { $0.category == category }
        }

        if let maxAmount = maxAmountFilter {
            bills = bills.filter { $0.amountCents <= maxAmount }
        }

        return bills
    }

    var canCreateBill: Bool {
        guard let profile = trustProfile else { return false }
        return profile.activeSwapsCount < profile.tier.maxActiveSwaps
    }

    var tierInfo: (name: String, maxBill: String, maxSwaps: Int)? {
        guard let profile = trustProfile else { return nil }
        return (
            name: profile.tier.displayName,
            maxBill: profile.tier.formattedMaxBill,
            maxSwaps: profile.tier.maxActiveSwaps
        )
    }

    var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    var pendingSwapsCount: Int {
        activeSwaps.filter { $0.status == .offered || $0.status == .countered }.count
    }

    var swapsNeedingAction: [BillSwap] {
        guard let userId = SupabaseService.shared.currentUserId else { return [] }

        return activeSwaps.filter { swap in
            switch swap.status {
            case .offered, .countered:
                // Counterparty needs to accept/decline
                return swap.counterpartyUserId == nil || swap.counterpartyUserId == userId
            case .acceptedPendingFee:
                // Check if current user hasn't paid fee
                if swap.initiatorUserId == userId && !swap.feePaidInitiator {
                    return true
                }
                if swap.counterpartyUserId == userId && !swap.feePaidCounterparty {
                    return true
                }
                return false
            case .awaitingProof:
                // User needs to submit or review proof
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Load Data

    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load all data in parallel
            async let profileTask = trustService.fetchCurrentUserProfile()
            async let balanceTask = pointsService.fetchCurrentBalance()
            async let myBillsTask = billSwapService.fetchMyBills()
            async let availableBillsTask = billSwapService.fetchAvailableBills()
            async let activeSwapsTask = billSwapService.fetchActiveSwaps()
            async let historyTask = billSwapService.fetchSwapHistory()
            async let activityFeedTask = billSwapService.fetchActivityFeed()
            async let activityStatsTask = billSwapService.fetchActivityStats()

            trustProfile = try await profileTask
            pointsBalance = try await balanceTask
            myBills = try await myBillsTask
            availableBills = try await availableBillsTask
            activeSwaps = try await activeSwapsTask
            swapHistory = try await historyTask
            activityFeed = try await activityFeedTask
            activityStats = try? await activityStatsTask

            // Debug logging for bills visibility
            print("📋 BillSwap Debug:")
            print("   - Current user ID: \(currentUserId?.uuidString ?? "nil")")
            print("   - My bills count: \(myBills.count)")
            print("   - Available bills count: \(availableBills.count)")
            for bill in availableBills {
                print("   - Available bill: \(bill.title) | owner: \(bill.ownerUserId) | status: \(bill.status.rawValue)")
            }

            // Load payment products
            await paymentService.loadProducts()

            // Auto-find matches for available bills
            if let profile = trustProfile {
                await findMatchesForMyBills(profile: profile)
            }
        } catch {
            self.error = error
            print("❌ Failed to load bill swap data: \(error)")
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await loadInitialData()
    }

    // MARK: - Activity Feed

    func refreshActivityFeed() async {
        do {
            activityFeed = try await billSwapService.fetchActivityFeed()
            activityStats = try? await billSwapService.fetchActivityStats()
        } catch {
            print("❌ Failed to refresh activity feed: \(error)")
        }
    }

    // MARK: - Create Bill

    func createBill(
        title: String,
        category: SwapBillCategory,
        providerName: String?,
        amountCents: Int,
        dueDate: Date,
        paymentUrl: String?,
        accountNumberLast4: String?,
        billImageUrl: String? = nil
    ) async throws -> SwapBill {
        let request = CreateBillRequest(
            title: title,
            category: category,
            providerName: providerName,
            amountCents: amountCents,
            dueDate: dueDate,
            paymentUrl: paymentUrl,
            accountNumberLast4: accountNumberLast4,
            billImageUrl: billImageUrl
        )

        let bill = try await billSwapService.createBill(request)
        myBills.insert(bill, at: 0)
        return bill
    }

    // MARK: - Create Swap

    func createSwapOffer(
        billId: UUID,
        swapType: BillSwapType,
        counterpartyId: UUID? = nil
    ) async throws -> BillSwap {
        let request = CreateSwapRequest(
            billAId: billId,
            billBId: nil,
            counterpartyUserId: counterpartyId,
            swapType: swapType
        )

        let swap = try await billSwapService.createSwap(request)
        activeSwaps.insert(swap, at: 0)

        // Update bill status in local state
        if let index = myBills.firstIndex(where: { $0.id == billId }) {
            myBills[index].status = .lockedInSwap
        }

        return swap
    }

    // MARK: - Accept Swap

    func acceptSwap(_ swap: BillSwap, withBillId: UUID? = nil) async throws {
        try await billSwapService.acceptSwap(swap.id, billBId: withBillId)

        // Refresh active swaps
        activeSwaps = try await billSwapService.fetchActiveSwaps()
    }

    // MARK: - Cancel Swap

    func cancelSwap(_ swap: BillSwap) async throws {
        try await billSwapService.cancelSwap(swap.id)
        activeSwaps.removeAll { $0.id == swap.id }

        // Refresh my bills to unlock the bill
        myBills = try await billSwapService.fetchMyBills()
    }

    // MARK: - Delete Bill

    func deleteBill(_ bill: SwapBill) async throws {
        guard bill.status == .draft else {
            throw BillSwapError.operationFailed("Only draft bills can be deleted")
        }

        try await billSwapService.deleteBill(bill.id)
        myBills.removeAll { $0.id == bill.id }
    }

    // MARK: - Helpers

    func getSwap(by id: UUID) -> BillSwap? {
        activeSwaps.first { $0.id == id } ?? swapHistory.first { $0.id == id }
    }

    func getBill(by id: UUID) -> SwapBill? {
        myBills.first { $0.id == id } ?? availableBills.first { $0.id == id }
    }

    // MARK: - Matching

    /// Find matches for a specific bill
    func findMatches(for bill: SwapBill) async {
        guard let profile = trustProfile else { return }

        isMatching = true
        selectedBillForMatching = bill

        do {
            proposedMatches = try await matchingService.findMatches(for: bill, userProfile: profile)
            print("🔍 Found \(proposedMatches.count) matches for \(bill.title)")
        } catch {
            print("❌ Match search failed: \(error)")
            proposedMatches = []
        }

        isMatching = false
    }

    /// Find matches for all user's available bills
    func findMatchesForMyBills(profile: TrustProfile) async {
        let availableForSwap = myBills.filter { $0.status == .active }
        guard !availableForSwap.isEmpty else { return }

        isMatching = true

        do {
            try await matchingService.refreshAllMatches(for: availableForSwap, userProfile: profile)
            proposedMatches = matchingService.proposedMatches
            print("🔍 Found \(proposedMatches.count) total matches across all bills")
        } catch {
            print("❌ Match refresh failed: \(error)")
        }

        isMatching = false
    }

    /// Accept a proposed match and create swap
    func acceptMatch(_ match: SwapMatch) async throws -> BillSwap {
        let swap = try await billSwapService.createSwapFromMatch(match)
        activeSwaps.insert(swap, at: 0)

        // Remove from proposed matches
        proposedMatches.removeAll { $0.id == match.id }

        // Update bill status
        if let index = myBills.firstIndex(where: { $0.id == match.yourBill.id }) {
            myBills[index].status = .lockedInSwap
        }

        return swap
    }

    /// Clear proposed matches
    func clearMatches() {
        proposedMatches = []
        selectedBillForMatching = nil
    }

    // MARK: - Import from Upload

    /// Import a bill from BillAnalysis (from Upload feature)
    func importBillFromAnalysis(_ analysis: BillAnalysis) async throws -> SwapBill {
        let bill = try await billSwapService.importBillFromAnalysis(analysis)
        myBills.insert(bill, at: 0)

        // Auto-find matches for the new bill
        if let profile = trustProfile {
            await findMatches(for: bill)
        }

        return bill
    }

    // MARK: - Proof Handling

    /// Submit payment proof for a swap
    func submitProof(
        swapId: UUID,
        imageData: Data,
        notes: String? = nil
    ) async throws -> SwapProof {
        let proof = try await billSwapService.submitPaymentProof(
            swapId: swapId,
            imageData: imageData,
            notes: notes
        )

        // Refresh swap state
        activeSwaps = try await billSwapService.fetchActiveSwaps()

        return proof
    }

    /// Fetch proofs for a swap
    func fetchProofs(for swapId: UUID) async throws -> [SwapProof] {
        return try await billSwapService.fetchProofs(for: swapId)
    }

    // MARK: - Privacy Shield

    /// Create redacted bill info for counterparty view
    func createRedactedBillInfo(for bill: SwapBill) -> RedactedBillInfo {
        RedactedBillInfo.fromBill(bill, ownerProfile: nil)
    }

    // MARK: - Deal Sheet

    /// Create deal sheet panels for a swap
    func createDealSheetPanels(for swap: BillSwap) -> (yourPanel: DealSheetBillPanel, theirPanel: DealSheetBillPanel)? {
        guard let userId = currentUserId,
              let billA = swap.billA,
              let billB = swap.billB else { return nil }

        let isInitiator = swap.initiatorUserId == userId
        let yourBill = isInitiator ? billA : billB
        let theirBill = isInitiator ? billB : billA

        let yourRedacted = RedactedBillInfo.fromBill(yourBill, ownerProfile: swap.initiatorProfile)
        let theirRedacted = RedactedBillInfo.fromBill(theirBill, ownerProfile: swap.counterpartyProfile)

        let yourStatus = determineBillStatus(for: swap, isYourBill: true, isInitiator: isInitiator)
        let theirStatus = determineBillStatus(for: swap, isYourBill: false, isInitiator: isInitiator)

        let yourPanel = DealSheetBillPanel(
            isOwner: true,
            billInfo: yourRedacted,
            status: yourStatus
        )

        let theirPanel = DealSheetBillPanel(
            isOwner: false,
            billInfo: theirRedacted,
            status: theirStatus
        )

        return (yourPanel, theirPanel)
    }

    private func determineBillStatus(for swap: BillSwap, isYourBill: Bool, isInitiator: Bool) -> DealSheetBillStatus {
        switch swap.status {
        case .offered, .countered, .acceptedPendingFee:
            return .readyToBePaid
        case .locked:
            if let deadline = swap.proofDueDeadline {
                return .pendingPayment(dueDate: deadline)
            }
            return .readyToBePaid
        case .awaitingProof:
            return .paymentSubmitted
        case .completed:
            return .completed
        default:
            return .readyToBePaid
        }
    }
}

// MARK: - Hub Tab

enum SwapHubTab: String, CaseIterable, Identifiable {
    case marketplace = "Marketplace"
    case matches = "Matches"
    case myBills = "My Bills"
    case active = "Active"
    case history = "History"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .marketplace: return "storefront"
        case .matches: return "person.2.badge.gearshape"
        case .myBills: return "doc.text"
        case .active: return "clock"
        case .history: return "checkmark.circle"
        }
    }

    var description: String {
        switch self {
        case .marketplace: return "Browse available bills and activity"
        case .matches: return "View proposed swap matches"
        case .myBills: return "Bills available for swapping"
        case .active: return "Your active swaps"
        case .history: return "Completed and past swaps"
        }
    }
}

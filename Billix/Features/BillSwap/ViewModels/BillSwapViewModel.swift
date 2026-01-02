//
//  BillSwapViewModel.swift
//  Billix
//
//  Bill Swap Hub ViewModel
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

    // UI State
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var showCreateBillSheet = false
    @Published var selectedTab: SwapHubTab = .available

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

            trustProfile = try await profileTask
            pointsBalance = try await balanceTask
            myBills = try await myBillsTask
            availableBills = try await availableBillsTask
            activeSwaps = try await activeSwapsTask
            swapHistory = try await historyTask

            // Load payment products
            await paymentService.loadProducts()
        } catch {
            self.error = error
            print("Failed to load bill swap data: \(error)")
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await loadInitialData()
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
}

// MARK: - Hub Tab

enum SwapHubTab: String, CaseIterable, Identifiable {
    case available = "Available"
    case myBills = "My Bills"
    case active = "Active"
    case history = "History"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .available: return "arrow.left.arrow.right"
        case .myBills: return "doc.text"
        case .active: return "clock"
        case .history: return "checkmark.circle"
        }
    }
}

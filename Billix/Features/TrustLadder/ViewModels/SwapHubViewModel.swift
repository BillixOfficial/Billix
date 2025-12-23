//
//  SwapHubViewModel.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  ViewModel for the main Swap Hub interface
//

import Foundation
import SwiftUI

@MainActor
class SwapHubViewModel: ObservableObject {

    // MARK: - Tab Selection
    enum SwapHubTab: String, CaseIterable {
        case mySwaps = "My Swaps"
        case findMatch = "Find Match"
        case history = "History"

        var icon: String {
            switch self {
            case .mySwaps: return "arrow.left.arrow.right"
            case .findMatch: return "person.2.fill"
            case .history: return "clock.fill"
            }
        }
    }

    // MARK: - Published Properties

    // Navigation
    @Published var selectedTab: SwapHubTab = .mySwaps
    @Published var showPortfolioSetup = false
    @Published var showSwapDetail: Swap?
    @Published var showMatchDetail: MatchedPartner?

    // Data
    @Published var trustStatus: UserTrustStatus?
    @Published var activeSwaps: [Swap] = []
    @Published var pendingMatches: [MatchedPartner] = []
    @Published var completedSwaps: [Swap] = []
    @Published var myBills: [UserBill] = []
    @Published var paydaySchedule: PaydaySchedule?

    // UI State
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var showError = false
    @Published var errorMessage = ""

    // Services
    private let trustService = TrustLadderService.shared
    private let portfolioService = BillPortfolioService.shared

    // MARK: - Computed Properties

    var isPortfolioSetupComplete: Bool {
        portfolioService.isPortfolioComplete
    }

    var tier: TrustTier {
        trustStatus?.tier ?? .streamer
    }

    var tierProgress: Double {
        trustStatus?.progressToNextTier ?? 0
    }

    var swapsToNextTier: Int? {
        trustStatus?.swapsToNextTier
    }

    var hasActiveSwaps: Bool {
        !activeSwaps.isEmpty
    }

    var canStartNewSwap: Bool {
        isPortfolioSetupComplete && !myBills.isEmpty
    }

    var availableBillsForSwap: [UserBill] {
        myBills.filter { bill in
            guard let category = bill.category else { return false }
            return trustService.canSwapCategory(category) &&
                   trustService.canSwapAmount(bill.typicalAmount)
        }
    }

    // MARK: - Load Data

    func loadSwapHub() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load trust status
            trustStatus = try await trustService.fetchOrInitializeTrustStatus()

            // Load portfolio
            try await portfolioService.loadPortfolio()
            myBills = portfolioService.userBills
            paydaySchedule = portfolioService.paydaySchedule

            // Check if portfolio setup is needed
            if !isPortfolioSetupComplete {
                showPortfolioSetup = true
                return
            }

            // Load swaps (mock data for now - would come from SwapService)
            await loadSwaps()

        } catch {
            showError(error.localizedDescription)
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await loadSwapHub()
    }

    private func loadSwaps() async {
        // TODO: Implement SwapService to load actual swaps
        // For now, using empty arrays
        activeSwaps = []
        completedSwaps = []
        pendingMatches = []
    }

    // MARK: - Actions

    func selectBillForSwap(_ bill: UserBill) {
        // Navigate to match finding
        selectedTab = .findMatch
        // TODO: Trigger match search
    }

    func acceptMatch(_ match: MatchedPartner, myBill: UserBill) async {
        isLoading = true
        defer { isLoading = false }

        // TODO: Implement match acceptance via SwapService
        showSuccess("Match accepted! Waiting for partner confirmation.")
    }

    func cancelSwap(_ swap: Swap) async {
        isLoading = true
        do {
            // TODO: Implement swap cancellation via SwapService
        }
        isLoading = false
    }

    func viewSwapDetail(_ swap: Swap) {
        showSwapDetail = swap
    }

    func viewMatchDetail(_ match: MatchedPartner) {
        showMatchDetail = match
    }

    // MARK: - Portfolio Setup

    func openPortfolioSetup() {
        showPortfolioSetup = true
    }

    func onPortfolioSetupComplete() {
        showPortfolioSetup = false
        Task {
            await loadSwapHub()
        }
    }

    // MARK: - Error Handling

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func showSuccess(_ message: String) {
        // TODO: Implement success toast
    }

    func dismissError() {
        showError = false
        errorMessage = ""
    }
}

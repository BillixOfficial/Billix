//
//  PortfolioSetupViewModel.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  ViewModel for setting up user's bill portfolio and payday schedule
//

import Foundation
import SwiftUI

@MainActor
class PortfolioSetupViewModel: ObservableObject {

    // MARK: - Setup Step
    enum SetupStep: Int, CaseIterable {
        case payday = 0
        case bills = 1
        case review = 2

        var title: String {
            switch self {
            case .payday: return "When do you get paid?"
            case .bills: return "Add your bills"
            case .review: return "Review your portfolio"
            }
        }

        var subtitle: String {
            switch self {
            case .payday: return "We'll match you with partners who have money when you need it"
            case .bills: return "Add bills you'd like to swap with others"
            case .review: return "Make sure everything looks good"
            }
        }
    }

    // MARK: - Published Properties

    // Navigation
    @Published var currentStep: SetupStep = .payday
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isComplete = false

    // Payday
    @Published var selectedPaydayType: PaydayType = .biweekly
    @Published var selectedWeekday: Int = 6 // Friday (1=Sun, 2=Mon, etc.)
    @Published var selectedMonthDays: [Int] = [1, 15]

    // Bills
    @Published var selectedCategory: SwapBillCategory?
    @Published var billProviderName = ""
    @Published var billAmount = ""
    @Published var billDueDay: Int = 15
    @Published var addedBills: [UserBill] = []

    // Services
    private let portfolioService = BillPortfolioService.shared
    private let trustService = TrustLadderService.shared

    // MARK: - Computed Properties

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(SetupStep.allCases.count)
    }

    var canProceedFromPayday: Bool {
        switch selectedPaydayType {
        case .weekly, .biweekly:
            return selectedWeekday >= 1 && selectedWeekday <= 7
        case .semiMonthly:
            return selectedMonthDays.count == 2
        case .monthly:
            return !selectedMonthDays.isEmpty
        }
    }

    var canProceedFromBills: Bool {
        !addedBills.isEmpty
    }

    var paydayDays: [Int] {
        switch selectedPaydayType {
        case .weekly, .biweekly:
            return [selectedWeekday]
        case .semiMonthly, .monthly:
            return selectedMonthDays.sorted()
        }
    }

    var availableCategories: [SwapBillCategory] {
        trustService.availableCategories()
    }

    var billAmountDouble: Double? {
        Double(billAmount.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: ""))
    }

    var canAddBill: Bool {
        guard let category = selectedCategory else { return false }
        guard let amount = billAmountDouble, amount > 0 else { return false }
        guard !billProviderName.isEmpty else { return false }
        guard billDueDay >= 1 && billDueDay <= 31 else { return false }
        return amount <= category.tier.maxAmount
    }

    // MARK: - Weekday Options

    let weekdayOptions: [(value: Int, name: String)] = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]

    let monthDayOptions: [Int] = Array(1...31)

    // MARK: - Navigation

    func nextStep() {
        guard let nextIndex = SetupStep(rawValue: currentStep.rawValue + 1) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextIndex
        }
    }

    func previousStep() {
        guard let prevIndex = SetupStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prevIndex
        }
    }

    // MARK: - Payday Actions

    func savePaydaySchedule() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await portfolioService.setPaydaySchedule(
                type: selectedPaydayType,
                days: paydayDays
            )
            nextStep()
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Bill Actions

    func selectCategory(_ category: SwapBillCategory) {
        selectedCategory = category
        billProviderName = category.displayName
    }

    func addBill() async {
        guard canAddBill,
              let category = selectedCategory,
              let amount = billAmountDouble else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let bill = try await portfolioService.addBill(
                category: category,
                providerName: billProviderName,
                typicalAmount: amount,
                dueDay: billDueDay
            )

            addedBills.append(bill)
            resetBillForm()
        } catch {
            showError(error.localizedDescription)
        }
    }

    func removeBill(_ bill: UserBill) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await portfolioService.deleteBill(id: bill.id)
            addedBills.removeAll { $0.id == bill.id }
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func resetBillForm() {
        selectedCategory = nil
        billProviderName = ""
        billAmount = ""
        billDueDay = 15
    }

    // MARK: - Complete Setup

    func completeSetup() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Initialize trust status if needed
            _ = try await trustService.fetchOrInitializeTrustStatus()

            // Reload portfolio
            try await portfolioService.loadPortfolio()

            isComplete = true
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Load Existing Data

    func loadExistingData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await portfolioService.loadPortfolio()

            // Load existing bills
            addedBills = portfolioService.userBills

            // Load existing payday schedule
            if let schedule = portfolioService.paydaySchedule,
               let type = PaydayType(rawValue: schedule.paydayType) {
                selectedPaydayType = type

                switch type {
                case .weekly, .biweekly:
                    selectedWeekday = schedule.paydayDays.first ?? 6
                case .semiMonthly, .monthly:
                    selectedMonthDays = schedule.paydayDays
                }
            }
        } catch {
            // Ignore errors - user may be setting up for first time
        }
    }

    // MARK: - Error Handling

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }

    func dismissError() {
        showError = false
        errorMessage = ""
    }
}

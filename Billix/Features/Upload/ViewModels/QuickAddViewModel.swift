//
//  QuickAddViewModel.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation
import SwiftUI

/// ViewModel for the 4-step Quick Add flow
@MainActor
class QuickAddViewModel: ObservableObject {

    // MARK: - Step State

    enum Step: Int, CaseIterable {
        case billType = 1
        case provider = 2
        case amount = 3
        case result = 4

        var title: String {
            switch self {
            case .billType: return "Choose Bill Type"
            case .provider: return "Select Provider"
            case .amount: return "Enter Amount"
            case .result: return "Your Result"
            }
        }
    }

    // MARK: - Published Properties

    @Published var currentStep: Step = .billType
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Step 1: Bill Type
    @Published var billTypes: [BillType] = []
    @Published var selectedBillType: BillType?

    // Step 2: Provider
    @Published var zipCode: String = ""
    @Published var providers: [BillProvider] = []
    @Published var selectedProvider: BillProvider?

    // Step 3: Amount
    @Published var amount: String = ""
    @Published var frequency: BillingFrequency = .monthly

    // Step 4: Result
    @Published var result: QuickAddResult?

    // MARK: - Dependencies

    private let uploadService: BillUploadServiceProtocol

    // MARK: - Initialization

    init(uploadService: BillUploadServiceProtocol? = nil) {
        self.uploadService = uploadService ?? BillUploadServiceFactory.create()
    }

    // MARK: - Lifecycle

    func onAppear() {
        Task {
            await loadBillTypes()
        }
    }

    // MARK: - Step 1: Load Bill Types

    func loadBillTypes() async {
        isLoading = true
        errorMessage = nil

        do {
            billTypes = try await uploadService.getBillTypes()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func selectBillType(_ billType: BillType) {
        selectedBillType = billType
        nextStep()
    }

    // MARK: - Step 2: Load Providers

    func loadProviders() async {
        guard let billType = selectedBillType else { return }

        // Validate ZIP code
        guard zipCode.count == 5, zipCode.allSatisfy({ $0.isNumber }) else {
            errorMessage = "Please enter a valid 5-digit ZIP code"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            providers = try await uploadService.getProviders(zipCode: zipCode, billType: billType)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func selectProvider(_ provider: BillProvider) {
        selectedProvider = provider
        nextStep()
    }

    // MARK: - Step 3: Submit Quick Add

    func submitQuickAdd() async {
        guard let billType = selectedBillType,
              let provider = selectedProvider,
              let amountValue = Double(amount),
              amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let request = QuickAddRequest(
                billType: billType,
                provider: provider,
                zipCode: zipCode,
                amount: amountValue,
                frequency: frequency
            )

            result = try await uploadService.submitQuickAdd(request: request)
            nextStep()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Navigation

    func nextStep() {
        if let nextStep = Step(rawValue: currentStep.rawValue + 1) {
            withAnimation {
                currentStep = nextStep
            }
        }
    }

    func previousStep() {
        if let prevStep = Step(rawValue: currentStep.rawValue - 1) {
            withAnimation {
                currentStep = prevStep
            }
        }
    }

    func reset() {
        currentStep = .billType
        selectedBillType = nil
        zipCode = ""
        providers = []
        selectedProvider = nil
        amount = ""
        frequency = .monthly
        result = nil
        errorMessage = nil
    }

    // MARK: - Computed Properties

    var canProceed: Bool {
        switch currentStep {
        case .billType:
            return selectedBillType != nil
        case .provider:
            return selectedProvider != nil && zipCode.count == 5
        case .amount:
            return Double(amount) != nil && Double(amount)! > 0
        case .result:
            return false
        }
    }

    var progressPercentage: Double {
        return Double(currentStep.rawValue) / Double(Step.allCases.count)
    }
}

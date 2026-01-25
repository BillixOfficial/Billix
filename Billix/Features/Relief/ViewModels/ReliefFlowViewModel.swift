//
//  ReliefFlowViewModel.swift
//  Billix
//
//  ViewModel for the multi-step Relief request flow
//

import Foundation
import SwiftUI
import Supabase

/// ViewModel for the multi-step Relief request flow
@MainActor
class ReliefFlowViewModel: ObservableObject {

    // MARK: - Step Definition

    enum Step: Int, CaseIterable {
        case personalInfo = 1
        case billInfo = 2
        case situation = 3
        case urgency = 4
        case review = 5

        var title: String {
            switch self {
            case .personalInfo: return "Your Information"
            case .billInfo: return "Bill Details"
            case .situation: return "Your Situation"
            case .urgency: return "Urgency Level"
            case .review: return "Review & Submit"
            }
        }

        var icon: String {
            switch self {
            case .personalInfo: return "person.fill"
            case .billInfo: return "doc.text.fill"
            case .situation: return "house.fill"
            case .urgency: return "exclamationmark.triangle.fill"
            case .review: return "checkmark.circle.fill"
            }
        }
    }

    // MARK: - Published Properties

    @Published var currentStep: Step = .personalInfo
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var submittedRequest: ReliefRequest?

    // Step 1: Personal Info
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""

    // Step 2: Bill Info
    @Published var billType: ReliefBillType = .electric
    @Published var billProvider: String = ""
    @Published var amountOwed: String = ""
    @Published var description: String = ""

    // Step 3: Situation
    @Published var incomeLevel: ReliefIncomeLevel = .preferNotToSay
    @Published var householdSize: Int = 1
    @Published var employmentStatus: ReliefEmploymentStatus = .employedFullTime

    // Step 4: Urgency
    @Published var urgencyLevel: ReliefUrgencyLevel = .medium
    @Published var hasShutoffDate: Bool = false
    @Published var utilityShutoffDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60) // Default 1 week from now

    // MARK: - Dependencies

    private let reliefService = ReliefService.shared

    // MARK: - Initialization

    init() {
        // Pre-fill name from user profile if available
        if let user = AuthService.shared.currentUser {
            fullName = user.displayName
        }
        // Email will be pre-filled when view appears via prefillUserInfo()
    }

    /// Pre-fill user info from the current session (call this in onAppear)
    func prefillUserInfo() async {
        if let user = AuthService.shared.currentUser {
            fullName = user.displayName
        }
        // Fetch email from Supabase session
        do {
            let session = try await SupabaseService.shared.client.auth.session
            await MainActor.run {
                email = session.user.email ?? ""
            }
        } catch {
            print("Could not fetch user email: \(error)")
        }
    }

    // MARK: - Computed Properties

    var progressPercentage: Double {
        Double(currentStep.rawValue) / Double(Step.allCases.count)
    }

    var isFirstStep: Bool {
        currentStep == .personalInfo
    }

    var isLastStep: Bool {
        currentStep == .review
    }

    var canProceed: Bool {
        switch currentStep {
        case .personalInfo:
            return !fullName.trimmingCharacters(in: .whitespaces).isEmpty && isValidEmail(email)
        case .billInfo:
            return Decimal(string: amountOwed) != nil && (Decimal(string: amountOwed) ?? 0) > 0
        case .situation:
            return householdSize >= 1
        case .urgency:
            return true
        case .review:
            return false // Submit button handles this
        }
    }

    var formattedAmount: String? {
        guard let amount = Decimal(string: amountOwed) else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber)
    }

    var amountDecimal: Decimal? {
        Decimal(string: amountOwed)
    }

    // MARK: - Navigation

    func nextStep() {
        guard validateCurrentStep() else { return }

        if let next = Step(rawValue: currentStep.rawValue + 1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = next
            }
        }
    }

    func previousStep() {
        if let prev = Step(rawValue: currentStep.rawValue - 1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = prev
            }
        }
    }

    func goToStep(_ step: Step) {
        // Only allow going back to previous steps
        if step.rawValue < currentStep.rawValue {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = step
            }
        }
    }

    func reset() {
        currentStep = .personalInfo
        fullName = AuthService.shared.currentUser?.displayName ?? ""
        email = "" // Will be re-populated via prefillUserInfo()
        phone = ""
        billType = .electric
        billProvider = ""
        amountOwed = ""
        description = ""
        incomeLevel = .preferNotToSay
        householdSize = 1
        employmentStatus = .employedFullTime
        urgencyLevel = .medium
        hasShutoffDate = false
        utilityShutoffDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        submittedRequest = nil
        errorMessage = nil
        showError = false
        // Re-fetch user info
        Task { await prefillUserInfo() }
    }

    // MARK: - Validation

    func validateCurrentStep() -> Bool {
        errorMessage = nil
        showError = false

        switch currentStep {
        case .personalInfo:
            guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
                errorMessage = "Please enter your full name"
                showError = true
                return false
            }
            guard isValidEmail(email) else {
                errorMessage = "Please enter a valid email address"
                showError = true
                return false
            }

        case .billInfo:
            guard let amount = Decimal(string: amountOwed), amount > 0 else {
                errorMessage = "Please enter a valid amount"
                showError = true
                return false
            }

        case .situation:
            guard householdSize >= 1 else {
                errorMessage = "Household size must be at least 1"
                showError = true
                return false
            }

        case .urgency, .review:
            break
        }

        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: trimmed)
    }

    // MARK: - Submission

    func submitRequest() async {
        guard validateCurrentStep() else { return }

        guard let amount = Decimal(string: amountOwed) else {
            errorMessage = "Invalid amount"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let request = try await reliefService.createRequest(
                fullName: fullName.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                phone: phone.isEmpty ? nil : phone,
                billType: billType,
                billProvider: billProvider.isEmpty ? nil : billProvider,
                amountOwed: amount,
                description: description.isEmpty ? nil : description,
                incomeLevel: incomeLevel,
                householdSize: householdSize,
                employmentStatus: employmentStatus,
                urgencyLevel: urgencyLevel,
                utilityShutoffDate: hasShutoffDate ? utilityShutoffDate : nil
            )

            submittedRequest = request
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}

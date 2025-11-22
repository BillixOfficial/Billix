//
//  ProfileViewModel.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation
import SwiftUI

/// ViewModel for managing profile screen state and data
@MainActor
class ProfileViewModel: ObservableObject {

    // MARK: - Published Properties

    // Main data
    @Published var userProfile: UserProfile?
    @Published var credits: BillixCredits?
    @Published var billHealth: BillHealthSnapshot?
    @Published var focusAreas: [FocusArea] = []
    @Published var savingsGoal: SavingsGoal?
    @Published var dataConnection: DataConnection?
    @Published var marketplaceSettings: MarketplaceSettings?
    @Published var notificationPrefs: NotificationPreferences?
    @Published var securityAccount: SecurityAccount?

    // UI States
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var showError = false

    // Navigation
    @Published var showEditProfile = false
    @Published var showCreditsDetail = false
    @Published var showNotificationSettings = false
    @Published var showSecuritySettings = false

    // MARK: - Private Properties
    private let profileService = ProfileService.shared

    // MARK: - Initialization
    init() {
        Task {
            await loadAllData()
        }
    }

    // MARK: - Data Loading

    /// Load all profile data
    func loadAllData() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let profile = profileService.getProfile()
            async let credits = profileService.getCredits()
            async let billHealth = profileService.getBillHealth()
            async let focusAreas = profileService.getFocusAreas()
            async let savingsGoal = profileService.getSavingsGoal()
            async let dataConnection = profileService.getDataConnections()
            async let marketplaceSettings = profileService.getMarketplaceSettings()
            async let notificationPrefs = profileService.getNotificationPreferences()
            async let securityAccount = profileService.getSecurityAccount()

            self.userProfile = try await profile
            self.credits = try await credits
            self.billHealth = try await billHealth
            self.focusAreas = try await focusAreas
            self.savingsGoal = try await savingsGoal
            self.dataConnection = try await dataConnection
            self.marketplaceSettings = try await marketplaceSettings
            self.notificationPrefs = try await notificationPrefs
            self.securityAccount = try await securityAccount

            print("✅ Profile data loaded successfully")
        } catch {
            handleError(error)
        }
    }

    /// Refresh all data (for pull-to-refresh)
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        await loadAllData()
    }

    // MARK: - Profile Actions

    /// Update user profile
    func updateProfile(_ profile: UserProfile) async {
        do {
            try await profileService.updateProfile(profile)
            self.userProfile = profile

            showSuccessMessage("Profile updated successfully")
            hapticFeedback(.medium)
        } catch {
            handleError(error)
        }
    }

    /// Upload avatar image
    func uploadAvatar(_ imageData: Data) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let avatarURL = try await profileService.uploadAvatar(imageData)

            if var profile = userProfile {
                profile.avatarURL = avatarURL
                self.userProfile = profile
            }

            showSuccessMessage("Avatar uploaded!")
            hapticFeedback(.medium)
        } catch {
            handleError(error)
        }
    }

    // MARK: - Credits Actions

    /// Refresh credits
    func refreshCredits() async {
        do {
            let updatedCredits = try await profileService.getCredits()
            self.credits = updatedCredits
        } catch {
            handleError(error)
        }
    }

    // MARK: - Bill Health Actions

    /// Refresh bill health
    func refreshBillHealth() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let updatedHealth = try await profileService.refreshBillHealth()
            self.billHealth = updatedHealth

            showSuccessMessage("Bill Health refreshed!")
            hapticFeedback(.medium)
        } catch {
            handleError(error)
        }
    }

    // MARK: - Focus Area Actions

    /// Toggle focus area
    func toggleFocusArea(_ focusArea: FocusArea) async {
        // Optimistic update
        if let index = focusAreas.firstIndex(where: { $0.id == focusArea.id }) {
            focusAreas[index].isEnabled.toggle()

            do {
                try await profileService.updateFocusArea(
                    id: focusArea.id,
                    isEnabled: focusAreas[index].isEnabled
                )

                hapticFeedback(.light)
            } catch {
                // Revert on error
                focusAreas[index].isEnabled.toggle()
                handleError(error)
            }
        }
    }

    /// Update savings goal
    func updateSavingsGoal(targetAmount: Double) async {
        do {
            try await profileService.updateSavingsGoal(targetAmount: targetAmount)

            if var goal = savingsGoal {
                goal.targetAmount = targetAmount
                self.savingsGoal = goal
            }

            hapticFeedback(.light)
        } catch {
            handleError(error)
        }
    }

    // MARK: - Data Connection Actions

    /// Add bank connection
    func addBankConnection(institutionName: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await profileService.addBankConnection(institutionName: institutionName)

            // Refresh data connections
            let updated = try await profileService.getDataConnections()
            self.dataConnection = updated

            showSuccessMessage("Bank account connected!")
            hapticFeedback(.medium)
        } catch {
            handleError(error)
        }
    }

    /// Remove bank connection
    func removeBankConnection(_ connection: BankConnection) async {
        do {
            try await profileService.removeBankConnection(id: connection.id)

            // Remove from local state
            dataConnection?.bankConnections.removeAll { $0.id == connection.id }

            showSuccessMessage("Bank account disconnected")
            hapticFeedback(.light)
        } catch {
            handleError(error)
        }
    }

    // MARK: - Marketplace Settings Actions

    /// Update marketplace settings
    func updateMarketplaceSettings(_ settings: MarketplaceSettings) async {
        // Optimistic update
        let oldSettings = marketplaceSettings
        self.marketplaceSettings = settings

        do {
            try await profileService.updateMarketplaceSettings(settings)
            hapticFeedback(.light)
        } catch {
            // Revert on error
            self.marketplaceSettings = oldSettings
            handleError(error)
        }
    }

    // MARK: - Notification Preferences Actions

    /// Update notification preferences
    func updateNotificationPreferences(_ prefs: NotificationPreferences) async {
        // Optimistic update
        let oldPrefs = notificationPrefs
        self.notificationPrefs = prefs

        do {
            try await profileService.updateNotificationPreferences(prefs)
            hapticFeedback(.light)
        } catch {
            // Revert on error
            self.notificationPrefs = oldPrefs
            handleError(error)
        }
    }

    // MARK: - Security Actions

    /// Update email
    func updateEmail(_ email: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await profileService.updateEmail(email)

            if var profile = userProfile {
                profile.email = email
                profile.isEmailVerified = false
                self.userProfile = profile
            }

            showSuccessMessage("Email updated. Please verify your new email.")
            hapticFeedback(.medium)
        } catch {
            handleError(error)
        }
    }

    /// Update phone number
    func updatePhoneNumber(_ phone: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await profileService.updatePhoneNumber(phone)

            if var profile = userProfile {
                profile.phoneNumber = phone
                profile.isPhoneVerified = false
                self.userProfile = profile
            }

            showSuccessMessage("Phone number updated. Please verify your new number.")
            hapticFeedback(.medium)
        } catch {
            handleError(error)
        }
    }

    /// Toggle two-factor authentication
    func toggleTwoFactorAuth() async {
        guard let currentStatus = securityAccount?.isTwoFactorEnabled else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await profileService.updateTwoFactorAuth(enabled: !currentStatus)

            if var account = securityAccount {
                account.isTwoFactorEnabled.toggle()
                self.securityAccount = account
            }

            showSuccessMessage(currentStatus ? "Two-factor auth disabled" : "Two-factor auth enabled")
            hapticFeedback(.medium)
        } catch {
            handleError(error)
        }
    }

    /// Logout from other devices
    func logoutOtherDevices() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await profileService.logoutOtherDevices()

            // Refresh security account
            let updated = try await profileService.getSecurityAccount()
            self.securityAccount = updated

            showSuccessMessage("Logged out from all other devices")
            hapticFeedback(.medium)
        } catch {
            handleError(error)
        }
    }

    /// Verify email
    func verifyEmail(code: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await profileService.verifyEmail(code: code)

            if var profile = userProfile {
                profile.isEmailVerified = true
                self.userProfile = profile
            }

            showSuccessMessage("Email verified successfully!")
            hapticFeedback(.medium)
        } catch {
            handleError(error)
        }
    }

    /// Verify phone
    func verifyPhone(code: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await profileService.verifyPhone(code: code)

            if var profile = userProfile {
                profile.isPhoneVerified = true
                self.userProfile = profile
            }

            showSuccessMessage("Phone verified successfully!")
            hapticFeedback(.medium)
        } catch {
            handleError(error)
        }
    }

    // MARK: - Copy to Clipboard

    /// Copy text to clipboard
    func copyToClipboard(_ text: String, message: String = "Copied to clipboard") {
        UIPasteboard.general.string = text
        showSuccessMessage(message)
        hapticFeedback(.light)
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        print("❌ ProfileViewModel Error: \(error.localizedDescription)")
        showErrorMessage(error.localizedDescription)
        hapticFeedback(.heavy)
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true

        // Auto-dismiss after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            clearError()
        }
    }

    private func showSuccessMessage(_ message: String) {
        errorMessage = message
        showError = true

        // Auto-dismiss after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            clearError()
        }
    }

    private func clearError() {
        errorMessage = nil
        showError = false
    }

    // MARK: - Haptic Feedback

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

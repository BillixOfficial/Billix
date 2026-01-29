//
//  MockDataService.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation

/// Mock data service for profile-related data during development
@MainActor
class MockDataService {

    // MARK: - Singleton
    static let shared = MockDataService()

    // MARK: - Private State
    private var mockProfile: UserProfile
    private var mockCredits: BillixCredits
    private var mockBillHealth: BillHealthSnapshot
    private var mockFocusAreas: [FocusArea]
    private var mockSavingsGoal: SavingsGoal
    private var mockDataConnection: DataConnection
    private var mockMarketplaceSettings: MarketplaceSettings
    private var mockNotificationPrefs: NotificationPreferences
    private var mockSecurityAccount: SecurityAccount

    // MARK: - Initialization
    private init() {
        // Initialize with preview data
        self.mockProfile = .preview
        self.mockCredits = .preview
        self.mockBillHealth = .preview
        self.mockFocusAreas = FocusArea.all
        self.mockSavingsGoal = .preview
        self.mockDataConnection = .preview
        self.mockMarketplaceSettings = .preview
        self.mockNotificationPrefs = .default
        self.mockSecurityAccount = .preview
    }

    // MARK: - Profile Methods

    /// Get current user profile
    func getProfile() async throws -> UserProfile {
        try await simulateNetworkDelay()
        return mockProfile
    }

    /// Update user profile
    func updateProfile(_ profile: UserProfile) async throws {
        try await simulateNetworkDelay()
        self.mockProfile = profile
    }

    /// Upload avatar image
    func uploadAvatar(_ imageData: Data) async throws -> String {
        try await simulateNetworkDelay()
        // In a real app, this would upload to cloud storage
        let avatarURL = "https://example.com/avatars/\(UUID().uuidString).jpg"
        mockProfile.avatarURL = avatarURL
        return avatarURL
    }

    // MARK: - Credits Methods

    /// Get user's Billix credits
    func getCredits() async throws -> BillixCredits {
        try await simulateNetworkDelay()
        return mockCredits
    }

    /// Add credit transaction
    func addCreditTransaction(type: TransactionType, amount: Int, description: String) async throws {
        try await simulateNetworkDelay()

        let transaction = CreditTransaction(
            id: UUID(),
            type: type,
            amount: amount,
            description: description,
            createdAt: Date()
        )

        mockCredits.transactions.insert(transaction, at: 0)
        mockCredits.balance += amount
    }

    /// Update earn task status
    func updateEarnTask(taskId: UUID, status: TaskStatus, progress: Double) async throws {
        try await simulateNetworkDelay()

        if let index = mockCredits.earnTasks.firstIndex(where: { $0.id == taskId }) {
            mockCredits.earnTasks[index].status = status
            mockCredits.earnTasks[index].progress = progress

            // Award credits if completed
            if status == .completed && mockCredits.earnTasks[index].status != .completed {
                let reward = mockCredits.earnTasks[index].reward
                try await addCreditTransaction(
                    type: .earned,
                    amount: reward,
                    description: "Completed: \(mockCredits.earnTasks[index].title)"
                )
            }
        }
    }

    // MARK: - Bill Health Methods

    /// Get bill health snapshot
    func getBillHealth() async throws -> BillHealthSnapshot {
        try await simulateNetworkDelay()
        return mockBillHealth
    }

    /// Refresh bill health calculation
    func refreshBillHealth() async throws -> BillHealthSnapshot {
        try await simulateNetworkDelay(duration: 2.0)

        // Simulate recalculation
        mockBillHealth.overallScore = Int.random(in: 70...95)
        mockBillHealth.estimatedSavings = Double.random(in: 30...100)

        return mockBillHealth
    }

    // MARK: - Goals & Focus Methods

    /// Get focus areas
    func getFocusAreas() async throws -> [FocusArea] {
        try await simulateNetworkDelay()
        return mockFocusAreas
    }

    /// Update focus area
    func updateFocusArea(id: UUID, isEnabled: Bool) async throws {
        try await simulateNetworkDelay()

        if let index = mockFocusAreas.firstIndex(where: { $0.id == id }) {
            mockFocusAreas[index].isEnabled = isEnabled
        }
    }

    /// Get savings goal
    func getSavingsGoal() async throws -> SavingsGoal {
        try await simulateNetworkDelay()
        return mockSavingsGoal
    }

    /// Update savings goal
    func updateSavingsGoal(targetAmount: Double) async throws {
        try await simulateNetworkDelay()
        mockSavingsGoal.targetAmount = targetAmount
    }

    // MARK: - Data Connections Methods

    /// Get data connections
    func getDataConnections() async throws -> DataConnection {
        try await simulateNetworkDelay()
        return mockDataConnection
    }

    /// Add bank connection (Plaid)
    func addBankConnection(institutionName: String) async throws {
        try await simulateNetworkDelay(duration: 2.0)

        let newConnection = BankConnection(
            id: UUID(),
            institutionName: institutionName,
            lastRefreshed: Date(),
            isActive: true
        )

        mockDataConnection.bankConnections.append(newConnection)
    }

    /// Remove bank connection
    func removeBankConnection(id: UUID) async throws {
        try await simulateNetworkDelay()
        mockDataConnection.bankConnections.removeAll { $0.id == id }
    }

    // MARK: - Marketplace Settings Methods

    /// Get marketplace settings
    func getMarketplaceSettings() async throws -> MarketplaceSettings {
        try await simulateNetworkDelay()
        return mockMarketplaceSettings
    }

    /// Update marketplace settings
    func updateMarketplaceSettings(_ settings: MarketplaceSettings) async throws {
        try await simulateNetworkDelay()
        self.mockMarketplaceSettings = settings
    }

    // MARK: - Notification Preferences Methods

    /// Get notification preferences
    func getNotificationPreferences() async throws -> NotificationPreferences {
        try await simulateNetworkDelay()
        return mockNotificationPrefs
    }

    /// Update notification preferences
    func updateNotificationPreferences(_ prefs: NotificationPreferences) async throws {
        try await simulateNetworkDelay()
        self.mockNotificationPrefs = prefs
    }

    // MARK: - Security & Account Methods

    /// Get security account info
    func getSecurityAccount() async throws -> SecurityAccount {
        try await simulateNetworkDelay()
        return mockSecurityAccount
    }

    /// Update email
    func updateEmail(_ email: String) async throws {
        try await simulateNetworkDelay()
        mockSecurityAccount.email = email
        mockProfile.email = email
        mockProfile.isEmailVerified = false // Requires re-verification
    }

    /// Update phone number
    func updatePhoneNumber(_ phone: String) async throws {
        try await simulateNetworkDelay()
        mockSecurityAccount.phoneNumber = phone
        mockProfile.phoneNumber = phone
        mockProfile.isPhoneVerified = false // Requires re-verification
    }

    /// Enable/disable two-factor authentication
    func updateTwoFactorAuth(enabled: Bool) async throws {
        try await simulateNetworkDelay(duration: 1.5)
        mockSecurityAccount.isTwoFactorEnabled = enabled
    }

    /// Logout from other devices
    func logoutOtherDevices() async throws {
        try await simulateNetworkDelay()
        // Keep only the current device
        if let currentDevice = mockSecurityAccount.loggedInDevices.first {
            mockSecurityAccount.loggedInDevices = [currentDevice]
        }
    }

    // MARK: - Email Verification Methods

    /// Verify email with code
    func verifyEmail(code: String) async throws {
        try await simulateNetworkDelay()

        // Mock verification (accept any 6-digit code)
        guard code.count == 6, code.allSatisfy({ $0.isNumber }) else {
            throw MockError.invalidVerificationCode
        }

        mockProfile.isEmailVerified = true
    }

    /// Verify phone with code
    func verifyPhone(code: String) async throws {
        try await simulateNetworkDelay()

        // Mock verification (accept any 6-digit code)
        guard code.count == 6, code.allSatisfy({ $0.isNumber }) else {
            throw MockError.invalidVerificationCode
        }

        mockProfile.isPhoneVerified = true
    }

    // MARK: - Helper Methods

    /// Simulate network delay
    private func simulateNetworkDelay(duration: Double = 0.8) async throws {
        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }

    /// Reset all data to defaults
    func resetToDefaults() {
        self.mockProfile = .preview
        self.mockCredits = .preview
        self.mockBillHealth = .preview
        self.mockFocusAreas = FocusArea.all
        self.mockSavingsGoal = .preview
        self.mockDataConnection = .preview
        self.mockMarketplaceSettings = .preview
        self.mockNotificationPrefs = .default
        self.mockSecurityAccount = .preview
    }
}

// MARK: - Mock Errors

enum MockError: LocalizedError {
    case invalidVerificationCode
    case networkError
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidVerificationCode:
            return "Invalid verification code. Please enter a 6-digit code."
        case .networkError:
            return "Network error occurred. Please try again."
        case .unauthorized:
            return "Unauthorized. Please login again."
        }
    }
}

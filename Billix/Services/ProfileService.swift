//
//  ProfileService.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation

/// Protocol defining profile service interface
protocol ProfileServiceProtocol {
    // Profile
    func getProfile() async throws -> UserProfile
    func updateProfile(_ profile: UserProfile) async throws
    func uploadAvatar(_ imageData: Data) async throws -> String

    // Credits
    func getCredits() async throws -> BillixCredits
    func addCreditTransaction(type: TransactionType, amount: Int, description: String) async throws
    func updateEarnTask(taskId: UUID, status: TaskStatus, progress: Double) async throws

    // Bill Health
    func getBillHealth() async throws -> BillHealthSnapshot
    func refreshBillHealth() async throws -> BillHealthSnapshot

    // Goals & Focus
    func getFocusAreas() async throws -> [FocusArea]
    func updateFocusArea(id: UUID, isEnabled: Bool) async throws
    func getSavingsGoal() async throws -> SavingsGoal
    func updateSavingsGoal(targetAmount: Double) async throws

    // Data Connections
    func getDataConnections() async throws -> DataConnection
    func addBankConnection(institutionName: String) async throws
    func removeBankConnection(id: UUID) async throws

    // Marketplace Settings
    func getMarketplaceSettings() async throws -> MarketplaceSettings
    func updateMarketplaceSettings(_ settings: MarketplaceSettings) async throws

    // Notification Preferences
    func getNotificationPreferences() async throws -> NotificationPreferences
    func updateNotificationPreferences(_ prefs: NotificationPreferences) async throws

    // Security & Account
    func getSecurityAccount() async throws -> SecurityAccount
    func updateEmail(_ email: String) async throws
    func updatePhoneNumber(_ phone: String) async throws
    func updateTwoFactorAuth(enabled: Bool) async throws
    func logoutOtherDevices() async throws

    // Verification
    func verifyEmail(code: String) async throws
    func verifyPhone(code: String) async throws
}

/// Main profile service implementation using mock data
@MainActor
class ProfileService: ProfileServiceProtocol {

    // MARK: - Singleton
    static let shared = ProfileService()

    // MARK: - Private Properties
    private let mockDataService = MockDataService.shared

    // You can switch this to a real API service later
    private var useMockData = true

    // MARK: - Initialization
    private init() {}

    // MARK: - Profile Methods

    func getProfile() async throws -> UserProfile {
        return try await mockDataService.getProfile()
    }

    func updateProfile(_ profile: UserProfile) async throws {
        try await mockDataService.updateProfile(profile)
    }

    func uploadAvatar(_ imageData: Data) async throws -> String {
        return try await mockDataService.uploadAvatar(imageData)
    }

    // MARK: - Credits Methods

    func getCredits() async throws -> BillixCredits {
        return try await mockDataService.getCredits()
    }

    func addCreditTransaction(type: TransactionType, amount: Int, description: String) async throws {
        try await mockDataService.addCreditTransaction(type: type, amount: amount, description: description)
    }

    func updateEarnTask(taskId: UUID, status: TaskStatus, progress: Double) async throws {
        try await mockDataService.updateEarnTask(taskId: taskId, status: status, progress: progress)
    }

    // MARK: - Bill Health Methods

    func getBillHealth() async throws -> BillHealthSnapshot {
        return try await mockDataService.getBillHealth()
    }

    func refreshBillHealth() async throws -> BillHealthSnapshot {
        return try await mockDataService.refreshBillHealth()
    }

    // MARK: - Goals & Focus Methods

    func getFocusAreas() async throws -> [FocusArea] {
        return try await mockDataService.getFocusAreas()
    }

    func updateFocusArea(id: UUID, isEnabled: Bool) async throws {
        try await mockDataService.updateFocusArea(id: id, isEnabled: isEnabled)
    }

    func getSavingsGoal() async throws -> SavingsGoal {
        return try await mockDataService.getSavingsGoal()
    }

    func updateSavingsGoal(targetAmount: Double) async throws {
        try await mockDataService.updateSavingsGoal(targetAmount: targetAmount)
    }

    // MARK: - Data Connections Methods

    func getDataConnections() async throws -> DataConnection {
        return try await mockDataService.getDataConnections()
    }

    func addBankConnection(institutionName: String) async throws {
        try await mockDataService.addBankConnection(institutionName: institutionName)
    }

    func removeBankConnection(id: UUID) async throws {
        try await mockDataService.removeBankConnection(id: id)
    }

    // MARK: - Marketplace Settings Methods

    func getMarketplaceSettings() async throws -> MarketplaceSettings {
        return try await mockDataService.getMarketplaceSettings()
    }

    func updateMarketplaceSettings(_ settings: MarketplaceSettings) async throws {
        try await mockDataService.updateMarketplaceSettings(settings)
    }

    // MARK: - Notification Preferences Methods

    func getNotificationPreferences() async throws -> NotificationPreferences {
        return try await mockDataService.getNotificationPreferences()
    }

    func updateNotificationPreferences(_ prefs: NotificationPreferences) async throws {
        try await mockDataService.updateNotificationPreferences(prefs)
    }

    // MARK: - Security & Account Methods

    func getSecurityAccount() async throws -> SecurityAccount {
        return try await mockDataService.getSecurityAccount()
    }

    func updateEmail(_ email: String) async throws {
        try await mockDataService.updateEmail(email)
    }

    func updatePhoneNumber(_ phone: String) async throws {
        try await mockDataService.updatePhoneNumber(phone)
    }

    func updateTwoFactorAuth(enabled: Bool) async throws {
        try await mockDataService.updateTwoFactorAuth(enabled: enabled)
    }

    func logoutOtherDevices() async throws {
        try await mockDataService.logoutOtherDevices()
    }

    // MARK: - Verification Methods

    func verifyEmail(code: String) async throws {
        try await mockDataService.verifyEmail(code: code)
    }

    func verifyPhone(code: String) async throws {
        try await mockDataService.verifyPhone(code: code)
    }
}

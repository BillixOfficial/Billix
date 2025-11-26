//
//  ProfileService.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation
import Supabase

/// Protocol defining profile service interface
protocol ProfileServiceProtocol {
    // Profile
    func getProfile() async throws -> UserProfile
    func updateProfile(_ profile: UserProfile) async throws
    func uploadAvatar(_ imageData: Data) async throws -> String

    // Combined User (new)
    func getCombinedUser() async throws -> CombinedUser
    func updateUserProfile(displayName: String?, bio: String?, goal: String?) async throws
    func updateUserVault(zipCode: String?, marketplaceOptOut: Bool?) async throws

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

/// Main profile service implementation with Supabase integration
@MainActor
class ProfileService: ProfileServiceProtocol {

    // MARK: - Singleton
    static let shared = ProfileService()

    // MARK: - Private Properties
    private let mockDataService = MockDataService.shared

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // Toggle for development - set to false for real Supabase queries
    private var useMockData = false

    // MARK: - Initialization
    private init() {}

    // MARK: - Combined User Methods (Real Supabase)

    func getCombinedUser() async throws -> CombinedUser {
        guard let session = try? await supabase.auth.session else {
            throw ProfileError.notAuthenticated
        }

        let userId = session.user.id

        async let vaultResult: UserVault = supabase
            .from("user_vault")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        async let profileResult: UserProfileDB = supabase
            .from("user_profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        let (vault, profile) = try await (vaultResult, profileResult)

        return CombinedUser(id: userId, vault: vault, profile: profile)
    }

    func updateUserProfile(displayName: String? = nil, bio: String? = nil, goal: String? = nil) async throws {
        guard let session = try? await supabase.auth.session else {
            throw ProfileError.notAuthenticated
        }

        var updates: [String: String] = [:]
        if let displayName = displayName { updates["display_name"] = displayName }
        if let bio = bio { updates["bio"] = bio }
        if let goal = goal { updates["goal"] = goal }

        guard !updates.isEmpty else { return }

        try await supabase
            .from("user_profiles")
            .update(updates)
            .eq("id", value: session.user.id.uuidString)
            .execute()
    }

    func updateUserVault(zipCode: String? = nil, marketplaceOptOut: Bool? = nil) async throws {
        guard let session = try? await supabase.auth.session else {
            throw ProfileError.notAuthenticated
        }

        var updates: [String: String] = [:]
        if let zipCode = zipCode { updates["zip_code"] = zipCode }
        if let marketplaceOptOut = marketplaceOptOut { updates["marketplace_opt_out"] = String(marketplaceOptOut) }

        guard !updates.isEmpty else { return }

        try await supabase
            .from("user_vault")
            .update(updates)
            .eq("id", value: session.user.id.uuidString)
            .execute()
    }

    // MARK: - Profile Methods (Legacy - uses mock or converts)

    func getProfile() async throws -> UserProfile {
        if useMockData {
            return try await mockDataService.getProfile()
        }

        // Convert from CombinedUser to legacy UserProfile
        let combined = try await getCombinedUser()
        return convertToLegacyProfile(combined)
    }

    func updateProfile(_ profile: UserProfile) async throws {
        if useMockData {
            try await mockDataService.updateProfile(profile)
            return
        }

        // Update using new methods
        try await updateUserProfile(
            displayName: profile.displayName ?? profile.fullName,
            bio: nil,
            goal: nil
        )
    }

    func uploadAvatar(_ imageData: Data) async throws -> String {
        if useMockData {
            return try await mockDataService.uploadAvatar(imageData)
        }

        guard let session = try? await supabase.auth.session else {
            throw ProfileError.notAuthenticated
        }

        let userId = session.user.id
        let path = "\(userId.uuidString)/avatar.jpg"

        try await supabase.storage
            .from("avatars")
            .upload(
                path,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        let publicURL = try supabase.storage
            .from("avatars")
            .getPublicURL(path: path)

        // Update profile with new avatar URL
        try await supabase
            .from("user_profiles")
            .update(["avatar_url": publicURL.absoluteString])
            .eq("id", value: userId.uuidString)
            .execute()

        return publicURL.absoluteString
    }

    // MARK: - Helper Methods

    private func convertToLegacyProfile(_ combined: CombinedUser) -> UserProfile {
        let nameParts = (combined.profile.displayName ?? "User").split(separator: " ")
        let firstName = nameParts.first.map(String.init) ?? "User"
        let lastName = nameParts.dropFirst().joined(separator: " ")

        return UserProfile(
            id: combined.id,
            firstName: firstName,
            lastName: lastName.isEmpty ? "" : lastName,
            displayName: combined.profile.displayName,
            email: "", // Not stored in profile
            phoneNumber: nil,
            zipCode: combined.vault.zipCode,
            city: "", // Could be derived from ZIP
            state: combined.vault.state ?? "",
            isEmailVerified: true, // Assumed if authenticated
            isPhoneVerified: false,
            createdAt: combined.vault.createdAt,
            totalBillsUploaded: combined.profile.billsAnalyzedCount,
            badges: convertBadges(combined.profile.badges),
            avatarURL: combined.profile.avatarUrl
        )
    }

    private func convertBadges(_ badges: [String]) -> [UserBadge] {
        return badges.compactMap { badgeString in
            switch badgeString.lowercased() {
            case "pioneer", "billix pioneer": return .pioneer
            case "early_user", "early user": return .earlyUser
            case "power_user", "power user": return .powerUser
            case "savings_expert", "savings expert": return .savingsExpert
            default: return nil
            }
        }
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
        if !useMockData {
            // Also update vault
            try await updateUserVault(marketplaceOptOut: !settings.isMarketplaceEnabled)
        }
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

// MARK: - Profile Errors

enum ProfileError: LocalizedError {
    case notAuthenticated
    case profileNotFound
    case updateFailed(String)
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to access profile data"
        case .profileNotFound:
            return "Profile not found"
        case .updateFailed(let message):
            return "Failed to update profile: \(message)"
        case .uploadFailed(let message):
            return "Failed to upload: \(message)"
        }
    }
}

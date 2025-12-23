//
//  UnlockCreditsService.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Service for managing unlock credits - earned through actions, spent on features
//

import Foundation
import Supabase

// MARK: - Unlock Credit Transaction Types

enum UnlockCreditType: String, Codable, CaseIterable {
    case receiptUpload = "receipt_upload"
    case referral = "referral"
    case dailyLogin = "daily_login"
    case swapCompletion = "swap_completion"
    case featureUnlock = "feature_unlock"
    case promotion = "promotion"
    case refund = "refund"

    var displayName: String {
        switch self {
        case .receiptUpload: return "Receipt Upload"
        case .referral: return "Referral Bonus"
        case .dailyLogin: return "Daily Login"
        case .swapCompletion: return "Swap Completion"
        case .featureUnlock: return "Feature Unlock"
        case .promotion: return "Promotion"
        case .refund: return "Refund"
        }
    }

    var isEarning: Bool {
        switch self {
        case .receiptUpload, .referral, .dailyLogin, .swapCompletion, .promotion, .refund:
            return true
        case .featureUnlock:
            return false
        }
    }
}

// MARK: - Unlock Credit Transaction

struct UnlockCreditTransaction: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let amount: Int
    let transactionType: String
    let description: String?
    let referenceId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case transactionType = "transaction_type"
        case description
        case referenceId = "reference_id"
        case createdAt = "created_at"
    }

    var type: UnlockCreditType? {
        UnlockCreditType(rawValue: transactionType)
    }

    var isPositive: Bool {
        amount > 0
    }

    var formattedAmount: String {
        amount >= 0 ? "+\(amount)" : "\(amount)"
    }
}

// MARK: - Unlock Credits

struct UnlockCredits: Codable {
    let id: UUID
    let userId: UUID
    var balance: Int
    var lifetimeEarned: Int
    var lifetimeSpent: Int
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case balance
        case lifetimeEarned = "lifetime_earned"
        case lifetimeSpent = "lifetime_spent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Credit Errors

enum CreditError: LocalizedError {
    case insufficientBalance
    case notAuthenticated
    case updateFailed
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .insufficientBalance:
            return "Not enough credits"
        case .notAuthenticated:
            return "Please sign in to continue"
        case .updateFailed:
            return "Failed to update credits"
        case .invalidAmount:
            return "Invalid credit amount"
        }
    }
}

// MARK: - Insert Structs

private struct UnlockCreditsInsert: Codable {
    let userId: String
    let balance: Int
    let lifetimeEarned: Int
    let lifetimeSpent: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case balance
        case lifetimeEarned = "lifetime_earned"
        case lifetimeSpent = "lifetime_spent"
    }
}

private struct CreditTransactionInsert: Codable {
    let userId: String
    let amount: Int
    let transactionType: String
    let description: String?
    let referenceId: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case amount
        case transactionType = "transaction_type"
        case description
        case referenceId = "reference_id"
    }
}

private struct UnlockCreditsUpdate: Codable {
    let balance: Int
    let lifetimeEarned: Int?
    let lifetimeSpent: Int?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case balance
        case lifetimeEarned = "lifetime_earned"
        case lifetimeSpent = "lifetime_spent"
        case updatedAt = "updated_at"
    }
}

// MARK: - Unlock Credits Service

@MainActor
class UnlockCreditsService: ObservableObject {

    // MARK: - Singleton
    static let shared = UnlockCreditsService()

    // MARK: - Published Properties
    @Published var balance: Int = 0
    @Published var lifetimeEarned: Int = 0
    @Published var lifetimeSpent: Int = 0
    @Published var recentTransactions: [UnlockCreditTransaction] = []
    @Published var isLoading = false

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // MARK: - Initialization

    private init() {
        Task {
            await loadCredits()
        }
    }

    // MARK: - Load Credits

    /// Loads current credit balance from Supabase
    func loadCredits() async {
        guard let session = try? await supabase.auth.session else {
            balance = 0
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch or create credits record
            let credits: [UnlockCredits] = try await supabase
                .from("unlock_credits")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
                .value

            if let credit = credits.first {
                balance = credit.balance
                lifetimeEarned = credit.lifetimeEarned
                lifetimeSpent = credit.lifetimeSpent
            } else {
                // Create initial credits record
                let insert = UnlockCreditsInsert(
                    userId: session.user.id.uuidString,
                    balance: 0,
                    lifetimeEarned: 0,
                    lifetimeSpent: 0
                )

                try await supabase
                    .from("unlock_credits")
                    .insert(insert)
                    .execute()

                balance = 0
                lifetimeEarned = 0
                lifetimeSpent = 0
            }

            // Load recent transactions
            await loadRecentTransactions()

        } catch {
            print("Failed to load credits: \(error)")
        }
    }

    /// Loads recent credit transactions
    func loadRecentTransactions(limit: Int = 20) async {
        guard let session = try? await supabase.auth.session else { return }

        do {
            let transactions: [UnlockCreditTransaction] = try await supabase
                .from("credit_transactions")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            recentTransactions = transactions
        } catch {
            print("Failed to load transactions: \(error)")
        }
    }

    // MARK: - Earn Credits

    /// Awards credits to the user
    func earnCredits(_ amount: Int, type: UnlockCreditType, description: String? = nil, referenceId: UUID? = nil) async throws {
        guard amount > 0 else { throw CreditError.invalidAmount }
        guard let session = try? await supabase.auth.session else {
            throw CreditError.notAuthenticated
        }

        do {
            // Update balance
            let newBalance = balance + amount
            let newLifetimeEarned = lifetimeEarned + amount

            let update = UnlockCreditsUpdate(
                balance: newBalance,
                lifetimeEarned: newLifetimeEarned,
                lifetimeSpent: nil,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            try await supabase
                .from("unlock_credits")
                .update(update)
                .eq("user_id", value: session.user.id.uuidString)
                .execute()

            // Record transaction
            let transaction = CreditTransactionInsert(
                userId: session.user.id.uuidString,
                amount: amount,
                transactionType: type.rawValue,
                description: description ?? type.displayName,
                referenceId: referenceId?.uuidString
            )

            try await supabase
                .from("credit_transactions")
                .insert(transaction)
                .execute()

            // Update local state
            balance = newBalance
            lifetimeEarned = newLifetimeEarned

            // Reload transactions
            await loadRecentTransactions()

        } catch {
            throw CreditError.updateFailed
        }
    }

    // MARK: - Spend Credits

    /// Spends credits on a feature
    func spendCredits(_ amount: Int, for feature: PremiumFeature) async throws {
        guard amount > 0 else { throw CreditError.invalidAmount }
        guard balance >= amount else { throw CreditError.insufficientBalance }
        guard let session = try? await supabase.auth.session else {
            throw CreditError.notAuthenticated
        }

        do {
            // Update balance
            let newBalance = balance - amount
            let newLifetimeSpent = lifetimeSpent + amount

            let update = UnlockCreditsUpdate(
                balance: newBalance,
                lifetimeEarned: nil,
                lifetimeSpent: newLifetimeSpent,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            try await supabase
                .from("unlock_credits")
                .update(update)
                .eq("user_id", value: session.user.id.uuidString)
                .execute()

            // Record transaction
            let transaction = CreditTransactionInsert(
                userId: session.user.id.uuidString,
                amount: -amount,
                transactionType: UnlockCreditType.featureUnlock.rawValue,
                description: "Unlocked \(feature.displayName)",
                referenceId: nil
            )

            try await supabase
                .from("credit_transactions")
                .insert(transaction)
                .execute()

            // Update local state
            balance = newBalance
            lifetimeSpent = newLifetimeSpent

            // Reload transactions
            await loadRecentTransactions()

        } catch let error as CreditError {
            throw error
        } catch {
            throw CreditError.updateFailed
        }
    }

    // MARK: - Credit Rewards

    /// Credits earned for uploading a bill receipt
    static let receiptUploadCredits = 10

    /// Credits earned for completing a swap
    static let swapCompletionCredits = 25

    /// Credits earned for daily login
    static let dailyLoginCredits = 5

    /// Credits earned for referring a new user
    static let referralCredits = 100

    // MARK: - Helper Methods

    /// Checks if user can afford a credit cost
    func canAfford(_ amount: Int) -> Bool {
        balance >= amount
    }

    /// Formats credit balance for display
    var formattedBalance: String {
        "\(balance) credits"
    }

    // MARK: - Reset

    func reset() {
        balance = 0
        lifetimeEarned = 0
        lifetimeSpent = 0
        recentTransactions = []
    }
}

// MARK: - Preview Helpers

extension UnlockCreditsService {
    static func mockWithBalance(_ creditBalance: Int) -> UnlockCreditsService {
        let service = UnlockCreditsService.shared
        service.balance = creditBalance
        return service
    }
}

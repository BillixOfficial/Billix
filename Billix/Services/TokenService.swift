//
//  TokenService.swift
//  Billix
//
//  Service for managing Connect Tokens - the in-app currency for unlocking chat connections
//

import Foundation
import StoreKit
import Supabase

// MARK: - Token Constants

enum TokenConstants {
    static let freeTokensPerMonth = 2
    static let tokenPackAmount = 3
    static let tokenPackProductID = "com.billix.token_pack_3"
}

// MARK: - Token Service

@MainActor
class TokenService: ObservableObject {
    static let shared = TokenService()

    // MARK: - Published Properties

    @Published var tokenBalance: Int = 0
    @Published var freeTokensRemaining: Int = TokenConstants.freeTokensPerMonth
    @Published var freeTokensResetDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentUserId: UUID? {
        AuthService.shared.currentUser?.id
    }

    private var storeKitService: StoreKitService {
        StoreKitService.shared
    }

    private init() {}

    // MARK: - Computed Properties

    /// Total available tokens (purchased + free remaining)
    var totalAvailableTokens: Int {
        tokenBalance + freeTokensRemaining
    }

    /// Whether user has any tokens available
    var hasTokens: Bool {
        totalAvailableTokens > 0
    }

    /// Whether user has unlimited tokens (Prime subscriber)
    var hasUnlimitedTokens: Bool {
        storeKitService.isPrime
    }

    // MARK: - Load Balance

    /// Load token balance from Supabase (alias for loadBalance)
    func loadTokenBalance() async {
        await loadBalance()
    }

    /// Load token balance from Supabase
    func loadBalance() async {
        guard let userId = currentUserId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // First, ensure monthly free tokens are reset if needed
            try await resetMonthlyFreeTokensIfNeeded()

            // Try to get existing record
            let records: [ConnectTokenRecord] = try await supabase
                .from("connect_tokens")
                .select()
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if let record = records.first {
                tokenBalance = record.balance
                freeTokensRemaining = TokenConstants.freeTokensPerMonth - record.freeTokensUsed

                // Calculate next reset date (first of next month)
                if let resetDate = record.freeTokensResetDate {
                    let calendar = Calendar.current
                    if let nextMonth = calendar.date(byAdding: .month, value: 1, to: resetDate) {
                        let components = calendar.dateComponents([.year, .month], from: nextMonth)
                        freeTokensResetDate = calendar.date(from: components) ?? nextMonth
                    }
                }
            } else {
                // Create new record for user
                try await createTokenRecord(for: userId)
                tokenBalance = 0
                freeTokensRemaining = TokenConstants.freeTokensPerMonth
            }
        } catch {
            self.error = error
            print("Failed to load token balance: \(error)")
        }
    }

    /// Create initial token record for new user
    private func createTokenRecord(for userId: UUID) async throws {
        let newRecord = ConnectTokenInsert(userId: userId)

        try await supabase
            .from("connect_tokens")
            .insert(newRecord)
            .execute()
    }

    // MARK: - Use Token

    /// Use a token to unlock a chat connection
    /// Returns true if successful, false if no tokens available
    func useToken(for swapId: UUID) async throws -> Bool {
        guard let userId = currentUserId else {
            throw TokenError.notAuthenticated
        }

        // Prime users don't need to use tokens
        if hasUnlimitedTokens {
            // Log the "use" but don't deduct
            try await logTransaction(
                userId: userId,
                amount: 0,
                type: .use,
                referenceId: swapId,
                note: "Prime user - unlimited tokens"
            )
            return true
        }

        // Try to use a free token first
        if freeTokensRemaining > 0 {
            try await useFreeToken(for: swapId)
            return true
        }

        // Use purchased token
        if tokenBalance > 0 {
            try await usePurchasedToken(for: swapId)
            return true
        }

        // No tokens available
        return false
    }

    /// Use one of the free monthly tokens
    private func useFreeToken(for swapId: UUID) async throws {
        guard let userId = currentUserId else {
            throw TokenError.notAuthenticated
        }

        // Get current record
        let records: [ConnectTokenRecord] = try await supabase
            .from("connect_tokens")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let record = records.first else {
            throw TokenError.recordNotFound
        }

        let newFreeUsed = record.freeTokensUsed + 1

        // Update free tokens used
        try await supabase
            .from("connect_tokens")
            .update(FreeTokensUpdate(
                freeTokensUsed: newFreeUsed,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            ))
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Log transaction
        try await logTransaction(
            userId: userId,
            amount: -1,
            type: .use,
            referenceId: swapId,
            note: "Free monthly token"
        )

        freeTokensRemaining = TokenConstants.freeTokensPerMonth - newFreeUsed
    }

    /// Use a purchased token
    private func usePurchasedToken(for swapId: UUID) async throws {
        guard let userId = currentUserId else {
            throw TokenError.notAuthenticated
        }

        // Get current balance
        let records: [ConnectTokenRecord] = try await supabase
            .from("connect_tokens")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let record = records.first, record.balance > 0 else {
            throw TokenError.insufficientBalance
        }

        let newBalance = record.balance - 1

        // Update balance
        try await supabase
            .from("connect_tokens")
            .update(BalanceUpdate(
                balance: newBalance,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            ))
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Log transaction
        try await logTransaction(
            userId: userId,
            amount: -1,
            type: .use,
            referenceId: swapId
        )

        tokenBalance = newBalance
    }

    // MARK: - Refund Token

    /// Refund a token (e.g., when chat has < 5 messages)
    func refundToken(for swapId: UUID) async throws {
        guard let userId = currentUserId else {
            throw TokenError.notAuthenticated
        }

        // Prime users didn't use a token, nothing to refund
        if hasUnlimitedTokens {
            return
        }

        // Get current balance
        let records: [ConnectTokenRecord] = try await supabase
            .from("connect_tokens")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let record = records.first else {
            throw TokenError.recordNotFound
        }

        // Add token back to balance (always add to purchased balance for simplicity)
        let newBalance = record.balance + 1

        try await supabase
            .from("connect_tokens")
            .update(BalanceUpdate(
                balance: newBalance,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            ))
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Log refund transaction
        try await logTransaction(
            userId: userId,
            amount: 1,
            type: .refund,
            referenceId: swapId
        )

        tokenBalance = newBalance

        // Mark swap as refunded
        try await supabase
            .from("swaps")
            .update(["token_refunded": true])
            .eq("id", value: swapId.uuidString)
            .execute()
    }

    // MARK: - Purchase Tokens

    /// Purchase a token pack via StoreKit
    func purchaseTokenPack() async throws -> Bool {
        guard let userId = currentUserId else {
            throw TokenError.notAuthenticated
        }

        // Find the token pack product
        guard let product = storeKitService.products.first(where: { $0.id == TokenConstants.tokenPackProductID }) else {
            // Fallback to handshake fee product during transition
            guard let fallbackProduct = storeKitService.handshakeFeeProduct else {
                throw TokenError.productNotFound
            }

            return try await purchaseWithProduct(fallbackProduct, userId: userId)
        }

        return try await purchaseWithProduct(product, userId: userId)
    }

    private func purchaseWithProduct(_ product: Product, userId: UUID) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                guard case .verified(let transaction) = verification else {
                    throw TokenError.verificationFailed
                }

                // Add tokens to balance
                try await addTokens(amount: TokenConstants.tokenPackAmount, for: userId)

                // Finish the transaction
                await transaction.finish()

                return true

            case .userCancelled:
                return false

            case .pending:
                return false

            @unknown default:
                return false
            }
        } catch {
            self.error = error
            throw error
        }
    }

    /// Add purchased tokens to balance
    private func addTokens(amount: Int, for userId: UUID) async throws {
        // Get current balance
        let records: [ConnectTokenRecord] = try await supabase
            .from("connect_tokens")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        let currentBalance = records.first?.balance ?? 0
        let newBalance = currentBalance + amount

        if records.isEmpty {
            // Create new record
            try await createTokenRecord(for: userId)
            try await supabase
                .from("connect_tokens")
                .update(BalanceOnlyUpdate(balance: amount))
                .eq("user_id", value: userId.uuidString)
                .execute()
        } else {
            // Update existing
            try await supabase
                .from("connect_tokens")
                .update(BalanceUpdate(
                    balance: newBalance,
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                ))
                .eq("user_id", value: userId.uuidString)
                .execute()
        }

        // Log transaction
        try await logTransaction(
            userId: userId,
            amount: amount,
            type: .purchase
        )

        tokenBalance = newBalance
    }

    // MARK: - Monthly Reset

    /// Reset free tokens if we're in a new month
    private func resetMonthlyFreeTokensIfNeeded() async throws {
        guard let userId = currentUserId else { return }

        let records: [ConnectTokenRecord] = try await supabase
            .from("connect_tokens")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let record = records.first else { return }

        let calendar = Calendar.current
        let now = Date()

        var needsReset = false

        if let lastReset = record.freeTokensResetDate {
            let lastMonth = calendar.component(.month, from: lastReset)
            let lastYear = calendar.component(.year, from: lastReset)
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)

            needsReset = (lastMonth != currentMonth || lastYear != currentYear)
        } else {
            needsReset = true
        }

        if needsReset {
            let nowString = ISO8601DateFormatter().string(from: now)
            try await supabase
                .from("connect_tokens")
                .update(MonthlyResetUpdate(
                    freeTokensUsed: 0,
                    freeTokensResetDate: nowString,
                    updatedAt: nowString
                ))
                .eq("user_id", value: userId.uuidString)
                .execute()

            // Log the free tokens grant
            try await logTransaction(
                userId: userId,
                amount: TokenConstants.freeTokensPerMonth,
                type: .freeMonthly,
                note: "Monthly free tokens reset"
            )

            freeTokensRemaining = TokenConstants.freeTokensPerMonth
        }
    }

    // MARK: - Transaction Logging

    private func logTransaction(
        userId: UUID,
        amount: Int,
        type: TokenTransactionType,
        referenceId: UUID? = nil,
        note: String? = nil
    ) async throws {
        let transaction = TokenTransactionInsert(
            userId: userId,
            amount: amount,
            type: type.rawValue,
            referenceId: referenceId
        )

        try await supabase
            .from("token_transactions")
            .insert(transaction)
            .execute()
    }
}

// MARK: - Supporting Types

private struct ConnectTokenRecord: Decodable {
    let id: UUID
    let userId: UUID
    let balance: Int
    let freeTokensUsed: Int
    let freeTokensResetDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case balance
        case freeTokensUsed = "free_tokens_used"
        case freeTokensResetDate = "free_tokens_reset_date"
    }
}

private struct ConnectTokenInsert: Encodable {
    let userId: UUID
    let balance: Int = 0
    let freeTokensUsed: Int = 0

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case balance
        case freeTokensUsed = "free_tokens_used"
    }
}

private struct FreeTokensUpdate: Encodable {
    let freeTokensUsed: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case freeTokensUsed = "free_tokens_used"
        case updatedAt = "updated_at"
    }
}

private struct BalanceUpdate: Encodable {
    let balance: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case balance
        case updatedAt = "updated_at"
    }
}

private struct BalanceOnlyUpdate: Encodable {
    let balance: Int
}

private struct MonthlyResetUpdate: Encodable {
    let freeTokensUsed: Int
    let freeTokensResetDate: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case freeTokensUsed = "free_tokens_used"
        case freeTokensResetDate = "free_tokens_reset_date"
        case updatedAt = "updated_at"
    }
}

private struct TokenTransactionInsert: Encodable {
    let userId: UUID
    let amount: Int
    let type: String
    let referenceId: UUID?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case amount
        case type
        case referenceId = "reference_id"
    }
}

enum TokenTransactionType: String {
    case purchase = "purchase"
    case freeMonthly = "free_monthly"
    case use = "use"
    case refund = "refund"
}

// MARK: - Errors

enum TokenError: LocalizedError {
    case notAuthenticated
    case recordNotFound
    case insufficientBalance
    case productNotFound
    case verificationFailed
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to manage tokens"
        case .recordNotFound:
            return "Token record not found"
        case .insufficientBalance:
            return "Not enough tokens. Purchase more to continue."
        case .productNotFound:
            return "Token pack not found in store"
        case .verificationFailed:
            return "Purchase verification failed"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        }
    }
}

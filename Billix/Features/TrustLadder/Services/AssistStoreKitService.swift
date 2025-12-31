//
//  AssistStoreKitService.swift
//  Billix
//
//  Created by Claude Code on 12/31/24.
//  Service for handling tiered assist connection fee payments via StoreKit 2
//

import Foundation
import StoreKit
import Supabase

// MARK: - Codable Structs for Supabase

private struct AssistFeeTransactionInsert: Codable {
    let assistRequestId: String
    let userId: String
    let userRole: String  // "requester" or "helper"
    let feeTier: String
    let appleTransactionId: String
    let amount: Double
    let currency: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case assistRequestId = "assist_request_id"
        case userId = "user_id"
        case userRole = "user_role"
        case feeTier = "fee_tier"
        case appleTransactionId = "apple_transaction_id"
        case amount
        case currency
        case status
    }
}

private struct AssistFeeTransactionRecord: Codable {
    let id: UUID
    let assistRequestId: UUID
    let userId: UUID
    let userRole: String
    let feeTier: String
    let appleTransactionId: String
    let amount: Double
    let currency: String
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case assistRequestId = "assist_request_id"
        case userId = "user_id"
        case userRole = "user_role"
        case feeTier = "fee_tier"
        case appleTransactionId = "apple_transaction_id"
        case amount
        case currency
        case status
        case createdAt = "created_at"
    }
}

private struct RequesterFeePaidUpdate: Codable {
    let requesterFeePaid: Bool
    let requesterFeeTransactionId: String

    enum CodingKeys: String, CodingKey {
        case requesterFeePaid = "requester_fee_paid"
        case requesterFeeTransactionId = "requester_fee_transaction_id"
    }
}

private struct HelperFeePaidUpdate: Codable {
    let helperFeePaid: Bool
    let helperFeeTransactionId: String

    enum CodingKeys: String, CodingKey {
        case helperFeePaid = "helper_fee_paid"
        case helperFeeTransactionId = "helper_fee_transaction_id"
    }
}

// MARK: - Assist Purchase Status

enum AssistPurchaseStatus: Equatable {
    case idle
    case purchasing
    case success(transactionId: String)
    case failed(Error)
    case cancelled

    static func == (lhs: AssistPurchaseStatus, rhs: AssistPurchaseStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.purchasing, .purchasing), (.cancelled, .cancelled):
            return true
        case let (.success(lhsId), .success(rhsId)):
            return lhsId == rhsId
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// MARK: - Assist Purchase Errors

enum AssistPurchaseError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case verificationFailed
    case userCancelled
    case notAuthenticated
    case recordingFailed
    case invalidTier

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not available. Please try again later."
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .verificationFailed:
            return "Unable to verify purchase. Please contact support."
        case .userCancelled:
            return "Purchase was cancelled"
        case .notAuthenticated:
            return "Please sign in to continue"
        case .recordingFailed:
            return "Failed to record payment. Please contact support."
        case .invalidTier:
            return "Invalid fee tier"
        }
    }
}

// MARK: - User Role in Assist

enum AssistUserRole: String {
    case requester = "requester"
    case helper = "helper"
}

// MARK: - Assist StoreKit Service

@MainActor
class AssistStoreKitService: ObservableObject {

    // MARK: - Singleton
    static let shared = AssistStoreKitService()

    // MARK: - Published Properties
    @Published var products: [AssistConnectionFeeTier: Product] = [:]
    @Published var purchaseStatus: AssistPurchaseStatus = .idle
    @Published var isLoading = false

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load products
        Task {
            await loadProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    /// Loads available products from the App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIds = AssistConnectionFeeTier.allCases.map { $0.productId }
            let storeProducts = try await Product.products(for: productIds)

            for product in storeProducts {
                for tier in AssistConnectionFeeTier.allCases {
                    if product.id == tier.productId {
                        products[tier] = product
                    }
                }
            }
        } catch {
            print("Failed to load assist fee products: \(error)")
        }
    }

    // MARK: - Get Product for Tier

    /// Returns the StoreKit product for a given tier
    func product(for tier: AssistConnectionFeeTier) -> Product? {
        return products[tier]
    }

    /// Returns the StoreKit product for an amount
    func product(for amount: Double) -> Product? {
        let tier = AssistConnectionFeeTier.tier(for: amount)
        return products[tier]
    }

    // MARK: - Purchase Connection Fee

    /// Purchases the connection fee for an assist request
    func purchaseConnectionFee(
        for assistRequestId: UUID,
        tier: AssistConnectionFeeTier,
        role: AssistUserRole
    ) async throws -> String {
        guard let product = products[tier] else {
            // Try loading products first
            await loadProducts()

            guard let product = products[tier] else {
                throw AssistPurchaseError.productNotFound
            }

            return try await performPurchase(
                product: product,
                assistRequestId: assistRequestId,
                tier: tier,
                role: role
            )
        }

        return try await performPurchase(
            product: product,
            assistRequestId: assistRequestId,
            tier: tier,
            role: role
        )
    }

    /// Convenience method that determines tier from amount
    func purchaseConnectionFee(
        for assistRequestId: UUID,
        amount: Double,
        role: AssistUserRole
    ) async throws -> String {
        let tier = AssistConnectionFeeTier.tier(for: amount)
        return try await purchaseConnectionFee(for: assistRequestId, tier: tier, role: role)
    }

    /// Performs the actual purchase
    private func performPurchase(
        product: Product,
        assistRequestId: UUID,
        tier: AssistConnectionFeeTier,
        role: AssistUserRole
    ) async throws -> String {
        purchaseStatus = .purchasing

        do {
            // Include assist request ID in app account token for tracking
            let purchaseOption = Product.PurchaseOption.appAccountToken(
                UUID(uuidString: assistRequestId.uuidString) ?? UUID()
            )

            let result = try await product.purchase(options: [purchaseOption])

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Record the transaction in our database
                let transactionId = String(transaction.id)
                try await recordTransaction(
                    transactionId: transactionId,
                    assistRequestId: assistRequestId,
                    tier: tier,
                    role: role,
                    amount: product.price,
                    currency: product.priceFormatStyle.currencyCode
                )

                // Update the assist request to mark fee as paid
                try await updateAssistRequestFeePaid(
                    assistRequestId: assistRequestId,
                    role: role,
                    transactionId: transactionId
                )

                // Finish the transaction
                await transaction.finish()

                purchaseStatus = .success(transactionId: transactionId)
                return transactionId

            case .userCancelled:
                purchaseStatus = .cancelled
                throw AssistPurchaseError.userCancelled

            case .pending:
                // Transaction pending (e.g., parental approval)
                purchaseStatus = .idle
                throw AssistPurchaseError.purchaseFailed

            @unknown default:
                purchaseStatus = .failed(AssistPurchaseError.purchaseFailed)
                throw AssistPurchaseError.purchaseFailed
            }
        } catch let error as AssistPurchaseError {
            purchaseStatus = .failed(error)
            throw error
        } catch {
            purchaseStatus = .failed(error)
            throw AssistPurchaseError.purchaseFailed
        }
    }

    // MARK: - Transaction Verification

    /// Verifies a StoreKit transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw AssistPurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Transaction Listener

    /// Listens for transaction updates (handles interrupted purchases, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    // Handle the transaction
                    await self.handleTransaction(transaction)

                    await transaction.finish()
                } catch {
                    print("Assist transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Handles a verified transaction
    private func handleTransaction(_ transaction: Transaction) async {
        // Check if this is an assist fee purchase
        let isAssistFee = AssistConnectionFeeTier.allCases.contains { $0.productId == transaction.productID }
        guard isAssistFee else { return }

        // If there's an app account token, it contains the assist request ID
        if let tokenData = transaction.appAccountToken,
           let assistRequestId = UUID(uuidString: tokenData.uuidString) {
            // Record the transaction if not already recorded
            try? await recordTransactionIfNeeded(
                transactionId: String(transaction.id),
                assistRequestId: assistRequestId,
                productId: transaction.productID
            )
        }
    }

    // MARK: - Database Recording

    /// Records the assist fee transaction in Supabase
    private func recordTransaction(
        transactionId: String,
        assistRequestId: UUID,
        tier: AssistConnectionFeeTier,
        role: AssistUserRole,
        amount: Decimal,
        currency: String
    ) async throws {
        guard let session = try? await supabase.auth.session else {
            throw AssistPurchaseError.notAuthenticated
        }

        let transactionData = AssistFeeTransactionInsert(
            assistRequestId: assistRequestId.uuidString,
            userId: session.user.id.uuidString,
            userRole: role.rawValue,
            feeTier: tier.rawValue,
            appleTransactionId: transactionId,
            amount: NSDecimalNumber(decimal: amount).doubleValue,
            currency: currency,
            status: "completed"
        )

        do {
            try await supabase
                .from("assist_fee_transactions")
                .insert(transactionData)
                .execute()
        } catch {
            throw AssistPurchaseError.recordingFailed
        }
    }

    /// Updates the assist request to mark fee as paid
    private func updateAssistRequestFeePaid(
        assistRequestId: UUID,
        role: AssistUserRole,
        transactionId: String
    ) async throws {
        if role == .requester {
            try await supabase
                .from("assist_requests")
                .update(RequesterFeePaidUpdate(requesterFeePaid: true, requesterFeeTransactionId: transactionId))
                .eq("id", value: assistRequestId.uuidString)
                .execute()
        } else {
            try await supabase
                .from("assist_requests")
                .update(HelperFeePaidUpdate(helperFeePaid: true, helperFeeTransactionId: transactionId))
                .eq("id", value: assistRequestId.uuidString)
                .execute()
        }
    }

    /// Records a transaction if it hasn't been recorded yet
    private func recordTransactionIfNeeded(
        transactionId: String,
        assistRequestId: UUID,
        productId: String
    ) async throws {
        guard let session = try? await supabase.auth.session else {
            return
        }

        // Check if already recorded
        let existing: [AssistFeeTransactionRecord] = try await supabase
            .from("assist_fee_transactions")
            .select()
            .eq("apple_transaction_id", value: transactionId)
            .execute()
            .value

        if existing.isEmpty {
            // Determine tier from product ID
            guard let tier = AssistConnectionFeeTier.allCases.first(where: { $0.productId == productId }) else {
                return
            }

            // We don't know the role here, default to requester
            let transactionData = AssistFeeTransactionInsert(
                assistRequestId: assistRequestId.uuidString,
                userId: session.user.id.uuidString,
                userRole: "requester",
                feeTier: tier.rawValue,
                appleTransactionId: transactionId,
                amount: tier.fee,
                currency: "USD",
                status: "completed"
            )

            try await supabase
                .from("assist_fee_transactions")
                .insert(transactionData)
                .execute()
        }
    }

    // MARK: - Check Purchase Status

    /// Checks if the user has paid the connection fee for an assist request
    func hasUserPaidFee(for assistRequestId: UUID, role: AssistUserRole) async throws -> Bool {
        guard let session = try? await supabase.auth.session else {
            throw AssistPurchaseError.notAuthenticated
        }

        let transactions: [AssistFeeTransactionRecord] = try await supabase
            .from("assist_fee_transactions")
            .select()
            .eq("assist_request_id", value: assistRequestId.uuidString)
            .eq("user_id", value: session.user.id.uuidString)
            .eq("user_role", value: role.rawValue)
            .eq("status", value: "completed")
            .execute()
            .value

        return !transactions.isEmpty
    }

    /// Checks if both parties have paid their fees
    func haveBothPartiesPaidFees(for assistRequestId: UUID) async throws -> Bool {
        let transactions: [AssistFeeTransactionRecord] = try await supabase
            .from("assist_fee_transactions")
            .select()
            .eq("assist_request_id", value: assistRequestId.uuidString)
            .eq("status", value: "completed")
            .execute()
            .value

        let requesterPaid = transactions.contains { $0.userRole == "requester" }
        let helperPaid = transactions.contains { $0.userRole == "helper" }

        return requesterPaid && helperPaid
    }

    // MARK: - Restore Purchases

    /// Restores previous purchases
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        // Sync with App Store
        do {
            try await AppStore.sync()
        } catch {
            print("Failed to sync with App Store: \(error)")
        }
    }

    // MARK: - Reset

    func reset() {
        purchaseStatus = .idle
    }
}

// MARK: - Product Formatting Extension

extension AssistConnectionFeeTier {
    /// Get formatted price from loaded product or fallback to tier fee
    @MainActor
    func formattedPrice(from service: AssistStoreKitService) -> String {
        if let product = service.product(for: self) {
            return product.displayPrice
        }
        return formattedFee
    }
}

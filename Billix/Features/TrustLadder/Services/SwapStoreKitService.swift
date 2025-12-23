//
//  SwapStoreKitService.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Service for handling coordination fee payments via StoreKit 2
//

import Foundation
import StoreKit
import Supabase

// MARK: - Codable Structs for Supabase

private struct FeeTransactionInsert: Codable {
    let swapId: String
    let userId: String
    let appleTransactionId: String
    let amount: Double
    let currency: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case userId = "user_id"
        case appleTransactionId = "apple_transaction_id"
        case amount
        case currency
        case status
    }
}

// MARK: - Product IDs

enum SwapProductID: String, CaseIterable {
    case coordinationFee = "com.billix.swap.coordination_fee"

    var displayName: String {
        switch self {
        case .coordinationFee:
            return "Swap Coordination Fee"
        }
    }

    var description: String {
        switch self {
        case .coordinationFee:
            return "One-time fee to secure your swap and unlock escrow protection"
        }
    }
}

// MARK: - Purchase Status

enum PurchaseStatus: Equatable {
    case idle
    case purchasing
    case success(transactionId: String)
    case failed(Error)
    case cancelled

    static func == (lhs: PurchaseStatus, rhs: PurchaseStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.purchasing, .purchasing), (.cancelled, .cancelled):
            return true
        case let (.success(lhsId), .success(rhsId)):
            return lhsId == rhsId
        case (.failed, .failed):
            return true // Don't compare errors
        default:
            return false
        }
    }
}

// MARK: - Purchase Errors

enum PurchaseError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case verificationFailed
    case userCancelled
    case notAuthenticated
    case recordingFailed

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
        }
    }
}

// MARK: - Swap StoreKit Service

@MainActor
class SwapStoreKitService: ObservableObject {

    // MARK: - Singleton
    static let shared = SwapStoreKitService()

    // MARK: - Published Properties
    @Published var coordinationFeeProduct: Product?
    @Published var purchaseStatus: PurchaseStatus = .idle
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
            let productIds = SwapProductID.allCases.map { $0.rawValue }
            let products = try await Product.products(for: productIds)

            for product in products {
                if product.id == SwapProductID.coordinationFee.rawValue {
                    coordinationFeeProduct = product
                }
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase Coordination Fee

    /// Purchases the coordination fee for a swap
    func purchaseCoordinationFee(for swapId: UUID) async throws -> String {
        guard let product = coordinationFeeProduct else {
            // Try loading products first
            await loadProducts()

            guard let product = coordinationFeeProduct else {
                throw PurchaseError.productNotFound
            }

            return try await performPurchase(product: product, swapId: swapId)
        }

        return try await performPurchase(product: product, swapId: swapId)
    }

    /// Performs the actual purchase
    private func performPurchase(product: Product, swapId: UUID) async throws -> String {
        purchaseStatus = .purchasing

        do {
            // Include swap ID in app account token for tracking
            let purchaseOption = Product.PurchaseOption.appAccountToken(
                UUID(uuidString: swapId.uuidString) ?? UUID()
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
                    swapId: swapId,
                    amount: product.price,
                    currency: product.priceFormatStyle.currencyCode
                )

                // Finish the transaction
                await transaction.finish()

                purchaseStatus = .success(transactionId: transactionId)
                return transactionId

            case .userCancelled:
                purchaseStatus = .cancelled
                throw PurchaseError.userCancelled

            case .pending:
                // Transaction pending (e.g., parental approval)
                purchaseStatus = .idle
                throw PurchaseError.purchaseFailed

            @unknown default:
                purchaseStatus = .failed(PurchaseError.purchaseFailed)
                throw PurchaseError.purchaseFailed
            }
        } catch let error as PurchaseError {
            purchaseStatus = .failed(error)
            throw error
        } catch {
            purchaseStatus = .failed(error)
            throw PurchaseError.purchaseFailed
        }
    }

    // MARK: - Transaction Verification

    /// Verifies a StoreKit transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
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
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Handles a verified transaction
    private func handleTransaction(_ transaction: Transaction) async {
        // Check if this is a coordination fee purchase
        guard transaction.productID == SwapProductID.coordinationFee.rawValue else {
            return
        }

        // If there's an app account token, it contains the swap ID
        if let tokenData = transaction.appAccountToken,
           let swapId = UUID(uuidString: tokenData.uuidString) {
            // Record the transaction if not already recorded
            try? await recordTransactionIfNeeded(
                transactionId: String(transaction.id),
                swapId: swapId
            )
        }
    }

    // MARK: - Database Recording

    /// Records the coordination fee transaction in Supabase
    private func recordTransaction(
        transactionId: String,
        swapId: UUID,
        amount: Decimal,
        currency: String
    ) async throws {
        guard let session = try? await supabase.auth.session else {
            throw PurchaseError.notAuthenticated
        }

        let transactionData = FeeTransactionInsert(
            swapId: swapId.uuidString,
            userId: session.user.id.uuidString,
            appleTransactionId: transactionId,
            amount: NSDecimalNumber(decimal: amount).doubleValue,
            currency: currency,
            status: "completed"
        )

        do {
            try await supabase
                .from("coordination_fee_transactions")
                .insert(transactionData)
                .execute()
        } catch {
            throw PurchaseError.recordingFailed
        }
    }

    /// Records a transaction if it hasn't been recorded yet
    private func recordTransactionIfNeeded(
        transactionId: String,
        swapId: UUID
    ) async throws {
        guard let session = try? await supabase.auth.session else {
            return
        }

        // Check if already recorded
        let existing: [CoordinationFeeTransaction] = try await supabase
            .from("coordination_fee_transactions")
            .select()
            .eq("apple_transaction_id", value: transactionId)
            .execute()
            .value

        if existing.isEmpty {
            // Record it
            let transactionData = FeeTransactionInsert(
                swapId: swapId.uuidString,
                userId: session.user.id.uuidString,
                appleTransactionId: transactionId,
                amount: 0.99, // Default fee amount
                currency: "USD",
                status: "completed"
            )

            try await supabase
                .from("coordination_fee_transactions")
                .insert(transactionData)
                .execute()
        }
    }

    // MARK: - Check Purchase Status

    /// Checks if the user has paid the coordination fee for a swap
    func hasUserPaidFee(for swapId: UUID) async throws -> Bool {
        guard let session = try? await supabase.auth.session else {
            throw PurchaseError.notAuthenticated
        }

        let transactions: [CoordinationFeeTransaction] = try await supabase
            .from("coordination_fee_transactions")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .eq("user_id", value: session.user.id.uuidString)
            .eq("status", value: "completed")
            .execute()
            .value

        return !transactions.isEmpty
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

// Note: CoordinationFeeTransaction is defined in TrustLadderModels.swift

// MARK: - Price Formatting Extension

extension Product {
    var formattedPrice: String {
        priceFormatStyle.format(price)
    }
}

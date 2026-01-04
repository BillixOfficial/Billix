//
//  SwapPaymentService.swift
//  Billix
//
//  Bill Swap Payment Service - StoreKit 2 integration for swap fees
//

import Foundation
import StoreKit
import Supabase

// MARK: - Product Identifiers

enum SwapProductIdentifier: String, CaseIterable {
    case twoSidedSwapFee = "com.billix.swap.fee.twosided"
    case oneSidedSwapFee = "com.billix.swap.fee.onesided"

    var displayName: String {
        switch self {
        case .twoSidedSwapFee:
            return "Two-Sided Swap Fee"
        case .oneSidedSwapFee:
            return "One-Sided Assist Fee"
        }
    }

    var amountCents: Int {
        switch self {
        case .twoSidedSwapFee:
            return 99
        case .oneSidedSwapFee:
            return 149
        }
    }
}

// MARK: - Payment Error

enum SwapPaymentError: LocalizedError {
    case notAuthenticated
    case productNotFound
    case purchaseFailed
    case purchaseCancelled
    case verificationFailed
    case alreadyPurchased
    case storeKitNotAvailable

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to make a payment"
        case .productNotFound:
            return "Product not available"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .purchaseCancelled:
            return "Purchase was cancelled"
        case .verificationFailed:
            return "Payment verification failed"
        case .alreadyPurchased:
            return "Fee already paid"
        case .storeKitNotAvailable:
            return "In-app purchases are not available"
        }
    }
}

// MARK: - Private Codable Payloads

private struct RecordPaymentPayload: Codable {
    let swapId: String
    let userId: String
    let transactionId: String
    let productId: String
    let amountCents: Int
    let paymentMethod: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case userId = "user_id"
        case transactionId = "transaction_id"
        case productId = "product_id"
        case amountCents = "amount_cents"
        case paymentMethod = "payment_method"
        case status
    }
}

// MARK: - Swap Payment Service

@MainActor
class SwapPaymentService: ObservableObject {
    static let shared = SwapPaymentService()

    private let supabase = SupabaseService.shared.client
    private let billSwapService = BillSwapService.shared
    private let pointsService = PointsService.shared

    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: SwapPaymentError?
    @Published var purchaseInProgress = false

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    /// Load available products from App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIds = SwapProductIdentifier.allCases.map { $0.rawValue }
            products = try await Product.products(for: Set(productIds))
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    /// Get product for a swap type
    func getProduct(for swapType: BillSwapType) -> Product? {
        let productId = swapType == .twoSided
            ? SwapProductIdentifier.twoSidedSwapFee.rawValue
            : SwapProductIdentifier.oneSidedSwapFee.rawValue

        return products.first { $0.id == productId }
    }

    // MARK: - Purchase Fee

    /// Purchase swap fee
    func purchaseFee(for swap: BillSwap, isInitiator: Bool) async throws {
        guard SupabaseService.shared.currentUserId != nil else {
            throw SwapPaymentError.notAuthenticated
        }

        // Check if already paid
        if isInitiator && swap.feePaidInitiator {
            throw SwapPaymentError.alreadyPurchased
        }
        if !isInitiator && swap.feePaidCounterparty {
            throw SwapPaymentError.alreadyPurchased
        }

        // Get the product
        guard let product = getProduct(for: swap.swapType) else {
            // Try to load products if not loaded
            await loadProducts()
            guard let product = getProduct(for: swap.swapType) else {
                throw SwapPaymentError.productNotFound
            }
            try await purchase(product: product, swapId: swap.id, isInitiator: isInitiator)
            return
        }

        try await purchase(product: product, swapId: swap.id, isInitiator: isInitiator)
    }

    /// Purchase a product
    private func purchase(product: Product, swapId: UUID, isInitiator: Bool) async throws {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            // Add swap metadata to the purchase
            let result = try await product.purchase(options: [
                .appAccountToken(UUID()) // Unique token for this purchase
            ])

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Mark fee as paid in our database
                try await billSwapService.markFeePaid(swapId, forInitiator: isInitiator)

                // Record the payment
                try await recordPayment(
                    swapId: swapId,
                    transactionId: String(transaction.id),
                    productId: product.id,
                    amountCents: NSDecimalNumber(decimal: product.price * 100).intValue
                )

                // Finish the transaction
                await transaction.finish()

            case .userCancelled:
                throw SwapPaymentError.purchaseCancelled

            case .pending:
                // Transaction is pending (e.g., Ask to Buy)
                // Don't throw error, but also don't mark as paid
                break

            @unknown default:
                throw SwapPaymentError.purchaseFailed
            }
        } catch is SwapPaymentError {
            throw error ?? SwapPaymentError.purchaseFailed
        } catch {
            throw SwapPaymentError.purchaseFailed
        }
    }

    /// Verify transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SwapPaymentError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Waive Fee with Points

    /// Waive fee using Billix points
    func waiveFeeWithPoints(for swap: BillSwap, isInitiator: Bool) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SwapPaymentError.notAuthenticated
        }

        // Check if user can waive fee
        let canWaive = try await pointsService.canWaiveFee(userId: userId)
        guard canWaive else {
            throw SwapPointsError.insufficientBalance
        }

        // Deduct points
        try await pointsService.deductPointsForFeeWaiver(
            userId: userId,
            swapId: swap.id
        )

        // Mark fee as paid
        try await billSwapService.markFeePaid(swap.id, forInitiator: isInitiator)
    }

    // MARK: - Record Payment

    /// Record payment in our database
    private func recordPayment(
        swapId: UUID,
        transactionId: String,
        productId: String,
        amountCents: Int
    ) async throws {
        guard let userId = SupabaseService.shared.currentUserId else { return }

        let payload = RecordPaymentPayload(
            swapId: swapId.uuidString,
            userId: userId.uuidString,
            transactionId: transactionId,
            productId: productId,
            amountCents: amountCents,
            paymentMethod: "apple_iap",
            status: "completed"
        )

        try await supabase
            .from("swap_payments")
            .insert(payload)
            .execute()
    }

    // MARK: - Transaction Listener

    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    // Handle restored or updated transaction
                    await transaction.finish()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async throws {
        try await AppStore.sync()
    }

    // MARK: - Check Entitlements

    /// Check if user has any pending transactions
    func hasPendingTransactions() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified = result {
                return true
            }
        }
        return false
    }

    // MARK: - Formatted Price

    /// Get formatted price for a swap type
    func formattedPrice(for swapType: BillSwapType) -> String {
        guard let product = getProduct(for: swapType) else {
            // Fallback to hardcoded prices
            return swapType == .twoSided ? "$0.99" : "$1.49"
        }
        return product.displayPrice
    }

    /// Get fee amount in cents for a swap type
    func feeAmountCents(for swapType: BillSwapType) -> Int {
        return swapType == .twoSided ? 99 : 149
    }
}

// MARK: - Fee Summary

struct SwapFeeSummary {
    let swapType: BillSwapType
    let feeAmountCents: Int
    let canWaiveWithPoints: Bool
    let pointsBalance: Int
    let pointsNeeded: Int

    var formattedFee: String {
        String(format: "$%.2f", Double(feeAmountCents) / 100.0)
    }

    var formattedPointsNeeded: String {
        "\(PointsConstants.feeWaiverCost) points"
    }

    var shortagePoints: Int {
        max(0, PointsConstants.feeWaiverCost - pointsBalance)
    }
}

//
//  StoreKitService.swift
//  Billix
//
//  StoreKit 2 service for handling Billix Prime subscriptions
//

import Foundation
import StoreKit

// MARK: - Product IDs

enum BillixProduct: String, CaseIterable {
    case billixPrimeMonthly = "com.billix.prime.monthly"
    case billixPrimeYearly = "com.billix.prime.yearly"
    case swapHandshakeFee = "com.billix.handshake_fee"
    case tokenPack3 = "com.billix.token_pack_3"

    var displayName: String {
        switch self {
        case .billixPrimeMonthly: return "Billix Prime Monthly"
        case .billixPrimeYearly: return "Billix Prime Yearly"
        case .swapHandshakeFee: return "Swap Handshake Fee"
        case .tokenPack3: return "3 Connect Tokens"
        }
    }

    var isConsumable: Bool {
        switch self {
        case .swapHandshakeFee, .tokenPack3: return true
        default: return false
        }
    }
}

// MARK: - StoreKit Service

@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var updateListenerTask: Task<Void, Error>?

    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    /// Check if user has an active Billix Prime subscription
    var isPrime: Bool {
        purchasedProductIDs.contains(BillixProduct.billixPrimeMonthly.rawValue) ||
        purchasedProductIDs.contains(BillixProduct.billixPrimeYearly.rawValue)
    }

    private init() {
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = BillixProduct.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIDs)

            // Sort by price
            products = storeProducts.sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("StoreKit Error: \(error)")
        }
    }

    // MARK: - Purchase Product

    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Update purchased products
                await updatePurchasedProducts()

                // Update Supabase with subscription status
                await updateSupabaseSubscription(isPremium: true)

                // Finish the transaction
                await transaction.finish()

                isLoading = false
                return transaction

            case .userCancelled:
                isLoading = false
                return nil

            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return nil

            @unknown default:
                isLoading = false
                return nil
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }

    // MARK: - Check Purchased Products

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if subscription is still valid
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        purchased.insert(transaction.productID)
                    }
                } else {
                    // Non-subscription purchases
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        purchasedProductIDs = purchased

        // Update Supabase
        await updateSupabaseSubscription(isPremium: !purchased.isEmpty)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    guard let self = self else { return }
                    let transaction = try await MainActor.run {
                        try self.checkVerified(result)
                    }

                    await self.updatePurchasedProducts()

                    await transaction.finish()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verify Transaction

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Update Supabase

    private func updateSupabaseSubscription(isPremium: Bool) async {
        guard let userId = AuthService.shared.currentUser?.id else { return }

        do {
            let tier = isPremium ? "prime" : "free"

            if isPremium, let expiresAt = Calendar.current.date(byAdding: .month, value: 1, to: Date()) {
                // Update profiles table with expiration date
                try await SupabaseService.shared.client
                    .from("profiles")
                    .update([
                        "subscription_tier": tier,
                        "subscription_expires_at": expiresAt.ISO8601Format()
                    ])
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                // Update user_vault table with expiration date
                try await SupabaseService.shared.client
                    .from("user_vault")
                    .update([
                        "subscription_tier": tier,
                        "subscription_expires_at": expiresAt.ISO8601Format()
                    ])
                    .eq("id", value: userId.uuidString)
                    .execute()
            } else {
                // Update profiles table without expiration
                try await SupabaseService.shared.client
                    .from("profiles")
                    .update(["subscription_tier": tier])
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                // Update user_vault table without expiration
                try await SupabaseService.shared.client
                    .from("user_vault")
                    .update(["subscription_tier": tier])
                    .eq("id", value: userId.uuidString)
                    .execute()
            }

            print("Updated Supabase subscription to: \(tier)")
        } catch {
            print("Failed to update Supabase subscription: \(error)")
        }
    }

    // MARK: - Get Monthly Product

    var monthlyProduct: Product? {
        products.first { $0.id == BillixProduct.billixPrimeMonthly.rawValue }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == BillixProduct.billixPrimeYearly.rawValue }
    }

    var handshakeFeeProduct: Product? {
        products.first { $0.id == BillixProduct.swapHandshakeFee.rawValue }
    }

    var handshakeFeePrice: String {
        handshakeFeeProduct?.displayPrice ?? "$1.99"
    }

    var tokenPackProduct: Product? {
        products.first { $0.id == BillixProduct.tokenPack3.rawValue }
    }

    var tokenPackPrice: String {
        tokenPackProduct?.displayPrice ?? "$1.99"
    }

    // MARK: - Purchase Token Pack (Consumable)

    /// Purchase the 3-token pack (consumable product)
    /// Returns true if purchase was successful
    func purchaseTokenPack() async throws -> Bool {
        guard let product = tokenPackProduct else {
            throw StoreError.productNotFound
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Consumable - don't add to purchasedProductIDs, just finish
                await transaction.finish()

                isLoading = false
                return true

            case .userCancelled:
                isLoading = false
                return false

            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Purchase Handshake Fee (Consumable)

    /// Purchase the swap handshake fee (consumable product)
    /// Returns true if purchase was successful
    func purchaseHandshakeFee() async throws -> Bool {
        guard let product = handshakeFeeProduct else {
            throw StoreError.productNotFound
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Consumable - don't add to purchasedProductIDs, just finish
                await transaction.finish()

                isLoading = false
                return true

            case .userCancelled:
                isLoading = false
                return false

            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }
}

// MARK: - Store Errors

enum StoreError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}

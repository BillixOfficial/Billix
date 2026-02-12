//
//  StoreKitService.swift
//  Billix
//
//  StoreKit 2 service for handling Billix membership and token purchases
//

import Foundation
import StoreKit

// MARK: - Product IDs

enum BillixProduct: String, CaseIterable {
    case billixPrimeMonthly = "com.billix.prime.monthly"  // $6.99/month
    case tokenFee = "com.billix.token_fee"                // 2 tokens for $1.99

    var displayName: String {
        switch self {
        case .billixPrimeMonthly: return "Billix Membership"
        case .tokenFee: return "2 Tokens"
        }
    }

    var isConsumable: Bool {
        switch self {
        case .tokenFee: return true
        case .billixPrimeMonthly: return false
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
    @Published private(set) var isVerifiedMember: Bool = false

    private var updateListenerTask: Task<Void, Error>?

    /// Check if user has an active Billix Membership (verified against both StoreKit and Supabase)
    var isMember: Bool {
        isVerifiedMember
    }

    /// Aliases for backwards compatibility
    var isPrime: Bool { isMember }
    var isPremium: Bool { isMember }

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

                // Sync membership to Supabase if this is a subscription
                if transaction.productID == BillixProduct.billixPrimeMonthly.rawValue {
                    try? await SubscriptionSyncService.shared.recordMembershipPurchase(transaction: transaction)
                    // Re-verify membership with both sources after sync
                    await verifyMembershipWithSupabase()
                }

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
            await verifyMembershipWithSupabase()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }

    // MARK: - Verify Membership with Supabase

    /// Verify membership against both StoreKit and Supabase
    /// Both sources must confirm active subscription for isMember to return true
    /// Falls back to StoreKit-only if Supabase check fails (network error)
    func verifyMembershipWithSupabase() async {
        // 1. Check if StoreKit says user has membership entitlement
        let hasStoreKitEntitlement = purchasedProductIDs.contains(BillixProduct.billixPrimeMonthly.rawValue)

        guard hasStoreKitEntitlement else {
            isVerifiedMember = false
            return
        }

        // 2. Check Supabase profiles table
        guard let userId = AuthService.shared.currentUser?.id else {
            // Not logged in - fall back to StoreKit only
            isVerifiedMember = hasStoreKitEntitlement
            return
        }

        do {
            let profile: ProfileSubscriptionCheck = try await SupabaseService.shared.client
                .from("profiles")
                .select("subscription_tier, subscription_expires_at")
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            // 3. Verify both conditions:
            //    - subscription_tier == "prime"
            //    - subscription_expires_at > now (if set)
            let tierValid = profile.subscriptionTier == "prime"
            let notExpired = profile.subscriptionExpiresAt == nil || profile.subscriptionExpiresAt! > Date()

            isVerifiedMember = tierValid && notExpired
            print("Membership verified: tier=\(profile.subscriptionTier), expires=\(String(describing: profile.subscriptionExpiresAt)), verified=\(isVerifiedMember)")
        } catch {
            // If Supabase check fails, fall back to StoreKit only (graceful degradation)
            isVerifiedMember = hasStoreKitEntitlement
            print("Supabase membership check failed, falling back to StoreKit: \(error)")
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

    // MARK: - Product Accessors

    var monthlyProduct: Product? {
        products.first { $0.id == BillixProduct.billixPrimeMonthly.rawValue }
    }

    var monthlyPrice: String {
        monthlyProduct?.displayPrice ?? "$6.99"
    }

    var tokenPackProduct: Product? {
        products.first { $0.id == BillixProduct.tokenFee.rawValue }
    }

    var tokenPackPrice: String {
        tokenPackProduct?.displayPrice ?? "$1.99"
    }

    // MARK: - Purchase Token Pack (Consumable)

    /// Purchase the 2-token pack (consumable product)
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

                // Award tokens to user (throws if fails)
                try await TokenService.shared.addTokens(2)

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

    // MARK: - Purchase Membership

    /// Purchase the monthly membership
    /// Returns true if purchase was successful
    func purchaseMembership() async throws -> Bool {
        guard let product = monthlyProduct else {
            throw StoreError.productNotFound
        }

        do {
            let transaction = try await purchase(product)
            return transaction != nil
        } catch {
            throw error
        }
    }
}

// MARK: - Supporting Types

private struct ProfileSubscriptionCheck: Decodable {
    let subscriptionTier: String
    let subscriptionExpiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
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

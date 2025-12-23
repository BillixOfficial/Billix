//
//  SubscriptionService.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Service for managing subscriptions via StoreKit 2 and feature gating
//

import Foundation
import StoreKit
import Supabase

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case verificationFailed
    case notAuthenticated
    case alreadySubscribed
    case updateFailed
    case insufficientCredits

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not available"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .verificationFailed:
            return "Unable to verify purchase"
        case .notAuthenticated:
            return "Please sign in to continue"
        case .alreadySubscribed:
            return "You already have an active subscription"
        case .updateFailed:
            return "Failed to update subscription status"
        case .insufficientCredits:
            return "Not enough credits to unlock this feature"
        }
    }
}

// MARK: - Subscription Service

@MainActor
class SubscriptionService: ObservableObject {

    // MARK: - Singleton
    static let shared = SubscriptionService()

    // MARK: - Published Properties
    @Published var currentTier: BillixSubscriptionTier = .free
    @Published var subscription: UserSubscription?
    @Published var availableProducts: [Product] = []
    @Published var featureUnlocks: [String: FeatureUnlock] = [:]
    @Published var isLoading = false
    @Published var purchaseInProgress = false

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
            await loadSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    /// Loads available subscription products from App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIds = SubscriptionProductID.allCases.map { $0.rawValue }
            let products = try await Product.products(for: productIds)
            availableProducts = products.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load subscription products: \(error)")
        }
    }

    // MARK: - Load Subscription Status

    /// Loads current subscription status from Supabase
    func loadSubscriptionStatus() async {
        guard let session = try? await supabase.auth.session else {
            currentTier = .free
            subscription = nil
            return
        }

        do {
            // Fetch subscription from database
            let subscriptions: [UserSubscription] = try await supabase
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
                .value

            if let sub = subscriptions.first {
                subscription = sub
                currentTier = sub.isActive ? sub.tier : .free
            } else {
                subscription = nil
                currentTier = .free
            }

            // Load feature unlocks
            await loadFeatureUnlocks()

            // Verify with StoreKit
            await verifyEntitlements()

        } catch {
            print("Failed to load subscription status: \(error)")
            currentTier = .free
        }
    }

    // MARK: - Feature Unlocks

    /// Loads credit-based feature unlocks
    private func loadFeatureUnlocks() async {
        guard let session = try? await supabase.auth.session else { return }

        do {
            let unlocks: [FeatureUnlock] = try await supabase
                .from("feature_unlocks")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
                .value

            featureUnlocks = Dictionary(uniqueKeysWithValues: unlocks.map { ($0.featureKey, $0) })
        } catch {
            print("Failed to load feature unlocks: \(error)")
        }
    }

    // MARK: - Feature Access Check

    /// Checks if user has access to a premium feature
    func hasAccess(to feature: PremiumFeature) -> Bool {
        // Check subscription tier first
        if currentTier.features.contains(feature) {
            return true
        }

        // Check credit-based unlocks
        if let unlock = featureUnlocks[feature.rawValue], unlock.isActive {
            return true
        }

        return false
    }

    /// Returns the reason why a feature is locked
    func lockReason(for feature: PremiumFeature) -> String? {
        if hasAccess(to: feature) { return nil }

        let requiredTier = feature.requiredTier
        if let creditCost = feature.creditCost {
            return "Requires \(requiredTier.displayName) subscription or \(creditCost) credits"
        }
        return "Requires \(requiredTier.displayName) subscription"
    }

    // MARK: - Purchase Subscription

    /// Purchases a subscription product
    func purchase(_ productId: SubscriptionProductID) async throws {
        guard let product = availableProducts.first(where: { $0.id == productId.rawValue }) else {
            throw SubscriptionError.productNotFound
        }

        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await recordSubscription(transaction: transaction, productId: productId)
                await transaction.finish()

            case .userCancelled:
                break // User cancelled, no error

            case .pending:
                // Transaction pending (e.g., parental approval)
                break

            @unknown default:
                throw SubscriptionError.purchaseFailed
            }
        } catch let error as SubscriptionError {
            throw error
        } catch {
            throw SubscriptionError.purchaseFailed
        }
    }

    // MARK: - Unlock Feature with Credits

    /// Unlocks a feature using credits
    func unlockFeature(_ feature: PremiumFeature, using creditsService: UnlockCreditsService) async throws {
        guard let creditCost = feature.creditCost else {
            throw SubscriptionError.purchaseFailed
        }

        guard let session = try? await supabase.auth.session else {
            throw SubscriptionError.notAuthenticated
        }

        // Spend credits
        try await creditsService.spendCredits(creditCost, for: feature)

        // Record unlock
        let insert = FeatureUnlockInsert(
            userId: session.user.id.uuidString,
            featureKey: feature.rawValue,
            unlockMethod: UnlockMethod.credits.rawValue,
            expiresAt: nil // Permanent unlock
        )

        try await supabase
            .from("feature_unlocks")
            .insert(insert)
            .execute()

        // Reload unlocks
        await loadFeatureUnlocks()
    }

    // MARK: - Restore Purchases

    /// Restores previous purchases
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await verifyEntitlements()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }

    // MARK: - Transaction Verification

    /// Verifies a StoreKit transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    /// Verifies current entitlements from StoreKit
    private func verifyEntitlements() async {
        var hasActiveSubscription = false
        var activeTier: BillixSubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if let productId = SubscriptionProductID(rawValue: transaction.productID) {
                    hasActiveSubscription = true
                    if productId.tier.includes(activeTier) {
                        activeTier = productId.tier
                    }
                }
            } catch {
                print("Failed to verify entitlement: \(error)")
            }
        }

        // Update tier if StoreKit shows different status
        if hasActiveSubscription && activeTier != currentTier {
            currentTier = activeTier
            // Sync to database
            await syncSubscriptionToDatabase(tier: activeTier)
        }
    }

    // MARK: - Transaction Listener

    /// Listens for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.handleTransactionUpdate(transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Handles a transaction update
    private func handleTransactionUpdate(_ transaction: Transaction) async {
        guard let productId = SubscriptionProductID(rawValue: transaction.productID) else {
            return
        }

        // Update subscription status based on transaction
        if transaction.revocationDate != nil {
            // Subscription revoked
            await handleSubscriptionRevoked()
        } else if transaction.expirationDate != nil && transaction.expirationDate! < Date() {
            // Subscription expired
            await handleSubscriptionExpired()
        } else {
            // Active subscription
            await recordSubscription(transaction: transaction, productId: productId)
        }
    }

    // MARK: - Database Recording

    /// Records subscription to Supabase
    private func recordSubscription(transaction: Transaction, productId: SubscriptionProductID) async {
        guard let session = try? await supabase.auth.session else { return }

        let formatter = ISO8601DateFormatter()

        let insert = UserSubscriptionInsert(
            userId: session.user.id.uuidString,
            tier: productId.tier.rawValue,
            storekitProductId: productId.rawValue,
            storekitTransactionId: String(transaction.id),
            storekitOriginalTransactionId: String(transaction.originalID),
            status: SubscriptionStatus.active.rawValue,
            expiresAt: transaction.expirationDate.map { formatter.string(from: $0) },
            renewalDate: transaction.expirationDate.map { formatter.string(from: $0) }
        )

        do {
            try await supabase
                .from("user_subscriptions")
                .upsert(insert, onConflict: "user_id")
                .execute()

            currentTier = productId.tier
            await loadSubscriptionStatus()
        } catch {
            print("Failed to record subscription: \(error)")
        }
    }

    /// Syncs subscription tier to database
    private func syncSubscriptionToDatabase(tier: BillixSubscriptionTier) async {
        guard let session = try? await supabase.auth.session else { return }

        do {
            try await supabase
                .from("user_subscriptions")
                .update(["tier": tier.rawValue, "status": SubscriptionStatus.active.rawValue])
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
        } catch {
            print("Failed to sync subscription: \(error)")
        }
    }

    /// Handles subscription revocation
    private func handleSubscriptionRevoked() async {
        guard let session = try? await supabase.auth.session else { return }

        do {
            try await supabase
                .from("user_subscriptions")
                .update(["tier": BillixSubscriptionTier.free.rawValue, "status": SubscriptionStatus.cancelled.rawValue])
                .eq("user_id", value: session.user.id.uuidString)
                .execute()

            currentTier = .free
            await loadSubscriptionStatus()
        } catch {
            print("Failed to handle revocation: \(error)")
        }
    }

    /// Handles subscription expiration
    private func handleSubscriptionExpired() async {
        guard let session = try? await supabase.auth.session else { return }

        do {
            try await supabase
                .from("user_subscriptions")
                .update(["tier": BillixSubscriptionTier.free.rawValue, "status": SubscriptionStatus.expired.rawValue])
                .eq("user_id", value: session.user.id.uuidString)
                .execute()

            currentTier = .free
            await loadSubscriptionStatus()
        } catch {
            print("Failed to handle expiration: \(error)")
        }
    }

    // MARK: - Product Helpers

    /// Gets a product by subscription product ID
    func product(for productId: SubscriptionProductID) -> Product? {
        availableProducts.first { $0.id == productId.rawValue }
    }

    /// Gets monthly products
    var monthlyProducts: [Product] {
        availableProducts.filter { product in
            SubscriptionProductID(rawValue: product.id)?.isAnnual == false
        }
    }

    /// Gets annual products
    var annualProducts: [Product] {
        availableProducts.filter { product in
            SubscriptionProductID(rawValue: product.id)?.isAnnual == true
        }
    }

    // MARK: - Reset

    func reset() {
        currentTier = .free
        subscription = nil
        featureUnlocks = [:]
    }
}

// MARK: - Preview Helpers

extension SubscriptionService {
    static func mockWithTier(_ tier: BillixSubscriptionTier) -> SubscriptionService {
        let service = SubscriptionService.shared
        service.currentTier = tier
        return service
    }
}

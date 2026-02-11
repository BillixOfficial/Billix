//
//  SubscriptionSyncService.swift
//  Billix
//
//  Syncs StoreKit subscription status to Supabase for server-side tracking
//

import Foundation
import StoreKit
import Supabase

@MainActor
class SubscriptionSyncService: ObservableObject {
    static let shared = SubscriptionSyncService()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentUserId: UUID? {
        AuthService.shared.currentUser?.id
    }

    private init() {}

    // MARK: - Sync Subscription Status

    /// Sync current subscription status to Supabase
    /// Call this on app launch and after any purchase
    func syncSubscriptionStatus() async {
        guard let userId = currentUserId else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            // Check StoreKit for active subscription
            var activeSubscription: Transaction?
            var expirationDate: Date?

            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }

                if transaction.productID == BillixProduct.billixPrimeMonthly.rawValue {
                    activeSubscription = transaction
                    expirationDate = transaction.expirationDate
                    break
                }
            }

            // Update Supabase with subscription status
            if let transaction = activeSubscription, let expiry = expirationDate, expiry > Date() {
                // User has active membership
                try await updateSubscriptionInSupabase(
                    userId: userId,
                    tier: "prime",
                    expiresAt: expiry,
                    transaction: transaction
                )
            } else {
                // No active membership - check if we need to downgrade
                try await checkAndDowngradeIfExpired(userId: userId)
            }

            lastSyncDate = Date()
            syncError = nil
        } catch {
            syncError = error
            print("Failed to sync subscription status: \(error)")
        }
    }

    // MARK: - Record New Purchase

    /// Record a new membership purchase to Supabase
    /// Call this immediately after a successful purchase
    func recordMembershipPurchase(transaction: Transaction) async throws {
        guard let userId = currentUserId else {
            throw SubscriptionSyncError.notAuthenticated
        }

        guard let expirationDate = transaction.expirationDate else {
            throw SubscriptionSyncError.noExpirationDate
        }

        try await updateSubscriptionInSupabase(
            userId: userId,
            tier: "prime",
            expiresAt: expirationDate,
            transaction: transaction
        )
    }

    // MARK: - Private Helpers

    private func updateSubscriptionInSupabase(
        userId: UUID,
        tier: String,
        expiresAt: Date,
        transaction: Transaction
    ) async throws {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expiresAtString = isoFormatter.string(from: expiresAt)

        // Update profiles table
        try await supabase
            .from("profiles")
            .update(ProfileSubscriptionUpdate(
                subscriptionTier: tier,
                subscriptionExpiresAt: expiresAtString
            ))
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Upsert to user_subscriptions table for detailed tracking
        let subscriptionRecord = UserSubscriptionUpsert(
            userId: userId,
            tier: tier,
            storekitProductId: transaction.productID,
            storekitTransactionId: String(transaction.id),
            storekitOriginalTransactionId: String(transaction.originalID),
            status: "active",
            expiresAt: expiresAtString,
            renewalDate: expiresAtString
        )

        try await supabase
            .from("user_subscriptions")
            .upsert(subscriptionRecord, onConflict: "user_id")
            .execute()

        print("Subscription synced to Supabase: tier=\(tier), expires=\(expiresAt)")
    }

    private func checkAndDowngradeIfExpired(userId: UUID) async throws {
        // Check current profile subscription status
        let profile: ProfileSubscriptionRecord = try await supabase
            .from("profiles")
            .select("subscription_tier, subscription_expires_at")
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        // If they're marked as prime but StoreKit says no active subscription,
        // check if the expiration has passed
        if profile.subscriptionTier == "prime" {
            let shouldDowngrade: Bool

            if let expiresAt = profile.subscriptionExpiresAt {
                shouldDowngrade = expiresAt < Date()
            } else {
                // No expiration date but marked as prime - downgrade to be safe
                shouldDowngrade = true
            }

            if shouldDowngrade {
                // Downgrade to free
                try await supabase
                    .from("profiles")
                    .update(ProfileSubscriptionUpdate(
                        subscriptionTier: "free",
                        subscriptionExpiresAt: nil
                    ))
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                // Update user_subscriptions status
                try await supabase
                    .from("user_subscriptions")
                    .update(["status": "expired"])
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                print("Subscription expired - downgraded to free tier")
            }
        }
    }

    // MARK: - Cancel Subscription

    /// Record subscription cancellation
    func recordCancellation() async throws {
        guard let userId = currentUserId else {
            throw SubscriptionSyncError.notAuthenticated
        }

        let isoFormatter = ISO8601DateFormatter()
        let nowString = isoFormatter.string(from: Date())

        try await supabase
            .from("user_subscriptions")
            .update(UserSubscriptionCancelUpdate(
                status: "cancelled",
                cancelledAt: nowString
            ))
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
}

// MARK: - Supporting Types

private struct ProfileSubscriptionUpdate: Encodable {
    let subscriptionTier: String
    let subscriptionExpiresAt: String?

    enum CodingKeys: String, CodingKey {
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
    }
}

private struct ProfileSubscriptionRecord: Decodable {
    let subscriptionTier: String
    let subscriptionExpiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
    }
}

private struct UserSubscriptionUpsert: Encodable {
    let userId: UUID
    let tier: String
    let storekitProductId: String
    let storekitTransactionId: String
    let storekitOriginalTransactionId: String
    let status: String
    let expiresAt: String
    let renewalDate: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case tier
        case storekitProductId = "storekit_product_id"
        case storekitTransactionId = "storekit_transaction_id"
        case storekitOriginalTransactionId = "storekit_original_transaction_id"
        case status
        case expiresAt = "expires_at"
        case renewalDate = "renewal_date"
    }
}

private struct UserSubscriptionCancelUpdate: Encodable {
    let status: String
    let cancelledAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case cancelledAt = "cancelled_at"
    }
}

// MARK: - Errors

enum SubscriptionSyncError: LocalizedError {
    case notAuthenticated
    case noExpirationDate
    case syncFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to sync subscription"
        case .noExpirationDate:
            return "Subscription has no expiration date"
        case .syncFailed:
            return "Failed to sync subscription status"
        }
    }
}

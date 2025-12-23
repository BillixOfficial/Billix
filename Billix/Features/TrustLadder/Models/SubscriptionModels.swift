//
//  SubscriptionModels.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Models for subscription tiers and feature gating
//

import Foundation
import SwiftUI

// MARK: - Subscription Tier

enum BillixSubscriptionTier: String, Codable, CaseIterable, Identifiable {
    case free
    case basic
    case pro
    case premium

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .basic: return "Basic"
        case .pro: return "Pro"
        case .premium: return "Premium"
        }
    }

    var monthlyPrice: Decimal {
        switch self {
        case .free: return 0
        case .basic: return 2.99
        case .pro: return 5.99
        case .premium: return 9.99
        }
    }

    var formattedPrice: String {
        switch self {
        case .free: return "Free"
        case .basic: return "$2.99/mo"
        case .pro: return "$5.99/mo"
        case .premium: return "$9.99/mo"
        }
    }

    var features: [PremiumFeature] {
        switch self {
        case .free:
            return [.exactMatchSwaps, .billReceiptExchange, .liveMarketplaceFeed, .unlockCredits]
        case .basic:
            return [.exactMatchSwaps, .billReceiptExchange, .liveMarketplaceFeed, .unlockCredits, .priorityListings]
        case .pro:
            return [.exactMatchSwaps, .billReceiptExchange, .liveMarketplaceFeed, .unlockCredits, .priorityListings,
                    .fractionalSwaps, .multiPartySwaps, .swapBackProtection, .flexibleSwaps]
        case .premium:
            return [.exactMatchSwaps, .billReceiptExchange, .liveMarketplaceFeed, .unlockCredits, .priorityListings,
                    .fractionalSwaps, .multiPartySwaps, .swapBackProtection, .flexibleSwaps, .groupSwaps, .advancedAnalytics]
        }
    }

    var color: Color {
        switch self {
        case .free: return .gray
        case .basic: return .blue
        case .pro: return .purple
        case .premium: return .orange
        }
    }

    var icon: String {
        switch self {
        case .free: return "person.circle"
        case .basic: return "star.circle"
        case .pro: return "crown"
        case .premium: return "crown.fill"
        }
    }

    var tagline: String {
        switch self {
        case .free: return "Get started with basic swaps"
        case .basic: return "Stand out in the marketplace"
        case .pro: return "Unlock powerful swap options"
        case .premium: return "The complete Billix experience"
        }
    }

    /// Numeric level for tier comparison (0=free, 1=basic, 2=pro, 3=premium)
    var tierLevel: Int {
        switch self {
        case .free: return 0
        case .basic: return 1
        case .pro: return 2
        case .premium: return 3
        }
    }

    /// Returns true if this tier includes all features of another tier
    func includes(_ other: BillixSubscriptionTier) -> Bool {
        return self.tierLevel >= other.tierLevel
    }
}

// MARK: - Premium Features

enum PremiumFeature: String, Codable, CaseIterable, Identifiable {
    // Free features
    case exactMatchSwaps = "exact_match_swaps"
    case billReceiptExchange = "bill_receipt_exchange"
    case liveMarketplaceFeed = "live_marketplace_feed"
    case unlockCredits = "unlock_credits"

    // Basic features
    case priorityListings = "priority_listings"

    // Pro features
    case fractionalSwaps = "fractional_swaps"
    case multiPartySwaps = "multi_party_swaps"
    case swapBackProtection = "swap_back_protection"
    case flexibleSwaps = "flexible_swaps"

    // Premium features
    case groupSwaps = "group_swaps"
    case advancedAnalytics = "advanced_analytics"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .exactMatchSwaps: return "Exact Match Swaps"
        case .billReceiptExchange: return "Bill Receipt Exchange"
        case .liveMarketplaceFeed: return "Live Marketplace Feed"
        case .unlockCredits: return "Unlock Credits"
        case .priorityListings: return "Priority Listings"
        case .fractionalSwaps: return "Fractional Swaps"
        case .multiPartySwaps: return "Multi-Party Swaps"
        case .swapBackProtection: return "Swap-Back Protection"
        case .flexibleSwaps: return "Flexible Swaps"
        case .groupSwaps: return "Group Swaps"
        case .advancedAnalytics: return "Advanced Analytics"
        }
    }

    var description: String {
        switch self {
        case .exactMatchSwaps:
            return "Coordinate 1:1 bill swaps with matched partners"
        case .billReceiptExchange:
            return "Upload paid bill receipts to earn credits"
        case .liveMarketplaceFeed:
            return "See anonymized swap activity in real-time"
        case .unlockCredits:
            return "Earn and spend credits to unlock features"
        case .priorityListings:
            return "Get enhanced visibility in the marketplace"
        case .fractionalSwaps:
            return "Cover only a portion of a partner's bill"
        case .multiPartySwaps:
            return "Split one bill across multiple contributors"
        case .swapBackProtection:
            return "Get priority access during hardship periods"
        case .flexibleSwaps:
            return "Extended timelines and smaller obligation units"
        case .groupSwaps:
            return "Coordinate swaps with family or roommates"
        case .advancedAnalytics:
            return "Detailed insights and swap history analysis"
        }
    }

    var icon: String {
        switch self {
        case .exactMatchSwaps: return "arrow.left.arrow.right"
        case .billReceiptExchange: return "doc.text.image"
        case .liveMarketplaceFeed: return "chart.line.uptrend.xyaxis"
        case .unlockCredits: return "star.circle"
        case .priorityListings: return "arrow.up.circle"
        case .fractionalSwaps: return "chart.pie"
        case .multiPartySwaps: return "person.3"
        case .swapBackProtection: return "shield.checkered"
        case .flexibleSwaps: return "calendar.badge.clock"
        case .groupSwaps: return "person.3.fill"
        case .advancedAnalytics: return "chart.bar.xaxis"
        }
    }

    var requiredTier: BillixSubscriptionTier {
        switch self {
        case .exactMatchSwaps, .billReceiptExchange, .liveMarketplaceFeed, .unlockCredits:
            return .free
        case .priorityListings:
            return .basic
        case .fractionalSwaps, .multiPartySwaps, .swapBackProtection, .flexibleSwaps:
            return .pro
        case .groupSwaps, .advancedAnalytics:
            return .premium
        }
    }

    /// Credits required to unlock this feature (if not subscribed)
    var creditCost: Int? {
        switch self {
        case .exactMatchSwaps, .billReceiptExchange, .liveMarketplaceFeed, .unlockCredits:
            return nil // Always free
        case .priorityListings:
            return 50 // Per listing
        case .fractionalSwaps, .multiPartySwaps:
            return 100 // Per swap
        case .swapBackProtection:
            return 200 // Per activation
        case .flexibleSwaps:
            return 75 // Per swap
        case .groupSwaps:
            return nil // Subscription only
        case .advancedAnalytics:
            return nil // Subscription only
        }
    }
}

// MARK: - User Subscription

struct UserSubscription: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var tier: BillixSubscriptionTier
    var storekitProductId: String?
    var storekitTransactionId: String?
    var storekitOriginalTransactionId: String?
    var status: SubscriptionStatus
    var startedAt: Date
    var expiresAt: Date?
    var renewalDate: Date?
    var cancelledAt: Date?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tier
        case storekitProductId = "storekit_product_id"
        case storekitTransactionId = "storekit_transaction_id"
        case storekitOriginalTransactionId = "storekit_original_transaction_id"
        case status
        case startedAt = "started_at"
        case expiresAt = "expires_at"
        case renewalDate = "renewal_date"
        case cancelledAt = "cancelled_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isActive: Bool {
        status == .active || status == .gracePeriod
    }

    var daysUntilExpiration: Int? {
        guard let expiresAt = expiresAt else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day
    }
}

// MARK: - Subscription Status

enum SubscriptionStatus: String, Codable {
    case active
    case cancelled
    case expired
    case gracePeriod = "grace_period"
    case pending

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        case .gracePeriod: return "Grace Period"
        case .pending: return "Pending"
        }
    }

    var color: Color {
        switch self {
        case .active: return .green
        case .cancelled: return .orange
        case .expired: return .red
        case .gracePeriod: return .yellow
        case .pending: return .gray
        }
    }
}

// MARK: - StoreKit Product IDs

enum SubscriptionProductID: String, CaseIterable {
    case basicMonthly = "com.billix.subscription.basic.monthly"
    case basicAnnual = "com.billix.subscription.basic.annual"
    case proMonthly = "com.billix.subscription.pro.monthly"
    case proAnnual = "com.billix.subscription.pro.annual"
    case premiumMonthly = "com.billix.subscription.premium.monthly"
    case premiumAnnual = "com.billix.subscription.premium.annual"

    var tier: BillixSubscriptionTier {
        switch self {
        case .basicMonthly, .basicAnnual: return .basic
        case .proMonthly, .proAnnual: return .pro
        case .premiumMonthly, .premiumAnnual: return .premium
        }
    }

    var isAnnual: Bool {
        switch self {
        case .basicAnnual, .proAnnual, .premiumAnnual: return true
        default: return false
        }
    }

    var displayName: String {
        let period = isAnnual ? "Annual" : "Monthly"
        return "\(tier.displayName) (\(period))"
    }
}

// MARK: - Feature Unlock

struct FeatureUnlock: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let featureKey: String
    let unlockMethod: UnlockMethod
    var unlockedAt: Date
    var expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case featureKey = "feature_key"
        case unlockMethod = "unlock_method"
        case unlockedAt = "unlocked_at"
        case expiresAt = "expires_at"
    }

    var feature: PremiumFeature? {
        PremiumFeature(rawValue: featureKey)
    }

    var isActive: Bool {
        guard let expiresAt = expiresAt else { return true }
        return Date() < expiresAt
    }
}

enum UnlockMethod: String, Codable {
    case subscription
    case credits
    case promotion
    case referral
    case reward
}

// MARK: - Paywall Context

enum PaywallContext {
    case featureGate(PremiumFeature)
    case tierUpgrade
    case settings
    case onboarding

    var title: String {
        switch self {
        case .featureGate(let feature):
            return "Unlock \(feature.displayName)"
        case .tierUpgrade:
            return "Upgrade Your Plan"
        case .settings:
            return "Manage Subscription"
        case .onboarding:
            return "Choose Your Plan"
        }
    }

    var subtitle: String? {
        switch self {
        case .featureGate(let feature):
            return feature.description
        case .tierUpgrade:
            return "Get more from Billix with a premium plan"
        case .settings:
            return nil
        case .onboarding:
            return "Start coordinating bills with your community"
        }
    }
}

// MARK: - Insert Structs for Supabase

struct UserSubscriptionInsert: Codable {
    let userId: String
    let tier: String
    let storekitProductId: String?
    let storekitTransactionId: String?
    let storekitOriginalTransactionId: String?
    let status: String
    let expiresAt: String?
    let renewalDate: String?

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

struct FeatureUnlockInsert: Codable {
    let userId: String
    let featureKey: String
    let unlockMethod: String
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case featureKey = "feature_key"
        case unlockMethod = "unlock_method"
        case expiresAt = "expires_at"
    }
}

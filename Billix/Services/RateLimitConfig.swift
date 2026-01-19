//
//  RateLimitConfig.swift
//  Billix
//
//  Created by Claude Code on 1/18/26.
//  Configuration for RentCast API rate limiting
//

import Foundation

/// Configuration for per-user RentCast API rate limits (points-based)
enum RateLimitConfig {
    // MARK: - Weekly Limits (in points)

    /// Weekly point limit for free tier users
    static let freeLimit: Int = 10

    /// Weekly point limit for premium tier users (future)
    static let premiumLimit: Int = 50

    /// Weekly point limit for enterprise tier users (future)
    static let enterpriseLimit: Int = Int.max

    // MARK: - Point Costs

    /// Points for a new address search (rent estimate + market stats)
    static let newSearchCost: Int = 2

    /// Points for changing bedroom/bathroom filter (rent estimate only)
    static let filterChangeCost: Int = 1

    /// Points for cached searches (no API call)
    static let cachedSearchCost: Int = 0

    // MARK: - UI Thresholds

    /// Threshold percentage at which to show warning (orange indicator)
    /// e.g., 0.3 means warn when 30% or less remaining
    static let warningThreshold: Double = 0.3

    /// Threshold percentage at which to show critical warning (red indicator)
    /// e.g., 0.1 means critical when 10% or less remaining
    static let criticalThreshold: Double = 0.1
}

// MARK: - SubscriptionTier Extension for Rate Limiting

extension SubscriptionTier {
    /// Get the weekly call limit for this tier
    var weeklyLimit: Int {
        switch self {
        case .free:
            return RateLimitConfig.freeLimit
        case .premium:
            return RateLimitConfig.premiumLimit
        case .enterprise:
            return RateLimitConfig.enterpriseLimit
        }
    }
}

//
//  SwapBackProtectionModels.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Models for Swap-Back Protection feature (financial hardship safety net)
//

import Foundation
import SwiftUI

// MARK: - Protection Status

enum ProtectionStatus: String, Codable, CaseIterable {
    case inactive = "inactive"
    case active = "active"
    case pending = "pending"
    case claimed = "claimed"
    case expired = "expired"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .inactive: return "Inactive"
        case .active: return "Active"
        case .pending: return "Pending Verification"
        case .claimed: return "Claimed"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        }
    }

    var icon: String {
        switch self {
        case .inactive: return "shield.slash"
        case .active: return "shield.checkered"
        case .pending: return "clock"
        case .claimed: return "shield.fill"
        case .expired: return "clock.badge.xmark"
        case .cancelled: return "xmark.shield"
        }
    }

    var color: Color {
        switch self {
        case .inactive: return .gray
        case .active: return .green
        case .pending: return .orange
        case .claimed: return .blue
        case .expired, .cancelled: return .red
        }
    }

    var isProtected: Bool {
        self == .active
    }
}

// MARK: - Hardship Reason

enum HardshipReason: String, Codable, CaseIterable, Identifiable {
    case jobLoss = "job_loss"
    case medicalEmergency = "medical_emergency"
    case familyEmergency = "family_emergency"
    case unexpectedExpense = "unexpected_expense"
    case incomeReduction = "income_reduction"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .jobLoss: return "Job Loss"
        case .medicalEmergency: return "Medical Emergency"
        case .familyEmergency: return "Family Emergency"
        case .unexpectedExpense: return "Unexpected Major Expense"
        case .incomeReduction: return "Significant Income Reduction"
        case .other: return "Other Hardship"
        }
    }

    var description: String {
        switch self {
        case .jobLoss: return "Lost employment or primary source of income"
        case .medicalEmergency: return "Unexpected medical expenses or health crisis"
        case .familyEmergency: return "Death, illness, or crisis in the family"
        case .unexpectedExpense: return "Major unplanned expense (car repair, home repair, etc.)"
        case .incomeReduction: return "Reduced hours, pay cut, or business downturn"
        case .other: return "Another financial hardship situation"
        }
    }

    var icon: String {
        switch self {
        case .jobLoss: return "briefcase"
        case .medicalEmergency: return "cross.case"
        case .familyEmergency: return "person.3"
        case .unexpectedExpense: return "exclamationmark.triangle"
        case .incomeReduction: return "arrow.down.right.circle"
        case .other: return "questionmark.circle"
        }
    }

    var requiresDocumentation: Bool {
        switch self {
        case .jobLoss, .medicalEmergency:
            return true
        default:
            return false
        }
    }
}

// MARK: - Claim Status

enum ClaimStatus: String, Codable {
    case submitted = "submitted"
    case underReview = "under_review"
    case approved = "approved"
    case denied = "denied"
    case processed = "processed"

    var displayName: String {
        switch self {
        case .submitted: return "Submitted"
        case .underReview: return "Under Review"
        case .approved: return "Approved"
        case .denied: return "Denied"
        case .processed: return "Processed"
        }
    }

    var color: Color {
        switch self {
        case .submitted: return .blue
        case .underReview: return .orange
        case .approved: return .green
        case .denied: return .red
        case .processed: return .gray
        }
    }
}

// MARK: - Protection Plan

struct ProtectionPlan: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var status: String
    let activatedAt: Date
    let expiresAt: Date
    let swapsCovered: Int
    let maxCoverageAmount: Decimal
    var usedCoverageAmount: Decimal
    let claimsAllowed: Int
    var claimsUsed: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case activatedAt = "activated_at"
        case expiresAt = "expires_at"
        case swapsCovered = "swaps_covered"
        case maxCoverageAmount = "max_coverage_amount"
        case usedCoverageAmount = "used_coverage_amount"
        case claimsAllowed = "claims_allowed"
        case claimsUsed = "claims_used"
        case createdAt = "created_at"
    }

    var protectionStatus: ProtectionStatus? {
        ProtectionStatus(rawValue: status)
    }

    var isActive: Bool {
        protectionStatus == .active && !isExpired
    }

    var isExpired: Bool {
        Date() > expiresAt
    }

    var remainingCoverage: Decimal {
        maxCoverageAmount - usedCoverageAmount
    }

    var remainingClaims: Int {
        claimsAllowed - claimsUsed
    }

    var canMakeClaim: Bool {
        isActive && remainingClaims > 0 && remainingCoverage > 0
    }

    var formattedMaxCoverage: String {
        formatCurrency(maxCoverageAmount)
    }

    var formattedRemainingCoverage: String {
        formatCurrency(remainingCoverage)
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiresAt)
        return max(0, components.day ?? 0)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }
}

// MARK: - Protection Claim

struct ProtectionClaim: Codable, Identifiable {
    let id: UUID
    let planId: UUID
    let userId: UUID
    let swapId: UUID?
    let reason: String
    let reasonDetails: String?
    var status: String
    let claimAmount: Decimal
    var approvedAmount: Decimal?
    let documentationUrl: String?
    var reviewedAt: Date?
    var reviewNotes: String?
    var processedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case planId = "plan_id"
        case userId = "user_id"
        case swapId = "swap_id"
        case reason
        case reasonDetails = "reason_details"
        case status
        case claimAmount = "claim_amount"
        case approvedAmount = "approved_amount"
        case documentationUrl = "documentation_url"
        case reviewedAt = "reviewed_at"
        case reviewNotes = "review_notes"
        case processedAt = "processed_at"
        case createdAt = "created_at"
    }

    var hardshipReason: HardshipReason? {
        HardshipReason(rawValue: reason)
    }

    var claimStatus: ClaimStatus? {
        ClaimStatus(rawValue: status)
    }

    var formattedClaimAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: claimAmount as NSDecimalNumber) ?? "$\(claimAmount)"
    }

    var formattedApprovedAmount: String? {
        guard let amount = approvedAmount else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber)
    }
}

// MARK: - Claim Request

struct ClaimRequest {
    let planId: UUID
    let swapId: UUID?
    let reason: HardshipReason
    let reasonDetails: String?
    let claimAmount: Decimal
    let documentationUrl: String?

    var isValid: Bool {
        claimAmount > 0 &&
        (reason.requiresDocumentation ? documentationUrl != nil : true)
    }
}

// MARK: - Protection Tier

struct ProtectionTier: Identifiable {
    let id = UUID()
    let name: String
    let monthlySwapsCovered: Int
    let maxCoveragePerSwap: Decimal
    let claimsPerYear: Int
    let waitingPeriodDays: Int
    let requiredSubscriptionTier: BillixSubscriptionTier

    var formattedMaxCoverage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: maxCoveragePerSwap as NSDecimalNumber) ?? "$\(maxCoveragePerSwap)"
    }

    static var basic: ProtectionTier {
        ProtectionTier(
            name: "Basic Protection",
            monthlySwapsCovered: 2,
            maxCoveragePerSwap: 100,
            claimsPerYear: 2,
            waitingPeriodDays: 30,
            requiredSubscriptionTier: .basic
        )
    }

    static var pro: ProtectionTier {
        ProtectionTier(
            name: "Pro Protection",
            monthlySwapsCovered: 5,
            maxCoveragePerSwap: 250,
            claimsPerYear: 4,
            waitingPeriodDays: 14,
            requiredSubscriptionTier: .pro
        )
    }

    static var premium: ProtectionTier {
        ProtectionTier(
            name: "Premium Protection",
            monthlySwapsCovered: 10,
            maxCoveragePerSwap: 500,
            claimsPerYear: 6,
            waitingPeriodDays: 7,
            requiredSubscriptionTier: .premium
        )
    }

    static var allTiers: [ProtectionTier] {
        [.basic, .pro, .premium]
    }
}

// MARK: - Insert Structs

struct ProtectionPlanInsert: Codable {
    let userId: String
    let status: String
    let activatedAt: String
    let expiresAt: String
    let swapsCovered: Int
    let maxCoverageAmount: Decimal
    let usedCoverageAmount: Decimal
    let claimsAllowed: Int
    let claimsUsed: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
        case activatedAt = "activated_at"
        case expiresAt = "expires_at"
        case swapsCovered = "swaps_covered"
        case maxCoverageAmount = "max_coverage_amount"
        case usedCoverageAmount = "used_coverage_amount"
        case claimsAllowed = "claims_allowed"
        case claimsUsed = "claims_used"
    }
}

struct ProtectionClaimInsert: Codable {
    let planId: String
    let userId: String
    let swapId: String?
    let reason: String
    let reasonDetails: String?
    let status: String
    let claimAmount: Decimal
    let documentationUrl: String?

    enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case userId = "user_id"
        case swapId = "swap_id"
        case reason
        case reasonDetails = "reason_details"
        case status
        case claimAmount = "claim_amount"
        case documentationUrl = "documentation_url"
    }
}

struct ClaimReviewUpdate: Codable {
    let status: String
    let reviewedAt: String
    let reviewNotes: String?
    let approvedAmount: Decimal?

    enum CodingKeys: String, CodingKey {
        case status
        case reviewedAt = "reviewed_at"
        case reviewNotes = "review_notes"
        case approvedAmount = "approved_amount"
    }
}

struct ProtectionPlanUsageUpdate: Codable {
    let usedCoverageAmount: Decimal
    let claimsUsed: Int

    enum CodingKeys: String, CodingKey {
        case usedCoverageAmount = "used_coverage_amount"
        case claimsUsed = "claims_used"
    }
}

// MARK: - Protection Summary

struct ProtectionSummary {
    let plan: ProtectionPlan?
    let recentClaims: [ProtectionClaim]
    let tier: ProtectionTier?

    var hasActiveProtection: Bool {
        plan?.isActive ?? false
    }

    var pendingClaims: [ProtectionClaim] {
        recentClaims.filter { $0.claimStatus == .submitted || $0.claimStatus == .underReview }
    }

    var approvedClaimsTotal: Decimal {
        recentClaims
            .filter { $0.claimStatus == .approved || $0.claimStatus == .processed }
            .compactMap { $0.approvedAmount }
            .reduce(0, +)
    }
}

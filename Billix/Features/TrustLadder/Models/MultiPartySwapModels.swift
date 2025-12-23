//
//  MultiPartySwapModels.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Models for fractional, multi-party, and flexible swaps
//

import Foundation
import SwiftUI

// MARK: - Swap Type

enum SwapType: String, Codable, CaseIterable {
    case exactMatch = "exact_match"
    case fractional = "fractional"
    case multiParty = "multi_party"
    case group = "group"
    case flexible = "flexible"

    var displayName: String {
        switch self {
        case .exactMatch: return "Exact Match"
        case .fractional: return "Fractional"
        case .multiParty: return "Multi-Party"
        case .group: return "Group"
        case .flexible: return "Flexible"
        }
    }

    var description: String {
        switch self {
        case .exactMatch: return "1:1 swap with a single partner"
        case .fractional: return "Cover a portion of your partner's bill"
        case .multiParty: return "Multiple contributors for one bill"
        case .group: return "Coordinate swaps within a group"
        case .flexible: return "Extended timelines and smaller units"
        }
    }

    var icon: String {
        switch self {
        case .exactMatch: return "arrow.left.arrow.right"
        case .fractional: return "chart.pie"
        case .multiParty: return "person.3"
        case .group: return "person.3.fill"
        case .flexible: return "calendar.badge.clock"
        }
    }

    var color: Color {
        switch self {
        case .exactMatch: return .blue
        case .fractional: return .purple
        case .multiParty: return .orange
        case .group: return .green
        case .flexible: return .cyan
        }
    }

    var requiredFeature: PremiumFeature {
        switch self {
        case .exactMatch: return .exactMatchSwaps
        case .fractional: return .fractionalSwaps
        case .multiParty: return .multiPartySwaps
        case .group: return .groupSwaps
        case .flexible: return .flexibleSwaps
        }
    }

    var requiredTier: BillixSubscriptionTier {
        requiredFeature.requiredTier
    }
}

// MARK: - Multi-Party Swap Status

enum MultiPartySwapStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case recruiting = "recruiting"
    case filled = "filled"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .recruiting: return "Recruiting"
        case .filled: return "Filled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .recruiting: return "person.badge.plus"
        case .filled: return "checkmark.circle"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        case .expired: return "clock.badge.xmark"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .gray
        case .recruiting: return .blue
        case .filled: return .purple
        case .inProgress: return .orange
        case .completed: return .green
        case .cancelled: return .red
        case .expired: return .gray
        }
    }

    var isActive: Bool {
        switch self {
        case .pending, .recruiting, .filled, .inProgress:
            return true
        default:
            return false
        }
    }
}

// MARK: - Participant Status

enum ParticipantStatus: String, Codable {
    case invited = "invited"
    case pending = "pending"
    case confirmed = "confirmed"
    case paid = "paid"
    case verified = "verified"
    case declined = "declined"
    case removed = "removed"

    var displayName: String {
        switch self {
        case .invited: return "Invited"
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .paid: return "Paid"
        case .verified: return "Verified"
        case .declined: return "Declined"
        case .removed: return "Removed"
        }
    }

    var color: Color {
        switch self {
        case .invited: return .blue
        case .pending: return .orange
        case .confirmed: return .purple
        case .paid: return .cyan
        case .verified: return .green
        case .declined, .removed: return .red
        }
    }
}

// MARK: - Multi-Party Swap

struct MultiPartySwap: Codable, Identifiable {
    let id: UUID
    let swapType: String
    var status: String
    let organizerId: UUID
    let targetBillId: UUID?
    let targetAmount: Decimal
    var filledAmount: Decimal
    let minContribution: Decimal?
    let maxParticipants: Int
    let groupId: UUID?
    let executionDeadline: Date?
    let tierRequired: Int
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case swapType = "swap_type"
        case status
        case organizerId = "organizer_id"
        case targetBillId = "target_bill_id"
        case targetAmount = "target_amount"
        case filledAmount = "filled_amount"
        case minContribution = "min_contribution"
        case maxParticipants = "max_participants"
        case groupId = "group_id"
        case executionDeadline = "execution_deadline"
        case tierRequired = "tier_required"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var type: SwapType? {
        SwapType(rawValue: swapType)
    }

    var swapStatus: MultiPartySwapStatus? {
        MultiPartySwapStatus(rawValue: status)
    }

    var remainingAmount: Decimal {
        targetAmount - filledAmount
    }

    var fillPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return Double(truncating: (filledAmount / targetAmount) as NSDecimalNumber)
    }

    var isFilled: Bool {
        filledAmount >= targetAmount
    }

    var formattedTargetAmount: String {
        formatCurrency(targetAmount)
    }

    var formattedFilledAmount: String {
        formatCurrency(filledAmount)
    }

    var formattedRemainingAmount: String {
        formatCurrency(remainingAmount)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }
}

// MARK: - Swap Participant

struct SwapParticipant: Codable, Identifiable {
    let id: UUID
    let swapId: UUID
    let userId: UUID
    let billId: UUID?
    let contributionAmount: Decimal
    var status: String
    var feePaid: Bool
    var screenshotUrl: String?
    var screenshotVerified: Bool?
    var completedAt: Date?
    var ratingGiven: Int?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case userId = "user_id"
        case billId = "bill_id"
        case contributionAmount = "contribution_amount"
        case status
        case feePaid = "fee_paid"
        case screenshotUrl = "screenshot_url"
        case screenshotVerified = "screenshot_verified"
        case completedAt = "completed_at"
        case ratingGiven = "rating_given"
        case createdAt = "created_at"
    }

    var participantStatus: ParticipantStatus? {
        ParticipantStatus(rawValue: status)
    }

    var formattedContribution: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: contributionAmount as NSDecimalNumber) ?? "$\(contributionAmount)"
    }
}

// MARK: - Fractional Swap Request

struct FractionalSwapRequest {
    let targetBillId: UUID?
    let targetAmount: Decimal
    let minContribution: Decimal
    let maxParticipants: Int
    let executionDeadline: Date?
    let category: ReceiptBillCategory
    let providerName: String?

    var isValid: Bool {
        targetAmount > 0 &&
        minContribution > 0 &&
        minContribution <= targetAmount &&
        maxParticipants >= 1
    }

    var defaultMinContribution: Decimal {
        // Default to 25% of target
        targetAmount * Decimal(0.25)
    }
}

// MARK: - Contribution Option

struct ContributionOption: Identifiable {
    let id = UUID()
    let percentage: Int
    let amount: Decimal

    var displayPercentage: String {
        "\(percentage)%"
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }

    static func options(for totalAmount: Decimal) -> [ContributionOption] {
        [25, 50, 75, 100].map { percentage in
            ContributionOption(
                percentage: percentage,
                amount: totalAmount * Decimal(percentage) / 100
            )
        }
    }
}

// MARK: - Flexible Swap Options

struct FlexibleSwapOptions: Codable {
    var extendedDeadlineDays: Int // Extra days beyond standard
    var allowPartialPayments: Bool
    var minimumPaymentUnit: Decimal // Smallest chunk allowed

    static var standard: FlexibleSwapOptions {
        FlexibleSwapOptions(
            extendedDeadlineDays: 0,
            allowPartialPayments: false,
            minimumPaymentUnit: 0
        )
    }

    static var flexible: FlexibleSwapOptions {
        FlexibleSwapOptions(
            extendedDeadlineDays: 14,
            allowPartialPayments: true,
            minimumPaymentUnit: 10
        )
    }
}

// MARK: - Priority Listing

struct PriorityListing: Codable {
    let swapId: UUID
    let userId: UUID
    var isActive: Bool
    var boostMultiplier: Double // 1.5x, 2x, etc.
    var expiresAt: Date
    var createdAt: Date

    var isExpired: Bool {
        Date() > expiresAt
    }

    var remainingTime: TimeInterval {
        expiresAt.timeIntervalSince(Date())
    }

    var formattedRemainingTime: String {
        let hours = Int(remainingTime / 3600)
        if hours > 24 {
            return "\(hours / 24)d left"
        } else if hours > 0 {
            return "\(hours)h left"
        } else {
            let minutes = Int(remainingTime / 60)
            return "\(max(0, minutes))m left"
        }
    }
}

// MARK: - Insert Structs

struct MultiPartySwapInsert: Codable {
    let swapType: String
    let status: String
    let organizerId: String
    let targetBillId: String?
    let targetAmount: Decimal
    let filledAmount: Decimal
    let minContribution: Decimal?
    let maxParticipants: Int
    let groupId: String?
    let executionDeadline: String?
    let tierRequired: Int

    enum CodingKeys: String, CodingKey {
        case swapType = "swap_type"
        case status
        case organizerId = "organizer_id"
        case targetBillId = "target_bill_id"
        case targetAmount = "target_amount"
        case filledAmount = "filled_amount"
        case minContribution = "min_contribution"
        case maxParticipants = "max_participants"
        case groupId = "group_id"
        case executionDeadline = "execution_deadline"
        case tierRequired = "tier_required"
    }
}

struct SwapParticipantInsert: Codable {
    let swapId: String
    let userId: String
    let billId: String?
    let contributionAmount: Decimal
    let status: String
    let feePaid: Bool

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case userId = "user_id"
        case billId = "bill_id"
        case contributionAmount = "contribution_amount"
        case status
        case feePaid = "fee_paid"
    }
}

struct MultiPartySwapUpdate: Codable {
    let filledAmount: Decimal
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case filledAmount = "filled_amount"
        case status
        case updatedAt = "updated_at"
    }
}

struct ParticipantVerificationUpdate: Codable {
    let screenshotVerified: Bool
    let status: String
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case screenshotVerified = "screenshot_verified"
        case status
        case completedAt = "completed_at"
    }
}

struct PriorityListingInsert: Codable {
    let swapId: String
    let userId: String
    let isActive: Bool
    let boostMultiplier: Double
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case userId = "user_id"
        case isActive = "is_active"
        case boostMultiplier = "boost_multiplier"
        case expiresAt = "expires_at"
    }
}

// MARK: - Swap Summary

struct MultiPartySwapSummary {
    let swap: MultiPartySwap
    let participants: [SwapParticipant]
    let organizerName: String?

    var participantCount: Int {
        participants.count
    }

    var confirmedCount: Int {
        participants.filter { $0.participantStatus == .confirmed || $0.participantStatus == .paid || $0.participantStatus == .verified }.count
    }

    var totalContributed: Decimal {
        participants
            .filter { $0.participantStatus == .verified }
            .reduce(Decimal(0)) { $0 + $1.contributionAmount }
    }
}

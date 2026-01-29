//
//  SwapDeal.swift
//  Billix
//
//  Deal Card model for structured swap negotiations
//

import Foundation

// MARK: - Payment Order

/// Determines who pays their partner's bill first in the swap
enum PaymentOrder: String, Codable, CaseIterable {
    case userAPaysFirst = "user_a_first"
    case userBPaysFirst = "user_b_first"
    case simultaneous = "simultaneous"

    var displayName: String {
        switch self {
        case .userAPaysFirst:
            return "You pay first"
        case .userBPaysFirst:
            return "Partner pays first"
        case .simultaneous:
            return "Pay at same time"
        }
    }

    var description: String {
        switch self {
        case .userAPaysFirst:
            return "You'll pay your partner's bill first, then they pay yours"
        case .userBPaysFirst:
            return "Your partner pays your bill first, then you pay theirs"
        case .simultaneous:
            return "Both parties pay within the same deadline window"
        }
    }

    /// Get display name from perspective of a specific user
    func displayName(isUserA: Bool) -> String {
        switch self {
        case .userAPaysFirst:
            return isUserA ? "You pay first" : "Partner pays first"
        case .userBPaysFirst:
            return isUserA ? "Partner pays first" : "You pay first"
        case .simultaneous:
            return "Pay at same time"
        }
    }
}

// MARK: - Proof Type

/// Type of payment proof required
enum ProofType: String, Codable, CaseIterable {
    case screenshot = "screenshot"
    case screenshotWithConfirmation = "screenshot_confirmation"

    var displayName: String {
        switch self {
        case .screenshot:
            return "Screenshot only"
        case .screenshotWithConfirmation:
            return "Screenshot + confirmation #"
        }
    }

    var description: String {
        switch self {
        case .screenshot:
            return "Payment screenshot showing amount and date"
        case .screenshotWithConfirmation:
            return "Screenshot plus confirmation/transaction number"
        }
    }

    var icon: String {
        switch self {
        case .screenshot:
            return "camera.fill"
        case .screenshotWithConfirmation:
            return "checkmark.seal.fill"
        }
    }
}

// MARK: - Fallback Action

/// What happens if a party fails to meet their deadline
enum FallbackAction: String, Codable, CaseIterable {
    case trustPointPenalty = "trust_penalty"
    case eligibilityLock = "eligibility_lock"
    case creditStake = "credit_stake"

    var displayName: String {
        switch self {
        case .trustPointPenalty:
            return "Trust point penalty"
        case .eligibilityLock:
            return "Swap eligibility lock"
        case .creditStake:
            return "Stake platform credits"
        }
    }

    var description: String {
        switch self {
        case .trustPointPenalty:
            return "Late party loses trust points (-10)"
        case .eligibilityLock:
            return "Late party can't start new swaps for 7 days"
        case .creditStake:
            return "Stake credits as trust deposit (returned on completion)"
        }
    }

    var icon: String {
        switch self {
        case .trustPointPenalty:
            return "star.slash.fill"
        case .eligibilityLock:
            return "lock.fill"
        case .creditStake:
            return "dollarsign.circle.fill"
        }
    }

    var shortName: String {
        switch self {
        case .trustPointPenalty:
            return "-10 Trust"
        case .eligibilityLock:
            return "7-day lock"
        case .creditStake:
            return "Credits"
        }
    }
}

// MARK: - Deal Status

/// Current status of the deal negotiation
enum DealStatus: String, Codable, CaseIterable {
    case proposed = "proposed"
    case countered = "countered"
    case accepted = "accepted"
    case rejected = "rejected"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .proposed:
            return "Proposed"
        case .countered:
            return "Counter-offer"
        case .accepted:
            return "Accepted"
        case .rejected:
            return "Rejected"
        case .expired:
            return "Expired"
        }
    }

    var color: String {
        switch self {
        case .proposed:
            return "#5BA4D4" // Info blue
        case .countered:
            return "#E8A54B" // Warning amber
        case .accepted:
            return "#4CAF7A" // Success green
        case .rejected:
            return "#E07A6B" // Danger red
        case .expired:
            return "#8B9A94" // Secondary gray
        }
    }

    var icon: String {
        switch self {
        case .proposed:
            return "paperplane.fill"
        case .countered:
            return "arrow.triangle.2.circlepath"
        case .accepted:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        case .expired:
            return "clock.badge.xmark.fill"
        }
    }
}

// MARK: - Swap Deal

/// A deal/terms proposal between two users in a swap
struct SwapDeal: Codable, Identifiable, Equatable {
    let id: UUID
    let swapId: UUID
    let proposerId: UUID
    let version: Int              // Increments with each counter-offer

    // Deal Terms
    var whoPaysFirst: PaymentOrder
    var amountA: Decimal          // Amount User A pays
    var amountB: Decimal          // Amount User B pays
    var deadlineA: Date           // When User A must pay
    var deadlineB: Date           // When User B must pay
    var proofRequired: ProofType
    var fallbackIfLate: FallbackAction

    // Status
    var status: DealStatus
    let createdAt: Date
    var respondedAt: Date?
    var expiresAt: Date           // 24h to respond

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case proposerId = "proposer_id"
        case version
        case whoPaysFirst = "who_pays_first"
        case amountA = "amount_a"
        case amountB = "amount_b"
        case deadlineA = "deadline_a"
        case deadlineB = "deadline_b"
        case proofRequired = "proof_required"
        case fallbackIfLate = "fallback_if_late"
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
        case expiresAt = "expires_at"
    }

    // MARK: - Computed Properties

    /// Check if the deal has expired
    var isExpired: Bool {
        Date() > expiresAt
    }

    /// Check if the deal is expiring soon (less than 3 hours remaining)
    var isExpiringSoon: Bool {
        guard let remaining = timeRemaining else { return false }
        return remaining < 3 * 60 * 60 // Less than 3 hours
    }

    /// Time remaining until expiration
    var timeRemaining: TimeInterval? {
        guard status == .proposed || status == .countered else { return nil }
        let remaining = expiresAt.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    /// Formatted time remaining (e.g., "23h 45m")
    var formattedTimeRemaining: String? {
        guard let remaining = timeRemaining, remaining > 0 else { return nil }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }

    /// Check if current user is the proposer
    func isProposer(userId: UUID) -> Bool {
        proposerId == userId
    }

    /// Check if current user can respond to the deal
    func canRespond(userId: UUID) -> Bool {
        !isProposer(userId: userId) && (status == .proposed || status == .countered) && !isExpired
    }

    /// Check if more counter-offers are allowed (max 3)
    var canCounter: Bool {
        version < 3 && !isExpired
    }

    /// Get deadline for a specific user
    func deadline(isUserA: Bool) -> Date {
        isUserA ? deadlineA : deadlineB
    }

    /// Get amount for a specific user
    func amount(isUserA: Bool) -> Decimal {
        isUserA ? amountA : amountB
    }

    /// Formatted amount for display
    func formattedAmount(isUserA: Bool) -> String {
        let value = amount(isUserA: isUserA)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0.00"
    }
}

// MARK: - Deal Terms Input

/// Input struct for creating/updating deal terms
struct DealTermsInput: Codable {
    var whoPaysFirst: PaymentOrder
    var amountA: Decimal
    var amountB: Decimal
    var deadlineA: Date
    var deadlineB: Date
    var proofRequired: ProofType
    var fallbackIfLate: FallbackAction

    /// Create default terms based on bills
    static func defaultTerms(
        myBillAmount: Decimal,
        partnerBillAmount: Decimal,
        isUserA: Bool
    ) -> DealTermsInput {
        let now = Date()
        let defaultDeadline = Calendar.current.date(byAdding: .hour, value: 48, to: now) ?? now

        return DealTermsInput(
            whoPaysFirst: .simultaneous,
            amountA: isUserA ? partnerBillAmount : myBillAmount,
            amountB: isUserA ? myBillAmount : partnerBillAmount,
            deadlineA: defaultDeadline,
            deadlineB: defaultDeadline,
            proofRequired: .screenshot,
            fallbackIfLate: .trustPointPenalty
        )
    }
}

// MARK: - Insert Model

/// Model for inserting new deals into Supabase
struct SwapDealInsert: Encodable {
    let swapId: UUID
    let proposerId: UUID
    let version: Int
    let whoPaysFirst: String
    let amountA: Decimal
    let amountB: Decimal
    let deadlineA: String  // ISO8601
    let deadlineB: String  // ISO8601
    let proofRequired: String
    let fallbackIfLate: String
    let status: String
    let expiresAt: String  // ISO8601

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case proposerId = "proposer_id"
        case version
        case whoPaysFirst = "who_pays_first"
        case amountA = "amount_a"
        case amountB = "amount_b"
        case deadlineA = "deadline_a"
        case deadlineB = "deadline_b"
        case proofRequired = "proof_required"
        case fallbackIfLate = "fallback_if_late"
        case status
        case expiresAt = "expires_at"
    }

    init(
        swapId: UUID,
        proposerId: UUID,
        terms: DealTermsInput,
        version: Int = 1
    ) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        self.swapId = swapId
        self.proposerId = proposerId
        self.version = version
        self.whoPaysFirst = terms.whoPaysFirst.rawValue
        self.amountA = terms.amountA
        self.amountB = terms.amountB
        self.deadlineA = formatter.string(from: terms.deadlineA)
        self.deadlineB = formatter.string(from: terms.deadlineB)
        self.proofRequired = terms.proofRequired.rawValue
        self.fallbackIfLate = terms.fallbackIfLate.rawValue
        self.status = DealStatus.proposed.rawValue

        // Expires 24h from now
        let expirationDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
        self.expiresAt = formatter.string(from: expirationDate)
    }
}

// MARK: - Mock Data

#if DEBUG
extension SwapDeal {
    static func mockDeal(
        swapId: UUID = UUID(),
        proposerId: UUID = UUID(),
        status: DealStatus = .proposed
    ) -> SwapDeal {
        let now = Date()
        return SwapDeal(
            id: UUID(),
            swapId: swapId,
            proposerId: proposerId,
            version: 1,
            whoPaysFirst: .simultaneous,
            amountA: Decimal(125.50),
            amountB: Decimal(118.75),
            deadlineA: Calendar.current.date(byAdding: .hour, value: 48, to: now) ?? now,
            deadlineB: Calendar.current.date(byAdding: .hour, value: 48, to: now) ?? now,
            proofRequired: .screenshot,
            fallbackIfLate: .trustPointPenalty,
            status: status,
            createdAt: now,
            respondedAt: nil,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: now) ?? now
        )
    }
}
#endif

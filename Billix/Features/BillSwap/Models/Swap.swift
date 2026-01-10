//
//  Swap.swift
//  Billix
//
//  Bill Swap Core Model with State Machine
//

import Foundation

// MARK: - Swap Type

enum BillSwapType: String, Codable, CaseIterable {
    case twoSided = "TWO_SIDED"
    case oneSidedAssist = "ONE_SIDED_ASSIST"

    var displayName: String {
        switch self {
        case .twoSided: return "Two-Way Swap"
        case .oneSidedAssist: return "One-Sided Assist"
        }
    }

    var description: String {
        switch self {
        case .twoSided: return "Both users pay each other's bills"
        case .oneSidedAssist: return "Helper pays your bill, you pay them back later"
        }
    }

    var icon: String {
        switch self {
        case .twoSided: return "arrow.left.arrow.right"
        case .oneSidedAssist: return "hand.raised"
        }
    }

    /// Facilitation fee for initiator in cents ($1.99)
    var initiatorFeeCents: Int {
        switch self {
        case .twoSided: return 199      // $1.99
        case .oneSidedAssist: return 0  // Free for recipient
        }
    }

    /// Facilitation fee for counterparty (helper) in cents ($1.99)
    var counterpartyFeeCents: Int {
        switch self {
        case .twoSided: return 199      // $1.99
        case .oneSidedAssist: return 199 // $1.99 for helper
        }
    }

    /// Formatted fee string
    var formattedFee: String {
        "$1.99"
    }
}

// MARK: - Fee Calculator

enum SwapFeeCalculator {
    /// Facilitation fee per user in cents
    static let facilitationFeeCents: Int = 199  // $1.99

    /// Spread fee percentage (for unequal bill amounts)
    static let spreadFeePercentage: Double = 0.03  // 3%

    /// Calculate spread fee for unequal bills
    static func calculateSpreadFee(billACents: Int, billBCents: Int) -> Int {
        let difference = abs(billACents - billBCents)
        return Int(Double(difference) * spreadFeePercentage)
    }

    /// Calculate total fees for a swap
    static func calculateTotalFees(billACents: Int, billBCents: Int?, swapType: BillSwapType) -> SwapFees {
        let spreadFee: Int
        if let billBCents = billBCents {
            spreadFee = calculateSpreadFee(billACents: billACents, billBCents: billBCents)
        } else {
            spreadFee = 0
        }

        let initiatorFee = swapType.initiatorFeeCents
        let counterpartyFee = swapType.counterpartyFeeCents

        return SwapFees(
            facilitationFeeInitiator: initiatorFee,
            facilitationFeeCounterparty: counterpartyFee,
            spreadFee: spreadFee,
            totalInitiator: initiatorFee + (spreadFee / 2),
            totalCounterparty: counterpartyFee + (spreadFee / 2)
        )
    }
}

/// Fee breakdown for a swap
struct SwapFees {
    let facilitationFeeInitiator: Int
    let facilitationFeeCounterparty: Int
    let spreadFee: Int
    let totalInitiator: Int
    let totalCounterparty: Int

    var totalAllFees: Int {
        totalInitiator + totalCounterparty
    }

    var formattedInitiatorFee: String {
        String(format: "$%.2f", Double(totalInitiator) / 100.0)
    }

    var formattedCounterpartyFee: String {
        String(format: "$%.2f", Double(totalCounterparty) / 100.0)
    }

    var formattedSpreadFee: String {
        String(format: "$%.2f", Double(spreadFee) / 100.0)
    }
}

// MARK: - Swap Status (10-State Machine)

enum BillSwapStatus: String, Codable, CaseIterable {
    case offered = "OFFERED"
    case countered = "COUNTERED"
    case acceptedPendingFee = "ACCEPTED_PENDING_FEE"
    case locked = "LOCKED"
    case awaitingProof = "AWAITING_PROOF"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case disputed = "DISPUTED"
    case cancelled = "CANCELLED"
    case expired = "EXPIRED"

    var displayName: String {
        switch self {
        case .offered: return "Offered"
        case .countered: return "Counter Offered"
        case .acceptedPendingFee: return "Pending Fee"
        case .locked: return "Locked"
        case .awaitingProof: return "Awaiting Proof"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .disputed: return "Disputed"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        }
    }

    var icon: String {
        switch self {
        case .offered: return "arrow.right.circle"
        case .countered: return "arrow.left.arrow.right"
        case .acceptedPendingFee: return "creditcard"
        case .locked: return "lock.fill"
        case .awaitingProof: return "doc.badge.clock"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .disputed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle"
        case .expired: return "clock.badge.xmark"
        }
    }

    var color: String {
        switch self {
        case .offered: return "#5BA4D4"       // Blue
        case .countered: return "#9B59B6"     // Purple
        case .acceptedPendingFee: return "#F5A623"  // Orange
        case .locked: return "#2ECC71"        // Green
        case .awaitingProof: return "#F5A623" // Orange
        case .completed: return "#27AE60"     // Dark Green
        case .failed: return "#E74C3C"        // Red
        case .disputed: return "#E67E22"      // Dark Orange
        case .cancelled: return "#8B9A94"     // Gray
        case .expired: return "#8B9A94"       // Gray
        }
    }

    /// Is this an active (non-terminal) state?
    var isActive: Bool {
        switch self {
        case .offered, .countered, .acceptedPendingFee, .locked, .awaitingProof, .disputed:
            return true
        default:
            return false
        }
    }

    /// Is this a terminal state?
    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled, .expired:
            return true
        default:
            return false
        }
    }

    /// Valid transitions from this state
    var validTransitions: [BillSwapStatus] {
        switch self {
        case .offered:
            return [.acceptedPendingFee, .countered, .cancelled, .expired]
        case .countered:
            return [.acceptedPendingFee, .countered, .cancelled, .expired]
        case .acceptedPendingFee:
            return [.locked, .cancelled, .expired]
        case .locked:
            return [.awaitingProof]
        case .awaitingProof:
            return [.completed, .failed, .disputed]
        case .disputed:
            return [.completed, .failed]
        case .completed, .failed, .cancelled, .expired:
            return [] // Terminal states
        }
    }
}

// MARK: - Bill Swap Model

struct BillSwap: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let swapType: BillSwapType
    var status: BillSwapStatus

    // Participants
    let initiatorUserId: UUID
    var counterpartyUserId: UUID?

    // Bills
    let billAId: UUID
    var billBId: UUID?

    // Counter offer
    var counterOfferAmountCents: Int?
    var counterOfferByUserId: UUID?

    // Fees (in cents) - $1.99 = 199 cents per user
    let feeAmountCentsInitiator: Int
    let feeAmountCentsCounterparty: Int
    var spreadFeeCents: Int  // 3% of bill difference
    var feePaidInitiator: Bool
    var feePaidCounterparty: Bool
    var pointsWaiverInitiator: Bool
    var pointsWaiverCounterparty: Bool

    // Deadlines
    var acceptDeadline: Date?
    var proofDueDeadline: Date?

    // Timestamps
    let createdAt: Date
    var updatedAt: Date
    var acceptedAt: Date?
    var lockedAt: Date?
    var completedAt: Date?

    // Associated data (not from DB)
    var billA: SwapBill?
    var billB: SwapBill?
    var initiatorProfile: TrustProfile?
    var counterpartyProfile: TrustProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case swapType = "swap_type"
        case status
        case initiatorUserId = "initiator_user_id"
        case counterpartyUserId = "counterparty_user_id"
        case billAId = "bill_a_id"
        case billBId = "bill_b_id"
        case counterOfferAmountCents = "counter_offer_amount_cents"
        case counterOfferByUserId = "counter_offer_by_user_id"
        case feeAmountCentsInitiator = "fee_amount_cents_initiator"
        case feeAmountCentsCounterparty = "fee_amount_cents_counterparty"
        case spreadFeeCents = "spread_fee_cents"
        case feePaidInitiator = "fee_paid_initiator"
        case feePaidCounterparty = "fee_paid_counterparty"
        case pointsWaiverInitiator = "points_waiver_initiator"
        case pointsWaiverCounterparty = "points_waiver_counterparty"
        case acceptDeadline = "accept_deadline"
        case proofDueDeadline = "proof_due_deadline"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case acceptedAt = "accepted_at"
        case lockedAt = "locked_at"
        case completedAt = "completed_at"
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: BillSwap, rhs: BillSwap) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    /// Total fee in cents
    var totalFeeCents: Int {
        feeAmountCentsInitiator + feeAmountCentsCounterparty
    }

    /// Are both fees paid (or waived)?
    var bothFeesPaid: Bool {
        let initiatorPaid = feePaidInitiator || pointsWaiverInitiator
        let counterpartyPaid = feePaidCounterparty || pointsWaiverCounterparty || swapType == .oneSidedAssist
        return initiatorPaid && counterpartyPaid
    }

    /// Is the swap expired based on deadline?
    var isExpired: Bool {
        if let deadline = acceptDeadline, status == .offered || status == .countered {
            return Date() > deadline
        }
        if let deadline = proofDueDeadline, status == .awaitingProof {
            return Date() > deadline
        }
        return status == .expired
    }

    /// Is chat enabled for this swap?
    var isChatEnabled: Bool {
        switch status {
        case .offered, .countered, .cancelled, .expired:
            return false
        default:
            return true
        }
    }

    /// Can current user accept this swap?
    func canAccept(currentUserId: UUID) -> Bool {
        guard status == .offered || status == .countered else { return false }
        guard !isExpired else { return false }

        // Initiator can accept counter offer
        if status == .countered && initiatorUserId == currentUserId {
            return counterOfferByUserId != currentUserId
        }

        // Counterparty can accept offer
        return counterpartyUserId == currentUserId || counterpartyUserId == nil
    }

    /// Can current user cancel this swap?
    func canCancel(currentUserId: UUID) -> Bool {
        guard status.isActive else { return false }
        return initiatorUserId == currentUserId || counterpartyUserId == currentUserId
    }

    // MARK: - State Transition

    func canTransition(to newStatus: BillSwapStatus) -> Bool {
        status.validTransitions.contains(newStatus)
    }

    mutating func transition(to newStatus: BillSwapStatus) throws {
        guard canTransition(to: newStatus) else {
            throw BillSwapError.invalidTransition(from: status, to: newStatus)
        }
        status = newStatus
        updatedAt = Date()
    }
}

// MARK: - Bill Swap Error

enum BillSwapError: LocalizedError {
    case notAuthenticated
    case swapNotFound
    case billNotFound
    case invalidTransition(from: BillSwapStatus, to: BillSwapStatus)
    case tierCapExceeded(maxCents: Int)
    case maxActiveSwapsReached(max: Int)
    case billNotAvailable
    case cannotSwapOwnBill
    case insufficientPoints
    case proofRequired
    case proofRejected
    case disputeWindowExpired
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in"
        case .swapNotFound:
            return "Swap not found"
        case .billNotFound:
            return "Bill not found"
        case .invalidTransition(let from, let to):
            return "Cannot change status from \(from.displayName) to \(to.displayName)"
        case .tierCapExceeded(let maxCents):
            return "Bill amount exceeds your tier limit of $\(maxCents / 100)"
        case .maxActiveSwapsReached(let max):
            return "You've reached the maximum of \(max) active swaps for your tier"
        case .billNotAvailable:
            return "This bill is no longer available"
        case .cannotSwapOwnBill:
            return "You cannot swap your own bill"
        case .insufficientPoints:
            return "Not enough points to waive fee"
        case .proofRequired:
            return "Payment proof is required"
        case .proofRejected:
            return "Your payment proof was rejected"
        case .disputeWindowExpired:
            return "The dispute window has expired"
        case .operationFailed(let message):
            return message
        }
    }
}

// MARK: - Create Swap Request

struct CreateSwapRequest: Codable {
    let billAId: UUID
    let billBId: UUID?
    let counterpartyUserId: UUID?
    let swapType: BillSwapType

    enum CodingKeys: String, CodingKey {
        case billAId = "bill_a_id"
        case billBId = "bill_b_id"
        case counterpartyUserId = "counterparty_user_id"
        case swapType = "swap_type"
    }
}

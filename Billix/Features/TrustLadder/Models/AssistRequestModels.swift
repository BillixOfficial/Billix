//
//  AssistRequestModels.swift
//  Billix
//
//  Created by Claude Code on 12/31/24.
//  Data models for the Bill Assist peer-to-peer assistance feature
//

import Foundation
import SwiftUI

// MARK: - Assist Type

/// The type of assistance being requested/offered
enum AssistType: String, Codable, CaseIterable {
    case gift = "gift"              // No repayment expected
    case loan = "loan"              // Full repayment expected
    case partialGift = "partial"    // Partial repayment (helper forgives some)

    var displayName: String {
        switch self {
        case .gift: return "Gift"
        case .loan: return "Loan"
        case .partialGift: return "Partial Gift"
        }
    }

    var description: String {
        switch self {
        case .gift: return "No repayment expected"
        case .loan: return "Full repayment with optional interest"
        case .partialGift: return "Partial repayment agreed upon"
        }
    }

    var icon: String {
        switch self {
        case .gift: return "gift.fill"
        case .loan: return "arrow.left.arrow.right"
        case .partialGift: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .gift: return .pink
        case .loan: return .blue
        case .partialGift: return .purple
        }
    }
}

// MARK: - Assist Urgency

/// How urgent the bill assistance request is
enum AssistUrgency: String, Codable, CaseIterable {
    case low = "low"            // Due in 7+ days
    case medium = "medium"      // Due in 3-7 days
    case high = "high"          // Due in 1-2 days
    case critical = "critical"  // Due today or overdue

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    var description: String {
        switch self {
        case .low: return "Due in 7+ days"
        case .medium: return "Due in 3-7 days"
        case .high: return "Due in 1-2 days"
        case .critical: return "Due today or overdue"
        }
    }

    var icon: String {
        switch self {
        case .low: return "clock"
        case .medium: return "clock.badge"
        case .high: return "exclamationmark.clock"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }

    /// Sort order for display (lower = more urgent = shown first)
    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }

    /// Calculate urgency based on days until due
    static func fromDaysUntilDue(_ days: Int) -> AssistUrgency {
        switch days {
        case ..<0: return .critical  // Overdue
        case 0...1: return .critical
        case 2: return .high
        case 3...7: return .medium
        default: return .low
        }
    }
}

// MARK: - Assist Request Status

/// Status flow for an assist request
enum AssistRequestStatus: String, Codable, CaseIterable {
    case draft = "draft"                    // Not yet published
    case active = "active"                  // Seeking helper
    case matched = "matched"                // Helper found, pending fee payment
    case feePending = "fee_pending"         // Waiting for connection fees
    case feePaid = "fee_paid"               // Both paid, ready for negotiation
    case negotiating = "negotiating"        // In chat, working out terms
    case termsAccepted = "terms_accepted"   // Both agreed on terms
    case paymentPending = "payment_pending" // Waiting for helper to pay bill
    case paymentSent = "payment_sent"       // Helper paid, awaiting verification
    case completed = "completed"            // Screenshot verified, done
    case repaying = "repaying"              // In repayment period (if loan)
    case repaid = "repaid"                  // Loan fully repaid
    case disputed = "disputed"              // Issue reported
    case cancelled = "cancelled"            // Cancelled by requester
    case expired = "expired"                // Timed out
    case failed = "failed"                  // Failed (ghost, etc.)

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Seeking Help"
        case .matched: return "Matched"
        case .feePending: return "Fee Pending"
        case .feePaid: return "Ready to Negotiate"
        case .negotiating: return "Negotiating"
        case .termsAccepted: return "Terms Accepted"
        case .paymentPending: return "Awaiting Payment"
        case .paymentSent: return "Verifying Payment"
        case .completed: return "Completed"
        case .repaying: return "In Repayment"
        case .repaid: return "Fully Repaid"
        case .disputed: return "Disputed"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        case .failed: return "Failed"
        }
    }

    var color: Color {
        switch self {
        case .draft: return .gray
        case .active: return .blue
        case .matched, .feePending, .feePaid: return .orange
        case .negotiating, .termsAccepted: return .purple
        case .paymentPending, .paymentSent: return .yellow
        case .completed, .repaid: return .green
        case .repaying: return .teal
        case .disputed, .failed: return .red
        case .cancelled, .expired: return .gray
        }
    }

    var isActive: Bool {
        switch self {
        case .active, .matched, .feePending, .feePaid, .negotiating,
             .termsAccepted, .paymentPending, .paymentSent, .repaying:
            return true
        default:
            return false
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .repaid, .cancelled, .expired, .failed:
            return true
        default:
            return false
        }
    }

    /// Sort order for grouping display (active first, then completed, then terminal)
    var sortOrder: Int {
        switch self {
        case .draft: return 0
        case .active: return 1
        case .matched: return 2
        case .feePending: return 3
        case .feePaid: return 4
        case .negotiating: return 5
        case .termsAccepted: return 6
        case .paymentPending: return 7
        case .paymentSent: return 8
        case .repaying: return 9
        case .completed: return 10
        case .repaid: return 11
        case .disputed: return 12
        case .cancelled: return 13
        case .expired: return 14
        case .failed: return 15
        }
    }
}

// MARK: - Offer Status

enum AssistOfferStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case withdrawn = "withdrawn"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .rejected: return "Declined"
        case .withdrawn: return "Withdrawn"
        case .expired: return "Expired"
        }
    }
}

// MARK: - Repayment Terms

/// Terms negotiated between requester and helper
struct RepaymentTerms: Codable, Equatable {
    var assistType: AssistType
    var interestRate: Double?           // Optional APR (e.g., 0.05 = 5%)
    var repaymentDate: Date?            // When full repayment is due
    var installmentCount: Int?          // Number of payments (if installments)
    var installmentAmount: Double?      // Amount per installment
    var gracePeriodDays: Int?           // Days before late fees apply
    var notes: String?                  // Additional terms/notes

    enum CodingKeys: String, CodingKey {
        case assistType = "assist_type"
        case interestRate = "interest_rate"
        case repaymentDate = "repayment_date"
        case installmentCount = "installment_count"
        case installmentAmount = "installment_amount"
        case gracePeriodDays = "grace_period_days"
        case notes
    }

    /// Calculate total repayment amount including interest
    func totalRepaymentAmount(principal: Double) -> Double {
        guard assistType == .loan else {
            return assistType == .gift ? 0 : principal * 0.5 // partialGift defaults to 50%
        }

        let interest = interestRate ?? 0
        return principal * (1 + interest)
    }

    /// Format terms for display
    var formattedSummary: String {
        switch assistType {
        case .gift:
            return "Gift - No repayment"
        case .loan:
            var summary = "Loan"
            if let rate = interestRate, rate > 0 {
                summary += " @ \(Int(rate * 100))% interest"
            }
            if let date = repaymentDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                summary += " due \(formatter.string(from: date))"
            }
            return summary
        case .partialGift:
            return "Partial repayment"
        }
    }

    /// Default gift terms
    static var giftDefault: RepaymentTerms {
        RepaymentTerms(assistType: .gift)
    }

    /// Default loan terms (no interest, 30 days)
    static func loanDefault(repaymentDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date())!) -> RepaymentTerms {
        RepaymentTerms(assistType: .loan, interestRate: 0, repaymentDate: repaymentDate)
    }
}

// MARK: - Assist Request

/// Main model for a bill assistance request
struct AssistRequest: Identifiable, Codable, Equatable {
    let id: UUID
    let requesterId: UUID
    var status: AssistRequestStatus

    // Bill Info
    var billId: UUID?
    var billCategory: String
    var billProvider: String
    var billAmount: Double
    var billDueDate: Date
    var billScreenshotUrl: String?
    var billScreenshotVerified: Bool

    // Request Details
    var amountRequested: Double
    var urgency: AssistUrgency
    var description: String?
    var preferredTerms: RepaymentTerms?

    // Helper (once matched)
    var helperId: UUID?
    var agreedTerms: RepaymentTerms?
    var matchedAt: Date?

    // Fee Tracking
    var requesterFeePaid: Bool
    var helperFeePaid: Bool
    var requesterFeeTransactionId: String?
    var helperFeeTransactionId: String?

    // Payment Proof
    var paymentScreenshotUrl: String?
    var paymentVerified: Bool
    var paymentVerifiedAt: Date?

    // Ratings
    var requesterRating: Int?
    var helperRating: Int?
    var requesterReview: String?
    var helperReview: String?

    // Repayment Tracking (for loans)
    var totalRepaid: Double
    var lastRepaymentAt: Date?

    // Timestamps
    let createdAt: Date
    var updatedAt: Date
    var expiresAt: Date?
    var completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case status
        case billId = "bill_id"
        case billCategory = "bill_category"
        case billProvider = "bill_provider"
        case billAmount = "bill_amount"
        case billDueDate = "bill_due_date"
        case billScreenshotUrl = "bill_screenshot_url"
        case billScreenshotVerified = "bill_screenshot_verified"
        case amountRequested = "amount_requested"
        case urgency
        case description
        case preferredTerms = "preferred_terms"
        case helperId = "helper_id"
        case agreedTerms = "agreed_terms"
        case matchedAt = "matched_at"
        case requesterFeePaid = "requester_fee_paid"
        case helperFeePaid = "helper_fee_paid"
        case requesterFeeTransactionId = "requester_fee_transaction_id"
        case helperFeeTransactionId = "helper_fee_transaction_id"
        case paymentScreenshotUrl = "payment_screenshot_url"
        case paymentVerified = "payment_verified"
        case paymentVerifiedAt = "payment_verified_at"
        case requesterRating = "requester_rating"
        case helperRating = "helper_rating"
        case requesterReview = "requester_review"
        case helperReview = "helper_review"
        case totalRepaid = "total_repaid"
        case lastRepaymentAt = "last_repayment_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires_at"
        case completedAt = "completed_at"
    }

    // MARK: - Computed Properties

    var bothFeesPaid: Bool {
        requesterFeePaid && helperFeePaid
    }

    var isLoan: Bool {
        agreedTerms?.assistType == .loan || preferredTerms?.assistType == .loan
    }

    var repaymentProgress: Double {
        guard isLoan, let terms = agreedTerms else { return 0 }
        let totalDue = terms.totalRepaymentAmount(principal: amountRequested)
        guard totalDue > 0 else { return 1.0 }
        return min(1.0, totalRepaid / totalDue)
    }

    var remainingRepayment: Double {
        guard isLoan, let terms = agreedTerms else { return 0 }
        let totalDue = terms.totalRepaymentAmount(principal: amountRequested)
        return max(0, totalDue - totalRepaid)
    }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: billDueDate).day ?? 0
    }

    var isOverdue: Bool {
        daysUntilDue < 0
    }

    /// Connection fee based on amount requested
    var connectionFee: Double {
        AssistConnectionFeeTier.fee(for: amountRequested)
    }

    var connectionFeeTier: AssistConnectionFeeTier {
        AssistConnectionFeeTier.tier(for: amountRequested)
    }
}

// MARK: - Assist Offer

/// An offer from a potential helper
struct AssistOffer: Identifiable, Codable, Equatable {
    let id: UUID
    let assistRequestId: UUID
    let offererId: UUID
    var proposedTerms: RepaymentTerms
    var message: String?
    var status: AssistOfferStatus
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case assistRequestId = "assist_request_id"
        case offererId = "offerer_id"
        case proposedTerms = "proposed_terms"
        case message
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Assist Message

/// In-app message for negotiation
struct AssistMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let assistRequestId: UUID
    let senderId: UUID
    var messageType: AssistMessageType
    var content: String?
    var termsData: RepaymentTerms?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case assistRequestId = "assist_request_id"
        case senderId = "sender_id"
        case messageType = "message_type"
        case content
        case termsData = "terms_data"
        case createdAt = "created_at"
    }
}

enum AssistMessageType: String, Codable {
    case text = "text"
    case termsProposal = "terms_proposal"
    case termsAccepted = "terms_accepted"
    case termsRejected = "terms_rejected"
    case system = "system"
    case paymentSent = "payment_sent"
    case paymentVerified = "payment_verified"
    case repaymentReceived = "repayment_received"
}

// MARK: - Assist Repayment

/// Record of a repayment (for loans)
struct AssistRepayment: Identifiable, Codable, Equatable {
    let id: UUID
    let assistRequestId: UUID
    let payerId: UUID
    var amount: Double
    var paymentMethod: String?
    var screenshotUrl: String?
    var verified: Bool
    var verifiedAt: Date?
    var notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case assistRequestId = "assist_request_id"
        case payerId = "payer_id"
        case amount
        case paymentMethod = "payment_method"
        case screenshotUrl = "screenshot_url"
        case verified
        case verifiedAt = "verified_at"
        case notes
        case createdAt = "created_at"
    }
}

// MARK: - Connection Fee Tiers

/// Tiered connection fees based on amount requested
enum AssistConnectionFeeTier: String, CaseIterable {
    case small = "small"     // < $50 = $0.99
    case medium = "medium"   // $50-149.99 = $1.99
    case large = "large"     // >= $150 = $2.99

    var fee: Double {
        switch self {
        case .small: return 0.99
        case .medium: return 1.99
        case .large: return 2.99
        }
    }

    var productId: String {
        switch self {
        case .small: return "com.billix.assist.fee.small"
        case .medium: return "com.billix.assist.fee.medium"
        case .large: return "com.billix.assist.fee.large"
        }
    }

    var amountRange: String {
        switch self {
        case .small: return "Under $50"
        case .medium: return "$50 - $149.99"
        case .large: return "$150+"
        }
    }

    var formattedFee: String {
        "$\(String(format: "%.2f", fee))"
    }

    static func tier(for amount: Double) -> AssistConnectionFeeTier {
        switch amount {
        case ..<50: return .small
        case 50..<150: return .medium
        default: return .large
        }
    }

    static func fee(for amount: Double) -> Double {
        tier(for: amount).fee
    }
}

// MARK: - Assist Dispute

/// Dispute filed for an assist request
struct AssistDispute: Identifiable, Codable, Equatable {
    let id: UUID
    let assistRequestId: UUID
    let reportedBy: UUID
    var reason: AssistDisputeReason
    var description: String?
    var status: DisputeStatus
    var resolution: String?
    var resolvedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case assistRequestId = "assist_request_id"
        case reportedBy = "reported_by"
        case reason
        case description
        case status
        case resolution
        case resolvedAt = "resolved_at"
        case createdAt = "created_at"
    }
}

enum AssistDisputeReason: String, Codable, CaseIterable {
    case ghost = "ghost"                    // Helper/requester disappeared
    case fakeScreenshot = "fake_screenshot" // Fraudulent payment proof
    case wrongAmount = "wrong_amount"       // Paid wrong amount
    case wrongProvider = "wrong_provider"   // Paid wrong bill
    case noRepayment = "no_repayment"       // Loan not being repaid
    case harassment = "harassment"          // Inappropriate messages
    case scam = "scam"                      // Attempted scam
    case other = "other"

    var displayName: String {
        switch self {
        case .ghost: return "No Response"
        case .fakeScreenshot: return "Fake Payment Proof"
        case .wrongAmount: return "Wrong Amount Paid"
        case .wrongProvider: return "Wrong Bill Paid"
        case .noRepayment: return "Missing Repayment"
        case .harassment: return "Harassment"
        case .scam: return "Scam Attempt"
        case .other: return "Other Issue"
        }
    }
}

enum DisputeStatus: String, Codable {
    case open = "open"
    case investigating = "investigating"
    case resolved = "resolved"
    case dismissed = "dismissed"
}

// MARK: - User Assist Stats Extension

/// Extension to track assist-specific stats on UserTrustStatus
struct UserAssistStats: Codable, Equatable {
    var totalAssistsGiven: Int
    var totalAssistsReceived: Int
    var assistRatingAsHelper: Double?
    var assistRatingAsRequester: Double?
    var totalAmountAssisted: Double
    var successfulRepayments: Int
    var failedRepayments: Int

    enum CodingKeys: String, CodingKey {
        case totalAssistsGiven = "total_assists_given"
        case totalAssistsReceived = "total_assists_received"
        case assistRatingAsHelper = "assist_rating_as_helper"
        case assistRatingAsRequester = "assist_rating_as_requester"
        case totalAmountAssisted = "total_amount_assisted"
        case successfulRepayments = "successful_repayments"
        case failedRepayments = "failed_repayments"
    }

    static var empty: UserAssistStats {
        UserAssistStats(
            totalAssistsGiven: 0,
            totalAssistsReceived: 0,
            assistRatingAsHelper: nil,
            assistRatingAsRequester: nil,
            totalAmountAssisted: 0,
            successfulRepayments: 0,
            failedRepayments: 0
        )
    }
}

// MARK: - Eligibility Check Result

/// Result of checking if user can request/offer assist
struct AssistEligibility {
    var canRequest: Bool
    var canOffer: Bool
    var reasons: [String]

    var isFullyEligible: Bool {
        canRequest && canOffer
    }

    static var eligible: AssistEligibility {
        AssistEligibility(canRequest: true, canOffer: true, reasons: [])
    }

    static func ineligible(reasons: [String]) -> AssistEligibility {
        AssistEligibility(canRequest: false, canOffer: false, reasons: reasons)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension AssistRequest {
    static var preview: AssistRequest {
        AssistRequest(
            id: UUID(),
            requesterId: UUID(),
            status: .active,
            billId: nil,
            billCategory: "Electric",
            billProvider: "DTE Energy",
            billAmount: 145.50,
            billDueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            billScreenshotUrl: nil,
            billScreenshotVerified: false,
            amountRequested: 145.50,
            urgency: .medium,
            description: "Need help with my electric bill this month. Lost some hours at work.",
            preferredTerms: .loanDefault(),
            helperId: nil,
            agreedTerms: nil,
            matchedAt: nil,
            requesterFeePaid: false,
            helperFeePaid: false,
            requesterFeeTransactionId: nil,
            helperFeeTransactionId: nil,
            paymentScreenshotUrl: nil,
            paymentVerified: false,
            paymentVerifiedAt: nil,
            requesterRating: nil,
            helperRating: nil,
            requesterReview: nil,
            helperReview: nil,
            totalRepaid: 0,
            lastRepaymentAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            completedAt: nil
        )
    }

    static var previewCritical: AssistRequest {
        var request = preview
        request.urgency = .critical
        request.billDueDate = Date()
        request.billAmount = 89.99
        request.amountRequested = 89.99
        request.billProvider = "Xfinity"
        request.billCategory = "Internet"
        return request
    }
}

extension AssistOffer {
    static var preview: AssistOffer {
        AssistOffer(
            id: UUID(),
            assistRequestId: UUID(),
            offererId: UUID(),
            proposedTerms: .loanDefault(),
            message: "Happy to help! I can cover this for you.",
            status: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
#endif

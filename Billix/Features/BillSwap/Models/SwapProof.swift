//
//  SwapProof.swift
//  Billix
//
//  Bill Swap Payment Proof Model
//

import Foundation

// MARK: - Proof Type

enum SwapProofType: String, Codable, CaseIterable {
    case screenshot = "SCREENSHOT"
    case emailForward = "EMAIL_FORWARD"
    case bankStatement = "BANK_STATEMENT"
    case pdfReceipt = "PDF_RECEIPT"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .screenshot: return "Screenshot"
        case .emailForward: return "Email Confirmation"
        case .bankStatement: return "Bank Statement"
        case .pdfReceipt: return "PDF Receipt"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .screenshot: return "camera.fill"
        case .emailForward: return "envelope.fill"
        case .bankStatement: return "building.columns.fill"
        case .pdfReceipt: return "doc.fill"
        case .other: return "doc.text.fill"
        }
    }

    var description: String {
        switch self {
        case .screenshot: return "Screenshot of payment confirmation"
        case .emailForward: return "Email receipt from provider"
        case .bankStatement: return "Bank transaction showing payment"
        case .pdfReceipt: return "PDF receipt from provider"
        case .other: return "Other proof of payment"
        }
    }
}

// MARK: - Proof Status

enum SwapProofStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case pendingReview = "PENDING_REVIEW"
    case accepted = "ACCEPTED"
    case autoAccepted = "AUTO_ACCEPTED"
    case rejected = "REJECTED"
    case resubmitted = "RESUBMITTED"

    var displayName: String {
        switch self {
        case .pending, .pendingReview: return "Pending Review"
        case .accepted: return "Accepted"
        case .autoAccepted: return "Auto-Accepted"
        case .rejected: return "Rejected"
        case .resubmitted: return "Resubmitted"
        }
    }

    var icon: String {
        switch self {
        case .pending, .pendingReview: return "clock.fill"
        case .accepted, .autoAccepted: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .resubmitted: return "arrow.counterclockwise"
        }
    }

    var color: String {
        switch self {
        case .pending, .pendingReview: return "#F5A623"  // Orange
        case .accepted, .autoAccepted: return "#27AE60"  // Green
        case .rejected: return "#E74C3C"                  // Red
        case .resubmitted: return "#3498DB"               // Blue
        }
    }
}

// MARK: - Proof Rejection Reason

enum SwapProofRejectionReason: String, Codable, CaseIterable {
    case unclear = "UNCLEAR"
    case wrongAmount = "WRONG_AMOUNT"
    case wrongDate = "WRONG_DATE"
    case wrongRecipient = "WRONG_RECIPIENT"
    case insufficientProof = "INSUFFICIENT_PROOF"
    case suspectedFraud = "SUSPECTED_FRAUD"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .unclear: return "Unclear/Unreadable"
        case .wrongAmount: return "Wrong Amount"
        case .wrongDate: return "Wrong Date"
        case .wrongRecipient: return "Wrong Recipient"
        case .insufficientProof: return "Insufficient Proof"
        case .suspectedFraud: return "Suspected Fraud"
        case .other: return "Other"
        }
    }

    var description: String {
        switch self {
        case .unclear: return "The proof is blurry, cut off, or hard to read"
        case .wrongAmount: return "The payment amount doesn't match the bill"
        case .wrongDate: return "The payment date is too old or doesn't match"
        case .wrongRecipient: return "The payment was made to a different recipient"
        case .insufficientProof: return "More details are needed to verify payment"
        case .suspectedFraud: return "The proof appears to be altered or fake"
        case .other: return "Another issue with the proof"
        }
    }
}

// MARK: - Swap Proof Model

struct SwapProof: Identifiable, Codable, Equatable {
    let id: UUID
    let swapId: UUID
    let userId: UUID
    let billId: UUID
    let proofType: SwapProofType
    let fileUrl: String
    var notes: String?
    var status: SwapProofStatus
    var reviewedByUserId: UUID?
    var rejectionReason: String?
    var resubmissionCount: Int
    var originalProofId: UUID?
    var reviewDeadline: Date?
    let submittedAt: Date
    var reviewedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case userId = "user_id"
        case billId = "bill_id"
        case proofType = "proof_type"
        case fileUrl = "file_url"
        case notes
        case status
        case reviewedByUserId = "reviewed_by_user_id"
        case rejectionReason = "rejection_reason"
        case resubmissionCount = "resubmission_count"
        case originalProofId = "original_proof_id"
        case reviewDeadline = "review_deadline"
        case submittedAt = "submitted_at"
        case reviewedAt = "reviewed_at"
    }

    // MARK: - Computed Properties

    /// Can this proof be resubmitted?
    var canResubmit: Bool {
        status == .rejected && resubmissionCount < 1
    }

    /// Is this a resubmission?
    var isResubmission: Bool {
        originalProofId != nil
    }

    /// Formatted submission date
    var formattedSubmittedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: submittedAt)
    }

    /// Time remaining for review (in hours)
    var hoursUntilReviewDeadline: Int? {
        guard let deadline = reviewDeadline else { return nil }
        let hours = Calendar.current.dateComponents([.hour], from: Date(), to: deadline).hour
        return hours
    }

    /// Is review deadline approaching?
    var isReviewDeadlineApproaching: Bool {
        guard let hours = hoursUntilReviewDeadline else { return false }
        return hours <= 4 && hours >= 0
    }

    /// Is review overdue?
    var isReviewOverdue: Bool {
        guard let deadline = reviewDeadline else { return false }
        return Date() > deadline && status == .pendingReview
    }
}

// MARK: - Upload Proof Request

struct UploadProofRequest: Codable {
    let swapId: UUID
    let billId: UUID
    let proofType: SwapProofType
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case billId = "bill_id"
        case proofType = "proof_type"
        case notes
    }
}

// MARK: - Review Proof Request

struct ReviewProofRequest: Codable {
    let proofId: UUID
    let accepted: Bool
    let rejectionReason: String?

    enum CodingKeys: String, CodingKey {
        case proofId = "proof_id"
        case accepted
        case rejectionReason = "rejection_reason"
    }
}

// MARK: - Proof Error

// MARK: - Proof Constants

enum ProofConstants {
    static let maxResubmissions = 2
    static let reviewDeadlineHours = 12
    static let autoAcceptAfterHours = 24
}

enum SwapProofError: LocalizedError {
    case notAuthenticated
    case uploadFailed
    case invalidProofType
    case fileTooLarge
    case cannotResubmit
    case reviewFailed
    case proofNotFound
    case notAuthorizedToReview
    case maxResubmissionsReached
    case submitFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in"
        case .uploadFailed:
            return "Failed to upload proof"
        case .invalidProofType:
            return "Invalid proof type"
        case .fileTooLarge:
            return "File is too large (max 10MB)"
        case .maxResubmissionsReached:
            return "Maximum resubmission attempts reached"
        case .submitFailed:
            return "Failed to submit proof"
        case .cannotResubmit:
            return "You can only resubmit once after rejection"
        case .reviewFailed:
            return "Failed to review proof"
        case .proofNotFound:
            return "Proof not found"
        case .notAuthorizedToReview:
            return "You are not authorized to review this proof"
        }
    }
}

// MARK: - BillSwapProof Type Alias

/// Type alias for views that use `BillSwapProof` naming
typealias BillSwapProof = SwapProof

// MARK: - SwapProof Alias Properties

extension SwapProof {
    /// Alias for fileUrl (used by views)
    var proofUrl: String { fileUrl }

    /// Alias for formattedSubmittedAt (used by views)
    var formattedCreatedAt: String { formattedSubmittedAt }

    /// Alias for notes (used by views)
    var submitterNotes: String? { notes }

    /// Alias for userId (used by views)
    var submitterUserId: UUID { userId }

    /// Whether this proof has been flagged for review
    var isFlagged: Bool { false }

    /// Formatted time for chat-style display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: submittedAt)
    }
}

// MARK: - Submit Proof Request

struct SubmitProofRequest: Codable {
    let swapId: UUID
    let proofType: SwapProofType
    let proofUrl: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case proofType = "proof_type"
        case proofUrl = "proof_url"
        case notes
    }
}

//
//  SwapDispute.swift
//  Billix
//
//  Bill Swap Dispute Model
//

import Foundation

// MARK: - Dispute Reason

enum SwapDisputeReason: String, Codable, CaseIterable {
    case proofRejected = "PROOF_REJECTED"
    case noPayment = "NO_PAYMENT"
    case wrongAmount = "WRONG_AMOUNT"
    case fakeProof = "FAKE_PROOF"
    case noResponse = "NO_RESPONSE"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .proofRejected: return "Proof Unfairly Rejected"
        case .noPayment: return "Payment Not Made"
        case .wrongAmount: return "Wrong Amount Paid"
        case .fakeProof: return "Fake/Invalid Proof"
        case .noResponse: return "No Response from Partner"
        case .other: return "Other Issue"
        }
    }

    var icon: String {
        switch self {
        case .proofRejected: return "doc.badge.xmark"
        case .noPayment: return "dollarsign.circle"
        case .wrongAmount: return "number.circle"
        case .fakeProof: return "exclamationmark.shield"
        case .noResponse: return "clock.badge.questionmark"
        case .other: return "questionmark.circle"
        }
    }

    var description: String {
        switch self {
        case .proofRejected:
            return "Your valid payment proof was rejected without good reason"
        case .noPayment:
            return "Partner did not pay your bill as agreed"
        case .wrongAmount:
            return "Partner paid a different amount than agreed"
        case .fakeProof:
            return "Partner submitted fake or manipulated proof"
        case .noResponse:
            return "Partner is not responding to messages"
        case .other:
            return "Another issue not listed above"
        }
    }
}

// MARK: - Dispute Status

enum SwapDisputeStatus: String, Codable, CaseIterable {
    case open = "OPEN"
    case investigating = "INVESTIGATING"
    case resolved = "RESOLVED"
    case dismissed = "DISMISSED"

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .investigating: return "Under Investigation"
        case .resolved: return "Resolved"
        case .dismissed: return "Dismissed"
        }
    }

    var icon: String {
        switch self {
        case .open: return "exclamationmark.triangle.fill"
        case .investigating: return "magnifyingglass"
        case .resolved: return "checkmark.seal.fill"
        case .dismissed: return "xmark.seal.fill"
        }
    }

    var color: String {
        switch self {
        case .open: return "#E67E22"        // Orange
        case .investigating: return "#5BA4D4" // Blue
        case .resolved: return "#27AE60"    // Green
        case .dismissed: return "#8B9A94"   // Gray
        }
    }

    var isActive: Bool {
        self == .open || self == .investigating
    }
}

// MARK: - Swap Dispute Model

struct SwapDispute: Identifiable, Codable, Equatable {
    let id: UUID
    let swapId: UUID
    let reporterUserId: UUID
    let reportedUserId: UUID
    let reason: SwapDisputeReason
    var description: String?
    var evidenceUrls: [String]?
    var status: SwapDisputeStatus
    var resolution: String?
    var atFaultUserId: UUID?
    var resolvedByAdminId: UUID?
    var filingDeadline: Date?
    let createdAt: Date
    var updatedAt: Date
    var resolvedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case reporterUserId = "reporter_user_id"
        case reportedUserId = "reported_user_id"
        case reason
        case description
        case evidenceUrls = "evidence_urls"
        case status
        case resolution
        case atFaultUserId = "at_fault_user_id"
        case resolvedByAdminId = "resolved_by_admin_id"
        case filingDeadline = "filing_deadline"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case resolvedAt = "resolved_at"
    }

    // MARK: - Computed Properties

    /// Was the current user found at fault?
    func isAtFault(currentUserId: UUID) -> Bool {
        atFaultUserId == currentUserId
    }

    /// Formatted creation date
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    /// Time since dispute was filed
    var daysSinceFiled: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    /// Expected resolution time message
    var expectedResolutionMessage: String {
        switch status {
        case .open:
            return "Under review. Expected resolution within 48 hours."
        case .investigating:
            return "Being investigated. You may be contacted for more info."
        case .resolved:
            return "Dispute has been resolved."
        case .dismissed:
            return "Dispute was dismissed."
        }
    }
}

// MARK: - File Dispute Request

struct FileDisputeRequest: Codable {
    let swapId: UUID
    let reportedUserId: UUID
    let reason: SwapDisputeReason
    let description: String?
    let evidenceUrls: [String]?

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case reportedUserId = "reported_user_id"
        case reason
        case description
        case evidenceUrls = "evidence_urls"
    }
}

// MARK: - Dispute Error

enum SwapDisputeError: LocalizedError {
    case notAuthenticated
    case disputeWindowExpired
    case alreadyDisputed
    case cannotDisputeOwnSwap
    case createFailed
    case disputeNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in"
        case .disputeWindowExpired:
            return "The 24-hour dispute window has expired"
        case .alreadyDisputed:
            return "This swap has already been disputed"
        case .cannotDisputeOwnSwap:
            return "You cannot dispute yourself"
        case .createFailed:
            return "Failed to file dispute"
        case .disputeNotFound:
            return "Dispute not found"
        }
    }
}

// MARK: - Dispute Constants

enum DisputeConstants {
    /// Hours after proof rejection to file dispute
    static let filingWindowHours: Int = 24

    /// Expected hours for admin to resolve
    static let expectedResolutionHours: Int = 48
}

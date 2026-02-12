//
//  ConnectionTerms.swift
//  Billix
//
//  Simplified terms model for Bill Connection (replaces SwapDeal)
//  One-round acceptance - no negotiation, no collateral, no fallbacks
//

import Foundation
import SwiftUI

// MARK: - Terms Status

/// Current status of the connection terms
enum TermsStatus: String, Codable, CaseIterable {
    case proposed = "proposed"      // Supporter proposed terms
    case accepted = "accepted"      // Initiator accepted
    case rejected = "rejected"      // Initiator rejected
    case expired = "expired"        // 24h passed without response

    var displayName: String {
        switch self {
        case .proposed: return "Pending"
        case .accepted: return "Accepted"
        case .rejected: return "Declined"
        case .expired: return "Expired"
        }
    }

    var color: Color {
        switch self {
        case .proposed: return Color(hex: "#E8B54D")    // Amber
        case .accepted: return Color(hex: "#5B8A6B")    // Green
        case .rejected: return Color(hex: "#C45C5C")    // Red
        case .expired: return Color(hex: "#8B9A94")     // Gray
        }
    }

    var icon: String {
        switch self {
        case .proposed: return "clock.fill"
        case .accepted: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .expired: return "clock.badge.xmark.fill"
        }
    }
}

// MARK: - Connection Terms

/// Simplified terms for a Bill Connection
/// No negotiation rounds - just propose and accept/reject
struct ConnectionTerms: Codable, Identifiable, Equatable {
    let id: UUID
    let connectionId: UUID
    let proposerId: UUID            // Usually the supporter

    // Simple Terms (no negotiation needed)
    var billAmount: Decimal         // Amount to be paid
    var deadline: Date              // When payment should be made
    var proofRequired: ProofType    // What verification is needed

    // Status
    var status: TermsStatus
    let createdAt: Date
    var respondedAt: Date?
    var expiresAt: Date             // 24h to respond

    enum CodingKeys: String, CodingKey {
        case id
        case connectionId = "connection_id"
        case proposerId = "proposer_id"
        case billAmount = "bill_amount"
        case deadline
        case proofRequired = "proof_required"
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
        case expiresAt = "expires_at"
    }

    init(
        id: UUID = UUID(),
        connectionId: UUID,
        proposerId: UUID,
        billAmount: Decimal,
        deadline: Date,
        proofRequired: ProofType = .screenshot,
        status: TermsStatus = .proposed,
        createdAt: Date = Date(),
        respondedAt: Date? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.connectionId = connectionId
        self.proposerId = proposerId
        self.billAmount = billAmount
        self.deadline = deadline
        self.proofRequired = proofRequired
        self.status = status
        self.createdAt = createdAt
        self.respondedAt = respondedAt
        // Default: 24h to respond
        self.expiresAt = expiresAt ?? Calendar.current.date(byAdding: .hour, value: 24, to: createdAt) ?? createdAt
    }

    // MARK: - Computed Properties

    /// Check if the terms have expired
    var isExpired: Bool {
        Date() > expiresAt
    }

    /// Check if expiring soon (less than 3 hours remaining)
    var isExpiringSoon: Bool {
        guard let remaining = timeRemaining else { return false }
        return remaining < 3 * 60 * 60
    }

    /// Time remaining until expiration
    var timeRemaining: TimeInterval? {
        guard status == .proposed else { return nil }
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

    /// Check if current user can respond (accept/reject)
    func canRespond(userId: UUID) -> Bool {
        !isProposer(userId: userId) && status == .proposed && !isExpired
    }

    /// Formatted bill amount
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: billAmount)) ?? "$0.00"
    }

    /// Formatted deadline
    var formattedDeadline: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: deadline)
    }

    /// Relative deadline description
    var relativeDeadline: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: deadline, relativeTo: Date())
    }
}

// MARK: - Terms Input

/// Input struct for creating new connection terms
struct ConnectionTermsInput: Codable {
    var billAmount: Decimal
    var deadline: Date
    var proofRequired: ProofType

    /// Create default terms from a bill
    static func fromBill(_ bill: SupportBill) -> ConnectionTermsInput {
        // Default deadline: 48 hours from now
        let defaultDeadline = Calendar.current.date(byAdding: .hour, value: 48, to: Date()) ?? Date()

        return ConnectionTermsInput(
            billAmount: bill.amount,
            deadline: bill.dueDate ?? defaultDeadline,
            proofRequired: .screenshot
        )
    }
}

// MARK: - Insert Model

/// Model for inserting new terms into Supabase
struct ConnectionTermsInsert: Encodable {
    let connectionId: UUID
    let proposerId: UUID
    let billAmount: Decimal
    let deadline: String        // ISO8601
    let proofRequired: String
    let status: String
    let expiresAt: String       // ISO8601

    enum CodingKeys: String, CodingKey {
        case connectionId = "connection_id"
        case proposerId = "proposer_id"
        case billAmount = "bill_amount"
        case deadline
        case proofRequired = "proof_required"
        case status
        case expiresAt = "expires_at"
    }

    init(
        connectionId: UUID,
        proposerId: UUID,
        terms: ConnectionTermsInput
    ) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        self.connectionId = connectionId
        self.proposerId = proposerId
        self.billAmount = terms.billAmount
        self.deadline = formatter.string(from: terms.deadline)
        self.proofRequired = terms.proofRequired.rawValue
        self.status = TermsStatus.proposed.rawValue

        // Expires 24h from now
        let expirationDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
        self.expiresAt = formatter.string(from: expirationDate)
    }
}

// MARK: - Mock Data

extension ConnectionTerms {
    static func mockProposed(connectionId: UUID = UUID(), proposerId: UUID = UUID()) -> ConnectionTerms {
        let now = Date()
        return ConnectionTerms(
            id: UUID(),
            connectionId: connectionId,
            proposerId: proposerId,
            billAmount: Decimal(125.50),
            deadline: Calendar.current.date(byAdding: .hour, value: 48, to: now) ?? now,
            proofRequired: .screenshot,
            status: .proposed,
            createdAt: now,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: now)
        )
    }

    static func mockAccepted(connectionId: UUID = UUID(), proposerId: UUID = UUID()) -> ConnectionTerms {
        let now = Date()
        return ConnectionTerms(
            id: UUID(),
            connectionId: connectionId,
            proposerId: proposerId,
            billAmount: Decimal(89.99),
            deadline: Calendar.current.date(byAdding: .hour, value: 36, to: now) ?? now,
            proofRequired: .screenshotWithConfirmation,
            status: .accepted,
            createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: now) ?? now,
            respondedAt: now,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 22, to: now)
        )
    }
}

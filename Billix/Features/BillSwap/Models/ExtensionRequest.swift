//
//  ExtensionRequest.swift
//  Billix
//
//  Extension/renegotiation request model for swap deadlines
//

import Foundation

// MARK: - Extension Reason

/// Pre-defined reasons for requesting a deadline extension
enum ExtensionReason: String, Codable, CaseIterable {
    case paymentProcessing = "payment_processing"
    case unexpectedExpense = "unexpected_expense"
    case payScheduleConflict = "pay_schedule_conflict"
    case technicalIssue = "technical_issue"
    case other = "other"

    var displayName: String {
        switch self {
        case .paymentProcessing:
            return "Payment still processing"
        case .unexpectedExpense:
            return "Unexpected expense came up"
        case .payScheduleConflict:
            return "Pay schedule conflict"
        case .technicalIssue:
            return "Technical issue with payment"
        case .other:
            return "Other reason"
        }
    }

    var description: String {
        switch self {
        case .paymentProcessing:
            return "My payment is being processed but hasn't cleared yet"
        case .unexpectedExpense:
            return "An unexpected expense means I need a few more days"
        case .payScheduleConflict:
            return "My paycheck arrives after the current deadline"
        case .technicalIssue:
            return "There's a technical problem preventing my payment"
        case .other:
            return "I need more time for another reason"
        }
    }

    var icon: String {
        switch self {
        case .paymentProcessing:
            return "hourglass"
        case .unexpectedExpense:
            return "exclamationmark.circle"
        case .payScheduleConflict:
            return "calendar.badge.clock"
        case .technicalIssue:
            return "exclamationmark.triangle"
        case .other:
            return "ellipsis.circle"
        }
    }

    /// Whether this reason requires a custom note
    var requiresNote: Bool {
        self == .other
    }
}

// MARK: - Extension Status

/// Status of an extension request
enum ExtensionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case denied = "denied"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .denied:
            return "Denied"
        case .expired:
            return "Expired"
        }
    }

    var color: String {
        switch self {
        case .pending:
            return "#E8A54B" // Warning amber
        case .approved:
            return "#4CAF7A" // Success green
        case .denied:
            return "#E07A6B" // Danger red
        case .expired:
            return "#8B9A94" // Secondary gray
        }
    }

    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .approved:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .expired:
            return "clock.badge.xmark.fill"
        }
    }
}

// MARK: - Extension Request

/// A request to extend the payment deadline in a swap
struct ExtensionRequest: Codable, Identifiable, Equatable {
    let id: UUID
    let swapId: UUID
    let requesterId: UUID
    let reason: ExtensionReason
    let customNote: String?
    let originalDeadline: Date
    let requestedDeadline: Date
    let partialPaymentAmount: Decimal?
    var status: ExtensionStatus
    let createdAt: Date
    var respondedAt: Date?
    var expiresAt: Date  // 24h to respond

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case requesterId = "requester_id"
        case reason
        case customNote = "custom_note"
        case originalDeadline = "original_deadline"
        case requestedDeadline = "requested_deadline"
        case partialPaymentAmount = "partial_payment_amount"
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
        case expiresAt = "expires_at"
    }

    // MARK: - Computed Properties

    /// Days of extension requested
    var daysRequested: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: originalDeadline, to: requestedDeadline)
        return components.day ?? 0
    }

    /// Check if request has expired
    var isExpired: Bool {
        Date() > expiresAt
    }

    /// Time remaining for partner to respond
    var timeRemaining: TimeInterval? {
        guard status == .pending && !isExpired else { return nil }
        let remaining = expiresAt.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    /// Formatted time remaining
    var formattedTimeRemaining: String? {
        guard let remaining = timeRemaining, remaining > 0 else { return nil }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m to respond"
        } else if minutes > 0 {
            return "\(minutes)m to respond"
        } else {
            return "< 1m to respond"
        }
    }

    /// Formatted extension duration
    var formattedExtensionDuration: String {
        if daysRequested == 1 {
            return "1 day extension"
        } else if daysRequested > 1 {
            return "\(daysRequested) day extension"
        } else {
            let hours = Int(requestedDeadline.timeIntervalSince(originalDeadline) / 3600)
            return "\(hours) hour extension"
        }
    }

    /// Formatted partial payment amount
    var formattedPartialPayment: String? {
        guard let amount = partialPaymentAmount, amount > 0 else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount))
    }

    /// Check if current user is the requester
    func isRequester(userId: UUID) -> Bool {
        requesterId == userId
    }

    /// Check if current user can respond
    func canRespond(userId: UUID) -> Bool {
        !isRequester(userId: userId) && status == .pending && !isExpired
    }

    /// Description for display
    var displayDescription: String {
        var text = reason.displayName

        if let note = customNote, !note.isEmpty, reason == .other {
            text += ": \(note)"
        }

        if let partial = formattedPartialPayment {
            text += " (offering \(partial) now)"
        }

        return text
    }
}

// MARK: - Extension Request Input

/// Input for creating an extension request
struct ExtensionRequestInput {
    var reason: ExtensionReason
    var customNote: String?
    var requestedDeadline: Date
    var partialPaymentAmount: Decimal?

    /// Preset extension durations
    static let presetDurations: [(name: String, hours: Int)] = [
        ("24 hours", 24),
        ("48 hours", 48),
        ("3 days", 72),
        ("1 week", 168)
    ]

    /// Create input with preset duration
    static func withPreset(
        reason: ExtensionReason,
        currentDeadline: Date,
        durationHours: Int
    ) -> ExtensionRequestInput {
        ExtensionRequestInput(
            reason: reason,
            customNote: nil,
            requestedDeadline: Calendar.current.date(
                byAdding: .hour,
                value: durationHours,
                to: currentDeadline
            ) ?? currentDeadline,
            partialPaymentAmount: nil
        )
    }
}

// MARK: - Insert Model

/// Model for inserting extension requests into Supabase
struct ExtensionRequestInsert: Encodable {
    let swapId: UUID
    let requesterId: UUID
    let reason: String
    let customNote: String?
    let originalDeadline: String  // ISO8601
    let requestedDeadline: String  // ISO8601
    let partialPaymentAmount: Decimal?
    let status: String
    let expiresAt: String  // ISO8601

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case requesterId = "requester_id"
        case reason
        case customNote = "custom_note"
        case originalDeadline = "original_deadline"
        case requestedDeadline = "requested_deadline"
        case partialPaymentAmount = "partial_payment_amount"
        case status
        case expiresAt = "expires_at"
    }

    init(
        swapId: UUID,
        requesterId: UUID,
        originalDeadline: Date,
        input: ExtensionRequestInput
    ) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        self.swapId = swapId
        self.requesterId = requesterId
        self.reason = input.reason.rawValue
        self.customNote = input.customNote
        self.originalDeadline = formatter.string(from: originalDeadline)
        self.requestedDeadline = formatter.string(from: input.requestedDeadline)
        self.partialPaymentAmount = input.partialPaymentAmount
        self.status = ExtensionStatus.pending.rawValue

        // Expires 24h from now
        let expirationDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
        self.expiresAt = formatter.string(from: expirationDate)
    }
}

// MARK: - Mock Data

#if DEBUG
extension ExtensionRequest {
    static func mockRequest(
        swapId: UUID = UUID(),
        requesterId: UUID = UUID(),
        status: ExtensionStatus = .pending
    ) -> ExtensionRequest {
        let now = Date()
        let originalDeadline = Calendar.current.date(byAdding: .hour, value: 48, to: now) ?? now
        let requestedDeadline = Calendar.current.date(byAdding: .hour, value: 96, to: now) ?? now

        return ExtensionRequest(
            id: UUID(),
            swapId: swapId,
            requesterId: requesterId,
            reason: .payScheduleConflict,
            customNote: nil,
            originalDeadline: originalDeadline,
            requestedDeadline: requestedDeadline,
            partialPaymentAmount: nil,
            status: status,
            createdAt: now,
            respondedAt: nil,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: now) ?? now
        )
    }

    static func mockWithPartialPayment(
        swapId: UUID = UUID(),
        requesterId: UUID = UUID()
    ) -> ExtensionRequest {
        let now = Date()
        let originalDeadline = Calendar.current.date(byAdding: .hour, value: 48, to: now) ?? now
        let requestedDeadline = Calendar.current.date(byAdding: .hour, value: 72, to: now) ?? now

        return ExtensionRequest(
            id: UUID(),
            swapId: swapId,
            requesterId: requesterId,
            reason: .unexpectedExpense,
            customNote: nil,
            originalDeadline: originalDeadline,
            requestedDeadline: requestedDeadline,
            partialPaymentAmount: Decimal(50.00),
            status: .pending,
            createdAt: now,
            respondedAt: nil,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: now) ?? now
        )
    }
}
#endif

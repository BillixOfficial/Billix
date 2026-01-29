//
//  SwapEvent.swift
//  Billix
//
//  Structured event/evidence trail model for swap negotiations
//

import Foundation

// MARK: - Swap Event Type

/// Types of events that can occur during a swap lifecycle
enum SwapEventType: String, Codable, CaseIterable {
    // Deal negotiation events
    case dealProposed = "deal_proposed"
    case dealCountered = "deal_countered"
    case dealAccepted = "deal_accepted"
    case dealRejected = "deal_rejected"

    // Payment events
    case paymentProofSubmitted = "proof_submitted"
    case paymentConfirmed = "payment_confirmed"
    case paymentDisputed = "payment_disputed"

    // Extension/renegotiation events
    case extensionRequested = "extension_requested"
    case extensionApproved = "extension_approved"
    case extensionDenied = "extension_denied"

    // Dispute events
    case disputeOpened = "dispute_opened"
    case disputeResolved = "dispute_resolved"
    case disputeEscalated = "dispute_escalated"

    // Collateral events
    case collateralLocked = "collateral_locked"
    case collateralReleased = "collateral_released"
    case collateralForfeited = "collateral_forfeited"

    // Swap lifecycle events
    case swapActivated = "swap_activated"
    case swapCompleted = "swap_completed"
    case swapCancelled = "swap_cancelled"
    case swapExpired = "swap_expired"

    // Chat events (for audit trail)
    case chatUnlocked = "chat_unlocked"
    case messageReported = "message_reported"

    var displayName: String {
        switch self {
        case .dealProposed: return "Terms Proposed"
        case .dealCountered: return "Counter-Offer Sent"
        case .dealAccepted: return "Terms Accepted"
        case .dealRejected: return "Terms Rejected"
        case .paymentProofSubmitted: return "Proof Uploaded"
        case .paymentConfirmed: return "Payment Confirmed"
        case .paymentDisputed: return "Proof Disputed"
        case .extensionRequested: return "Extension Requested"
        case .extensionApproved: return "Extension Approved"
        case .extensionDenied: return "Extension Denied"
        case .disputeOpened: return "Dispute Opened"
        case .disputeResolved: return "Dispute Resolved"
        case .disputeEscalated: return "Dispute Escalated"
        case .collateralLocked: return "Trust Deposit Locked"
        case .collateralReleased: return "Trust Deposit Released"
        case .collateralForfeited: return "Trust Deposit Forfeited"
        case .swapActivated: return "Swap Activated"
        case .swapCompleted: return "Swap Completed"
        case .swapCancelled: return "Swap Cancelled"
        case .swapExpired: return "Swap Expired"
        case .chatUnlocked: return "Chat Unlocked"
        case .messageReported: return "Message Reported"
        }
    }

    var icon: String {
        switch self {
        case .dealProposed: return "paperplane.fill"
        case .dealCountered: return "arrow.triangle.2.circlepath"
        case .dealAccepted: return "checkmark.circle.fill"
        case .dealRejected: return "xmark.circle.fill"
        case .paymentProofSubmitted: return "camera.fill"
        case .paymentConfirmed: return "checkmark.seal.fill"
        case .paymentDisputed: return "exclamationmark.triangle.fill"
        case .extensionRequested: return "clock.arrow.circlepath"
        case .extensionApproved: return "clock.badge.checkmark.fill"
        case .extensionDenied: return "clock.badge.xmark.fill"
        case .disputeOpened: return "flag.fill"
        case .disputeResolved: return "flag.checkered"
        case .disputeEscalated: return "arrow.up.circle.fill"
        case .collateralLocked: return "lock.fill"
        case .collateralReleased: return "lock.open.fill"
        case .collateralForfeited: return "lock.slash.fill"
        case .swapActivated: return "bolt.fill"
        case .swapCompleted: return "star.fill"
        case .swapCancelled: return "xmark.octagon.fill"
        case .swapExpired: return "clock.badge.xmark.fill"
        case .chatUnlocked: return "message.fill"
        case .messageReported: return "exclamationmark.bubble.fill"
        }
    }

    var color: String {
        switch self {
        case .dealProposed, .dealCountered:
            return "#5BA4D4" // Info blue
        case .dealAccepted, .paymentConfirmed, .extensionApproved,
             .disputeResolved, .collateralReleased, .swapCompleted:
            return "#4CAF7A" // Success green
        case .dealRejected, .extensionDenied, .collateralForfeited,
             .swapCancelled, .swapExpired:
            return "#E07A6B" // Danger red
        case .extensionRequested, .paymentProofSubmitted:
            return "#E8A54B" // Warning amber
        case .paymentDisputed, .disputeOpened, .disputeEscalated, .messageReported:
            return "#E07A6B" // Danger red
        case .collateralLocked, .swapActivated, .chatUnlocked:
            return "#5B8A6B" // Primary green
        }
    }

    /// Whether this event is significant enough to show in summary view
    var isSignificant: Bool {
        switch self {
        case .dealProposed, .dealAccepted, .dealRejected,
             .paymentProofSubmitted, .paymentConfirmed,
             .disputeOpened, .disputeResolved,
             .swapActivated, .swapCompleted, .swapCancelled:
            return true
        default:
            return false
        }
    }
}

// MARK: - Swap Event

/// An immutable record of an action in the swap lifecycle
struct SwapEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let swapId: UUID
    let actorId: UUID
    let eventType: SwapEventType
    let payload: SwapEventPayload?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case actorId = "actor_id"
        case eventType = "event_type"
        case payload
        case createdAt = "created_at"
    }

    // MARK: - Computed Properties

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: createdAt)
    }

    var formattedDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(createdAt) {
            return "Today"
        } else if calendar.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: createdAt)
        }
    }

    var formattedDateTime: String {
        "\(formattedDate) at \(formattedTime)"
    }

    /// Generate human-readable description of the event
    func description(actorName: String, isCurrentUser: Bool) -> String {
        let actor = isCurrentUser ? "You" : actorName

        switch eventType {
        case .dealProposed:
            return "\(actor) proposed swap terms"
        case .dealCountered:
            return "\(actor) sent a counter-offer"
        case .dealAccepted:
            return "\(actor) accepted the terms"
        case .dealRejected:
            return "\(actor) rejected the terms"
        case .paymentProofSubmitted:
            return "\(actor) uploaded payment proof"
        case .paymentConfirmed:
            return "\(actor)'s payment was confirmed"
        case .paymentDisputed:
            return "\(actor) disputed the payment proof"
        case .extensionRequested:
            return "\(actor) requested an extension"
        case .extensionApproved:
            return "\(actor) approved the extension"
        case .extensionDenied:
            return "\(actor) denied the extension"
        case .disputeOpened:
            return "\(actor) opened a dispute"
        case .disputeResolved:
            return "Dispute resolved by platform"
        case .disputeEscalated:
            return "Dispute escalated for review"
        case .collateralLocked:
            return "\(actor)'s trust deposit locked"
        case .collateralReleased:
            return "\(actor)'s trust deposit released"
        case .collateralForfeited:
            return "\(actor)'s trust deposit forfeited"
        case .swapActivated:
            return "Swap is now active"
        case .swapCompleted:
            return "Swap completed successfully"
        case .swapCancelled:
            return "Swap was cancelled"
        case .swapExpired:
            return "Swap expired"
        case .chatUnlocked:
            return "\(actor) unlocked chat"
        case .messageReported:
            return "\(actor) reported a message"
        }
    }
}

// MARK: - Swap Event Payload

/// Structured payload data for different event types
struct SwapEventPayload: Codable, Equatable {
    // Deal-related fields
    var dealId: UUID?
    var dealVersion: Int?
    var whoPaysFirst: String?
    var amountA: Decimal?
    var amountB: Decimal?
    var deadlineA: Date?
    var deadlineB: Date?

    // Proof-related fields
    var proofUrl: String?
    var confirmationNumber: String?

    // Extension-related fields
    var extensionId: UUID?
    var reason: String?
    var requestedDeadline: Date?
    var partialPaymentAmount: Decimal?

    // Dispute-related fields
    var disputeId: UUID?
    var disputeReason: String?
    var resolution: String?

    // Collateral-related fields
    var collateralType: String?
    var collateralAmount: Int?

    // Generic note field
    var note: String?

    enum CodingKeys: String, CodingKey {
        case dealId = "deal_id"
        case dealVersion = "deal_version"
        case whoPaysFirst = "who_pays_first"
        case amountA = "amount_a"
        case amountB = "amount_b"
        case deadlineA = "deadline_a"
        case deadlineB = "deadline_b"
        case proofUrl = "proof_url"
        case confirmationNumber = "confirmation_number"
        case extensionId = "extension_id"
        case reason
        case requestedDeadline = "requested_deadline"
        case partialPaymentAmount = "partial_payment_amount"
        case disputeId = "dispute_id"
        case disputeReason = "dispute_reason"
        case resolution
        case collateralType = "collateral_type"
        case collateralAmount = "collateral_amount"
        case note
    }

    // MARK: - Factory Methods

    static func dealProposed(deal: SwapDeal) -> SwapEventPayload {
        SwapEventPayload(
            dealId: deal.id,
            dealVersion: deal.version,
            whoPaysFirst: deal.whoPaysFirst.rawValue,
            amountA: deal.amountA,
            amountB: deal.amountB,
            deadlineA: deal.deadlineA,
            deadlineB: deal.deadlineB
        )
    }

    static func proofSubmitted(proofUrl: String, confirmationNumber: String? = nil) -> SwapEventPayload {
        SwapEventPayload(
            proofUrl: proofUrl,
            confirmationNumber: confirmationNumber
        )
    }

    static func extensionRequested(
        extensionId: UUID,
        reason: String,
        requestedDeadline: Date,
        partialPaymentAmount: Decimal? = nil
    ) -> SwapEventPayload {
        SwapEventPayload(
            extensionId: extensionId,
            reason: reason,
            requestedDeadline: requestedDeadline,
            partialPaymentAmount: partialPaymentAmount
        )
    }

    static func collateral(type: String, amount: Int) -> SwapEventPayload {
        SwapEventPayload(
            collateralType: type,
            collateralAmount: amount
        )
    }

    static func dispute(disputeId: UUID, reason: String) -> SwapEventPayload {
        SwapEventPayload(
            disputeId: disputeId,
            disputeReason: reason
        )
    }

    static func disputeResolved(disputeId: UUID, resolution: String) -> SwapEventPayload {
        SwapEventPayload(
            disputeId: disputeId,
            resolution: resolution
        )
    }

    static func withNote(_ note: String) -> SwapEventPayload {
        SwapEventPayload(note: note)
    }
}

// MARK: - Insert Model

/// Model for inserting new events into Supabase
struct SwapEventInsert: Encodable {
    let swapId: UUID
    let actorId: UUID
    let eventType: String
    let payload: SwapEventPayload?

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case actorId = "actor_id"
        case eventType = "event_type"
        case payload
    }

    init(swapId: UUID, actorId: UUID, type: SwapEventType, payload: SwapEventPayload? = nil) {
        self.swapId = swapId
        self.actorId = actorId
        self.eventType = type.rawValue
        self.payload = payload
    }
}

// MARK: - Timeline Grouping

/// Helper for grouping events by date in timeline view
struct SwapEventGroup: Identifiable {
    let date: Date
    let events: [SwapEvent]

    var id: Date { date }

    var formattedDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

extension Array where Element == SwapEvent {
    /// Group events by date for timeline display
    func groupedByDate() -> [SwapEventGroup] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: self) { event in
            calendar.startOfDay(for: event.createdAt)
        }

        return grouped
            .map { SwapEventGroup(date: $0.key, events: $0.value.sorted { $0.createdAt < $1.createdAt }) }
            .sorted { $0.date < $1.date }
    }

    /// Filter to significant events only
    var significantEvents: [SwapEvent] {
        filter { $0.eventType.isSignificant }
    }
}

// MARK: - Mock Data

#if DEBUG
extension SwapEvent {
    static func mockEvent(
        swapId: UUID = UUID(),
        actorId: UUID = UUID(),
        type: SwapEventType = .dealProposed
    ) -> SwapEvent {
        SwapEvent(
            id: UUID(),
            swapId: swapId,
            actorId: actorId,
            eventType: type,
            payload: nil,
            createdAt: Date()
        )
    }

    static func mockTimeline(swapId: UUID = UUID()) -> [SwapEvent] {
        let userA = UUID()
        let userB = UUID()
        let now = Date()

        return [
            SwapEvent(
                id: UUID(),
                swapId: swapId,
                actorId: userA,
                eventType: .dealProposed,
                payload: nil,
                createdAt: Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? now
            ),
            SwapEvent(
                id: UUID(),
                swapId: swapId,
                actorId: userB,
                eventType: .dealCountered,
                payload: nil,
                createdAt: Calendar.current.date(byAdding: .hour, value: -20, to: now) ?? now
            ),
            SwapEvent(
                id: UUID(),
                swapId: swapId,
                actorId: userA,
                eventType: .dealAccepted,
                payload: nil,
                createdAt: Calendar.current.date(byAdding: .hour, value: -18, to: now) ?? now
            ),
            SwapEvent(
                id: UUID(),
                swapId: swapId,
                actorId: userA,
                eventType: .collateralLocked,
                payload: .collateral(type: "trust_points", amount: 10),
                createdAt: Calendar.current.date(byAdding: .hour, value: -18, to: now) ?? now
            ),
            SwapEvent(
                id: UUID(),
                swapId: swapId,
                actorId: userB,
                eventType: .collateralLocked,
                payload: .collateral(type: "trust_points", amount: 10),
                createdAt: Calendar.current.date(byAdding: .hour, value: -17, to: now) ?? now
            ),
            SwapEvent(
                id: UUID(),
                swapId: swapId,
                actorId: userA,
                eventType: .paymentProofSubmitted,
                payload: .proofSubmitted(proofUrl: "https://example.com/proof.jpg"),
                createdAt: Calendar.current.date(byAdding: .hour, value: -4, to: now) ?? now
            )
        ]
    }
}
#endif

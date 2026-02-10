//
//  ConnectionEventService.swift
//  Billix
//
//  Service for logging connection events and maintaining audit trail
//  Replaces the old swap event logging system
//

import Foundation
import Supabase

// MARK: - Event Types

/// Types of events that can occur during a connection
enum ConnectionEventType: String, Codable {
    // Phase 1: Request
    case requestCreated = "request_created"
    case requestExpired = "request_expired"

    // Phase 2: Handshake
    case supporterMatched = "supporter_matched"
    case termsProposed = "terms_proposed"
    case termsAccepted = "terms_accepted"
    case termsRejected = "terms_rejected"
    case termsExpired = "terms_expired"

    // Phase 3: Execution
    case paymentStarted = "payment_started"

    // Phase 4: Proof
    case proofSubmitted = "proof_submitted"
    case proofVerified = "proof_verified"
    case proofRejected = "proof_rejected"

    // Phase 5: Reputation
    case connectionCompleted = "connection_completed"
    case reputationAwarded = "reputation_awarded"

    // Other
    case connectionCancelled = "connection_cancelled"
    case disputeRaised = "dispute_raised"
    case disputeResolved = "dispute_resolved"
    case messagesSent = "message_sent"

    var displayName: String {
        switch self {
        case .requestCreated: return "Request Created"
        case .requestExpired: return "Request Expired"
        case .supporterMatched: return "Supporter Matched"
        case .termsProposed: return "Terms Proposed"
        case .termsAccepted: return "Terms Accepted"
        case .termsRejected: return "Terms Declined"
        case .termsExpired: return "Terms Expired"
        case .paymentStarted: return "Payment Started"
        case .proofSubmitted: return "Proof Submitted"
        case .proofVerified: return "Proof Verified"
        case .proofRejected: return "Proof Rejected"
        case .connectionCompleted: return "Connection Completed"
        case .reputationAwarded: return "Reputation Awarded"
        case .connectionCancelled: return "Connection Cancelled"
        case .disputeRaised: return "Dispute Raised"
        case .disputeResolved: return "Dispute Resolved"
        case .messagesSent: return "Message Sent"
        }
    }

    var icon: String {
        switch self {
        case .requestCreated: return "doc.text.fill"
        case .requestExpired: return "clock.badge.xmark.fill"
        case .supporterMatched: return "person.2.fill"
        case .termsProposed: return "doc.badge.plus"
        case .termsAccepted: return "checkmark.circle.fill"
        case .termsRejected: return "xmark.circle.fill"
        case .termsExpired: return "clock.badge.xmark.fill"
        case .paymentStarted: return "creditcard.fill"
        case .proofSubmitted: return "camera.fill"
        case .proofVerified: return "checkmark.seal.fill"
        case .proofRejected: return "xmark.seal.fill"
        case .connectionCompleted: return "star.fill"
        case .reputationAwarded: return "trophy.fill"
        case .connectionCancelled: return "xmark.circle.fill"
        case .disputeRaised: return "exclamationmark.triangle.fill"
        case .disputeResolved: return "checkmark.shield.fill"
        case .messagesSent: return "message.fill"
        }
    }
}

// MARK: - Event Payload

/// Payload data for different event types
enum ConnectionEventPayload: Codable {
    case request(billAmount: Decimal, connectionType: ConnectionType)
    case match(supporterId: UUID)
    case terms(termsId: UUID)
    case termsRejection(termsId: UUID, reason: String?)
    case proof(proofUrl: String)
    case completion(success: Bool)
    case cancellation(reason: String?, cancelledBy: UUID)
    case dispute(reason: DisputeReason, raisedBy: UUID, details: String?)
    case disputeResolution(resolution: String, resolvedBy: UUID)
    case reputation(points: Int, tier: ReputationTier)
    case message(messageId: UUID)
    case empty

    // Custom coding for JSONB storage
    enum CodingKeys: String, CodingKey {
        case type
        case billAmount = "bill_amount"
        case connectionType = "connection_type"
        case supporterId = "supporter_id"
        case termsId = "terms_id"
        case reason
        case proofUrl = "proof_url"
        case success
        case cancelledBy = "cancelled_by"
        case raisedBy = "raised_by"
        case details
        case resolution
        case resolvedBy = "resolved_by"
        case points
        case tier
        case messageId = "message_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .request(let amount, let type):
            try container.encode("request", forKey: .type)
            try container.encode(amount, forKey: .billAmount)
            try container.encode(type.rawValue, forKey: .connectionType)

        case .match(let supporterId):
            try container.encode("match", forKey: .type)
            try container.encode(supporterId.uuidString, forKey: .supporterId)

        case .terms(let termsId):
            try container.encode("terms", forKey: .type)
            try container.encode(termsId.uuidString, forKey: .termsId)

        case .termsRejection(let termsId, let reason):
            try container.encode("terms_rejection", forKey: .type)
            try container.encode(termsId.uuidString, forKey: .termsId)
            try container.encodeIfPresent(reason, forKey: .reason)

        case .proof(let proofUrl):
            try container.encode("proof", forKey: .type)
            try container.encode(proofUrl, forKey: .proofUrl)

        case .completion(let success):
            try container.encode("completion", forKey: .type)
            try container.encode(success, forKey: .success)

        case .cancellation(let reason, let cancelledBy):
            try container.encode("cancellation", forKey: .type)
            try container.encodeIfPresent(reason, forKey: .reason)
            try container.encode(cancelledBy.uuidString, forKey: .cancelledBy)

        case .dispute(let reason, let raisedBy, let details):
            try container.encode("dispute", forKey: .type)
            try container.encode(reason.rawValue, forKey: .reason)
            try container.encode(raisedBy.uuidString, forKey: .raisedBy)
            try container.encodeIfPresent(details, forKey: .details)

        case .disputeResolution(let resolution, let resolvedBy):
            try container.encode("dispute_resolution", forKey: .type)
            try container.encode(resolution, forKey: .resolution)
            try container.encode(resolvedBy.uuidString, forKey: .resolvedBy)

        case .reputation(let points, let tier):
            try container.encode("reputation", forKey: .type)
            try container.encode(points, forKey: .points)
            try container.encode(tier.rawValue, forKey: .tier)

        case .message(let messageId):
            try container.encode("message", forKey: .type)
            try container.encode(messageId.uuidString, forKey: .messageId)

        case .empty:
            try container.encode("empty", forKey: .type)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "request":
            let amount = try container.decode(Decimal.self, forKey: .billAmount)
            let typeString = try container.decode(String.self, forKey: .connectionType)
            let connectionType = ConnectionType(rawValue: typeString) ?? .oneWay
            self = .request(billAmount: amount, connectionType: connectionType)

        case "match":
            let supporterId = try container.decode(String.self, forKey: .supporterId)
            self = .match(supporterId: UUID(uuidString: supporterId) ?? UUID())

        case "terms":
            let termsId = try container.decode(String.self, forKey: .termsId)
            self = .terms(termsId: UUID(uuidString: termsId) ?? UUID())

        case "terms_rejection":
            let termsId = try container.decode(String.self, forKey: .termsId)
            let reason = try container.decodeIfPresent(String.self, forKey: .reason)
            self = .termsRejection(termsId: UUID(uuidString: termsId) ?? UUID(), reason: reason)

        case "proof":
            let proofUrl = try container.decode(String.self, forKey: .proofUrl)
            self = .proof(proofUrl: proofUrl)

        case "completion":
            let success = try container.decode(Bool.self, forKey: .success)
            self = .completion(success: success)

        case "cancellation":
            let reason = try container.decodeIfPresent(String.self, forKey: .reason)
            let cancelledBy = try container.decode(String.self, forKey: .cancelledBy)
            self = .cancellation(reason: reason, cancelledBy: UUID(uuidString: cancelledBy) ?? UUID())

        case "dispute":
            let reasonString = try container.decode(String.self, forKey: .reason)
            let reason = DisputeReason(rawValue: reasonString) ?? .other
            let raisedBy = try container.decode(String.self, forKey: .raisedBy)
            let details = try container.decodeIfPresent(String.self, forKey: .details)
            self = .dispute(reason: reason, raisedBy: UUID(uuidString: raisedBy) ?? UUID(), details: details)

        case "dispute_resolution":
            let resolution = try container.decode(String.self, forKey: .resolution)
            let resolvedBy = try container.decode(String.self, forKey: .resolvedBy)
            self = .disputeResolution(resolution: resolution, resolvedBy: UUID(uuidString: resolvedBy) ?? UUID())

        case "reputation":
            let points = try container.decode(Int.self, forKey: .points)
            let tierValue = try container.decode(Int.self, forKey: .tier)
            let tier = ReputationTier(rawValue: tierValue) ?? .neighbor
            self = .reputation(points: points, tier: tier)

        case "message":
            let messageId = try container.decode(String.self, forKey: .messageId)
            self = .message(messageId: UUID(uuidString: messageId) ?? UUID())

        default:
            self = .empty
        }
    }
}

// MARK: - Connection Event Model

/// A logged event for a connection
struct ConnectionEvent: Identifiable, Codable {
    let id: UUID
    let connectionId: UUID
    let actorId: UUID?
    let eventType: ConnectionEventType
    let payload: ConnectionEventPayload?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case connectionId = "connection_id"
        case actorId = "actor_id"
        case eventType = "event_type"
        case payload
        case createdAt = "created_at"
    }
}

// MARK: - Event Insert Model

private struct ConnectionEventInsert: Encodable {
    let connectionId: UUID
    let actorId: UUID?
    let eventType: String
    let payload: ConnectionEventPayload?

    enum CodingKeys: String, CodingKey {
        case connectionId = "connection_id"
        case actorId = "actor_id"
        case eventType = "event_type"
        case payload
    }
}

// MARK: - Connection Event Service

/// Service for logging and retrieving connection events
@MainActor
class ConnectionEventService: ObservableObject {

    // MARK: - Singleton

    static let shared = ConnectionEventService()

    // MARK: - Properties

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentUserId: UUID? {
        AuthService.shared.currentUser?.id
    }

    private init() {}

    // MARK: - Log Event

    /// Log an event for a connection
    func logEvent(
        connectionId: UUID,
        type: ConnectionEventType,
        payload: ConnectionEventPayload = .empty
    ) async throws {
        let event = ConnectionEventInsert(
            connectionId: connectionId,
            actorId: currentUserId,
            eventType: type.rawValue,
            payload: payload
        )

        try await supabase
            .from("connection_events")
            .insert(event)
            .execute()
    }

    /// Log an event with a specific actor (for system events)
    func logSystemEvent(
        connectionId: UUID,
        type: ConnectionEventType,
        payload: ConnectionEventPayload = .empty
    ) async throws {
        let event = ConnectionEventInsert(
            connectionId: connectionId,
            actorId: nil,
            eventType: type.rawValue,
            payload: payload
        )

        try await supabase
            .from("connection_events")
            .insert(event)
            .execute()
    }

    // MARK: - Fetch Events

    /// Get all events for a connection
    func getEvents(for connectionId: UUID) async throws -> [ConnectionEvent] {
        let events: [ConnectionEvent] = try await supabase
            .from("connection_events")
            .select()
            .eq("connection_id", value: connectionId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return events
    }

    /// Get recent events for a connection (limited)
    func getRecentEvents(for connectionId: UUID, limit: Int = 10) async throws -> [ConnectionEvent] {
        let events: [ConnectionEvent] = try await supabase
            .from("connection_events")
            .select()
            .eq("connection_id", value: connectionId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return events
    }

    /// Get events of a specific type for a connection
    func getEvents(for connectionId: UUID, type: ConnectionEventType) async throws -> [ConnectionEvent] {
        let events: [ConnectionEvent] = try await supabase
            .from("connection_events")
            .select()
            .eq("connection_id", value: connectionId.uuidString)
            .eq("event_type", value: type.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value

        return events
    }

    /// Get all events for the current user across all connections
    func getMyEvents(limit: Int = 50) async throws -> [ConnectionEvent] {
        guard let userId = currentUserId else {
            throw EventServiceError.notAuthenticated
        }

        let events: [ConnectionEvent] = try await supabase
            .from("connection_events")
            .select()
            .eq("actor_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return events
    }
}

// MARK: - Dispute Reason
// NOTE: DisputeReason is defined in TrustLadderEnums.swift

// MARK: - Errors

enum EventServiceError: LocalizedError {
    case notAuthenticated
    case eventNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .eventNotFound:
            return "Event not found"
        }
    }
}

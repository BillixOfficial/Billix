//
//  TermsService.swift
//  Billix
//
//  Simplified terms service for Bill Connection (replaces DealService)
//  One-round acceptance - no negotiation, just propose and accept/reject
//

import Foundation
import Supabase

/// Service for managing connection terms
/// Simplified flow: Supporter proposes → Initiator accepts/rejects
@MainActor
class TermsService: ObservableObject {

    // MARK: - Singleton

    static let shared = TermsService()

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentUserId: UUID? {
        AuthService.shared.currentUser?.id
    }

    private init() {}

    // MARK: - Propose Terms

    /// Propose terms for a connection (typically done by supporter)
    func proposeTerms(connectionId: UUID, terms: ConnectionTermsInput) async throws -> ConnectionTerms {
        guard let userId = currentUserId else {
            throw TermsError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Verify connection exists and is in handshake phase
        let connection = try await ConnectionService.shared.getConnection(id: connectionId)

        guard connection.status == .handshake else {
            throw TermsError.invalidState("Terms can only be proposed during handshake phase")
        }

        // Check if there's already pending terms
        if let existingTerms = try await getCurrentTerms(for: connectionId) {
            if existingTerms.status == .proposed {
                throw TermsError.termsAlreadyPending
            }
        }

        // Create terms
        let termsInsert = ConnectionTermsInsert(
            connectionId: connectionId,
            proposerId: userId,
            terms: terms
        )

        let newTerms: ConnectionTerms = try await supabase
            .from("connection_terms")
            .insert(termsInsert)
            .select()
            .single()
            .execute()
            .value

        // Log event
        try await ConnectionEventService.shared.logEvent(
            connectionId: connectionId,
            type: .termsProposed,
            payload: .terms(termsId: newTerms.id)
        )

        // Notify the other party
        await NotificationService.shared.notifyTermsProposed(connectionId: connectionId)

        return newTerms
    }

    // MARK: - Accept Terms

    /// Accept proposed terms (moves connection to execution phase)
    func acceptTerms(termsId: UUID) async throws -> ConnectionTerms {
        guard let userId = currentUserId else {
            throw TermsError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Get the terms
        var terms = try await getTerms(id: termsId)

        // Verify user can accept (not the proposer)
        guard !terms.isProposer(userId: userId) else {
            throw TermsError.cannotAcceptOwnTerms
        }

        // Verify terms are still pending
        guard terms.status == .proposed else {
            throw TermsError.termsNotPending
        }

        // Check if expired
        guard !terms.isExpired else {
            // Update to expired status
            try await supabase
                .from("connection_terms")
                .update(["status": TermsStatus.expired.rawValue])
                .eq("id", value: termsId.uuidString)
                .execute()

            throw TermsError.termsExpired
        }

        // Accept the terms
        try await supabase
            .from("connection_terms")
            .update([
                "status": TermsStatus.accepted.rawValue,
                "responded_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: termsId.uuidString)
            .execute()

        // Reload terms
        terms = try await getTerms(id: termsId)

        // Log event
        try await ConnectionEventService.shared.logEvent(
            connectionId: terms.connectionId,
            type: .termsAccepted,
            payload: .terms(termsId: termsId)
        )

        // Notify proposer
        await NotificationService.shared.notifyTermsAccepted(connectionId: terms.connectionId)

        return terms
    }

    // MARK: - Reject Terms

    /// Reject proposed terms
    func rejectTerms(termsId: UUID, reason: String? = nil) async throws -> ConnectionTerms {
        guard let userId = currentUserId else {
            throw TermsError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Get the terms
        var terms = try await getTerms(id: termsId)

        // Verify user can reject (not the proposer)
        guard !terms.isProposer(userId: userId) else {
            throw TermsError.cannotRejectOwnTerms
        }

        // Verify terms are still pending
        guard terms.status == .proposed else {
            throw TermsError.termsNotPending
        }

        // Reject the terms
        try await supabase
            .from("connection_terms")
            .update([
                "status": TermsStatus.rejected.rawValue,
                "responded_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: termsId.uuidString)
            .execute()

        // Reload terms
        terms = try await getTerms(id: termsId)

        // Log event
        try await ConnectionEventService.shared.logEvent(
            connectionId: terms.connectionId,
            type: .termsRejected,
            payload: .termsRejection(termsId: termsId, reason: reason)
        )

        // Notify proposer
        await NotificationService.shared.notifyTermsRejected(connectionId: terms.connectionId)

        return terms
    }

    // MARK: - Fetch Methods

    /// Get terms by ID
    func getTerms(id: UUID) async throws -> ConnectionTerms {
        let terms: ConnectionTerms = try await supabase
            .from("connection_terms")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return terms
    }

    /// Get current/latest terms for a connection
    func getCurrentTerms(for connectionId: UUID) async throws -> ConnectionTerms? {
        let terms: [ConnectionTerms] = try await supabase
            .from("connection_terms")
            .select()
            .eq("connection_id", value: connectionId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return terms.first
    }

    /// Get all terms history for a connection
    func getTermsHistory(for connectionId: UUID) async throws -> [ConnectionTerms] {
        let terms: [ConnectionTerms] = try await supabase
            .from("connection_terms")
            .select()
            .eq("connection_id", value: connectionId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return terms
    }

    // MARK: - Expiration Check

    /// Check and expire old pending terms
    func expireOldTerms() async throws {
        // This could be called periodically or by a cron job
        // Find all proposed terms that are past their expiration

        let expiredTerms: [ConnectionTerms] = try await supabase
            .from("connection_terms")
            .select()
            .eq("status", value: TermsStatus.proposed.rawValue)
            .lt("expires_at", value: ISO8601DateFormatter().string(from: Date()))
            .execute()
            .value

        for terms in expiredTerms {
            try await supabase
                .from("connection_terms")
                .update(["status": TermsStatus.expired.rawValue])
                .eq("id", value: terms.id.uuidString)
                .execute()

            // Log event
            try await ConnectionEventService.shared.logEvent(
                connectionId: terms.connectionId,
                type: .termsExpired,
                payload: .terms(termsId: terms.id)
            )
        }
    }
}

// MARK: - Errors

enum TermsError: LocalizedError {
    case notAuthenticated
    case termsNotFound
    case invalidState(String)
    case cannotAcceptOwnTerms
    case cannotRejectOwnTerms
    case termsNotPending
    case termsExpired
    case termsAlreadyPending

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .termsNotFound:
            return "Terms not found"
        case .invalidState(let message):
            return message
        case .cannotAcceptOwnTerms:
            return "You cannot accept your own proposed terms"
        case .cannotRejectOwnTerms:
            return "You cannot reject your own proposed terms"
        case .termsNotPending:
            return "These terms are no longer pending"
        case .termsExpired:
            return "These terms have expired"
        case .termsAlreadyPending:
            return "There are already pending terms for this connection"
        }
    }
}

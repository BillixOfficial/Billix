//
//  ConnectionService.swift
//  Billix
//
//  Service for managing Bill Connection transactions (replaces SwapService)
//  Implements the 5-phase peer-to-peer support workflow
//

import Foundation
import Supabase

/// Service for Bill Connection matching, creation, and management
@MainActor
class ConnectionService: ObservableObject {

    // MARK: - Singleton

    static let shared = ConnectionService()

    // MARK: - Published Properties

    @Published var communityRequests: [CommunityBoardItem] = []   // Bills posted for support with connection info
    @Published var myRequests: [Connection] = []            // My support requests
    @Published var activeConnections: [Connection] = []     // Connections I'm involved in
    @Published var completedConnections: [Connection] = []
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

    // MARK: - Phase 1: REQUEST - Post Support Request

    /// Create a support request by posting a bill to the Community Board
    /// Charges 2 tokens at upload time
    func createRequest(bill: SupportBill, connectionType: ConnectionType) async throws -> Connection {
        guard let userId = currentUserId else {
            throw ConnectionError.notAuthenticated
        }

        // Check tier limits
        try await validateTierLimit(amount: bill.amount, userId: userId)

        // Check velocity limit for Neighbor tier
        try await checkVelocityLimit(userId: userId)

        // Use a token for posting the support request
        // Note: Token cost is 1 per request (via existing useToken method)
        _ = try await TokenService.shared.useTokenForSwapEntry(billId: bill.id)

        // Create the connection in "requested" status
        let connectionInsert = ConnectionInsert(
            initiatorId: userId,
            billId: bill.id,
            connectionType: connectionType
        )

        let connection: Connection = try await supabase
            .from("connections")
            .insert(connectionInsert)
            .select()
            .single()
            .execute()
            .value

        // Log the event
        try await ConnectionEventService.shared.logEvent(
            connectionId: connection.id,
            type: .requestCreated,
            payload: .request(billAmount: bill.amount, connectionType: connectionType)
        )

        // Refresh data
        try await fetchMyConnections()

        return connection
    }

    // MARK: - Phase 2: HANDSHAKE - Connect and Agree on Terms

    /// Offer to support someone's bill (moves to handshake phase)
    func offerSupport(connectionId: UUID) async throws -> Connection {
        guard let userId = currentUserId else {
            throw ConnectionError.notAuthenticated
        }

        // Get the connection
        var connection = try await getConnection(id: connectionId)

        // Verify status
        guard connection.status == .requested else {
            throw ConnectionError.invalidState("Can only offer support on requested connections")
        }

        // Can't support your own request
        guard connection.initiatorId != userId else {
            throw ConnectionError.cannotSupportOwnRequest
        }

        // Update connection with supporter
        try await supabase
            .from("connections")
            .update([
                "supporter_id": userId.uuidString,
                "status": ConnectionStatus.handshake.rawValue,
                "phase": "2",
                "matched_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: connectionId.uuidString)
            .execute()

        // Reload connection
        connection = try await getConnection(id: connectionId)

        // Log event
        try await ConnectionEventService.shared.logEvent(
            connectionId: connectionId,
            type: .supporterMatched,
            payload: .match(supporterId: userId)
        )

        // Notify initiator
        await NotificationService.shared.notifySupporterFound(connectionId: connectionId)

        return connection
    }

    /// Accept proposed terms (initiator accepts, moves to executing)
    func acceptTerms(connectionId: UUID, termsId: UUID) async throws -> Connection {
        guard let userId = currentUserId else {
            throw ConnectionError.notAuthenticated
        }

        // Get connection
        var connection = try await getConnection(id: connectionId)

        // Verify user is the initiator
        guard connection.isInitiator(userId: userId) else {
            throw ConnectionError.unauthorized("Only the initiator can accept terms")
        }

        // Accept terms via TermsService
        try await TermsService.shared.acceptTerms(termsId: termsId)

        // Move to executing phase
        try await supabase
            .from("connections")
            .update([
                "status": ConnectionStatus.executing.rawValue,
                "phase": "3"
            ])
            .eq("id", value: connectionId.uuidString)
            .execute()

        // Reload
        connection = try await getConnection(id: connectionId)

        // Log event
        try await ConnectionEventService.shared.logEvent(
            connectionId: connectionId,
            type: .termsAccepted,
            payload: .terms(termsId: termsId)
        )

        return connection
    }

    // MARK: - Phase 3: EXTERNAL EXECUTION - Pay via Utility Portal

    /// Get the Guest Pay URL for a connection's bill
    func getGuestPayUrl(connectionId: UUID) async throws -> String? {
        let connection = try await getConnection(id: connectionId)

        let bill: SupportBill = try await supabase
            .from("support_bills")
            .select()
            .eq("id", value: connection.billId.uuidString)
            .single()
            .execute()
            .value

        return bill.guestPayLink
    }

    // MARK: - Phase 4: PROOF OF SUPPORT - Upload Payment Proof

    /// Submit proof of payment (supporter uploads screenshot)
    func submitProof(connectionId: UUID, proofUrl: String) async throws -> Connection {
        guard let userId = currentUserId else {
            throw ConnectionError.notAuthenticated
        }

        // Get connection
        var connection = try await getConnection(id: connectionId)

        // Verify user is the supporter
        guard connection.isSupporter(userId: userId) else {
            throw ConnectionError.unauthorized("Only the supporter can submit proof")
        }

        // Verify state
        guard connection.status == .executing else {
            throw ConnectionError.invalidState("Can only submit proof during execution phase")
        }

        // Update with proof
        try await supabase
            .from("connections")
            .update([
                "proof_url": proofUrl,
                "status": ConnectionStatus.proofing.rawValue,
                "phase": "4"
            ])
            .eq("id", value: connectionId.uuidString)
            .execute()

        // Reload
        connection = try await getConnection(id: connectionId)

        // Log event
        try await ConnectionEventService.shared.logEvent(
            connectionId: connectionId,
            type: .proofSubmitted,
            payload: .proof(proofUrl: proofUrl)
        )

        // Notify initiator to verify
        await NotificationService.shared.notifyProofSubmitted(connectionId: connectionId)

        return connection
    }

    /// Verify proof and complete the connection (initiator confirms)
    func verifyProof(connectionId: UUID) async throws -> Connection {
        guard let userId = currentUserId else {
            throw ConnectionError.notAuthenticated
        }

        // Get connection
        var connection = try await getConnection(id: connectionId)

        // Verify user is the initiator
        guard connection.isInitiator(userId: userId) else {
            throw ConnectionError.unauthorized("Only the initiator can verify proof")
        }

        // Verify state
        guard connection.status == .proofing else {
            throw ConnectionError.invalidState("Can only verify during proofing phase")
        }

        // Update proof verification
        try await supabase
            .from("connections")
            .update([
                "proof_verified_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: connectionId.uuidString)
            .execute()

        // Complete the connection
        connection = try await completeConnection(connectionId: connectionId)

        return connection
    }

    // MARK: - Phase 5: REPUTATION UPDATE

    /// Complete the connection and award reputation
    private func completeConnection(connectionId: UUID) async throws -> Connection {
        // Update to completed
        try await supabase
            .from("connections")
            .update([
                "status": ConnectionStatus.completed.rawValue,
                "phase": "5",
                "completed_at": ISO8601DateFormatter().string(from: Date()),
                "reputation_awarded": "true"
            ])
            .eq("id", value: connectionId.uuidString)
            .execute()

        // Get the connection
        let connection = try await getConnection(id: connectionId)

        // Award reputation to both users
        try await ReputationService.shared.awardReputation(
            userId: connection.initiatorId,
            connectionId: connectionId,
            role: .initiator
        )

        if let supporterId = connection.supporterId {
            try await ReputationService.shared.awardReputation(
                userId: supporterId,
                connectionId: connectionId,
                role: .supporter
            )
        }

        // Award Billix Score points (5 points per successful connection)
        // This awards to the current user who triggered the completion
        await BillixScoreService.shared.recordConnectionCompleted(connectionId: connectionId)

        // Award 5 Billix Points to both users in profiles table
        await awardBillixPoints(userId: connection.initiatorId, points: 5)
        if let supporterId = connection.supporterId {
            await awardBillixPoints(userId: supporterId, points: 5)
        }

        // Update bill status
        try await supabase
            .from("support_bills")
            .update(["status": SupportBillStatus.paid.rawValue])
            .eq("id", value: connection.billId.uuidString)
            .execute()

        // Log event
        try await ConnectionEventService.shared.logEvent(
            connectionId: connectionId,
            type: .connectionCompleted,
            payload: .completion(success: true)
        )

        // Notify both users
        await NotificationService.shared.notifyConnectionComplete(connection: connection)

        // Refresh
        try await fetchMyConnections()

        return connection
    }

    // MARK: - Cancel / Dispute

    /// Cancel a connection
    func cancelConnection(connectionId: UUID, reason: String? = nil) async throws {
        guard let userId = currentUserId else {
            throw ConnectionError.notAuthenticated
        }

        let connection = try await getConnection(id: connectionId)

        // Only participants can cancel
        guard connection.isInitiator(userId: userId) || connection.isSupporter(userId: userId) else {
            throw ConnectionError.unauthorized("Only participants can cancel")
        }

        // Can only cancel before completion
        guard connection.isActive else {
            throw ConnectionError.invalidState("Cannot cancel completed or disputed connections")
        }

        try await supabase
            .from("connections")
            .update([
                "status": ConnectionStatus.cancelled.rawValue,
                "cancelled_at": ISO8601DateFormatter().string(from: Date()),
                "cancel_reason": reason ?? ""
            ])
            .eq("id", value: connectionId.uuidString)
            .execute()

        // Log event
        try await ConnectionEventService.shared.logEvent(
            connectionId: connectionId,
            type: .connectionCancelled,
            payload: .cancellation(reason: reason, cancelledBy: userId)
        )

        try await fetchMyConnections()
    }

    /// Raise a dispute
    func raiseDispute(connectionId: UUID, reason: DisputeReason, details: String? = nil) async throws {
        guard let userId = currentUserId else {
            throw ConnectionError.notAuthenticated
        }

        let connection = try await getConnection(id: connectionId)

        // Only participants can dispute
        guard connection.isInitiator(userId: userId) || connection.isSupporter(userId: userId) else {
            throw ConnectionError.unauthorized("Only participants can raise disputes")
        }

        try await supabase
            .from("connections")
            .update(["status": ConnectionStatus.disputed.rawValue])
            .eq("id", value: connectionId.uuidString)
            .execute()

        // Log event
        try await ConnectionEventService.shared.logEvent(
            connectionId: connectionId,
            type: .disputeRaised,
            payload: .dispute(reason: reason, raisedBy: userId, details: details)
        )

        try await fetchMyConnections()
    }

    // MARK: - Fetch Methods

    /// Fetch all connections for current user
    func fetchMyConnections() async throws {
        guard let userId = currentUserId else {
            throw ConnectionError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let connections: [Connection] = try await supabase
            .from("connections")
            .select()
            .or("initiator_id.eq.\(userId.uuidString),supporter_id.eq.\(userId.uuidString)")
            .order("created_at", ascending: false)
            .execute()
            .value

        self.activeConnections = connections.filter { $0.isActive }
        self.completedConnections = connections.filter { $0.status == .completed }

        // Also get requests I initiated that are still waiting
        self.myRequests = connections.filter {
            $0.initiatorId == userId && $0.status == .requested
        }
    }

    /// Fetch Community Board (available support requests)
    func fetchCommunityBoard() async throws {
        guard let userId = currentUserId else {
            throw ConnectionError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Step 1: Get open connections (status = 'requested', no supporter yet)
        let openConnections: [Connection] = try await supabase
            .from("connections")
            .select()
            .eq("status", value: ConnectionStatus.requested.rawValue)
            .is("supporter_id", value: nil)
            .execute()
            .value

        // Create a lookup dictionary for connection info by billId
        let connectionsByBillId = Dictionary(uniqueKeysWithValues: openConnections.map { ($0.billId, $0) })
        let openBillIds = Set(openConnections.map { $0.billId })

        // Step 2: Get all posted bills that aren't from current user
        let allBills: [SupportBill] = try await supabase
            .from("support_bills")
            .select()
            .neq("user_id", value: userId.uuidString)
            .eq("status", value: SupportBillStatus.posted.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value

        // Step 3: Combine bills with their connection info
        self.communityRequests = allBills.compactMap { bill -> CommunityBoardItem? in
            guard openBillIds.contains(bill.id),
                  let connection = connectionsByBillId[bill.id] else {
                return nil
            }
            return CommunityBoardItem(
                bill: bill,
                connectionType: connection.connectionType,
                connectionCreatedAt: connection.createdAt
            )
        }
    }

    /// Get a specific connection by ID
    func getConnection(id: UUID) async throws -> Connection {
        let connection: Connection = try await supabase
            .from("connections")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return connection
    }

    /// Get a support bill by ID
    func getBill(id: UUID) async throws -> SupportBill {
        let bill: SupportBill = try await supabase
            .from("support_bills")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return bill
    }

    /// Get a connection by its associated bill ID (for offering support)
    func getConnectionByBillId(billId: UUID) async throws -> Connection {
        // Fetch all connections for this bill (don't use .single() to handle errors gracefully)
        let connections: [Connection] = try await supabase
            .from("connections")
            .select()
            .eq("bill_id", value: billId.uuidString)
            .execute()
            .value

        // Find a connection that's still open for support (status = requested)
        if let openConnection = connections.first(where: { $0.status == .requested }) {
            return openConnection
        }

        // If no open connection, check if it was already claimed
        if connections.contains(where: { $0.supporterId != nil }) {
            throw ConnectionError.billAlreadyClaimed
        }

        // No connection found at all
        throw ConnectionError.connectionNotFound
    }

    // MARK: - Billix Points & Trust Score

    /// Award Billix Points and Trust Score to a user's profile (displayed on Profile page)
    /// Points: raw count displayed as "BILLIX POINTS"
    /// Trust Score: 0-100 scale displayed as "BILLIX SCORE"
    private func awardBillixPoints(userId: UUID, points: Int) async {
        do {
            // First get current points and trust_score
            struct ProfileScores: Decodable {
                let points: Int?
                let trustScore: Int?

                enum CodingKeys: String, CodingKey {
                    case points
                    case trustScore = "trust_score"
                }
            }

            let profiles: [ProfileScores] = try await supabase
                .from("profiles")
                .select("points, trust_score")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            let currentPoints = profiles.first?.points ?? 0
            let currentTrustScore = profiles.first?.trustScore ?? 0

            let newPoints = currentPoints + points
            // Cap trust_score at 100
            let newTrustScore = min(100, currentTrustScore + points)

            // Update both points and trust_score
            try await supabase
                .from("profiles")
                .update([
                    "points": newPoints,
                    "trust_score": newTrustScore
                ])
                .eq("user_id", value: userId.uuidString)
                .execute()
        } catch {
            print("Failed to award Billix points and trust score: \(error)")
        }
    }

    // MARK: - Validation

    /// Validate bill amount against user's tier limit
    private func validateTierLimit(amount: Decimal, userId: UUID) async throws {
        let tier = try await ReputationService.shared.getUserTier(userId: userId)
        let maxAmount = Decimal(tier.maxAmount)

        guard amount <= maxAmount else {
            throw ConnectionError.amountExceedsTierLimit(
                amount: amount,
                limit: maxAmount,
                tier: tier
            )
        }
    }

    /// Check velocity limit for Neighbor tier (1/month)
    private func checkVelocityLimit(userId: UUID) async throws {
        let tier = try await ReputationService.shared.getUserTier(userId: userId)

        guard let velocityLimit = tier.velocityLimit else {
            // No limit for this tier
            return
        }

        let monthlyCount = try await ReputationService.shared.getMonthlyConnectionCount(userId: userId)

        guard monthlyCount < velocityLimit else {
            throw ConnectionError.velocityLimitReached(
                limit: velocityLimit,
                tier: tier
            )
        }
    }
}

// MARK: - Insert Models

private struct ConnectionInsert: Encodable {
    let initiatorId: UUID
    let billId: UUID
    let status: String
    let connectionType: String
    let phase: Int

    enum CodingKeys: String, CodingKey {
        case initiatorId = "initiator_id"
        case billId = "bill_id"
        case status
        case connectionType = "connection_type"
        case phase
    }

    init(initiatorId: UUID, billId: UUID, connectionType: ConnectionType) {
        self.initiatorId = initiatorId
        self.billId = billId
        self.status = ConnectionStatus.requested.rawValue
        self.connectionType = connectionType.rawValue
        self.phase = 1
    }
}

// MARK: - Errors

enum ConnectionError: LocalizedError {
    case notAuthenticated
    case connectionNotFound
    case invalidState(String)
    case unauthorized(String)
    case cannotSupportOwnRequest
    case billAlreadyClaimed
    case amountExceedsTierLimit(amount: Decimal, limit: Decimal, tier: ReputationTier)
    case velocityLimitReached(limit: Int, tier: ReputationTier)
    case insufficientTokens

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .connectionNotFound:
            return "Connection not found"
        case .invalidState(let message):
            return message
        case .unauthorized(let message):
            return message
        case .cannotSupportOwnRequest:
            return "You cannot offer support on your own request"
        case .billAlreadyClaimed:
            return "This bill has already been claimed by another supporter"
        case .amountExceedsTierLimit(let amount, let limit, let tier):
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            let amountStr = formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
            let limitStr = formatter.string(from: limit as NSDecimalNumber) ?? "$\(limit)"
            return "Bill amount \(amountStr) exceeds your \(tier.displayName) tier limit of \(limitStr)"
        case .velocityLimitReached(let limit, let tier):
            return "You've reached your monthly limit of \(limit) connection(s) as a \(tier.displayName). Upgrade to increase your limit."
        case .insufficientTokens:
            return "Not enough tokens to create a support request. You need 2 tokens."
        }
    }
}

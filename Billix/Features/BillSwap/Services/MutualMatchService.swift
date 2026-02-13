//
//  MutualMatchService.swift
//  Billix
//
//  Service for finding and managing mutual swap matches
//  Handles the matching algorithm and paired connection lifecycle
//

import Foundation
import Supabase

// MARK: - Potential Match Display Model

/// A potential mutual partner shown in the suggestions list
struct PotentialMutualMatch: Identifiable {
    let id: UUID                    // Suggestion ID
    let connection: Connection      // Their connection
    let bill: SupportBill           // Their bill
    let compatibilityScore: Int     // How well they match (0-100)
    let matchReasons: [String]      // Why this is a good match

    /// Compatibility level for display
    var compatibilityLevel: CompatibilityLevel {
        switch compatibilityScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .low
        }
    }
}

enum CompatibilityLevel {
    case excellent, good, fair, low

    var displayText: String {
        switch self {
        case .excellent: return "Excellent Match"
        case .good: return "Good Match"
        case .fair: return "Fair Match"
        case .low: return "Possible Match"
        }
    }

    var color: String {
        switch self {
        case .excellent: return "#4CAF7A"    // Green
        case .good: return "#5B8A6B"         // Money green
        case .fair: return "#E8A54B"         // Amber
        case .low: return "#8B9A94"          // Gray
        }
    }
}

// MARK: - Mutual Match Service

@MainActor
class MutualMatchService: ObservableObject {
    static let shared = MutualMatchService()

    private let supabase = SupabaseService.shared.client

    @Published var isLoading = false
    @Published var potentialMatches: [PotentialMutualMatch] = []
    @Published var errorMessage: String?

    private init() {}

    // MARK: - Find Matches

    /// Find potential mutual partners for a connection
    /// Returns other mutual requests that could be paired with this one
    func findMutualMatches(for connectionId: UUID, myBill: SupportBill) async throws -> [PotentialMutualMatch] {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        guard let userId = try? await supabase.auth.session.user.id else {
            throw MutualMatchError.notAuthenticated
        }

        // Query: Find other "mutual" connections where:
        // 1. Status is "requested" (still on Community Board)
        // 2. Different user (can't match with yourself)
        // 3. Not already paired (mutual_pair_id is null)
        // 4. Connection type is mutual

        let connections: [Connection] = try await supabase
            .from("connections")
            .select()
            .eq("connection_type", value: "mutual")
            .eq("status", value: "requested")
            .is("mutual_pair_id", value: nil)
            .neq("initiator_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        // Get the bills for these connections
        let billIds = connections.map { $0.billId.uuidString }

        guard !billIds.isEmpty else {
            potentialMatches = []
            return []
        }

        let bills: [SupportBill] = try await supabase
            .from("support_bills")
            .select()
            .in("id", values: billIds)
            .execute()
            .value

        let billsById = Dictionary(uniqueKeysWithValues: bills.map { ($0.id, $0) })

        // Calculate compatibility scores and create match objects
        var matches: [PotentialMutualMatch] = []

        for connection in connections {
            guard let bill = billsById[connection.billId] else { continue }

            let (score, reasons) = calculateCompatibility(myBill: myBill, theirBill: bill)

            let match = PotentialMutualMatch(
                id: UUID(), // Temporary ID for display
                connection: connection,
                bill: bill,
                compatibilityScore: score,
                matchReasons: reasons
            )
            matches.append(match)
        }

        // Sort by compatibility score (highest first)
        matches.sort { $0.compatibilityScore > $1.compatibilityScore }

        potentialMatches = matches
        return matches
    }

    // MARK: - Calculate Compatibility

    /// Calculate how compatible two bills are for mutual swap
    private func calculateCompatibility(myBill: SupportBill, theirBill: SupportBill) -> (score: Int, reasons: [String]) {
        var score = 0
        var reasons: [String] = []

        // Same category (+25 points)
        if myBill.category == theirBill.category {
            score += 25
            reasons.append("Same bill type")
        }

        // Similar amount (+20 points for within 20%)
        let amountDiff = abs(myBill.amount - theirBill.amount)
        let avgAmount = (myBill.amount + theirBill.amount) / 2
        if avgAmount > 0 {
            let diffPercent = amountDiff / avgAmount
            if diffPercent <= 0.1 {
                score += 20
                reasons.append("Very similar amount")
            } else if diffPercent <= 0.2 {
                score += 15
                reasons.append("Similar amount")
            } else if diffPercent <= 0.3 {
                score += 10
                reasons.append("Comparable amount")
            }
        }

        // Same state (+15 points) - based on zip code comparison
        let myState = stateFromZip(myBill.zipCode ?? "")
        let theirState = stateFromZip(theirBill.zipCode ?? "")
        if !myState.isEmpty && myState == theirState {
            score += 15
            reasons.append("Same state")
        }

        // Recency bonus (+10 points if posted in last 24 hours)
        if Date().timeIntervalSince(theirBill.createdAt) < 24 * 60 * 60 {
            score += 10
            reasons.append("Recently posted")
        }

        // Due date urgency alignment (+10 points if both urgent or both not)
        let myUrgent = (myBill.daysUntilDue ?? 30) <= 7
        let theirUrgent = (theirBill.daysUntilDue ?? 30) <= 7
        if myUrgent == theirUrgent {
            score += 10
            if myUrgent {
                reasons.append("Both need help soon")
            }
        }

        // Base score for any mutual request (+20 points)
        score += 20

        return (min(score, 100), reasons)
    }

    /// Extract state abbreviation from zip code (simple lookup)
    private func stateFromZip(_ zip: String) -> String {
        guard zip.count >= 3 else { return "" }
        let prefix = String(zip.prefix(3))

        // Basic zip code to state mapping (first 3 digits)
        let zipToState: [String: String] = [
            "070": "NJ", "071": "NJ", "072": "NJ", "073": "NJ", "074": "NJ",
            "075": "NJ", "076": "NJ", "077": "NJ", "078": "NJ", "079": "NJ",
            "080": "NJ", "081": "NJ", "082": "NJ", "083": "NJ", "084": "NJ",
            "085": "NJ", "086": "NJ", "087": "NJ", "088": "NJ", "089": "NJ",
            "100": "NY", "101": "NY", "102": "NY", "103": "NY", "104": "NY",
            "105": "NY", "106": "NY", "107": "NY", "108": "NY", "109": "NY",
            "110": "NY", "111": "NY", "112": "NY", "113": "NY", "114": "NY",
            "115": "NY", "116": "NY", "117": "NY", "118": "NY", "119": "NY"
            // Add more as needed
        ]

        return zipToState[prefix] ?? ""
    }

    // MARK: - Accept Match

    /// Accept a mutual match - creates both linked connections
    /// Returns the MutualPair with both connections
    func acceptMutualMatch(myConnectionId: UUID, theirConnectionId: UUID) async throws -> MutualPair {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        guard let userId = try? await supabase.auth.session.user.id else {
            throw MutualMatchError.notAuthenticated
        }

        // Generate shared pair ID
        let pairId = UUID()

        // Get both connections
        var myConnection: Connection = try await supabase
            .from("connections")
            .select()
            .eq("id", value: myConnectionId.uuidString)
            .single()
            .execute()
            .value

        var theirConnection: Connection = try await supabase
            .from("connections")
            .select()
            .eq("id", value: theirConnectionId.uuidString)
            .single()
            .execute()
            .value

        // Verify both are eligible for pairing
        guard myConnection.connectionType == .mutual,
              theirConnection.connectionType == .mutual,
              myConnection.status == .requested,
              theirConnection.status == .requested,
              myConnection.mutualPairId == nil,
              theirConnection.mutualPairId == nil else {
            throw MutualMatchError.invalidMatchState
        }

        // Update MY connection: set pair ID, set their user as my supporter
        try await supabase
            .from("connections")
            .update([
                "mutual_pair_id": pairId.uuidString,
                "supporter_id": theirConnection.initiatorId.uuidString,
                "status": "handshake",
                "phase": "2",
                "matched_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: myConnectionId.uuidString)
            .execute()

        // Update THEIR connection: set pair ID, set me as their supporter
        try await supabase
            .from("connections")
            .update([
                "mutual_pair_id": pairId.uuidString,
                "supporter_id": userId.uuidString,
                "status": "handshake",
                "phase": "2",
                "matched_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: theirConnectionId.uuidString)
            .execute()

        // Log events for both connections
        try await logMutualMatchEvent(connectionId: myConnectionId, eventType: "mutual_matched", pairId: pairId)
        try await logMutualMatchEvent(connectionId: theirConnectionId, eventType: "mutual_matched", pairId: pairId)

        // Refresh connections with updated data
        myConnection = try await supabase
            .from("connections")
            .select()
            .eq("id", value: myConnectionId.uuidString)
            .single()
            .execute()
            .value

        theirConnection = try await supabase
            .from("connections")
            .select()
            .eq("id", value: theirConnectionId.uuidString)
            .single()
            .execute()
            .value

        // Send notifications to both users
        await sendMutualMatchNotifications(myConnection: myConnection, theirConnection: theirConnection)

        return MutualPair(
            pairId: pairId,
            connectionA: myConnection,
            connectionB: theirConnection
        )
    }

    // MARK: - Cancel Mutual Pair

    /// Cancel a mutual pair - cancels BOTH connections and applies penalty
    func cancelMutualPair(pairId: UUID, reason: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        guard let userId = try? await supabase.auth.session.user.id else {
            throw MutualMatchError.notAuthenticated
        }

        // Find both connections with this pair ID
        let connections: [Connection] = try await supabase
            .from("connections")
            .select()
            .eq("mutual_pair_id", value: pairId.uuidString)
            .execute()
            .value

        guard connections.count == 2 else {
            throw MutualMatchError.pairNotFound
        }

        let now = ISO8601DateFormatter().string(from: Date())

        // Cancel both connections
        for connection in connections {
            try await supabase
                .from("connections")
                .update([
                    "status": "cancelled",
                    "cancelled_at": now,
                    "cancel_reason": reason
                ])
                .eq("id", value: connection.id.uuidString)
                .execute()

            // Log cancellation event
            try await logMutualMatchEvent(
                connectionId: connection.id,
                eventType: "mutual_pair_cancelled",
                pairId: pairId,
                metadata: ["reason": reason, "cancelled_by": userId.uuidString]
            )
        }

        // Apply reputation penalty to the cancelling user
        try await ReputationService.shared.penalizeMutualSwapFailure(
            userId: userId,
            pairId: pairId,
            reason: .abandonedConnection
        )

        // Notify both users
        for connection in connections {
            await sendMutualCancellationNotification(connection: connection, reason: reason)
        }
    }

    // MARK: - Get Paired Connection

    /// Get the partner connection for a mutual pair
    func getPairedConnection(for connectionId: UUID) async throws -> Connection? {
        guard let connection: Connection = try? await supabase
            .from("connections")
            .select()
            .eq("id", value: connectionId.uuidString)
            .single()
            .execute()
            .value,
              let pairId = connection.mutualPairId else {
            return nil
        }

        let pairedConnection: Connection = try await supabase
            .from("connections")
            .select()
            .eq("mutual_pair_id", value: pairId.uuidString)
            .neq("id", value: connectionId.uuidString)
            .single()
            .execute()
            .value

        return pairedConnection
    }

    // MARK: - Helper Methods

    private func logMutualMatchEvent(
        connectionId: UUID,
        eventType: String,
        pairId: UUID,
        metadata: [String: String]? = nil
    ) async throws {
        var eventData: [String: String] = [
            "connection_id": connectionId.uuidString,
            "event_type": eventType,
            "mutual_pair_id": pairId.uuidString
        ]

        if let metadata = metadata {
            for (key, value) in metadata {
                eventData[key] = value
            }
        }

        try await supabase
            .from("connection_events")
            .insert(eventData)
            .execute()
    }

    private func sendMutualMatchNotifications(myConnection: Connection, theirConnection: Connection) async {
        // Send push notifications via Edge Function
        do {
            let request = [
                "type": "mutual_match_created",
                "connection_a_id": myConnection.id.uuidString,
                "connection_b_id": theirConnection.id.uuidString,
                "pair_id": myConnection.mutualPairId?.uuidString ?? ""
            ]

            try await supabase.functions
                .invoke("notify-connection-event", options: .init(body: request))
        } catch {
            print("Failed to send mutual match notifications: \(error)")
        }
    }

    private func sendMutualCancellationNotification(connection: Connection, reason: String) async {
        do {
            let request = [
                "type": "mutual_pair_cancelled",
                "connection_id": connection.id.uuidString,
                "user_id": connection.initiatorId.uuidString,
                "reason": reason
            ]

            try await supabase.functions
                .invoke("notify-connection-event", options: .init(body: request))
        } catch {
            print("Failed to send cancellation notification: \(error)")
        }
    }
}

// MARK: - Errors

enum MutualMatchError: LocalizedError {
    case notAuthenticated
    case invalidMatchState
    case pairNotFound
    case alreadyPaired

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to match"
        case .invalidMatchState:
            return "One or both connections are no longer available for matching"
        case .pairNotFound:
            return "Could not find the mutual pair"
        case .alreadyPaired:
            return "This connection is already paired"
        }
    }
}

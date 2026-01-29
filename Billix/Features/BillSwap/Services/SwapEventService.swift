//
//  SwapEventService.swift
//  Billix
//
//  Service for logging and retrieving swap events (evidence trail)
//

import Foundation
import Supabase

/// Service for managing swap event/evidence trail
@MainActor
class SwapEventService: ObservableObject {

    // MARK: - Singleton

    static let shared = SwapEventService()

    // MARK: - Published Properties

    @Published var events: [SwapEvent] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    private init() {}

    // MARK: - Fetch Events

    /// Get all events for a swap
    func getEvents(for swapId: UUID) async throws -> [SwapEvent] {
        isLoading = true
        defer { isLoading = false }

        let fetchedEvents: [SwapEvent] = try await supabase
            .from("swap_events")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        events = fetchedEvents
        return fetchedEvents
    }

    /// Get significant events only (for summary view)
    func getSignificantEvents(for swapId: UUID) async throws -> [SwapEvent] {
        let allEvents = try await getEvents(for: swapId)
        return allEvents.significantEvents
    }

    /// Get events grouped by date
    func getGroupedEvents(for swapId: UUID) async throws -> [SwapEventGroup] {
        let allEvents = try await getEvents(for: swapId)
        return allEvents.groupedByDate()
    }

    /// Get the most recent event for a swap
    func getLatestEvent(for swapId: UUID) async throws -> SwapEvent? {
        let latestEvents: [SwapEvent] = try await supabase
            .from("swap_events")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return latestEvents.first
    }

    // MARK: - Log Events

    /// Log a new event to the swap timeline
    func logEvent(
        swapId: UUID,
        type: SwapEventType,
        payload: SwapEventPayload? = nil
    ) async throws {
        guard let userId = currentUserId else {
            throw SwapEventError.notAuthenticated
        }

        let insert = SwapEventInsert(
            swapId: swapId,
            actorId: userId,
            type: type,
            payload: payload
        )

        try await supabase
            .from("swap_events")
            .insert(insert)
            .execute()

        // Send notification for significant events
        if type.isSignificant {
            await sendEventNotification(swapId: swapId, type: type)
        }
    }

    /// Log a system event (no user actor)
    func logSystemEvent(
        swapId: UUID,
        type: SwapEventType,
        payload: SwapEventPayload? = nil
    ) async throws {
        // System events use a placeholder UUID
        let systemId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

        let insert = SwapEventInsert(
            swapId: swapId,
            actorId: systemId,
            type: type,
            payload: payload
        )

        try await supabase
            .from("swap_events")
            .insert(insert)
            .execute()
    }

    // MARK: - Event Helpers

    /// Send notification for an event
    private func sendEventNotification(swapId: UUID, type: SwapEventType) async {
        // Get the swap to find the partner
        let swaps: [BillSwapTransaction] = (try? await supabase
            .from("swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .limit(1)
            .execute()
            .value) ?? []

        guard let swap = swaps.first,
              let userId = currentUserId else { return }

        let partnerId = swap.partnerId(for: userId)

        // Create notification based on event type using in-app toast
        switch type {
        case .dealProposed:
            NotificationService.shared.addNotification(
                type: .reminder,
                subtitle: "Your swap partner proposed new terms. Review and respond within 24 hours.",
                swapId: swapId
            )
        case .dealAccepted:
            NotificationService.shared.addNotification(
                type: .matchFound,
                subtitle: "Your swap is now active. Time to pay your partner's bill.",
                swapId: swapId
            )
        case .paymentProofSubmitted:
            NotificationService.shared.addNotification(
                type: .billPaid,
                subtitle: "Your partner uploaded payment proof. Check and confirm.",
                swapId: swapId
            )
        case .extensionRequested:
            NotificationService.shared.addNotification(
                type: .reminder,
                subtitle: "Your partner requested more time. Review and respond.",
                swapId: swapId
            )
        case .disputeOpened:
            NotificationService.shared.addNotification(
                type: .reminder,
                subtitle: "A dispute has been opened for your swap. Platform review pending.",
                swapId: swapId
            )
        default:
            break
        }
    }

    /// Check if an event type has occurred for a swap
    func hasEventOccurred(swapId: UUID, type: SwapEventType) async throws -> Bool {
        let events: [SwapEvent] = try await supabase
            .from("swap_events")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .eq("event_type", value: type.rawValue)
            .limit(1)
            .execute()
            .value

        return !events.isEmpty
    }

    /// Get count of unread events (events after last viewed timestamp)
    func getUnreadCount(for swapId: UUID, since: Date) async throws -> Int {
        let events: [SwapEvent] = try await supabase
            .from("swap_events")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .gt("created_at", value: ISO8601DateFormatter().string(from: since))
            .execute()
            .value

        return events.count
    }

    // MARK: - Export Timeline

    /// Export timeline as JSON for dispute evidence
    func exportTimelineJSON(for swapId: UUID) async throws -> Data {
        let allEvents = try await getEvents(for: swapId)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        return try encoder.encode(allEvents)
    }

    /// Export timeline as formatted text
    func exportTimelineText(for swapId: UUID) async throws -> String {
        let allEvents = try await getEvents(for: swapId)

        var text = "SWAP TIMELINE - ID: \(swapId.uuidString)\n"
        text += "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .medium))\n"
        text += String(repeating: "=", count: 60) + "\n\n"

        for event in allEvents {
            let dateStr = DateFormatter.localizedString(from: event.createdAt, dateStyle: .medium, timeStyle: .medium)
            text += "[\(dateStr)]\n"
            text += "Event: \(event.eventType.displayName)\n"
            text += "Actor: \(event.actorId.uuidString)\n"

            if let payload = event.payload {
                if let note = payload.note {
                    text += "Note: \(note)\n"
                }
                if let proofUrl = payload.proofUrl {
                    text += "Proof: \(proofUrl)\n"
                }
                if let amount = payload.amountA {
                    text += "Amount A: $\(amount)\n"
                }
                if let amount = payload.amountB {
                    text += "Amount B: $\(amount)\n"
                }
            }

            text += "\n"
        }

        return text
    }
}

// MARK: - Errors

enum SwapEventError: LocalizedError {
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

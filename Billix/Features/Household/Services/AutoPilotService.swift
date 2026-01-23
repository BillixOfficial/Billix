//
//  AutoPilotService.swift
//  Billix
//
//  Service for Auto-Pilot bill escalation algorithm.
//  Day 1-2: Internal household matching only
//  Day 3: Alert owner about escalation
//  Day 4+: Escalate to public marketplace
//

import Foundation
import Supabase

@MainActor
class AutoPilotService: ObservableObject {
    static let shared = AutoPilotService()

    private let supabase = SupabaseService.shared.client
    private let householdService = HouseholdService.shared

    @Published var autoPilotBills: [HouseholdBill] = []
    @Published var pendingEscalations: [EscalationAlert] = []
    @Published var isLoading = false

    private init() {}

    // MARK: - Auto-Pilot Configuration

    /// Enable Auto-Pilot for a household bill
    func enableAutoPilot(billId: UUID) async throws {
        let updates: [String: AnyEncodable] = [
            "auto_pilot_enabled": AnyEncodable(true),
            "escalation_started_at": AnyEncodable(ISO8601DateFormatter().string(from: Date())),
            "escalation_stage": AnyEncodable(0)
        ]

        try await supabase
            .from("household_bills")
            .update(updates)
            .eq("id", value: billId.uuidString)
            .execute()

        await fetchAutoPilotBills()
    }

    /// Disable Auto-Pilot for a bill
    func disableAutoPilot(billId: UUID) async throws {
        let updates: [String: AnyEncodable] = [
            "auto_pilot_enabled": AnyEncodable(false),
            "escalation_started_at": AnyEncodable(nil as String?),
            "escalation_stage": AnyEncodable(0)
        ]

        try await supabase
            .from("household_bills")
            .update(updates)
            .eq("id", value: billId.uuidString)
            .execute()

        await fetchAutoPilotBills()
    }

    /// Fetch all bills with Auto-Pilot enabled
    func fetchAutoPilotBills() async {
        guard let household = householdService.currentHousehold else {
            autoPilotBills = []
            return
        }

        do {
            let bills: [HouseholdBill] = try await supabase
                .from("household_bills")
                .select("*, swap_bills(id, provider_name, bill_type, amount, status)")
                .eq("household_id", value: household.id.uuidString)
                .eq("auto_pilot_enabled", value: true)
                .order("escalation_started_at", ascending: true)
                .execute()
                .value

            autoPilotBills = bills

            // Check for pending escalations
            updatePendingEscalations()
        } catch {
            print("Failed to fetch Auto-Pilot bills: \(error)")
        }
    }

    // MARK: - Escalation Processing

    /// Process escalations for all Auto-Pilot bills
    /// This should be called periodically (e.g., on app launch, daily)
    func processEscalations() async throws {
        guard let household = householdService.currentHousehold else { return }

        isLoading = true
        defer { isLoading = false }

        let bills = autoPilotBills.filter { $0.autoPilotEnabled }

        for bill in bills {
            guard let startedAt = bill.escalationStartedAt else { continue }

            let daysSinceStart = Calendar.current.dateComponents(
                [.day],
                from: startedAt,
                to: Date()
            ).day ?? 0

            let currentStage = bill.escalationStage
            var newStage = currentStage

            switch daysSinceStart {
            case 0..<3:
                // Day 1-2: Internal only (stage 0)
                newStage = 0
            case 3:
                // Day 3: Alert owner (stage 1)
                if currentStage < 1 {
                    newStage = 1
                    await sendEscalationAlert(bill: bill, stage: .alerted)
                }
            default:
                // Day 4+: Go public (stage 2)
                if currentStage < 2 {
                    newStage = 2
                    try await escalateToPublic(bill: bill)
                    await sendEscalationAlert(bill: bill, stage: .public)
                }
            }

            // Update stage if changed
            if newStage != currentStage {
                try await supabase
                    .from("household_bills")
                    .update(["escalation_stage": newStage])
                    .eq("id", value: bill.id.uuidString)
                    .execute()
            }
        }

        await fetchAutoPilotBills()
    }

    /// Escalate a bill to the public marketplace
    private func escalateToPublic(bill: HouseholdBill) async throws {
        // Update visibility to public
        try await supabase
            .from("household_bills")
            .update(["visibility": "public"])
            .eq("id", value: bill.id.uuidString)
            .execute()

        // Also update the swap_bill if needed
        if let swapBillId = bill.swapBillId {
            try await supabase
                .from("swap_bills")
                .update(["household_only": false])
                .eq("id", value: swapBillId.uuidString)
                .execute()
        }
    }

    /// Send escalation alert to bill owner
    private func sendEscalationAlert(bill: HouseholdBill, stage: EscalationStatus) async {
        let alert = EscalationAlert(
            bill: bill,
            stage: stage,
            message: stage == .alerted
                ? "Your bill hasn't found a match yet. It will go public tomorrow if no internal match is found."
                : "Your bill is now available on the public marketplace.",
            createdAt: Date()
        )

        // Add to pending alerts
        pendingEscalations.append(alert)

        // In production, this would trigger a push notification
        // await NotificationService.shared.sendEscalationNotification(alert)
    }

    // MARK: - Escalation Status

    /// Get the escalation timeline for a bill
    func getEscalationTimeline(bill: HouseholdBill) -> EscalationTimeline {
        guard let startedAt = bill.escalationStartedAt else {
            return EscalationTimeline(
                startDate: nil,
                internalEndDate: nil,
                alertDate: nil,
                publicDate: nil,
                currentStage: .internal,
                daysRemaining: nil
            )
        }

        let calendar = Calendar.current

        let internalEnd = calendar.date(byAdding: .day, value: 2, to: startedAt)
        let alertDate = calendar.date(byAdding: .day, value: 3, to: startedAt)
        let publicDate = calendar.date(byAdding: .day, value: 4, to: startedAt)

        let daysSinceStart = calendar.dateComponents([.day], from: startedAt, to: Date()).day ?? 0

        let currentStage: EscalationStatus
        let daysRemaining: Int?

        switch daysSinceStart {
        case 0..<3:
            currentStage = .internal
            daysRemaining = 3 - daysSinceStart
        case 3:
            currentStage = .alerted
            daysRemaining = 1
        default:
            currentStage = .public
            daysRemaining = nil
        }

        return EscalationTimeline(
            startDate: startedAt,
            internalEndDate: internalEnd,
            alertDate: alertDate,
            publicDate: publicDate,
            currentStage: currentStage,
            daysRemaining: daysRemaining
        )
    }

    /// Update pending escalations based on current bills
    private func updatePendingEscalations() {
        pendingEscalations = autoPilotBills.compactMap { bill in
            guard bill.escalationStage >= 1 else { return nil }

            let stage = EscalationStatus(rawValue: bill.escalationStage) ?? .alerted

            return EscalationAlert(
                bill: bill,
                stage: stage,
                message: stage == .alerted
                    ? "Bill will go public soon"
                    : "Bill is now public",
                createdAt: bill.escalationStartedAt ?? Date()
            )
        }
    }

    /// Cancel escalation and keep bill internal
    func cancelEscalation(billId: UUID) async throws {
        let updates: [String: AnyEncodable] = [
            "auto_pilot_enabled": AnyEncodable(false),
            "escalation_stage": AnyEncodable(0),
            "visibility": AnyEncodable("household")
        ]

        try await supabase
            .from("household_bills")
            .update(updates)
            .eq("id", value: billId.uuidString)
            .execute()

        // Remove from pending alerts
        pendingEscalations.removeAll { $0.bill.id == billId }

        await fetchAutoPilotBills()
    }

    /// Manually escalate a bill to public immediately
    func manualEscalateToPublic(billId: UUID) async throws {
        guard let bill = autoPilotBills.first(where: { $0.id == billId }) else { return }

        try await escalateToPublic(bill: bill)

        let updates: [String: AnyEncodable] = [
            "escalation_stage": AnyEncodable(2),
            "visibility": AnyEncodable("public")
        ]

        try await supabase
            .from("household_bills")
            .update(updates)
            .eq("id", value: billId.uuidString)
            .execute()

        await fetchAutoPilotBills()
    }
}

// MARK: - Supporting Types

struct EscalationAlert: Identifiable {
    var id: UUID { bill.id }
    let bill: HouseholdBill
    let stage: EscalationStatus
    let message: String
    let createdAt: Date
}

struct EscalationTimeline {
    let startDate: Date?
    let internalEndDate: Date?
    let alertDate: Date?
    let publicDate: Date?
    let currentStage: EscalationStatus
    let daysRemaining: Int?

    var statusMessage: String {
        guard let remaining = daysRemaining else {
            return "Now public on marketplace"
        }

        switch currentStage {
        case .internal:
            return "\(remaining) day\(remaining == 1 ? "" : "s") until alert"
        case .alerted:
            return "Goes public tomorrow"
        case .public:
            return "Now public"
        }
    }
}

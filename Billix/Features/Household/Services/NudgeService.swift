//
//  NudgeService.swift
//  Billix
//
//  Service for sending and receiving nudge reminders
//  with haptic feedback for social pressure.
//

import Foundation
import Supabase
import class UIKit.UIImpactFeedbackGenerator
import class UIKit.UINotificationFeedbackGenerator

@MainActor
class NudgeService: ObservableObject {
    static let shared = NudgeService()

    private let supabase = SupabaseService.shared.client
    private let householdService = HouseholdService.shared
    private let karmaService = KarmaService.shared

    @Published var receivedNudges: [NudgeReminder] = []
    @Published var sentNudges: [NudgeReminder] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false

    private init() {}

    // MARK: - Send Nudge

    /// Send a nudge reminder to another household member
    func sendNudge(toUserId: UUID, billId: UUID? = nil, message: String? = nil) async throws {
        guard let household = householdService.currentHousehold,
              let fromUserId = supabase.auth.currentUser?.id else {
            throw HouseholdError.noHousehold
        }

        // Can't nudge yourself
        guard toUserId != fromUserId else {
            throw NudgeError.cannotNudgeSelf
        }

        // Check if user is in household
        let isMember = householdService.members.contains { $0.userId == toUserId }
        guard isMember else {
            throw NudgeError.notInHousehold
        }

        isLoading = true
        defer { isLoading = false }

        // Create nudge
        let nudgeInsert: [String: AnyEncodable] = [
            "household_id": AnyEncodable(household.id),
            "from_user_id": AnyEncodable(fromUserId),
            "to_user_id": AnyEncodable(toUserId),
            "bill_id": AnyEncodable(billId),
            "message": AnyEncodable(message ?? defaultNudgeMessage())
        ]

        try await supabase
            .from("nudge_reminders")
            .insert(nudgeInsert)
            .execute()

        // Trigger haptic on sender's device
        triggerSentHaptic()

        await fetchSentNudges()
    }

    /// Send a bill-specific nudge
    func sendBillNudge(toUserId: UUID, bill: HouseholdBill) async throws {
        let message = "Hey! Can you take a look at the \(bill.swapBill?.providerName ?? "bill")?"
        try await sendNudge(toUserId: toUserId, billId: bill.id, message: message)
    }

    // MARK: - Receive & Respond

    /// Fetch nudges received by current user
    func fetchReceivedNudges() async {
        guard let userId = supabase.auth.currentUser?.id else { return }

        do {
            let nudges: [NudgeReminder] = try await supabase
                .from("nudge_reminders")
                .select("*, from_profiles:from_user_id(id, display_name, avatar_url), household_bills(id, swap_bills(provider_name, bill_type, amount))")
                .eq("to_user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            receivedNudges = nudges
            unreadCount = nudges.filter { !$0.isRead }.count

            // Trigger haptic if there are new unread nudges
            if unreadCount > 0 {
                triggerReceivedHaptic()
            }
        } catch {
            print("Failed to fetch received nudges: \(error)")
        }
    }

    /// Fetch nudges sent by current user
    func fetchSentNudges() async {
        guard let userId = supabase.auth.currentUser?.id else { return }

        do {
            let nudges: [NudgeReminder] = try await supabase
                .from("nudge_reminders")
                .select("*, to_profiles:to_user_id(id, display_name, avatar_url)")
                .eq("from_user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            sentNudges = nudges
        } catch {
            print("Failed to fetch sent nudges: \(error)")
        }
    }

    /// Mark a nudge as read
    func markAsRead(nudgeId: UUID) async throws {
        try await supabase
            .from("nudge_reminders")
            .update(["is_read": true])
            .eq("id", value: nudgeId.uuidString)
            .execute()

        await fetchReceivedNudges()
    }

    /// Mark all nudges as read
    func markAllAsRead() async throws {
        guard let userId = supabase.auth.currentUser?.id else { return }

        try await supabase
            .from("nudge_reminders")
            .update(["is_read": true])
            .eq("to_user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()

        await fetchReceivedNudges()
    }

    /// Respond to a nudge (marks as responded and awards karma)
    func respondToNudge(nudgeId: UUID) async throws {
        // Update nudge
        let updates: [String: AnyEncodable] = [
            "is_read": AnyEncodable(true),
            "responded_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        try await supabase
            .from("nudge_reminders")
            .update(updates)
            .eq("id", value: nudgeId.uuidString)
            .execute()

        // Award karma for responding
        try await karmaService.awardKarma(
            eventType: .nudgeResponded,
            description: "Responded to a nudge"
        )

        // Trigger positive haptic
        triggerRespondedHaptic()

        await fetchReceivedNudges()
    }

    // MARK: - Haptic Feedback

    /// Light tap when sending a nudge
    private func triggerSentHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Medium tap when receiving a nudge (social pressure)
    private func triggerReceivedHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    /// Success tap when responding to nudge
    private func triggerRespondedHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Trigger haptic externally (for UI components)
    func triggerNudgeHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Helpers

    private func defaultNudgeMessage() -> String {
        let messages = [
            "Hey! Just a friendly reminder about the bills",
            "Don't forget about the household bills!",
            "Quick nudge about our shared expenses",
            "Time to check on the bills!"
        ]
        return messages.randomElement() ?? messages[0]
    }

    /// Get time since nudge was sent
    func timeSinceNudge(_ nudge: NudgeReminder) -> String {
        let interval = Date().timeIntervalSince(nudge.createdAt)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    /// Check if can send another nudge (cooldown)
    func canNudge(userId: UUID) -> Bool {
        // Check for recent nudges (1 hour cooldown)
        let recentNudge = sentNudges.first { nudge in
            nudge.toUserId == userId &&
            Date().timeIntervalSince(nudge.createdAt) < 3600
        }
        return recentNudge == nil
    }
}

// MARK: - Errors

enum NudgeError: LocalizedError {
    case cannotNudgeSelf
    case notInHousehold
    case cooldownActive

    var errorDescription: String? {
        switch self {
        case .cannotNudgeSelf:
            return "You can't nudge yourself"
        case .notInHousehold:
            return "This person is not in your household"
        case .cooldownActive:
            return "Please wait before sending another nudge"
        }
    }
}

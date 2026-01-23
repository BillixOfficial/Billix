//
//  KarmaService.swift
//  Billix
//
//  Service for karma scoring, leaderboard tracking,
//  and monthly household hero selection.
//

import Foundation
import Supabase

@MainActor
class KarmaService: ObservableObject {
    static let shared = KarmaService()

    private let supabase = SupabaseService.shared.client
    private let householdService = HouseholdService.shared

    @Published var leaderboard: [KarmaLeaderboardEntry] = []
    @Published var monthlyHero: HouseholdHero?
    @Published var recentEvents: [KarmaEvent] = []
    @Published var isLoading = false

    private init() {}

    // MARK: - Karma Events

    /// Award karma to a user for an event
    func awardKarma(eventType: KarmaEventType, userId: UUID? = nil, description: String? = nil, relatedBillId: UUID? = nil) async throws {
        guard let household = householdService.currentHousehold else {
            throw HouseholdError.noHousehold
        }

        let targetUserId = userId ?? supabase.auth.currentUser?.id
        guard let targetUserId = targetUserId else {
            throw HouseholdError.notAuthenticated
        }

        // Insert karma event
        let eventInsert: [String: AnyEncodable] = [
            "household_id": AnyEncodable(household.id),
            "user_id": AnyEncodable(targetUserId),
            "event_type": AnyEncodable(eventType.rawValue),
            "karma_change": AnyEncodable(eventType.karmaPoints),
            "description": AnyEncodable(description),
            "related_bill_id": AnyEncodable(relatedBillId)
        ]

        try await supabase
            .from("karma_events")
            .insert(eventInsert)
            .execute()

        // Update member's karma scores
        try await updateMemberKarma(userId: targetUserId, points: eventType.karmaPoints)

        // Refresh data
        await fetchRecentEvents()
        await fetchLeaderboard()
    }

    /// Update member's karma score and monthly karma
    private func updateMemberKarma(userId: UUID, points: Int) async throws {
        guard let household = householdService.currentHousehold else { return }

        // Get current scores
        let member: HouseholdMemberModel? = try await supabase
            .from("household_members")
            .select()
            .eq("household_id", value: household.id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        guard let member = member else { return }

        // Update scores
        try await supabase
            .from("household_members")
            .update([
                "karma_score": member.karmaScore + points,
                "monthly_karma": member.monthlyKarma + points
            ])
            .eq("id", value: member.id.uuidString)
            .execute()
    }

    // MARK: - Leaderboard

    /// Fetch the karma leaderboard for current household
    func fetchLeaderboard() async {
        guard let household = householdService.currentHousehold else {
            leaderboard = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let members: [HouseholdMemberModel] = try await supabase
                .from("household_members")
                .select("*, profiles:user_id(id, display_name, avatar_url)")
                .eq("household_id", value: household.id.uuidString)
                .eq("is_active", value: true)
                .is("left_at", value: nil)
                .order("monthly_karma", ascending: false)
                .execute()
                .value

            let currentUserId = supabase.auth.currentUser?.id

            leaderboard = members.enumerated().map { index, member in
                KarmaLeaderboardEntry(
                    member: member,
                    rank: index + 1,
                    isCurrentUser: member.userId == currentUserId,
                    previousRank: nil // Could track historical ranks
                )
            }

            // Determine monthly hero (top karma this month)
            if let topMember = members.first, topMember.monthlyKarma > 0 {
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMMM yyyy"

                monthlyHero = HouseholdHero(
                    member: topMember,
                    month: monthFormatter.string(from: Date()),
                    totalKarma: topMember.monthlyKarma,
                    topAchievement: await getTopAchievement(for: topMember.userId)
                )
            }
        } catch {
            print("Failed to fetch leaderboard: \(error)")
        }
    }

    /// Get the most frequent karma event type for a user this month
    private func getTopAchievement(for userId: UUID) async -> KarmaEventType? {
        guard let household = householdService.currentHousehold else { return nil }

        // Get start of current month
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!

        do {
            let events: [KarmaEvent] = try await supabase
                .from("karma_events")
                .select()
                .eq("household_id", value: household.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .gte("created_at", value: ISO8601DateFormatter().string(from: startOfMonth))
                .execute()
                .value

            // Count events by type
            var typeCounts: [KarmaEventType: Int] = [:]
            for event in events {
                typeCounts[event.eventType, default: 0] += 1
            }

            // Return most frequent
            return typeCounts.max(by: { $0.value < $1.value })?.key
        } catch {
            return nil
        }
    }

    // MARK: - Recent Events

    /// Fetch recent karma events for the household
    func fetchRecentEvents(limit: Int = 20) async {
        guard let household = householdService.currentHousehold else {
            recentEvents = []
            return
        }

        do {
            let events: [KarmaEvent] = try await supabase
                .from("karma_events")
                .select()
                .eq("household_id", value: household.id.uuidString)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            recentEvents = events
        } catch {
            print("Failed to fetch karma events: \(error)")
        }
    }

    /// Get karma summary for a specific user
    func getKarmaSummary(for userId: UUID) async -> KarmaSummary? {
        guard let household = householdService.currentHousehold else { return nil }

        do {
            let member: HouseholdMemberModel? = try await supabase
                .from("household_members")
                .select()
                .eq("household_id", value: household.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            guard let member = member else { return nil }

            // Get event breakdown
            let events: [KarmaEvent] = try await supabase
                .from("karma_events")
                .select()
                .eq("household_id", value: household.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            var breakdown: [KarmaEventType: Int] = [:]
            for event in events {
                breakdown[event.eventType, default: 0] += event.karmaChange
            }

            return KarmaSummary(
                totalKarma: member.karmaScore,
                monthlyKarma: member.monthlyKarma,
                rank: leaderboard.first { $0.member.userId == userId }?.rank ?? 0,
                breakdown: breakdown
            )
        } catch {
            return nil
        }
    }
}

// MARK: - Karma Summary

struct KarmaSummary {
    let totalKarma: Int
    let monthlyKarma: Int
    let rank: Int
    let breakdown: [KarmaEventType: Int]
}

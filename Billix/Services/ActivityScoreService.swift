//
//  ActivityScoreService.swift
//  Billix
//
//  Activity-based engagement score calculation
//

import SwiftUI

// MARK: - Score Breakdown Model

struct ActivityScoreBreakdown: Equatable {
    let billsPoints: Int
    let swapsPoints: Int
    let streakPoints: Int
    let profilePoints: Int
    let activityPoints: Int

    var total: Int {
        billsPoints + swapsPoints + streakPoints + profilePoints + activityPoints
    }

    static let maxBillsPoints = 30
    static let maxSwapsPoints = 25
    static let maxStreakPoints = 20
    static let maxProfilePoints = 15
    static let maxActivityPoints = 10
    static let maxTotal = 100
}

// MARK: - Score Service

@MainActor
class ActivityScoreService: ObservableObject {
    static let shared = ActivityScoreService()

    @Published var score: Int = 0
    @Published var breakdown: ActivityScoreBreakdown?
    @Published var isLoading = false

    private init() {}

    // MARK: - Score Label

    var scoreLabel: String {
        switch score {
        case 80...100: return "Power User"
        case 60..<80: return "Active"
        case 40..<60: return "Getting Started"
        default: return "Needs Work"
        }
    }

    var scoreColor: Color {
        switch score {
        case 80...100: return Color(hex: "#22C55E") // Green
        case 60..<80: return Color(hex: "#3B82F6") // Blue
        case 40..<60: return Color(hex: "#F59E0B") // Amber
        default: return Color(hex: "#EF4444") // Red
        }
    }

    var encouragementText: String {
        switch score {
        case 80...100: return "You're a Billix champion!"
        case 60..<80: return "Great progress, keep it up!"
        case 40..<60: return "You're on your way!"
        default: return "Start uploading bills to boost your score"
        }
    }

    // MARK: - Calculate Score

    func calculateScore(
        billsCount: Int,
        swapsCount: Int,
        streakDays: Int,
        profileComplete: Bool,
        weeklyLogins: Int
    ) {
        // Bills: 3 points per bill, max 30 (10 bills)
        let billsPoints = min(billsCount * 3, ActivityScoreBreakdown.maxBillsPoints)

        // Swaps: 5 points per swap, max 25 (5 swaps)
        let swapsPoints = min(swapsCount * 5, ActivityScoreBreakdown.maxSwapsPoints)

        // Streak: 2 points per day, max 20 (10 days)
        let streakPoints = min(streakDays * 2, ActivityScoreBreakdown.maxStreakPoints)

        // Profile: 15 points if complete
        let profilePoints = profileComplete ? ActivityScoreBreakdown.maxProfilePoints : 0

        // Activity: 2 points per login this week, max 10 (5 logins)
        let activityPoints = min(weeklyLogins * 2, ActivityScoreBreakdown.maxActivityPoints)

        breakdown = ActivityScoreBreakdown(
            billsPoints: billsPoints,
            swapsPoints: swapsPoints,
            streakPoints: streakPoints,
            profilePoints: profilePoints,
            activityPoints: activityPoints
        )

        score = breakdown?.total ?? 0
    }

    // MARK: - Fetch and Calculate

    func fetchAndCalculateScore() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch bills count
            let billsCount = try await fetchBillsCount()

            // Fetch swaps count
            let swapsCount = try await fetchSwapsCount()

            // Get streak from StreakService
            let streakDays = StreakService.shared.currentStreak

            // Check profile completeness
            let profileComplete = checkProfileComplete()

            // Weekly logins (simplified - could track in Supabase)
            let weeklyLogins = 3 // Default for now

            calculateScore(
                billsCount: billsCount,
                swapsCount: swapsCount,
                streakDays: streakDays,
                profileComplete: profileComplete,
                weeklyLogins: weeklyLogins
            )
        } catch {
            print("Error calculating Billix score: \(error)")
            // Set default score on error
            calculateScore(billsCount: 0, swapsCount: 0, streakDays: 0, profileComplete: false, weeklyLogins: 0)
        }
    }

    // MARK: - Data Fetching Helpers

    private func fetchBillsCount() async throws -> Int {
        let userId = try await SupabaseService.shared.client.auth.session.user.id.uuidString

        let response: [BillCountResponse] = try await SupabaseService.shared.client
            .from("stored_bills")
            .select("id", head: false, count: .exact)
            .eq("user_id", value: userId)
            .execute()
            .value

        return response.count
    }

    private func fetchSwapsCount() async throws -> Int {
        let userId = try await SupabaseService.shared.client.auth.session.user.id.uuidString

        // Count from old swap_transactions table
        let oldSwaps: [SwapCountResponse] = try await SupabaseService.shared.client
            .from("swap_transactions")
            .select("id", head: false, count: .exact)
            .eq("user_id", value: userId)
            .eq("status", value: "completed")
            .execute()
            .value

        // Count from new connections table (Bill Connection feature)
        // User could be initiator or supporter
        let connectionsAsInitiator: [SwapCountResponse] = try await SupabaseService.shared.client
            .from("connections")
            .select("id", head: false, count: .exact)
            .eq("initiator_id", value: userId)
            .eq("status", value: "completed")
            .execute()
            .value

        let connectionsAsSupporter: [SwapCountResponse] = try await SupabaseService.shared.client
            .from("connections")
            .select("id", head: false, count: .exact)
            .eq("supporter_id", value: userId)
            .eq("status", value: "completed")
            .execute()
            .value

        return oldSwaps.count + connectionsAsInitiator.count + connectionsAsSupporter.count
    }

    private func checkProfileComplete() -> Bool {
        guard let profile = AuthService.shared.currentUser?.billixProfile else {
            return false
        }

        // Check if key profile fields are filled
        let hasName = !(profile.displayName?.isEmpty ?? true)
        let hasCity = !(profile.city?.isEmpty ?? true)
        let hasZip = !profile.zipCode.isEmpty

        return hasName && hasCity && hasZip
    }
}

// MARK: - Helper Response Models

private struct BillCountResponse: Codable {
    let id: String
}

private struct SwapCountResponse: Codable {
    let id: String
}

//
//  StreakService.swift
//  Billix
//
//  Tracks user engagement streaks with Supabase
//

import Foundation
import Supabase

// MARK: - Streak Models

struct UserStreak: Codable {
    let userId: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastActivityDate: String?
    var streakStartedAt: String?
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActivityDate = "last_activity_date"
        case streakStartedAt = "streak_started_at"
        case updatedAt = "updated_at"
    }
}

struct StreakStatusResult: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let lastActivityDate: String?
    let isAtRisk: Bool

    enum CodingKeys: String, CodingKey {
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActivityDate = "last_activity_date"
        case isAtRisk = "is_at_risk"
    }
}

struct UpdateStreakResult: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let isAtRisk: Bool

    enum CodingKeys: String, CodingKey {
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case isAtRisk = "is_at_risk"
    }
}

// MARK: - Streak Service

@MainActor
class StreakService: ObservableObject {

    // MARK: - Singleton
    static let shared = StreakService()

    // MARK: - Published Properties
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var isAtRisk: Bool = false
    @Published var lastActivityDate: Date?
    @Published var isLoading: Bool = false

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private init() {}

    // MARK: - Public Methods

    /// Fetch current streak status for the logged-in user
    func fetchStreak() async throws {
        print("🔄 [STREAK SERVICE] fetchStreak() called - START")

        guard let userId = try? await supabase.auth.session.user.id else {
            print("⚠️ [STREAK SERVICE] No user logged in")
            return
        }

        print("✅ [STREAK SERVICE] User ID: \(userId.uuidString)")

        isLoading = true
        defer {
            isLoading = false
            print("🔄 [STREAK SERVICE] isLoading set to false")
        }

        do {
            print("🌐 [STREAK SERVICE] Calling get_streak_status RPC...")
            // Call the get_streak_status function
            let results: [StreakStatusResult] = try await supabase
                .rpc("get_streak_status", params: ["p_user_id": userId.uuidString])
                .execute()
                .value

            print("📦 [STREAK SERVICE] RPC response received - results count: \(results.count)")

            if let result = results.first {
                print("📊 [STREAK SERVICE] Result data:")
                print("   - currentStreak: \(result.currentStreak)")
                print("   - longestStreak: \(result.longestStreak)")
                print("   - isAtRisk: \(result.isAtRisk)")
                print("   - lastActivityDate: \(result.lastActivityDate ?? "nil")")

                // BEFORE update
                print("📍 [STREAK SERVICE] BEFORE UPDATE - self.currentStreak = \(self.currentStreak)")

                self.currentStreak = result.currentStreak
                self.longestStreak = result.longestStreak
                self.isAtRisk = result.isAtRisk

                // AFTER update
                print("📍 [STREAK SERVICE] AFTER UPDATE - self.currentStreak = \(self.currentStreak)")

                // Parse last activity date
                if let dateString = result.lastActivityDate {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    self.lastActivityDate = formatter.date(from: dateString)
                    print("📅 [STREAK SERVICE] lastActivityDate parsed: \(self.lastActivityDate?.description ?? "nil")")

                    // Validate streak is still active (last activity must be today or yesterday)
                    if let lastActivity = self.lastActivityDate {
                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        let lastActivityDay = calendar.startOfDay(for: lastActivity)
                        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

                        // If last activity was NOT today or yesterday, streak is broken
                        if lastActivityDay != today && lastActivityDay != yesterday {
                            print("⚠️ [STREAK SERVICE] Streak broken! Last activity was \(lastActivityDay), resetting to 0")
                            self.currentStreak = 0
                        }
                    }
                }

                print("✅ [STREAK SERVICE] Streak fetched successfully: \(self.currentStreak) days")
            } else {
                print("⚠️ [STREAK SERVICE] No streak record found in results")
                // No streak record yet - will be created on first activity
                self.currentStreak = 0
                self.longestStreak = 0
                self.isAtRisk = false
                print("ℹ️ [STREAK SERVICE] Set to defaults - currentStreak: 0")
            }
        } catch {
            print("❌ [STREAK SERVICE] Error fetching streak: \(error)")
            print("❌ [STREAK SERVICE] Error details: \(error.localizedDescription)")
            throw error
        }

        print("✅ [STREAK SERVICE] fetchStreak() completed - FINAL currentStreak = \(self.currentStreak)")
    }

    /// Record activity and update streak
    /// Call this when user performs meaningful engagement (opens app, uploads bill, etc.)
    func recordActivity() async throws {
        guard let userId = try? await supabase.auth.session.user.id else {
            print("⚠️ StreakService: No user logged in")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Call the update_user_streak function
            let results: [UpdateStreakResult] = try await supabase
                .rpc("update_user_streak", params: ["p_user_id": userId.uuidString])
                .execute()
                .value

            if let result = results.first {
                let oldStreak = self.currentStreak
                self.currentStreak = result.currentStreak
                self.longestStreak = result.longestStreak
                self.isAtRisk = result.isAtRisk
                self.lastActivityDate = Date()

                // Log streak milestone
                if result.currentStreak > oldStreak && result.currentStreak > 0 {
                    print("🔥 Streak increased to \(result.currentStreak) days!")
                }
            }
        } catch {
            print("❌ Error recording activity: \(error)")
            throw error
        }
    }

    /// Check if streak is at risk (< 2 hours until midnight without activity today)
    func checkStreakStatus() {
        guard let lastActivity = lastActivityDate else {
            isAtRisk = false
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActivityDay = calendar.startOfDay(for: lastActivity)

        // If already active today, not at risk
        if lastActivityDay == today {
            isAtRisk = false
            return
        }

        // If last activity was yesterday, check time until midnight
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        if lastActivityDay == yesterday {
            // Calculate hours until midnight
            let now = Date()
            let midnight = calendar.date(byAdding: .day, value: 1, to: today)!
            let hoursUntilMidnight = midnight.timeIntervalSince(now) / 3600

            isAtRisk = hoursUntilMidnight < 2
        } else {
            // Streak already broken
            isAtRisk = false
        }
    }

    /// Format streak for display
    var streakDisplayText: String {
        if currentStreak == 0 {
            return "Start your streak!"
        } else if currentStreak == 1 {
            return "1 Day Streak"
        } else {
            return "\(currentStreak) Day Streak"
        }
    }

    /// Get motivational message based on streak
    var streakMotivation: String {
        switch currentStreak {
        case 0:
            return "Open the app daily to build your streak"
        case 1...2:
            return "Great start! Keep it going"
        case 3...6:
            return "You're building a habit!"
        case 7...13:
            return "One week strong! 🔥"
        case 14...29:
            return "Two weeks! You're on fire!"
        case 30...59:
            return "A whole month! Incredible!"
        case 60...89:
            return "Two months! Legendary!"
        default:
            return "You're a streak master! 🏆"
        }
    }
}

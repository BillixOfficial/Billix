//
//  RateLimitService.swift
//  Billix
//
//  Created by Claude Code on 1/18/26.
//  Service for managing per-user RentCast API rate limits via Supabase
//

import Foundation
import Supabase

/// Error types for rate limiting
enum RateLimitError: Error, LocalizedError {
    case rateLimitExceeded(remaining: Int, limit: Int)
    case userNotAuthenticated
    case networkError(Error)
    case databaseError(Error)

    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded(_, let limit):
            return "Weekly limit reached (\(limit) points). Resets Monday."
        case .userNotAuthenticated:
            return "Please log in to search properties"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .rateLimitExceeded:
            return "Upgrade to Premium for more points, or wait until Monday for your limit to reset."
        case .userNotAuthenticated:
            return "Log in to your account to continue."
        case .networkError:
            return "Check your internet connection and try again."
        case .databaseError:
            return "Please try again later."
        }
    }
}

/// Model for the rentcast_usage table
struct RentCastUsage: Codable {
    let id: UUID?
    let userId: UUID
    let weekStart: String  // DATE stored as string (YYYY-MM-DD)
    var callCount: Int
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weekStart = "week_start"
        case callCount = "call_count"
        case updatedAt = "updated_at"
    }
}

/// Response from the increment_rentcast_usage RPC function
struct IncrementUsageResponse: Codable {
    let newCount: Int
    let allowed: Bool

    enum CodingKeys: String, CodingKey {
        case newCount = "new_count"
        case allowed
    }
}

/// Result of checking/recording usage
struct UsageCheckResult {
    let allowed: Bool
    let currentCount: Int
    let limit: Int
    let remaining: Int
    let weekStart: Date

    var remainingPercentage: Double {
        guard limit > 0 else { return 0 }
        return Double(remaining) / Double(limit)
    }
}

/// Service for managing RentCast API rate limits
@MainActor
class RateLimitService: ObservableObject {
    static let shared = RateLimitService()

    private let supabase = SupabaseService.shared.client

    /// Current usage state (updated after each check)
    @Published private(set) var currentUsage: Int = 0
    @Published private(set) var weeklyLimit: Int = RateLimitConfig.freeLimit
    @Published private(set) var remainingCalls: Int = RateLimitConfig.freeLimit
    @Published private(set) var isLoading: Bool = false

    /// User's subscription tier (for future use)
    @Published private(set) var subscriptionTier: SubscriptionTier = .free

    private init() {}

    /// Get the start of the current week (Monday at 00:00 UTC)
    private func getCurrentWeekStart() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        var cal = calendar
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 2  // Monday = 2

        let today = Date()
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        return cal.date(from: components) ?? today
    }

    /// Format date as YYYY-MM-DD string for database
    private func formatDateForDB(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    /// Check current usage and record points if allowed (atomic operation)
    /// - Parameter points: Number of points to consume (default 1)
    /// Returns UsageCheckResult with current state
    /// Throws RateLimitError if limit exceeded or other errors
    func checkAndRecordUsage(points: Int = 1) async throws -> UsageCheckResult {
        guard let userId = supabase.auth.currentSession?.user.id else {
            throw RateLimitError.userNotAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let weekStart = getCurrentWeekStart()
        let weekStartStr = formatDateForDB(weekStart)
        let limit = subscriptionTier.weeklyLimit

        do {
            // First check current usage to see if we're already at limit
            let currentResponse: [RentCastUsage] = try await supabase
                .from("rentcast_usage")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("week_start", value: weekStartStr)
                .execute()
                .value

            let currentCount = currentResponse.first?.callCount ?? 0

            // Check if adding points would exceed limit
            if currentCount >= limit {
                currentUsage = currentCount
                remainingCalls = 0
                weeklyLimit = limit
                throw RateLimitError.rateLimitExceeded(remaining: 0, limit: limit)
            }

            // Use atomic RPC to increment (prevents race conditions)
            let rpcResponse: [IncrementUsageResponse] = try await supabase
                .rpc("increment_rentcast_usage", params: [
                    "p_user_id": userId.uuidString,
                    "p_week_start": weekStartStr,
                    "p_increment": String(points)
                ])
                .execute()
                .value

            guard let result = rpcResponse.first else {
                throw RateLimitError.databaseError(NSError(domain: "RateLimitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "RPC returned no result"]))
            }

            let newCount = result.newCount
            let remaining = max(0, limit - newCount)

            // Update published state
            currentUsage = newCount
            remainingCalls = remaining
            weeklyLimit = limit

            return UsageCheckResult(
                allowed: result.allowed,
                currentCount: newCount,
                limit: limit,
                remaining: remaining,
                weekStart: weekStart
            )

        } catch let error as RateLimitError {
            throw error
        } catch {
            throw RateLimitError.databaseError(error)
        }
    }

    /// Get current usage without recording a new call
    /// Use this to display UI indicators
    func getRemainingCalls() async throws -> UsageCheckResult {
        guard let userId = supabase.auth.currentSession?.user.id else {
            throw RateLimitError.userNotAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let weekStart = getCurrentWeekStart()
        let weekStartStr = formatDateForDB(weekStart)
        let limit = subscriptionTier.weeklyLimit

        do {
            let response: [RentCastUsage] = try await supabase
                .from("rentcast_usage")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("week_start", value: weekStartStr)
                .execute()
                .value

            let currentCount = response.first?.callCount ?? 0
            let remaining = max(0, limit - currentCount)

            // Update published state
            currentUsage = currentCount
            remainingCalls = remaining
            weeklyLimit = limit

            return UsageCheckResult(
                allowed: remaining > 0,
                currentCount: currentCount,
                limit: limit,
                remaining: remaining,
                weekStart: weekStart
            )

        } catch {
            throw RateLimitError.databaseError(error)
        }
    }

    /// Refresh usage state from database
    func refreshUsage() async {
        do {
            _ = try await getRemainingCalls()
        } catch {
            // Silently fail - UI will show stale data
        }
    }

    /// Check if user can make an API call (without recording)
    var canMakeAPICall: Bool {
        return remainingCalls > 0
    }

    /// Get the status color for UI indicators
    var statusColor: RateLimitStatusColor {
        let percentage = Double(remainingCalls) / Double(weeklyLimit)

        if percentage <= RateLimitConfig.criticalThreshold {
            return .critical
        } else if percentage <= RateLimitConfig.warningThreshold {
            return .warning
        } else {
            return .normal
        }
    }
}

/// Color status for rate limit indicator
enum RateLimitStatusColor {
    case normal   // Green - plenty remaining
    case warning  // Orange - getting low
    case critical // Red - almost out or exhausted
}

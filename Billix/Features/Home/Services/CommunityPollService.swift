//
//  CommunityPollService.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation
import Supabase

// MARK: - Models

struct CommunityPoll: Codable, Identifiable {
    let id: UUID
    let question: String
    let optionA: String
    let optionB: String
    let category: String?
    let viewCount: Int
    let voteCountA: Int
    let voteCountB: Int
    let activeDate: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case question
        case optionA = "option_a"
        case optionB = "option_b"
        case category
        case viewCount = "view_count"
        case voteCountA = "vote_count_a"
        case voteCountB = "vote_count_b"
        case activeDate = "active_date"
        case createdAt = "created_at"
    }

    var totalVotes: Int {
        voteCountA + voteCountB
    }

    var percentageA: Double {
        guard totalVotes > 0 else { return 50.0 }
        return Double(voteCountA) / Double(totalVotes) * 100.0
    }

    var percentageB: Double {
        guard totalVotes > 0 else { return 50.0 }
        return Double(voteCountB) / Double(totalVotes) * 100.0
    }
}

struct PollResponse: Codable, Identifiable {
    let id: UUID
    let pollId: UUID
    let userId: UUID
    let selectedOption: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case pollId = "poll_id"
        case userId = "user_id"
        case selectedOption = "selected_option"
        case createdAt = "created_at"
    }
}

enum PollOption: String, Codable {
    case a
    case b
}

struct PollWithUserResponse {
    let poll: CommunityPoll
    let userResponse: PollResponse?
    let hasVoted: Bool

    var selectedOption: PollOption? {
        guard let response = userResponse else { return nil }
        return PollOption(rawValue: response.selectedOption)
    }
}

// MARK: - Protocol

protocol CommunityPollServiceProtocol {
    func getTodaysPoll() async throws -> CommunityPoll?
    func getPollWithUserResponse() async throws -> PollWithUserResponse?
    func recordView(pollId: UUID) async throws
    func submitVote(pollId: UUID, option: PollOption) async throws -> CommunityPoll
    func hasUserVoted(pollId: UUID) async throws -> Bool
    func getUserResponse(pollId: UUID) async throws -> PollResponse?
}

// MARK: - Service Implementation

@MainActor
class CommunityPollService: CommunityPollServiceProtocol {

    // MARK: - Singleton
    static let shared = CommunityPollService()

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // Cache for today's poll to reduce DB calls
    private var cachedPoll: CommunityPoll?
    private var cacheDate: Date?

    // MARK: - Initialization
    private init() {}

    // MARK: - Public Methods

    /// Get today's poll (uses database function)
    func getTodaysPoll() async throws -> CommunityPoll? {
        // Check cache first (valid for same calendar day)
        if let cached = cachedPoll,
           let cacheDate = cacheDate,
           Calendar.current.isDateInToday(cacheDate) {
            return cached
        }

        // Get today's date in EST timezone (matching task reset logic)
        let calendar = Calendar.current
        guard let estTimeZone = TimeZone(identifier: "America/New_York") else {
            return nil
        }

        let now = Date()
        let estComponents = calendar.dateComponents(in: estTimeZone, from: now)
        guard let year = estComponents.year,
              let month = estComponents.month,
              let day = estComponents.day else {
            return nil
        }

        let todayString = String(format: "%04d-%02d-%02d", year, month, day)

        let response: [CommunityPoll] = try await supabase
            .from("community_polls")
            .select()
            .eq("active_date", value: todayString)
            .limit(1)
            .execute()
            .value

        let poll = response.first
        cachedPoll = poll
        cacheDate = Date()

        return poll
    }

    /// Get today's poll along with the user's response (if any)
    func getPollWithUserResponse() async throws -> PollWithUserResponse? {
        guard let poll = try await getTodaysPoll() else {
            return nil
        }

        let userResponse = try await getUserResponse(pollId: poll.id)

        return PollWithUserResponse(
            poll: poll,
            userResponse: userResponse,
            hasVoted: userResponse != nil
        )
    }

    /// Record a view when the poll is displayed
    func recordView(pollId: UUID) async throws {
        // Use the database function to increment view count
        try await supabase
            .rpc("increment_poll_view", params: ["p_poll_id": pollId.uuidString])
            .execute()
    }

    /// Submit a vote for a poll option
    func submitVote(pollId: UUID, option: PollOption) async throws -> CommunityPoll {
        guard let session = try? await supabase.auth.session else {
            throw PollError.notAuthenticated
        }

        // Check if user already voted
        let existingResponse = try await getUserResponse(pollId: pollId)
        if existingResponse != nil {
            throw PollError.alreadyVoted
        }

        // Insert the vote
        try await supabase
            .from("poll_responses")
            .insert([
                "poll_id": pollId.uuidString,
                "user_id": session.user.id.uuidString,
                "selected_option": option.rawValue
            ])
            .execute()

        // Clear cache to get fresh data
        cachedPoll = nil

        // Fetch updated poll with new vote counts
        let updatedPoll: CommunityPoll = try await supabase
            .from("community_polls")
            .select()
            .eq("id", value: pollId.uuidString)
            .single()
            .execute()
            .value

        cachedPoll = updatedPoll
        cacheDate = Date()

        return updatedPoll
    }

    /// Check if the current user has voted on a specific poll
    func hasUserVoted(pollId: UUID) async throws -> Bool {
        let response = try await getUserResponse(pollId: pollId)
        return response != nil
    }

    /// Get the user's response for a specific poll
    func getUserResponse(pollId: UUID) async throws -> PollResponse? {
        guard let session = try? await supabase.auth.session else {
            return nil // Not authenticated means no response
        }

        // Get today's start in EST (matching task reset logic)
        let calendar = Calendar.current
        var estComponents = calendar.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: Date())
        estComponents.hour = 0
        estComponents.minute = 0
        estComponents.second = 0
        guard let todayStart = calendar.date(from: estComponents) else {
            return nil
        }

        let response: [PollResponse] = try await supabase
            .from("poll_responses")
            .select()
            .eq("poll_id", value: pollId.uuidString)
            .eq("user_id", value: session.user.id.uuidString)
            .gte("created_at", value: todayStart.ISO8601Format())
            .limit(1)
            .execute()
            .value

        return response.first
    }

    // MARK: - Helper Methods

    /// Get formatted view count for display (e.g., "1.2K views")
    func formattedViewCount(_ count: Int) -> String {
        if count >= 1000 {
            let thousands = Double(count) / 1000.0
            return String(format: "%.1fK views", thousands)
        }
        return "\(count) views"
    }

    /// Get formatted percentage for display
    func formattedPercentage(_ percentage: Double) -> String {
        return String(format: "%.0f%%", percentage)
    }

    /// Clear the cache (useful for testing or force refresh)
    func clearCache() {
        cachedPoll = nil
        cacheDate = nil
    }
}

// MARK: - Errors

enum PollError: LocalizedError {
    case notAuthenticated
    case pollNotFound
    case alreadyVoted
    case voteFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to vote"
        case .pollNotFound:
            return "Poll not found"
        case .alreadyVoted:
            return "You've already voted on this poll"
        case .voteFailed(let message):
            return "Failed to submit vote: \(message)"
        }
    }
}

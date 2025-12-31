//
//  BillixScoreModels.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Models for Billix Score trust system
//

import Foundation
import SwiftUI

// MARK: - Badge Level

enum BillixBadgeLevel: String, Codable, CaseIterable, Identifiable {
    case newcomer
    case trusted
    case verified
    case elite

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newcomer: return "Newcomer"
        case .trusted: return "Trusted"
        case .verified: return "Verified"
        case .elite: return "Elite"
        }
    }

    var description: String {
        switch self {
        case .newcomer: return "Just getting started"
        case .trusted: return "Building a track record"
        case .verified: return "Proven reliability"
        case .elite: return "Top community member"
        }
    }

    var icon: String {
        switch self {
        case .newcomer: return "person.circle"
        case .trusted: return "checkmark.shield"
        case .verified: return "checkmark.seal.fill"
        case .elite: return "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .newcomer: return .gray
        case .trusted: return .blue
        case .verified: return .purple
        case .elite: return .orange
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .newcomer:
            return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .trusted:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .verified:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .elite:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var scoreRange: ClosedRange<Int> {
        switch self {
        case .newcomer: return 0...300
        case .trusted: return 301...600
        case .verified: return 601...850
        case .elite: return 851...1000
        }
    }

    var minimumScore: Int {
        scoreRange.lowerBound
    }

    /// Returns the badge level for a given score
    static func level(for score: Int) -> BillixBadgeLevel {
        switch score {
        case 0...300: return .newcomer
        case 301...600: return .trusted
        case 601...850: return .verified
        default: return .elite
        }
    }

    /// Points needed to reach next badge level
    func pointsToNextLevel(currentScore: Int) -> Int? {
        guard self != .elite else { return nil }
        let nextMin: Int
        switch self {
        case .newcomer: nextMin = 301
        case .trusted: nextMin = 601
        case .verified: nextMin = 851
        case .elite: return nil
        }
        return max(0, nextMin - currentScore)
    }
}

// MARK: - Score Component

enum ScoreComponent: String, Codable, CaseIterable, Identifiable {
    case completion
    case verification
    case community
    case reliability

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .completion: return "Completion"
        case .verification: return "Verification"
        case .community: return "Community"
        case .reliability: return "Reliability"
        }
    }

    var description: String {
        switch self {
        case .completion: return "Successfully completed swaps"
        case .verification: return "Screenshot verification rate"
        case .community: return "Ratings from swap partners"
        case .reliability: return "On-time completion & consistency"
        }
    }

    var icon: String {
        switch self {
        case .completion: return "checkmark.circle.fill"
        case .verification: return "camera.viewfinder"
        case .community: return "star.fill"
        case .reliability: return "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .completion: return .green
        case .verification: return .blue
        case .community: return .yellow
        case .reliability: return .purple
        }
    }

    /// Weight in overall score calculation
    var weight: Double {
        switch self {
        case .completion: return 0.35
        case .verification: return 0.25
        case .community: return 0.25
        case .reliability: return 0.15
        }
    }

    var maxValue: Int { 100 }
}

// MARK: - Billix Score

struct BillixScore: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var overallScore: Int
    var completionScore: Int
    var verificationScore: Int
    var communityScore: Int
    var reliabilityScore: Int
    var badgeLevel: BillixBadgeLevel
    var lastCalculatedAt: Date
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case overallScore = "overall_score"
        case completionScore = "completion_score"
        case verificationScore = "verification_score"
        case communityScore = "community_score"
        case reliabilityScore = "reliability_score"
        case badgeLevel = "badge_level"
        case lastCalculatedAt = "last_calculated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Returns score for a specific component
    func score(for component: ScoreComponent) -> Int {
        switch component {
        case .completion: return completionScore
        case .verification: return verificationScore
        case .community: return communityScore
        case .reliability: return reliabilityScore
        }
    }

    /// Progress to next badge level (0.0 - 1.0)
    var progressToNextLevel: Double {
        let range = badgeLevel.scoreRange
        let rangeSize = Double(range.upperBound - range.lowerBound)
        let progress = Double(overallScore - range.lowerBound) / rangeSize
        return min(1.0, max(0.0, progress))
    }

    /// Static initializer for new users
    static func newUser(userId: UUID) -> BillixScore {
        BillixScore(
            id: UUID(),
            userId: userId,
            overallScore: 500,
            completionScore: 100,
            verificationScore: 100,
            communityScore: 100,
            reliabilityScore: 100,
            badgeLevel: .trusted,
            lastCalculatedAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Score Event

enum ScoreEventType: String, Codable {
    case swapCompleted = "swap_completed"
    case swapFailed = "swap_failed"
    case ghostIncident = "ghost_incident"
    case screenshotVerified = "screenshot_verified"
    case screenshotRejected = "screenshot_rejected"
    case ratingReceived = "rating_received"
    case onTimeCompletion = "on_time_completion"
    case lateCompletion = "late_completion"
    case accountAgeMilestone = "account_age_milestone"
    case consistencyStreak = "consistency_streak"

    var displayName: String {
        switch self {
        case .swapCompleted: return "Swap Completed"
        case .swapFailed: return "Swap Failed"
        case .ghostIncident: return "Ghost Incident"
        case .screenshotVerified: return "Screenshot Verified"
        case .screenshotRejected: return "Screenshot Rejected"
        case .ratingReceived: return "Rating Received"
        case .onTimeCompletion: return "On-Time Completion"
        case .lateCompletion: return "Late Completion"
        case .accountAgeMilestone: return "Account Milestone"
        case .consistencyStreak: return "Consistency Streak"
        }
    }

    var affectedComponent: ScoreComponent {
        switch self {
        case .swapCompleted, .swapFailed, .ghostIncident:
            return .completion
        case .screenshotVerified, .screenshotRejected:
            return .verification
        case .ratingReceived:
            return .community
        case .onTimeCompletion, .lateCompletion, .accountAgeMilestone, .consistencyStreak:
            return .reliability
        }
    }

    /// Base point change for this event type
    var basePointChange: Int {
        switch self {
        case .swapCompleted: return 10
        case .swapFailed: return -15
        case .ghostIncident: return -25
        case .screenshotVerified: return 5
        case .screenshotRejected: return -10
        case .ratingReceived: return 0 // Calculated based on rating
        case .onTimeCompletion: return 5
        case .lateCompletion: return -5
        case .accountAgeMilestone: return 10
        case .consistencyStreak: return 15
        }
    }

    var isPositive: Bool {
        basePointChange >= 0
    }
}

// MARK: - Score History Entry

struct ScoreHistoryEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let eventType: String
    let component: String
    let pointChange: Int
    let newScore: Int
    let description: String?
    let referenceId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case eventType = "event_type"
        case component
        case pointChange = "point_change"
        case newScore = "new_score"
        case description
        case referenceId = "reference_id"
        case createdAt = "created_at"
    }

    var event: ScoreEventType? {
        ScoreEventType(rawValue: eventType)
    }

    var scoreComponent: ScoreComponent? {
        ScoreComponent(rawValue: component)
    }

    var formattedChange: String {
        pointChange >= 0 ? "+\(pointChange)" : "\(pointChange)"
    }
}

// MARK: - Insert Structs

struct BillixScoreInsert: Codable {
    let userId: String
    let overallScore: Int
    let completionScore: Int
    let verificationScore: Int
    let communityScore: Int
    let reliabilityScore: Int
    let badgeLevel: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case overallScore = "overall_score"
        case completionScore = "completion_score"
        case verificationScore = "verification_score"
        case communityScore = "community_score"
        case reliabilityScore = "reliability_score"
        case badgeLevel = "badge_level"
    }
}

struct BillixScoreUpdate: Codable {
    let overallScore: Int
    let completionScore: Int
    let verificationScore: Int
    let communityScore: Int
    let reliabilityScore: Int
    let badgeLevel: String

    enum CodingKeys: String, CodingKey {
        case overallScore = "overall_score"
        case completionScore = "completion_score"
        case verificationScore = "verification_score"
        case communityScore = "community_score"
        case reliabilityScore = "reliability_score"
        case badgeLevel = "badge_level"
    }
}

struct ScoreHistoryInsert: Codable {
    let userId: String
    let eventType: String
    let component: String
    let pointChange: Int
    let newScore: Int
    let description: String?
    let referenceId: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case eventType = "event_type"
        case component
        case pointChange = "point_change"
        case newScore = "new_score"
        case description
        case referenceId = "reference_id"
    }
}

// MARK: - Score Summary

struct ScoreSummary {
    let currentScore: Int
    let badgeLevel: BillixBadgeLevel
    let components: [ScoreComponent: Int]
    let recentChange: Int
    let percentile: Int?

    var formattedPercentile: String? {
        guard let p = percentile else { return nil }
        return "Top \(100 - p)%"
    }
}

// MARK: - Score Calculation Parameters

struct ScoreCalculationParams {
    // Completion score
    static let baseCompletionScore = 50
    static let completedSwapBonus = 10
    static let maxCompletedSwapBonus = 50
    static let failedSwapPenalty = 15
    static let ghostIncidentPenalty = 25

    // Verification score
    static let baseVerificationScore = 70
    static let verifiedScreenshotBonus = 5
    static let maxVerifiedScreenshotBonus = 30
    static let rejectedScreenshotPenalty = 10

    // Community score (0-100 based on average rating)
    static let ratingMultiplier = 20 // 5 stars * 20 = 100

    // Reliability score
    static let baseReliabilityScore = 70
    static let onTimeBonus = 5
    static let latePenalty = 5
    static let accountAgeBonus = 10 // Per milestone
    static let consistencyStreakBonus = 15

    // Component weights
    static let completionWeight = 0.35
    static let verificationWeight = 0.25
    static let communityWeight = 0.25
    static let reliabilityWeight = 0.15
}

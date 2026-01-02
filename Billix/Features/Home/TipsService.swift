//
//  TipsService.swift
//  Billix
//
//  Created by Claude Code
//  Service for managing daily money-saving tips
//

import Foundation
import Supabase

// MARK: - Models

struct Tip: Codable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let category: String?
    let activeDate: Date
    let iconName: String?
    let iconColor: String?
    let viewCount: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case category
        case activeDate = "active_date"
        case iconName = "icon_name"
        case iconColor = "icon_color"
        case viewCount = "view_count"
        case createdAt = "created_at"
    }
}

struct UserTipView: Codable, Identifiable {
    let id: UUID
    let tipId: UUID
    let userId: UUID
    let readDurationSeconds: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case tipId = "tip_id"
        case userId = "user_id"
        case readDurationSeconds = "read_duration_seconds"
        case createdAt = "created_at"
    }
}

struct TipWithReadStatus {
    let tip: Tip
    let hasRead: Bool
    let tipView: UserTipView?
}

// MARK: - Protocol

protocol TipsServiceProtocol {
    func getTodaysTip() async throws -> Tip?
    func getTipWithReadStatus() async throws -> TipWithReadStatus?
    func hasUserReadTip(tipId: UUID) async throws -> Bool
    func markTipAsRead(tipId: UUID, readDuration: Int?) async throws
    func getTipView(tipId: UUID) async throws -> UserTipView?
}

// MARK: - Service Implementation

@MainActor
class TipsService: TipsServiceProtocol {

    // MARK: - Singleton
    static let shared = TipsService()

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // Cache for today's tip to reduce DB calls
    private var cachedTipWithStatus: TipWithReadStatus?
    private var cacheDate: Date?

    // MARK: - Initialization
    private init() {}

    // MARK: - Public Methods

    /// Get today's tip
    func getTodaysTip() async throws -> Tip? {
        // Check cache first (valid for same calendar day)
        if let cached = cachedTipWithStatus,
           let cacheDate = cacheDate,
           Calendar.current.isDateInToday(cacheDate) {
            return cached.tip
        }

        // Query for today's tip
        let todayString = ISO8601DateFormatter().string(from: Date()).prefix(10)

        let response: [Tip] = try await supabase
            .from("tips")
            .select()
            .eq("active_date", value: String(todayString))
            .limit(1)
            .execute()
            .value

        return response.first
    }

    /// Get today's tip along with user's read status
    func getTipWithReadStatus() async throws -> TipWithReadStatus? {
        // Check cache first
        if let cached = cachedTipWithStatus,
           let cacheDate = cacheDate,
           Calendar.current.isDateInToday(cacheDate) {
            return cached
        }

        guard let tip = try await getTodaysTip() else {
            return nil
        }

        let tipView = try await getTipView(tipId: tip.id)

        let tipWithStatus = TipWithReadStatus(
            tip: tip,
            hasRead: tipView != nil,
            tipView: tipView
        )

        // Cache the result
        cachedTipWithStatus = tipWithStatus
        cacheDate = Date()

        return tipWithStatus
    }

    /// Check if the current user has read a specific tip
    func hasUserReadTip(tipId: UUID) async throws -> Bool {
        let tipView = try await getTipView(tipId: tipId)
        return tipView != nil
    }

    /// Get the user's tip view record
    func getTipView(tipId: UUID) async throws -> UserTipView? {
        guard let session = try? await supabase.auth.session else {
            return nil // Not authenticated means no view record
        }

        let response: [UserTipView] = try await supabase
            .from("tip_views")
            .select()
            .eq("tip_id", value: tipId.uuidString)
            .eq("user_id", value: session.user.id.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    /// Mark a tip as read
    func markTipAsRead(tipId: UUID, readDuration: Int? = nil) async throws {
        guard let session = try? await supabase.auth.session else {
            throw TipError.notAuthenticated
        }

        // Check if already read
        let existingView = try await getTipView(tipId: tipId)
        if existingView != nil {
            throw TipError.alreadyRead
        }

        // Create tip view record
        struct TipViewInsert: Encodable {
            let tip_id: String
            let user_id: String
            let read_duration_seconds: Int?
        }

        let viewData = TipViewInsert(
            tip_id: tipId.uuidString,
            user_id: session.user.id.uuidString,
            read_duration_seconds: readDuration
        )

        try await supabase
            .from("tip_views")
            .insert(viewData)
            .execute()

        // Clear cache to force refresh
        clearCache()
    }

    // MARK: - Helper Methods

    /// Get formatted view count for display (e.g., "1.2K views")
    func formattedViewCount(_ count: Int) -> String {
        if count >= 1000 {
            let thousands = Double(count) / 1000.0
            return String(format: "%.1fK reads", thousands)
        }
        return "\(count) reads"
    }

    /// Get icon color as SwiftUI Color
    func getIconColor(hexString: String?) -> String {
        return hexString ?? "#10B981" // Default green
    }

    /// Clear the cache (useful for testing or force refresh)
    func clearCache() {
        cachedTipWithStatus = nil
        cacheDate = nil
    }
}

// MARK: - Errors

enum TipError: LocalizedError {
    case notAuthenticated
    case tipNotFound
    case alreadyRead
    case markReadFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to read tips"
        case .tipNotFound:
            return "Tip not found"
        case .alreadyRead:
            return "You've already read this tip"
        case .markReadFailed(let message):
            return "Failed to mark tip as read: \(message)"
        }
    }
}

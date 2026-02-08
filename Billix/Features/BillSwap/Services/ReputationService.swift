//
//  ReputationService.swift
//  Billix
//
//  Service for managing user reputation in the Bill Connection feature
//  Replaces the collateral/trust point locking system with reputation-based trust
//

import Foundation
import Supabase

// MARK: - Reputation Role

/// Role in a connection (for reputation context)
enum ConnectionRole: String, Codable {
    case initiator
    case supporter
}

// MARK: - Sanction Reason

/// Reasons for reputation sanctions
enum SanctionReason: String, Codable, CaseIterable {
    case fakeReceipt = "fake_receipt"
    case noPayment = "no_payment"
    case harassment = "harassment"
    case abandonedConnection = "abandoned_connection"
    case other = "other"

    var displayName: String {
        switch self {
        case .fakeReceipt: return "Fake payment receipt"
        case .noPayment: return "Failed to make payment"
        case .harassment: return "Harassment"
        case .abandonedConnection: return "Abandoned connection"
        case .other: return "Other violation"
        }
    }

    var severity: SanctionSeverity {
        switch self {
        case .fakeReceipt: return .severe
        case .noPayment: return .moderate
        case .harassment: return .severe
        case .abandonedConnection: return .mild
        case .other: return .moderate
        }
    }
}

enum SanctionSeverity: String, Codable {
    case mild       // Warning, small reputation penalty
    case moderate   // Reputation penalty, possible temp suspension
    case severe     // Large penalty, possible permanent ban
}

// MARK: - Reputation Service

/// Service for managing user reputation and sanctions
@MainActor
class ReputationService: ObservableObject {

    // MARK: - Singleton

    static let shared = ReputationService()

    // MARK: - Constants

    /// Reputation points awarded per successful connection
    static let pointsPerConnection = 10

    /// Reputation points awarded per role
    static let initiatorBonus = 5
    static let supporterBonus = 10

    /// Connections needed to advance from Contributor to Pillar
    static let connectionsForPillar = 15

    // MARK: - Published Properties

    @Published var userReputation: ReputationInfo?
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentUserId: UUID? {
        AuthService.shared.currentUser?.id
    }

    private init() {}

    // MARK: - Load User Reputation

    /// Load current user's reputation info
    func loadUserReputation() async throws -> ReputationInfo {
        guard let userId = currentUserId else {
            throw ReputationError.notAuthenticated
        }

        return try await getReputationInfo(userId: userId)
    }

    /// Get reputation info for any user
    func getReputationInfo(userId: UUID) async throws -> ReputationInfo {
        struct ProfileReputation: Decodable {
            let reputationScore: Int?
            let reputationTier: Int?
            let successfulConnections: Int?
            let monthlyConnectionCount: Int?
            let isDeactivated: Bool?
            let isPermanentlyBanned: Bool?

            enum CodingKeys: String, CodingKey {
                case reputationScore = "reputation_score"
                case reputationTier = "reputation_tier"
                case successfulConnections = "successful_connections"
                case monthlyConnectionCount = "monthly_connection_count"
                case isDeactivated = "is_deactivated"
                case isPermanentlyBanned = "is_permanently_banned"
            }
        }

        let profiles: [ProfileReputation] = try await supabase
            .from("profiles")
            .select("reputation_score, reputation_tier, successful_connections, monthly_connection_count, is_deactivated, is_permanently_banned")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let profile = profiles.first else {
            // Return default tier 1 if no profile
            return ReputationInfo(
                reputationScore: 0,
                reputationTier: .neighbor,
                successfulConnections: 0,
                monthlyConnectionCount: 0,
                isDeactivated: false,
                isPermanentlyBanned: false
            )
        }

        let tier = ReputationTier(rawValue: profile.reputationTier ?? 1) ?? .neighbor

        let info = ReputationInfo(
            reputationScore: profile.reputationScore ?? 0,
            reputationTier: tier,
            successfulConnections: profile.successfulConnections ?? 0,
            monthlyConnectionCount: profile.monthlyConnectionCount ?? 0,
            isDeactivated: profile.isDeactivated ?? false,
            isPermanentlyBanned: profile.isPermanentlyBanned ?? false
        )

        if userId == currentUserId {
            userReputation = info
        }

        return info
    }

    /// Get user's current tier
    func getUserTier(userId: UUID) async throws -> ReputationTier {
        let info = try await getReputationInfo(userId: userId)
        return info.reputationTier
    }

    /// Get user's monthly connection count
    func getMonthlyConnectionCount(userId: UUID) async throws -> Int {
        let info = try await getReputationInfo(userId: userId)
        return info.monthlyConnectionCount
    }

    // MARK: - Award Reputation

    /// Award reputation points after successful connection
    func awardReputation(userId: UUID, connectionId: UUID, role: ConnectionRole) async throws {
        isLoading = true
        defer { isLoading = false }

        // Calculate points based on role
        let basePoints = Self.pointsPerConnection
        let roleBonus = role == .supporter ? Self.supporterBonus : Self.initiatorBonus
        let totalPoints = basePoints + roleBonus

        // Get current reputation
        var info = try await getReputationInfo(userId: userId)

        // Update reputation score
        let newScore = info.reputationScore + totalPoints
        let newConnections = info.successfulConnections + 1
        let newMonthlyCount = info.monthlyConnectionCount + 1

        // Check for tier advancement
        let newTier = calculateTierAdvancement(
            currentTier: info.reputationTier,
            successfulConnections: newConnections
        )

        // Update profile
        try await supabase
            .from("profiles")
            .update([
                "reputation_score": newScore,
                "successful_connections": newConnections,
                "monthly_connection_count": newMonthlyCount,
                "reputation_tier": newTier.rawValue
            ])
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Notify if tier advanced
        if newTier.rawValue > info.reputationTier.rawValue {
            await NotificationService.shared.notifyTierAdvancement(
                userId: userId,
                newTier: newTier
            )
        }

        // Reload if current user
        if userId == currentUserId {
            _ = try await loadUserReputation()
        }
    }

    /// Calculate if user should advance to a new tier
    private func calculateTierAdvancement(
        currentTier: ReputationTier,
        successfulConnections: Int
    ) -> ReputationTier {
        switch currentTier {
        case .neighbor:
            // Neighbor → Contributor requires Verified Prime + Gov ID (handled elsewhere)
            return .neighbor

        case .contributor:
            // Contributor → Pillar requires 15 successful connections
            if successfulConnections >= Self.connectionsForPillar {
                return .pillar
            }
            return .contributor

        case .pillar:
            // Already at top tier
            return .pillar
        }
    }

    // MARK: - Sanctions

    /// Apply a reputation sanction to a user
    func sanctionUser(userId: UUID, reason: SanctionReason, connectionId: UUID? = nil, details: String? = nil) async throws {
        isLoading = true
        defer { isLoading = false }

        let info = try await getReputationInfo(userId: userId)

        // Calculate penalty based on severity
        let penalty: Int
        var shouldDeactivate = false
        var shouldBan = false

        switch reason.severity {
        case .mild:
            penalty = 5

        case .moderate:
            penalty = 15
            // Deactivate if reputation drops below threshold
            if info.reputationScore - penalty < 0 {
                shouldDeactivate = true
            }

        case .severe:
            penalty = 30
            shouldDeactivate = true
            // Permanent ban if ID verified (they can't just create new account)
            // This would be checked via verification status
            shouldBan = await checkIfIDVerified(userId: userId)
        }

        // Apply penalty
        let newScore = max(0, info.reputationScore - penalty)

        var updateData: [String: String] = [
            "reputation_score": "\(newScore)"
        ]

        if shouldDeactivate {
            updateData["is_deactivated"] = "true"
        }

        if shouldBan {
            updateData["is_permanently_banned"] = "true"
        }

        try await supabase
            .from("profiles")
            .update(updateData)
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Log the sanction
        try await logSanction(
            userId: userId,
            reason: reason,
            penalty: penalty,
            connectionId: connectionId,
            details: details,
            wasDeactivated: shouldDeactivate,
            wasBanned: shouldBan
        )

        // Reload if current user
        if userId == currentUserId {
            _ = try await loadUserReputation()
        }
    }

    /// Check if user is ID verified (for permanent ban eligibility)
    private func checkIfIDVerified(userId: UUID) async -> Bool {
        struct VerificationStatus: Decodable {
            let isGovIdVerified: Bool?

            enum CodingKeys: String, CodingKey {
                case isGovIdVerified = "is_gov_id_verified"
            }
        }

        do {
            let profiles: [VerificationStatus] = try await supabase
                .from("profiles")
                .select("is_gov_id_verified")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            return profiles.first?.isGovIdVerified ?? false
        } catch {
            return false
        }
    }

    /// Log sanction to database
    private func logSanction(
        userId: UUID,
        reason: SanctionReason,
        penalty: Int,
        connectionId: UUID?,
        details: String?,
        wasDeactivated: Bool,
        wasBanned: Bool
    ) async throws {
        struct SanctionLog: Encodable {
            let userId: UUID
            let reason: String
            let penalty: Int
            let connectionId: UUID?
            let details: String?
            let wasDeactivated: Bool
            let wasBanned: Bool
            let createdAt: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case reason
                case penalty
                case connectionId = "connection_id"
                case details
                case wasDeactivated = "was_deactivated"
                case wasBanned = "was_banned"
                case createdAt = "created_at"
            }
        }

        let log = SanctionLog(
            userId: userId,
            reason: reason.rawValue,
            penalty: penalty,
            connectionId: connectionId,
            details: details,
            wasDeactivated: wasDeactivated,
            wasBanned: wasBanned,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("reputation_sanctions")
            .insert(log)
            .execute()
    }

    // MARK: - Tier Upgrade Eligibility

    /// Check if user is eligible to upgrade to Contributor tier
    /// Requires Verified Prime + Government ID
    func checkContributorEligibility(userId: UUID) async throws -> (eligible: Bool, reason: String?) {
        struct VerificationCheck: Decodable {
            let isPrime: Bool?
            let isGovIdVerified: Bool?

            enum CodingKeys: String, CodingKey {
                case isPrime = "is_prime"
                case isGovIdVerified = "is_gov_id_verified"
            }
        }

        let profiles: [VerificationCheck] = try await supabase
            .from("profiles")
            .select("is_prime, is_gov_id_verified")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let profile = profiles.first else {
            return (false, "Profile not found")
        }

        let isPrime = profile.isPrime ?? false
        let isGovIdVerified = profile.isGovIdVerified ?? false

        if !isPrime {
            return (false, "Verified Prime membership required")
        }

        if !isGovIdVerified {
            return (false, "Government ID verification required")
        }

        return (true, nil)
    }

    /// Upgrade user to Contributor tier (after verification)
    func upgradeToContributor(userId: UUID) async throws {
        let (eligible, reason) = try await checkContributorEligibility(userId: userId)

        guard eligible else {
            throw ReputationError.notEligible(reason ?? "Not eligible for upgrade")
        }

        try await supabase
            .from("profiles")
            .update(["reputation_tier": ReputationTier.contributor.rawValue])
            .eq("user_id", value: userId.uuidString)
            .execute()

        await NotificationService.shared.notifyTierAdvancement(
            userId: userId,
            newTier: .contributor
        )
    }

    // MARK: - Monthly Reset

    /// Reset monthly connection counts (call at month start)
    func resetMonthlyConnectionCounts() async throws {
        try await supabase
            .from("profiles")
            .update(["monthly_connection_count": 0])
            .execute()
    }
}

// MARK: - Reputation Info Model

struct ReputationInfo: Codable {
    let reputationScore: Int
    let reputationTier: ReputationTier
    let successfulConnections: Int
    let monthlyConnectionCount: Int
    let isDeactivated: Bool
    let isPermanentlyBanned: Bool

    /// Check if user can use Bill Connection
    var canUseConnection: Bool {
        !isDeactivated && !isPermanentlyBanned
    }

    /// Progress to next tier (0.0 to 1.0)
    var tierProgress: Double {
        switch reputationTier {
        case .neighbor:
            // Progress is verification-based, not connection-based
            return 0.0
        case .contributor:
            // Progress toward Pillar (15 connections)
            let target = ReputationService.connectionsForPillar
            return min(1.0, Double(successfulConnections) / Double(target))
        case .pillar:
            return 1.0
        }
    }

    /// Connections remaining until next tier
    var connectionsToNextTier: Int? {
        switch reputationTier {
        case .neighbor:
            return nil  // Upgrade via verification
        case .contributor:
            let target = ReputationService.connectionsForPillar
            return max(0, target - successfulConnections)
        case .pillar:
            return nil  // Already at top
        }
    }
}

// MARK: - Errors

enum ReputationError: LocalizedError {
    case notAuthenticated
    case profileNotFound
    case notEligible(String)
    case alreadyDeactivated
    case alreadyBanned

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .profileNotFound:
            return "Profile not found"
        case .notEligible(let reason):
            return "Not eligible for upgrade: \(reason)"
        case .alreadyDeactivated:
            return "Account is already deactivated"
        case .alreadyBanned:
            return "Account is permanently banned"
        }
    }
}

//
//  ReferralService.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation
import Supabase

// MARK: - Models

struct ReferralInfo: Codable {
    let referralCode: String
    let referralCount: Int
    let referralBonusClaimed: Bool
    let referredById: UUID?

    enum CodingKeys: String, CodingKey {
        case referralCode = "referral_code"
        case referralCount = "referral_count"
        case referralBonusClaimed = "referral_bonus_claimed"
        case referredById = "referred_by_id"
    }
}

struct Referral: Codable, Identifiable {
    let id: UUID
    let referrerId: UUID
    let refereeId: UUID
    let referralCode: String
    let status: String
    let referrerPointsAwarded: Int
    let refereePointsAwarded: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case referrerId = "referrer_id"
        case refereeId = "referee_id"
        case referralCode = "referral_code"
        case status
        case referrerPointsAwarded = "referrer_points_awarded"
        case refereePointsAwarded = "referee_points_awarded"
        case createdAt = "created_at"
    }
}

struct ProcessReferralResult: Codable {
    let success: Bool
    let error: String?
    let referrerPoints: Int?
    let refereePoints: Int?
    let bonusAwarded: Bool?
    let referrerTotalReferrals: Int?

    enum CodingKeys: String, CodingKey {
        case success
        case error
        case referrerPoints = "referrer_points"
        case refereePoints = "referee_points"
        case bonusAwarded = "bonus_awarded"
        case referrerTotalReferrals = "referrer_total_referrals"
    }
}

// MARK: - Protocol

protocol ReferralServiceProtocol {
    func getReferralInfo() async throws -> ReferralInfo
    func getReferralCode() async throws -> String
    func getMyReferrals() async throws -> [Referral]
    func applyReferralCode(_ code: String) async throws -> ProcessReferralResult
    func generateShareMessage() async throws -> String
    func getReferralProgress() async throws -> ReferralProgress
}

struct ReferralProgress {
    let currentCount: Int
    let maxReferrals: Int
    let pointsEarned: Int
    let bonusClaimed: Bool
    let nextMilestone: Int?
    let progressPercent: Double

    var isAtCap: Bool {
        currentCount >= maxReferrals
    }

    var remainingReferrals: Int {
        max(0, maxReferrals - currentCount)
    }
}

// MARK: - Service Implementation

@MainActor
class ReferralService: ReferralServiceProtocol {

    // MARK: - Singleton
    static let shared = ReferralService()

    // MARK: - Constants
    private let maxReferrals = 5
    private let pointsPerReferral = 100
    private let bonusPointsAtFive = 500

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Public Methods

    /// Get the current user's referral information
    func getReferralInfo() async throws -> ReferralInfo {
        guard let session = try? await supabase.auth.session else {
            throw ReferralError.notAuthenticated
        }

        let response: ReferralInfo = try await supabase
            .from("user_profiles")
            .select("referral_code, referral_count, referral_bonus_claimed, referred_by_id")
            .eq("user_id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value

        return response
    }

    /// Get just the referral code (auto-generates if missing)
    func getReferralCode() async throws -> String {
        let info = try await getReferralInfo()

        // If code is nil or empty, trigger generation by updating profile
        if info.referralCode.isEmpty {
            guard let session = try? await supabase.auth.session else {
                throw ReferralError.notAuthenticated
            }

            // Trigger the auto-generation trigger by updating a dummy field
            try await supabase
                .from("user_profiles")
                .update(["updated_at": ISO8601DateFormatter().string(from: Date())])
                .eq("user_id", value: session.user.id.uuidString)
                .execute()

            // Fetch the newly generated code
            let updatedInfo = try await getReferralInfo()
            return updatedInfo.referralCode
        }

        return info.referralCode
    }

    /// Get all referrals made by the current user
    func getMyReferrals() async throws -> [Referral] {
        guard let session = try? await supabase.auth.session else {
            throw ReferralError.notAuthenticated
        }

        let response: [Referral] = try await supabase
            .from("referrals")
            .select()
            .eq("referrer_id", value: session.user.id.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    /// Apply a referral code (for new users signing up with a code)
    func applyReferralCode(_ code: String) async throws -> ProcessReferralResult {
        guard let session = try? await supabase.auth.session else {
            throw ReferralError.notAuthenticated
        }

        // Validate code format
        let cleanCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanCode.count == 8 else {
            return ProcessReferralResult(
                success: false,
                error: "Invalid referral code format",
                referrerPoints: nil,
                refereePoints: nil,
                bonusAwarded: nil,
                referrerTotalReferrals: nil
            )
        }

        // Check user hasn't already been referred
        let existingInfo = try await getReferralInfo()
        if existingInfo.referredById != nil {
            return ProcessReferralResult(
                success: false,
                error: "You've already used a referral code",
                referrerPoints: nil,
                refereePoints: nil,
                bonusAwarded: nil,
                referrerTotalReferrals: nil
            )
        }

        // Call the database function to process the referral
        let result: ProcessReferralResult = try await supabase
            .rpc("process_referral", params: [
                "p_referee_id": session.user.id.uuidString,
                "p_referral_code": cleanCode
            ])
            .execute()
            .value

        return result
    }

    /// Generate a share message with the user's referral code
    func generateShareMessage() async throws -> String {
        let code = try await getReferralCode()

        return """
        Join me on Billix and we both get $1 in rewards! 💰

        Use my code: \(code)

        Track your bills, find savings, and earn rewards.
        Download: https://billix.app/download
        """
    }

    /// Get the user's referral progress for UI display
    func getReferralProgress() async throws -> ReferralProgress {
        let info = try await getReferralInfo()

        let pointsEarned = info.referralCount * pointsPerReferral +
            (info.referralBonusClaimed ? bonusPointsAtFive : 0)

        let nextMilestone: Int? = info.referralCount < maxReferrals ? maxReferrals : nil

        let progressPercent = Double(info.referralCount) / Double(maxReferrals)

        return ReferralProgress(
            currentCount: info.referralCount,
            maxReferrals: maxReferrals,
            pointsEarned: pointsEarned,
            bonusClaimed: info.referralBonusClaimed,
            nextMilestone: nextMilestone,
            progressPercent: min(1.0, progressPercent)
        )
    }

    // MARK: - Share Helpers

    /// Get the formatted referral code for display
    func getFormattedCode() async throws -> String {
        let code = try await getReferralCode()
        // Format as XXXX-XXXX for easier reading
        let midIndex = code.index(code.startIndex, offsetBy: 4)
        return "\(code[..<midIndex])-\(code[midIndex...])"
    }

    /// Copy referral code to clipboard (returns the code)
    func copyCodeToClipboard() async throws -> String {
        let code = try await getReferralCode()
        // Note: UIPasteboard.general.string = code would be called in the view
        return code
    }
}

// MARK: - Errors

enum ReferralError: LocalizedError {
    case notAuthenticated
    case invalidCode
    case alreadyReferred
    case referrerAtCap
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to use referral features"
        case .invalidCode:
            return "Invalid referral code"
        case .alreadyReferred:
            return "You've already used a referral code"
        case .referrerAtCap:
            return "This referral code has reached its limit"
        case .processingFailed(let message):
            return "Failed to process referral: \(message)"
        }
    }
}

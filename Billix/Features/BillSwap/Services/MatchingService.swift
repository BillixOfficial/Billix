//
//  MatchingService.swift
//  Billix
//
//  Auto-Match Service for Bill Swap Marketplace
//

import Foundation
import Supabase

// MARK: - Matching Service

@MainActor
class MatchingService: ObservableObject {
    static let shared = MatchingService()

    @Published var proposedMatches: [SwapMatch] = []
    @Published var isMatching = false
    @Published var matchError: String?

    private let supabase = SupabaseService.shared.client

    private init() {}

    // MARK: - Find Matches

    /// Find potential swap matches for a given bill
    func findMatches(for bill: SwapBill, userProfile: TrustProfile) async throws -> [SwapMatch] {
        isMatching = true
        matchError = nil

        defer { isMatching = false }

        do {
            // Fetch available bills from other users
            let availableBills = try await fetchAvailableBills(
                excludeUserId: userProfile.userId,
                minCents: userProfile.tier.minBillCents,
                maxCents: userProfile.tier.maxBillCents
            )

            // Score and filter matches
            var matches: [SwapMatch] = []

            for otherBill in availableBills {
                guard let otherProfile = otherBill.ownerProfile else { continue }

                // Calculate match score
                let (score, reasons) = calculateMatchScore(
                    yourBill: bill,
                    theirBill: otherBill,
                    theirProfile: otherProfile
                )

                // Only include matches with score > 30
                guard score > 30 else { continue }

                // Calculate fees
                let fees = MatchFees.calculate(
                    yourBillCents: bill.amountCents,
                    theirBillCents: otherBill.amountCents
                )

                let match = SwapMatch(
                    yourBill: bill,
                    theirBill: otherBill,
                    partnerProfile: otherProfile,
                    matchScore: score,
                    matchReasons: reasons,
                    estimatedFees: fees
                )

                matches.append(match)
            }

            // Sort by score descending, take top 10
            let topMatches = matches
                .sorted { $0.matchScore > $1.matchScore }
                .prefix(10)

            proposedMatches = Array(topMatches)
            return proposedMatches

        } catch {
            matchError = error.localizedDescription
            throw error
        }
    }

    // MARK: - Fetch Available Bills

    private func fetchAvailableBills(
        excludeUserId: UUID,
        minCents: Int,
        maxCents: Int
    ) async throws -> [SwapBill] {
        // Fetch bills that are:
        // 1. Not owned by current user
        // 2. Status is AVAILABLE
        // 3. Within amount range
        // 4. Due date is in the future

        let response: [SwapBillWithProfile] = try await supabase
            .from("swap_bills")
            .select("""
                *,
                trust_profiles!inner (
                    user_id,
                    trust_score,
                    tier,
                    completed_swaps_count,
                    failed_swaps_count,
                    success_rate,
                    display_name,
                    handle,
                    is_id_verified
                )
            """)
            .neq("user_id", value: excludeUserId.uuidString)
            .eq("status", value: "AVAILABLE")
            .gte("amount_cents", value: minCents)
            .lte("amount_cents", value: maxCents)
            .gte("due_date", value: ISO8601DateFormatter().string(from: Date()))
            .order("amount_cents", ascending: true)
            .limit(50)
            .execute()
            .value

        return response.map { $0.toSwapBill() }
    }

    // MARK: - Match Scoring Algorithm

    /// Calculate match score (0-100) and reasons
    private func calculateMatchScore(
        yourBill: SwapBill,
        theirBill: SwapBill,
        theirProfile: TrustProfile
    ) -> (Double, [MatchReason]) {
        var score: Double = 0
        var reasons: [MatchReason] = []

        // 1. Amount similarity (up to 25 points)
        let amountDiff = abs(yourBill.amountCents - theirBill.amountCents)
        let maxAmount = max(yourBill.amountCents, theirBill.amountCents)
        let amountSimilarity = 1.0 - (Double(amountDiff) / Double(maxAmount))

        if amountDiff == 0 {
            score += MatchReason.exactAmount.scoreContribution
            reasons.append(.exactAmount)
        } else if amountSimilarity >= 0.85 {
            score += MatchReason.similarAmount.scoreContribution
            reasons.append(.similarAmount)
        } else {
            // Partial score for moderate similarity
            score += amountSimilarity * 15
        }

        // 2. Due date alignment (up to 15 points)
        let calendar = Calendar.current
        let daysDiff = abs(calendar.dateComponents(
            [.day],
            from: yourBill.dueDate,
            to: theirBill.dueDate
        ).day ?? 0)

        if daysDiff <= 3 {
            score += MatchReason.complementaryDueDate.scoreContribution
            reasons.append(.complementaryDueDate)
        } else if daysDiff <= 7 {
            score += 10
        } else if daysDiff <= 14 {
            score += 5
        }

        // 3. Category match (10 points)
        if yourBill.category == theirBill.category {
            score += MatchReason.categoryMatch.scoreContribution
            reasons.append(.categoryMatch)
        }

        // 4. Trust tier compatibility (up to 15 points)
        if theirProfile.tier == .T4_POWER || theirProfile.tier == .T5_ELITE {
            score += MatchReason.highTrustPartner.scoreContribution
            reasons.append(.highTrustPartner)
        } else if theirProfile.tier.tierNumber >= 2 {
            score += MatchReason.sameTier.scoreContribution
            reasons.append(.sameTier)
        }

        // 5. Reliable partner bonus (10 points)
        if theirProfile.successRate >= 90 && theirProfile.completedSwapsCount >= 5 {
            score += MatchReason.reliablePartner.scoreContribution
            reasons.append(.reliablePartner)
        }

        // 6. Urgent bill priority (5 points)
        let yourDaysUntilDue = calendar.dateComponents([.day], from: Date(), to: yourBill.dueDate).day ?? 0
        if yourDaysUntilDue <= 3 {
            score += MatchReason.urgentBill.scoreContribution
            reasons.append(.urgentBill)
        }

        // Cap at 100
        return (min(100, score), reasons)
    }

    // MARK: - Quick Match

    /// Find the single best match for a bill (for quick-match feature)
    func findBestMatch(for bill: SwapBill, userProfile: TrustProfile) async throws -> SwapMatch? {
        let matches = try await findMatches(for: bill, userProfile: userProfile)
        return matches.first
    }

    // MARK: - Refresh Matches

    /// Refresh matches for all user's available bills
    func refreshAllMatches(for bills: [SwapBill], userProfile: TrustProfile) async throws {
        var allMatches: [SwapMatch] = []

        for bill in bills where bill.status == .active {
            let matches = try await findMatches(for: bill, userProfile: userProfile)
            allMatches.append(contentsOf: matches)
        }

        // Deduplicate and sort by score
        let uniqueMatches = Dictionary(grouping: allMatches, by: { $0.id })
            .values
            .compactMap { $0.first }
            .sorted { $0.matchScore > $1.matchScore }

        proposedMatches = Array(uniqueMatches.prefix(20))
    }
}

// MARK: - Helper Types for Supabase Response

private struct SwapBillWithProfile: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let providerName: String?
    let amountCents: Int
    let category: String
    let dueDate: Date
    let accountNumberLast4: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date
    let trustProfiles: TrustProfileResponse

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case providerName = "provider_name"
        case amountCents = "amount_cents"
        case category
        case dueDate = "due_date"
        case accountNumberLast4 = "account_number_last_4"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case trustProfiles = "trust_profiles"
    }

    func toSwapBill() -> SwapBill {
        var bill = SwapBill(
            id: id,
            ownerUserId: userId,
            title: title,
            category: SwapBillCategory(rawValue: category) ?? .electric,
            providerName: providerName,
            amountCents: amountCents,
            dueDate: dueDate,
            status: SwapBillStatus(rawValue: status) ?? .active,
            paymentUrl: nil,
            accountNumberLast4: accountNumberLast4,
            billImageUrl: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        bill.ownerProfile = trustProfiles.toTrustProfile()
        return bill
    }
}

private struct TrustProfileResponse: Codable {
    let userId: UUID
    let trustScore: Int
    let tier: String
    let completedSwapsCount: Int
    let failedSwapsCount: Int
    let successRate: Double
    let displayName: String?
    let handle: String?
    let isIdVerified: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case trustScore = "trust_score"
        case tier
        case completedSwapsCount = "completed_swaps_count"
        case failedSwapsCount = "failed_swaps_count"
        case successRate = "success_rate"
        case displayName = "display_name"
        case handle
        case isIdVerified = "is_id_verified"
    }

    func toTrustProfile() -> TrustProfile {
        TrustProfile(
            userId: userId,
            trustScore: trustScore,
            tier: SwapTrustTier(rawValue: tier) ?? .T1_PROVISIONAL,
            completedSwapsCount: completedSwapsCount,
            failedSwapsCount: failedSwapsCount,
            disputedAtFaultCount: 0,
            noShowCount: 0,
            activeSwapsCount: 0,
            currentStreak: 0,
            consecutiveSuccessfulSwaps: 0,
            lastSwapDate: nil,
            isIdVerified: isIdVerified,
            hasGovIdVerification: false,
            hasBankLinkVerification: false,
            hasWorkEmailVerification: false,
            successRate: successRate,
            billixPointsBalance: 0,
            displayName: displayName,
            handle: handle,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Match Preferences

/// User preferences for matching
struct MatchPreferences: Codable {
    var preferredCategories: [SwapBillCategory]?
    var maxAmountDifferencePercent: Double?
    var maxDueDateDays: Int?
    var minPartnerTier: SwapTrustTier?
    var autoMatchEnabled: Bool

    static var `default`: MatchPreferences {
        MatchPreferences(
            preferredCategories: nil,
            maxAmountDifferencePercent: 20,
            maxDueDateDays: 14,
            minPartnerTier: nil,
            autoMatchEnabled: true
        )
    }
}

//
//  SwapMatchingService.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Service for finding Mirror Partners and managing swap matching
//

import Foundation
import Supabase

// MARK: - Errors

enum SwapMatchError: LocalizedError {
    case notAuthenticated
    case noMatchesFound
    case matchExpired
    case partnerUnavailable
    case billNotEligible
    case alreadyMatched
    case swapCreationFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .noMatchesFound:
            return "No matching partners found. Try again later."
        case .matchExpired:
            return "This match has expired"
        case .partnerUnavailable:
            return "This partner is no longer available"
        case .billNotEligible:
            return "This bill is not eligible for swapping"
        case .alreadyMatched:
            return "You already have an active swap for this bill"
        case .swapCreationFailed:
            return "Failed to create swap"
        }
    }
}

// MARK: - Match Parameters

struct MatchSearchParams {
    let billId: UUID
    let billCategory: String
    let billAmount: Double
    let billDueDay: Int
    let userPaydayType: String
    let userPaydayDays: [Int]
    let tierNumber: Int
    let maxResults: Int

    init(
        bill: UserBill,
        payday: PaydaySchedule,
        tier: TrustTier,
        maxResults: Int = 10
    ) {
        self.billId = bill.id
        self.billCategory = bill.billCategory
        self.billAmount = bill.typicalAmount
        self.billDueDay = bill.dueDay
        self.userPaydayType = payday.paydayType
        self.userPaydayDays = payday.paydayDays
        self.tierNumber = tier.rawValue
        self.maxResults = maxResults
    }
}

// MARK: - Swap Matching Service

@MainActor
class SwapMatchingService: ObservableObject {

    // MARK: - Singleton
    static let shared = SwapMatchingService()

    // MARK: - Published Properties
    @Published var availableMatches: [MatchedPartner] = []
    @Published var isSearching = false
    @Published var searchError: SwapMatchError?

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Find Mirror Partners

    /// Finds potential swap partners using the Mirror Partner algorithm
    /// Mirror Partners have money when you're broke (opposite payday schedules)
    func findMirrorPartners(for bill: UserBill, payday: PaydaySchedule, tier: TrustTier) async throws -> [MatchedPartner] {
        guard let session = try? await supabase.auth.session else {
            throw SwapMatchError.notAuthenticated
        }

        isSearching = true
        searchError = nil
        defer { isSearching = false }

        let params = MatchSearchParams(bill: bill, payday: payday, tier: tier)

        // For now, use local matching algorithm
        // The RPC functions exist in the database but require proper parameter encoding
        return try await findMatchesLocally(
            userId: session.user.id,
            params: params
        )
    }

    /// Local fallback matching algorithm when RPC is not available
    private func findMatchesLocally(userId: UUID, params: MatchSearchParams) async throws -> [MatchedPartner] {
        // For MVP, return empty matches since we need proper user base
        // In production, this would query the database for matching users
        // The RPC functions exist but require proper parameter encoding
        let potentialPartners: [PotentialPartnerData] = []

        // Calculate match scores and create MatchedPartner objects
        var matches: [MatchedPartner] = []

        for partner in potentialPartners {
            let matchScore = calculateMatchScore(
                userPaydayDays: params.userPaydayDays,
                userBillDueDay: params.billDueDay,
                partnerPaydayDays: partner.paydayDays,
                partnerBillDueDay: partner.billDueDay,
                userAmount: params.billAmount,
                partnerAmount: partner.billAmount
            )

            // Only include good matches (score > 0.5)
            if matchScore > 0.5 {
                let executionWindow = calculateExecutionWindow(
                    userPaydayDays: params.userPaydayDays,
                    partnerPaydayDays: partner.paydayDays,
                    userBillDueDay: params.billDueDay,
                    partnerBillDueDay: partner.billDueDay
                )

                let match = MatchedPartner(
                    id: UUID(),
                    partnerId: partner.userId,
                    partnerHandle: partner.handle,
                    partnerInitials: partner.initials,
                    partnerTrustScore: partner.trustScore,
                    partnerSuccessfulSwaps: partner.successfulSwaps,
                    partnerRating: partner.rating,
                    matchScore: matchScore,
                    partnerBillCategory: partner.billCategory,
                    partnerBillProvider: partner.providerName,
                    partnerAmount: partner.billAmount,
                    partnerDueDay: partner.billDueDay,
                    executionWindowStart: executionWindow.start,
                    executionWindowEnd: executionWindow.end
                )
                matches.append(match)
            }
        }

        // Sort by match score descending
        matches.sort { $0.matchScore > $1.matchScore }

        // Limit results
        let limitedMatches = Array(matches.prefix(params.maxResults))
        self.availableMatches = limitedMatches

        return limitedMatches
    }

    // MARK: - Match Score Calculation

    /// Calculates how well two users' schedules align for swapping
    /// Higher score = better match (opposite money availability)
    private func calculateMatchScore(
        userPaydayDays: [Int],
        userBillDueDay: Int,
        partnerPaydayDays: [Int],
        partnerBillDueDay: Int,
        userAmount: Double,
        partnerAmount: Double
    ) -> Double {
        var score = 0.0

        // 1. Timing alignment (40% of score)
        // Best match: Partner gets paid right before user's bill is due
        // And user gets paid right before partner's bill is due
        let timingScore = calculateTimingScore(
            userPaydayDays: userPaydayDays,
            userBillDueDay: userBillDueDay,
            partnerPaydayDays: partnerPaydayDays,
            partnerBillDueDay: partnerBillDueDay
        )
        score += timingScore * 0.4

        // 2. Amount similarity (30% of score)
        // Closer amounts = more balanced swap
        let amountDiff = abs(userAmount - partnerAmount)
        let maxAmount = max(userAmount, partnerAmount)
        let amountScore = maxAmount > 0 ? 1.0 - (amountDiff / maxAmount) : 1.0
        score += amountScore * 0.3

        // 3. Calendar opposition (30% of score)
        // Ideal: User and partner have opposite payday schedules
        let oppositionScore = calculateOppositionScore(
            userPaydayDays: userPaydayDays,
            partnerPaydayDays: partnerPaydayDays
        )
        score += oppositionScore * 0.3

        return min(1.0, max(0.0, score))
    }

    /// Calculates how well the timing works for the swap
    private func calculateTimingScore(
        userPaydayDays: [Int],
        userBillDueDay: Int,
        partnerPaydayDays: [Int],
        partnerBillDueDay: Int
    ) -> Double {
        // Best case: Partner's payday is 1-5 days before user's bill due date
        // And user's payday is 1-5 days before partner's bill due date

        var score = 0.0

        // Check if partner can pay user's bill on time
        for partnerPayday in partnerPaydayDays {
            let daysBeforeUserBill = (userBillDueDay - partnerPayday + 31) % 31
            if daysBeforeUserBill >= 1 && daysBeforeUserBill <= 7 {
                score += 0.5
                break
            } else if daysBeforeUserBill >= 0 && daysBeforeUserBill <= 14 {
                score += 0.3
                break
            }
        }

        // Check if user can pay partner's bill on time
        for userPayday in userPaydayDays {
            let daysBeforePartnerBill = (partnerBillDueDay - userPayday + 31) % 31
            if daysBeforePartnerBill >= 1 && daysBeforePartnerBill <= 7 {
                score += 0.5
                break
            } else if daysBeforePartnerBill >= 0 && daysBeforePartnerBill <= 14 {
                score += 0.3
                break
            }
        }

        return score
    }

    /// Calculates how opposite the payday schedules are
    private func calculateOppositionScore(
        userPaydayDays: [Int],
        partnerPaydayDays: [Int]
    ) -> Double {
        // Calculate the minimum distance between any user payday and partner payday
        var minDistance = 31

        for userDay in userPaydayDays {
            for partnerDay in partnerPaydayDays {
                let distance = min(
                    abs(userDay - partnerDay),
                    31 - abs(userDay - partnerDay)
                )
                minDistance = min(minDistance, distance)
            }
        }

        // Ideal opposition: paydays are ~15 days apart
        // Score is highest when distance is around 15, lowest when 0
        let idealDistance = 15.0
        let normalizedDistance = Double(minDistance) / idealDistance

        if normalizedDistance >= 1.0 {
            return 1.0
        } else {
            return normalizedDistance
        }
    }

    // MARK: - Execution Window Calculation

    /// Calculates the optimal execution window for a swap
    private func calculateExecutionWindow(
        userPaydayDays: [Int],
        partnerPaydayDays: [Int],
        userBillDueDay: Int,
        partnerBillDueDay: Int
    ) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        // Find the earliest upcoming payday (either user or partner)
        var earliestPayday: Date = now

        let currentDay = calendar.component(.day, from: now)
        let allPaydays = (userPaydayDays + partnerPaydayDays).sorted()

        for payday in allPaydays {
            if payday > currentDay {
                var components = calendar.dateComponents([.year, .month], from: now)
                components.day = payday
                if let date = calendar.date(from: components) {
                    earliestPayday = date
                    break
                }
            }
        }

        // If no payday this month, use first payday next month
        if earliestPayday <= now, let firstPayday = allPaydays.first {
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) {
                var components = calendar.dateComponents([.year, .month], from: nextMonth)
                components.day = firstPayday
                if let date = calendar.date(from: components) {
                    earliestPayday = date
                }
            }
        }

        // Execution window: payday to payday + 24 hours
        let windowStart = earliestPayday
        let windowEnd = calendar.date(byAdding: .hour, value: 24, to: windowStart) ?? windowStart

        return (windowStart, windowEnd)
    }

    // MARK: - Confirm Match

    /// Confirms a match and creates a pending swap
    func confirmMatch(_ match: MatchedPartner, myBill: UserBill) async throws -> Swap {
        guard let session = try? await supabase.auth.session else {
            throw SwapMatchError.notAuthenticated
        }

        // Check if user already has an active swap for this bill
        let existingSwaps: [Swap] = try await supabase
            .from("swaps")
            .select()
            .eq("user_a_id", value: session.user.id.uuidString)
            .eq("user_a_bill_id", value: myBill.id.uuidString)
            .in("status", values: ["pending", "matched", "fee_pending", "fee_paid", "leg_a_complete", "leg_b_complete"])
            .execute()
            .value

        if !existingSwaps.isEmpty {
            throw SwapMatchError.alreadyMatched
        }

        // Create swap record
        let swapInsert = SwapInsert(
            userAId: session.user.id.uuidString,
            userABillId: myBill.id.uuidString,
            userAAmount: myBill.typicalAmount,
            userBId: match.partnerId.uuidString,
            userBBillId: match.id.uuidString,
            userBAmount: match.partnerAmount,
            tierNumber: myBill.category?.tier.rawValue ?? 1,
            status: "matched",
            matchScore: match.matchScore,
            matchedAt: ISO8601DateFormatter().string(from: Date()),
            executionWindowStart: ISO8601DateFormatter().string(from: match.executionWindowStart),
            executionDeadline: ISO8601DateFormatter().string(from: match.executionWindowEnd)
        )

        let swap: Swap = try await supabase
            .from("swaps")
            .insert(swapInsert)
            .select()
            .single()
            .execute()
            .value

        // Remove the match from available matches
        availableMatches.removeAll { $0.id == match.id }

        return swap
    }

    // MARK: - Clear Matches

    func clearMatches() {
        availableMatches = []
        searchError = nil
    }
}

// MARK: - Insert/Update Structs

private struct SwapInsert: Codable {
    let userAId: String
    let userABillId: String
    let userAAmount: Double
    let userBId: String
    let userBBillId: String
    let userBAmount: Double
    let tierNumber: Int
    let status: String
    let matchScore: Double
    let matchedAt: String
    let executionWindowStart: String
    let executionDeadline: String

    enum CodingKeys: String, CodingKey {
        case userAId = "user_a_id"
        case userABillId = "user_a_bill_id"
        case userAAmount = "user_a_amount"
        case userBId = "user_b_id"
        case userBBillId = "user_b_bill_id"
        case userBAmount = "user_b_amount"
        case tierNumber = "tier_number"
        case status
        case matchScore = "match_score"
        case matchedAt = "matched_at"
        case executionWindowStart = "execution_window_start"
        case executionDeadline = "execution_deadline"
    }
}

// MARK: - Supporting Types

/// Data structure for potential partner query results
private struct PotentialPartnerData: Codable {
    let userId: UUID
    let handle: String
    let initials: String
    let trustScore: Int
    let successfulSwaps: Int
    let rating: Double
    let billId: UUID
    let billCategory: String
    let providerName: String
    let billAmount: Double
    let billDueDay: Int
    let paydayType: String
    let paydayDays: [Int]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case handle
        case initials
        case trustScore = "trust_score"
        case successfulSwaps = "successful_swaps"
        case rating
        case billId = "bill_id"
        case billCategory = "bill_category"
        case providerName = "provider_name"
        case billAmount = "bill_amount"
        case billDueDay = "bill_due_day"
        case paydayType = "payday_type"
        case paydayDays = "payday_days"
    }
}

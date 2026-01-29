//
//  CollateralService.swift
//  Billix
//
//  Service for managing non-monetary collateral (trust points, eligibility, credits)
//

import Foundation
import Supabase

/// Service for managing platform collateral/trust deposits
@MainActor
class CollateralService: ObservableObject {

    // MARK: - Singleton

    static let shared = CollateralService()

    // MARK: - Constants

    /// Trust points locked per active swap
    static let trustPointsPerSwap = 10

    /// Days of swap eligibility lock for failed swaps
    static let eligibilityLockDays = 7

    /// Bonus percentage for staked credits returned on completion
    static let creditStakeBonus: Decimal = 0.05

    // MARK: - Published Properties

    @Published var userTrustPoints: Int = 100
    @Published var lockedTrustPoints: Int = 0
    @Published var isEligibilityLocked: Bool = false
    @Published var eligibilityLockedUntil: Date?
    @Published var stakedCredits: Decimal = 0
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    private init() {}

    // MARK: - Load User Collateral State

    /// Load current user's collateral status
    func loadUserCollateral() async throws {
        guard let userId = currentUserId else {
            throw CollateralError.notAuthenticated
        }

        struct ProfileCollateral: Decodable {
            let trustPoints: Int?
            let trustPointsLocked: Int?
            let swapEligibilityLocked: Bool?
            let swapEligibilityLockedUntil: Date?
            let creditsStaked: Decimal?

            enum CodingKeys: String, CodingKey {
                case trustPoints = "trust_points"
                case trustPointsLocked = "trust_points_locked"
                case swapEligibilityLocked = "swap_eligibility_locked"
                case swapEligibilityLockedUntil = "swap_eligibility_locked_until"
                case creditsStaked = "credits_staked"
            }
        }

        let profiles: [ProfileCollateral] = try await supabase
            .from("profiles")
            .select("trust_points, trust_points_locked, swap_eligibility_locked, swap_eligibility_locked_until, credits_staked")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        if let profile = profiles.first {
            userTrustPoints = profile.trustPoints ?? 100
            lockedTrustPoints = profile.trustPointsLocked ?? 0
            isEligibilityLocked = profile.swapEligibilityLocked ?? false
            eligibilityLockedUntil = profile.swapEligibilityLockedUntil
            stakedCredits = profile.creditsStaked ?? 0

            // Check if eligibility lock has expired
            if let lockedUntil = eligibilityLockedUntil, Date() > lockedUntil {
                try await unlockSwapEligibility(userId: userId)
            }
        }
    }

    // MARK: - Trust Points

    /// Lock trust points for a swap
    func lockTrustPoints(userId: UUID, amount: Int) async throws {
        isLoading = true
        defer { isLoading = false }

        // Get current state
        struct ProfilePoints: Decodable {
            let trustPoints: Int?
            let trustPointsLocked: Int?

            enum CodingKeys: String, CodingKey {
                case trustPoints = "trust_points"
                case trustPointsLocked = "trust_points_locked"
            }
        }

        let profiles: [ProfilePoints] = try await supabase
            .from("profiles")
            .select("trust_points, trust_points_locked")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let profile = profiles.first else {
            throw CollateralError.profileNotFound
        }

        let currentPoints = profile.trustPoints ?? 100
        let currentLocked = profile.trustPointsLocked ?? 0

        // Check if user has enough points
        let availablePoints = currentPoints - currentLocked
        guard availablePoints >= amount else {
            throw CollateralError.insufficientTrustPoints
        }

        // Update locked amount
        try await supabase
            .from("profiles")
            .update(["trust_points_locked": currentLocked + amount])
            .eq("user_id", value: userId.uuidString)
            .execute()

        lockedTrustPoints = currentLocked + amount
    }

    /// Release trust points after successful swap
    func releaseTrustPoints(userId: UUID, amount: Int) async throws {
        isLoading = true
        defer { isLoading = false }

        struct ProfilePoints: Decodable {
            let trustPointsLocked: Int?

            enum CodingKeys: String, CodingKey {
                case trustPointsLocked = "trust_points_locked"
            }
        }

        let profiles: [ProfilePoints] = try await supabase
            .from("profiles")
            .select("trust_points_locked")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        let currentLocked = profiles.first?.trustPointsLocked ?? 0
        let newLocked = max(0, currentLocked - amount)

        try await supabase
            .from("profiles")
            .update(["trust_points_locked": newLocked])
            .eq("user_id", value: userId.uuidString)
            .execute()

        lockedTrustPoints = newLocked
    }

    /// Deduct trust points as penalty
    func deductTrustPoints(userId: UUID, amount: Int) async throws {
        isLoading = true
        defer { isLoading = false }

        struct ProfilePoints: Decodable {
            let trustPoints: Int?
            let trustPointsLocked: Int?

            enum CodingKeys: String, CodingKey {
                case trustPoints = "trust_points"
                case trustPointsLocked = "trust_points_locked"
            }
        }

        let profiles: [ProfilePoints] = try await supabase
            .from("profiles")
            .select("trust_points, trust_points_locked")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let profile = profiles.first else {
            throw CollateralError.profileNotFound
        }

        let currentPoints = profile.trustPoints ?? 100
        let currentLocked = profile.trustPointsLocked ?? 0
        let newPoints = max(0, currentPoints - amount)
        let newLocked = max(0, currentLocked - amount)

        try await supabase
            .from("profiles")
            .update(["trust_points": newPoints, "trust_points_locked": newLocked])
            .eq("user_id", value: userId.uuidString)
            .execute()

        userTrustPoints = newPoints
        lockedTrustPoints = newLocked
    }

    /// Award trust points (on successful completion)
    func awardTrustPoints(userId: UUID, amount: Int) async throws {
        struct ProfilePoints: Decodable {
            let trustPoints: Int?

            enum CodingKeys: String, CodingKey {
                case trustPoints = "trust_points"
            }
        }

        let profiles: [ProfilePoints] = try await supabase
            .from("profiles")
            .select("trust_points")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        let currentPoints = profiles.first?.trustPoints ?? 100
        let newPoints = currentPoints + amount

        try await supabase
            .from("profiles")
            .update(["trust_points": newPoints])
            .eq("user_id", value: userId.uuidString)
            .execute()

        if userId == currentUserId {
            userTrustPoints = newPoints
        }
    }

    // MARK: - Swap Eligibility

    /// Lock user's ability to start new swaps
    func lockSwapEligibility(userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        let lockedUntil = Calendar.current.date(
            byAdding: .day,
            value: Self.eligibilityLockDays,
            to: Date()
        ) ?? Date()

        let updateData: [String: String] = [
            "swap_eligibility_locked": "true",
            "swap_eligibility_locked_until": ISO8601DateFormatter().string(from: lockedUntil)
        ]
        try await supabase
            .from("profiles")
            .update(updateData)
            .eq("user_id", value: userId.uuidString)
            .execute()

        if userId == currentUserId {
            isEligibilityLocked = true
            eligibilityLockedUntil = lockedUntil
        }
    }

    /// Unlock user's swap eligibility
    func unlockSwapEligibility(userId: UUID) async throws {
        let unlockData: [String: String?] = [
            "swap_eligibility_locked": "false",
            "swap_eligibility_locked_until": nil
        ]
        try await supabase
            .from("profiles")
            .update(unlockData)
            .eq("user_id", value: userId.uuidString)
            .execute()

        if userId == currentUserId {
            isEligibilityLocked = false
            eligibilityLockedUntil = nil
        }
    }

    /// Check if user can start new swaps
    func canStartSwap(userId: UUID) async throws -> Bool {
        struct ProfileEligibility: Decodable {
            let swapEligibilityLocked: Bool?
            let swapEligibilityLockedUntil: Date?

            enum CodingKeys: String, CodingKey {
                case swapEligibilityLocked = "swap_eligibility_locked"
                case swapEligibilityLockedUntil = "swap_eligibility_locked_until"
            }
        }

        let profiles: [ProfileEligibility] = try await supabase
            .from("profiles")
            .select("swap_eligibility_locked, swap_eligibility_locked_until")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let profile = profiles.first else { return true }

        // If locked, check if lock has expired
        if profile.swapEligibilityLocked == true {
            if let lockedUntil = profile.swapEligibilityLockedUntil, Date() > lockedUntil {
                // Lock expired, unlock them
                try await unlockSwapEligibility(userId: userId)
                return true
            }
            return false
        }

        return true
    }

    // MARK: - Credits Staking

    /// Stake credits as trust deposit
    func stakeCredits(userId: UUID, amount: Decimal) async throws {
        isLoading = true
        defer { isLoading = false }

        struct ProfileCredits: Decodable {
            let creditsStaked: Decimal?

            enum CodingKeys: String, CodingKey {
                case creditsStaked = "credits_staked"
            }
        }

        let profiles: [ProfileCredits] = try await supabase
            .from("profiles")
            .select("credits_staked")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        let currentStaked = profiles.first?.creditsStaked ?? 0
        let newStaked = currentStaked + amount

        try await supabase
            .from("profiles")
            .update(["credits_staked": NSDecimalNumber(decimal: newStaked).doubleValue])
            .eq("user_id", value: userId.uuidString)
            .execute()

        if userId == currentUserId {
            stakedCredits = newStaked
        }
    }

    /// Release staked credits with bonus
    func releaseCreditsWithBonus(userId: UUID, amount: Decimal) async throws {
        isLoading = true
        defer { isLoading = false }

        struct ProfileCredits: Decodable {
            let creditsStaked: Decimal?

            enum CodingKeys: String, CodingKey {
                case creditsStaked = "credits_staked"
            }
        }

        let profiles: [ProfileCredits] = try await supabase
            .from("profiles")
            .select("credits_staked")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        let currentStaked = profiles.first?.creditsStaked ?? 0
        let newStaked = max(0, currentStaked - amount)

        // Calculate bonus (5%)
        let bonus = amount * Self.creditStakeBonus
        let totalReturn = amount + bonus

        // Update staked amount
        try await supabase
            .from("profiles")
            .update(["credits_staked": NSDecimalNumber(decimal: newStaked).doubleValue])
            .eq("user_id", value: userId.uuidString)
            .execute()

        // TODO: Add credits to user's account (through CreditService)
        // try await CreditService.shared.addCredits(userId: userId, amount: totalReturn)

        if userId == currentUserId {
            stakedCredits = newStaked
        }
    }

    /// Forfeit staked credits (on failed swap)
    func forfeitCredits(userId: UUID, amount: Decimal) async throws {
        isLoading = true
        defer { isLoading = false }

        struct ProfileCredits: Decodable {
            let creditsStaked: Decimal?

            enum CodingKeys: String, CodingKey {
                case creditsStaked = "credits_staked"
            }
        }

        let profiles: [ProfileCredits] = try await supabase
            .from("profiles")
            .select("credits_staked")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        let currentStaked = profiles.first?.creditsStaked ?? 0
        let newStaked = max(0, currentStaked - amount)

        try await supabase
            .from("profiles")
            .update(["credits_staked": NSDecimalNumber(decimal: newStaked).doubleValue])
            .eq("user_id", value: userId.uuidString)
            .execute()

        if userId == currentUserId {
            stakedCredits = newStaked
        }
    }

    // MARK: - Swap Collateral Management

    /// Lock collateral for both users when a swap is accepted
    func lockCollateralForSwap(swapId: UUID, fallbackType: FallbackAction) async throws {
        // Get the swap
        let swaps: [BillSwapTransaction] = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let swap = swaps.first else {
            throw CollateralError.swapNotFound
        }

        // Lock collateral based on fallback type
        switch fallbackType {
        case .trustPointPenalty:
            try await lockTrustPoints(userId: swap.userAId, amount: Self.trustPointsPerSwap)
            try await lockTrustPoints(userId: swap.userBId, amount: Self.trustPointsPerSwap)

            // Log events
            try await SwapEventService.shared.logEvent(
                swapId: swapId,
                type: .collateralLocked,
                payload: .collateral(type: "trust_points", amount: Self.trustPointsPerSwap)
            )

        case .eligibilityLock:
            // Eligibility is locked only on failure, not upfront
            break

        case .creditStake:
            // Credits staking is handled separately when user chooses to stake
            break
        }
    }

    /// Release collateral after successful swap completion
    func releaseCollateralForSwap(swapId: UUID) async throws {
        // Get the swap
        let swaps: [BillSwapTransaction] = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let swap = swaps.first else {
            throw CollateralError.swapNotFound
        }

        // Release trust points
        try await releaseTrustPoints(userId: swap.userAId, amount: Self.trustPointsPerSwap)
        try await releaseTrustPoints(userId: swap.userBId, amount: Self.trustPointsPerSwap)

        // Award bonus trust points for completion
        try await awardTrustPoints(userId: swap.userAId, amount: 5)
        try await awardTrustPoints(userId: swap.userBId, amount: 5)

        // Log events
        try await SwapEventService.shared.logSystemEvent(
            swapId: swapId,
            type: .collateralReleased,
            payload: .collateral(type: "trust_points", amount: Self.trustPointsPerSwap)
        )
    }

    /// Apply collateral penalty for failed swap
    func applyPenaltyForSwap(swapId: UUID, failedUserId: UUID, fallbackType: FallbackAction) async throws {
        switch fallbackType {
        case .trustPointPenalty:
            try await deductTrustPoints(userId: failedUserId, amount: Self.trustPointsPerSwap)

        case .eligibilityLock:
            try await lockSwapEligibility(userId: failedUserId)

        case .creditStake:
            // Forfeit any staked credits
            if stakedCredits > 0 {
                try await forfeitCredits(userId: failedUserId, amount: stakedCredits)
            }
        }

        // Log event
        try await SwapEventService.shared.logSystemEvent(
            swapId: swapId,
            type: .collateralForfeited,
            payload: .collateral(type: fallbackType.rawValue, amount: Self.trustPointsPerSwap)
        )
    }
}

// MARK: - Errors

enum CollateralError: LocalizedError {
    case notAuthenticated
    case profileNotFound
    case swapNotFound
    case insufficientTrustPoints
    case insufficientCredits

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .profileNotFound:
            return "Profile not found"
        case .swapNotFound:
            return "Swap not found"
        case .insufficientTrustPoints:
            return "Not enough trust points available"
        case .insufficientCredits:
            return "Not enough credits to stake"
        }
    }
}

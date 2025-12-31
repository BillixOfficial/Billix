//
//  SwapBackProtectionService.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Service for managing Swap-Back Protection (financial hardship safety net)
//

import Foundation
import Supabase
import Combine

// MARK: - Swap-Back Protection Service

@MainActor
class SwapBackProtectionService: ObservableObject {

    // MARK: - Singleton
    static let shared = SwapBackProtectionService()

    // MARK: - Published Properties
    @Published var currentPlan: ProtectionPlan?
    @Published var claims: [ProtectionClaim] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var subscriptionService: SubscriptionService {
        SubscriptionService.shared
    }

    private var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    // MARK: - Initialization

    private init() {
        Task {
            await loadProtectionStatus()
        }
    }

    // MARK: - Computed Properties

    /// Current protection tier based on subscription
    var currentTier: ProtectionTier? {
        switch subscriptionService.currentTier {
        case .premium: return .premium
        case .pro: return .pro
        case .basic: return .basic
        case .free: return nil
        }
    }

    /// Whether user has active protection
    var hasActiveProtection: Bool {
        currentPlan?.isActive ?? false
    }

    /// Whether user can activate protection
    var canActivateProtection: Bool {
        currentTier != nil && currentPlan == nil
    }

    /// Current protection summary
    var summary: ProtectionSummary {
        ProtectionSummary(
            plan: currentPlan,
            recentClaims: claims,
            tier: currentTier
        )
    }

    // MARK: - Load Protection Status

    /// Loads the current protection plan and claims
    func loadProtectionStatus() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // Load active plan
            let plans: [ProtectionPlan] = try await supabase
                .from("protection_plans")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("status", value: ProtectionStatus.active.rawValue)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            currentPlan = plans.first

            // Check expiration
            if let plan = currentPlan, plan.isExpired {
                await expirePlan(plan.id)
            }

            // Load claims
            let userClaims: [ProtectionClaim] = try await supabase
                .from("protection_claims")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value

            claims = userClaims

        } catch {
            self.error = "Failed to load protection status: \(error.localizedDescription)"
            print("Failed to load protection status: \(error)")
        }
    }

    // MARK: - Activate Protection

    /// Activates protection for the user based on their subscription tier
    func activateProtection() async throws -> ProtectionPlan {
        guard let userId = currentUserId else {
            throw ProtectionError.notAuthenticated
        }

        guard let tier = currentTier else {
            throw ProtectionError.noEligibleTier
        }

        // Check if already has active plan
        if hasActiveProtection {
            throw ProtectionError.alreadyActive
        }

        let now = Date()
        let expiresAt = Calendar.current.date(byAdding: .month, value: 1, to: now)!
        let formatter = ISO8601DateFormatter()

        let insert = ProtectionPlanInsert(
            userId: userId.uuidString,
            status: ProtectionStatus.active.rawValue,
            activatedAt: formatter.string(from: now),
            expiresAt: formatter.string(from: expiresAt),
            swapsCovered: tier.monthlySwapsCovered,
            maxCoverageAmount: tier.maxCoveragePerSwap * Decimal(tier.monthlySwapsCovered),
            usedCoverageAmount: 0,
            claimsAllowed: tier.claimsPerYear,
            claimsUsed: 0
        )

        let plan: ProtectionPlan = try await supabase
            .from("protection_plans")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        currentPlan = plan
        return plan
    }

    /// Renews an expired or expiring plan
    func renewProtection() async throws -> ProtectionPlan {
        guard currentUserId != nil else {
            throw ProtectionError.notAuthenticated
        }

        guard currentTier != nil else {
            throw ProtectionError.noEligibleTier
        }

        // Expire old plan if exists
        if let oldPlan = currentPlan {
            await expirePlan(oldPlan.id)
        }

        return try await activateProtection()
    }

    // MARK: - File Claim

    /// Files a protection claim
    func fileClaim(_ request: ClaimRequest) async throws -> ProtectionClaim {
        guard let userId = currentUserId else {
            throw ProtectionError.notAuthenticated
        }

        guard let plan = currentPlan, plan.canMakeClaim else {
            throw ProtectionError.noActivePlan
        }

        guard request.isValid else {
            throw ProtectionError.invalidClaim
        }

        // Validate claim amount against remaining coverage
        if request.claimAmount > plan.remainingCoverage {
            throw ProtectionError.exceedsCoverage
        }

        let insert = ProtectionClaimInsert(
            planId: request.planId.uuidString,
            userId: userId.uuidString,
            swapId: request.swapId?.uuidString,
            reason: request.reason.rawValue,
            reasonDetails: request.reasonDetails,
            status: ClaimStatus.submitted.rawValue,
            claimAmount: request.claimAmount,
            documentationUrl: request.documentationUrl
        )

        let claim: ProtectionClaim = try await supabase
            .from("protection_claims")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        claims.insert(claim, at: 0)

        return claim
    }

    /// Uploads documentation for a claim
    func uploadClaimDocumentation(_ claimId: UUID, documentationUrl: String) async throws {
        try await supabase
            .from("protection_claims")
            .update(["documentation_url": documentationUrl])
            .eq("id", value: claimId.uuidString)
            .execute()

        await loadProtectionStatus()
    }

    // MARK: - Admin Functions (would be called by backend)

    /// Reviews a claim (admin function)
    func reviewClaim(_ claimId: UUID, approved: Bool, approvedAmount: Decimal?, notes: String?) async throws {
        let newStatus = approved ? ClaimStatus.approved : ClaimStatus.denied
        let formatter = ISO8601DateFormatter()

        let update = ClaimReviewUpdate(
            status: newStatus.rawValue,
            reviewedAt: formatter.string(from: Date()),
            reviewNotes: notes,
            approvedAmount: approved ? approvedAmount : nil
        )

        try await supabase
            .from("protection_claims")
            .update(update)
            .eq("id", value: claimId.uuidString)
            .execute()

        // Update plan used coverage
        if approved, let amount = approvedAmount, let plan = currentPlan {
            let planUpdate = ProtectionPlanUsageUpdate(
                usedCoverageAmount: plan.usedCoverageAmount + amount,
                claimsUsed: plan.claimsUsed + 1
            )
            try await supabase
                .from("protection_plans")
                .update(planUpdate)
                .eq("id", value: plan.id.uuidString)
                .execute()
        }

        await loadProtectionStatus()
    }

    /// Processes an approved claim (marks as fulfilled)
    func processClaim(_ claimId: UUID) async throws {
        let formatter = ISO8601DateFormatter()

        try await supabase
            .from("protection_claims")
            .update([
                "status": ClaimStatus.processed.rawValue,
                "processed_at": formatter.string(from: Date())
            ])
            .eq("id", value: claimId.uuidString)
            .execute()

        await loadProtectionStatus()
    }

    // MARK: - Cancel Protection

    /// Cancels the current protection plan
    func cancelProtection() async throws {
        guard let plan = currentPlan else {
            throw ProtectionError.noActivePlan
        }

        try await supabase
            .from("protection_plans")
            .update(["status": ProtectionStatus.cancelled.rawValue])
            .eq("id", value: plan.id.uuidString)
            .execute()

        currentPlan = nil
    }

    // MARK: - Expire Plan

    /// Expires a plan
    private func expirePlan(_ planId: UUID) async {
        do {
            try await supabase
                .from("protection_plans")
                .update(["status": ProtectionStatus.expired.rawValue])
                .eq("id", value: planId.uuidString)
                .execute()

            if currentPlan?.id == planId {
                currentPlan = nil
            }
        } catch {
            print("Failed to expire plan: \(error)")
        }
    }

    // MARK: - Eligibility Check

    /// Checks if a swap is eligible for protection claim
    func isSwapEligible(_ swapId: UUID) async -> Bool {
        guard hasActiveProtection else { return false }

        // In production, would check:
        // - Swap was completed during protection period
        // - Waiting period has passed
        // - Swap amount within coverage limits

        return true
    }

    /// Gets eligible swaps for claiming
    func getEligibleSwaps() async -> [UUID] {
        guard let plan = currentPlan, plan.isActive else { return [] }

        // In production, would query swaps completed during protection period
        // that haven't been claimed yet

        return []
    }

    // MARK: - Statistics

    /// Gets claim statistics
    func getClaimStatistics() -> (approved: Int, denied: Int, pending: Int) {
        let approved = claims.filter { $0.claimStatus == .approved || $0.claimStatus == .processed }.count
        let denied = claims.filter { $0.claimStatus == .denied }.count
        let pending = claims.filter { $0.claimStatus == .submitted || $0.claimStatus == .underReview }.count

        return (approved, denied, pending)
    }

    // MARK: - Reset

    func reset() {
        currentPlan = nil
        claims = []
        error = nil
    }
}

// MARK: - Protection Errors

enum ProtectionError: LocalizedError {
    case notAuthenticated
    case noEligibleTier
    case alreadyActive
    case noActivePlan
    case invalidClaim
    case exceedsCoverage
    case claimNotFound
    case swapNotEligible

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .noEligibleTier:
            return "Upgrade to Basic or higher to access Swap-Back Protection"
        case .alreadyActive:
            return "You already have active protection"
        case .noActivePlan:
            return "No active protection plan found"
        case .invalidClaim:
            return "Invalid claim request"
        case .exceedsCoverage:
            return "Claim amount exceeds remaining coverage"
        case .claimNotFound:
            return "Claim not found"
        case .swapNotEligible:
            return "This swap is not eligible for protection"
        }
    }
}

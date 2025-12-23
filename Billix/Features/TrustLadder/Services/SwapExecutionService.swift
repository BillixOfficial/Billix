//
//  SwapExecutionService.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Service for managing swap execution lifecycle
//

import Foundation
import Supabase

// MARK: - Errors

enum SwapExecutionError: LocalizedError {
    case notAuthenticated
    case swapNotFound
    case notYourSwap
    case invalidStatus
    case feesNotPaid
    case screenshotRequired
    case verificationFailed
    case swapExpired
    case alreadyCompleted
    case partnerGhosted

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .swapNotFound:
            return "Swap not found"
        case .notYourSwap:
            return "You are not part of this swap"
        case .invalidStatus:
            return "Invalid swap status for this action"
        case .feesNotPaid:
            return "Both parties must pay the coordination fee first"
        case .screenshotRequired:
            return "Please upload a payment screenshot"
        case .verificationFailed:
            return "Screenshot verification failed"
        case .swapExpired:
            return "This swap has expired"
        case .alreadyCompleted:
            return "This swap is already completed"
        case .partnerGhosted:
            return "Your partner did not complete their payment"
        }
    }
}

// MARK: - Update Structs

private struct FeeUpdateUserA: Codable {
    let userAFeePaid: Bool
    let userAFeeTransactionId: String
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case userAFeePaid = "user_a_fee_paid"
        case userAFeeTransactionId = "user_a_fee_transaction_id"
        case status
        case updatedAt = "updated_at"
    }
}

private struct FeeUpdateUserB: Codable {
    let userBFeePaid: Bool
    let userBFeeTransactionId: String
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case userBFeePaid = "user_b_fee_paid"
        case userBFeeTransactionId = "user_b_fee_transaction_id"
        case status
        case updatedAt = "updated_at"
    }
}

private struct ScreenshotUpdateUserA: Codable {
    let userAScreenshotUrl: String
    let userAScreenshotVerified: Bool
    let userAVerificationConfidence: Double
    let userACompletedAt: String
    let status: String
    let updatedAt: String
    let completedAt: String?
    let trustPointsAwarded: Int?
    let disputeReason: String?

    enum CodingKeys: String, CodingKey {
        case userAScreenshotUrl = "user_a_screenshot_url"
        case userAScreenshotVerified = "user_a_screenshot_verified"
        case userAVerificationConfidence = "user_a_verification_confidence"
        case userACompletedAt = "user_a_completed_at"
        case status
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case trustPointsAwarded = "trust_points_awarded"
        case disputeReason = "dispute_reason"
    }
}

private struct ScreenshotUpdateUserB: Codable {
    let userBScreenshotUrl: String
    let userBScreenshotVerified: Bool
    let userBVerificationConfidence: Double
    let userBCompletedAt: String
    let status: String
    let updatedAt: String
    let completedAt: String?
    let trustPointsAwarded: Int?
    let disputeReason: String?

    enum CodingKeys: String, CodingKey {
        case userBScreenshotUrl = "user_b_screenshot_url"
        case userBScreenshotVerified = "user_b_screenshot_verified"
        case userBVerificationConfidence = "user_b_verification_confidence"
        case userBCompletedAt = "user_b_completed_at"
        case status
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case trustPointsAwarded = "trust_points_awarded"
        case disputeReason = "dispute_reason"
    }
}

private struct RatingUpdate: Codable {
    let userARatingGiven: Int?
    let userBRatingGiven: Int?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case userARatingGiven = "user_a_rating_given"
        case userBRatingGiven = "user_b_rating_given"
        case updatedAt = "updated_at"
    }
}

private struct GhostUpdate: Codable {
    let status: String
    let disputeReason: String
    let ghostUserId: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case disputeReason = "dispute_reason"
        case ghostUserId = "ghost_user_id"
        case updatedAt = "updated_at"
    }
}

private struct CancelUpdate: Codable {
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case updatedAt = "updated_at"
    }
}

private struct ScreenshotInsert: Codable {
    let swapId: String
    let userId: String
    let imageUrl: String
    let ocrRawText: String
    let ocrExtractedAmount: Double?
    let ocrExtractedProvider: String?
    let ocrConfidence: Double
    let verificationStatus: String

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case userId = "user_id"
        case imageUrl = "image_url"
        case ocrRawText = "ocr_raw_text"
        case ocrExtractedAmount = "ocr_extracted_amount"
        case ocrExtractedProvider = "ocr_extracted_provider"
        case ocrConfidence = "ocr_confidence"
        case verificationStatus = "verification_status"
    }
}

private struct DisputeInsert: Codable {
    let swapId: String
    let reportedBy: String
    let reportedUser: String
    let reason: String
    let description: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case reportedBy = "reported_by"
        case reportedUser = "reported_user"
        case reason
        case description
        case status
    }
}

// MARK: - Swap Execution Service

@MainActor
class SwapExecutionService: ObservableObject {

    // MARK: - Singleton
    static let shared = SwapExecutionService()

    // MARK: - Published Properties
    @Published var activeSwaps: [Swap] = []
    @Published var completedSwaps: [Swap] = []
    @Published var currentSwap: Swap?
    @Published var isLoading = false
    @Published var error: SwapExecutionError?

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private let trustService = TrustLadderService.shared

    // MARK: - Initialization
    private init() {}

    // MARK: - Fetch Swaps

    /// Fetches all swaps for the current user
    func fetchSwaps() async throws {
        guard let session = try? await supabase.auth.session else {
            throw SwapExecutionError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let userId = session.user.id.uuidString

        // Fetch active swaps
        let active: [Swap] = try await supabase
            .from("swaps")
            .select()
            .or("user_a_id.eq.\(userId),user_b_id.eq.\(userId)")
            .in("status", values: ["pending", "matched", "fee_pending", "fee_paid", "leg_a_complete", "leg_b_complete", "disputed"])
            .order("created_at", ascending: false)
            .execute()
            .value

        self.activeSwaps = active

        // Fetch completed swaps (last 20)
        let completed: [Swap] = try await supabase
            .from("swaps")
            .select()
            .or("user_a_id.eq.\(userId),user_b_id.eq.\(userId)")
            .in("status", values: ["completed", "failed", "cancelled", "refunded"])
            .order("completed_at", ascending: false)
            .limit(20)
            .execute()
            .value

        self.completedSwaps = completed
    }

    /// Fetches a specific swap by ID
    func fetchSwap(id: UUID) async throws -> Swap {
        guard let session = try? await supabase.auth.session else {
            throw SwapExecutionError.notAuthenticated
        }

        let swap: Swap = try await supabase
            .from("swaps")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        // Verify user is part of this swap
        guard swap.userAId == session.user.id || swap.userBId == session.user.id else {
            throw SwapExecutionError.notYourSwap
        }

        self.currentSwap = swap
        return swap
    }

    // MARK: - Record Fee Payment

    /// Records that a user has paid the coordination fee
    func recordFeePaid(swapId: UUID, transactionId: String) async throws -> Swap {
        guard let session = try? await supabase.auth.session else {
            throw SwapExecutionError.notAuthenticated
        }

        let swap = try await fetchSwap(id: swapId)

        // Determine which user paid
        let isUserA = swap.userAId == session.user.id
        let now = ISO8601DateFormatter().string(from: Date())

        // Check if both fees are now paid
        let bothPaid: Bool
        if isUserA {
            bothPaid = swap.userBFeePaid
        } else {
            bothPaid = swap.userAFeePaid
        }

        let newStatus = bothPaid ? "fee_paid" : "fee_pending"

        if isUserA {
            let update = FeeUpdateUserA(
                userAFeePaid: true,
                userAFeeTransactionId: transactionId,
                status: newStatus,
                updatedAt: now
            )
            try await supabase
                .from("swaps")
                .update(update)
                .eq("id", value: swapId.uuidString)
                .execute()
        } else {
            let update = FeeUpdateUserB(
                userBFeePaid: true,
                userBFeeTransactionId: transactionId,
                status: newStatus,
                updatedAt: now
            )
            try await supabase
                .from("swaps")
                .update(update)
                .eq("id", value: swapId.uuidString)
                .execute()
        }

        return try await fetchSwap(id: swapId)
    }

    // MARK: - Submit Payment Proof

    /// Submits a payment screenshot for verification
    func submitPaymentProof(
        swapId: UUID,
        screenshotUrl: String,
        verificationResult: ScreenshotVerificationResult
    ) async throws -> Swap {
        guard let session = try? await supabase.auth.session else {
            throw SwapExecutionError.notAuthenticated
        }

        let swap = try await fetchSwap(id: swapId)

        // Check swap status
        guard swap.swapStatus == .feePaid || swap.swapStatus == .legAComplete || swap.swapStatus == .legBComplete else {
            throw SwapExecutionError.invalidStatus
        }

        // Determine which user is submitting
        let isUserA = swap.userAId == session.user.id
        let now = ISO8601DateFormatter().string(from: Date())

        // Save screenshot to database
        let screenshotInsert = ScreenshotInsert(
            swapId: swapId.uuidString,
            userId: session.user.id.uuidString,
            imageUrl: screenshotUrl,
            ocrRawText: verificationResult.rawText,
            ocrExtractedAmount: verificationResult.extractedAmount,
            ocrExtractedProvider: verificationResult.extractedProvider,
            ocrConfidence: verificationResult.confidence,
            verificationStatus: verificationResult.status.rawValue
        )

        try await supabase
            .from("swap_screenshots")
            .insert(screenshotInsert)
            .execute()

        // Determine new status based on leg completion
        let newStatus: String
        let completedAt: String?
        let trustPoints: Int?
        let disputeReason: String?

        if isUserA && swap.userBCompletedAt == nil {
            newStatus = "leg_a_complete"
            completedAt = nil
            trustPoints = nil
            disputeReason = nil
        } else if !isUserA && swap.userACompletedAt == nil {
            newStatus = "leg_b_complete"
            completedAt = nil
            trustPoints = nil
            disputeReason = nil
        } else {
            // Both legs complete - check verification
            if verificationResult.isVerified {
                newStatus = "completed"
                completedAt = now
                trustPoints = 50
                disputeReason = nil
            } else {
                newStatus = "disputed"
                completedAt = nil
                trustPoints = nil
                disputeReason = "screenshot_verification_failed"
            }
        }

        // Update swap with screenshot info
        if isUserA {
            let update = ScreenshotUpdateUserA(
                userAScreenshotUrl: screenshotUrl,
                userAScreenshotVerified: verificationResult.isVerified,
                userAVerificationConfidence: verificationResult.confidence,
                userACompletedAt: now,
                status: newStatus,
                updatedAt: now,
                completedAt: completedAt,
                trustPointsAwarded: trustPoints,
                disputeReason: disputeReason
            )
            try await supabase
                .from("swaps")
                .update(update)
                .eq("id", value: swapId.uuidString)
                .execute()
        } else {
            let update = ScreenshotUpdateUserB(
                userBScreenshotUrl: screenshotUrl,
                userBScreenshotVerified: verificationResult.isVerified,
                userBVerificationConfidence: verificationResult.confidence,
                userBCompletedAt: now,
                status: newStatus,
                updatedAt: now,
                completedAt: completedAt,
                trustPointsAwarded: trustPoints,
                disputeReason: disputeReason
            )
            try await supabase
                .from("swaps")
                .update(update)
                .eq("id", value: swapId.uuidString)
                .execute()
        }

        let updatedSwap = try await fetchSwap(id: swapId)

        // Award trust points if completed
        if updatedSwap.swapStatus == .completed {
            try? await trustService.recordSuccessfulSwap(swapId: swapId, trustPointsEarned: 50)
        }

        return updatedSwap
    }

    // MARK: - Rate Partner

    /// Rate the swap partner after completion
    func ratePartner(swapId: UUID, rating: Int) async throws {
        guard let session = try? await supabase.auth.session else {
            throw SwapExecutionError.notAuthenticated
        }

        guard rating >= 1 && rating <= 5 else { return }

        let swap = try await fetchSwap(id: swapId)

        guard swap.swapStatus == .completed else {
            throw SwapExecutionError.invalidStatus
        }

        let isUserA = swap.userAId == session.user.id
        let now = ISO8601DateFormatter().string(from: Date())

        let update = RatingUpdate(
            userARatingGiven: isUserA ? rating : nil,
            userBRatingGiven: isUserA ? nil : rating,
            updatedAt: now
        )

        try await supabase
            .from("swaps")
            .update(update)
            .eq("id", value: swapId.uuidString)
            .execute()
    }

    // MARK: - Report Ghost

    /// Reports that a partner has ghosted (didn't complete their payment)
    func reportGhost(swapId: UUID) async throws {
        guard let session = try? await supabase.auth.session else {
            throw SwapExecutionError.notAuthenticated
        }

        let swap = try await fetchSwap(id: swapId)

        // Check if swap is in a state where ghosting can occur
        guard swap.swapStatus == .feePaid ||
              swap.swapStatus == .legAComplete ||
              swap.swapStatus == .legBComplete else {
            throw SwapExecutionError.invalidStatus
        }

        // Check if deadline has passed
        guard swap.isExpired else {
            throw SwapExecutionError.invalidStatus
        }

        let isUserA = swap.userAId == session.user.id
        let ghosterId = isUserA ? swap.userBId : swap.userAId
        let now = ISO8601DateFormatter().string(from: Date())

        // Create dispute record
        let dispute = DisputeInsert(
            swapId: swapId.uuidString,
            reportedBy: session.user.id.uuidString,
            reportedUser: ghosterId?.uuidString ?? "",
            reason: "ghost",
            description: "Partner did not complete payment before deadline",
            status: "open"
        )

        try await supabase
            .from("swap_disputes")
            .insert(dispute)
            .execute()

        // Update swap status
        let update = GhostUpdate(
            status: "failed",
            disputeReason: "ghost",
            ghostUserId: ghosterId?.uuidString ?? "",
            updatedAt: now
        )

        try await supabase
            .from("swaps")
            .update(update)
            .eq("id", value: swapId.uuidString)
            .execute()

        // Refresh swaps
        try await fetchSwaps()
    }

    // MARK: - Cancel Swap

    /// Cancels a swap (only available before fees are paid)
    func cancelSwap(swapId: UUID) async throws {
        guard (try? await supabase.auth.session) != nil else {
            throw SwapExecutionError.notAuthenticated
        }

        let swap = try await fetchSwap(id: swapId)

        // Can only cancel before fees are paid
        guard swap.swapStatus == .pending || swap.swapStatus == .matched else {
            throw SwapExecutionError.invalidStatus
        }

        let update = CancelUpdate(
            status: "cancelled",
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("swaps")
            .update(update)
            .eq("id", value: swapId.uuidString)
            .execute()

        // Refresh swaps
        try await fetchSwaps()
    }

    // MARK: - Check Expired Swaps

    /// Checks for and handles expired swaps
    func checkExpiredSwaps() async throws {
        for swap in activeSwaps {
            if swap.isExpired && swap.swapStatus.isActive {
                // Handle expiration based on status
                switch swap.swapStatus {
                case .feePaid, .legAComplete, .legBComplete:
                    // Someone ghosted - auto-report
                    try? await reportGhost(swapId: swap.id)
                case .matched, .feePending:
                    // Fees weren't paid - auto-cancel
                    try? await cancelSwap(swapId: swap.id)
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Screenshot Verification Result

struct ScreenshotVerificationResult {
    let rawText: String
    let extractedAmount: Double?
    let extractedProvider: String?
    let extractedDate: Date?
    let confidence: Double
    let status: ScreenshotVerificationStatus
    let flags: [VerificationFlag]

    var isVerified: Bool {
        status == .autoVerified || status == .verified
    }

    enum VerificationFlag {
        case amountMismatch(expected: Double, found: Double)
        case providerNotFound
        case dateTooOld
        case lowConfidence
        case possibleEdit
    }
}

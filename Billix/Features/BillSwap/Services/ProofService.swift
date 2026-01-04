//
//  ProofService.swift
//  Billix
//
//  Bill Swap Proof Service
//

import Foundation
import Supabase

// MARK: - Private Codable Payloads

private struct SubmitProofPayload: Codable {
    let swapId: String
    let submitterUserId: String
    let proofType: String
    let proofUrl: String
    let status: String
    let reviewDeadline: String
    let resubmissionCount: Int
    var submitterNotes: String?

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case submitterUserId = "submitter_user_id"
        case proofType = "proof_type"
        case proofUrl = "proof_url"
        case status
        case reviewDeadline = "review_deadline"
        case resubmissionCount = "resubmission_count"
        case submitterNotes = "submitter_notes"
    }
}

private struct AcceptProofPayload: Codable {
    let status: String
    let reviewerUserId: String
    let reviewedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case reviewerUserId = "reviewer_user_id"
        case reviewedAt = "reviewed_at"
        case updatedAt = "updated_at"
    }
}

private struct RejectProofPayload: Codable {
    let status: String
    let reviewerUserId: String
    let reviewedAt: String
    let rejectionReason: String
    let updatedAt: String
    var reviewerNotes: String?

    enum CodingKeys: String, CodingKey {
        case status
        case reviewerUserId = "reviewer_user_id"
        case reviewedAt = "reviewed_at"
        case rejectionReason = "rejection_reason"
        case updatedAt = "updated_at"
        case reviewerNotes = "reviewer_notes"
    }
}

private struct AutoAcceptProofPayload: Codable {
    let status: String
    let reviewedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case reviewedAt = "reviewed_at"
        case updatedAt = "updated_at"
    }
}

@MainActor
class ProofService: ObservableObject {
    static let shared = ProofService()

    private let supabase = SupabaseService.shared.client
    private let trustService = TrustService.shared
    private let pointsService = PointsService.shared

    @Published var proofs: [BillSwapProof] = []
    @Published var isLoading = false
    @Published var error: Error?

    private init() {}

    // MARK: - Fetch Proofs

    /// Fetch all proofs for a swap
    func fetchProofsForSwap(_ swapId: UUID) async throws -> [BillSwapProof] {
        let proofs: [BillSwapProof] = try await supabase
            .from("bill_swap_proofs")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        self.proofs = proofs
        return proofs
    }

    /// Fetch a single proof by ID
    func fetchProof(_ proofId: UUID) async throws -> BillSwapProof {
        let proof: BillSwapProof = try await supabase
            .from("bill_swap_proofs")
            .select()
            .eq("id", value: proofId.uuidString)
            .single()
            .execute()
            .value

        return proof
    }

    // MARK: - Submit Proof

    /// Submit payment proof
    func submitProof(_ request: SubmitProofRequest) async throws -> BillSwapProof {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SwapProofError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Check resubmission limit
        let existingProofs = try await fetchProofsForSwap(request.swapId)
        let userProofs = existingProofs.filter { $0.submitterUserId == userId }

        if userProofs.count >= ProofConstants.maxResubmissions {
            throw SwapProofError.maxResubmissionsReached
        }

        // Calculate review deadline (12 hours)
        let reviewDeadline = Calendar.current.date(byAdding: .hour, value: 12, to: Date())!

        var payload = SubmitProofPayload(
            swapId: request.swapId.uuidString,
            submitterUserId: userId.uuidString,
            proofType: request.proofType.rawValue,
            proofUrl: request.proofUrl,
            status: SwapProofStatus.pending.rawValue,
            reviewDeadline: ISO8601DateFormatter().string(from: reviewDeadline),
            resubmissionCount: userProofs.count,
            submitterNotes: request.notes
        )

        let response: [BillSwapProof] = try await supabase
            .from("bill_swap_proofs")
            .insert(payload)
            .select()
            .execute()
            .value

        guard let proof = response.first else {
            throw SwapProofError.submitFailed
        }

        proofs.insert(proof, at: 0)
        return proof
    }

    // MARK: - Upload Proof Image

    /// Upload proof image to storage
    func uploadProofImage(swapId: UUID, imageData: Data) async throws -> String {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SwapProofError.notAuthenticated
        }

        let fileName = "\(userId.uuidString)/\(swapId.uuidString)/\(UUID().uuidString).jpg"

        try await supabase.storage
            .from("swap-proofs")
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        // Get public URL
        let publicURL = try supabase.storage
            .from("swap-proofs")
            .getPublicURL(path: fileName)

        return publicURL.absoluteString
    }

    // MARK: - Review Proof

    /// Accept a proof
    func acceptProof(_ proofId: UUID) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SwapProofError.notAuthenticated
        }

        let now = ISO8601DateFormatter().string(from: Date())
        let payload = AcceptProofPayload(
            status: SwapProofStatus.accepted.rawValue,
            reviewerUserId: userId.uuidString,
            reviewedAt: now,
            updatedAt: now
        )

        try await supabase
            .from("bill_swap_proofs")
            .update(payload)
            .eq("id", value: proofId.uuidString)
            .execute()

        // Check if all proofs for the swap are accepted
        let proof = try await fetchProof(proofId)
        try await checkSwapCompletion(swapId: proof.swapId)
    }

    /// Reject a proof with reason
    func rejectProof(_ proofId: UUID, reason: SwapProofRejectionReason, notes: String?) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SwapProofError.notAuthenticated
        }

        let now = ISO8601DateFormatter().string(from: Date())
        var payload = RejectProofPayload(
            status: SwapProofStatus.rejected.rawValue,
            reviewerUserId: userId.uuidString,
            reviewedAt: now,
            rejectionReason: reason.rawValue,
            updatedAt: now,
            reviewerNotes: notes
        )

        try await supabase
            .from("bill_swap_proofs")
            .update(payload)
            .eq("id", value: proofId.uuidString)
            .execute()
    }

    // MARK: - Check Swap Completion

    /// Check if swap should be completed (all required proofs accepted)
    private func checkSwapCompletion(swapId: UUID) async throws {
        // Fetch swap to check type
        let swap: BillSwap = try await supabase
            .from("bill_swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .single()
            .execute()
            .value

        let allProofs = try await fetchProofsForSwap(swapId)
        let acceptedProofs = allProofs.filter { $0.status == .accepted }

        // For two-sided swaps, need 2 accepted proofs (one from each party)
        // For one-sided, need 1 accepted proof from the helper
        let requiredProofs = swap.swapType == .twoSided ? 2 : 1

        if acceptedProofs.count >= requiredProofs {
            // Check that proofs are from different users for two-sided
            if swap.swapType == .twoSided {
                let uniqueSubmitters = Set(acceptedProofs.map { $0.submitterUserId })
                if uniqueSubmitters.count >= 2 {
                    // Complete the swap
                    try await BillSwapService.shared.completeSwap(swapId)
                }
            } else {
                // One-sided: just need one accepted proof
                try await BillSwapService.shared.completeSwap(swapId)
            }
        }
    }

    // MARK: - Auto-Accept Deadline Check

    /// Check for proofs past review deadline and auto-accept them
    func processExpiredProofReviews() async throws {
        let now = ISO8601DateFormatter().string(from: Date())

        // Find pending proofs past deadline
        let expiredProofs: [BillSwapProof] = try await supabase
            .from("bill_swap_proofs")
            .select()
            .eq("status", value: SwapProofStatus.pending.rawValue)
            .lt("review_deadline", value: now)
            .execute()
            .value

        for proof in expiredProofs {
            // Auto-accept expired proofs
            let payload = AutoAcceptProofPayload(
                status: SwapProofStatus.autoAccepted.rawValue,
                reviewedAt: now,
                updatedAt: now
            )
            try await supabase
                .from("bill_swap_proofs")
                .update(payload)
                .eq("id", value: proof.id.uuidString)
                .execute()

            // Check if swap should complete
            try await checkSwapCompletion(swapId: proof.swapId)
        }
    }

    // MARK: - Pending Proof Count

    /// Get count of proofs pending user review
    func getPendingReviewCount(forUserId userId: UUID) async throws -> Int {
        // Find swaps where user is a participant
        let swaps: [BillSwap] = try await supabase
            .from("bill_swaps")
            .select()
            .or("initiator_user_id.eq.\(userId.uuidString),counterparty_user_id.eq.\(userId.uuidString)")
            .eq("status", value: BillSwapStatus.awaitingProof.rawValue)
            .execute()
            .value

        var pendingCount = 0

        for swap in swaps {
            // Get proofs submitted by the OTHER user (not this user)
            let proofs: [BillSwapProof] = try await supabase
                .from("bill_swap_proofs")
                .select()
                .eq("swap_id", value: swap.id.uuidString)
                .eq("status", value: SwapProofStatus.pending.rawValue)
                .neq("submitter_user_id", value: userId.uuidString)
                .execute()
                .value

            pendingCount += proofs.count
        }

        return pendingCount
    }
}

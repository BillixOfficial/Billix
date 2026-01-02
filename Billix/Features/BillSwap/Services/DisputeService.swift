//
//  DisputeService.swift
//  Billix
//
//  Bill Swap Dispute Service
//

import Foundation
import Supabase

// MARK: - Private Codable Payloads

private struct FileDisputePayload: Codable {
    let swapId: String
    let reporterUserId: String
    let reportedUserId: String
    let reason: String
    let status: String
    let filingDeadline: String
    let description: String?
    let evidenceUrls: [String]?

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case reporterUserId = "reporter_user_id"
        case reportedUserId = "reported_user_id"
        case reason
        case status
        case filingDeadline = "filing_deadline"
        case description
        case evidenceUrls = "evidence_urls"
    }
}

private struct UpdateEvidencePayload: Codable {
    let evidenceUrls: [String]
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case evidenceUrls = "evidence_urls"
        case updatedAt = "updated_at"
    }
}

private struct RespondToDisputePayload: Codable {
    let description: String
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case description
        case status
        case updatedAt = "updated_at"
    }
}

private struct ResolveDisputePayload: Codable {
    let status: String
    let resolution: String
    let atFaultUserId: String?
    let resolvedByAdminId: String
    let resolvedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case resolution
        case atFaultUserId = "at_fault_user_id"
        case resolvedByAdminId = "resolved_by_admin_id"
        case resolvedAt = "resolved_at"
        case updatedAt = "updated_at"
    }
}

private struct DismissDisputePayload: Codable {
    let status: String
    let resolution: String
    let resolvedByAdminId: String
    let resolvedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case resolution
        case resolvedByAdminId = "resolved_by_admin_id"
        case resolvedAt = "resolved_at"
        case updatedAt = "updated_at"
    }
}

private struct UpdateSwapStatusPayload: Codable {
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case updatedAt = "updated_at"
    }
}

@MainActor
class DisputeService: ObservableObject {
    static let shared = DisputeService()

    private let supabase = SupabaseService.shared.client
    private let trustService = TrustService.shared
    private let pointsService = PointsService.shared

    @Published var activeDisputes: [SwapDispute] = []
    @Published var isLoading = false
    @Published var error: Error?

    private init() {}

    // MARK: - Fetch Disputes

    /// Fetch all disputes involving current user
    func fetchMyDisputes() async throws -> [SwapDispute] {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SwapDisputeError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let disputes: [SwapDispute] = try await supabase
            .from("bill_swap_disputes")
            .select()
            .or("reporter_user_id.eq.\(userId.uuidString),reported_user_id.eq.\(userId.uuidString)")
            .order("created_at", ascending: false)
            .execute()
            .value

        activeDisputes = disputes.filter { $0.status.isActive }
        return disputes
    }

    /// Fetch dispute by ID
    func fetchDispute(_ disputeId: UUID) async throws -> SwapDispute {
        let dispute: SwapDispute = try await supabase
            .from("bill_swap_disputes")
            .select()
            .eq("id", value: disputeId.uuidString)
            .single()
            .execute()
            .value

        return dispute
    }

    /// Fetch disputes for a specific swap
    func fetchDisputesForSwap(_ swapId: UUID) async throws -> [SwapDispute] {
        let disputes: [SwapDispute] = try await supabase
            .from("bill_swap_disputes")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return disputes
    }

    // MARK: - Check Dispute Eligibility

    /// Check if user can file a dispute for a swap
    func canFileDispute(for swap: BillSwap) -> Result<Void, SwapDisputeError> {
        guard let userId = SupabaseService.shared.currentUserId else {
            return .failure(.notAuthenticated)
        }

        // Must be a participant
        guard swap.initiatorUserId == userId || swap.counterpartyUserId == userId else {
            return .failure(.cannotDisputeOwnSwap)
        }

        // Check valid statuses for dispute
        let disputeableStatuses: [BillSwapStatus] = [.awaitingProof, .failed]
        guard disputeableStatuses.contains(swap.status) else {
            return .failure(.disputeWindowExpired)
        }

        return .success(())
    }

    /// Check if dispute window is still open for a proof rejection
    func isDisputeWindowOpen(proofRejectedAt: Date) -> Bool {
        let deadline = Calendar.current.date(
            byAdding: .hour,
            value: DisputeConstants.filingWindowHours,
            to: proofRejectedAt
        )!
        return Date() < deadline
    }

    // MARK: - File Dispute

    /// File a new dispute
    func fileDispute(_ request: FileDisputeRequest) async throws -> SwapDispute {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SwapDisputeError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Verify swap exists and user can dispute
        let swap: BillSwap = try await supabase
            .from("bill_swaps")
            .select()
            .eq("id", value: request.swapId.uuidString)
            .single()
            .execute()
            .value

        let canDispute = canFileDispute(for: swap)
        if case .failure(let error) = canDispute {
            throw error
        }

        // Check for existing dispute
        let existingDisputes = try await fetchDisputesForSwap(request.swapId)
        if existingDisputes.contains(where: { $0.reporterUserId == userId && $0.status.isActive }) {
            throw SwapDisputeError.alreadyDisputed
        }

        // Calculate filing deadline (24h from now for response)
        let filingDeadline = Calendar.current.date(
            byAdding: .hour,
            value: DisputeConstants.expectedResolutionHours,
            to: Date()
        )!

        let disputePayload = FileDisputePayload(
            swapId: request.swapId.uuidString,
            reporterUserId: userId.uuidString,
            reportedUserId: request.reportedUserId.uuidString,
            reason: request.reason.rawValue,
            status: SwapDisputeStatus.open.rawValue,
            filingDeadline: ISO8601DateFormatter().string(from: filingDeadline),
            description: request.description,
            evidenceUrls: request.evidenceUrls?.isEmpty == false ? request.evidenceUrls : nil
        )

        let response: [SwapDispute] = try await supabase
            .from("bill_swap_disputes")
            .insert(disputePayload)
            .select()
            .execute()
            .value

        guard let dispute = response.first else {
            throw SwapDisputeError.createFailed
        }

        // Update swap status to disputed
        let disputedStatusPayload = UpdateSwapStatusPayload(
            status: BillSwapStatus.disputed.rawValue,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("bill_swaps")
            .update(disputedStatusPayload)
            .eq("id", value: request.swapId.uuidString)
            .execute()

        // Send system chat message
        try? await SwapChatService.shared.sendSystemMessage(
            "A dispute has been filed. Our team will review and respond within 48 hours.",
            swapId: request.swapId
        )

        activeDisputes.insert(dispute, at: 0)
        return dispute
    }

    // MARK: - Upload Evidence

    /// Upload evidence image for a dispute
    func uploadEvidence(disputeId: UUID, imageData: Data) async throws -> String {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SwapDisputeError.notAuthenticated
        }

        let fileName = "\(userId.uuidString)/\(disputeId.uuidString)/\(UUID().uuidString).jpg"

        try await supabase.storage
            .from("dispute-evidence")
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        let publicURL = try supabase.storage
            .from("dispute-evidence")
            .getPublicURL(path: fileName)

        return publicURL.absoluteString
    }

    /// Add evidence URL to existing dispute
    func addEvidence(disputeId: UUID, evidenceUrl: String) async throws {
        // Fetch current dispute
        let dispute = try await fetchDispute(disputeId)

        var urls = dispute.evidenceUrls ?? []
        urls.append(evidenceUrl)

        let payload = UpdateEvidencePayload(
            evidenceUrls: urls,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("bill_swap_disputes")
            .update(payload)
            .eq("id", value: disputeId.uuidString)
            .execute()
    }

    // MARK: - Respond to Dispute (for reported user)

    /// Add response from reported user
    func respondToDispute(disputeId: UUID, response: String) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SwapDisputeError.notAuthenticated
        }

        let dispute = try await fetchDispute(disputeId)

        // Verify this user is the reported party
        guard dispute.reportedUserId == userId else {
            throw SwapDisputeError.notAuthenticated
        }

        // Update with response (stored in description field with prefix)
        let existingDesc = dispute.description ?? ""
        let fullDescription = existingDesc + "\n\n---\nReported user response:\n" + response

        let payload = RespondToDisputePayload(
            description: fullDescription,
            status: SwapDisputeStatus.investigating.rawValue,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("bill_swap_disputes")
            .update(payload)
            .eq("id", value: disputeId.uuidString)
            .execute()
    }

    // MARK: - Admin Resolution (called via edge function/admin panel)

    /// Resolve dispute (typically called by admin)
    func resolveDispute(
        disputeId: UUID,
        resolution: String,
        atFaultUserId: UUID?,
        adminId: UUID
    ) async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        let resolvePayload = ResolveDisputePayload(
            status: SwapDisputeStatus.resolved.rawValue,
            resolution: resolution,
            atFaultUserId: atFaultUserId?.uuidString,
            resolvedByAdminId: adminId.uuidString,
            resolvedAt: now,
            updatedAt: now
        )
        try await supabase
            .from("bill_swap_disputes")
            .update(resolvePayload)
            .eq("id", value: disputeId.uuidString)
            .execute()

        let dispute = try await fetchDispute(disputeId)

        // Fetch swap for trust updates
        let swap: BillSwap = try await supabase
            .from("bill_swaps")
            .select()
            .eq("id", value: dispute.swapId.uuidString)
            .single()
            .execute()
            .value

        // If someone is at fault, apply trust penalty
        if let faultId = atFaultUserId {
            // Get bill amount for trust calculation
            let billA: SwapBill = try await supabase
                .from("swap_bills")
                .select()
                .eq("id", value: swap.billAId.uuidString)
                .single()
                .execute()
                .value

            try await trustService.recordFailedSwap(
                userId: faultId,
                swapAmountCents: billA.amountCents,
                isOneSided: swap.swapType == .oneSidedAssist,
                isAtFault: true
            )

            // Refund points to the non-faulty party
            let nonFaultyUserId = faultId == swap.initiatorUserId
                ? swap.counterpartyUserId
                : swap.initiatorUserId

            if let refundUserId = nonFaultyUserId {
                try await pointsService.refundDisputePoints(
                    userId: refundUserId,
                    swapId: dispute.swapId,
                    points: PointsConstants.perCompletedSwap
                )
            }
        }

        // Update swap status to failed
        let failedPayload = UpdateSwapStatusPayload(
            status: BillSwapStatus.failed.rawValue,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("bill_swaps")
            .update(failedPayload)
            .eq("id", value: dispute.swapId.uuidString)
            .execute()

        // Remove from active disputes
        activeDisputes.removeAll { $0.id == disputeId }
    }

    /// Dismiss dispute (typically called by admin)
    func dismissDispute(disputeId: UUID, reason: String, adminId: UUID) async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        let dismissPayload = DismissDisputePayload(
            status: SwapDisputeStatus.dismissed.rawValue,
            resolution: "Dismissed: " + reason,
            resolvedByAdminId: adminId.uuidString,
            resolvedAt: now,
            updatedAt: now
        )
        try await supabase
            .from("bill_swap_disputes")
            .update(dismissPayload)
            .eq("id", value: disputeId.uuidString)
            .execute()

        let dispute = try await fetchDispute(disputeId)

        // Return swap to awaiting proof status
        let awaitingProofPayload = UpdateSwapStatusPayload(
            status: BillSwapStatus.awaitingProof.rawValue,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("bill_swaps")
            .update(awaitingProofPayload)
            .eq("id", value: dispute.swapId.uuidString)
            .execute()

        activeDisputes.removeAll { $0.id == disputeId }
    }
}

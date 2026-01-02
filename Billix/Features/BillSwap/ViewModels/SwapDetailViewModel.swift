//
//  SwapDetailViewModel.swift
//  Billix
//
//  Swap Detail ViewModel
//

import Foundation
import Combine
import UIKit

@MainActor
class SwapDetailViewModel: ObservableObject {
    // MARK: - Services
    private let billSwapService = BillSwapService.shared
    private let proofService = ProofService.shared
    private let trustService = TrustService.shared
    private let paymentService = SwapPaymentService.shared
    private let disputeService = DisputeService.shared

    // MARK: - Published Properties

    @Published var swap: BillSwap
    @Published var billA: SwapBill?
    @Published var billB: SwapBill?
    @Published var proofs: [BillSwapProof] = []
    @Published var disputes: [SwapDispute] = []

    // User info
    @Published var initiatorProfile: TrustProfile?
    @Published var counterpartyProfile: TrustProfile?

    // UI State
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var error: Error?

    // Sheets
    @Published var showProofUpload = false
    @Published var showProofReview = false
    @Published var showPaymentSheet = false
    @Published var showDisputeSheet = false
    @Published var showCounterOfferSheet = false
    @Published var showChatSheet = false

    @Published var selectedProof: BillSwapProof?
    @Published var proofToReview: BillSwapProof?

    // MARK: - Computed Properties

    var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    var isInitiator: Bool {
        currentUserId == swap.initiatorUserId
    }

    var isCounterparty: Bool {
        currentUserId == swap.counterpartyUserId
    }

    var myBill: SwapBill? {
        isInitiator ? billA : billB
    }

    var theirBill: SwapBill? {
        isInitiator ? billB : billA
    }

    var needsToPay: Bool {
        guard swap.status == .acceptedPendingFee else { return false }
        if isInitiator {
            return !swap.feePaidInitiator
        } else {
            return !swap.feePaidCounterparty
        }
    }

    var needsToSubmitProof: Bool {
        guard swap.status == .awaitingProof else { return false }
        guard let userId = currentUserId else { return false }

        // Check if user already has an accepted proof
        let myAcceptedProofs = proofs.filter {
            $0.submitterUserId == userId &&
            ($0.status == .accepted || $0.status == .autoAccepted)
        }
        return myAcceptedProofs.isEmpty
    }

    var needsToReviewProof: Bool {
        guard swap.status == .awaitingProof else { return false }
        guard let userId = currentUserId else { return false }

        // Check if there are pending proofs from the other party
        let theirPendingProofs = proofs.filter {
            $0.submitterUserId != userId && $0.status == .pending
        }
        return !theirPendingProofs.isEmpty
    }

    var pendingProofsToReview: [BillSwapProof] {
        guard let userId = currentUserId else { return [] }
        return proofs.filter {
            $0.submitterUserId != userId && $0.status == .pending
        }
    }

    var myProofs: [BillSwapProof] {
        guard let userId = currentUserId else { return [] }
        return proofs.filter { $0.submitterUserId == userId }
    }

    var theirProofs: [BillSwapProof] {
        guard let userId = currentUserId else { return [] }
        return proofs.filter { $0.submitterUserId != userId }
    }

    var canCancel: Bool {
        swap.status.isActive && (isInitiator || isCounterparty)
    }

    var canDispute: Bool {
        let disputeableStatuses: [BillSwapStatus] = [.awaitingProof, .failed]
        return disputeableStatuses.contains(swap.status) && disputes.isEmpty
    }

    var isChatEnabled: Bool {
        let chatStatuses: [BillSwapStatus] = [
            .acceptedPendingFee, .locked, .awaitingProof,
            .completed, .failed, .disputed
        ]
        return chatStatuses.contains(swap.status)
    }

    var feeAmount: String {
        paymentService.formattedPrice(for: swap.swapType)
    }

    var statusMessage: String {
        switch swap.status {
        case .offered:
            return isInitiator
                ? "Waiting for someone to accept your swap offer"
                : "You have a swap offer to review"
        case .countered:
            return isInitiator
                ? "Your swap has a counter-offer to review"
                : "Waiting for counter-offer response"
        case .acceptedPendingFee:
            if needsToPay {
                return "Pay \(feeAmount) to lock in the swap"
            }
            return "Waiting for the other party to pay"
        case .locked:
            return "Swap locked! Payment in progress..."
        case .awaitingProof:
            if needsToSubmitProof {
                return "Submit proof of your payment"
            }
            if needsToReviewProof {
                return "Review the payment proof submitted"
            }
            return "Waiting for proof submissions"
        case .completed:
            return "Swap completed successfully!"
        case .failed:
            return "Swap failed"
        case .disputed:
            return "Under dispute review"
        case .cancelled:
            return "Swap was cancelled"
        case .expired:
            return "Swap offer expired"
        }
    }

    var timeRemaining: String? {
        switch swap.status {
        case .offered:
            guard let deadline = swap.acceptDeadline else { return nil }
            return formatTimeRemaining(until: deadline)
        case .awaitingProof:
            guard let deadline = swap.proofDueDeadline else { return nil }
            return formatTimeRemaining(until: deadline)
        default:
            return nil
        }
    }

    // MARK: - Initialization

    init(swap: BillSwap) {
        self.swap = swap
    }

    // MARK: - Load Data

    func loadDetails() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load swap details in parallel
            async let swapTask = billSwapService.fetchSwap(swap.id)
            async let proofsTask = proofService.fetchProofsForSwap(swap.id)
            async let disputesTask = disputeService.fetchDisputesForSwap(swap.id)

            swap = try await swapTask
            proofs = try await proofsTask
            disputes = try await disputesTask

            // Load bill details
            async let billATask = fetchBill(swap.billAId)
            let billBTask: SwapBill? = swap.billBId != nil ? try await fetchBill(swap.billBId!) : nil

            billA = try await billATask
            billB = billBTask

            // Load profiles
            async let initiatorTask = trustService.fetchProfile(userId: swap.initiatorUserId)
            initiatorProfile = try await initiatorTask

            if let counterpartyId = swap.counterpartyUserId {
                counterpartyProfile = try await trustService.fetchProfile(userId: counterpartyId)
            }
        } catch {
            self.error = error
            print("Failed to load swap details: \(error)")
        }
    }

    private func fetchBill(_ billId: UUID) async throws -> SwapBill {
        let supabase = SupabaseService.shared.client
        return try await supabase
            .from("swap_bills")
            .select()
            .eq("id", value: billId.uuidString)
            .single()
            .execute()
            .value
    }

    func refresh() async {
        await loadDetails()
    }

    // MARK: - Accept Swap

    func acceptSwap(withBillId: UUID? = nil) async throws {
        isProcessing = true
        defer { isProcessing = false }

        try await billSwapService.acceptSwap(swap.id, billBId: withBillId)
        await loadDetails()
    }

    // MARK: - Cancel Swap

    func cancelSwap() async throws {
        isProcessing = true
        defer { isProcessing = false }

        try await billSwapService.cancelSwap(swap.id)
        await loadDetails()
    }

    // MARK: - Pay Fee

    func payFee() async throws {
        isProcessing = true
        defer { isProcessing = false }

        try await paymentService.purchaseFee(for: swap, isInitiator: isInitiator)
        await loadDetails()
    }

    func waiveFeeWithPoints() async throws {
        isProcessing = true
        defer { isProcessing = false }

        try await paymentService.waiveFeeWithPoints(for: swap, isInitiator: isInitiator)
        await loadDetails()
    }

    // MARK: - Proof Submission

    func submitProof(type: SwapProofType, imageData: Data, notes: String?) async throws {
        isProcessing = true
        defer { isProcessing = false }

        // Upload image
        let imageUrl = try await proofService.uploadProofImage(
            swapId: swap.id,
            imageData: imageData
        )

        // Submit proof
        let request = SubmitProofRequest(
            swapId: swap.id,
            proofType: type,
            proofUrl: imageUrl,
            notes: notes
        )

        _ = try await proofService.submitProof(request)
        await loadDetails()
    }

    // MARK: - Proof Review

    func acceptProof(_ proof: BillSwapProof) async throws {
        isProcessing = true
        defer { isProcessing = false }

        try await proofService.acceptProof(proof.id)
        await loadDetails()
    }

    func rejectProof(_ proof: BillSwapProof, reason: SwapProofRejectionReason, notes: String?) async throws {
        isProcessing = true
        defer { isProcessing = false }

        try await proofService.rejectProof(proof.id, reason: reason, notes: notes)
        await loadDetails()
    }

    // MARK: - File Dispute

    func fileDispute(reason: SwapDisputeReason, description: String?, evidence: [Data]?) async throws {
        isProcessing = true
        defer { isProcessing = false }

        guard let userId = currentUserId else {
            throw BillSwapError.notAuthenticated
        }

        let reportedUserId = isInitiator
            ? swap.counterpartyUserId ?? UUID()
            : swap.initiatorUserId

        // Upload evidence if provided
        var evidenceUrls: [String]?
        if let evidenceData = evidence {
            evidenceUrls = []
            for data in evidenceData {
                // Upload would go here - simplified for now
                // let url = try await disputeService.uploadEvidence(disputeId: UUID(), imageData: data)
                // evidenceUrls?.append(url)
            }
        }

        let request = FileDisputeRequest(
            swapId: swap.id,
            reportedUserId: reportedUserId,
            reason: reason,
            description: description,
            evidenceUrls: evidenceUrls
        )

        _ = try await disputeService.fileDispute(request)
        await loadDetails()
    }

    // MARK: - Helpers

    private func formatTimeRemaining(until date: Date) -> String {
        let now = Date()
        let remaining = date.timeIntervalSince(now)

        if remaining <= 0 {
            return "Expired"
        }

        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) % 3600 / 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)d remaining"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
}

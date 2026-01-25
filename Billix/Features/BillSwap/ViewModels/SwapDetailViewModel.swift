//
//  SwapDetailViewModel.swift
//  Billix
//
//  ViewModel for individual swap details and handshake flow
//

import Foundation
import UIKit
import Combine

/// ViewModel for managing a single swap transaction
@MainActor
class SwapDetailViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var swap: BillSwapTransaction?
    @Published var myBill: SwapBill?
    @Published var partnerBill: SwapBill?
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var isUploadingProof = false
    @Published var error: Error?
    @Published var showError = false
    @Published var showPaymentSuccess = false
    @Published var showProofSuccess = false
    @Published var remainingFreeSwaps: Int = 2  // Default, will be loaded from profile

    // Proof upload
    @Published var proofImage: UIImage?
    @Published var showProofImagePicker = false

    // MARK: - Services
    private let swapService = SwapService.shared
    private let billService = SwapBillService.shared
    private let storeKitService = StoreKitService.shared

    // MARK: - Properties
    private var swapId: UUID?

    // MARK: - Computed Properties

    var currentUserId: UUID? {
        AuthService.shared.currentUser?.id
    }

    var hasPaidFee: Bool {
        guard let swap = swap, let userId = currentUserId else { return false }
        return swap.hasPaidFee(userId: userId)
    }

    var hasPaidPartner: Bool {
        guard let swap = swap, let userId = currentUserId else { return false }
        return swap.hasPaidPartner(userId: userId)
    }

    var partnerHasPaidMe: Bool {
        guard let swap = swap, let userId = currentUserId else { return false }
        return swap.partnerHasPaidMe(userId: userId)
    }

    var canSeeAccountNumber: Bool {
        // Account number is revealed only when BOTH users have paid/committed
        guard let swap = swap else { return false }
        return swap.bothPaidFees
    }

    var statusMessage: String {
        guard let swap = swap, let userId = currentUserId else { return "" }
        return swap.statusMessage(for: userId)
    }

    var progress: Double {
        swap?.progressPercentage ?? 0
    }

    var handshakeFeePrice: String {
        storeKitService.handshakeFeePrice
    }

    /// Whether current user has Billix Prime subscription
    var isPrime: Bool {
        storeKitService.isPrime
    }

    /// Whether partner has already committed to the swap
    var partnerHasCommitted: Bool {
        guard let swap = swap, let userId = currentUserId else { return false }
        return swap.partnerHasCommitted(userId: userId)
    }

    /// Time remaining until match expires
    var formattedTimeRemaining: String? {
        swap?.formattedTimeRemaining
    }

    /// Whether the swap has expired
    var isExpired: Bool {
        swap?.isExpired ?? false
    }

    /// Whether user has remaining free swaps
    var hasFreeSwapsRemaining: Bool {
        remainingFreeSwaps > 0
    }

    /// Description of what happens when user confirms
    var confirmButtonText: String {
        if isPrime {
            return "Confirm Swap (Free with Prime)"
        } else if hasFreeSwapsRemaining {
            return "Use Free Swap (\(remainingFreeSwaps) remaining)"
        } else {
            return "Pay \(handshakeFeePrice) to Unlock"
        }
    }

    // MARK: - Initialization

    init(swapId: UUID? = nil) {
        self.swapId = swapId
    }

    // MARK: - Data Loading

    /// Load swap details
    func loadSwap() async {
        guard let swapId = swapId else { return }

        isLoading = true
        error = nil

        do {
            let swap = try await swapService.getSwap(id: swapId)
            self.swap = swap

            // Load bills
            guard let userId = currentUserId else { return }

            let myBillId = swap.myBillId(for: userId)
            let partnerBillId = swap.partnerBillId(for: userId)

            // Fetch both bills
            let myBillResult: SwapBill = try await SupabaseService.shared.client
                .from("swap_bills")
                .select()
                .eq("id", value: myBillId.uuidString)
                .single()
                .execute()
                .value

            let partnerBillResult: SwapBill = try await SupabaseService.shared.client
                .from("swap_bills")
                .select()
                .eq("id", value: partnerBillId.uuidString)
                .single()
                .execute()
                .value

            self.myBill = myBillResult
            self.partnerBill = partnerBillResult

        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    /// Set swap ID and load
    func setSwap(id: UUID) async {
        self.swapId = id
        await loadSwap()
    }

    // MARK: - Handshake Flow

    /// Accept the swap - handles Prime users, free swaps, and paid swaps
    func acceptSwap() async {
        guard let swapId = swapId else { return }

        isPurchasing = true
        error = nil

        do {
            var committed = false

            if isPrime {
                // Prime users get unlimited free swaps
                committed = true
            } else if hasFreeSwapsRemaining {
                // Use one of the free monthly swaps
                try await swapService.useFreeSwap()
                remainingFreeSwaps -= 1
                committed = true
            } else {
                // Must pay the handshake fee
                committed = try await storeKitService.purchaseHandshakeFee()
            }

            if committed {
                // Update swap in database
                try await swapService.acceptSwap(swapId: swapId)

                // Reload swap data
                await loadSwap()

                showPaymentSuccess = true
            }
        } catch {
            self.error = error
            self.showError = true
        }

        isPurchasing = false
    }

    /// Load remaining free swaps from user profile
    func loadFreeSwapCount() async {
        do {
            remainingFreeSwaps = try await swapService.getRemainingFreeSwaps()
        } catch {
            print("Failed to load free swap count: \(error)")
            remainingFreeSwaps = 0
        }
    }

    // MARK: - Proof Upload

    /// Process and upload proof of payment
    func uploadProof() async {
        guard let swapId = swapId,
              let proofImage = proofImage else {
            error = SwapDetailError.proofImageRequired
            showError = true
            return
        }

        isUploadingProof = true
        error = nil

        do {
            // Upload image to storage
            let proofUrl = try await billService.uploadBillImage(proofImage)

            // Update swap with proof
            try await swapService.markPartnerPaid(swapId: swapId, proofUrl: proofUrl)

            // Reload swap data
            await loadSwap()

            // Clear proof image
            self.proofImage = nil

            showProofSuccess = true
        } catch {
            self.error = error
            self.showError = true
        }

        isUploadingProof = false
    }

    // MARK: - Dispute

    /// Raise a dispute
    func raiseDispute(reason: String) async {
        guard let swapId = swapId else { return }

        do {
            try await swapService.raiseDispute(swapId: swapId, reason: reason)
            await loadSwap()
        } catch {
            self.error = error
            self.showError = true
        }
    }
}

// MARK: - Errors

enum SwapDetailError: LocalizedError {
    case proofImageRequired
    case swapNotFound

    var errorDescription: String? {
        switch self {
        case .proofImageRequired:
            return "Please capture a photo of your payment receipt"
        case .swapNotFound:
            return "Swap not found"
        }
    }
}

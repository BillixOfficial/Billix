//
//  SwapDetailView.swift
//  Billix
//
//  Swap Detail View - Redesigned with Timeline Hero
//

import SwiftUI

struct SwapDetailView: View {
    @StateObject private var viewModel: SwapDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(swap: BillSwap) {
        _viewModel = StateObject(wrappedValue: SwapDetailViewModel(swap: swap))
    }

    var body: some View {
        ZStack {
            // Background
            BillSwapTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Timeline Hero Card
                    TimelineHeroCard(
                        currentStep: progressStep,
                        partnerName: partnerName,
                        statusMessage: viewModel.statusMessage,
                        timeRemaining: viewModel.timeRemaining
                    )

                    // Action buttons based on status
                    ActionSection(viewModel: viewModel)

                    // Bill details
                    BillDetailsSection(viewModel: viewModel)

                    // Proof section
                    if viewModel.swap.status == .awaitingProof ||
                       viewModel.swap.status == .completed ||
                       viewModel.swap.status == .disputed {
                        ProofSection(viewModel: viewModel)
                    }

                    // Dispute info
                    if !viewModel.disputes.isEmpty {
                        DisputeSection(disputes: viewModel.disputes)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Swap Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isChatEnabled {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.showChatSheet = true
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .foregroundColor(BillSwapTheme.accent)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadDetails()
        }
        .sheet(isPresented: $viewModel.showPaymentSheet) {
            SwapPaymentSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showProofUpload) {
            ProofUploadView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showProofReview) {
            if let proof = viewModel.proofToReview {
                ProofReviewView(proof: proof, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showDisputeSheet) {
            DisputeSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showChatSheet) {
            SwapChatView(swapId: viewModel.swap.id, swap: viewModel.swap)
        }
        .overlay {
            if viewModel.isLoading || viewModel.isProcessing {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(BillSwapTheme.accent)

                        Text("Processing...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(BillSwapTheme.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }

    // MARK: - Computed Properties

    private var progressStep: SwapProgressStep {
        SwapProgressStep.from(status: viewModel.swap.status.rawValue)
    }

    private var partnerName: String {
        // Placeholder - actual partner name would be fetched separately
        if viewModel.isInitiator {
            return viewModel.swap.counterpartyUserId != nil ? "partner" : "waiting"
        } else {
            return "partner"
        }
    }
}

// MARK: - Action Section (Redesigned)

private struct ActionSection: View {
    @ObservedObject var viewModel: SwapDetailViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Pay fee button
            if viewModel.needsToPay {
                BillSwapTheme.PrimaryButton(
                    title: "Pay Fee (\(viewModel.feeAmount))",
                    icon: "creditcard.fill"
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.showPaymentSheet = true
                }
            }

            // Submit proof button
            if viewModel.needsToSubmitProof {
                BillSwapTheme.PrimaryButton(
                    title: "Submit Payment Proof",
                    icon: "camera.fill"
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.showProofUpload = true
                }
            }

            // Review proofs button
            if viewModel.needsToReviewProof {
                ForEach(viewModel.pendingProofsToReview) { proof in
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.proofToReview = proof
                        viewModel.showProofReview = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                            Text("Review Partner's Proof")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BillSwapTheme.statusPending)
                        .cornerRadius(12)
                    }
                }
            }

            // Accept/Cancel buttons for offered swaps
            if viewModel.swap.status == .offered && !viewModel.isInitiator {
                HStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { try? await viewModel.acceptSwap() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text("Accept")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BillSwapTheme.statusComplete)
                        .cornerRadius(12)
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { try? await viewModel.cancelSwap() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                            Text("Decline")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BillSwapTheme.statusDispute)
                        .cornerRadius(12)
                    }
                }
            }

            // Cancel button
            if viewModel.canCancel && viewModel.swap.status != .offered {
                BillSwapTheme.SecondaryButton(
                    title: "Cancel Swap",
                    icon: "xmark.circle"
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    Task { try? await viewModel.cancelSwap() }
                }
            }

            // Dispute button
            if viewModel.canDispute {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.showDisputeSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                        Text("File Dispute")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BillSwapTheme.statusPending)
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Bill Details Section (Deal Sheet Style)

private struct BillDetailsSection: View {
    @ObservedObject var viewModel: SwapDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(BillSwapTheme.accent)
                Text("Deal Sheet")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(BillSwapTheme.primaryText)
            }

            // Side-by-side Deal Sheet layout
            if let billA = viewModel.billA, let billB = viewModel.billB {
                DealSheetLayout(
                    yourBill: viewModel.isInitiator ? billA : billB,
                    theirBill: viewModel.isInitiator ? billB : billA,
                    swap: viewModel.swap
                )
            } else if let billA = viewModel.billA {
                // Only one bill available (one-sided or pending)
                DetailBillCard(
                    bill: billA,
                    label: viewModel.isInitiator ? "Your Bill" : "Their Bill"
                )

                if viewModel.swap.billBId == nil {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 28))
                                .foregroundColor(BillSwapTheme.secondaryText)
                            Text("Waiting for partner's bill")
                                .font(.system(size: 13))
                                .foregroundColor(BillSwapTheme.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 24)
                    .background(BillSwapTheme.cardBackground)
                    .cornerRadius(BillSwapTheme.cardCornerRadius)
                }
            }
        }
    }
}

// MARK: - Deal Sheet Layout (Side-by-Side)

private struct DealSheetLayout: View {
    let yourBill: SwapBill
    let theirBill: SwapBill
    let swap: BillSwap

    var body: some View {
        VStack(spacing: 16) {
            // Side-by-side bill panels
            HStack(alignment: .top, spacing: 12) {
                // Your Bill (Left)
                DealSheetBillCard(
                    bill: yourBill,
                    isYours: true,
                    status: determineBillStatus(isYours: true)
                )

                // Center lock indicator
                VStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color(hex: swap.status.color).opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: swap.status.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: swap.status.color))
                    }

                    Text(swap.status.displayName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color(hex: swap.status.color))
                        .multilineTextAlignment(.center)
                        .frame(width: 50)

                    Spacer()
                }
                .frame(width: 50)

                // Their Bill (Right)
                DealSheetBillCard(
                    bill: theirBill,
                    isYours: false,
                    status: determineBillStatus(isYours: false)
                )
            }

            // Fees breakdown
            DealSheetFees(swap: swap)
        }
    }

    private func determineBillStatus(isYours: Bool) -> DealSheetBillStatus {
        switch swap.status {
        case .offered, .countered, .acceptedPendingFee:
            return .readyToBePaid
        case .locked:
            if let deadline = swap.proofDueDeadline {
                return .pendingPayment(dueDate: deadline)
            }
            return .readyToBePaid
        case .awaitingProof:
            return .paymentSubmitted
        case .completed:
            return .completed
        default:
            return .readyToBePaid
        }
    }
}

// MARK: - Deal Sheet Bill Card

private struct DealSheetBillCard: View {
    let bill: SwapBill
    let isYours: Bool
    let status: DealSheetBillStatus

    private var redactedInfo: RedactedBillInfo {
        RedactedBillInfo.fromBill(bill, ownerProfile: nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text(isYours ? "Your Bill" : "Their Bill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(BillSwapTheme.mutedText)
                    .textCase(.uppercase)

                Spacer()

                // Tier badge (only show for their bill)
                if !isYours {
                    HStack(spacing: 3) {
                        Image(systemName: redactedInfo.ownerTier.icon)
                            .font(.system(size: 8))
                        Text(redactedInfo.tierDisplayName)
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(Color(hex: redactedInfo.tierBadgeColor))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: redactedInfo.tierBadgeColor).opacity(0.12))
                    .cornerRadius(4)
                }
            }

            // Category icon and biller name
            HStack(spacing: 6) {
                Image(systemName: redactedInfo.categoryIcon)
                    .font(.system(size: 12))
                    .foregroundColor(BillSwapTheme.accent)
                    .frame(width: 22, height: 22)
                    .background(BillSwapTheme.accentLight)
                    .cornerRadius(4)

                Text(redactedInfo.billerName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BillSwapTheme.primaryText)
                    .lineLimit(1)
            }

            // Amount
            Text(redactedInfo.formattedAmount)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isYours ? BillSwapTheme.accent : BillSwapTheme.primaryText)

            // Account (masked for privacy)
            if !isYours {
                HStack(spacing: 3) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 8))
                    Text(redactedInfo.maskedAccountNumber)
                        .font(.system(size: 10))
                }
                .foregroundColor(BillSwapTheme.secondaryText)
            }

            // Due date
            HStack(spacing: 3) {
                Image(systemName: "calendar")
                    .font(.system(size: 8))
                Text(redactedInfo.dueDateUrgencyText)
                    .font(.system(size: 10))
                    .foregroundColor(redactedInfo.isUrgent ? .orange : BillSwapTheme.secondaryText)
            }

            Divider()

            // Status
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.system(size: 10))
                Text(status.displayText(isOwner: isYours))
                    .font(.system(size: 10))
                    .lineLimit(2)
            }
            .foregroundColor(Color(hex: status.color))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isYours ? BillSwapTheme.accentLight : BillSwapTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isYours ? BillSwapTheme.accent.opacity(0.2) : BillSwapTheme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Deal Sheet Fees

private struct DealSheetFees: View {
    let swap: BillSwap

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Facilitation Fee")
                    .font(.system(size: 12))
                    .foregroundColor(BillSwapTheme.secondaryText)
                Spacer()
                Text("$1.99")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BillSwapTheme.primaryText)
            }

            if swap.spreadFeeCents > 0 {
                HStack {
                    Text("Spread Fee (3%)")
                        .font(.system(size: 12))
                        .foregroundColor(BillSwapTheme.secondaryText)
                    Spacer()
                    Text(String(format: "$%.2f", Double(swap.spreadFeeCents) / 100.0))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(BillSwapTheme.primaryText)
                }
            }

            Divider()

            HStack {
                Text("Your Total Fee")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(BillSwapTheme.primaryText)
                Spacer()
                Text(String(format: "$%.2f", Double(swap.feeAmountCentsInitiator) / 100.0))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(BillSwapTheme.accent)
            }
        }
        .padding(12)
        .background(BillSwapTheme.cardBackground)
        .cornerRadius(10)
        .shadow(color: BillSwapTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
}

private struct DetailBillCard: View {
    let bill: SwapBill
    let label: String

    private var categoryColor: Color {
        BillSwapTheme.categoryColor(for: bill.category.rawValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(BillSwapTheme.mutedText)
                .tracking(0.5)

            HStack(spacing: 12) {
                // Category icon
                CategoryIcon(category: bill.category.rawValue, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(BillSwapTheme.primaryText)

                    if let provider = bill.providerName {
                        Text(provider)
                            .font(.system(size: 12))
                            .foregroundColor(BillSwapTheme.secondaryText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(bill.formattedAmount)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(BillSwapTheme.accent)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(bill.formattedDueDate)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(BillSwapTheme.secondaryText)
                }
            }
        }
        .padding(16)
        .background(BillSwapTheme.cardBackground)
        .cornerRadius(BillSwapTheme.cardCornerRadius)
        .shadow(
            color: BillSwapTheme.cardShadow,
            radius: BillSwapTheme.cardShadowRadius,
            x: 0,
            y: BillSwapTheme.cardShadowY
        )
        .overlay(
            RoundedRectangle(cornerRadius: BillSwapTheme.cardCornerRadius)
                .stroke(categoryColor.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Proof Section (Redesigned)

private struct ProofSection: View {
    @ObservedObject var viewModel: SwapDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(BillSwapTheme.accent)
                Text("Payment Proofs")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(BillSwapTheme.primaryText)
            }

            if viewModel.proofs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 32))
                        .foregroundColor(BillSwapTheme.secondaryText.opacity(0.5))

                    Text("No proofs submitted yet")
                        .font(.system(size: 14))
                        .foregroundColor(BillSwapTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(BillSwapTheme.cardBackground)
                .cornerRadius(BillSwapTheme.cardCornerRadius)
                .shadow(
                    color: BillSwapTheme.cardShadow,
                    radius: BillSwapTheme.cardShadowRadius,
                    x: 0,
                    y: BillSwapTheme.cardShadowY
                )
            } else {
                ForEach(viewModel.proofs) { proof in
                    ProofRow(
                        proof: proof,
                        isMyProof: proof.submitterUserId == viewModel.currentUserId
                    )
                }
            }
        }
    }
}

private struct ProofRow: View {
    let proof: BillSwapProof
    let isMyProof: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(BillSwapTheme.accentLight)
                    .frame(width: 40, height: 40)

                Image(systemName: proof.proofType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(BillSwapTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isMyProof ? "Your Proof" : "Partner's Proof")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BillSwapTheme.primaryText)

                Text(proof.proofType.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(BillSwapTheme.secondaryText)
            }

            Spacer()

            ProofStatusBadge(status: proof.status)
        }
        .padding(14)
        .background(BillSwapTheme.cardBackground)
        .cornerRadius(BillSwapTheme.cardCornerRadius)
        .shadow(
            color: BillSwapTheme.cardShadow,
            radius: BillSwapTheme.cardShadowRadius,
            x: 0,
            y: BillSwapTheme.cardShadowY
        )
    }
}

private struct ProofStatusBadge: View {
    let status: SwapProofStatus

    var body: some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }

    private var statusColor: Color {
        switch status {
        case .pending, .pendingReview: return BillSwapTheme.statusPending
        case .accepted, .autoAccepted: return BillSwapTheme.statusComplete
        case .rejected: return BillSwapTheme.statusDispute
        case .resubmitted: return BillSwapTheme.statusActive
        }
    }
}

// MARK: - Dispute Section (Redesigned)

private struct DisputeSection: View {
    let disputes: [SwapDispute]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(BillSwapTheme.statusDispute)
                Text("Disputes")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(BillSwapTheme.primaryText)
            }

            ForEach(disputes) { dispute in
                DisputeCard(dispute: dispute)
            }
        }
    }
}

private struct DisputeCard: View {
    let dispute: SwapDispute

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: dispute.status.icon)
                    .foregroundColor(Color(hex: dispute.status.color))

                Text(dispute.status.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BillSwapTheme.primaryText)

                Spacer()

                Text(dispute.formattedCreatedAt)
                    .font(.system(size: 11))
                    .foregroundColor(BillSwapTheme.secondaryText)
            }

            Text(dispute.reason.displayName)
                .font(.system(size: 13))
                .foregroundColor(BillSwapTheme.secondaryText)

            if let resolution = dispute.resolution {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Resolution: \(resolution)")
                        .font(.system(size: 12))
                }
                .foregroundColor(BillSwapTheme.statusComplete)
            }
        }
        .padding(14)
        .background(BillSwapTheme.cardBackground)
        .cornerRadius(BillSwapTheme.cardCornerRadius)
        .shadow(
            color: BillSwapTheme.cardShadow,
            radius: BillSwapTheme.cardShadowRadius,
            x: 0,
            y: BillSwapTheme.cardShadowY
        )
        .overlay(
            RoundedRectangle(cornerRadius: BillSwapTheme.cardCornerRadius)
                .stroke(BillSwapTheme.statusDispute.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SwapDetailView(swap: BillSwap(
            id: UUID(),
            swapType: .twoSided,
            status: .awaitingProof,
            initiatorUserId: UUID(),
            counterpartyUserId: UUID(),
            billAId: UUID(),
            billBId: UUID(),
            counterOfferAmountCents: nil,
            counterOfferByUserId: nil,
            feeAmountCentsInitiator: 99,
            feeAmountCentsCounterparty: 99,
            spreadFeeCents: 0,
            feePaidInitiator: true,
            feePaidCounterparty: true,
            pointsWaiverInitiator: false,
            pointsWaiverCounterparty: false,
            acceptDeadline: nil,
            proofDueDeadline: Date().addingTimeInterval(72 * 3600),
            createdAt: Date(),
            updatedAt: Date(),
            acceptedAt: Date(),
            lockedAt: Date(),
            completedAt: nil,
            billA: SwapBill(
                id: UUID(),
                ownerUserId: UUID(),
                title: "Electric Bill",
                category: .electric,
                providerName: "ConEd",
                amountCents: 8500,
                dueDate: Date().addingTimeInterval(86400 * 5),
                status: .lockedInSwap,
                paymentUrl: nil,
                accountNumberLast4: nil,
                billImageUrl: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            billB: SwapBill(
                id: UUID(),
                ownerUserId: UUID(),
                title: "Internet Bill",
                category: .internet,
                providerName: "Spectrum",
                amountCents: 6500,
                dueDate: Date().addingTimeInterval(86400 * 7),
                status: .lockedInSwap,
                paymentUrl: nil,
                accountNumberLast4: nil,
                billImageUrl: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            initiatorProfile: nil,
            counterpartyProfile: nil
        ))
    }
}

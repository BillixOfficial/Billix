//
//  SwapDetailView.swift
//  Billix
//
//  Swap Detail View
//

import SwiftUI

struct SwapDetailView: View {
    @StateObject private var viewModel: SwapDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(swap: BillSwap) {
        _viewModel = StateObject(wrappedValue: SwapDetailViewModel(swap: swap))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status card
                StatusHeaderCard(viewModel: viewModel)

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
        .navigationTitle("Swap Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isChatEnabled {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showChatSheet = true
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right")
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
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
}

// MARK: - Status Header Card

struct StatusHeaderCard: View {
    @ObservedObject var viewModel: SwapDetailViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Status icon and name
            HStack {
                Image(systemName: viewModel.swap.status.icon)
                    .font(.title)
                    .foregroundColor(statusColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.swap.status.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(viewModel.statusMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Time remaining
            if let timeRemaining = viewModel.timeRemaining {
                HStack {
                    Image(systemName: "clock")
                    Text(timeRemaining)
                }
                .font(.subheadline)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Swap type
            HStack {
                Label(
                    viewModel.swap.swapType.displayName,
                    systemImage: viewModel.swap.swapType.icon
                )
                .font(.subheadline)
                .foregroundColor(.secondary)

                Spacer()

                Text("Fee: \(viewModel.feeAmount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var statusColor: Color {
        switch viewModel.swap.status {
        case .offered, .countered: return .blue
        case .acceptedPendingFee, .locked: return .orange
        case .awaitingProof: return .purple
        case .completed: return .green
        case .failed, .disputed: return .red
        case .cancelled, .expired: return .gray
        }
    }
}

// MARK: - Action Section

struct ActionSection: View {
    @ObservedObject var viewModel: SwapDetailViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Pay fee button
            if viewModel.needsToPay {
                Button {
                    viewModel.showPaymentSheet = true
                } label: {
                    Label("Pay Fee (\(viewModel.feeAmount))", systemImage: "creditcard")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.billixMoneyGreen)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

            // Submit proof button
            if viewModel.needsToSubmitProof {
                Button {
                    viewModel.showProofUpload = true
                } label: {
                    Label("Submit Proof", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.billixDarkTeal)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

            // Review proofs button
            if viewModel.needsToReviewProof {
                ForEach(viewModel.pendingProofsToReview) { proof in
                    Button {
                        viewModel.proofToReview = proof
                        viewModel.showProofReview = true
                    } label: {
                        Label("Review Proof", systemImage: "eye")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }

            // Accept/Cancel buttons for offered swaps
            if viewModel.swap.status == .offered && !viewModel.isInitiator {
                HStack(spacing: 12) {
                    Button {
                        Task { try? await viewModel.acceptSwap() }
                    } label: {
                        Label("Accept", systemImage: "checkmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button {
                        Task { try? await viewModel.cancelSwap() }
                    } label: {
                        Label("Decline", systemImage: "xmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }

            // Cancel button
            if viewModel.canCancel && viewModel.swap.status != .offered {
                Button {
                    Task { try? await viewModel.cancelSwap() }
                } label: {
                    Label("Cancel Swap", systemImage: "xmark.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            }

            // Dispute button
            if viewModel.canDispute {
                Button {
                    viewModel.showDisputeSheet = true
                } label: {
                    Label("File Dispute", systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - Bill Details Section

struct BillDetailsSection: View {
    @ObservedObject var viewModel: SwapDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bills")
                .font(.headline)

            if let billA = viewModel.billA {
                BillDetailCard(
                    bill: billA,
                    label: viewModel.isInitiator ? "Your Bill" : "Their Bill"
                )
            }

            if let billB = viewModel.billB {
                BillDetailCard(
                    bill: billB,
                    label: viewModel.isInitiator ? "Their Bill" : "Your Bill"
                )
            }
        }
    }
}

struct BillDetailCard: View {
    let bill: SwapBill
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: bill.category.icon)
                    .foregroundColor(Color.billixDarkTeal)

                VStack(alignment: .leading) {
                    Text(bill.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let provider = bill.providerName {
                        Text(provider)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(bill.formattedAmount)
                    .font(.headline)
                    .foregroundColor(Color.billixMoneyGreen)
            }

            HStack {
                Label(bill.formattedDueDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Proof Section

struct ProofSection: View {
    @ObservedObject var viewModel: SwapDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Proofs")
                .font(.headline)

            if viewModel.proofs.isEmpty {
                Text("No proofs submitted yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(12)
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

struct ProofRow: View {
    let proof: BillSwapProof
    let isMyProof: Bool

    var body: some View {
        HStack {
            Image(systemName: proof.proofType.icon)
                .foregroundColor(Color.billixDarkTeal)

            VStack(alignment: .leading, spacing: 2) {
                Text(isMyProof ? "Your Proof" : "Their Proof")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(proof.proofType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            ProofStatusBadge(status: proof.status)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProofStatusBadge: View {
    let status: SwapProofStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(6)
    }

    private var statusColor: Color {
        switch status {
        case .pending, .pendingReview: return .orange
        case .accepted, .autoAccepted: return .green
        case .rejected: return .red
        case .resubmitted: return .blue
        }
    }
}

// MARK: - Dispute Section

struct DisputeSection: View {
    let disputes: [SwapDispute]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disputes")
                .font(.headline)

            ForEach(disputes) { dispute in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: dispute.status.icon)
                            .foregroundColor(Color(hex: dispute.status.color))

                        Text(dispute.status.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Text(dispute.formattedCreatedAt)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(dispute.reason.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let resolution = dispute.resolution {
                        Text("Resolution: \(resolution)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
}

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
            billA: nil,
            billB: nil,
            initiatorProfile: nil,
            counterpartyProfile: nil
        ))
    }
}

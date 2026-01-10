//
//  ProofReviewView.swift
//  Billix
//
//  Proof Review View for Bill Swap
//

import SwiftUI

struct ProofReviewView: View {
    let proof: BillSwapProof
    @ObservedObject var viewModel: SwapDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showRejectSheet = false
    @State private var rejectionReason: SwapProofRejectionReason = .unclear
    @State private var rejectionNotes = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Proof image
                    AsyncImage(url: URL(string: proof.proofUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 300)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 400)
                                .cornerRadius(12)
                        case .failure:
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Failed to load image")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(12)
                        @unknown default:
                            EmptyView()
                        }
                    }

                    // Proof info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(proof.proofType.displayName, systemImage: proof.proofType.icon)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(proof.formattedCreatedAt)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let notes = proof.submitterNotes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes from submitter:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(notes)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)
                        }

                        if proof.resubmissionCount > 0 {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Resubmission #\(proof.resubmissionCount)")
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                        }
                    }

                    // Review deadline
                    if proof.status == .pending, let deadline = proof.reviewDeadline {
                        HStack {
                            Image(systemName: "clock")
                            Text(formatDeadline(deadline))
                        }
                        .font(.subheadline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                    }

                    // Guidelines
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review Guidelines")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        VStack(alignment: .leading, spacing: 6) {
                            GuidelineRow(text: "Check the payment amount matches the bill", icon: "dollarsign.circle")
                            GuidelineRow(text: "Verify the date is recent", icon: "calendar")
                            GuidelineRow(text: "Look for the payment confirmation", icon: "checkmark.seal")
                            GuidelineRow(text: "Ensure the proof is clear and readable", icon: "eye")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Review Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if proof.status == .pending {
                    HStack(spacing: 16) {
                        Button {
                            showRejectSheet = true
                        } label: {
                            Label("Reject", systemImage: "xmark")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                        }

                        Button {
                            acceptProof()
                        } label: {
                            Label("Accept", systemImage: "checkmark")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
            .sheet(isPresented: $showRejectSheet) {
                RejectProofSheet(
                    reason: $rejectionReason,
                    notes: $rejectionNotes,
                    onReject: rejectProof
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }

    private func formatDeadline(_ date: Date) -> String {
        let remaining = date.timeIntervalSince(Date())
        if remaining <= 0 {
            return "Review deadline passed - will auto-accept"
        }

        let hours = Int(remaining / 3600)
        let minutes = Int(remaining) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m left to review"
        } else {
            return "\(minutes)m left to review"
        }
    }

    private func acceptProof() {
        isProcessing = true

        Task {
            do {
                try await viewModel.acceptProof(proof)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }

    private func rejectProof() {
        isProcessing = true
        showRejectSheet = false

        Task {
            do {
                try await viewModel.rejectProof(
                    proof,
                    reason: rejectionReason,
                    notes: rejectionNotes.isEmpty ? nil : rejectionNotes
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Guideline Row

struct GuidelineRow: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.billixDarkTeal)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Reject Proof Sheet

struct RejectProofSheet: View {
    @Binding var reason: SwapProofRejectionReason
    @Binding var notes: String
    let onReject: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Rejection Reason", selection: $reason) {
                        ForEach(SwapProofRejectionReason.allCases, id: \.self) { reason in
                            Text(reason.displayName)
                                .tag(reason)
                        }
                    }
                } header: {
                    Text("Reason")
                } footer: {
                    Text(reason.description)
                }

                Section {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes (Optional)")
                } footer: {
                    Text("Help the other party understand what's wrong with the proof")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Important", systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)

                        Text("The other party can resubmit proof up to 3 times. If you unfairly reject valid proof, they can file a dispute.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Reject Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reject") {
                        onReject()
                    }
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ProofReviewView(
        proof: SwapProof(
            id: UUID(),
            swapId: UUID(),
            userId: UUID(),
            billId: UUID(),
            proofType: .screenshot,
            fileUrl: "https://example.com/proof.jpg",
            notes: "Payment made via bank app",
            status: .pending,
            reviewedByUserId: nil,
            rejectionReason: nil,
            resubmissionCount: 0,
            originalProofId: nil,
            reviewDeadline: Date().addingTimeInterval(12 * 3600),
            submittedAt: Date(),
            reviewedAt: nil
        ),
        viewModel: SwapDetailViewModel(swap: BillSwap(
            id: UUID(),
            swapType: .twoSided,
            status: .awaitingProof,
            initiatorUserId: UUID(),
            counterpartyUserId: UUID(),
            billAId: UUID(),
            billBId: nil,
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
            billA: nil,
            billB: nil,
            initiatorProfile: nil,
            counterpartyProfile: nil
        ))
    )
}

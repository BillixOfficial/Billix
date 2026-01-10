//
//  ProofUploadView.swift
//  Billix
//
//  Proof Upload View for Bill Swap
//

import SwiftUI
import PhotosUI

struct ProofUploadView: View {
    @ObservedObject var viewModel: SwapDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProofType: SwapProofType = .screenshot
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var notes: String = ""
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var canSubmit: Bool {
        selectedImage != nil && !isUploading
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Submit Payment Proof", systemImage: "doc.badge.plus")
                            .font(.headline)

                        Text("Upload a clear screenshot or photo showing your payment was made.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.billixCreamBeige.opacity(0.5))
                    .cornerRadius(12)

                    // Proof type picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Proof Type")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("Proof Type", selection: $selectedProofType) {
                            ForEach(SwapProofType.allCases, id: \.self) { type in
                                Label(type.displayName, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    // Image picker
                    VStack(spacing: 12) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .overlay(
                                    Button {
                                        selectedImage = nil
                                        selectedPhotoItem = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.white)
                                            .shadow(radius: 2)
                                    }
                                    .padding(8),
                                    alignment: .topTrailing
                                )
                        } else {
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images
                            ) {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color.billixDarkTeal)

                                    Text("Tap to Select Image")
                                        .font(.headline)

                                    Text("Select a screenshot or photo of your payment")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(40)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            Color.billixDarkTeal,
                                            style: StrokeStyle(lineWidth: 2, dash: [10])
                                        )
                                )
                            }
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newValue in
                        loadImage(from: newValue)
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("Add any notes about this proof...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    // Tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tips for Good Proof")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        VStack(alignment: .leading, spacing: 4) {
                            ProofTipRow(text: "Show the payment amount clearly")
                            ProofTipRow(text: "Include the date and time")
                            ProofTipRow(text: "Show the recipient/bill reference if possible")
                            ProofTipRow(text: "Make sure text is readable")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(12)

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Upload Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitProof()
                    }
                    .disabled(!canSubmit)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isUploading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Uploading proof...")
                            .font(.subheadline)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        }
    }

    private func submitProof() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process image"
            showError = true
            return
        }

        isUploading = true

        Task {
            do {
                try await viewModel.submitProof(
                    type: selectedProofType,
                    imageData: imageData,
                    notes: notes.isEmpty ? nil : notes
                )

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isUploading = false
                }
            }
        }
    }
}

// MARK: - Proof Tip Row

struct ProofTipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProofUploadView(viewModel: SwapDetailViewModel(swap: BillSwap(
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
    )))
}

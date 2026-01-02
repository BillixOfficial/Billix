//
//  DisputeSheet.swift
//  Billix
//
//  Dispute Sheet for Bill Swap
//

import SwiftUI
import PhotosUI

struct DisputeSheet: View {
    @ObservedObject var viewModel: SwapDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: SwapDisputeReason = .noPayment
    @State private var description: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var evidenceImages: [UIImage] = []
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var canSubmit: Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        description.count >= 20 &&
        !isSubmitting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("File a Dispute", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text("If you believe the other party has not fulfilled their obligation, you can file a dispute for review by our team.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Picker("Reason", selection: $selectedReason) {
                        ForEach(SwapDisputeReason.allCases, id: \.self) { reason in
                            Label(reason.displayName, systemImage: reason.icon)
                                .tag(reason)
                        }
                    }
                } header: {
                    Text("Dispute Reason")
                } footer: {
                    Text(selectedReason.description)
                }

                Section {
                    TextField("Describe what happened...", text: $description, axis: .vertical)
                        .lineLimit(5...10)
                } header: {
                    Text("Description")
                } footer: {
                    HStack {
                        Text("Minimum 20 characters")
                        Spacer()
                        Text("\(description.count)/500")
                    }
                    .foregroundColor(description.count < 20 ? .orange : .secondary)
                }

                Section {
                    if evidenceImages.isEmpty {
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 3,
                            matching: .images
                        ) {
                            Label("Add Evidence Photos", systemImage: "photo.on.rectangle.angled")
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(evidenceImages.enumerated()), id: \.offset) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                            .clipped()

                                        Button {
                                            evidenceImages.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                                .shadow(radius: 2)
                                        }
                                        .offset(x: 8, y: -8)
                                    }
                                }

                                if evidenceImages.count < 3 {
                                    PhotosPicker(
                                        selection: $selectedPhotos,
                                        maxSelectionCount: 3 - evidenceImages.count,
                                        matching: .images
                                    ) {
                                        VStack {
                                            Image(systemName: "plus")
                                                .font(.title2)
                                            Text("Add")
                                                .font(.caption)
                                        }
                                        .frame(width: 80, height: 80)
                                        .background(Color(UIColor.tertiarySystemBackground))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Evidence (Optional)")
                } footer: {
                    Text("Screenshots or photos that support your dispute")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock")
                            Text("Expected Resolution: 48 hours")
                        }
                        .font(.subheadline)

                        Text("Our team will review the dispute and may contact you for more information. You will be notified of the outcome.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("What Happens Next")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Important", systemImage: "info.circle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)

                        Text("Filing false disputes may result in penalties to your trust score. Only file a dispute if you have a genuine issue.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("File Dispute")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitDispute()
                    }
                    .disabled(!canSubmit)
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhotos) { _, newValue in
                loadImages(from: newValue)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isSubmitting {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Submitting dispute...")
                            .font(.subheadline)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        if evidenceImages.count < 3 {
                            evidenceImages.append(image)
                        }
                    }
                }
            }
            await MainActor.run {
                selectedPhotos = []
            }
        }
    }

    private func submitDispute() {
        isSubmitting = true

        // Convert images to data
        let evidenceData = evidenceImages.compactMap { $0.jpegData(compressionQuality: 0.7) }

        Task {
            do {
                try await viewModel.fileDispute(
                    reason: selectedReason,
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                    evidence: evidenceData.isEmpty ? nil : evidenceData
                )

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    DisputeSheet(viewModel: SwapDetailViewModel(swap: BillSwap(
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

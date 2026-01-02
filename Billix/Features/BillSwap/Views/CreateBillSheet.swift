//
//  CreateBillSheet.swift
//  Billix
//
//  Create Bill Sheet for Bill Swap
//

import SwiftUI
import PhotosUI

struct CreateBillSheet: View {
    @ObservedObject var viewModel: BillSwapViewModel
    @Environment(\.dismiss) private var dismiss

    // Bill details
    @State private var title: String = ""
    @State private var category: SwapBillCategory = .electric
    @State private var providerName: String = ""
    @State private var amountText: String = ""
    @State private var dueDate: Date = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var paymentUrl: String = ""
    @State private var accountLast4: String = ""

    // Photo picker
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var billImage: UIImage?
    @State private var isUploadingImage = false

    // State
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var amountCents: Int {
        let cleanAmount = amountText.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        guard let amount = Double(cleanAmount) else { return 0 }
        return Int(amount * 100)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        amountCents >= 100 && // Min $1
        amountCents <= maxAmountCents
    }

    private var maxAmountCents: Int {
        viewModel.trustProfile?.tier.maxBillCents ?? 10000
    }

    private var formattedMaxAmount: String {
        String(format: "$%.0f", Double(maxAmountCents) / 100.0)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Bill Photo Section
                Section {
                    VStack(spacing: 12) {
                        if let image = billImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        billImage = nil
                                        selectedPhoto = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .shadow(radius: 2)
                                    }
                                    .padding(8)
                                }
                        }

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack {
                                Image(systemName: billImage == nil ? "photo.on.rectangle.angled" : "arrow.triangle.2.circlepath")
                                    .font(.system(size: 18))
                                Text(billImage == nil ? "Add Bill Photo" : "Change Photo")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(Color.billixMoneyGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.billixMoneyGreen.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .onChange(of: selectedPhoto) { oldValue, newValue in
                            loadPhoto(from: newValue)
                        }
                    }
                } header: {
                    Text("Bill Photo")
                } footer: {
                    Text("Upload a photo of your bill to help verify the payment details")
                }

                // Bill Details Section
                Section {
                    TextField("Bill Title", text: $title)
                        .textContentType(.none)

                    Picker("Category", selection: $category) {
                        ForEach(SwapBillCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    TextField("Provider Name (Optional)", text: $providerName)
                } header: {
                    Text("Bill Details")
                }

                // Amount Section
                Section {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                    }

                    if amountCents > 0 {
                        if amountCents > maxAmountCents {
                            Label(
                                "Amount exceeds your tier limit (\(formattedMaxAmount))",
                                systemImage: "exclamationmark.triangle"
                            )
                            .font(.caption)
                            .foregroundColor(.red)
                        } else if amountCents < 100 {
                            Label(
                                "Minimum amount is $1.00",
                                systemImage: "exclamationmark.triangle"
                            )
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }

                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                } header: {
                    Text("Amount & Due Date")
                } footer: {
                    Text("Your tier allows bills up to \(formattedMaxAmount)")
                }

                // Payment Info Section
                Section {
                    TextField("Payment URL (Optional)", text: $paymentUrl)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)

                    TextField("Account Last 4 Digits (Optional)", text: $accountLast4)
                        .keyboardType(.numberPad)
                        .onChange(of: accountLast4) { oldValue, newValue in
                            if newValue.count > 4 {
                                accountLast4 = String(newValue.prefix(4))
                            }
                        }
                } header: {
                    Text("Payment Info")
                } footer: {
                    Text("This helps your swap partner pay the correct bill")
                }

                // Swap Types Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Two-Sided Swap", systemImage: "arrow.left.arrow.right")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("Both parties pay each other's bills. Fee: $0.99 each")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("One-Sided Assist", systemImage: "hand.raised")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("A helper pays your bill. Fee: $1.49 (helper pays)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Swap Types Available")
                }
            }
            .navigationTitle("Add Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createBill()
                    }
                    .disabled(!isValid || isCreating || isUploadingImage)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isCreating || isUploadingImage {
                    ProgressView(isUploadingImage ? "Uploading photo..." : "Creating...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    billImage = image
                }
            }
        }
    }

    private func createBill() {
        isCreating = true

        Task {
            do {
                // Upload image first if one is selected
                var imageUrl: String? = nil
                if let image = billImage,
                   let imageData = image.jpegData(compressionQuality: 0.8) {
                    await MainActor.run {
                        isUploadingImage = true
                        isCreating = false
                    }

                    imageUrl = try await BillSwapService.shared.uploadBillImage(imageData)

                    await MainActor.run {
                        isUploadingImage = false
                        isCreating = true
                    }
                }

                _ = try await viewModel.createBill(
                    title: title.trimmingCharacters(in: .whitespaces),
                    category: category,
                    providerName: providerName.isEmpty ? nil : providerName,
                    amountCents: amountCents,
                    dueDate: dueDate,
                    paymentUrl: paymentUrl.isEmpty ? nil : paymentUrl,
                    accountNumberLast4: accountLast4.isEmpty ? nil : accountLast4,
                    billImageUrl: imageUrl
                )

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isCreating = false
                    isUploadingImage = false
                }
            }
        }
    }
}

#Preview {
    CreateBillSheet(viewModel: BillSwapViewModel())
}

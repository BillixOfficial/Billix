//
//  BillReceiptUploadView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  View for uploading paid bill receipts to earn credits
//

import SwiftUI
import PhotosUI

struct BillReceiptUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var receiptService = BillReceiptExchangeService.shared

    // Form state
    @State private var selectedCategory: ReceiptBillCategory = .electricity
    @State private var providerName: String = ""
    @State private var amount: String = ""
    @State private var paidDate: Date = Date()
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage?

    // Photo picker
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var photoPickerItem: PhotosPickerItem?

    // Alerts
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var earnedCredits = 0

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Info banner
                        infoBanner

                        // Image selection
                        imageSelectionCard

                        // Bill details form
                        billDetailsCard

                        // Credits preview
                        creditsPreviewCard

                        // Upload button
                        uploadButton

                        // Legal text
                        legalText
                    }
                    .padding()
                }
            }
            .navigationTitle("Upload Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(secondaryText)
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
            .onChange(of: photoPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        selectedImage = UIImage(data: data)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(imageData: $selectedImageData, image: $selectedImage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Receipt Uploaded!", isPresented: $showSuccess) {
                Button("Great!") { dismiss() }
            } message: {
                Text("Your receipt is being verified. You'll earn \(earnedCredits) credits once approved!")
            }
        }
    }

    // MARK: - Info Banner

    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Earn Credits")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)

                Text("Upload a paid bill receipt to earn credits you can use to unlock premium features")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)
            }

            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Image Selection

    private var imageSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Receipt Image")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(secondaryText)

            if let image = selectedImage {
                // Show selected image
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)

                    Button {
                        selectedImage = nil
                        selectedImageData = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(8)
                }
            } else {
                // Image picker buttons
                HStack(spacing: 12) {
                    Button {
                        showCamera = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                            Text("Take Photo")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(cardBg)
                        .cornerRadius(12)
                    }

                    Button {
                        showPhotoPicker = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 24))
                            Text("Choose Photo")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(cardBg)
                        .cornerRadius(12)
                    }
                }
            }

            Text("Upload a clear photo of your payment confirmation or receipt")
                .font(.system(size: 11))
                .foregroundColor(secondaryText)
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - Bill Details

    private var billDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bill Details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(secondaryText)

            // Category picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ReceiptBillCategory.allCases) { category in
                            categoryChip(category)
                        }
                    }
                }
            }

            // Provider name
            VStack(alignment: .leading, spacing: 8) {
                Text("Provider (optional)")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)

                TextField("e.g., AT&T, Verizon, etc.", text: $providerName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(background)
                    .cornerRadius(8)
                    .foregroundColor(primaryText)
            }

            // Amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount Paid")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)

                HStack {
                    Text("$")
                        .foregroundColor(secondaryText)
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(primaryText)
                }
                .padding()
                .background(background)
                .cornerRadius(8)
            }

            // Date picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Payment Date")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)

                DatePicker("", selection: $paidDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                    .colorScheme(.dark)
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func categoryChip(_ category: ReceiptBillCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            selectedCategory = category
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                Text(category.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? category.color : cardBg)
            .cornerRadius(20)
        }
    }

    // MARK: - Credits Preview

    private var creditsPreviewCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("You'll earn")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)

                HStack(spacing: 4) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.yellow)
                    Text("\(selectedCategory.creditsEarned)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(primaryText)
                    Text("credits")
                        .font(.system(size: 14))
                        .foregroundColor(secondaryText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("after verification")
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)

                Text("~1-2 minutes")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(accent)
            }
        }
        .padding()
        .background(accent.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Upload Button

    private var uploadButton: some View {
        Button {
            Task {
                await uploadReceipt()
            }
        } label: {
            HStack {
                if receiptService.isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    Text("Uploading... \(Int(receiptService.uploadProgress * 100))%")
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Upload Receipt")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isFormValid ? accent : accent.opacity(0.5))
            .cornerRadius(12)
        }
        .disabled(!isFormValid || receiptService.isUploading)
    }

    private var isFormValid: Bool {
        selectedImageData != nil && !amount.isEmpty && (Decimal(string: amount) ?? 0) > 0
    }

    // MARK: - Legal Text

    private var legalText: some View {
        VStack(spacing: 8) {
            Text("By uploading, you confirm this is a genuine receipt for a bill you paid. Fraudulent uploads may result in account suspension.")
                .font(.system(size: 10))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)

            Text("Receipts are verified automatically and never shared with other users.")
                .font(.system(size: 10))
                .foregroundColor(secondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Upload Action

    private func uploadReceipt() async {
        guard let imageData = selectedImageData,
              let amountDecimal = Decimal(string: amount) else {
            return
        }

        let request = ReceiptUploadRequest(
            category: selectedCategory,
            providerName: providerName.isEmpty ? nil : providerName,
            amount: amountDecimal,
            paidDate: paidDate,
            imageData: imageData
        )

        do {
            let receipt = try await receiptService.uploadReceipt(request)
            earnedCredits = selectedCategory.creditsEarned
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Receipt History View

struct ReceiptHistoryView: View {
    @StateObject private var receiptService = BillReceiptExchangeService.shared
    @State private var selectedFilter: ReceiptFilter = .all

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.gray
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 16) {
                // Stats card
                statsCard

                // Filter
                filterPicker

                // Receipt list
                if filteredReceipts.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredReceipts) { receipt in
                                receiptRow(receipt)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Receipt History")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await receiptService.loadReceipts()
        }
    }

    private var filteredReceipts: [BillReceipt] {
        receiptService.filteredReceipts(by: selectedFilter)
    }

    private var statsCard: some View {
        HStack(spacing: 20) {
            statItem(
                value: "\(receiptService.statistics.totalUploaded)",
                label: "Uploaded",
                color: .blue
            )
            statItem(
                value: "\(receiptService.statistics.totalVerified)",
                label: "Verified",
                color: .green
            )
            statItem(
                value: "\(receiptService.statistics.totalCreditsEarned)",
                label: "Credits",
                color: .yellow
            )
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(ReceiptFilter.allCases, id: \.self) { filter in
                Text(filter.displayName).tag(filter)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.text.image")
                .font(.system(size: 48))
                .foregroundColor(secondaryText)
            Text("No receipts yet")
                .font(.system(size: 16))
                .foregroundColor(secondaryText)
            Text("Upload your first receipt to start earning credits!")
                .font(.system(size: 13))
                .foregroundColor(secondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private func receiptRow(_ receipt: BillReceipt) -> some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: receipt.category?.icon ?? "doc.fill")
                .font(.system(size: 18))
                .foregroundColor(receipt.category?.color ?? .gray)
                .frame(width: 40, height: 40)
                .background((receipt.category?.color ?? .gray).opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(receipt.category?.displayName ?? "Bill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(primaryText)

                    if let provider = receipt.providerName {
                        Text("• \(provider)")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                    }
                }

                Text(receipt.formattedDate)
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(receipt.formattedAmount)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)

                HStack(spacing: 4) {
                    Image(systemName: receipt.status.icon)
                        .font(.system(size: 10))
                    Text(receipt.status.displayName)
                        .font(.system(size: 10))
                }
                .foregroundColor(receipt.status.color)
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct BillReceiptUploadView_Previews: PreviewProvider {
    static var previews: some View {
        BillReceiptUploadView()
            .preferredColorScheme(.dark)
    }
}
